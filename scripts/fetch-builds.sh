#!/usr/bin/env bash
# ============================================================
# Copy the three final installer builds into this site's
# downloads/ folder and prove the copies are faithful.
#
#   bash scripts/fetch-builds.sh [source-folder]
#
# Default source: the app repo's release/ folder.
# downloads/ is gitignored on purpose — the installers are
# 93-118 MB each, over GitHub's 100 MB file limit.
# ============================================================
set -euo pipefail

SRC="${1:-/Users/sachin/Documents/GitHub/freebuff-theme-injector/release}"
SITE="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$SITE/downloads"

FILES=(
  ThemeInjector-1.0.0-windows-x64.exe
  ThemeInjector-1.0.0-macos-arm64.dmg
  ThemeInjector-1.0.0-macos-intel.dmg
)

[ -d "$SRC" ] || { echo "!! No such source folder: $SRC"; exit 1; }
mkdir -p "$DEST"

echo "-> Copying from $SRC"
for f in "${FILES[@]}"; do
  [ -f "$SRC/$f" ] || { echo "!! Missing build: $SRC/$f"; exit 1; }
  # -p keeps mtime so an unchanged build is easy to spot
  cp -p "$SRC/$f" "$DEST/$f"
done

echo "-> Verifying byte-for-byte"
fail=0
for f in "${FILES[@]}"; do
  a=$(shasum -a 256 "$SRC/$f" | cut -d' ' -f1)
  b=$(shasum -a 256 "$DEST/$f" | cut -d' ' -f1)
  if [ "$a" = "$b" ]; then
    printf '   OK  %-42s %s\n' "$f" "$(ls -lh "$DEST/$f" | awk '{print $5}')"
    printf '       sha256 %s\n' "$a"
  else
    printf '   BAD %s (source %s != copy %s)\n' "$f" "$a" "$b"; fail=1
  fi
done
[ "$fail" = 0 ] || { echo "!! Copies do not match the builds — do not deploy."; exit 1; }

echo ""
echo "OK  $DEST holds all three installers, identical to the source builds."
echo "    The site's download buttons link these paths directly:"
for f in "${FILES[@]}"; do echo "      downloads/$f"; done
