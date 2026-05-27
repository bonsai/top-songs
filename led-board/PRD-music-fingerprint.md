# PRD: 音楽認識（音声 fingerprint）— 方式A
> 参照: `../melon-sound/PRD-audio-intelligence.md`（3機能統合PRD）

## 概要

PCのスピーカー出力をループバック録音し、Shazamライクなfingerprint方式で曲名を特定。ローカル完結。

## 音声キャプチャ

| OS | 経路 |
|---|---|
| Windows | WASAPI ループバック / Stereo Mix |
| macOS | BlackHole / Soundflower |
| Linux | PulseAudio モニター / PipeWire |

- 形式: 16kHz モノラル PCM
- 常時録音バッファ: 直近5〜10秒をリングバッファ

## fingerprint 抽出

1. STFT（16kHz, ハミング窓, 1024サンプル, 50% オーバーラップ）
2. スペクトログラムのピーク検出（局所極大、振幅フィルタ、密度制御）
3. アンカーピーク + target zone内ピークのペアで 32-bit ハッシュ生成
   - `anchor_freq(10bit) | target_freq(10bit) | time_delta(12bit)`

## DB / マッチング

- DB: SQLite + インメモリハッシュテーブル（キー=32-bit ハッシュ, 値=[曲ID, オフセット時間]）
- マッチ: 時間オフセット差のヒストグラム → ピークが一定以上で一致判定
- 未登録曲: 「🎵 ???」表示、ユーザーが曲名を入力すると次回から認識

## LED Board 連携

```bash
curl -X POST http://localhost:8080/api/message -d "text=🎵 曲名 - アーティスト"
```

## 非機能要件

- 認識レイテンシ: 3秒以内
- CPU: 常時 10% 以下
- メモリ: 200MB 以下（DB除く）
- オフライン: 完全オフライン

## 実装計画

| Phase | 内容 | 言語 / OSS |
|---|---|---|
| 1 | 録音 + 抽出 + 簡易マッチ | Python / `Audio-Fingerprint` or `dejavu` |
| 2 | DB拡張 + 調整 + Board連携 | Python + Flask |
| 3 | 常駐デーモン化 + 最適化 | Rust / `audiofp` |
