#!/usr/bin/env bash
# Downloads the example-sentence corpus into tools/.corpus (git-ignored).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .corpus/books
for pkg in reuters inaugural state_union gutenberg; do
  [ -d ".corpus/$pkg" ] && continue
  curl -fsSL -o ".corpus/$pkg.zip" "https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/$pkg.zip"
  unzip -q -o ".corpus/$pkg.zip" -d .corpus && rm ".corpus/$pkg.zip"
done
python3 -c 'import yaml,sys; [print(b["repo"]) for b in yaml.safe_load(open("sources.yaml"))["books"]]' |
while read -r repo; do
  out=".corpus/books/$repo.txt"; [ -s "$out" ] && continue
  id="${repo##*_}"
  for f in "$id.txt" "$id-0.txt" "$id-8.txt"; do
    curl -fsSL -o "$out" "https://raw.githubusercontent.com/GITenberg/$repo/master/$f" 2>/dev/null && break
  done || { rm -f "$out"; echo "warning: could not fetch $repo" >&2; }
done
echo "corpus ready in tools/.corpus"
