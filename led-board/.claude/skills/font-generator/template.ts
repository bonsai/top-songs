/**
 * Font Generator Template - Claude API で漢字を ドット行列に変換
 *
 * このテンプレートをコピーして、プロジェクトに組み込んでください。
 * `src/font-generator.ts` として保存し、dev-server.ts から import します。
 */

import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

/**
 * 1文字を 16×16 ドット行列に変換
 * @param char Unicode 1文字（例: "漢"）
 * @param maxRetries リトライ回数（デフォルト 3）
 * @returns 16行の hex 文字列配列
 */
export async function generateKanjiGlyph(
  char: string,
  maxRetries: number = 3
): Promise<string[]> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const message = await client.messages.create({
        model: "claude-opus-4-7",
        max_tokens: 500,
        messages: [
          {
            role: "user",
            content: `漢字「${char}」を 16×16 ドット行列（16進数形式）で表現してください。

要件:
- 16行、各行4文字の16進数 (0-F)
- 1 = 黒（LED点灯）, 0 = 白（消灯）
- 左上から右下へ、行ごとに出力

JSON 形式で返してください:
{
  "char": "${char}",
  "rows": ["0000", "7FFE", "8001", ...]
}`,
          },
        ],
      });

      const content = message.content[0];
      if (content.type !== "text") {
        throw new Error("Unexpected response type");
      }

      const rows = parseGlyphResponse(content.text);
      validateGlyph(rows);
      return rows;
    } catch (error) {
      if (attempt === maxRetries - 1) {
        throw new Error(
          `Failed to generate glyph for '${char}' after ${maxRetries} retries: ${error}`
        );
      }
      // 指数バックオフ
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
  throw new Error("Unexpected error in generateKanjiGlyph");
}

/**
 * 複数文字をバッチで生成（効率化）
 * @param text 複数文字（例: "複数文字"）
 * @returns 文字ごとのグリフ辞書
 */
export async function generateBatchGlyphs(
  text: string
): Promise<Record<string, string[]>> {
  const chars = [...new Set(text)]; // 重複除去
  const results: Record<string, string[]> = {};
  const errors: any[] = [];

  for (const char of chars) {
    try {
      results[char] = await generateKanjiGlyph(char);
    } catch (error) {
      errors.push({ char, error: String(error) });
    }
  }

  if (errors.length > 0) {
    console.warn(`Font generation errors:`, errors);
  }

  return results;
}

/**
 * Claude レスポンスから JSON を抽出してパース
 */
function parseGlyphResponse(response: string): string[] {
  const jsonMatch = response.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error("No JSON found in response");
  }

  const parsed = JSON.parse(jsonMatch[0]);
  if (!Array.isArray(parsed.rows)) {
    throw new Error("Response rows is not an array");
  }

  return parsed.rows;
}

/**
 * グリフ形式のバリデーション
 * @throws 無効な形式の場合
 */
export function validateGlyph(rows: string[]): void {
  if (!Array.isArray(rows)) {
    throw new Error("Glyph rows must be an array");
  }

  if (rows.length !== 16) {
    throw new Error(`Expected 16 rows, got ${rows.length}`);
  }

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (typeof row !== "string") {
      throw new Error(`Row ${i} is not a string`);
    }

    if (row.length !== 4) {
      throw new Error(`Row ${i} has ${row.length} characters, expected 4`);
    }

    if (!/^[0-9A-Fa-f]{4}$/.test(row)) {
      throw new Error(`Row ${i} contains non-hex characters: ${row}`);
    }
  }
}
