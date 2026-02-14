-- Admin v0.3 migration: add slide_flag for SVG slide rendering mode
PRAGMA foreign_keys=off;

ALTER TABLE posts ADD COLUMN slide_flag INTEGER NOT NULL DEFAULT 0;

PRAGMA foreign_keys=on;
