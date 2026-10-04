#!/usr/bin/env bash
# ============================================================
# Theme Injector — one-time GitHub publish.
#
#   bash scripts/publish-github.sh
#
# 1. Creates the public repo sachin1228/theme-injector-website
#    (origin) and pushes main.
# 2. Creates release v1.0.0 and attaches the three installers
#    built into theme-studio/dist/.
#
# Requires the gh CLI (https://cli.github.com).
# If you are not logged in yet, run:  gh auth login
# ============================================================
set -euo pipefail

REPO="sachin1228/theme-injector-website"
TAG="v1.0.0"
DIST="/Users/sachin/Documents/GitHub/freebuff theme injector desktop app/theme-studio/dist"

cd "$(dirname "$0")/.."

command -v gh >/dev/null 2>&1 || { echo "!! gh CLI not found — install from https://cli.github.com"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "!! Not logged in. Run:  gh auth login"; exit 1; }

# The electron-builder output keeps the productName ("Theme Injector ..."),
# but the site's download URLs use hyphenated names — stage copies so the
# release assets match the hrefs in index.html exactly (no %20 in URLs).
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

stage() { # $1 = dist filename, $2 = release filename
  [ -f "$DIST/$1" ] || { echo "!! Missing installer: $DIST/$1"; exit 1; }
  cp "$DIST/$1" "$STAGE/$2"
}

stage "Theme Injector Setup 1.0.0.exe"   "Theme-Injector-Setup-1.0.0.exe"
stage "Theme Injector-1.0.0-arm64.dmg"  "Theme-Injector-1.0.0-arm64.dmg"
stage "Theme Injector-1.0.0.dmg"        "Theme-Injector-1.0.0.dmg"

echo "-> Pushing source"
if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "$REPO" --public --source . --remote origin --push
else
  git push -u origin main
fi

echo "-> Publishing release $TAG"
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "   (release already exists — uploading/overwriting assets)"
  gh release upload "$TAG" --repo "$REPO" --clobber "$STAGE"/*
else
  gh release create "$TAG" \
    "$STAGE"/* \
    --repo "$REPO" \
    --title "Theme Injector v1.0.0" \
    --notes "First release — unsigned Windows (.exe) and macOS (.dmg, Apple Silicon + Intel) builds. First-launch approval guides are on the website."
fi

echo ""
echo "OK  Repo:    https://github.com/$REPO"
echo "OK  Release: https://github.com/$REPO/releases/tag/$TAG"
echo ""
echo "Next: import the repo at https://vercel.com/new (framework preset: Other, no build step)."
