# Figures for the NanoFaaS 0.23.0 post

TikZ sources for `assets/blog/nanofaas-0-23-0/`: `modules.tex` is the module map
(light and dark variants, colors from `palette.tex`, which mirrors the site's CSS
tokens) and `preview.tex` is the 1200×630 link-preview card. Rebuild from this
directory; needs LuaLaTeX with Inter and JetBrains Mono installed, and poppler's
`pdftocairo`:

```bash
out=../../../assets/blog/nanofaas-0-23-0; tmp=$(mktemp -d)
for t in light dark; do
  lualatex -interaction=nonstopmode -halt-on-error -output-directory="$tmp" -jobname="modules-$t" "\def\theme{$t}\input{modules.tex}"
  pdftocairo -svg "$tmp/modules-$t.pdf" "$out/modules-$t.svg"
done
lualatex -interaction=nonstopmode -halt-on-error -output-directory="$tmp" preview.tex
pdftocairo -png -singlefile -scale-to-x 1200 -scale-to-y 630 "$tmp/preview.pdf" "$out/preview"
```
