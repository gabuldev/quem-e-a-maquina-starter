#!/usr/bin/env bash
# Publica o app no Hosting do SEU projeto (o do `firebase use`).
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -f .firebaserc ]; then
  echo "Rode 'firebase use --add' antes e escolha o seu projeto." >&2
  exit 1
fi
flutter build web --release
firebase deploy --only hosting
