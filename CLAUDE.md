# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Jekyll site for NanoFaaS, published by GitHub Pages from `main` of `Nanofaas/nanofaas.github.io` (no Actions workflow; GitHub builds it with the `github-pages` gem, Jekyll 3.10).

## Commands

- `scripts/check.sh` — builds in Docker (`ruby:3.3`; system Ruby 2.6 is too old) and asserts on `_site/`: assets present, `docs/ scripts/ brand/` not published, section ids and module count, no "research" wording, Open Graph image, skip link, Clipboard-API guard, WCAG AA contrast of the light accent, `color-mix()` fallbacks. It also builds a throwaway `tutorials/zz-check-fixture.md` (deleted on exit) to prove a Markdown page gets the prose layout. Run after every change.
- `python3 -m http.server 4000 -d _site` — view the built site.
- `python3 scripts/make-assets.py` — regenerate `assets/img/*` (logo, dark variant, 64px mark, 1200×630 `og.png` link preview) from `brand/nanofaas-logo-transparent.png`.

Headless Chrome screenshots with `--window-size` are misleading: the viewport is clamped to ≥500px and follows the OS theme. Use Chrome DevTools Protocol (`Emulation.setDeviceMetricsOverride`, `Emulation.setEmulatedMedia`) to check phone widths and light/dark.

## Structure

- `_layouts/default.html` is the only layout: head (`{% seo %}`, Google Fonts), nav, footer, and the inline copy-button script (targets `.highlight > pre`, copies from `code`).
- `main` gets class `page.main_class`, defaulting to `container prose`; `index.html` sets `main_class: home` and builds its own `.section`s. Any new Markdown page with `layout: default` is styled as prose automatically.
- `assets/css/style.css` holds everything: tokens on `:root` with a `prefers-color-scheme: dark` override, then base, header/footer, code/Rouge colors, prose, landing sections, SVG diagram classes (`d-*`).
- Nav links use `/#id`, so they work from sub-pages. The landing ids `highlights quick-start architecture modules recipes sdks` are asserted by `check.sh`.
- Code blocks on `index.html` use `{% highlight %}` so they get the same Rouge markup as Markdown fences.

## Content rules

- Copy is sourced from the `Nanofaas/nanofaas` README; links point to `Nanofaas/nanofaas` (`main`) and `Nanofaas/nanolab`.
- Module facts (list, defaults, requirements, conflicts) come from upstream `platform/modules/*/module.properties` and module READMEs, which are newer than the top-level README (12 modules, not 10). `check.sh` asserts 12 module cards; update it when upstream adds or removes one.
- Do not describe NanoFaaS as a research platform and do not claim production readiness or high availability.
- `docs/superpowers/` holds the design spec and plan; it is excluded from the build.
