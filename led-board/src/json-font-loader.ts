/**
 * JSON ビットマップフォント ローダー
 *
 * BDF→JSON 変換したフォントデータを読み込み、LED Board で使える形式に変換する。
 *
 * 使い方:
 *   import { loadFontFromJson, renderJsonFont, getLoadedFonts } from "./json-font-loader";
 *   await loadFontFromJson("/data/kanji-16x16.json", "kanji16");
 *   const matrix = renderJsonFont("こんにちは", { fontId: "kanji16" });
 */

import type { CharMap } from "./dot-font";

// ── 型定義 ──

export interface BitmapFontMetadata {
  name: string;
  source: string;
  license: string;
  width: number;
  height: number;
  description: string;
  glyphCount?: number;
}

export interface BitmapFontJson {
  format: string;
  version: number;
  metadata: BitmapFontMetadata;
  glyphs: Record<string, string[]>;
}

export interface RenderOptions {
  fontId?: string;
  scale?: number;
}

// ── ストア ──

interface LoadedFont {
  metadata: BitmapFontMetadata;
  glyphs: Record<string, string[]>;
  charMap: CharMap; // 5x7 互換形式
}

const fontStore = new Map<string, LoadedFont>();

// ── ローダー ──

/**
 * JSON フォントファイルを読み込んでストアに登録する。
 * @param url JSON ファイルの URL またはパス
 * @param fontId フォント ID (省略時は metadata.name)
 */
export async function loadFontFromJson(
  url: string,
  fontId?: string,
): Promise<LoadedFont> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to load font: ${url} (${res.status})`);
  const json: BitmapFontJson = await res.json();

  if (json.format !== "led-board-bitmap-font") {
    throw new Error(`Unsupported format: ${json.format}`);
  }

  const id = fontId ?? json.metadata.name;
  const { width, height } = json.metadata;

  // charMap に変換 (dot-font.ts 互換の string[] 形式)
  const charMap: CharMap = {};
  for (const [char, hexRows] of Object.entries(json.glyphs)) {
    const dotRows = hexRows.map((hexRow) => {
      // "11101" → "#   #" 形式に変換
      return hexRow
        .padEnd(width, "0")
        .slice(0, width)
        .replace(/1/g, "#")
        .replace(/0/g, " ");
    });
    charMap[char] = dotRows;
  }

  const loaded: LoadedFont = {
    metadata: json.metadata,
    glyphs: json.glyphs,
    charMap,
  };

  fontStore.set(id, loaded);
  console.debug(`[json-font-loader] Loaded "${id}" (${Object.keys(charMap).length} chars, ${width}×${height})`);
  return loaded;
}

/**
 * ストアからフォントを取得する。
 */
export function getFont(fontId: string): LoadedFont | undefined {
  return fontStore.get(fontId);
}

/**
 * 読み込み済みフォント一覧を取得する。
 */
export function getLoadedFonts(): { id: string; metadata: BitmapFontMetadata }[] {
  return Array.from(fontStore.entries()).map(([id, font]) => ({
    id,
    metadata: font.metadata,
  }));
}

// ── レンダリング ──

/**
 * JSON フォントデータからドットマトリクスをレンダリングする。
 * @param text 表示するテキスト
 * @param options.fontId フォント ID (省略時は最初に読み込まれたもの)
 * @param options.scale 拡大率 (デフォルト 1)
 * @returns boolean[][] 各行の各カラムが on/off
 */
export function renderJsonFont(
  text: string,
  options: RenderOptions = {},
): boolean[][] {
  const { fontId, scale = 1 } = options;

  // フォント選択
  const font = fontId
    ? fontStore.get(fontId)
    : fontStore.values().next().value;

  if (!font) {
    console.warn("[json-font-loader] No font loaded, returning empty matrix");
    return [];
  }

  const { charMap } = font;
  const charHeight = font.metadata.height * scale;
  const charWidth = font.metadata.width * scale;
  const rows: boolean[][] = Array.from({ length: charHeight }, () => []);

  for (const ch of text) {
    const pattern = charMap[ch] ?? charMap[ch.toUpperCase()] ?? null;
    if (!pattern) {
      // 未登録文字 → 空白列
      for (let r = 0; r < charHeight; r++) {
        for (let c = 0; c < charWidth; c++) {
          rows[r].push(false);
        }
      }
      continue;
    }

    for (let r = 0; r < charHeight; r++) {
      const srcRow = pattern[Math.floor(r / scale)] ?? "";
      for (let c = 0; c < charWidth; c++) {
        rows[r].push((srcRow[Math.floor(c / scale)] ?? " ") !== " ");
      }
    }
  }

  return rows;
}

// ── フォントセレクター (自動フォールバック) ──

/**
 * テキストに応じて適切なフォントを選びレンダリングする。
 * - 漢字/かなを含む → JSON フォント
 * - ASCII のみ → dot-font.ts の 5x7 フォント
 */
export function renderSmartText(
  text: string,
  fontId: string,
  scale: number = 1,
  fallback: (text: string, scale: number) => boolean[][],
): boolean[][] {
  const hasCJK = /[\u3000-\u9FFF\uF900-\uFAFF]/.test(text);
  if (hasCJK && fontStore.has(fontId)) {
    return renderJsonFont(text, { fontId, scale });
  }
  return fallback(text, scale);
}

// \u2500\u2500 \u30B0\u30EA\u30D5\u52D5\u7684\u8FFD\u52A0 \u2500\u2500

/**
 * \u52D5\u7684\u306B\u30B0\u30EA\u30D5\u3092\u8FFD\u52A0\u3059\u308B\uFF08\u5B9F\u884C\u6642\u30D5\u30A9\u30F3\u30C8\u62E1\u5F35\u7528\uFF09
 * @param fontId \u30D5\u30A9\u30F3\u30C8 ID
 * @param glyphs \u65B0\u3057\u3044\u30B0\u30EA\u30D5 { "\u6F22": ["0000", ...], ... }
 */
export function addGlyphs(
  fontId: string,
  glyphs: Record<string, string[]>,
): void {
  const font = fontStore.get(fontId);
  if (!font) {
    console.warn(`Font ${fontId} not loaded, cannot add glyphs`);
    return;
  }

  for (const [char, hexRows] of Object.entries(glyphs)) {
    const charMap = hexToCharMap(hexRows);
    font.charMap[char] = charMap;
    font.glyphs[char] = hexRows;
  }

  console.log(`Added ${Object.keys(glyphs).length} glyphs to font ${fontId}`);
}

/**
 * hex\u5F62\u5F0F\u3092 CharMap \u5F62\u5F0F\u306B\u5909\u63DB\uFF0816x16 hex \u2192 \u63CF\u753B\u53EF\u80FD\u306A\u884C\u5217\uFF09
 */
function hexToCharMap(hexRows: string[]): string[] {
  return hexRows.map((hexRow) => {
    const bits = parseInt(hexRow, 16).toString(2).padStart(16, "0");
    return bits.split("").map((b) => (b === "1" ? "#" : " ")).join("");
  });
}
