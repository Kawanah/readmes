#!/usr/bin/env bash
# Cherche des motifs sensibles dans les README copiés. Sortie vide = rien trouvé.
cd "$(dirname "$0")"
grep -rnEi \
  -e '(sk-[a-z0-9_-]{20,}|sk_live|pk_live|ghp_[a-z0-9]{20,}|xox[bp]-|AKIA[0-9A-Z]{16}|eyJ[a-zA-Z0-9_-]{20,}\.)' \
  -e '(api[_-]?key|secret|token|password|mot de passe)\s*[:=]\s*["'"'"']?[a-z0-9_\-]{12,}' \
  -e '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}' \
  -e '(\+33|0)[1-9]([ .-]?[0-9]{2}){4}' \
  -e 'postgres(ql)?://[^ ]*:[^ ]*@' \
  projets/ || true
