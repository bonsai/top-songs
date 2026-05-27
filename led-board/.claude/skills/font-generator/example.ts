/**
 * Font Generator スキル使用例
 *
 * LED Board で新しい漢字フォントを実装する際のリファレンス
 */

import {
  generateKanjiGlyph,
  generateBatchGlyphs,
  validateGlyph,
} from "./template";

// ── 例 1: 単一文字の生成 ──

async function example1SingleChar() {
  try {
    const glyph = await generateKanjiGlyph("漢");
    console.log("Generated glyph for 漢:");
    console.log(glyph);
    // Output:
    // [
    //   "0000",
    //   "7FFE",
    //   "8001",
    //   ...
    //   "0000"
    // ]
  } catch (error) {
    console.error("Error:", error);
  }
}

// ── 例 2: 複数文字のバッチ生成 ──

async function example2BatchChars() {
  try {
    const glyphs = await generateBatchGlyphs("複数文字フォント");
    console.log("Generated glyphs:", Object.keys(glyphs));
    // Output:
    // ["複", "数", "文", "字", "フ", "ォ", "ン", "ト"]

    // 各文字のグリフを検証
    for (const [char, rows] of Object.entries(glyphs)) {
      validateGlyph(rows);
      console.log(`✓ ${char}: ${rows.length} rows`);
    }
  } catch (error) {
    console.error("Error:", error);
  }
}

// ── 例 3: API エンドポイントでの使用（dev-server.ts） ──

async function example3ApiEndpoint(body: string) {
  try {
    const { text } = JSON.parse(body);

    // バッチ生成
    const glyphs = await generateBatchGlyphs(text);

    // DB に保存（font-db.ts の batchSaveGlyphs を呼び出し）
    // await batchSaveGlyphs(glyphs);

    // API レスポンス
    return {
      ok: true,
      glyphs,
      generated: Object.keys(glyphs).length,
    };
  } catch (error) {
    return {
      ok: false,
      error: error instanceof Error ? error.message : "Unknown error",
    };
  }
}

// ── 例 4: リトライロジック（自動リトライ） ──

async function example4WithRetry() {
  // generateKanjiGlyph は自動的に 3 回までリトライします
  try {
    const glyph = await generateKanjiGlyph("字", 5); // 最大 5 回まで試行
    console.log("Success:", glyph);
  } catch (error) {
    console.error("Failed after retries:", error);
  }
}

// ── 例 5: バリデーション（エラーハンドリング） ──

async function example5Validation() {
  const validGlyph = ["0000", "7FFE", "8001", "8001", "8001", "8001", "7FFE", "0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000"];

  try {
    validateGlyph(validGlyph);
    console.log("✓ Valid glyph");
  } catch (error) {
    console.error("✗ Invalid glyph:", error);
  }

  // 無効な例
  const invalidGlyph = ["0000", "7FFE", "8001"]; // 16行未満

  try {
    validateGlyph(invalidGlyph);
  } catch (error) {
    console.error("✗ Expected error:", error?.message);
    // Expected error: Expected 16 rows, got 3
  }
}

// ── 実行例 ──

if (import.meta.main) {
  (async () => {
    console.log("Running examples...\n");
    await example1SingleChar();
    console.log("\n---\n");
    await example2BatchChars();
    console.log("\n---\n");
    await example4WithRetry();
    console.log("\n---\n");
    await example5Validation();
  })();
}
