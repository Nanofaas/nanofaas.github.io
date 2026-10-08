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
