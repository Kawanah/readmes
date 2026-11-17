#!/usr/bin/env bash
# Recopie les README listés dans projets.tsv, les nettoie pour une lecture publique
# et régénère l'index README.md (intro.md + liste par catégorie, dans l'ordre du fichier).
# Usage : ./sync.sh   (puis relire le diff avant de commit)
set -euo pipefail
cd "$(dirname "$0")"
SRC="${DOCS_ROOT:-$HOME/Documents}"

# Traitement Markdown commun, en perl (fourni avec macOS) : un fichier par appel.
#   MODE=nettoyer  réécrit le fichier : citations « Vous reprenez ce site », chemins locaux, liens relatifs cassés
#   MODE=controler n'écrit rien, liste ce qui reste à corriger (liens relatifs cassés, chemins locaux)
# Les blocs de code (```) ne sont pas touchés par le traitement des liens.
# shellcheck disable=SC2016
PERL_MD='
use strict; use warnings;
my ($fichier) = @ARGV;
my $dossier = $fichier =~ m{/} ? $fichier =~ s{/[^/]*$}{}r : ".";
my $mode = $ENV{MODE};
local $/; open(my $in, "<:raw", $fichier) or die; my $texte = <$in>; close $in;

my $CHEMIN_LOCAL = qr{(?:~/Documents|/Users/[^/\s`]+)(?:/[^\s`)\]\x27"<>]*)?};

sub cible_cassee {
  my ($cible) = @_;
  return 0 if $cible =~ m{^(?:[a-z][a-z0-9+.-]*:|#|//)}i;   # http(s), mailto, ancre…
  my $chemin = $cible =~ s/[#?].*$//r;
  $chemin =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
  return 0 if $chemin eq "";
  return !-e "$dossier/$chemin";
}

my $LIEN = qr{(!?)\[((?:[^\[\]]|\[[^\]]*\])*)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)};

if ($mode eq "nettoyer") {
  # 1. Citations qui s adressent à un développeur qui reprend le projet.
  $texte =~ s{(?:^>[^\n]*\n?)+}{ my $b = $&; $b =~ /Vous reprenez ce site/ ? "" : $b }gme;
  $texte =~ s/\n{3,}/\n\n/g;
  # 2. Chemins locaux.
  $texte =~ s/$CHEMIN_LOCAL/dossier local/g;
  # 3. Liens relatifs cassés -> leur texte seul, hors blocs de code.
  my $dans_code = 0;
  $texte = join "", map {
    $dans_code = !$dans_code if /^\s*(```|~~~)/;
    my $l = $_;
    $l =~ s{$LIEN}{ cible_cassee($3) ? $2 : $& }ge unless $dans_code;
    $l;
  } split /(?<=\n)/, $texte;
  open(my $out, ">:raw", $fichier) or die; print $out $texte; close $out;
} else {
  my ($n, $dans_code) = (0, 0);
  for my $l (split /\n/, $texte) {
    $n++;
    $dans_code = !$dans_code if $l =~ /^\s*(```|~~~)/;
    unless ($dans_code) {
      while ($l =~ /$LIEN/g) { print "$fichier:$n: lien cassé -> $3\n" if cible_cassee($3) }
    }
    print "$fichier:$n: chemin local -> $&\n" while $l =~ /$CHEMIN_LOCAL/g;
  }
}
'

rm -rf projets && mkdir projets
index_body=""
current_cat=""

while IFS=$'\t' read -r slug path cat; do
  [[ -z "$slug" || "$slug" == \#* ]] && continue
  dir="$SRC/$path"
  mkdir -p "projets/$slug"
  readme="projets/$slug/README.md"
  # Chemin en ./ : README rédigé dans ce dépôt (projet au code privé, voir manuel/).
  if [[ "$path" == ./* ]]; then
    cp "$path" "$readme"
    src="manuel"
  # Dépôt git avec remote : version de la branche par défaut sur GitHub (le dossier local peut être en retard).
  elif git -C "$dir" remote get-url origin >/dev/null 2>&1 && git -C "$dir" fetch -q origin 2>/dev/null; then
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

  MODE=nettoyer perl -e "$PERL_MD" "$readme"

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
  cat intro.md
  printf '%s' "$index_body"
  echo
  echo "<!-- Généré par sync.sh à partir de intro.md et projets.tsv. Ne pas éditer à la main. -->"
} > README.md

# Contrôle final : rien ne doit rester cassé ni pointer vers un dossier local.
problemes=$(for f in README.md projets/*/README.md; do MODE=controler perl -e "$PERL_MD" "$f"; done)
if [[ -n "$problemes" ]]; then
  echo "❌ À corriger avant de publier :" >&2
  echo "$problemes" >&2
  exit 1
fi

echo "Index régénéré, liens et chemins vérifiés. Ensuite : ./check-secrets.sh puis git diff."
