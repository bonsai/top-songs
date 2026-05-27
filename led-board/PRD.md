# PRD: LED Board — 電光掲示板システム

## 概要

LED Boardは、外部からHTTP POSTでメッセージを受け取り、LEDドットマトリクス風にスクロール表示するシステム。ローカルネットワークおよびインターネット経由でリアルタイムにメッセージを配信可能。

### コアコンセプト

- **統一API**: POST /api/message 1つで全サービスからメッセージを受け付ける
- **サービス間依存ゼロ**: melon-sound / jacket-eye / news-server / AI / curl すべて同じAPIで連携
- **プッシュ型配信**: ポーリングなしで即座にメッセージを反映

---

## モード

| モード | 起動方法 | 機能 | 用途 |
|---|---|---|---|
| Server Mode | `npm run dev` | HTTP API + SSE + 全UI | Raspberry Pi / PCでの常時稼働 |
| Static Mode | `led-board.html` を開く | サーバー不要、URL/localStorage入力 | 手軽な表示、GitHub Pages等 |

---

## 機能要件

### 1. メッセージ表示（コア）

**入力方法**
- HTTP POST /api/message
  - JSON: `{"text": "メッセージ"}`
  - Form: `text=メッセージ`
- CLI: `npm run msg <message>`
- URL hash: `index.html#メッセージ`（Static Mode）
- localStorage: 別タブから入力（Static Mode）
- 手動入力: テキストボックス（UI）

**表示機能**
- LEDドットマトリクス風スクロール表示
- カラー選択（27色 + レインボー）
- サイズ調整（1-5）
- 光彩効果（OFF/LOW/MED/HIGH）
- マトリクス選択（3×5 / 5×7 / 5×9）
- スクロール速度（1-5）

### 2. リアルタイム配信（SSE）

**Server Mode**
- Server-Sent Events (SSE) でブラウザにプッシュ
- 同一LAN内でレイテンシ最小
- フォールバック: ポーリング（3秒間隔）

**クラウド経由（オプション）**
- Supabase Realtime WebSocketでプッシュ
- Vercel API → Supabase → LED Board
- インターネット越しに利用可能

### 3. CSVログ

**機能**
- 全メッセージをCSV形式で記録
- ファイル: `data/log.csv`
- フォーマット: `timestamp,message,source`
- GET /api/log で最新50件取得

### 4. ニュース表示（NEWSモード）

**機能**
- 外部news-serverと連携
- RSSフィードを自動取得
- ボタンで次のニュースに切り替え
- ユーザー入力で一時停止
- アイドル時（20秒）に自動復帰

**API**
- POST /api/news (action=start/stop/next)
- GET /api/news (ステータス取得)

### 5. 音楽認識（LISTENモード）

**機能**
- PCスピーカー出力をループバック録音
- WASM fingerprintで曲名を特定
- 認識結果をLED Boardに表示
- 未登録曲は「🎵 ???」表示

**API**
- POST /api/listen (action=start/stop)
- POST /api/listen/pcm (PCMデータ送信)
- POST /api/listen/register (曲登録)

**詳細**: `PRD-music-fingerprint.md` 参照

### 6. MIDI表示モード（未実装）

**機能**
- MIDI入力を受信
- 楽譜としてLED Boardに表示

### 7. ヘルスチェック（未実装）

**機能**
- GET /api/health
- WASM準備状態
- Supabase接続状態
- Newsサーバー接続状態

---

## 非機能要件

### パフォーマンス

| 項目 | 目標 |
|---|---|
| メッセージ反映遅延 | < 100ms（SSE） |
| 音楽認識レイテンシ | < 3秒 |
| CPU使用率 | < 10%（常時） |
| メモリ使用量 | < 200MB（DB除く） |

### 可用性

| 項目 | 目標 |
|---|---|
| サーバー稼働時間 | 24/7（Raspberry Pi） |
| SSE再接続 | 自動 |
| Supabaseフォールバック | ローカルSSE優先 |

### 互換性

| 項目 | 対応 |
|---|---|
| OS | Windows / macOS / Linux |
| ブラウザ | Chrome / Firefox / Safari / Edge |
| ネットワーク | LAN / インターネット |

### セキュリティ

| 項目 | 対応 |
|---|---|
| CORS | 全許可（ローカル利用前提） |
| 認証 | なし（ローカルネットワーク） |
| HTTPS | Vercelで対応 |

---

## API仕様

### POST /api/message

メッセージを送信

**リクエスト**
```json
{
  "text": "メッセージ"
}
```

または
```
text=メッセージ
```

**レスポンス**
```json
{
  "message": "メッセージ"
}
```

### GET /api/message

最新メッセージを取得

**レスポンス**
```json
{
  "message": "メッセージ"
}
```

### GET /api/events

SSEエンドポイント

**レスポンス**
```
data: {"message":"メッセージ"}
```

### POST /api/news

ニュースモード制御

**リクエスト**
```
action=start|stop|next
```

**レスポンス**
```json
{
  "newsMode": true,
  "count": 10,
  "current": 0,
  "items": [...]
}
```

### POST /api/listen

音楽認識モード制御

**リクエスト**
```
action=start|stop
```

**レスポンス**
```json
{
  "listenMode": true,
  "wasmReady": true,
  "songs": 5
}
```

### POST /api/listen/pcm

PCMデータ送信（バイナリ）

**リクエスト**
- Content-Type: application/octet-stream
- Body: Float32Array (44100Hz)

**レスポンス**
```json
{
  "match": true,
  "songId": 1,
  "songName": "曲名",
  "score": 100
}
```

### POST /api/log

ログ記録

**リクエスト**
```json
{
  "text": "メッセージ",
  "source": "demo"
}
```

**レスポンス**
```json
{
  "ok": true
}
```

### GET /api/log

ログ取得（最新50件）

**レスポンス**
```json
{
  "rows": [
    ["2024-01-01T00:00:00Z", "メッセージ", "source"],
    ...
  ]
}
```

---

## 技術スタック

### Server Mode

| レイヤー | 技術 |
|---|---|
| サーバー | Node.js + TypeScript |
| HTTP | httpモジュール |
| SSE | Server-Sent Events |
| データベース | Supabase（PostgreSQL） |
| 音楽認識 | Rust WASM |
| ログ | CSVファイル |

### Static Mode

| レイヤー | 技術 |
|---|---|
| フロントエンド | Vanilla JS + HTML5 Canvas |
| データ転送 | URL hash / localStorage |
| 配信 | GitHub Pages / Vercel / Netlify |

---

## デプロイ

### Server Mode

**ローカル**
```bash
npm run dev
```

**Raspberry Pi**
- PM2で常時稼働
- systemdサービス化

**クラウド（Vercel）**
- api/message.js をデプロイ
- Supabase Realtime連携

### Static Mode

**GitHub Pages**
- index.html をプッシュ

**Vercel / Netlify**
- index.html をデプロイ

---

## 開発ロードマップ

| Phase | 内容 | ステータス |
|---|---|---|
| 1 | コア機能（メッセージ表示 + SSE） | 完了 |
| 2 | CSVログ | 完了 |
| 3 | Supabase Realtime | 完了 |
| 4 | ニュース表示 | 完了 |
| 5 | 音楽認識（LISTEN） | 完了 |
| 6 | POST /api/message 統一 | 未 |
| 7 | メッセージキュー + priority | 未 |
| 8 | GET /api/health | 未 |
| 9 | MIDI表示モード | 未 |
| 10 | Static Mode | 未 |
| 11 | プラグインアーキテクチャ | 検討中 |

---

## 関連ドキュメント

- `ADR-001-message-delivery.md` — メッセージ配信アーキテクチャ
- `ADR-001-music-identification.md` — 音楽認識方式
- `ADR-002-architecture-split.md` — 機能肥大化対策
- `PRD-music-fingerprint.md` — 音楽認識詳細PRD
- `TODO.md` — 開発タスク
- `REFACTORING_PLAN.md` — 再構築計画
