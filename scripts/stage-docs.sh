#!/usr/bin/env bash
# Stage the root Markdown into ./docs so MkDocs has a valid docs_dir (it forbids docs_dir being the
# config's parent). The repo keeps its Markdown at the root (GitHub landing README + existing relative
# links); ./docs is a build-time copy, gitignored. Run by CI before `mkdocs build`, and locally before
# `mkdocs serve`.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf docs
mkdir -p docs/adr

# Top-level docs (everything except the toolchain files and this staging dir).
for f in *.md; do
  cp "$f" "docs/$f"
done
# ADRs (preserve the adr/ subpath so nav links resolve).
cp adr/*.md docs/adr/

echo "Staged $(find docs -name '*.md' | wc -l) markdown files into ./docs"
