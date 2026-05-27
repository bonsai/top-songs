# Kanban Board

## To Do

### Server Mode
- [ ] POST /api/message 統一 (JSON) — 全サービスの入力口
- [ ] メッセージキュー + priority 制御
- [ ] GET /api/health
- [ ] MIDI→楽譜 表示モード

### Static Mode
- [ ] URL hash 入力: `index.html#Hello`
- [ ] localStorage 連携: 別タブから入力
- [ ] テキストボックス手動入力
- [ ] 1 HTML file で完結

### Refactoring (Phase 1)
- [ ] 重複UI削除 (LedBoardPage.tsx削除)
- [ ] dev-server.ts モジュール分割
- [ ] 型定義追加

### Refactoring (Phase 2)
- [ ] 設定管理集約 (config.ts)
- [ ] エラーハンドリング標準化
- [ ] APIエンドポイント統一

### Refactoring (Phase 4)
- [ ] Lite版作成 (led-board-lite/index.html)

### Event Mode
- [ ] 入力用ページ作成 (input.html)
- [ ] イベントモード切替
- [ ] 履歴保存（Supabase）
- [ ] QRコード生成
- [ ] 絵文字ピッカー
- [ ] 寄せ書きモード（非リアルタイム）
- [ ] メッセージキュー実装
- [ ] IPレート制限
- [ ] V2課金機能

---

## In Progress

なし

---

## Done

### Server Mode
- [x] DEMO / NEWS / LISTEN ボタン (index.html)
- [x] カラー / Size / Glow / Matrix / Speed 設定
- [x] SSE ストリーム
- [x] CSV ログ
- [x] WASM fingerprint ロード（melon-sound/music-id）

### Documentation
- [x] ADR-001-message-delivery.md
- [x] ADR-001-music-identification.md
- [x] ADR-002-architecture-split.md
- [x] PRD-music-fingerprint.md
- [x] PRD.md
- [x] REFACTORING_PLAN.md
- [x] DESIGN_PRINCIPLES.md
- [x] kanban.md
