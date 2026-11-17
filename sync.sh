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
  mkdir -p "projets/$slug"
  readme="projets/$slug/README.md"
  # Dépôt git avec remote : version de la branche par défaut sur GitHub (le dossier local peut être en retard).
  if git -C "$dir" remote get-url origin >/dev/null 2>&1 && git -C "$dir" fetch -q origin 2>/dev/null; then
    branch=$(git -C "$dir" ls-remote --symref origin HEAD | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')
    prefix=$(git -C "$dir" rev-parse --show-prefix)
    name=$(git -C "$dir" ls-tree --name-only "origin/$branch" -- "${prefix:-.}" | sed "s#^$prefix##" \
           | grep -iE '^readme[^/]*\.md$' | grep -vi backup | sort | head -1)
    [[ -n "$name" ]] && git -C "$dir" show "origin/$branch:$prefix$name" > "$readme"
    src="origin/$branch"
  else
    name=$(find "$dir" -maxdepth 1 -iname 'README*.md' ! -iname '*backup*' -exec basename {} \; | sort | head -1)
    [[ -n "$name" ]] && cp "$dir/$name" "$readme"
    src="local"
  fi
  if [[ ! -s "$readme" ]]; then
    echo "⚠️  pas de README : $path" >&2
    rm -rf "projets/$slug"
    continue
  fi

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
  echo "✓ $slug ($src)"
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
