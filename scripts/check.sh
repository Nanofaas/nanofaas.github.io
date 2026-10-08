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
