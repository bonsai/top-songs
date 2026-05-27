# 理想的なディレクトリ構造

```
led-board/
├── .env.example
├── .gitignore
├── package.json
├── package-lock.json
├── tsconfig.json
├── vercel.json
│
├── README.md
├── TODO.md
├── kanban.md
├── PRD.md
├── DESIGN_PRINCIPLES.md
├── REFACTORING_PLAN.md
│
├── ADR/
│   ├── ADR-001-message-delivery.md
│   ├── ADR-001-music-identification.md
│   └── ADR-002-architecture-split.md
│
├── src/
│   ├── config.ts                 # 設定管理
│   ├── types.ts                  # 共通型定義
│   │
│   ├── server/
│   │   ├── index.ts              # メインHTTPサーバー
│   │   ├── middleware/
│   │   │   ├── cors.ts
│   │   │   └── errorHandler.ts
│   │   │
│   │   ├── api/
│   │   │   ├── message.ts        # POST /api/message
│   │   │   ├── events.ts         # SSE /api/events
│   │   │   ├── news.ts           # News proxy
│   │   │   ├── listen.ts         # Music fingerprinting
│   │   │   ├── health.ts         # GET /api/health
│   │   │   └── log.ts            # CSV logging
│   │   │
│   │   ├── services/
│   │   │   ├── sse.ts            # SSE管理
│   │   │   ├── logger.ts         # CSVログ
│   │   │   ├── supabase.ts       # Supabase連携
│   │   │   └── news-proxy.ts     # Newsサーバー連携
│   │   │
│   │   └── wasm/
│   │       └── fingerprint.ts    # WASM fingerprinting
│   │
│   ├── dev-server.ts             # エントリーポイント
│   ├── cli.ts                    # CLIツール
│   ├── dot-font.ts               # 5×7フォント
│   └── pixelix-font.ts           # 3×5フォント
│
├── api/
│   └── message.js                # Vercel serverless function
│
├── index.html                    # Server Mode UI
├── supabase-schema.sql
│
├── data/
│   └── log.csv
│
└── led-board-lite/               # Static Mode
    └── index.html
```

## 構成のポイント

**責務分離**
- `server/api/`: HTTPエンドポイント
- `server/services/`: ビジネスロジック
- `server/middleware/`: 共通処理
- `server/wasm/`: WASM連携

**設定管理**
- `config.ts`: 環境変数 + デフォルト値
- `types.ts`: 共通型定義

**モード別**
- Server Mode: `src/` + `index.html`
- Static Mode: `led-board-lite/`
- Cloud: `api/message.js`
