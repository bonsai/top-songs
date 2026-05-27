import "dotenv/config";
import * as http from "node:http";
import * as os from "node:os";
import { readFileSync, appendFileSync, existsSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import pg from "pg";
const { Pool } = pg;
import { generateBatchGlyphs } from "./font-generator.js";
import { initFontDb, batchSaveGlyphs, getGlyph } from "./font-db.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(__dirname, "..", "index.html"), "utf-8");

// ── Neon / PostgreSQL ──
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 5,
  ssl: { rejectUnauthorized: false },
});

async function initDb() {
  const client = await pool.connect();
  try {
    // dataset table
    await client.query(`
      CREATE TABLE IF NOT EXISTS dataset (
        id SERIAL PRIMARY KEY,
        content TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        metadata JSONB NOT NULL DEFAULT '{}',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    console.log(" DB: dataset table ready");

    // font_glyphs table
    await client.query(`
      CREATE TABLE IF NOT EXISTS font_glyphs (
        id SERIAL PRIMARY KEY,
        font_id TEXT NOT NULL,
        character CHAR(1) NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        glyph_data JSONB NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE(font_id, character)
      );
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_font_glyphs_lookup ON font_glyphs(font_id, character);
    `);
    console.log(" DB: font_glyphs table ready");
  } finally {
    client.release();
  }
}
initDb().catch(e => console.error("DB init error:", e));

// ── WASM Music Fingerprint ──
const WASM_PATH = join(__dirname, "..", "..", "melon-sound", "music-id", "target", "wasm32-unknown-unknown", "release", "music_id.wasm");
let wasmInstance: WebAssembly.Instance | null = null;
let fpPtr = 0;
let dbPtr = 0;
let wasmHeapBase = 0;

// scratch offsets within WASM memory (set during initWasm)
let pcmBase = 0, hashBase = 0, offBase = 0, cntOff = 0;
const PCM_MAX_SAMPLES = 44100 * 3; // 3 seconds
const HASH_MAX = 10000;

function wasmMem(): WebAssembly.Memory {
  return wasmInstance!.exports.memory as WebAssembly.Memory;
}
function u32View(ptr: number): Uint32Array {
  return new Uint32Array(wasmMem().buffer, ptr, 1);
}
function f32Arr(ptr: number, len: number): Float32Array {
  return new Float32Array(wasmMem().buffer, ptr, len);
}
function growWasmPages(needed: number) {
  const mem = wasmMem();
  const current = mem.buffer.byteLength;
  if (needed > current) {
    const pages = Math.ceil((needed - current) / 65536);
    mem.grow(pages);
  }
}

function initWasm() {
  if (!existsSync(WASM_PATH)) {
    console.warn(" WASM not found at", WASM_PATH, "- listen feature disabled");
    return;
  }
  const bytes = readFileSync(WASM_PATH);
  const mod = new WebAssembly.Module(bytes);
  wasmInstance = new WebAssembly.Instance(mod);
  const e = wasmInstance.exports;

  wasmHeapBase = Number(e.__heap_base);
  const neededBytes = wasmHeapBase + 256 + PCM_MAX_SAMPLES * 4 + HASH_MAX * 4 * 2 + 128;
  growWasmPages(neededBytes);

  fpPtr = (e.fingerprint_create as CallableFunction)(44100) as number;
  dbPtr = (e.db_new as CallableFunction)() as number;

  const base = wasmHeapBase + 256;
  pcmBase = base;
  hashBase = pcmBase + PCM_MAX_SAMPLES * 4;
  offBase = hashBase + HASH_MAX * 4;
  cntOff = offBase + HASH_MAX * 4;

  console.log(" WASM fingerprint module loaded, fp=" + fpPtr + " db=" + dbPtr);
}

// Song name registry
let songNames: Record<number, string> = {};
let nextSongId = 1;
let listenMode = false;

function fingerprintPcm(pcm: Float32Array): { songId: number; score: number; songName: string } | null {
  if (!wasmInstance) return null;
  const e = wasmInstance.exports;
  const len = Math.min(pcm.length, PCM_MAX_SAMPLES);

  // write PCM to scratch
  const buf = f32Arr(pcmBase, len);
  buf.set(pcm.subarray(0, len));

  // fingerprint
  (e.fingerprint_pcm as CallableFunction)(fpPtr, pcmBase, len, hashBase, offBase, cntOff);
  const count = u32View(cntOff)[0];
  if (count === 0) return null;

  // match
  const songPtr = cntOff + 16;
  const scorePtr = cntOff + 20;
  const matchId = (e.db_match as CallableFunction)(dbPtr, hashBase, offBase, count, 3, songPtr, scorePtr);
  if (matchId < 0) return null;

  const songId = u32View(songPtr)[0];
  const score = u32View(scorePtr)[0];
  const songName = songNames[songId] || "Unknown #" + songId;
  return { songId, score, songName };
}

function registerSong(songId: number, name: string, hashes: Float32Array) {
  if (!wasmInstance) return;
  const e = wasmInstance.exports;
  const len = Math.min(hashes.length, PCM_MAX_SAMPLES);
  const buf = f32Arr(pcmBase, len);
  buf.set(hashes.subarray(0, len));
  (e.fingerprint_pcm as CallableFunction)(fpPtr, pcmBase, len, hashBase, offBase, cntOff);
  const count = u32View(cntOff)[0];
  if (count > 0) {
    (e.db_insert as CallableFunction)(dbPtr, songId, hashBase, offBase, count);
    songNames[songId] = name;
    console.log(` Song registered: #${songId} "${name}" (${count} hashes)`);
  }
}

// ── CSV Log ──
const dataDir = join(__dirname, "..", "data");
const logPath = join(dataDir, "log.csv");
if (!existsSync(dataDir)) mkdirSync(dataDir);
if (!existsSync(logPath)) {
  appendFileSync(logPath, "timestamp,message,source\n");
}

let message = "LED BOARD";
let clients: http.ServerResponse[] = [];

// ── News (proxied to news-server) ──
const NEWS_SERVER = process.env.NEWS_SERVER || "http://localhost:8081";
let newsMode = false;
let messageTimeout: ReturnType<typeof setTimeout> | null = null;
const NEWS_IDLE_MS = 20_000;

async function newsFetch(path: string, body?: string): Promise<any> {
  try {
    const opts: RequestInit = {};
    if (body) { opts.method = "POST"; opts.headers = { "Content-Type": "application/x-www-form-urlencoded" }; opts.body = body; }
    const res = await fetch(`${NEWS_SERVER}${path}`, opts);
    return await res.json();
  } catch { return null; }
}

async function startNews() {
  const data = await newsFetch("/api/news", "action=start");
  if (data) newsMode = true;
}

function stopNews() {
  newsMode = false;
  newsFetch("/api/news", "action=stop");
}

async function advanceNews() {
  const data = await newsFetch("/api/news", "action=next");
}

function userMessageReceived(text: string) {
  stopNews();
  message = text;
  broadcast(text, "manual");
  if (messageTimeout) clearTimeout(messageTimeout);
  messageTimeout = setTimeout(() => {
    newsFetch("/api/news").then(data => { if (data?.count > 0) startNews(); });
  }, NEWS_IDLE_MS);
}

// Init Font DB
initFontDb(pool);

// Init WASM fingerprint module
initWasm();

// Log initial message
broadcast(message, "startup");

// ── Optional Supabase Realtime subscription ──
const SUPABASE_URL = process.env.SUPABASE_URL || "";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "";
if (SUPABASE_URL && SUPABASE_ANON_KEY) {
  (async () => {
    const { createClient } = await import("@supabase/supabase-js");
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Fetch latest message on startup
    const { data: existing } = await supabase
      .from("messages")
      .select("text")
      .order("id", { ascending: false })
      .limit(1);
    if (existing?.length) {
      message = existing[0].text;
      broadcast(message, "startup");
    }

      // Subscribe to new inserts (push from Vercel API)
    supabase
      .channel("led-board")
      .on("postgres_changes",
        { event: "INSERT", schema: "public", table: "messages" },
        (payload) => {
          const text = payload.new?.text as string;
          if (text) userMessageReceived(text);
        }
      )
      .subscribe();
    console.log(" Supabase Realtime connected");
  })();
}

// ── Shared: notify all SSE clients + log ──
function broadcast(msg: string, source = "") {
  const ts = new Date().toISOString();
  const line = `"${ts}","${msg.replace(/"/g, '""')}","${source}"\n`;
  try { appendFileSync(logPath, line); } catch {}
  for (const client of clients) {
    client.write(`data: ${JSON.stringify({ message: msg })}\n\n`);
  }
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url ?? "/", `http://${req.headers.host ?? "localhost"}`);

  // API
  if (url.pathname === "/api/message") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.writeHead(200);
      res.end();
      return;
    }

    if (req.method === "POST") {
      let body = "";
      req.on("data", (chunk: string) => body += chunk);
      req.on("end", async () => {
        let text = "";
        try {
          const json = JSON.parse(body);
          if (json.text) text = json.text;
        } catch {
          const params = new URLSearchParams(body);
          if (params.get("text")) text = params.get("text")!;
        }
        if (text) {
          userMessageReceived(text);
          // Also write to Supabase if configured
          if (SUPABASE_URL && SUPABASE_ANON_KEY) {
            try {
              const { createClient } = await import("@supabase/supabase-js");
              const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
              await supabase.from("messages").insert({ text });
            } catch {}
          }
        }
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ message }));
      });
      return;
    }

    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ message }));
    return;
  }

  // SSE endpoint
  if (url.pathname === "/api/events") {
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "Access-Control-Allow-Origin": "*",
    });
    res.write(`data: ${JSON.stringify({ message })}\n\n`);
    clients.push(res);
    req.on("close", () => {
      clients = clients.filter(c => c !== res);
    });
    return;
  }

  // News API → proxy to news-server
  if (url.pathname === "/api/news") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") { res.writeHead(200); res.end(); return; }
    if (req.method === "POST") {
      let body = "";
      req.on("data", (chunk: string) => body += chunk);
      req.on("end", async () => {
        let action = "";
        try { const j = JSON.parse(body); if (j.action) action = j.action; }
        catch { const p = new URLSearchParams(body); action = p.get("action") || ""; }
        if (action === "start") await startNews();
        else if (action === "stop") stopNews();
        else if (action === "next") await advanceNews();
        const data = await newsFetch("/api/news");
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ newsMode, count: data?.count ?? 0 }));
      });
      return;
    }
    (async () => {
    const data = await newsFetch("/api/news") ?? {};
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
      newsMode,
      count: data.count ?? 0,
      current: data.index ?? -1,
      items: data.items ?? [],
    }));
    })();
    return;
  }

  // Listen (Music ID) API
  if (url.pathname === "/api/listen") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") { res.writeHead(200); res.end(); return; }
    if (req.method === "POST") {
      let body = "";
      req.on("data", (chunk: string) => body += chunk);
      req.on("end", async () => {
        let action = "";
        try { const j = JSON.parse(body); if (j.action) action = j.action; }
        catch { const p = new URLSearchParams(body); action = p.get("action") || ""; }
        if (action === "start") {
          listenMode = true;
          console.log(" Listen mode ON");
        } else if (action === "stop") {
          listenMode = false;
          console.log(" Listen mode OFF");
        }
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ listenMode, wasmReady: wasmInstance !== null }));
      });
      return;
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
      listenMode,
      wasmReady: wasmInstance !== null,
      songs: Object.keys(songNames).length,
    }));
    return;
  }

  // PCM fingerprint endpoint (binary Float32Array POST)
  if (url.pathname === "/api/listen/pcm") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    if (req.method === "OPTIONS") { res.writeHead(200); res.end(); return; }
    if (req.method === "POST") {
      const chunks: Buffer[] = [];
      req.on("data", (chunk: Buffer) => chunks.push(chunk));
      req.on("end", () => {
        const raw = Buffer.concat(chunks);
        const samples = raw.length / 4;
        if (samples < 1000 || !wasmInstance) {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ match: false, reason: samples < 1000 ? "too short" : "no wasm" }));
          return;
        }
        const pcm = new Float32Array(raw.buffer, raw.byteOffset, samples);
        const result = fingerprintPcm(pcm);
        if (result) {
          const msg = `🎵 ${result.songName}`;
          broadcast(msg, "listen");
          // Also set as current message
          if (!newsMode) {
            message = msg;
          }
          console.log(` Listen match: "${result.songName}" (score=${result.score})`);
          listenMode = false; // auto-stop after match
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ match: true, songId: result.songId, songName: result.songName, score: result.score }));
        } else {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ match: false }));
        }
      });
      return;
    }
    res.writeHead(405);
    res.end();
    return;
  }

  // Register a song in the fingerprint DB
  if (url.pathname === "/api/listen/register") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") { res.writeHead(200); res.end(); return; }
    if (req.method === "POST") {
      const chunks: Buffer[] = [];
      req.on("data", (chunk: Buffer) => chunks.push(chunk));
      req.on("end", () => {
        const raw = Buffer.concat(chunks);
        // Expect: JSON header "name" then binary PCM, OR full JSON with base64 PCM
        // Simple: multipart or just JSON with name + base64
        let name = "Song #" + nextSongId;
        let pcmData: Float32Array | null = null;
        try {
          const json = JSON.parse(raw.toString("utf-8"));
          name = json.name || name;
          if (json.pcm) {
            pcmData = new Float32Array(json.pcm);
          }
        } catch {
          // raw binary PCM
          if (raw.length > 4) {
            pcmData = new Float32Array(raw.buffer, raw.byteOffset, raw.length / 4);
          }
        }
        if (!pcmData || pcmData.length < 1000) {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "invalid PCM data" }));
          return;
        }
        const songId = nextSongId++;
        registerSong(songId, name, pcmData);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ songId, name, wasmReady: wasmInstance !== null }));
      });
      return;
    }
    res.writeHead(405);
    res.end();
    return;
  }

  // Log API
  if (url.pathname === "/api/log") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    if (req.method === "POST") {
      let body = "";
      req.on("data", (chunk: string) => body += chunk);
      req.on("end", () => {
        let text = "", src = "";
        try { const j = JSON.parse(body); text = j.text; src = j.source || "client"; }
        catch { const p = new URLSearchParams(body); text = p.get("text") || ""; src = p.get("source") || "client"; }
        if (text) broadcast(text, src);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true }));
      });
      return;
    }
    // GET: return last 50 log lines
    try {
      const raw = readFileSync(logPath, "utf-8").trim().split("\n");
      const rows = raw.slice(Math.max(0, raw.length - 51)).slice(1); // skip header, limit 50
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ rows: rows.map(r => r.match(/"(.*?)","(.*?)","(.*?)"/)?.slice(1) || []) }));
    } catch {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ rows: [] }));
    }
    return;
  }

  // ── Font Generator API ──
  if (url.pathname === "/api/font-generate") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") {
      res.writeHead(200);
      res.end();
      return;
    }

    if (req.method === "POST") {
      let body = "";
      req.on("data", (chunk: string) => (body += chunk));
      req.on("end", async () => {
        try {
          let text = "";
          try {
            const json = JSON.parse(body);
            text = json.text || "";
          } catch {
            const params = new URLSearchParams(body);
            text = params.get("text") || "";
          }

          if (!text) {
            res.writeHead(400, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ ok: false, error: "text required" }));
            return;
          }

          // Check existing glyphs in DB
          const chars = [...new Set(text)];
          const cached: Record<string, string[]> = {};
          const toGenerate: string[] = [];

          for (const char of chars) {
            const existing = await getGlyph(char);
            if (existing) {
              cached[char] = existing;
            } else {
              toGenerate.push(char);
            }
          }

          let generated: Record<string, string[]> = {};
          if (toGenerate.length > 0) {
            generated = await generateBatchGlyphs(toGenerate.join(""));
            await batchSaveGlyphs(generated);
            console.log(` Generated ${toGenerate.length} new glyphs`);
          }

          const allGlyphs = { ...cached, ...generated };
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(
            JSON.stringify({
              ok: true,
              glyphs: allGlyphs,
              generated: Object.keys(generated).length,
              cached: Object.keys(cached).length,
            })
          );
        } catch (error: any) {
          console.error("Font generation error:", error);
          res.writeHead(500, { "Content-Type": "application/json" });
          res.end(
            JSON.stringify({
              ok: false,
              error: error.message || "Font generation failed",
            })
          );
        }
      });
      return;
    }

    res.writeHead(405);
    res.end();
    return;
  }

  // ── Dataset API (Neon) ──
  if (url.pathname === "/api/dataset") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") { res.writeHead(200); res.end(); return; }

    if (req.method === "POST") {
      let body = "";
      req.on("data", (chunk: string) => body += chunk);
      req.on("end", async () => {
        try {
          let content = "", category = "general", metadata = {};
          try { const j = JSON.parse(body); content = j.content || ""; category = j.category || "general"; metadata = j.metadata || {}; }
          catch { const p = new URLSearchParams(body); content = p.get("content") || p.get("text") || ""; category = p.get("category") || "general"; }
          if (!content) { res.writeHead(400); res.end(JSON.stringify({ error: "content required" })); return; }
          const result = await pool.query(
            "INSERT INTO dataset (content, category, metadata) VALUES ($1, $2, $3) RETURNING id, created_at",
            [content, category, JSON.stringify(metadata)]
          );
          // Also broadcast as message if text provided
          broadcast(content, `dataset:${category}`);
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ ok: true, id: result.rows[0].id, created_at: result.rows[0].created_at }));
        } catch (e: any) { res.writeHead(500); res.end(JSON.stringify({ error: e.message })); }
      });
      return;
    }

    // GET /api/dataset?category=general&limit=50&offset=0
    (async () => {
    try {
      const category = url.searchParams.get("category") || null;
      const limit = Math.min(parseInt(url.searchParams.get("limit") || "50"), 200);
      const offset = parseInt(url.searchParams.get("offset") || "0");
      let query = "SELECT id, content, category, metadata, created_at FROM dataset";
      const params: any[] = [];
      if (category) { query += " WHERE category = $1"; params.push(category); }
      query += " ORDER BY created_at DESC LIMIT $" + (params.length + 1) + " OFFSET $" + (params.length + 2);
      params.push(limit, offset);
      const result = await pool.query(query, params);
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ rows: result.rows, total: result.rows.length }));
    } catch (e: any) { res.writeHead(500); res.end(JSON.stringify({ error: e.message })); }
    })();
    return;
  }

  // Serve the page
  if (url.pathname === "/" || url.pathname === "") {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(html);
    return;
  }

  // Serve PWA static assets
  const pwaFiles: Record<string, string> = {
    "/manifest.json": "application/manifest+json",
    "/sw.js": "application/javascript",
    "/icon-192.png": "image/png",
    "/icon-512.png": "image/png",
  };
  if (pwaFiles[url.pathname]) {
    const pwaPath = join(__dirname, "..", url.pathname);
    if (existsSync(pwaPath)) {
      res.writeHead(200, { "Content-Type": pwaFiles[url.pathname], "Cache-Control": "no-cache" });
      res.end(readFileSync(pwaPath));
      return;
    }
  }

  // Serve static data files (JSON fonts, etc.)
  const dataPath = join(__dirname, "..", url.pathname);
  if (url.pathname.startsWith("/data/") && existsSync(dataPath)) {
    const extMap: Record<string, string> = {
      ".json": "application/json",
      ".txt": "text/plain",
      ".csv": "text/csv",
    };
    const ext = extMap[dataPath.slice(dataPath.lastIndexOf("."))] || "application/octet-stream";
    res.writeHead(200, {
      "Content-Type": ext,
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "no-cache",
    });
    res.end(readFileSync(dataPath));
    return;
  }

  // 404
  res.writeHead(404);
  res.end("Not found");
});

const PORT = parseInt(process.env.PORT ?? "8080", 10);
const HOST = "0.0.0.0";
server.listen(PORT, HOST, () => {
  const ifaces = os.networkInterfaces();
  const addrs: string[] = [];
  for (const name of Object.keys(ifaces)) {
    for (const iface of ifaces[name] ?? []) {
      if (iface.family === "IPv4" && !iface.internal) {
        addrs.push(iface.address);
      }
    }
  }
  console.log(` LED Board @ http://localhost:${PORT}`);
  if (addrs.length) {
    console.log(` LAN       @ http://${addrs[0]}:${PORT}`);
    console.log(`\n POST direct:`);
    console.log(`   curl -X POST http://${addrs[0]}:${PORT}/api/message -d "text=こんにちは"`);
  }
  if (!SUPABASE_URL) {
    console.log(`\n [Hint] Set SUPABASE_URL & SUPABASE_ANON_KEY for Vercel→local push`);
  }
});
