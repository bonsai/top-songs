#!/usr/bin/env node
/**
 * jiskan16.bdf をダウンロードして JSON に変換するスクリプト。
 *
 * 使い方:
 *   npx tsx src/download-kanji-font.ts
 *
 * 必要なもの:
 *   - curl (または fetch を使用)
 *
 * 出力: data/kanji-16x16.json
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.resolve(__dirname, "../data");
const BDF_URL = "https://raw.githubusercontent.com/hohno-46466/uZone--tools--getbitmapfont/main/fonts/jiskan16.bdf";
const BDF_FILE = path.join(DATA_DIR, "jiskan16.bdf");
const JSON_FILE = path.join(DATA_DIR, "kanji-16x16.json");

async function download(url: string, dest: string): Promise<void> {
  console.error(`Downloading ${url} ...`);
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${url}`);
  const buf = await res.arrayBuffer();
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, Buffer.from(buf));
  console.error(`Saved: ${dest} (${buf.byteLength.toLocaleString()} bytes)`);
}

type Glyph = { encoding: number; name: string; bitmap: string[] };

function parseBdf(content: string): Glyph[] {
  const glyphs: Glyph[] = [];
  let cur: Glyph | null = null;
  let inBitmap = false;
  const bmp: string[] = [];

  for (const line of content.split(/\r?\n/)) {
    if (line.startsWith("STARTCHAR")) {
      cur = { encoding: 0, name: line.slice(10).trim(), bitmap: [] };
      inBitmap = false;
      bmp.length = 0;
    } else if (line.startsWith("ENCODING") && cur) {
      cur.encoding = parseInt(line.slice(9).trim(), 10);
    } else if (line.startsWith("BITMAP")) {
      inBitmap = true;
      bmp.length = 0;
    } else if (line.startsWith("ENDCHAR") && cur) {
      cur.bitmap = [...bmp];
      glyphs.push(cur);
      cur = null;
      inBitmap = false;
    } else if (inBitmap) {
      bmp.push(line.trim());
    }
  }
  return glyphs;
}

// unused in final output, kept for reference
function _hexRowToDot(hex: string, w: number): boolean[] {
  const n = parseInt(hex, 16);
  if (isNaN(n)) return Array(w).fill(false);
  const bits = n.toString(2).padStart(w, "0").slice(-w);
  return bits.split("").map((b) => b === "1");
}


function glyphToJsonRows(glyph: Glyph, w: number, h: number): string[] | null {
  const cp = glyph.encoding;
  const isCJK =
    (cp >= 0x4E00 && cp <= 0x9FFF) ||
    (cp >= 0x3040 && cp <= 0x309F) ||
    (cp >= 0x30A0 && cp <= 0x30FF) ||
    (cp >= 0xFF00 && cp <= 0xFFEF) ||
    (cp >= 0x3000 && cp <= 0x303F) ||
    (cp >= 0x0020 && cp <= 0x007E) ||
    (cp >= 0xFF61 && cp <= 0xFF9F);

  if (!isCJK || glyph.bitmap.length === 0) return null;

  const rows = glyph.bitmap.slice(0, h).map((hex) => {
    const n = parseInt(hex, 16);
    return isNaN(n) ? "".padEnd(w, "0") : n.toString(2).padStart(w, "0").slice(-w);
  });

  while (rows.length < h) rows.push("".padEnd(w, "0"));
  return rows;
}

async function main() {
  // Download BDF
  fs.mkdirSync(DATA_DIR, { recursive: true });

  if (!fs.existsSync(BDF_FILE)) {
    await download(BDF_URL, BDF_FILE);
  } else {
    console.error(`Already cached: ${BDF_FILE}`);
  }

  // Parse
  console.error("Parsing BDF...");
  const content = fs.readFileSync(BDF_FILE, "utf-8");
  const glyphs = parseBdf(content);
  console.error(`Total glyphs: ${glyphs.length}`);

  // Convert & build sample index
  const W = 16, H = 16;
  const jsonGlyphs: Record<string, string[]> = {};
  const sampleChars = [
    "一","二","三","四","五","六","七","八","九","十",
    "百","千","万","円","日","月","火","水","木","金",
    "土","年","時","間","分","秒","曜","大","小","中",
    "人","手","足","目","口","耳","鼻","頭","体","心",
    "花","山","川","海","空","星","雲","雨","電","車",
    "道","駅","前","後","左","右","上","下","外","内",
    "東","西","南","北","高","安","新","古","長","短",
    "赤","青","白","黒","黄","緑","色","光","音","色",
    "男","女","子","父","母","友","自","己","私","君",
    "生","死","病","気","痛","疲","楽","喜","怒","哀",
    "会","社","員","長","部","課","係","者","場","所",
    "学","校","先","生","医","者","看","護","師","院",
    "店","屋","宅","家","庭","台","所","食","物","肉",
    "魚","野菜","果物","米","麦","豆","茶","酒","薬","服",
  ];

  for (const glyph of glyphs) {
    const char = String.fromCodePoint(glyph.encoding);
    const rows = glyphToJsonRows(glyph, W, H);
    if (rows) {
      jsonGlyphs[char] = rows;
    }
  }

  // Build output
  const includeChars = new Set(sampleChars);
  const sampleGlyphs: Record<string, string[]> = {};
  for (const char of sampleChars) {
    if (jsonGlyphs[char]) {
      sampleGlyphs[char] = jsonGlyphs[char];
    }
  }

  const fullOutput = {
    format: "led-board-bitmap-font",
    version: 1,
    metadata: {
      name: "jiskan16",
      source: BDF_URL,
      license: "Public Domain",
      width: W,
      height: H,
      description: "JIS Kanji 16x16 dot bitmap font converted from jiskan16.bdf",
      glyphCount: Object.keys(jsonGlyphs).length,
    },
    glyphs: jsonGlyphs,
  };

  fs.writeFileSync(JSON_FILE, JSON.stringify(fullOutput, null, 2), "utf-8");
  const byteSize = fs.statSync(JSON_FILE).size;
  console.error(`Written: ${JSON_FILE}`);
  console.error(`  ${byteSize.toLocaleString()} bytes`);
  console.error(`  ${Object.keys(jsonGlyphs).length} glyphs`);
}

main().catch(console.error);
