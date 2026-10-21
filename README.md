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

## Write a post

Create `_posts/YYYY-MM-DD-slug.md`; it is published at `/blog/slug/` and the newest three posts appear on the landing page.

```markdown
---
title: "NanoFaaS 1.0"
description: "One or two sentences for the post cards and link previews."
image: /assets/blog/slug/preview.png   # optional, 1200×630; defaults to the site's og.png
---
The post, in Markdown.
```

Images go in `assets/blog/slug/`. Put unfinished posts in `_drafts/` (no date in the file name) and preview them with `bundle exec jekyll serve --drafts`. A post dated in the future is skipped until the site is rebuilt after that date. Pushing to `main` publishes, so run `scripts/check.sh` first.

From a browser, <https://nanofaas.github.io/blog/new/> (not linked from the site) builds the file name and front matter and opens GitHub's editor.

## Logo

Source files live in `brand/`. Regenerate `assets/img/` with `python3 scripts/make-assets.py` (needs Pillow).
