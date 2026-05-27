# OSS 漢字ドットフォント調査 — LED Board インポート用

## 概要

LED Board プロジェクトで漢字を LED ドットマトリクス表示するための OSS ビットマップフォントを調査。
BDF 形式のフォントを JSON に変換し `dot-font.ts` 相当のデータとして利用する。

---

## 調査結果一覧

| プロジェクト | 形式 | サイズ | 文字数 | ライセンス | JSON変換 | 推奨 |
|---|---|---|---|---|---|---|
| **jiskan16** (BDF) | BDF | 16×16 | JIS第1〜第4水準 (約6,400字) | パブリックドメイン相当 | ◯ 容易 | ★★★ |
| **Shinonome** | BDF/PCF | 14×14 / 16×16 | JIS第1〜第2水準 (約6,400字) | パブリックドメイン | ◯ 容易 | ★★★ |
| **JF-Dot-jiskan16** | WOFF2 | 16×16 | JIS第1〜第2水準 | OFL | △ 変換必要 | ★★ |
| **Misaki Gothic** | TTF/BDF | 8×8 / 8×8 | JIS第1〜第2 + 機種依存 | パブリックドメイン | ◯ 容易 | ★★ |
| **bdf2json** ツール | — | 可変 | — | — | ◯ | — |
| **getbitmapfont.sh** | シェルスクリプト | 任意 | JIS漢字 | — | △ | ★ |

---

## 各プロジェクト詳細

### 1. jiskan16 (JIS Kanji 16-dot)

| 項目 | 内容 |
|---|---|
| **URL** | https://github.com/hohno-46466/uZone--tools--getbitmapfont |
| **フォントファイル** | `fonts/jiskan16.bdf` (1.1MB) |
| **形式** | BDF (Glyph Bitmap Distribution Format) |
| **サイズ** | 16×16 ドット |
| **収録文字** | JIS X 0208 全漢字 (第1〜第4水準) |
| **ライセンス** | パブリックドメイン |
| **特徴** | 最も標準的な16ドット日本語ビットマップフォント。X11 標準。 |

**JSON変換**: BDF はテキストベースでパース可能。各文字のビットマップが16進数で記述されている。

```
STARTCHAR 亜
ENCODING 9248
SWIDTH 1000 0
DWIDTH 16 0
BBX 16 16 0 -2
BITMAP
0000
0000
0000
0000
0000
0000
0000
0000
0000
0180
0180
3186
6F6C
4F2C
3FFC
0180
ENDCHAR
```

### 2. Shinonome フォント

| 項目 | 内容 |
|---|---|
| **URL** | https://github.com/shinonome-fonts/shinonome-fonts (ミラー) |
| **オリジナル** | http://openlab.ring.gr.jp/efont/shinonome/ |
| **形式** | BDF / PCF |
| **サイズ** | 14×14 / 16×16 |
| **収録文字** | JIS X 0208 漢字 (約6,400字) |
| **ライセンス** | パブリックドメイン |
| **特徴** | 14ドットは小さいLEDマトリクスに最適。高品質。 |

### 3. JF-Dot-jiskan16

| 項目 | 内容 |
|---|---|
| **URL** | https://github.com/jpadgett314/led-matrix-vocab |
| **フォントファイル** | `public/fonts/JF-Dot-jiskan16-1990.woff2` |
| **形式** | WOFF2 (Web Open Font Format) |
| **サイズ** | 16×16 |
| **収録文字** | JIS第1〜第2水準 |
| **ライセンス** | OFL (SIL Open Font License) |
| **特徴** | Framework 16 LED Matrix で日本語単語を表示するプロジェクトで使用。 |

### 4. Misaki Gothic (美咲ゴシック)

| 項目 | 内容 |
|---|---|
| **URL** | https://github.com/kjunichi/fontsv で使用 (fontsv/misaki_gothic.ttf) |
| **オリジナル** | https://github.com/topics/misaki-font |
| **形式** | TTF (TrueType) / BDF |
| **サイズ** | 8×8 |
| **収録文字** | JIS第1〜第2 + 機種依存文字 |
| **ライセンス** | パブリックドメイン |
| **特徴** | 8×8は小さいが、Arduino UNO R4 LEDマトリクス向けに使われている。 |

### 5. Pixelix TomThumb

| 項目 | 内容 |
|---|---|
| **URL** | https://github.com/bonsai/Pixelix |
| **形式** | 独自テキスト形式 |
| **サイズ** | 3×5 |
| **収録文字** | ASCIIのみ |
| **ライセンス** | MIT |
| **特徴** | 既に `pixelix-font.ts` として導入済み。漢字非対応。 |

---

## JSON フォーマット仕様

BDF やその他のビットマップフォントから LED Board にインポートするための統一 JSON フォーマット。

### 形式

```json
{
  "format": "led-board-bitmap-font",
  "version": 1,
  "metadata": {
    "name": "jiskan16",
    "source": "https://github.com/hohno-46466/uZone--tools--getbitmapfont",
    "license": "Public Domain",
    "width": 16,
    "height": 16,
    "description": "JIS Kanji 16x16 dot bitmap font"
  },
  "glyphs": {
    "亜": ["0000","0000","0000","0000","0180","0180","3186","6F6C","4F2C","3FFC","0180","0000","0000","0000","0000","0000"],
    "一": ["0000","0000","0000","0000","0000","0000","7FFE","0000","0000","0000","0000","0000","0000","0000","0000","0000"],
    ...
  }
}
```

- `glyphs` のキー = 文字 (UTF-8)
- 値 = 16進数文字列の配列 (各行1つ)
- 各16進数文字列 = 1行分のドットパターン (1ビット=1ドット)

### 5×7 互換拡張

既存の `dot-font.ts` 互換フォーマットも用意:

```json
{
  "format": "led-board-bitmap-font-5x7",
  "version": 1,
  "glyphs": {
    "一": ["     ","     ","#####","     ","     ","     ","     "]
  }
}
```

---

## 変換パイプライン

```
BDF/PCF/TTF フォント
       ↓
  bdf2json.ts (コンバーター)
       ↓
  data/kanji-16x16.json  (16×16 データ)
       ↓
  JSONローダー (loadFontFromJson)
       ↓
  dot-font.ts 互換関数 (renderTextFromJson)
```

### bdf2json.ts

BDF ファイルをパースして JSON に変換する CLI ツール。

```bash
npx tsx src/bdf2json.ts fonts/jiskan16.bdf -o data/kanji-16x16.json
```

---

## 対応方法

### 方法 A: 16×16 高精細フォント (推奨)

1. jiskan16.bdf から JSON に変換
2. 現在の 5×7 に加えて 16×16 モードを追加
3. 漢字は 16×16、それ以外は 5×7 のハイブリッド動作

### 方法 B: 5×7 データ充填 (現状維持)

現在の 5×7 KANJI テーブルの質が低いため、jiskan16 から 5×7 にダウンスケールして再生成。

### 方法 C: Misaki 8×8 採用

一番小さいマトリクス (3×5, 5×7 に次ぐ) として 8×8 モード追加。
Misaki Gothic のビットマップデータを JSON に変換。

---

## 参考リンク

| リソース | URL |
|---|---|
| getbitmapfont | https://github.com/hohno-46466/uZone--tools--getbitmapfont |
| led-matrix-vocab | https://github.com/jpadgett314/led-matrix-vocab |
| fontsv | https://github.com/kjunichi/fontsv |
| Pixelix | https://github.com/bonsai/Pixelix |
| Shinonome 公式 | http://openlab.ring.gr.jp/efont/shinonome/ |
| BDF 仕様 | https://www.adobe.com/content/dam/acom/en/devnet/font/pdfs/5005.BDF_Spec.pdf |
