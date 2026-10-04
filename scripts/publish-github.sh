#!/usr/bin/env bash
# ============================================================
# Theme Injector — one-time GitHub publish (CLI path).
#
#   bash scripts/publish-github.sh
#
# 1. Creates the public repo sachin1228/theme-injector-website
#    (origin) and pushes main.
# 2. Creates release v1.0.0 and attaches the three installers
#    from the app's release/ folder.
#
# Requires the gh CLI (https://cli.github.com).
# If you are not logged in yet, run:  gh auth login
#
# Prefer the browser? The same result comes from repo → Releases →
# Draft a new release → tag v1.0.0 → drag the three files in. See README.
# ============================================================
set -euo pipefail

REPO="sachin1228/theme-injector-website"
TAG="v1.0.0"
# Final builds produced by the app repo (freebuff-theme-injector).
BUILD_DIR="/Users/sachin/Documents/GitHub/freebuff-theme-injector/release"

cd "$(dirname "$0")/.."

command -v gh >/dev/null 2>&1 || { echo "!! gh CLI not found — install from https://cli.github.com"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "!! Not logged in. Run:  gh auth login"; exit 1; }

# The asset names below are the hrefs baked into index.html, so the
# uploaded files must keep these exact names.
ASSETS=(
  "ThemeInjector-1.0.0-windows-x64.exe"
  "ThemeInjector-1.0.0-macos-arm64.dmg"
  "ThemeInjector-1.0.0-macos-intel.dmg"
)
for a in "${ASSETS[@]}"; do
  [ -f "$BUILD_DIR/$a" ] || { echo "!! Missing installer: $BUILD_DIR/$a"; exit 1; }
done

echo "-> Pushing source"
if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "$REPO" --public --source . --remote origin --push
else
  git push -u origin main
fi

echo "-> Publishing release $TAG"
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "   (release already exists — uploading/overwriting assets)"
  gh release upload "$TAG" --repo "$REPO" --clobber "${ASSETS[@]/#/$BUILD_DIR/}"
else
  gh release create "$TAG" \
    "${ASSETS[@]/#/$BUILD_DIR/}" \
    --repo "$REPO" \
    --title "Theme Injector v1.0.0" \
    --notes "First release — unsigned Windows (.exe) and macOS (.dmg, Apple Silicon + Intel) builds. First-launch approval guides are on the website."
fi

echo ""
echo "OK  Repo:    https://github.com/$REPO"
echo "OK  Release: https://github.com/$REPO/releases/tag/$TAG"
echo ""
echo "Next: import the repo at https://vercel.com/new (framework preset: Other, no build step)."
