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
