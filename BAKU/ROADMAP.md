# ランダム単語ショートショート生成 — ロードマップ

## 概要
複数のテキストリストからランダムに単語を選び、3つのテーマでショートショート（短編）を自動生成。
Python MCP経由でAPI連携。

---

## Phase 1: 基盤構築 ✅ 完了
### 1.1 言語ソース（単語リスト） ✅
- [x] `MEGA/SEKAI/baku/word_pools/` 作成
  - `nouns.txt`（名詞 20語）
  - `verbs.txt`（動詞 15語）
  - `adjectives.txt`（形容詞 14語）
  - `settings.txt`（場面） — 未作成
  - `emotions.txt`（感情） — 未作成

### 1.2 プロジェクト構造
```
【コード】MEGA/MCP/clips/
├── baku.asd                  # ASDFシステム定義
├── src/
│   ├── config.lisp           # 設定モジュール
│   ├── word-pool.lisp        # 単語プール管理
│   ├── mcp-connector.lisp    # MCP接続
│   ├── story-generator.lisp  # ストーリー生成
│   └── main.lisp             # CLIエントリーポイント
└── scripts/                  # Python（別担当）
    └── story_generator.py

【言語ソース】MEGA/SEKAI/baku/
├── word_pools/
│   ├── nouns.txt
│   ├── verbs.txt
│   ├── adjectives.txt
│   ├── settings.txt（未作成）
│   └── emotions.txt（未作成）
└── output/                   # 生成されたストーリー保存先
```

### 1.3 依存関係
- [x] SBCL 2.6.3（Common Lisp）
- [ ] Python 3.10+（別担当）
- [ ] `openai`, `requests`, `pyyaml`（Python側）
- [ ] MCPサーバー接続設定

---

## Phase 2: コアコンポーネント
### 2.1 単語選択モジュール（Lisp完了 / Python未実装）
- [x] 複数単語リスト読み込み
- [x] ランダム選択（重複なし）
- [x] カテゴリ別管理
- [ ] 重み付き確率（任意）

### 2.2 MCP接続モジュール（Lisp骨組 / Python未実装）
- [ ] MCPプロトコル実装
- [ ] 認証・再接続処理
- [ ] エラーハンドリング・リトライ

### 2.3 プロンプトテンプレート
```
以下の〜Dつのテーマでショートショートを書いてください：
テーマ1: 〜A
テーマ2: 〜A
テーマ3: 〜A

スタイル: ショートショート（-flash fiction）
文字数: 400-800字
言語: 日本語
トーン: 文学的、叙情的
```

---

## Phase 3: ストーリー生成
### 3.1 API統合
- [ ] MCP経由でLLMに送信
- [ ] レスポンス受信・パース
- [ ] `output/` に保存（タイムスタンプ付）

### 3.2 メインフロー
```
1. 単語プール読み込み
2. ランダム単語選択（3テーマ）
3. プロンプト構築
4. MCP経由でAPI送信
5. ストーリー受信
6. ファイル保存
```

---

## Phase 4: 機能拡張
### 4.1 定期実行（スケジュール）
- [ ] `--schedule` オプション追加
  - `--schedule hourly`（毎時）
  - `--schedule daily`（毎日）
  - `--schedule cron "0 9 * * *"`（cron指定）
- [ ] バックグラウンド実行モード
- [ ] 生成履歴の自動バックアップ

### 4.1 単語リスト自動生成（pool-generator.lisp）
- [x] SEKAIディレクトリ内テキストファイルスキャン
- [x] 単語抽出（日本語文字判定、長さフィルタ）
- [x] カテゴリ分類（名詞/動詞/形容詞 簡易ヒューリスティック）
- [x] 単語リストファイル自動生成
- [ ] 品質フィルタ（頻出度チェック）
- [ ] 手動キュレーションモード

### 4.2 定期実行スケジュール
- [ ] `--schedule` オプション
  - `--schedule hourly`（毎時）
  - `--schedule daily`（毎日）
  - `--schedule cron "0 9 * * *"`（cron指定）
- [ ] バックグラウンド実行
- [ ] 生成履歴バックアップ

### 4.3 CLIインターフェース
- [ ] `--themes 3`（テーマ数）
- [ ] `--genre SF`（ジャンル指定）
- [ ] `--output custom.txt`（出力ファイル指定）
- [ ] `--batch 5`（一括生成）
- [ ] `--scan-pool`（SEKAIスキャン→単語リスト生成）

### 4.4 MCPスキル統合
- [ ] `.skill`定義ファイル作成
- [ ] Qwen Codeスキル登録
- [ ] トリガー: 「ショートショート生成」「爆して」

---

## Phase 5: テスト・デプロイ
### 5.1 テスト
- [ ] 単語選択の単体テスト
- [ ] MCP接続テスト
- [ ] APIレスポンス検証
- [ ] エッジケース（空プール、APIエラー）

### 5.2 ドキュメント
- [ ] セットアップ手順
- [ ] 使用例
- [ ] トラブルシューティング

### 5.3 統合テスト
- [ ] ローカルLLM（Qwen3 8B via MCP）
- [ ] クラウドAPI
- [ ] 定期実行動作確認

---

## クイックスタート

### 単一生成
```bash
sbcl --load src/main.lisp
# または
sbcl --eval "(asdf:load-system :baku)" --eval "(baku-main:run)"
```

### バッチ生成（5件）
```lisp
* (baku-main:run :batch-count 5)
```

### 定期実行（今後実装）
```lisp
* (baku-scheduler:start-scheduler :interval 3600)  ;; 1時間ごと
```

---

## APIオプション

| オプション | 説明 | 設定必要 |
|-----------|------|---------|
| **ローカルLLM（MCP）** | Qwen3 8B via MCP | MCPサーバー設定 |
| **OpenAI API** | GPT-4/GPT-3.5 | APIキー |
| **Anthropic** | Claude | APIキー |
| **カスタム** | 任意エンドポイント | 独自設定 |

---

## 進捗状況

| フェーズ | 優先度 | 状態 |
|---------|--------|------|
| Phase 1: 基盤構築 | 高 | ✅ 完了（コード配置） |
| Phase 2: コアコンポーネント | 高 | 🟡 Lisp骨組完了 / Python未実装 |
| Phase 3: ストーリー生成 | 高 | ⬜ 未着手 |
| Phase 4: 機能拡張 | 中 | ⬜ 未着手 |
| Phase 5: テスト | 中 | ⬜ 未着手 |

---

## 次のステップ
1. **単語リスト追加**（settings.txt, emotions.txt） — SEKAI/baku/word_pools/
2. **Python MCPコネクタ実装** — 別担当
3. **API接続テスト** — ローカルLLM優先

---

*作成日: 2026-04-12*
*最終更新: 2026-04-12*
*状態: Phase 1 完了 / Phase 2 進行中*
