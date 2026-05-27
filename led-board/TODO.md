# TODO: led-board — 表示板（server mode + static mode）

## アーキテクチャ

**led-board は POST /api/message 1 つで何からでもメッセージを受け付ける表示板。**

melon-sound / jacket-eye / news-server / AI / curl — すべて同じ API で連携。
サービス同士の依存はゼロ。

## モード

| モード | 起動 | 機能 |
|---|---|---|
| server mode | `npm run dev` | HTTP API + SSE + 全UI |
| static mode | `led-board.html` を開く | サーバー不要、URL/localStorage 入力 |

## server mode タスク

- [x] DEMO / NEWS / LISTEN ボタン (index.html)
- [x] カラー / Size / Glow / Matrix / Speed 設定
- [x] SSE ストリーム
- [x] CSV ログ
- [x] WASM fingerprint ロード（melon-sound/music-id）
- [ ] POST /api/message 統一 (JSON) — 全サービスの入力口
- [ ] メッセージキュー + priority 制御
- [ ] GET /api/health
- [ ] MIDI→楽譜 表示モード

## static mode タスク

- [ ] URL hash 入力: `index.html#Hello`
- [ ] localStorage 連携: 別タブから入力
- [ ] テキストボックス手動入力
- [ ] 1 HTML file で完結
