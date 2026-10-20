# NanoFaaS blog — design

## Goal

The project can publish updates (releases, new modules, write-ups) on the site.
Each post has a stable, shareable URL with its own link preview and share
buttons, and the landing page shows the latest posts right after the hero.
Posts are created from the repository, either by committing a Markdown file or
from a hidden page on the site that opens GitHub's editor pre-filled.

## Decisions

- **Engine:** native Jekyll posts (`_posts/`). GitHub Pages builds them with no
  workflow and no new plugin; `jekyll-seo-tag` already treats them as articles.
- **Language:** English, like the rest of the site. Same tone rules: not a
  research platform, no production-readiness or HA claims.
- **Authors:** none. Posts are signed by the project; only the date is shown.
- **Sharing:** per-post link preview + plain share links. No RSS feed, no
  third-party scripts or trackers, no Mastodon (its share URL depends on the
  reader's instance).
- **Cover images:** none by default. A post may set `image:` to override the
  site's `og.png` in its link preview.
- **Pagination:** none until the post count calls for it.
- **Figures:** a post's images live in `assets/blog/<slug>/`. How they are made
  (TikZ, screenshots, …) is up to that post and not part of the site's design.

## Structure

```
_config.yml               defaults: posts get layout: post and permalink /blog/:title/
_layouts/post.html        extends default: title, date, content, share bar, back link
_includes/share.html      share links + Copy link / native Share buttons
_includes/post-card.html  card used by the landing page and the blog index
blog/index.html           /blog/ — every post, newest first
blog/new.html             /blog/new/ — form that opens GitHub's new-file editor (noindex)
_posts/YYYY-MM-DD-slug.md one file per post
_drafts/                  unpublished posts, previewed with --drafts
assets/blog/<slug>/       a post's images
```

`_layouts/default.html` gains a nav link **Blog** (before Docs, not `optional`,
so it shows at phone width) and a `<meta name="robots" content="noindex">` when
`page.noindex` is true. The copy-link button reuses the Clipboard-API guard of
the code copy button.

## Post front matter

```yaml
---
title: NanoFaaS 0.23.0, the first release candidate
description: One or two sentences used by the cards and the link preview.
image: /assets/blog/<slug>/preview.png   # optional, 1200×630
---
```

The date and slug come from the file name. `description` is required (checked).

## Pages

1. **Landing `#updates`** — section "Latest updates" between the hero and
   `#highlights`, with an "All posts →" link and up to 3 cards (date, title,
   description, "Read more"). Grid of up to 3 columns, 1 at phone width; a single
   card keeps its normal width. Not rendered when there are no posts.
2. **Blog index `/blog/`** — heading, one-line lead, all posts as cards, newest
   first.
3. **Post `/blog/<slug>/`** — h1 title, `<time datetime>` date, prose content
   (existing Markdown styles, highlighted code with copy buttons), share bar,
   "← All posts".
4. **New post `/blog/new/`** — not linked from the nav, `noindex`. Fields:
   title, description, date (defaults to today). It builds the slug (lowercase
   ASCII, hyphens), file name and front matter, previews them, and opens
   `https://github.com/Nanofaas/nanofaas.github.io/new/main/_posts?filename=…&value=…`.
   The author writes the body in GitHub's editor and commits (or, without
   write access, GitHub offers a fork + pull request). Images are uploaded
   separately with "Upload files" into `assets/blog/<slug>/`; the page states
   this and shows the Markdown to reference them.

## Sharing

- **Link preview:** `{% seo %}` emits `og:type=article`, `og:title`,
  `og:description`, `og:url`, `article:published_time` and the image (post
  `image`, else `/assets/img/og.png`) with a large Twitter card.
- **Share bar:** links with the URL-encoded absolute post URL and title:
  - LinkedIn `https://www.linkedin.com/sharing/share-offsite/?url=…`
  - X `https://x.com/intent/post?url=…&text=…`
  - Bluesky `https://bsky.app/intent/compose?text=…`
  - Email `mailto:?subject=…&body=…`
  - **Copy link** button (shows "Copied" / "Copy failed")
  - **Share** button, shown only when `navigator.share` exists (phones).
  External links open in a new tab with `rel="noopener"`.

## Authoring from the repository

README and CLAUDE.md get a "Write a post" section: file name convention,
front matter template, image folder, `_drafts/` and how to preview drafts
(`jekyll build --drafts`), and that `scripts/check.sh` must pass before
pushing to `main` (pushing publishes).

## Testing (`scripts/check.sh`)

- `_site/blog/index.html` exists; every page has the Blog nav link.
- Landing has `id="updates"` with 1–3 post cards, each linking to a built post.
- Every built post has `og:type` `article`, `article:published_time`, a
  non-empty `og:description`, the skip link, and share links containing its
  absolute URL.
- Every `_posts/*.md` has `title` and `description`.
- `_site/blog/new/index.html` has `noindex` and the GitHub new-file URL for
  `Nanofaas/nanofaas.github.io`; it is not linked from the nav.
- The "research" check covers all of `_site/**/*.html`, not just the landing.
- New CSS passes the existing `color-mix()` fallback and AA contrast checks.
- Manual: phone width and light/dark via Chrome DevTools Protocol for the
  landing section, blog index, a post and `/blog/new/`.

## First post

Announces v0.23.0 as the first release candidate, with `p2p-discovery` in beta.
Written in English from the real `v0.22.0 → v0.23.0` diff once the tag is on
GitHub, dated on the tag date, and reviewed by the maintainer before commit.
Figures, if any, are TikZ compiled to SVG with light and dark variants, and are
dropped unless they look clean and professional in both themes.

## Out of scope

RSS/Atom feed, authors, tags/categories, pagination, comments, a CMS
(Pages CMS can be added later on the same files), Mastodon sharing.
