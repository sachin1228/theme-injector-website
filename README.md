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
├── scripts/upload-r2.sh    # publish new builds to the R2 bucket + verify them
├── scripts/publish-github.sh  # alternative host: attach builds to a GitHub Release
└── vercel.json             # headers + clean URLs
```

## Downloads

The installers are **not** in this repository — they are objects in a Cloudflare
R2 bucket, which serves them directly and charges nothing for egress. Each
button's `href` is that object's URL:

| Object (name matters) | Size | Platform |
| --- | --- | --- |
| `ThemeInjector-1.0.0-windows-x64.exe` | 93 MB | Windows 10/11 x64 (NSIS) |
| `ThemeInjector-1.0.0-macos-arm64.dmg` | 113 MB | macOS · Apple Silicon |
| `ThemeInjector-1.0.0-macos-intel.dmg` | 118 MB | macOS · Intel |

Base URL: `https://pub-09ca9e5f34964feb91e582deedda252d.r2.dev/`

Click → the browser saves the file (objects are `application/octet-stream`, and
the link carries `download`), and the same click opens the per-platform guide
modal, because unsigned builds need one-time approval (SmartScreen / Gatekeeper).
The `<a href>` works with JavaScript disabled too.

The `href`s, the buttons' `data-file` labels and the text inside the modals all
quote the same filenames, so a build must be uploaded under exactly the name the
page links.

## Hosting

The page itself is static (no build step, ~1 MB of assets), so any host takes
it — Vercel's free plan is fine because the large files live in R2 instead:

1. Import the repo at vercel.com/new → framework preset **Other** → no build
   command, no output directory → Deploy.
2. `vercel.json` supplies the security headers and week-long asset caching.

Why the installers are off the page host: [Vercel's free plan caps a single file
at 100 MB](https://vercel.com/docs/limits) and
[Cloudflare Pages / Workers assets at 25 MiB](https://developers.cloudflare.com/pages/platform/limits/),
so both `.dmg` files exceed them; R2 has no such cap in practice and GitHub
refuses files over 100 MB in a repository.

To publish new builds:

```sh
npx wrangler login                      # once
bash scripts/upload-r2.sh <bucket-name> # uploads + verifies each object's size
```

`scripts/publish-github.sh` is the alternative (GitHub Releases, 2 GB/file free);
switching to it means pointing the three `href`s at
`https://github.com/sachin1228/theme-injector-website/releases/download/v1.0.0/<file>`.

## Local preview

```sh
python3 -m http.server 8765
# open http://127.0.0.1:8765/  — buttons download straight from R2
```

(Python's server ignores HTTP range requests, so the hero video can't be
scrubbed locally — playback from the start works fine. Any range-capable static
server behaves like production.)

### Version bumps

Rebuild the app into its `release/` folder → `bash scripts/upload-r2.sh <bucket>`
with the new filenames → update in `index.html`: the three `href`s, the
`data-file` / `data-size` attributes, the visible `.dl-meta` lines, the Windows
modal's file line, and the footer tag.

## License

MIT
