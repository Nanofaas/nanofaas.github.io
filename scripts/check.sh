#!/bin/sh
# Build the site in Docker (system Ruby is too old for github-pages) and sanity-check _site/.
set -eu
cd "$(dirname "$0")/.."

# A throwaway Markdown page proves a tutorial gets the shared layout; it is removed on exit.
fixture=tutorials/zz-check-fixture.md
[ -d tutorials ] || { mkdir tutorials; created_dir=1; }
trap 'rm -f "$fixture"; [ -n "${created_dir:-}" ] && rmdir tutorials 2>/dev/null; true' EXIT
cat > "$fixture" <<'MD'
---
layout: default
title: Check fixture
---
# Check fixture

| A | B |
|---|---|
| 1 | 2 |

```bash
echo hello
```
MD

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
for id in highlights quick-start architecture modules recipes sdks; do
  grep -q "id=\"$id\"" "$page" || fail "section #$id missing"
done
grep -q 'class="highlight"' "$page" || fail "no Rouge-highlighted code blocks"
if grep -q 'CLI and Java example functions compile to GraalVM native executables and ship' "$page"; then
  fail "CLI does not ship as an image (README: services ship on Distroless)"
fi
n=$(grep -c 'class="module"' "$page" || true)
test "$n" -eq 12 || fail "expected 12 module cards, found $n"
for m in forecasting p2p-discovery; do grep -q "<code>$m</code>" "$page" || fail "module $m missing"; done
grep -q 'containerd/crun' "$page" || fail "containerd/crun backend not mentioned"
grep -q '/blob/main/LICENSE"' "$page" || fail "no link to the LICENSE file"

grep -q '<meta property="og:image" content="https://nanofaas.github.io/assets/img/og.png"' "$page" || fail "og:image missing"
grep -q 'twitter:card" content="summary_large_image"' "$page" || fail "large link preview card missing"
python3 -c "from PIL import Image; assert Image.open('_site/assets/img/og.png').size == (1200, 630)" || fail "og.png must be 1200x630"

tut=_site/tutorials/zz-check-fixture.html
test -f "$tut" || fail "Markdown tutorial page not built"
grep -q 'class="container prose"' "$tut" || fail "tutorial page not styled as prose"
grep -q '<table' "$tut" || fail "tutorial table not rendered"
grep -q 'class="highlight"' "$tut" || fail "tutorial code not highlighted"

grep -q 'class="skip-link" href="#main"' "$page" || fail "skip-to-content link missing"
grep -q '<main id="main"' "$page" || fail "main has no id for the skip link"
grep -q 'navigator.clipboard ?' "$page" || fail "copy button must handle a missing Clipboard API"

# every color-mix() declaration needs a plain fallback for the same property in the same rule
python3 - _site/assets/css/style.css <<'PY' || fail "color-mix() without fallback"
import re, sys
css = re.sub(r"/\*.*?\*/", "", open(sys.argv[1]).read(), flags=re.S)
bad = []
for sel, body in re.findall(r"([^{}]+)\{([^{}]*)\}", css):
    decls = [d.strip() for d in body.split(";") if ":" in d]
    for i, d in enumerate(decls):
        prop = d.split(":", 1)[0].strip()
        decorative = "gradient(" in d  # an ignored gradient just drops decoration
        has_fallback = any(x.split(":", 1)[0].strip() == prop and "color-mix(" not in x for x in decls[:i])
        if "color-mix(" in d and not decorative and not has_fallback:
            bad.append(sel.strip() + " " + prop)
print("no fallback:", bad) if bad else None
sys.exit(1 if bad else 0)
PY

grep -q 'href="https://unimib-datai.github.io/datai-website/"' "$page" || fail "DatAI link missing"
grep -q 'href="https://www.disco.unimib.it/en"' "$page" || fail "DISCo link missing"

# WCAG AA (4.5:1) for light-theme link text and white-on-primary button text
python3 - _site/assets/css/style.css <<'PY' || fail "light-theme contrast below 4.5:1"
import re, sys
css = open(sys.argv[1]).read()
root = dict(re.findall(r"--([\w-]+):\s*(#[0-9A-Fa-f]{6})", css.split("@media")[0]))
btn = re.search(r"\.btn-primary\s*\{[^}]*background:\s*var\(--([\w-]+)\)", css).group(1)
def lum(h):
    c = [int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    c = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def ratio(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)
pairs = {"accent/bg": (root["accent"], root["bg"]), "accent/bg-alt": (root["accent"], root["bg-alt"]),
         "btn-primary": ("#FFFFFF", root[btn])}
bad = {k: round(ratio(*v), 2) for k, v in pairs.items() if ratio(*v) < 4.5}
print("contrast fail:", bad) if bad else None
sys.exit(1 if bad else 0)
PY

echo "check ok"
