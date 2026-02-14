-- Seed data (idempotent - can be run multiple times safely)
-- Clear existing data first to avoid UNIQUE constraint violations
DELETE FROM posts;

INSERT INTO posts (title, slug, excerpt, content, status, published_at, updated_at)
VALUES
  ('Hello World', 'hello-world', 'Welcome to the blog',
   'This is the first post content. Welcome to our new blog built with MoonBit and Cloudflare Workers!',
   'published', '2026-01-30T00:00:00Z', '2026-01-30T00:00:00Z'),
  ('Second Post', 'second-post', 'Another post',
   'More content here. This is the second blog post demonstrating the pagination feature.',
   'published', '2026-01-30T01:00:00Z', '2026-01-30T01:00:00Z'),
  ('MoonBit Rocks', 'moonbit-rocks', 'Why MoonBit is great',
   'MoonBit is a modern programming language designed for cloud and edge computing.',
   'published', '2026-01-30T02:00:00Z', '2026-01-30T02:00:00Z'),
  ('Cloudflare Workers', 'cloudflare-workers', 'Deploying to the edge',
   'Cloudflare Workers allow you to run code at the edge, close to your users.',
   'published', '2026-01-30T03:00:00Z', '2026-01-30T03:00:00Z'),
  ('TMPX Templating', 'tmpx-templating', 'Type-safe HTML in MoonBit',
   'TMPX provides type-safe HTML templating for MoonBit applications.',
   'published', '2026-01-30T04:00:00Z', '2026-01-30T04:00:00Z'),
  ('MHX Interactivity', 'mhx-interactivity', 'Hypermedia-driven apps',
   'MHX brings htmx-like interactivity to MoonBit applications.',
   'published', '2026-01-30T05:00:00Z', '2026-01-30T05:00:00Z'),
  ('D1 Database', 'd1-database', 'SQLite at the edge',
   'D1 is Cloudflare serverless SQL database powered by SQLite.',
   'published', '2026-01-30T06:00:00Z', '2026-01-30T06:00:00Z'),
  ('Getting Started', 'getting-started', 'How to use this blog',
   'A guide to getting started with the MoonBit blog system.',
   'published', '2026-01-30T07:00:00Z', '2026-01-30T07:00:00Z'),
  ('Performance Tips', 'performance-tips', 'Optimizing your blog',
   'Tips and tricks for optimizing your MoonBit blog performance.',
   'published', '2026-01-30T08:00:00Z', '2026-01-30T08:00:00Z'),
  ('Future Plans', 'future-plans', 'What is coming next',
   'A roadmap of upcoming features for the blog system.',
   'published', '2026-01-30T09:00:00Z', '2026-01-30T09:00:00Z'),
  ('RSS Feeds', 'rss-feeds', 'Syndication support',
   'Adding RSS feed support to your blog.',
   'published', '2026-01-30T10:00:00Z', '2026-01-30T10:00:00Z'),
  ('Markdown Support', 'markdown-support', 'Rich text formatting',
   '# Slide Test

SpeakerDeck:
[!embed](https://speakerdeck.com/player/d3030541c29e4ae7ac68b6ac7622209e)

Docswell:
[!embed](https://www.docswell.com/slide/ZVMQ74/embed)

Google Slides:
[!embed](https://docs.google.com/presentation/d/1NTk3YAo_V2XQp-mkI1Xl3SAAOY1pYuhY3BQj0wR4FMw/preview?slide=id.p)',
   'published', '2026-01-30T11:00:00Z', '2026-01-30T11:00:00Z');
