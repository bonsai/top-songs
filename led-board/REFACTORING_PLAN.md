# コードベース分析と再構築計画

## 現状分析

### プロジェクト概要
- **led-board**: LED表示板システム（メッセージ表示、リアルタイム配信、音楽認識、ニュース表示）
- **技術スタック**: TypeScript, Node.js, Supabase, WASM（音楽fingerprinting）
- **アーキテクチャ**: モノリシックなdev-server.ts（482行）が複数の責務を担当

### 主要コンポーネント

| ファイル | 行数 | 役割 | 問題 |
|---------|------|------|------|
| `dev-server.ts` | 482 | メインサーバー | モノリス、複数責務 |
| `index.html` | 615 | フロントエンド | 単一ファイル、JS埋め込み |
| `LedBoardPage.tsx` | 266 | React UI | 重複実装、未使用？ |
| `api/message.js` | 66 | Vercel API | クラウド連携 |
| `dot-font.ts` | 37,545 | フォントデータ | 巨大なデータファイル |

### 特定された問題

**1. モノリシックなdev-server.ts**
- HTTP API、SSE、WASM fingerprinting、CSVログ、News proxy、Supabase連携が1ファイル
- テスト困難、保守性低
- ADR-002で指摘済み（500行超過）

**2. 重複するUI実装**
- `index.html`（vanilla JS）と`LedBoardPage.tsx`（React）が共存
- 異なるAPIエンドポイント使用
- どちらが正解か不明

**3. 機能肥大化**
- コア: メッセージ表示 + SSE
- 追加: CSVログ、Supabase Realtime、RSSニュース、音楽fingerprinting
- 各機能が複雑性を増加

**4. 密結合**
- WASM fingerprintingがサーバーに直接埋め込み
- News proxyが密結合
- プラグインアーキテクチャなし

**5. 未完了機能（TODO.md）**
- POST /api/message 統一
- メッセージキュー + priority制御
- GET /api/health
- MIDI表示モード
- Static mode未実装

**6. コード品質**
- 責務分離なし
- エラーハンドリング不足
- WASM exportsの型安全性なし
- ハードコード値散在

---

## 再構築計画

### Phase 1: 緊急整理（優先度: 高）

**1.1 重複UIの整理**
- `LedBoardPage.tsx`を削除（index.htmlがメイン）
- React依存をpackage.jsonから削除
- 単一のUI実装に統一

**1.2 dev-server.tsのモジュール分割**
```
src/
├── server/
│   ├── index.ts           # メインHTTPサーバー
│   ├── api/
│   │   ├── message.ts     # POST /api/message
│   │   ├── events.ts     # SSE /api/events
│   │   ├── news.ts        # News proxy
│   │   ├── listen.ts      # Music fingerprinting
│   │   └── log.ts         # CSV logging
│   ├── services/
│   │   ├── sse.ts         # SSE管理
│   │   ├── logger.ts      # CSVログ
│   │   ├── supabase.ts    # Supabase連携
│   │   └── news-proxy.ts  # Newsサーバー連携
│   └── wasm/
│       └── fingerprint.ts # WASM fingerprinting
├── dev-server.ts          # エントリーポイント（簡素化）
├── cli.ts
├── dot-font.ts
└── pixelix-font.ts
```

**1.3 型定義の追加**
- WASM exports用の型定義
- APIリクエスト/レスポンス型
- 設定オブジェクト型

### Phase 2: コア機能の分離（優先度: 高）

**2.1 設定管理の集約**
```typescript
// src/config.ts
export const config = {
  port: parseInt(process.env.PORT ?? "8080"),
  supabaseUrl: process.env.SUPABASE_URL || "",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || "",
  newsServer: process.env.NEWS_SERVER || "http://localhost:8081",
  wasmPath: "...",
  // ...
};
```

**2.2 エラーハンドリングの標準化**
- 統一エラーレスポンス形式
- ロギング標準化
- APIエラー処理ミドルウェア

**2.3 APIエンドポイントの統一**
- POST /api/message をJSONのみに統一
- リクエストバリデーション追加
- レスポンス形式統一

### Phase 3: プラグイン化の検討（優先度: 中）

**ADR-002の選択肢B（プラグインアーキテクチャ）を再検討**
```
src/
├── core/              # コア機能のみ
│   ├── server.ts
│   ├── sse.ts
│   └── message.ts
├── plugins/
│   ├── news/          # RSSニュース
│   ├── listen/        # 音楽fingerprinting
│   ├── supabase/      # Supabase連携
│   └── logger/        # CSVログ
└── index.ts
```

**判断基準:**
- プラグイン数が3つ以上になったら実施
- 現状はNEWSとLISTENのみ → 見送り可

### Phase 4: Lite版の作成（優先度: 中）

**ADR-002の選択肢C（HTML-only Lite版）を実装**
```
led-board-lite/
└── index.html         # サーバー不要の単一HTMLファイル
```

**機能:**
- URL hash/queryパラメータでメッセージ受信
- localStorage連携
- 手動入力
- 表示機能のみ

### Phase 5: 未完了機能の実装（優先度: 低）

**5.1 メッセージキュー + priority制御**
- 優先度キュー実装
- FIFO + priority

**5.2 GET /api/health**
- ヘルスチェックエンドポイント
- WASM準備状態、Supabase接続状態等

**5.3 MIDI表示モード**
- MIDI入力 → 楽譜表示

**5.4 Static mode**
- index.htmlのhash/localStorage対応

---

## 実装順序

| Phase | タスク | 予測工数 | リスク |
|-------|-------|----------|--------|
| 1.1 | 重複UI削除 | 0.5h | 低 |
| 1.2 | dev-server.ts分割 | 4h | 中 |
| 1.3 | 型定義追加 | 1h | 低 |
| 2.1 | 設定管理集約 | 1h | 低 |
| 2.2 | エラーハンドリング | 2h | 低 |
| 2.3 | API統一 | 2h | 中 |
| 3 | プラグイン化検討 | - | 見送り可 |
| 4 | Lite版作成 | 3h | 低 |
| 5.1 | メッセージキュー | 3h | 中 |
| 5.2 | health endpoint | 0.5h | 低 |
| 5.3 | MIDIモード | 5h | 高 |
| 5.4 | Static mode | 2h | 低 |

**合計（Phase 1-2+4+5.2+5.4）: 約19時間**

---

## 推奨アクション

1. **即時実施**: Phase 1.1（重複UI削除）
2. **優先実施**: Phase 1.2, 1.3, 2.1, 2.2（コア品質向上）
3. **検討**: Phase 3（プラグイン化 - 機能追加時に再評価）
4. **オプション**: Phase 4, 5（Lite版と追加機能）
