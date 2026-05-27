# ADR-001: 音楽認識（Shazamライク）— ローカル音声識別
> 実装は `../melon-sound/music-id/` に移管
> 参照: `../melon-sound/ADR-003-audio-intelligence-platform.md`（3機能統合アーキテクチャ）

## ステータス
提案

## コンテキスト

LED Board に「今流れている曲名」を自動表示したい。
スマホの Shazam のように PC スピーカー出力を常時監視し、曲を特定する仕組みをローカルで完結させる。

要件：
- 完全オフライン動作（外部API不使用）
- キャプチャ〜認識まで 3 秒以内
- CPU / メモリはバックグラウンドで軽量
- 未登録曲は「不明」と表示し、後から教えると学習

## 決定

**方式A（音声 fingerprint）を第1候補とし、実装は段階的に進める。**

```
PC スピーカー出力
    ↓
ループバック録音（WASAPI / PulseAudio）
    ↓  リングバッファ（直近 5〜10 秒）
STFT → スペクトログラム
    ↓  ピーク検出
コンスタレーションマップ
    ↓  コンビナトリアルハッシュ
32-bit ハッシュ群
    ↓  ハッシュテーブル検索
候補曲リスト
    ↓  時間オフセット・ヒストグラム
スコアリング → 一致判定 → 曲名
```

### 第1層: 音声キャプチャ

| OS | 経路 | ライブラリ |
|---|---|---|
| Windows | WASAPI ループバック | `pyaudio` / `ffmpeg -f dshow` |
| macOS | BlackHole / Soundflower | `ffmpeg` |
| Linux | PulseAudio モニター / PipeWire | `pyaudio` / `ffmpeg` |

- フォーマット: 16kHz モノラル PCM（全アルゴリズムで標準化）
- バッファリング: リングバッファで直近 5〜10 秒を保持

### 第2層: fingerprint 抽出

Shazam（Avery Wang, 2003）のアルゴリズムに準拠：

1. **STFT**: 16kHz, ハミング窓, 1024サンプル, 50% オーバーラップ → 約 31fps
2. **ピーク検出**: 時間-周波数平面で局所極大。振幅で絞り、密度制御
3. **ハッシュ生成**: 各アンカーピークに対し target zone（+0.1〜1.0秒先）のピークとペア
   - 1ハッシュ = `anchor_freq(10bit) | target_freq(10bit) | time_delta(12bit)` = 32bit
   - fan-out 数（target zone内ペア数）= 10〜20 程度

### 第3層: DB / マッチング

- **DB**: SQLite + インメモリハッシュテーブル
  - キー: 32-bit ハッシュ値
  - 値: `[曲ID, 曲内オフセット時間]` のリスト
- **マッチ**: クエリハッシュを DB 検索 → 曲ID ごとに `オフセット差` のヒストグラム → ピーク検出
  - 条件: peak_count >= 5 かつ ヒストグラム値が 2位の 3倍以上
- **未登録曲**: 表示は「🎵 ???」、ユーザーが曲名を入力すると次回から認識

### 第4層: LED Board 連携

```bash
# 認識時
curl -X POST http://localhost:8080/api/message -d "text=🎵 曲名 - アーティスト"
# 未認識時
curl -X POST http://localhost:8080/api/message -d "text=🎵 ???"
```

## 代替案

### A. 音声 fingerprint（採用）
- Shazam と同一方式。ノイズに強く、サンプル長も数秒で十分
- 既存 OSS 実装が豊富（dejavu, Audio-Fingerprint, chromaprint, audiofp）

### B. アルバムジャケット画像認識（第2候補）
- スクリーンショット / drag & drop でジャケ写を送信
- ローカル VLM（LLaVA / Qwen-VL 等）でアーティスト名＋曲名を抽出
- 方式A よりレイテンシ大（VLM推論時間）で常時監視には不向き
- 方式A で不明だった場合の補助として併用を検討

### C. 音楽配信サービス API（却下）
- Spotify / Apple Music API を叩く方式
- オフライン要件に違反。外部依存が発生

## 結果

### メリット
- 完全オフライン、外部API不要
- 過去 OSS 実装多数でプロトタイピング容易
- 数秒のサンプルで認識可能、ノイズ耐性あり
- 半教師ありで徐々にDB充実

### デメリット
- DB 構築（既知曲の fingerprint 登録）に初期コスト
- 同一曲でも別ミックス / ライブ版は非対応（別 fingerprint）
- CPU 負荷は STFT + 検索時にある程度かかる

### 相違点
- Shazam と違い、1端末で完結（クラウド不要 = サーバー不要）
- 未知曲を対話的に追加できる（Shazam は不可能）
- fingerprinter の選定次第で精度と速度が大きく変わる

## 実装計画

| Phase | 内容 | 言語 / OSS |
|---|---|---|
| 1 | ループバック録音 + fingerprint 抽出 + 簡易マッチ | Python / `Audio-Fingerprint` or `dejavu` |
| 2 | DB 拡張 + 信頼度調整 + LED Board 連携 | Python + Flask |
| 3 | 常駐デーモン化 + パフォーマンス最適化 | Rust / `audiofp` |
| 4 | アルバムジャケット認識（方式B）連携 | Rust + VLM |
