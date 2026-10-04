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

| Asset (exact name matters) | Size | Platform |
| --- | --- | --- |
| `ThemeInjector-1.0.0-windows-x64.exe` | 93 MB | Windows 10/11 x64 (NSIS) |
| `ThemeInjector-1.0.0-macos-arm64.dmg` | 113 MB | macOS · Apple Silicon |
| `ThemeInjector-1.0.0-macos-intel.dmg` | 118 MB | macOS · Intel |

The three `href`s in `index.html`, the `data-file` labels on the buttons and the
text inside the download modals all quote these names, so an asset must be
uploaded under exactly the name it links to.

Builds are unsigned. Each download button opens a per-platform modal with the
first-launch approval steps (Windows SmartScreen / macOS Gatekeeper).

## Local preview

```sh
python3 -m http.server 8765
# open http://127.0.0.1:8765/
```

(Python's server ignores HTTP range requests, so the hero video can't be
scrubbed locally — playback from the start works fine. Any range-capable static
server behaves like production.)

## Deploy (Vercel)

1. Import `sachin1228/theme-injector-website` at vercel.com/new
2. Framework preset: **Other** — no build step, no output dir (static site)
3. Deploy. `vercel.json` supplies security headers and caching

## Publishing a release

The installers are built in the app repo,
`/Users/sachin/Documents/GitHub/freebuff-theme-injector/release/`.

**In the browser** (no tooling needed): create the public repo
`sachin1228/theme-injector-website` and push `main`, then open
*Releases → Draft a new release*, set the tag to `v1.0.0`, drag the three files
above into the assets box, and publish. The buttons on the site work the moment
the assets are there.

**From the CLI** instead:

```sh
bash scripts/publish-github.sh
```

It creates the repo, pushes `main`, and attaches the three installers from the
app's `release/` folder to release `v1.0.0`. Requires the
[gh CLI](https://cli.github.com) and `gh auth login`.

### Version bumps

Rebuild the app, upload the new assets to a new tag, then update in `index.html`:
the tag in the three `href`s, the three filenames, the `data-file` / `data-size`
attributes, the visible `.dl-meta` sizes, and the Windows modal's file line.

## License

MIT
