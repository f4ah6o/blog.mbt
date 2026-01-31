-- Admin v0.2 migration: add status, allow NULL published_at, backfill updated_at
PRAGMA foreign_keys=off;

ALTER TABLE posts RENAME TO posts_old;

CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  excerpt TEXT,
  content TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft',
  published_at TEXT,
  updated_at TEXT NOT NULL
);

INSERT INTO posts (id, title, slug, excerpt, content, status, published_at, updated_at)
SELECT
  id,
  title,
  slug,
  excerpt,
  content,
  CASE
    WHEN NULLIF(published_at, '') IS NOT NULL THEN 'published'
    ELSE 'draft'
  END,
  NULLIF(published_at, ''),
  COALESCE(NULLIF(published_at, ''), strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
FROM posts_old;

DROP TABLE posts_old;
PRAGMA foreign_keys=on;
