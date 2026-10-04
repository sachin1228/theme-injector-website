#!/usr/bin/env bash
# ============================================================
# Publish the installer builds to the Cloudflare R2 bucket the
# site links, then prove each object is live at the right size.
#
#   bash scripts/upload-r2.sh <bucket-name> [source-folder]
#
# Bucket name:  npx wrangler r2 bucket list
# Source folder defaults to the app repo's release/ output.
#
# Sign in once first:  npx wrangler login
# ============================================================
set -euo pipefail

BUCKET="${1:-}"
SRC="${2:-/Users/sachin/Documents/GitHub/freebuff-theme-injector/release}"
PUB="https://pub-09ca9e5f34964feb91e582deedda252d.r2.dev"

# Object keys must match the hrefs / data-file names in index.html exactly.
FILES=(
  ThemeInjector-1.0.0-windows-x64.exe
  ThemeInjector-1.0.0-macos-arm64.dmg
  ThemeInjector-1.0.0-macos-intel.dmg
)

[ -n "$BUCKET" ] || { echo "usage: bash scripts/upload-r2.sh <bucket-name> [source-folder]"; exit 1; }
[ -d "$SRC" ] || { echo "!! No such source folder: $SRC"; exit 1; }
command -v npx >/dev/null 2>&1 || { echo "!! npx not found — install Node.js"; exit 1; }
WRANGLER="npx --yes wrangler"
$WRANGLER whoami >/dev/null 2>&1 || { echo "!! Not signed in. Run:  npx wrangler login"; exit 1; }

echo "-> Uploading to bucket '$BUCKET' (object keys = filenames, at the root)"
for f in "${FILES[@]}"; do
  [ -f "$SRC/$f" ] || { echo "!! Missing build: $SRC/$f"; exit 1; }
  $WRANGLER r2 object put "$BUCKET/$f" --file "$SRC/$f" \
    --content-type "application/octet-stream" \
    --content-disposition "attachment; filename=\"$f\"" \
    --cache-control "public, max-age=2592000, immutable" --remote
done

echo "-> Verifying the live objects answer at the advertised size"
fail=0
for f in "${FILES[@]}"; do
  local_bytes=$(stat -f%z "$SRC/$f")
  live=$(curl -sI "$PUB/$f" | tr -d '\r')
  code=$(printf '%s\n' "$live" | awk 'NR==1{print $2}')
  size=$(printf '%s\n' "$live" | awk 'tolower($1)=="content-length:"{print $2}')
  if [ "$code" = "200" ] && [ "$size" = "$local_bytes" ]; then
    printf '   OK  %-42s %s bytes  %s\n' "$f" "$size" "$PUB/$f"
  else
    printf '   BAD %-42s http=%s size=%s (expected %s)\n' "$f" "$code" "$size" "$local_bytes"; fail=1
  fi
done

[ "$fail" = 0 ] || { echo "!! R2 did not confirm every object — check the bucket's public access settings."; exit 1; }
echo ""
echo "OK  All three links on the page now serve these objects."
