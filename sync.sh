#!/usr/bin/env bash
# Recopie les README listés dans projets.tsv et régénère l'index README.md.
# Usage : ./sync.sh   (puis relire le diff avant de commit)
set -euo pipefail
cd "$(dirname "$0")"
SRC="${DOCS_ROOT:-$HOME/Documents}"

rm -rf projets && mkdir projets
index_body=""
current_cat=""

while IFS=$'\t' read -r slug path cat; do
  [[ -z "$slug" || "$slug" == \#* ]] && continue
  dir="$SRC/$path"
  readme=$(find "$dir" -maxdepth 1 -iname 'README*.md' ! -iname '*backup*' | sort | head -1)
  if [[ -z "$readme" ]]; then
    echo "⚠️  pas de README : $path" >&2
    continue
  fi
  mkdir -p "projets/$slug"
  cp "$readme" "projets/$slug/README.md"

  title=$(grep -m1 -E '^#[[:space:]]' "$readme" | sed -E 's/^#+[[:space:]]*//')
  # 1er paragraphe de texte après le titre, sur une ligne, sans gras, ≤ 180 car.
  desc=$(awk 'NR>1 && !started && /^[^#<>|`*!\-[:space:]]/ {started=1}
              started && /^[[:space:]]*$/ {exit}
              started {printf "%s ", $0}' "$readme" \
         | sed -E 's/\*\*//g; s/[[:space:]]+$//' \
         | awk '{ if (length($0) > 180) { s=substr($0,1,180); sub(/ [^ ]*$/, "", s); print s "…" } else print }')
  if [[ "$cat" != "$current_cat" ]]; then
    index_body+=$'\n'"## $cat"$'\n\n'
    current_cat="$cat"
  fi
  index_body+="- **[${title:-$slug}](projets/$slug/README.md)**${desc:+ — $desc}"$'\n'
  echo "✓ $slug"
done < projets.tsv

{
  echo "# Mes projets"
  echo
  echo "Les README de mes projets réunis en un seul endroit. Le code reste dans chaque dépôt ; ici, seulement la doc."
  echo
  echo "_Généré par \`sync.sh\` à partir de \`projets.tsv\`. Ne pas éditer à la main._"
  printf '%s' "$index_body"
} > README.md

echo "Index régénéré. Vérifier : git diff, puis ./check-secrets.sh"
