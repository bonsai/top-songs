# ADR-001: 電光掲示板 メッセージ配信アーキテクチャ

## ステータス
提案

## コンテキスト

電光掲示板（LED Board）は以下の要件を持つ：

- **表示側**: ローカルネットワーク上のデバイス（Raspberry Pi, PC 等）で動作し、LED ドットマトリクスに文字を流す
- **入力側**: リモートから API 経由でメッセージを書き込む（スマホ・PC・curl）
- **経路**: テザリング（同一 LAN）またはインターネット経由（Vercel）
- **要求**: 書き込み後、表示側がポーリングなしで即座にメッセージを反映する（プッシュ型）

## 決定

**2層構成 + フォールバック** を採用する。

```
┌─────────────────────────────────────────────────┐
│  Layer 1: クラウド永続化 + リアルタイム配信       │
│                                                  │
│  クライアント → POST /api/message (Vercel)       │
│                   ↓                             │
│              Supabase (Broadcast) に書き込み      │
│                   ↓                             │
│              Supabase Realtime WebSocket 購読     │
│                   ↓                             │
│              LED Board 表示（即時反映）            │
│                                                  │
│  Layer 2: 直接 LAN プッシュ（テザリング高速 path） │
│                                                  │
│  クライアント → POST http://<LED-IP>:8080/api/msg│
│                   ↓                             │
│              Dev Server が受信                    │
│                   ↓                             │
│              Server-Sent Events でブラウザに配信  │
│                   ↓                             │
│              LED Board 表示（最速反映）            │
└─────────────────────────────────────────────────┘
```

### Layer 1: クラウド経由（インターネット越し）

- Vercel API は Supabase の `broadcast` チャンネルにメッセージを書き込む
- LED Board ブラウザは Supabase Realtime クライアントで `broadcast` を購読
- 新着メッセージは WebSocket 経由でプッシュ → ポーリング不要
- Vercel KV は使わない（KV には pub/sub 機構がなく、プッシュに不向き）

### Layer 2: 同一 LAN / テザリング（高速 path）

- 表示デバイスが http://localhost:8080 で Dev Server を起動
- 同一 LAN のクライアントは `http://<表示デバイスのIP>:8080/api/msg` に POST
- Dev Server は `EventSource` (SSE) で接続中のブラウザ全台に即時プッシュ
- クラウドを経由しないためレイテンシ最小、テザリング時に最適

### フォールバック動作

1. **ブラウザ起動時**: Layer 2 (SSE) に接続 → 失敗したら Layer 1 (Supabase) に購読
2. **両方失敗**: メッセージがない状態で静かに待機（表示はデフォルト or 消灯）
3. **再接続**: SSE 切断時は自動リトライ。Supabase も同様

## 代替案

### A. Vercel KV + ポーリング（却下）
- 最も単純だが、ユーザー要件によりポーリング不可
- 3 秒間隔でも 5 秒間隔でも表示までのラグと無駄なリクエストが発生

### B. Vercel KV + WebSocket Relay Server（却下）
- 常時起動の WebSocket サーバーが必要（Railway / Fly.io 等）
- Vercel サーバーレスとの親和性が低い。維持コストがかかる

### C. WebRTC (P2P)（却下）
- シグナリングサーバーが必要
- NAT 越えが不安定。テザリング環境ではオーバーキル

### D. ポーリングのみ（却下）
- ユーザーが「定期実行しないと？」と懸念し、プッシュを要求

### E. Firebase Realtime Database（検討済み）
- Supabase と同様にリアルタイム更新可能
- 今回は Supabase を採用（OSS、Vercel との相性が良い）

## 結果

### メリット
- ポーリングゼロ：書き込みから表示までの遅延が最小
- LAN 経路とクラウド経路の二重化により可用性が高い
- SSE の実装は軽量（Server-Sent Events、ブラウザ標準 API）
- Supabase Realtime は WebSocket ベースでブラウザ対応済み

### デメリット
- Supabase プロジェクト＋テーブルが必要（無料枠で十分）
- ブラウザ側に Supabase クライアントライブラリが必要
- テザリング専用なら Layer 2 だけで十分だが、汎用性のために Layer 1 も必要

### トレードオフ
- シンプルさを取るなら Layer 2（ローカル SSE）＋フォールバック無し
- 汎用性を取るなら Layer 1 + Layer 2 の 2 層構成
- 当面は Layer 2 のみ実装し、必要に応じて Layer 1 を追加する
