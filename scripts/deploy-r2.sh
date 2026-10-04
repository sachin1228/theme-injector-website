#!/usr/bin/env bash
# ============================================================
# Deploy this site — including the large installers in
# downloads/ — to a Cloudflare R2 bucket.
#
#   bash scripts/deploy-r2.sh [bucket-name]
#
# Why R2: it puts no size cap that matters here (the 118 MB
# .dmg is fine), egress to the internet is free, and the page
# and its files stay in one folder with relative links — the
# buttons keep working exactly as they do in local preview.
#
# Free tier: 10 GiB-month storage, 10 million reads/month.
# The whole site is ~325 MB.
#
# Requires: node/npx. You authenticate once with:
#   npx wrangler login
# ============================================================
set -euo pipefail

BUCKET="${1:-theme-injector}"
SITE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SITE"

WRANGLER="npx --yes wrangler"

command -v npx >/dev/null 2>&1 || { echo "!! npx not found — install Node.js"; exit 1; }

# ---- preflight: the installers must be present and correct ----
[ -d downloads ] || { echo "!! No downloads/ folder. Run:  bash scripts/fetch-builds.sh"; exit 1; }
for f in ThemeInjector-1.0.0-windows-x64.exe ThemeInjector-1.0.0-macos-arm64.dmg ThemeInjector-1.0.0-macos-intel.dmg; do
  [ -f "downloads/$f" ] || { echo "!! Missing downloads/$f — run scripts/fetch-builds.sh first"; exit 1; }
done

# ---- auth check (never reads or moves your credentials) ----
if ! $WRANGLER whoami >/dev/null 2>&1; then
  echo "!! Not signed in to Cloudflare. Run this first, then re-run this script:"
  echo "     npx wrangler login"
  exit 1
fi

# ---- content types: a wrong type is the difference between the page
#     rendering and the browser offering to save index.html ----
ctype() {
  case "${1##*.}" in
    html) echo "text/html; charset=utf-8" ;;
    css)  echo "text/css; charset=utf-8" ;;
    js)   echo "text/javascript; charset=utf-8" ;;
    json) echo "application/json" ;;
    png)  echo "image/png" ;;
    jpg|jpeg) echo "image/jpeg" ;;
    svg)  echo "image/svg+xml" ;;
    mp4)  echo "video/mp4" ;;
    webm) echo "video/webm" ;;
    woff2) echo "font/woff2" ;;
    ico)  echo "image/x-icon" ;;
    txt)  echo "text/plain; charset=utf-8" ;;
    *)    echo "application/octet-stream" ;;
  esac
}

# ---- create the bucket if it does not exist yet ----
echo "-> Ensuring bucket '$BUCKET' exists"
$WRANGLER r2 bucket list 2>/dev/null | grep -qx "$BUCKET" || $WRANGLER r2 bucket create "$BUCKET"

# ---- upload: site files first, then the installers ----
upload() { # $1 = local path, $2 = object key, $3 = cache-control
  local ct cdisp=()
  ct="$(ctype "$1")"
  case "$1" in
    *.exe|*.dmg) cdisp=(--content-disposition "attachment; filename=\"${1##*/}\"") ;;
  esac
  printf '   %-52s -> %s/%s\n' "$1" "$BUCKET" "${2:-$1}"
  $WRANGLER r2 object put "$BUCKET/${2:-$1}" --file "$1" --content-type "$ct" \
    --cache-control "${3:-public, max-age=3600}" "${cdisp[@]}" --remote
}

echo "-> Uploading the page, styles, scripts and media"
upload index.html index.html "public, max-age=0, must-revalidate"
upload css/styles.css css/styles.css "public, max-age=604800"
upload js/main.js js/main.js "public, max-age=604800"
[ -f favicon.ico ] && upload favicon.ico favicon.ico "public, max-age=604800"
for a in assets/*; do [ -f "$a" ] && upload "$a" "$a" "public, max-age=604800"; done

echo "-> Uploading the installers (each is ~100 MB — this takes a few minutes)"
for f in downloads/*; do upload "$f" "$f" "public, max-age=2592000, immutable"; done

# ---- public access cannot be toggled from wrangler ----
cat <<EOF

OK  Everything is uploaded.

Last step (once, in the dashboard — Cloudflare does not expose this to the CLI):
  1. dash.cloudflare.com → R2 → Storage → '$BUCKET' → Settings
  2. Public development URL → Enable → type "allow" → Allow
     (fine to start; it is rate-limited and meant for non-production traffic)
     Better long term: Custom Domains → Add → e.g. dl.yourdomain.com
  3. Your download URLs become:
       https://pub-<hash>.r2.dev/index.html                 ← the site itself
       https://pub-<hash>.r2.dev/downloads/ThemeInjector-1.0.0-windows-x64.exe
       https://pub-<hash>.r2.dev/downloads/ThemeInjector-1.0.0-macos-arm64.dmg
       https://pub-<hash>.r2.dev/downloads/ThemeInjector-1.0.0-macos-intel.dmg

The page links the installers with relative paths (downloads/<file>), so hosting
index.html and the files in the same bucket means the buttons need no changes.
EOF
