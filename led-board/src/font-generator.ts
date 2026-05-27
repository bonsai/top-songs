/**
 * Sakura AI API を使用した漢字フォント生成
 *
 * API: https://api.ai.sakura.ad.jp/v1/messages
 * Model: preview/Phi-4-mini-instruct-cpu
 */

export interface GlyphData {
  char: string;
  rows: string[];
}

export interface GenerationResult {
  success: boolean;
  char: string;
  data?: string[];
  error?: string;
}

const SAKURA_API_URL = process.env.SAKURA_API_URL || "https://api.ai.sakura.ad.jp/v1/messages";
const SAKURA_API_KEY = process.env.SAKURA_API_KEY;
const SAKURA_MODEL = "preview/Phi-4-mini-instruct-cpu";

if (!SAKURA_API_KEY) {
  console.warn("⚠️  SAKURA_API_KEY not set - font generation will fail");
}

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
      const message = await callSakuraApi(char);
      const rows = parseGlyphResponse(message);
      validateGlyph(rows);
      return rows;
    } catch (error) {
      if (attempt === maxRetries - 1) {
        throw new Error(
          `Failed to generate glyph for '${char}' after ${maxRetries} retries: ${error}`
        );
      }
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
  throw new Error("Unexpected error in generateKanjiGlyph");
}

/**
 * 複数文字をバッチで生成
 * @param text 複数文字（例: "複数文字"）
 * @returns 文字ごとのグリフ辞書
 */
export async function generateBatchGlyphs(
  text: string
): Promise<Record<string, string[]>> {
  const chars = [...new Set(text)];
  const results: Record<string, string[]> = {};
  const errors: GenerationResult[] = [];

  for (const char of chars) {
    try {
      results[char] = await generateKanjiGlyph(char);
    } catch (error) {
      errors.push({
        success: false,
        char,
        error: String(error),
      });
    }
  }

  if (errors.length > 0) {
    console.warn(`Font generation errors:`, errors);
  }

  return results;
}

/**
 * Sakura AI API を呼び出し
 */
async function callSakuraApi(char: string): Promise<string> {
  if (!SAKURA_API_KEY) {
    throw new Error("SAKURA_API_KEY not configured");
  }

  const payload = {
    model: SAKURA_MODEL,
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
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);

  try {
    const response = await fetch(SAKURA_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${SAKURA_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Sakura API error ${response.status}: ${errorBody}`);
    }

    const data = await response.json();

    // OpenAI 互換形式に対応
    if (data.choices && data.choices.length > 0) {
      const message = data.choices[0].message;
      if (message && message.content) {
        return message.content;
      }
    }

    throw new Error("Invalid response format from Sakura API");
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * API レスポンスから JSON を抽出してパース
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
