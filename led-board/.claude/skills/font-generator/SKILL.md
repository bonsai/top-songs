# font-generator: Claude API 漢字フォント生成

**目的**: LED Board の LED ドットマトリクス用に、漢字を 16×16 ドット行列（16進数形式）に変換する Claude API クライアント

**使用場面**: `/font-generator` でカスタム漢字フォント実装を進める際に、API 統合のテンプレートとして活用

---

## スキル仕様

### 提供機能

1. **Claude API 初期化**
   - `ANTHROPIC_API_KEY` から自動認証
   - リトライロジック（失敗時 3 回まで）
   - タイムアウト管理（30 秒）

2. **プロンプト生成**
   - 漢字 1 文字を JSON スキーマ出力で 16×16 hex 行列に変換
   - 構造化出力形式で確実な解析
   - 複数文字バッチ処理対応

3. **出力パース**
   - hex 文字列配列への自動変換
   - バリデーション（16 行×4 文字/行）
   - エラー時の詳細メッセージ

4. **エラーハンドリング**
   - API 呼び出し失敗 → リトライ
   - JSON パース失敗 → 詳細ログ
   - 無効な Unicode → グレースフルフォールバック

---

## API インターフェース

### `generateKanjiGlyph(char: string): Promise<string[]>`

**入力**: Unicode 1文字（例: `"漢"`, `"字"`, `"テ"`）

**出力**: 16 行の hex 文字列配列
```javascript
[
  "0000",  // row 0: 全て白（0000 = 0000 0000 0000 0000）
  "7FFE",  // row 1: 1111 1111 1111 1110 (黒枠)
  ...
  "0000"   // row 15
]
```

**例**:
```typescript
const glyph = await generateKanjiGlyph("漢");
// ["0000", "7FFE", ..., "0000"]
```

### `generateBatchGlyphs(text: string): Promise<Record<string, string[]>>`

**入力**: 複数文字（例: `"複数文字"`）

**出力**: 文字ごとのグリフ辞書
```javascript
{
  "複": ["0000", "7FFE", ..., "0000"],
  "数": ["0000", "7FFC", ..., "0000"],
  "文": ["0000", "3FFE", ..., "0000"],
  "字": ["0000", "7FFE", ..., "0000"]
}
```

### `validateGlyph(rows: string[]): boolean`

**入力**: hex 行列

**出力**: 形式が正しいか判定（16 行、各 4 文字の hex）

---

## 実装ガイドライン

### 1. Claude API 呼び出し

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

async function generateKanjiGlyph(char: string): Promise<string[]> {
  const message = await client.messages.create({
    model: "claude-opus-4-7",
    max_tokens: 500,
    messages: [
      {
        role: "user",
        content: `
漢字「${char}」を 16×16 ドット行列（16進数形式）で表現してください。

要件:
- 16行、各行4文字の16進数 (0-F)
- 1 = 黒（LED点灯）, 0 = 白（消灯）
- 左上から右下へ、行ごとに出力

JSON 形式で返してください:
{
  "char": "${char}",
  "rows": ["0000", "7FFE", ...]
}
`,
      },
    ],
  });
  
  // パース処理...
}
```

### 2. リトライロジック

```typescript
async function callWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3
): Promise<T> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      const delay = Math.pow(2, i) * 1000; // 指数バックオフ
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  throw new Error("Max retries exceeded");
}
```

### 3. バッチ処理での効率化

```typescript
async function generateBatchGlyphs(text: string): Promise<Record<string, string[]>> {
  const chars = [...new Set(text)]; // 重複除去
  const results: Record<string, string[]> = {};
  
  for (const char of chars) {
    results[char] = await generateKanjiGlyph(char);
  }
  
  return results;
}
```

### 4. エラーハンドリング

```typescript
class FontGenerationError extends Error {
  constructor(
    public char: string,
    public reason: "api_error" | "parse_error" | "validation_error",
    message: string
  ) {
    super(`[${char}] ${reason}: ${message}`);
  }
}
```

---

## 統合パターン

### LED Board dev-server.ts での使用

```typescript
import { generateBatchGlyphs, validateGlyph } from "../font-generator";
import { batchSaveGlyphs } from "../font-db";

// POST /api/font-generate
if (url.pathname === "/api/font-generate") {
  let body = "";
  req.on("data", chunk => (body += chunk));
  req.on("end", async () => {
    try {
      const { text } = JSON.parse(body);
      const glyphs = await generateBatchGlyphs(text);
      
      // DB に保存
      await batchSaveGlyphs(glyphs, "kanji16");
      
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ ok: true, glyphs, generated: Object.keys(glyphs).length }));
    } catch (error) {
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ ok: false, error: error.message }));
    }
  });
}
```

---

## 環境変数

`.env` に以下を追加:
```
ANTHROPIC_API_KEY=sk-ant-v0-xxx...
```

---

## テスト例

```bash
# 1文字生成
curl -X POST http://localhost:8080/api/font-generate \
  -H "Content-Type: application/json" \
  -d '{"text": "漢", "format": "json16"}'

# 複数文字バッチ
curl -X POST http://localhost:8080/api/font-generate \
  -H "Content-Type: application/json" \
  -d '{"text": "漢字フォント", "format": "json16"}'

# レスポンス例
{
  "ok": true,
  "glyphs": {
    "漢": ["0000", "7FFE", ..., "0000"],
    "字": ["0000", "7FFC", ..., "0000"],
    "フ": ["0000", "3FFE", ..., "0000"],
    "ォ": ["0000", "7FFC", ..., "0000"],
    "ン": ["0000", "7FFE", ..., "0000"],
    "ト": ["0000", "3FFC", ..., "0000"]
  },
  "generated": 6
}
```

---

## パフォーマンス

- **単文字**: ~2 秒（API レイテンシ）
- **複数文字**: キャッシュあれば即座、新規は文字数 × 2 秒
- **DB キャッシュ**: 2 回目以降はミリ秒単位

---

## トラブルシューティング

| 問題 | 原因 | 解決方法 |
|------|------|--------|
| `401 Unauthorized` | ANTHROPIC_API_KEY 未設定 | `.env` に API キー追加 |
| `JSON parse error` | Claude 出力が JSON でない | プロンプト修正、モデル再選択 |
| `16 行未満の出力` | Claude の出力不完全 | リトライロジックが発動、3 回まで試行 |
| `Timeout` | API が 30 秒以上応答なし | ネットワーク確認、モデル確認 |

---

## 関連ファイル

- `src/font-db.ts` - Database access layer
- `src/dev-server.ts` - API endpoint host
- `src/json-font-loader.ts` - Font runtime loader
- `data/kanji-sample.json` - JSON font format reference
