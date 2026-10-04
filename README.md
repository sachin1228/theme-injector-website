# Theme Injector — website

Marketing and download site for **Theme Injector**, a one-switch theme engine for the
Freebuff desktop app. Dark-mode design language mirrors the app itself.

Unofficial community project — not affiliated with Codebuff, Inc.

## Structure

```
.
├── index.html              # single page: hero video + downloads + modals
├── css/styles.css          # design tokens + layout (app's own scale)
├── js/main.js              # platform detection, hero video, download modals
├── assets/                 # hero.mp4, hero-poster.jpg, logo, favicon, touch icon
├── scripts/publish-github.sh  # one-time: create repo + release with installers
└── vercel.json             # headers + clean URLs for Vercel
```

## Downloads

Installers are **not** committed (each is >90 MB — beyond GitHub's plain-git file
limit and Vercel's upload limit). They live in **GitHub Releases**; the download
buttons on the page link straight to:

`https://github.com/sachin1228/theme-injector-website/releases/download/v1.0.0/<file>`

Builds are unsigned. Each download button opens a per-platform modal with the
first-launch approval steps (Windows SmartScreen / macOS Gatekeeper).

## Local preview

```sh
python3 -m http.server 8765
# open http://127.0.0.1:8765/
```

## Deploy (Vercel)

1. Import `sachin1228/theme-injector-website` at vercel.com/new
2. Framework preset: **Other** — no build step, no output dir (static site)
3. Deploy. `vercel.json` supplies security headers and caching

## Publishing a release

Run once from this folder:

```sh
bash scripts/publish-github.sh
```

It creates the public repo, pushes `main`, and attaches the three installers from
`theme-studio/dist/` to release `v1.0.0`. Requires the
[gh CLI](https://cli.github.com) and `gh auth login`.

## License

MIT
