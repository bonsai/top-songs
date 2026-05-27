import pg from "pg";
const { Pool } = pg;

let pool: pg.Pool | null = null;

export function initFontDb(dbPool: pg.Pool): void {
  pool = dbPool;
}

export async function getGlyph(
  char: string,
  fontId: string = "kanji16"
): Promise<string[] | null> {
  if (!pool) throw new Error("Font DB not initialized");

  const result = await pool.query(
    "SELECT glyph_data FROM font_glyphs WHERE font_id = $1 AND character = $2",
    [fontId, char]
  );

  if (result.rows.length === 0) return null;

  const glyphData = result.rows[0].glyph_data;
  if (glyphData && Array.isArray(glyphData.rows)) {
    return glyphData.rows;
  }

  return null;
}

export async function saveGlyph(
  char: string,
  rows: string[],
  fontId: string = "kanji16",
  width: number = 16,
  height: number = 16
): Promise<void> {
  if (!pool) throw new Error("Font DB not initialized");

  await pool.query(
    `INSERT INTO font_glyphs (font_id, character, width, height, glyph_data)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (font_id, character) DO UPDATE SET
       glyph_data = EXCLUDED.glyph_data,
       updated_at = NOW()`,
    [fontId, char, width, height, JSON.stringify({ rows })]
  );
}

export async function batchSaveGlyphs(
  glyphs: Record<string, string[]>,
  fontId: string = "kanji16",
  width: number = 16,
  height: number = 16
): Promise<void> {
  if (!pool) throw new Error("Font DB not initialized");

  const chars = Object.keys(glyphs);
  if (chars.length === 0) return;

  const values = chars
    .map(
      (char, i) =>
        `($${i * 5 + 1}, $${i * 5 + 2}, $${i * 5 + 3}, $${i * 5 + 4}, $${
          i * 5 + 5
        })`
    )
    .join(",");

  const params: any[] = [];
  for (const char of chars) {
    params.push(fontId, char, width, height, JSON.stringify({ rows: glyphs[char] }));
  }

  await pool.query(
    `INSERT INTO font_glyphs (font_id, character, width, height, glyph_data)
     VALUES ${values}
     ON CONFLICT (font_id, character) DO UPDATE SET
       glyph_data = EXCLUDED.glyph_data`,
    params
  );
}

export async function getGlyphCount(fontId: string = "kanji16"): Promise<number> {
  if (!pool) throw new Error("Font DB not initialized");

  const result = await pool.query(
    "SELECT COUNT(*) as count FROM font_glyphs WHERE font_id = $1",
    [fontId]
  );

  return parseInt(result.rows[0].count, 10);
}

export async function getAllGlyphs(
  fontId: string = "kanji16"
): Promise<Record<string, string[]>> {
  if (!pool) throw new Error("Font DB not initialized");

  const result = await pool.query(
    "SELECT character, glyph_data FROM font_glyphs WHERE font_id = $1 ORDER BY character",
    [fontId]
  );

  const glyphs: Record<string, string[]> = {};
  for (const row of result.rows) {
    if (row.glyph_data && Array.isArray(row.glyph_data.rows)) {
      glyphs[row.character] = row.glyph_data.rows;
    }
  }

  return glyphs;
}
