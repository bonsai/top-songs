# BAKU プロセスフロー

> 獏は言葉を食べて 夢を見えさす。

---

## ⚠️ 注意: 新アーキテクチャ

**本プロセスフローは参考資料です。** 本番はGo製MCPサーバー (`MEGA/MCP/baku-mcp/`) を使用してください。

- **Phase A-C**: `baku-mcp` が SBCL経由で実行（単語選択）
- **Phase D (MCP通信)**: **オフライン時は不要**。Goテンプレートで生成完了
- **Phase D (LLM接続)**: **星 (hoshi)** が担当。`yao` 経由で port 8081 に接続
- 詳細: `MEGA/MCP/adr-baku-lisp-wrapper.md`

---

## システム概要

```
┌─────────────────────────────────────────────────────────────┐
│                        BAKU（爆）                           │
│          ランダム単語 → SFショートショート生成               │
└──────────────┬──────────────────────┬───────────────────────┘
               │                      │
        【言語ソース】            【コード】
    MEGA/SEKAI/baku/         MEGA/MCP/clips/
    └─ word_pools/           └─ src/*.lisp
                             └─ scripts/*.py
```

---

## プロセス全体像

```
┌─────────────┐
│  Phase A    │  単語リスト準備
│  PREPARE    │  （手動 or 自動生成）
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Phase B    │  ランダム単語選択
│  SELECT     │  （3テーマ抽出）
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Phase C    │  プロンプト構築
│  PROMPT     │  （テンプレート適用）
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Phase D    │  MCP通信
│  CONNECT    │  （Python → LLM API）
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Phase E    │  ストーリー生成
│  GENERATE   │  （LLM応答受信）
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Phase F    │  保存・出力
│  SAVE       │  （output/ に記録）
└─────────────┘
```

---

## Phase A: 単語リスト準備

### A-1: 手動登録
```
word_pools/*.txt に直接追記
```

### A-2: SEKAI自動スキャン
```
1. MEGA/SEKAI/ 内テキストファイル再帰スキャン
2. 日本語文字（ひらがな・カタカナ・漢字）抽出
3. 簡易ヒューリスティックでカテゴリ分類
   ├─ 名詞（デフォルト）
   ├─ 動詞（〜る/〜う/〜す 等）
   └─ 形容詞（〜い/〜な）
4. word_pools/generated/YYYYMMDD_HHMMSS/ に保存
```

**モジュール:** `pool-generator.lisp`

---

## Phase B: ランダム単語選択

```
入力: word_pools/ 配下の .txt ファイル
処理:
  1. 各カテゴリからファイル読み込み
  2. 重複なしランダム選択
     ├─ 名詞: 3語
     ├─ 動詞: 2語
     └─ 形容詞: 1語
  3. 選択テーマ配列生成

出力: ("月" "鏡" "夢" "巡る" "忘れる" "透明な")
```

**モジュール:** `word-pool.lisp`

---

## Phase C: プロンプト構築

```
入力: 選択テーマ配列
テンプレート適用:
  "以下の{N}つのテーマでショートショートを書いてください：
   テーマ1: {word1}
   テーマ2: {word2}
   ...
   
   スタイル: SFショートショート（星新一風）
   文字数: 400-800字
   言語: 日本語
   トーン: 知的、意外性のある結末"

出力: 完成プロンプト文字列
```

**モジュール:** `story-generator.lisp`

---

## Phase D: MCP通信

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   BAKU       │ ──────▶ │   Python     │ ──────▶ │   LLM API    │
│   (Lisp)     │  stdin  │   MCP        │  HTTP   │   (Qwen3)    │
│              │ ◀────── │   Connector  │ ◀────── │              │
└──────────────┘  stdout └──────────────┘         └──────────────┘

処理:
  1. Python MCPコネクタ起動（subprocess）
  2. プロンプトを stdin に送信
  3. Python → LLM API に HTTP リクエスト
  4. レスポンス受信
  5. stdout で Lisp に返却
```

**モジュール:** `mcp-connector.lisp` + `scripts/story_generator.py`

---

## Phase E: ストーリー生成

```
入力: LLM API レスポンス
処理:
  1. レスポンスパース
  2. 文字数チェック（400-800字）
  3. 品質フィルタ（任意）
  4. メタデータ付与
     ├─ 生成日時
     ├─ 使用テーマ
     └─ カテゴリタグ

出力: 完成ストーリーオブジェクト
```

**モジュール:** `story-generator.lisp`

---

## Phase F: 保存・出力

```
出力パス: MEGA/SEKAI/baku/output/
ファイル名: story_YYYYMMDD_HHMMSS.txt

内容:
  === ショートショート（爆） ===
  生成日時: 20260412_143025
  使用テーマ: 月, 鏡, 夢, 巡る, 忘れる, 透明な
  
  [ストーリー本文]
```

**モジュール:** `story-generator.lisp`

---

## 定期実行プロセス

### スケジュール設定
```lisp
;; 1時間ごと
(baku-scheduler:start :interval 3600)

;; 毎日9時
(baku-scheduler:start :cron "0 9 * * *")

;; 明後日実行
(baku-scheduler:start :delay 172800)  ;; 48時間後
```

### 定期実行フロー
```
1. タイマー起動
2. Phase A-F 自動実行
3. output/ に保存
4. 実行ログ記録
5. エラー時はリトライ（最大3回）
```

---

## エラーハンドリング

| エラー | 対応 |
|-------|------|
| 単語プール空 | デフォルト単語で補完 |
| MCP接続失敗 | 3回リトライ → ローカル生成にフォールバック |
| APIタイムアウト | タイマー延長（最大60秒） |
| ファイル保存失敗 | エラーログ記録 → 次回リトライ |

---

## 依存関係図

```
main.lisp
  ├── config.lisp
  ├── word-pool.lisp ─── config.lisp
  ├── mcp-connector.lisp ─── config.lisp
  ├── story-generator.lisp ─── config.lisp
  │                        ├── word-pool.lisp
  │                        └── mcp-connector.lisp
  └── pool-generator.lisp ─── config.lisp
```

---

*獏は言葉を食べて 夢を見えさす。*
