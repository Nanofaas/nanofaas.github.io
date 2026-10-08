# NanoFaaS landing page — design

## Goal

A developer landing on the site understands in ~30 seconds what NanoFaaS is and
how to try it, then goes to the repository. Content is sourced from the
`Nanofaas/nanofaas` README. Tutorials will be added later, so the site must make
adding a Markdown page trivial.

## Decisions

- **Scope:** single landing page. No docs site yet; "Docs" links to the repo's `docs/`.
- **Generator:** Jekyll, built natively by GitHub Pages (no Actions workflow, no Node).
- **Hosting:** new repo `Nanofaas/nanofaas.github.io` → `https://nanofaas.github.io`.
- **Language:** English.
- **Tone:** do not describe NanoFaaS as a research platform; make no production-readiness or HA claims.

## Structure

```
_config.yml              title, description, url, markdown: kramdown, highlighter: rouge,
                         exclude: docs/, Gemfile, README
_layouts/default.html    <head>, nav, footer, shared by every page
index.html               landing page (layout: default)
assets/css/style.css     single stylesheet, tokens on :root, dark mode, prose + rouge styles
assets/img/logo.png      resized logo, transparent background
assets/img/favicon.png   cloud mark only
Gemfile                  github-pages gem, local preview only
```

Extension path: a tutorial is `tutorials/<name>.md` with `layout: default` and a
`title`. The stylesheet already styles Markdown prose and highlighted code.
Deferred until tutorials exist: dedicated tutorial layout, `_data/` files, nav entry.

## Landing page sections

1. **Hero** — logo, "A minimal, modular Function-as-a-Service control plane.",
   one-sentence pitch, buttons: Get started (#quick-start), GitHub.
2. **Highlights** — 7 cards: build-time modularity; one API, three execution
   modes; interchangeable backends; concurrency control with SLOs; native builds;
   any language; reproducible distributions.
3. **Quick start** — three steps (control plane, example function, CLI register +
   invoke) with copy buttons and sample JSON output; async + curl variants.
4. **Architecture** — README Mermaid flowchart redrawn as inline SVG (client →
   control plane [core, optional modules, deployment provider] → managed
   instances / external endpoint), plus execution-modes table
   (DEPLOYMENT / EXTERNAL / LOCAL).
5. **Modules** — table of the 10 modules with purpose and default; note on
   `-PcontrolPlaneModules=<list|all|none>` and mutually exclusive providers.
6. **SDKs** — Java, Python, Go, JavaScript, Rust.
7. **Footer** — GitHub, Docs, NanoLab, MIT license.

## Visual

- Colors from the logo: navy `#0B2559`, electric blue `#1A7CFF`.
- Fonts (Google Fonts): Lexend headings, Inter body, JetBrains Mono code.
- Light theme + dark mode (`prefers-color-scheme`); SVG uses tokens so it works in both.
- Responsive to phone width, 16px side gutter, no horizontal scroll.
- JS: only the copy-to-clipboard buttons (~10 lines, inline).

## Verification

- `bundle exec jekyll build` succeeds (or GitHub Pages build if local Ruby is too old).
- Page viewed in a browser at desktop and phone widths, light and dark.
- All external links point to existing repo paths.

## Publishing (requires explicit user OK at each step)

1. Create `Nanofaas/nanofaas.github.io` and push.
2. Set it as homepage of `Nanofaas/nanofaas`.
