/**
 * BDF → JSON ビットマップフォントコンバーター
 *
 * 使い方:
 *   npx tsx src/bdf2json.ts fonts/jiskan16.bdf -o data/kanji-16x16.json
 *
 * 出力: LED Board 互換 JSON フォーマット
 *   {
 *     "format": "led-board-bitmap-font",
 *     "version": 1,
 *     "metadata": { "name": "...", "width": 16, "height": 16, ... },
 *     "glyphs": { "亜": ["0000","0000",...], ... }
 *   }
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { parseArgs } from "node:util";

const args = parseArgs({
  options: {
    output: { type: "string", short: "o" },
    width: { type: "string", default: "16" },
    height: { type: "string", default: "16" },
  },
  allowPositionals: true,
});

const [inputFile] = args.positionals;
if (!inputFile) {
  console.error("Usage: npx tsx src/bdf2json.ts <input.bdf> [-o output.json]");
  process.exit(1);
}

const W = parseInt(args.values.width!, 10);
const H = parseInt(args.values.height!, 10);
const outputFile = args.values.output;

interface Glyph {
  encoding: number;
  name: string;
  bitmap: string[];
}

function parseBDF(filePath: string): Glyph[] {
  const content = fs.readFileSync(filePath, "utf-8");
  const lines = content.split(/\r?\n/);
  const glyphs: Glyph[] = [];
  let current: Glyph | null = null;
  let inBitmap = false;
  let bitmapLines: string[] = [];

  for (const line of lines) {
    if (line.startsWith("STARTCHAR")) {
      current = { encoding: 0, name: line.slice(10).trim(), bitmap: [] };
      inBitmap = false;
      bitmapLines = [];
    } else if (line.startsWith("ENCODING")) {
      if (current) current.encoding = parseInt(line.slice(9).trim(), 10);
    } else if (line.startsWith("BITMAP")) {
      inBitmap = true;
      bitmapLines = [];
    } else if (line.startsWith("ENDCHAR")) {
      if (current) {
        current.bitmap = bitmapLines;
        glyphs.push(current);
      }
      current = null;
      inBitmap = false;
    } else if (inBitmap) {
      bitmapLines.push(line.trim());
    }
  }

  return glyphs;
}

function hexToDotRow(hex: string, width: number): string {
  const num = parseInt(hex, 16);
  if (isNaN(num)) return "".padEnd(width, "0");
  return num.toString(2).padStart(width, "0").slice(-width);
}

function convertToJsonGlyph(glyph: Glyph, w: number, h: number): string[] | null {
  // Only include CJK characters (U+4E00–U+9FFF and others)
  const cp = glyph.encoding;
  const isCJK =
    (cp >= 0x4E00 && cp <= 0x9FFF) ||   // CJK Unified Ideographs
    (cp >= 0x3040 && cp <= 0x309F) ||   // Hiragana
    (cp >= 0x30A0 && cp <= 0x30FF) ||   // Katakana
    (cp >= 0xFF00 && cp <= 0xFFEF) ||   // Fullwidth
    (cp >= 0x3000 && cp <= 0x303F) ||   // CJK Symbols
    (cp >= 0x0020 && cp <= 0x007E) ||   // ASCII
    (cp >= 0xFF61 && cp <= 0xFF9F);      // Halfwidth Katakana

  if (!isCJK || glyph.bitmap.length === 0) return null;

  const rows = glyph.bitmap.slice(0, h).map((hex) => hexToDotRow(hex, w));

  // Pad if short
  while (rows.length < h) rows.push("".padEnd(w, "0"));

  return rows;
}

function main() {
  console.error(`Reading BDF: ${inputFile}`);
  const glyphs = parseBDF(inputFile);
  console.error(`Total glyphs: ${glyphs.length}`);

  const jsonGlyphs: Record<string, string[]> = {};
  let converted = 0;
  let skipped = 0;

  for (const glyph of glyphs) {
    const char = String.fromCodePoint(glyph.encoding);
    const rows = convertToJsonGlyph(glyph, W, H);
    if (rows) {
      jsonGlyphs[char] = rows;
      converted++;
    } else {
      skipped++;
    }
  }

  console.error(`Converted: ${converted}, Skipped: ${skipped}`);

  const output = {
    format: "led-board-bitmap-font",
    version: 1,
    metadata: {
      name: path.basename(inputFile, ".bdf"),
      source: inputFile,
      license: "Public Domain / Unknown",
      width: W,
      height: H,
      description: `Converted from BDF: ${inputFile}`,
      glyphCount: converted,
    },
    glyphs: jsonGlyphs,
  };

  const json = JSON.stringify(output, null, 2);

  if (outputFile) {
    fs.mkdirSync(path.dirname(outputFile), { recursive: true });
    fs.writeFileSync(outputFile, json, "utf-8");
    console.error(`Written: ${outputFile} (${json.length.toLocaleString()} bytes, ${converted} glyphs)`);
  } else {
    process.stdout.write(json);
  }
}

main();
