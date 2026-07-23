-- Content v0.4 migration: track whether an article is public or private.
PRAGMA foreign_keys=off;

ALTER TABLE posts ADD COLUMN visibility TEXT NOT NULL DEFAULT 'public';

PRAGMA foreign_keys=on;
