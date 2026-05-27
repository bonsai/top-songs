import React, { useState, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import { renderText } from "../dot-font";
import { renderPixelixText } from "../pixelix-font";
import { loadFontFromJson, renderJsonFont, getLoadedFonts, renderSmartText, addGlyphs } from "../json-font-loader";

const COLORS = [
  "#ff0041","#ff2020","#ff4400","#ff6600","#ff8800",
  "#ffaa00","#ffcc00","#ffdd00","#ffff41","#aaff00",
  "#55ff00","#00ff41","#00ff88","#00ffcc","#00ffff",
  "#41ffff","#0088ff","#0041ff","#4400ff","#8800ff",
  "#aa00ff","#ff41ff","#ff00aa","#ff0066","#ff69b4",
  "#a020f0","#ffffff",
];

const API_MSG = "/api/board-messages";

const PRESETS = [
  "蔵前ドープネス",
  "そば処平井",
  "ライブで会おう",
  "ありがとう",
  "あつまれ",
  "LET'S GO",
  "LOVE",
  "FOX JUMP",
];

function hslHex(h: number): string {
  h = ((h % 360) + 360) % 360;
  const sec = Math.floor(h / 60), f = h / 60 - sec, q = 1 - f, t = f;
  let r = 0, g = 0, b = 0;
  switch (sec) {
    case 0: r = 1; g = t; break; case 1: r = q; g = 1; break; case 2: g = 1; b = t; break;
    case 3: g = q; b = 1; break; case 4: r = t; b = 1; break; case 5: r = 1; b = q; break;
  }
  const hx = (n: number) => Math.round(255 * n).toString(16).padStart(2, "0");
  return `#${hx(r)}${hx(g)}${hx(b)}`;
}

export const LedBoardPage: React.FC = () => {
  const [screenH, setScreenH] = useState(320);
  const [colorIdx, setColorIdx] = useState(11);
  const [dotSize, setDotSize] = useState(4);
  const [glow, setGlow] = useState(2);
  const [rainbow, setRainbow] = useState(false);
  const [text, setText] = useState("");
  const [previewText, setPreviewText] = useState("");
  const [pixelFont, setPixelFont] = useState(true);
  const [jsonFontLoaded, setJsonFontLoaded] = useState(false);
  const [fontMode, setFontMode] = useState<"auto" | "5x7" | "pixelix" | "json16">("auto");
  const [messages, setMessages] = useState<{ id: number; content: string; created_at: string }[]>([]);
  const [fontGenText, setFontGenText] = useState("");
  const [fontGenLoading, setFontGenLoading] = useState(false);
  const [fontGenStatus, setFontGenStatus] = useState<{ type: "success" | "error"; message: string } | null>(null);;

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const boxRef = useRef<HTMLDivElement>(null);
  const scrollRef = useRef(0);
  const hueRef = useRef(0);
  const [currentTime, setCurrentTime] = useState("");

  const handleSelectPreset = (preset: string) => {
    setText(preset);
    setPreviewText(preset);
  };

  const handleGenerateFont = async () => {
    if (!fontGenText.trim()) {
      setFontGenStatus({ type: "error", message: "Text is required" });
      return;
    }

    setFontGenLoading(true);
    setFontGenStatus(null);

    try {
      const res = await fetch("/api/font-generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: fontGenText.trim() }),
      });

      const data = await res.json();

      if (!data.ok) {
        throw new Error(data.error || "Font generation failed");
      }

      // Add glyphs to the loaded font
      if (jsonFontLoaded && data.glyphs) {
        addGlyphs("kanji16", data.glyphs);
      }

      setFontGenStatus({
        type: "success",
        message: `Generated ${data.generated} new glyphs, ${data.cached} cached`,
      });

      setFontGenText("");

      // Auto-hide status after 3 seconds
      setTimeout(() => setFontGenStatus(null), 3000);
    } catch (error) {
      setFontGenStatus({
        type: "error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    } finally {
      setFontGenLoading(false);
    }
  };

  /* fetch messages */
  useEffect(() => {
    const fetchMsg = async () => {
      try {
        const res = await fetch(`${API_MSG}?category=message`);
        if (res.ok) { const d = await res.json(); setMessages(d || []); }
      } catch {}
    };
    fetchMsg();
    const id = setInterval(fetchMsg, 4000);
    return () => clearInterval(id);
  }, []);

  /* auto-submit */
  useEffect(() => {
    if (!text.trim()) return;
    const t = setTimeout(async () => {
      try {
        await fetch(API_MSG, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ category: "message", content: text.trim(), key: "" }),
        });
        setText("");
      } catch {}
    }, 1000);
    return () => clearTimeout(t);
  }, [text]);

  /* update time */
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      const h = String(now.getHours()).padStart(2, "0");
      const m = String(now.getMinutes()).padStart(2, "0");
      setCurrentTime(`${h}:${m}`);
    };
    updateTime();
    const id = setInterval(updateTime, 1000);
    return () => clearInterval(id);
  }, []);

  /* load JSON font */
  useEffect(() => {
    (async () => {
      try {
        await loadFontFromJson("/data/kanji-sample.json", "kanji16");
        setJsonFontLoaded(true);
        console.log("JSON font loaded");
      } catch (e) {
        console.warn("Failed to load JSON font:", e);
      }
    })();
  }, []);

  useEffect(() => {
    if (!previewText || text.trim()) return;
    const t = setTimeout(() => setPreviewText(""), 2500);
    return () => clearTimeout(t);
  }, [previewText, text]);

  /* canvas render loop */
  useEffect(() => {
    const canvas = canvasRef.current;
    const box = boxRef.current;
    if (!canvas || !box) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let alive = true;

    const loop = () => {
      if (!alive) return;

      const W = box.clientWidth;
      const H = box.clientHeight;
      if (W < 10 || H < 10) { requestAnimationFrame(loop); return; }

      if (canvas.width !== W || canvas.height !== H) {
        canvas.width = W;
        canvas.height = H;
      }

      ctx.fillStyle = "#000";
      ctx.fillRect(0, 0, W, H);

      const displayText = previewText || (messages.length ? messages.map(m => m.content).join("     ") : currentTime);
      if (!displayText) { requestAnimationFrame(loop); return; }

      const f = dotSize;
      const STEP = 14 + (f - 1) * 6;
      let matrix: boolean[][];
      switch (fontMode) {
        case "json16":
          matrix = renderJsonFont(displayText, { fontId: "kanji16", scale: f });
          break;
        case "auto":
          matrix = renderSmartText(displayText, "kanji16", f, pixelFont ? renderPixelixText : renderText);
          break;
        case "pixelix":
          matrix = renderPixelixText(displayText, f);
          break;
        default:
          matrix = renderText(displayText, f);
          break;
      }
      const mH = matrix.length;
      const mW = matrix[0]?.length || 0;
      const totalW = mW * STEP;

      /* color */
      let color: string;
      if (rainbow) { hueRef.current = (hueRef.current + 2) % 360; color = hslHex(hueRef.current); }
      else { color = COLORS[colorIdx] || "#00ff41"; }

      /* scroll */
      scrollRef.current = (scrollRef.current + 0.6) % (totalW + W);
      const off = scrollRef.current;
      const dotR = 4 + (f - 1) * 2;
      const cy = (H - mH * STEP) / 2 + dotR;

      for (let r = 0; r < mH; r++) {
        for (let c = 0; c < mW; c++) {
          const on = matrix[r][c];
          const x = c * STEP - off;
          const y = cy + r * STEP;
          if (x < -STEP || x > W + STEP) continue;
          ctx.beginPath();
          ctx.arc(x, y, dotR, 0, Math.PI * 2);
          if (on) {
            const blur = [0, 4, 8 + 4 * f, 16 + 8 * f][glow] ?? 8;
            if (blur) { ctx.shadowColor = color; ctx.shadowBlur = blur; }
            ctx.fillStyle = color;
            ctx.fill();
            ctx.shadowBlur = 0;
            ctx.beginPath();
            ctx.arc(x - 1, y - 1, dotR * 0.35, 0, Math.PI * 2);
            ctx.fillStyle = "rgba(255,255,255,0.35)";
            ctx.fill();
          } else {
            ctx.fillStyle = "rgba(40,40,40,0.85)";
            ctx.fill();
          }
        }
      }

      requestAnimationFrame(loop);
    };

    scrollRef.current = 0;
    requestAnimationFrame(loop);
    return () => { alive = false; };
  }, [messages, currentTime, dotSize, colorIdx, rainbow, glow, pixelFont, fontMode, jsonFontLoaded]);

  const color = rainbow ? "rainbow" : (COLORS[colorIdx] || "#00ff41");

  return (
    <div style={{ minHeight: "100vh", display: "flex", flexDirection: "column", alignItems: "center", padding: "32px 16px", gap: 14, background: "#000" }}>
      <Link to="/" style={{ position: "absolute", top: 24, left: 16, fontSize: 13, opacity: 0.5, letterSpacing: "0.2em", color: "#fff", textDecoration: "none" }}>← BACK</Link>
      <div style={{ fontSize: 11, opacity: 0.3, letterSpacing: "0.3em" }}>LED BOARD</div>

      {/* LED display */}
      <div ref={boxRef} style={{
        width: "100%", maxWidth: 900, height: screenH, borderRadius: 10,
        background: "#0a0a0a", border: `2px solid ${color}4d`,
        boxShadow: `0 0 40px ${color}14`, overflow: "hidden",
      }}>
        <canvas ref={canvasRef} style={{ display: "block", width: "100%", height: "100%" }} />
      </div>

      {/* HEIGHT */}
      <div style={{ width: "100%", maxWidth: 500, display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: 10, opacity: 0.25 }}>HEIGHT</span>
        <input type="range" min={120} max={500} value={screenH} onChange={e => setScreenH(Number(e.target.value))} style={{ flex: 1, accentColor: color }} />
      </div>

      {/* COLOR */}
      <div style={{ width: "100%", maxWidth: 500, display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: 10, opacity: 0.25, minWidth: 40 }}>COLOR</span>
        <button onClick={() => setRainbow(!rainbow)} style={{
          padding: "2px 8px", borderRadius: 8, fontSize: 10, fontWeight: 700, cursor: "pointer", fontFamily: "inherit",
          border: rainbow ? "1px solid #fff" : "1px solid rgba(255,255,255,0.15)",
          background: rainbow ? "rgba(255,255,255,0.1)" : "transparent", color: rainbow ? "#fff" : "rgba(255,255,255,0.4)",
        }}>{rainbow ? "RBW" : "FIX"}</button>
        <input type="range" min={0} max={COLORS.length - 1} step={1} value={colorIdx}
          onChange={e => { setColorIdx(Number(e.target.value)); setRainbow(false); }} disabled={rainbow}
          style={{ flex: 1, accentColor: color }} />
        <div style={{ width: 16, height: 16, borderRadius: "50%", background: color, boxShadow: `0 0 6px ${color}` }} />
      </div>

      {/* DOT */}
      <div style={{ width: "100%", maxWidth: 500, display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: 10, opacity: 0.25, minWidth: 40 }}>DOT</span>
        <input type="range" min={1} max={5} step={1} value={dotSize} onChange={e => setDotSize(Number(e.target.value))} style={{ flex: 1, accentColor: color }} />
        <span style={{ fontSize: 10, opacity: 0.4, minWidth: 16 }}>{dotSize}</span>
      </div>

      {/* GLOW */}
      <div style={{ width: "100%", maxWidth: 500, display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: 10, opacity: 0.25, minWidth: 40 }}>GLOW</span>
        <input type="range" min={0} max={3} step={1} value={glow} onChange={e => setGlow(Number(e.target.value))} style={{ flex: 1, accentColor: color }} />
        <span style={{ fontSize: 10, opacity: 0.4, minWidth: 24 }}>{["OFF","LOW","MED","HIGH"][glow]}</span>
      </div>

      {/* FONT */}
      <div style={{ width: "100%", maxWidth: 500, display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: 10, opacity: 0.25 }}>FONT</span>
        {["auto", "5x7", "pixelix", "json16"].map(mode => (
          <button key={mode} onClick={() => setFontMode(mode as typeof fontMode)} style={{
            padding: "2px 8px", borderRadius: 8, fontSize: 10, fontWeight: 700, cursor: "pointer", fontFamily: "inherit",
            border: fontMode === mode ? "1px solid #fff" : "1px solid rgba(255,255,255,0.15)",
            background: fontMode === mode ? "rgba(255,255,255,0.1)" : "transparent",
            color: fontMode === mode ? "#fff" : "rgba(255,255,255,0.4)",
            opacity: mode === "json16" && !jsonFontLoaded ? 0.3 : 1,
            filter: mode === "json16" && !jsonFontLoaded ? "grayscale(1)" : "none",
          }} disabled={mode === "json16" && !jsonFontLoaded}>
            {mode === "auto" ? "AUTO" : mode === "5x7" ? "5×7" : mode === "pixelix" ? "3×5" : "16×16"}
          </button>
        ))}
      </div>

      {/* preset */}
      <div style={{ width: "100%", maxWidth: 500, display: "flex", flexWrap: "wrap", gap: 6, marginTop: 10 }}>
        {PRESETS.map(preset => (
          <button key={preset} onClick={() => handleSelectPreset(preset)} style={{
            padding: "6px 10px", borderRadius: 999, border: "1px solid rgba(255,255,255,0.15)", background: previewText === preset ? "rgba(255,255,255,0.12)" : "rgba(255,255,255,0.05)",
            color: "#fff", cursor: "pointer", fontSize: 12, fontFamily: "inherit",
          }}>{preset}</button>
        ))}
      </div>

      {/* input */}
      <div style={{ width: "100%", maxWidth: 500, marginTop: 8 }}>
        <input value={text} onChange={e => setText(e.target.value)} placeholder="type & enter"
          style={{ width: "100%", padding: "8px 12px", borderRadius: 6, border: "1px solid rgba(255,255,255,0.1)", background: "rgba(255,255,255,0.04)", color: "#fff", fontSize: 14, fontFamily: "inherit", outline: "none" }} />
      </div>

      {/* custom font generation */}
      {jsonFontLoaded && (
        <div style={{ width: "100%", maxWidth: 500, marginTop: 16, padding: "12px", borderRadius: 6, border: "1px solid rgba(255,255,255,0.15)", background: "rgba(255,255,255,0.03)" }}>
          <div style={{ fontSize: 10, opacity: 0.5, letterSpacing: "0.2em", marginBottom: 8 }}>CUSTOM FONTS</div>
          <div style={{ display: "flex", gap: 6, marginBottom: 8 }}>
            <input value={fontGenText} onChange={e => setFontGenText(e.target.value)} onKeyPress={e => e.key === "Enter" && handleGenerateFont()}
              placeholder="Enter text to generate fonts..."
              disabled={fontGenLoading}
              style={{ flex: 1, padding: "6px 8px", borderRadius: 4, border: "1px solid rgba(255,255,255,0.1)", background: "rgba(255,255,255,0.04)", color: "#fff", fontSize: 12, fontFamily: "inherit", outline: "none" }} />
            <button onClick={handleGenerateFont} disabled={fontGenLoading}
              style={{ padding: "6px 12px", borderRadius: 4, fontSize: 11, fontWeight: 700, cursor: fontGenLoading ? "default" : "pointer", fontFamily: "inherit", border: "1px solid rgba(255,255,255,0.2)", background: fontGenLoading ? "rgba(255,255,255,0.05)" : "rgba(255,255,255,0.1)", color: fontGenLoading ? "rgba(255,255,255,0.3)" : "#fff", opacity: fontGenLoading ? 0.5 : 1 }}>
              {fontGenLoading ? "..." : "GENERATE"}
            </button>
          </div>
          {fontGenStatus && (
            <div style={{ fontSize: 11, padding: "6px 8px", borderRadius: 4, background: fontGenStatus.type === "success" ? "rgba(0,255,100,0.15)" : "rgba(255,0,50,0.15)", color: fontGenStatus.type === "success" ? "#0ff" : "#f05", border: `1px solid ${fontGenStatus.type === "success" ? "rgba(0,255,100,0.3)" : "rgba(255,0,50,0.3)"}` }}>
              {fontGenStatus.message}
            </div>
          )}
        </div>
      )}

      {/* message list */}
      <div style={{ width: "100%", maxWidth: 500, display: "flex", flexDirection: "column", gap: 4 }}>
        {messages.length === 0 && <div style={{ fontSize: 10, opacity: 0.2, textAlign: "center", padding: 12 }}>no messages</div>}
        {messages.slice(0, 10).map(m => (
          <div key={m.id} style={{
            padding: "4px 10px", borderRadius: 6, fontSize: 12,
            background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)",
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", opacity: 0.7,
          }}>{m.content}</div>
        ))}
      </div>
    </div>
  );
};
