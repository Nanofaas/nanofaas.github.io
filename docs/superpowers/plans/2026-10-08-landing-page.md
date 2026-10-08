# NanoFaaS Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A single-page NanoFaaS site on GitHub Pages, built with Jekyll, that a Markdown tutorial can later be dropped into.

**Architecture:** Jekyll as built natively by GitHub Pages. One shared layout (`_layouts/default.html`) holds head, nav, footer and the copy-button script; `index.html` is the landing page; one stylesheet holds tokens, dark mode, landing sections and Markdown prose styles. Images are generated from the source logo by a small Pillow script.

**Tech Stack:** Jekyll 3.10 via the `github-pages` gem, kramdown + Rouge, `jekyll-seo-tag`, plain CSS, ~15 lines of inline JS, Python 3 + Pillow for assets, Docker (`ruby:3.3`) for local builds because system Ruby is 2.6.

**Spec:** `docs/superpowers/specs/2026-10-08-landing-page-design.md`

## Global Constraints

- English copy. Never describe NanoFaaS as a research platform; no production-readiness or HA claims.
- Colors: navy `#0B2559`, electric blue `#1A7CFF`. Fonts: Lexend (headings), Inter (body), JetBrains Mono (code), from Google Fonts only.
- No build step besides what GitHub Pages runs; no Node, no Actions workflow.
- No external scripts. JS limited to the copy buttons.
- Must work at 320px width with 16px side gutter and no horizontal page scroll (inner scroll in code blocks/diagram/tables is fine).
- Light theme + dark mode via `prefers-color-scheme`.
- `docs/`, `scripts/`, `brand/` must not be published.
- Links target `https://github.com/Nanofaas/nanofaas` (branch `main`) and `https://github.com/Nanofaas/nanolab`.

## Review Focus

1. **320px phone width** — code blocks, architecture SVG and tables scroll inside their own box; the page itself never scrolls sideways. Pinned in Task 4 (phone screenshot).
2. **Dark mode legibility** — logo, nav mark, SVG diagram, inline code and tables stay readable. Pinned in Task 4 (dark screenshots).
3. **Copy button copies exactly the command** — no trailing "Copy" text, heredoc kept intact. Pinned in Task 2 (check.sh greps that the script reads from `code`) and Task 4 (manual click).
4. **Nav anchors from non-home pages and under the sticky header** — links use `/#section` and sections have `scroll-margin-top`. Pinned in Task 4 (Markdown smoke page).
5. **A Markdown tutorial page renders styled** (prose, tables, highlighted code with copy button) with only `layout: default`. Pinned in Task 4 (smoke page build + screenshot).

---

## File map

| File | Responsibility |
|---|---|
| `brand/nanofaas-logo.png`, `brand/nanofaas-logo-transparent.png` | Source logos (moved from repo root), not published |
| `scripts/make-assets.py` | Generates `assets/img/*` from the transparent source logo, self-checks output |
| `scripts/check.sh` | Builds the site in Docker and asserts on `_site/` |
| `_config.yml` | Site metadata, links, markdown/highlighter, excludes |
| `Gemfile` | `github-pages` gem for local builds |
| `.gitignore` | `_site/`, `.jekyll-cache/`, `Gemfile.lock` |
| `_layouts/default.html` | Shared page shell |
| `assets/css/style.css` | All styles |
| `index.html` | Landing page content |
| `README.md`, `CLAUDE.md` | How to preview / extend |

---

### Task 1: Logo assets

**Files:**
- Move: `nanofaas-logo.png` → `brand/nanofaas-logo.png`
- Move: `Nanofaas Cloud Connection Logo.png` → `brand/nanofaas-logo-transparent.png`
- Create: `scripts/make-assets.py`
- Create (generated): `assets/img/logo.png`, `assets/img/logo-dark.png`, `assets/img/mark.png`, `assets/img/mark-dark.png`

**Interfaces:**
- Produces: `assets/img/logo.png` (480px wide, transparent), `logo-dark.png` (same, navy lightened), `mark.png` / `mark-dark.png` (64×64 cloud mark). Task 2 uses `mark*.png` in the nav and as favicon; Task 3 uses `logo*.png` in the hero.

The transparent source has alpha 0 at the corners; its opaque content bbox is `(169, 330, 1092, 945)` and the wordmark starts below y≈780.

- [ ] **Step 1: Move the source logos**

```bash
mkdir -p brand
mv nanofaas-logo.png brand/nanofaas-logo.png
mv "Nanofaas Cloud Connection Logo.png" brand/nanofaas-logo-transparent.png
```

- [ ] **Step 2: Write `scripts/make-assets.py`**

```python
#!/usr/bin/env python3
"""Regenerate site images from the source logo. Run: python3 scripts/make-assets.py"""
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "brand" / "nanofaas-logo-transparent.png"
OUT = ROOT / "assets" / "img"
WORDMARK_TOP = 760  # rows above this hold only the cloud mark


def trim(im):
    alpha = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    return im.crop(alpha.getbbox())


def for_dark_bg(im):
    # mirror the lightness of dark pixels (navy -> pale blue), keep hue and alpha
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if l < 0.5:
                r, g, b = (round(c * 255) for c in colorsys.hls_to_rgb(h, 1 - l, s))
                px[x, y] = (r, g, b, a)
    return im


def square(im, size):
    side = max(im.size)
    canvas = Image.new("RGBA", (side, side))
    canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    src = Image.open(SRC).convert("RGBA")

    logo = trim(src)
    logo = logo.resize((480, round(480 * logo.height / logo.width)), Image.LANCZOS)
    logo.save(OUT / "logo.png", optimize=True)
    for_dark_bg(logo).save(OUT / "logo-dark.png", optimize=True)

    mark = square(trim(src.crop((0, 0, src.width, WORDMARK_TOP))), 64)
    mark.save(OUT / "mark.png", optimize=True)
    for_dark_bg(mark).save(OUT / "mark-dark.png", optimize=True)

    for name in ("logo.png", "logo-dark.png", "mark.png", "mark-dark.png"):
        im = Image.open(OUT / name)
        assert im.mode == "RGBA", name
        assert im.getpixel((0, 0))[3] == 0, f"{name}: corner not transparent"
    assert Image.open(OUT / "mark.png").size == (64, 64)
    assert Image.open(OUT / "logo.png").width == 480
    print("assets ok")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run it**

Run: `python3 scripts/make-assets.py`
Expected: `assets ok`

- [ ] **Step 4: Eyeball the four images** (Read tool on each PNG): cloud + wordmark in `logo*.png`, cloud only in `mark*.png`, navy turned pale in `*-dark.png`.

- [ ] **Step 5: Commit**

```bash
git add brand scripts/make-assets.py assets/img
git commit -m "Add logo assets and generator script"
```

---

### Task 2: Jekyll scaffold (config, layout, stylesheet, build check)

**Files:**
- Create: `scripts/check.sh`, `_config.yml`, `Gemfile`, `.gitignore`, `_layouts/default.html`, `assets/css/style.css`, `index.html` (stub)

**Interfaces:**
- Consumes: `assets/img/mark.png`, `assets/img/mark-dark.png` (Task 1).
- Produces: `layout: default`; front-matter key `main_class` (default `container prose`; landing page sets `home`); `site.repo`, `site.docs`, `site.nanolab` URLs; CSS classes listed in the stylesheet below. Task 3 uses all of these.

- [ ] **Step 1: Write `scripts/check.sh`**

```sh
#!/bin/sh
# Build the site in Docker (system Ruby is too old for github-pages) and sanity-check _site/.
set -eu
cd "$(dirname "$0")/.."

docker run --rm -v "$PWD":/site -v nanofaas-site-bundle:/usr/local/bundle -w /site ruby:3.3 \
  sh -c 'bundle install --quiet && bundle exec jekyll build --quiet'

fail() { echo "FAIL: $*"; exit 1; }
page=_site/index.html

test -f "$page" || fail "no index.html"
for f in assets/css/style.css assets/img/logo.png assets/img/logo-dark.png assets/img/mark.png assets/img/mark-dark.png; do
  test -f "_site/$f" || fail "missing _site/$f"
done
for d in docs scripts brand; do
  test ! -e "_site/$d" || fail "$d/ is published"
done
grep -q 'rel="icon"' "$page" || fail "favicon link missing"
grep -q "querySelector('code')" "$page" || fail "copy button must copy from <code>, not the whole <pre>"
if grep -qi research "$page"; then fail "'research' wording on page"; fi

echo "check ok"
```

Then: `chmod +x scripts/check.sh`

- [ ] **Step 2: Run it to see it fail**

Run: `scripts/check.sh`
Expected: Docker build fails (no `Gemfile`) → non-zero exit.

- [ ] **Step 3: Write `Gemfile`**

```ruby
source "https://rubygems.org"

# Same versions GitHub Pages uses. Only needed for local builds.
gem "github-pages", group: :jekyll_plugins
```

- [ ] **Step 4: Write `.gitignore`**

```
_site/
.jekyll-cache/
.sass-cache/
Gemfile.lock
.DS_Store
```

- [ ] **Step 5: Write `_config.yml`**

```yaml
title: NanoFaaS
description: A minimal, modular Function-as-a-Service control plane.
url: https://nanofaas.github.io
baseurl: ""
lang: en

repo: https://github.com/Nanofaas/nanofaas
docs: https://github.com/Nanofaas/nanofaas/tree/main/docs
nanolab: https://github.com/Nanofaas/nanolab

markdown: kramdown
highlighter: rouge
kramdown:
  input: GFM

plugins:
  - jekyll-seo-tag

exclude:
  - brand
  - docs
  - scripts
  - Gemfile
  - Gemfile.lock
  - README.md
  - CLAUDE.md
```

- [ ] **Step 6: Write `_layouts/default.html`**

```html
<!doctype html>
<html lang="{{ site.lang }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  {% seo %}
  <link rel="icon" type="image/png" href="{{ '/assets/img/mark.png' | relative_url }}">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&family=Lexend:wght@500;600;700&display=swap">
  <link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
</head>
<body>
  <header class="site-header">
    <nav class="container nav" aria-label="Main">
      <a class="brand" href="{{ '/' | relative_url }}">
        <picture>
          <source srcset="{{ '/assets/img/mark-dark.png' | relative_url }}" media="(prefers-color-scheme: dark)">
          <img src="{{ '/assets/img/mark.png' | relative_url }}" alt="" width="32" height="32">
        </picture>
        nano<span>faas</span>
      </a>
      <ul class="nav-links">
        <li class="optional"><a href="{{ '/' | relative_url }}#highlights">Features</a></li>
        <li class="optional"><a href="{{ '/' | relative_url }}#quick-start">Quick start</a></li>
        <li class="optional"><a href="{{ '/' | relative_url }}#architecture">Architecture</a></li>
        <li><a href="{{ site.docs }}">Docs</a></li>
        <li><a href="{{ site.repo }}">GitHub</a></li>
      </ul>
    </nav>
  </header>

  <main class="{{ page.main_class | default: 'container prose' }}">
    {{ content }}
  </main>

  <footer class="site-footer">
    <div class="container">
      <p>NanoFaaS · MIT License</p>
      <ul>
        <li><a href="{{ site.repo }}">GitHub</a></li>
        <li><a href="{{ site.docs }}">Docs</a></li>
        <li><a href="{{ site.nanolab }}">NanoLab</a></li>
      </ul>
    </div>
  </footer>

  <script>
    document.querySelectorAll('.highlight > pre').forEach(function (pre) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'copy';
      btn.textContent = 'Copy';
      btn.setAttribute('aria-label', 'Copy code to clipboard');
      btn.addEventListener('click', function () {
        var text = (pre.querySelector('code') || pre).innerText.replace(/\n$/, '');
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = 'Copied';
        }, function () {
          btn.textContent = 'Copy failed';
        }).then(function () {
          setTimeout(function () { btn.textContent = 'Copy'; }, 1500);
        });
      });
      pre.parentElement.appendChild(btn);
    });
  </script>
</body>
</html>
```

- [ ] **Step 7: Write `assets/css/style.css`**

```css
/* ---------- tokens ---------- */
:root {
  --navy: #0B2559;
  --blue: #1A7CFF;
  --blue-hover: #0F66E0;

  --bg: #FFFFFF;
  --bg-alt: #F4F7FC;
  --surface: #FFFFFF;
  --text: #0E1A33;
  --muted: #51607A;
  --line: #DDE4F0;
  --accent: #1A7CFF;
  --accent-strong: #0B2559;
  --code-bg: #0B1730;
  --code-text: #E6EDF8;

  --radius: 12px;
  --maxw: 1120px;
  --font-head: "Lexend", system-ui, sans-serif;
  --font-body: "Inter", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;
  color-scheme: light dark;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #070F1F;
    --bg-alt: #0C1730;
    --surface: #0F1C38;
    --text: #E6EDF8;
    --muted: #9AA8C2;
    --line: #1E2D4D;
    --accent: #4D9BFF;
    --accent-strong: #BFD6FF;
    --code-bg: #050B18;
  }
}

/* ---------- base ---------- */
*, *::before, *::after { box-sizing: border-box; }
html { scroll-behavior: smooth; -webkit-text-size-adjust: 100%; }
body { margin: 0; background: var(--bg); color: var(--text); font: 16px/1.65 var(--font-body); }
img, svg { max-width: 100%; height: auto; }
a { color: var(--accent); text-underline-offset: 3px; }
a:focus-visible, button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
h1, h2, h3 { font-family: var(--font-head); line-height: 1.2; letter-spacing: -0.01em; }
code, pre { font-family: var(--font-mono); font-size: 0.9em; }
[id] { scroll-margin-top: 80px; }

.container { width: 100%; max-width: var(--maxw); margin: 0 auto; padding: 0 16px; }
@media (min-width: 720px) { .container { padding: 0 32px; } }

/* ---------- header / footer ---------- */
.site-header {
  position: sticky; top: 0; z-index: 10;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--line);
}
.nav { display: flex; align-items: center; gap: 24px; height: 64px; }
.brand {
  display: flex; align-items: center; gap: 10px;
  font: 600 1.25rem var(--font-head); color: var(--accent-strong); text-decoration: none;
}
.brand img { display: block; width: 32px; height: 32px; }
.brand span { color: var(--blue); }
.nav-links { display: flex; gap: 20px; margin: 0 0 0 auto; padding: 0; list-style: none; }
.nav-links a { color: var(--muted); font-size: 0.95rem; font-weight: 500; text-decoration: none; }
.nav-links a:hover { color: var(--text); }
@media (max-width: 760px) { .nav-links .optional { display: none; } }

.site-footer { border-top: 1px solid var(--line); padding: 32px 0; color: var(--muted); font-size: 0.9rem; }
.site-footer .container { display: flex; flex-wrap: wrap; gap: 12px 24px; justify-content: space-between; align-items: center; }
.site-footer p { margin: 0; }
.site-footer ul { display: flex; gap: 20px; margin: 0; padding: 0; list-style: none; }
.site-footer a { color: var(--muted); }

/* ---------- shared content: tables, code ---------- */
.table-wrap { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
th, td { padding: 10px 12px; border-bottom: 1px solid var(--line); text-align: left; vertical-align: top; }
th { font-family: var(--font-head); font-weight: 600; }
td.center, th.center { text-align: center; }
:not(pre) > code { padding: 0.1em 0.35em; background: var(--bg-alt); border: 1px solid var(--line); border-radius: 6px; }

.highlight { position: relative; margin: 0 0 1rem; }
pre {
  margin: 0; padding: 16px 76px 16px 18px; overflow-x: auto;
  background: var(--code-bg); color: var(--code-text);
  border-radius: var(--radius); line-height: 1.55;
}
.copy {
  position: absolute; top: 8px; right: 8px; padding: 4px 10px; cursor: pointer;
  font: 500 0.75rem var(--font-body); color: var(--code-text);
  background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 6px;
}
.copy:hover { background: rgba(255, 255, 255, 0.16); }

.highlight .c, .highlight .c1, .highlight .cm { color: #7C8BA8; font-style: italic; }
.highlight .s, .highlight .s1, .highlight .s2, .highlight .sh, .highlight .dl { color: #9FE0A8; }
.highlight .k, .highlight .kd, .highlight .nb { color: #7DB5FF; }
.highlight .nv, .highlight .nt, .highlight .nl { color: #F2C879; }
.highlight .m, .highlight .mi, .highlight .mf, .highlight .kc { color: #F59E8B; }
.highlight .o, .highlight .p { color: #B7C3D9; }

/* ---------- Markdown pages (tutorials) ---------- */
.prose { max-width: 760px; padding-top: 48px; padding-bottom: 64px; }
.prose h1 { font-size: clamp(1.8rem, 4vw, 2.4rem); }
.prose h2 { margin-top: 2.5rem; }
.prose img { border-radius: var(--radius); }
.prose table { display: block; overflow-x: auto; }

/* ---------- landing: sections ---------- */
.section { padding: 72px 0; }
.section-alt { background: var(--bg-alt); }
.section h2 { margin: 0 0 0.5rem; font-size: clamp(1.6rem, 3vw, 2.2rem); }
.section-lead { max-width: 680px; margin: 0 0 2.5rem; color: var(--muted); font-size: 1.05rem; }

/* hero */
.hero {
  padding: 64px 0 72px; text-align: center;
  background: radial-gradient(60% 60% at 50% 0%, color-mix(in srgb, var(--blue) 12%, transparent), transparent);
}
.hero-logo { width: min(320px, 70vw); height: auto; }
.hero h1 { max-width: 820px; margin: 24px auto 16px; font-size: clamp(1.9rem, 4.5vw, 3rem); }
.lead { max-width: 680px; margin: 0 auto 32px; color: var(--muted); font-size: 1.15rem; }
.actions { display: flex; flex-wrap: wrap; gap: 12px; justify-content: center; }
.btn { display: inline-block; padding: 12px 22px; border: 1px solid transparent; border-radius: 999px; font-weight: 600; text-decoration: none; }
.btn-primary { background: var(--blue); color: #fff; }
.btn-primary:hover { background: var(--blue-hover); }
.btn-ghost { border-color: var(--line); color: var(--text); }
.btn-ghost:hover { border-color: var(--accent); }
.badges { display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin: 32px 0 0; padding: 0; list-style: none; }
.badges li { padding: 4px 12px; border: 1px solid var(--line); border-radius: 999px; color: var(--muted); font-size: 0.85rem; }

/* highlight cards */
.cards { display: grid; gap: 16px; grid-template-columns: repeat(auto-fill, minmax(min(100%, 260px), 1fr)); margin: 0; padding: 0; list-style: none; }
.card { padding: 22px; background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); }
.card h3 { margin: 0 0 8px; font-size: 1.1rem; }
.card h3::before {
  content: ""; display: inline-block; width: 10px; height: 10px; margin-right: 10px;
  border-radius: 50%; background: var(--blue); vertical-align: middle;
}
.card p { margin: 0; color: var(--muted); }

/* quick start steps */
.steps { display: grid; gap: 32px; max-width: 860px; margin: 0; padding: 0; list-style: none; counter-reset: step; }
.steps > li { position: relative; min-width: 0; padding-left: 52px; counter-increment: step; }
.steps > li::before {
  content: counter(step); position: absolute; left: 0; top: 0;
  width: 34px; height: 34px; border-radius: 50%; background: var(--blue); color: #fff;
  font: 600 1rem/34px var(--font-head); text-align: center;
}
.steps h3 { margin: 4px 0 8px; font-size: 1.15rem; }
.steps p { margin: 0 0 12px; color: var(--muted); }
.two-col { display: grid; gap: 32px; grid-template-columns: repeat(auto-fit, minmax(min(100%, 400px), 1fr)); margin-top: 48px; }
.two-col > * { min-width: 0; }
.two-col h3 { margin: 0 0 8px; }
.two-col p { margin: 0 0 12px; color: var(--muted); }

/* architecture diagram */
.diagram { margin: 0 0 2.5rem; padding: 24px; overflow-x: auto; background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); }
.diagram svg { display: block; width: 100%; min-width: 640px; max-width: 820px; margin: 0 auto; }
.d-box { fill: var(--bg-alt); stroke: var(--line); stroke-width: 1.5; }
.d-core { fill: color-mix(in srgb, var(--blue) 14%, var(--surface)); stroke: var(--blue); stroke-width: 1.5; }
.d-frame { fill: none; stroke: var(--accent-strong); stroke-width: 1.5; stroke-dasharray: 6 5; }
.d-pill { fill: var(--accent-strong); }
.d-pill-text { font: 600 13px var(--font-body); fill: var(--bg); text-anchor: middle; }
.d-title { font: 600 15px var(--font-head); fill: var(--text); text-anchor: middle; }
.d-sub { font: 12px var(--font-body); fill: var(--muted); text-anchor: middle; }
.d-label { font: 500 11px var(--font-mono); fill: var(--muted); text-anchor: middle; }
.d-line { fill: none; stroke: var(--muted); stroke-width: 1.5; }
.d-arrowhead { fill: var(--muted); }

/* SDK chips */
.chips { display: flex; flex-wrap: wrap; gap: 12px; margin: 0 0 24px; padding: 0; list-style: none; }
.chips li { padding: 10px 20px; background: var(--surface); border: 1px solid var(--line); border-radius: 999px; font: 600 1rem var(--font-head); }
```

- [ ] **Step 8: Write a stub `index.html`** (replaced in Task 3)

```html
---
layout: default
main_class: home
---
<section class="hero"><div class="container"><h1>NanoFaaS</h1></div></section>
```

- [ ] **Step 9: Run the check**

Run: `scripts/check.sh`
Expected: last line `check ok`. (First run downloads gems; can take a few minutes.)

- [ ] **Step 10: Commit**

```bash
git add scripts/check.sh Gemfile .gitignore _config.yml _layouts assets/css index.html
git commit -m "Add Jekyll scaffold, layout and stylesheet"
```

---

### Task 3: Landing page content

**Files:**
- Modify: `scripts/check.sh` (add section assertions)
- Modify: `index.html` (full content)

**Interfaces:**
- Consumes: `layout: default`, `main_class`, `site.repo`, `site.docs`, CSS classes from Task 2; `assets/img/logo.png`, `logo-dark.png` from Task 1.
- Produces: section ids `highlights`, `quick-start`, `architecture`, `modules`, `sdks` (the nav links to the first three).

- [ ] **Step 1: Add section assertions to `scripts/check.sh`**, just before `echo "check ok"`:

```sh
for id in highlights quick-start architecture modules sdks; do
  grep -q "id=\"$id\"" "$page" || fail "section #$id missing"
done
grep -q 'class="highlight"' "$page" || fail "no Rouge-highlighted code blocks"
```

- [ ] **Step 2: Run to see it fail**

Run: `scripts/check.sh`
Expected: `FAIL: section #highlights missing`

- [ ] **Step 3: Replace `index.html`** with:

````html
---
layout: default
main_class: home
---
<section class="hero">
  <div class="container">
    <picture>
      <source srcset="{{ '/assets/img/logo-dark.png' | relative_url }}" media="(prefers-color-scheme: dark)">
      <img class="hero-logo" src="{{ '/assets/img/logo.png' | relative_url }}" alt="NanoFaaS" width="480" height="320">
    </picture>
    <h1>A minimal, modular Function-as-a-Service control plane.</h1>
    <p class="lead">NanoFaaS registers, deploys and invokes containerized functions on Kubernetes or on a single host. The control plane is one reactive Java service, and everything beyond invocation is a module you choose at build time.</p>
    <div class="actions">
      <a class="btn btn-primary" href="#quick-start">Get started</a>
      <a class="btn btn-ghost" href="{{ site.repo }}">View on GitHub</a>
    </div>
    <ul class="badges">
      <li>Java 25</li>
      <li>GraalVM native</li>
      <li>Kubernetes · Docker · containerd</li>
      <li>MIT licensed</li>
    </ul>
  </div>
</section>

<section class="section section-alt" id="highlights">
  <div class="container">
    <h2>Only what you need, nothing more</h2>
    <p class="section-lead">A build contains only the modules it needs. Queueing, autoscaling, concurrency control, hot reconfiguration, offloading and each deployment backend are opt-in.</p>
    <ul class="cards">
      <li class="card">
        <h3>Build-time modularity</h3>
        <p>Ten optional modules with declared defaults, requirements and conflicts, validated before a single task runs.</p>
      </li>
      <li class="card">
        <h3>One API, three execution modes</h3>
        <p>Managed deployments, passthrough to external endpoints and in-process execution share the same invocation endpoints.</p>
      </li>
      <li class="card">
        <h3>Interchangeable backends</h3>
        <p>Kubernetes, a local Docker-compatible runtime, or rootless containerd.</p>
      </li>
      <li class="card">
        <h3>Concurrency control with SLOs</h3>
        <p>Per-function limits that are static, adapt to latency, or share a platform-wide budget with weighted max-min fairness.</p>
      </li>
      <li class="card">
        <h3>Native builds</h3>
        <p>The control plane, CLI and Java example functions compile to GraalVM native executables and ship on Distroless images.</p>
      </li>
      <li class="card">
        <h3>Any language</h3>
        <p>Functions are HTTP services behind a small contract, with SDKs for Java, Python, Go, JavaScript and Rust.</p>
      </li>
      <li class="card">
        <h3>Reproducible distributions</h3>
        <p>One versioned YAML recipe builds a control plane and its functions, images included.</p>
      </li>
    </ul>
  </div>
</section>

<section class="section" id="quick-start">
  <div class="container">
    <h2>Quick start</h2>
    <p class="section-lead">You need Java 25; if it is missing, Gradle downloads a JDK. Clone the <a href="{{ site.repo }}">repository</a> and open three terminals.</p>
    <ol class="steps">
      <li>
        <h3>Start the control plane</h3>
{% highlight bash %}
./gradlew :control-plane:bootRun
{% endhighlight %}
      </li>
      <li>
        <h3>Start an example function on port 9090</h3>
{% highlight bash %}
./gradlew :functions:java:word-stats:bootRun --args='--server.port=9090'
{% endhighlight %}
      </li>
      <li>
        <h3>Build the CLI, register the function and invoke it</h3>
{% highlight bash %}
./gradlew :nanofaas-cli:installDist
alias nanofaas="$PWD/clients/cli/build/install/nanofaas-cli/bin/nanofaas-cli"

cat > word-stats.yaml <<'EOF'
name: word-stats
image: nanofaas/java-word-stats
executionMode: EXTERNAL
endpointUrl: http://localhost:9090/invoke
EOF

nanofaas fn apply -f word-stats.yaml
nanofaas invoke word-stats -d '{"text": "to be or not to be", "topN": 2}'
{% endhighlight %}
        <p>The response:</p>
{% highlight json %}
{"executionId":"cf9360a6-…","status":"success","output":{"averageWordLength":2.17,"wordCount":6,"topWords":[{"count":2,"word":"be"},{"count":2,"word":"to"}],"uniqueWords":4},…}
{% endhighlight %}
      </li>
    </ol>

    <div class="two-col">
      <div>
        <h3>Asynchronous invocation</h3>
        <p>Enqueue a call and get an execution ID straight away.</p>
{% highlight bash %}
nanofaas enqueue word-stats -d '{"text": "hello world"}'
nanofaas exec get <executionId>
{% endhighlight %}
      </div>
      <div>
        <h3>Plain HTTP</h3>
        <p>The CLI wraps the HTTP API, which you can also call directly.</p>
{% highlight bash %}
curl -X POST http://localhost:8080/v1/functions/word-stats:invoke \
  -H 'Content-Type: application/json' -d '{"input": {"text": "hello"}}'
{% endhighlight %}
      </div>
    </div>
    <p>Next: run functions on <a href="{{ site.repo }}/blob/main/docs/quickstart.md">Kubernetes</a>, or <a href="{{ site.repo }}/blob/main/docs/tutorial-function.md">write your own function</a>.</p>
  </div>
</section>

<section class="section section-alt" id="architecture">
  <div class="container">
    <h2>Architecture</h2>
    <p class="section-lead">One control plane with a small core. Optional modules plug in around it, and a deployment provider runs the functions it manages.</p>

    <figure class="diagram">
      <svg viewBox="0 0 760 300" role="img" aria-labelledby="arch-title arch-desc">
        <title id="arch-title">NanoFaaS architecture</title>
        <desc id="arch-desc">Clients call the control plane core over HTTP on port 8080. The core works with optional modules and a deployment provider. The provider runs managed instances; the core forwards external calls to an external endpoint.</desc>
        <defs>
          <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
            <path class="d-arrowhead" d="M0 0L10 5L0 10z"/>
          </marker>
        </defs>

        <rect class="d-pill" x="10" y="132" width="140" height="50" rx="25"/>
        <text class="d-pill-text" x="80" y="162">Client · SDK · CLI</text>
        <line class="d-line" x1="150" y1="157" x2="243" y2="157" marker-end="url(#arrow)"/>
        <text class="d-label" x="196" y="147">HTTP :8080</text>

        <rect class="d-frame" x="225" y="10" width="320" height="280" rx="14"/>
        <text class="d-title" x="385" y="34">Control plane</text>

        <rect class="d-box" x="245" y="45" width="280" height="65" rx="10"/>
        <text class="d-title" x="385" y="72">Optional modules</text>
        <text class="d-sub" x="385" y="94">queues · autoscaler · concurrency · offload</text>

        <rect class="d-core" x="245" y="125" width="280" height="65" rx="10"/>
        <text class="d-title" x="385" y="152">Core</text>
        <text class="d-sub" x="385" y="174">registry · dispatch · execution store</text>

        <rect class="d-box" x="245" y="205" width="280" height="65" rx="10"/>
        <text class="d-title" x="385" y="232">Deployment provider</text>
        <text class="d-sub" x="385" y="254">Kubernetes · container · containerd</text>

        <line class="d-line" x1="385" y1="110" x2="385" y2="125"/>
        <line class="d-line" x1="385" y1="190" x2="385" y2="205"/>

        <rect class="d-box" x="590" y="125" width="160" height="65" rx="10"/>
        <text class="d-title" x="670" y="152">External endpoint</text>
        <text class="d-sub" x="670" y="174">EXTERNAL mode</text>
        <line class="d-line" x1="525" y1="157" x2="588" y2="157" marker-end="url(#arrow)"/>

        <rect class="d-box" x="590" y="205" width="160" height="65" rx="10"/>
        <text class="d-title" x="670" y="232">Managed instances</text>
        <text class="d-sub" x="670" y="254">DEPLOYMENT mode</text>
        <line class="d-line" x1="525" y1="237" x2="588" y2="237" marker-end="url(#arrow)"/>
      </svg>
    </figure>

    <p class="section-lead">A synchronous call (<code>POST /v1/functions/{name}:invoke</code>) is validated, rate-limited and checked for idempotency, then recorded in the execution store. It goes through <code>sync-queue</code> if that module is present, otherwise through <code>async-queue</code>, otherwise straight to the function. Metrics and health are served on port 8081.</p>

    <div class="table-wrap">
      <table>
        <thead><tr><th>Execution mode</th><th>Behaviour</th></tr></thead>
        <tbody>
          <tr><td><code>DEPLOYMENT</code></td><td>The control plane owns the function's instances through a deployment backend.</td></tr>
          <tr><td><code>EXTERNAL</code></td><td>The function runs elsewhere; invocations are forwarded to its <code>endpointUrl</code>.</td></tr>
          <tr><td><code>LOCAL</code></td><td>In-process execution, for testing.</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</section>

<section class="section" id="modules">
  <div class="container">
    <h2>Modules</h2>
    <p class="section-lead">Pick a set at build time. Each module declares its defaults, requirements and conflicts, and an invalid selection fails before any task runs. The three deployment providers are mutually exclusive.</p>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Module</th><th>Purpose</th><th class="center">Default</th></tr></thead>
        <tbody>
          <tr><td><code>async-queue</code></td><td>Per-function queues and scheduler for asynchronous calls</td><td class="center">✓</td></tr>
          <tr><td><code>sync-queue</code></td><td>Admission control and backpressure for synchronous calls</td><td class="center">✓</td></tr>
          <tr><td><code>autoscaler</code></td><td>Replica scaling driven by workload metrics</td><td class="center">✓</td></tr>
          <tr><td><code>concurrency-control</code></td><td>Per-function concurrency governor</td><td class="center">✓</td></tr>
          <tr><td><code>runtime-config</code></td><td>Hot reconfiguration through an admin API</td><td class="center">✓</td></tr>
          <tr><td><code>offload</code></td><td>Transparent proxying of synchronous calls to a remote NanoFaaS</td><td class="center">✓</td></tr>
          <tr><td><code>build-metadata</code></td><td>Build diagnostics endpoint</td><td class="center">✓</td></tr>
          <tr><td><code>k8s-deployment-provider</code></td><td>Kubernetes backend</td><td class="center">✓</td></tr>
          <tr><td><code>container-deployment-provider</code></td><td>Docker-compatible local backend</td><td class="center"></td></tr>
          <tr><td><code>containerd-deployment-provider</code></td><td>Rootless containerd backend</td><td class="center"></td></tr>
        </tbody>
      </table>
    </div>
    <div class="two-col">
      <div>
        <h3>Choose modules</h3>
{% highlight bash %}
./gradlew :control-plane:bootJar -PcontrolPlaneModules=none
./gradlew :control-plane:bootJar -PcontrolPlaneModules=async-queue,autoscaler
./gradlew :control-plane:bootJar -PcontrolPlaneModules=all
{% endhighlight %}
      </div>
      <div>
        <h3>Or build from a recipe</h3>
        <p>A recipe fixes modules, configuration, JVM or native build mode, and the functions to package with their images. See <a href="{{ site.repo }}/blob/main/docs/recipes.md">distribution recipes</a>.</p>
{% highlight bash %}
./gradlew assembleRecipe -Precipe=recipes/local-demo.yaml
{% endhighlight %}
      </div>
    </div>
  </div>
</section>

<section class="section section-alt" id="sdks">
  <div class="container">
    <h2>Write functions in any language</h2>
    <p class="section-lead">A function is an HTTP service behind a small contract. SDKs make it a few lines; examples ship for every SDK language plus Bash.</p>
    <ul class="chips">
      <li>Java</li>
      <li>Python</li>
      <li>Go</li>
      <li>JavaScript</li>
      <li>Rust</li>
    </ul>
    <div class="actions" style="justify-content:flex-start">
      <a class="btn btn-primary" href="{{ site.repo }}/blob/main/docs/tutorial-function.md">Write a function</a>
      <a class="btn btn-ghost" href="{{ site.repo }}/tree/main/sdks">Browse the SDKs</a>
    </div>
  </div>
</section>
````

- [ ] **Step 4: Run the check**

Run: `scripts/check.sh`
Expected: `check ok`

- [ ] **Step 5: Commit**

```bash
git add scripts/check.sh index.html
git commit -m "Add landing page content"
```

---

### Task 4: Visual verification (Review Focus 1–5)

**Files:**
- Temporary: `tutorials/smoke.md` (deleted at the end of the task)
- Modify: `assets/css/style.css`, `index.html` only if a check below fails

**Interfaces:**
- Consumes: built `_site/` from Task 3.

- [ ] **Step 1: Create a throwaway Markdown page** `tutorials/smoke.md`:

````markdown
---
layout: default
title: Smoke test
---
# Smoke test

Inline `code`, a [link to quick start](/#quick-start), and a table:

| A | B |
|---|---|
| 1 | 2 |

```bash
echo "hello"
```
````

- [ ] **Step 2: Build and serve**

```bash
scripts/check.sh
python3 -m http.server 4000 -d _site   # run in background
```

- [ ] **Step 3: Screenshot light/dark × desktop/phone**

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT=/private/tmp/claude-501/-Users-micheleciavotta-Downloads-nanofaas-site/1f6d468a-dad1-4f89-9325-5255273d35aa/scratchpad
for theme in light dark; do
  flag=""; [ "$theme" = dark ] && flag="--force-dark-mode"
  "$CHROME" --headless=new $flag --hide-scrollbars --window-size=1280,4200 --screenshot="$OUT/desk-$theme.png" http://localhost:4000/
  "$CHROME" --headless=new $flag --hide-scrollbars --window-size=320,7000 --screenshot="$OUT/phone-$theme.png" http://localhost:4000/
  "$CHROME" --headless=new $flag --window-size=390,1200 --screenshot="$OUT/smoke-$theme.png" http://localhost:4000/tutorials/smoke.html
done
```

Read each PNG and confirm:
- 320px: nothing overflows the viewport; code blocks, diagram and tables scroll inside their own boxes. (Review Focus 1)
- Dark: logo, nav mark, diagram text/lines, inline code, tables are legible. If `--force-dark-mode` does not flip `prefers-color-scheme`, temporarily paste the dark `:root` block outside its media query, rebuild, screenshot, then revert. (Review Focus 2)
- Smoke page: prose width, table, highlighted code with Copy button, footer. (Review Focus 5)

- [ ] **Step 4: Check copy and anchors in a real browser**

Open `http://localhost:4000/` in Chrome: click Copy on the step 3 block, paste into a terminal-free text field, confirm the heredoc is intact and no "Copy" text is appended (Review Focus 3). Open `http://localhost:4000/tutorials/smoke.html`, click "Quick start" in the nav: lands on the home page with the section heading visible below the sticky header (Review Focus 4).

- [ ] **Step 5: Fix any failures**, rerun `scripts/check.sh` and the relevant screenshot.

- [ ] **Step 6: Remove the smoke page, stop the server, commit fixes (if any)**

```bash
rm -r tutorials
git add -A assets index.html
git commit -m "Polish layout after visual check" || true
```

---

### Task 5: Repo docs and publishing

**Files:**
- Create: `README.md`, `CLAUDE.md`

- [ ] **Step 1: Write `README.md`**

````markdown
# nanofaas.github.io

Website for [NanoFaaS](https://github.com/Nanofaas/nanofaas), served at <https://nanofaas.github.io>.
GitHub Pages builds it with Jekyll on every push to `main`; there is no workflow to maintain.

## Preview locally

```bash
scripts/check.sh                      # builds _site/ in Docker and runs sanity checks
python3 -m http.server 4000 -d _site  # then open http://localhost:4000
```

With Ruby ≥ 3 installed you can instead run `bundle install && bundle exec jekyll serve`.

## Add a page or tutorial

Create a Markdown file, e.g. `tutorials/my-tutorial.md`:

```markdown
---
layout: default
title: My tutorial
---
# My tutorial
...
```

It inherits the header, footer, prose styles and highlighted code with copy buttons.
Wrap code that contains `{{` or `{%` in `{% raw %}…{% endraw %}`.

## Logo

Source files live in `brand/`. Regenerate `assets/img/` with `python3 scripts/make-assets.py` (needs Pillow).
````

- [ ] **Step 2: Write `CLAUDE.md`**

````markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Jekyll site for NanoFaaS, published by GitHub Pages from `main` of `Nanofaas/nanofaas.github.io` (no Actions workflow; GitHub builds it with the `github-pages` gem, Jekyll 3.10).

## Commands

- `scripts/check.sh` — builds in Docker (`ruby:3.3`; system Ruby 2.6 is too old) and asserts on `_site/` (assets present, `docs/ scripts/ brand/` not published, section ids, no "research" wording). Run after every change.
- `python3 -m http.server 4000 -d _site` — view the built site.
- `python3 scripts/make-assets.py` — regenerate `assets/img/*` (logo, dark variant, 64px mark) from `brand/nanofaas-logo-transparent.png`.

## Structure

- `_layouts/default.html` is the only layout: head (`{% seo %}`, Google Fonts), nav, footer, and the inline copy-button script (targets `.highlight > pre`, copies from `code`).
- `main` gets class `page.main_class`, defaulting to `container prose`; `index.html` sets `main_class: home` and builds its own `.section`s. Any new Markdown page with `layout: default` is styled as prose automatically.
- `assets/css/style.css` holds everything: tokens on `:root` with a `prefers-color-scheme: dark` override, then base, header/footer, code/Rouge colors, prose, landing sections, SVG diagram classes (`d-*`).
- Nav links use `/#id`, so they work from sub-pages. The landing ids `highlights quick-start architecture modules sdks` are asserted by `check.sh`.
- Code blocks on `index.html` use `{% highlight %}` so they get the same Rouge markup as Markdown fences.

## Content rules

- Copy is sourced from the `Nanofaas/nanofaas` README; links point to `Nanofaas/nanofaas` (`main`) and `Nanofaas/nanolab`.
- Do not describe NanoFaaS as a research platform and do not claim production readiness or high availability.
- `docs/superpowers/` holds the design spec and plan; it is excluded from the build.
````

- [ ] **Step 3: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "Add README and CLAUDE.md"
```

- [ ] **Step 4: Ask the user for OK to publish**, then:

```bash
git branch -M main
gh repo create Nanofaas/nanofaas.github.io --public --source . --push \
  --description "Website for NanoFaaS" --homepage https://nanofaas.github.io
```

- [ ] **Step 5: Verify Pages is serving**

```bash
gh api repos/Nanofaas/nanofaas.github.io/pages -q '.status + " " + .html_url'
curl -sI https://nanofaas.github.io | head -1
```

Expected: `built https://nanofaas.github.io/` and `HTTP/2 200` (first build can take ~1 minute; if `/pages` returns 404, enable with `gh api -X POST repos/Nanofaas/nanofaas.github.io/pages -f 'source[branch]=main' -f 'source[path]=/'`).

- [ ] **Step 6: Ask the user for OK, then set the homepage on the main repo**

```bash
gh repo edit Nanofaas/nanofaas --homepage https://nanofaas.github.io
```
