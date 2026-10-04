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
├── downloads/              # the three installers (gitignored — see below)
├── scripts/fetch-builds.sh # copy + verify the installers into downloads/
├── scripts/deploy-r2.sh    # publish site + installers to Cloudflare R2
├── scripts/publish-github.sh  # alternative: GitHub Releases assets
└── vercel.json             # headers + clean URLs
```

## Downloads

Each button links a file that lives **inside this site**, at a relative path:

```
downloads/ThemeInjector-1.0.0-windows-x64.exe    93 MB   Windows 10/11 x64 (NSIS)
downloads/ThemeInjector-1.0.0-macos-arm64.dmg   113 MB   macOS · Apple Silicon
downloads/ThemeInjector-1.0.0-macos-intel.dmg   118 MB   macOS · Intel
```

Click → the browser saves the file, and the same click opens the per-platform
guide modal, because unsigned builds need one-time approval (SmartScreen /
Gatekeeper). The `<a href>` works with JavaScript disabled too;
`vercel.json` adds `Content-Disposition: attachment` for `/downloads/*`.

The three `href`s, the buttons' `data-file` labels and the text inside the
modals all quote these names, so a build must be published under exactly the
name the page links.

`downloads/` is in `.gitignore` on purpose: the two `.dmg` files are over
GitHub's 100 MB per-file limit for repositories. Put them there with:

```sh
bash scripts/fetch-builds.sh          # copies from the app repo's release/ and
                                      # verifies each SHA-256 against the source
```

## Hosting

The site is static — no build step. It needs a host that will serve a 118 MB
file, which rules out most free tiers for the `.dmg`s:

| Host | Largest file it accepts | Verdict |
| --- | --- | --- |
| Cloudflare R2 (public bucket / custom domain) | effectively unlimited; free egress, 10 GiB storage free | **recommended** — `bash scripts/deploy-r2.sh` |
| Vercel Pro | 1 GB per file ([limits](https://vercel.com/docs/limits)) | fine, paid |
| Vercel Hobby (free) | **100 MB per file** | the page deploys; both `.dmg`s exceed the cap |
| Cloudflare Pages / Workers assets | 25 MiB per file ([limits](https://developers.cloudflare.com/pages/platform/limits/)) | no |
| Any VPS / own nginx | whatever the disk holds | fine — `rsync` the folder |

If you specifically want the free GitHub route instead, `scripts/publish-github.sh`
attaches the same three files to a GitHub Release and the only change needed is
pointing the `href`s at `https://github.com/sachin1228/theme-injector-website/releases/download/v1.0.0/<file>`.

## Local preview

```sh
python3 -m http.server 8765
# open http://127.0.0.1:8765/  — the download buttons work here already
```

(Python's server ignores HTTP range requests, so the hero video can't be
scrubbed locally — playback from the start works fine. Any range-capable static
server behaves like production.)

### Version bumps

Rebuild the app into its `release/` folder → `bash scripts/fetch-builds.sh` →
update the version in the three `href`s, the `data-file` / `data-size`
attributes, the visible `.dl-meta` lines, the Windows modal's file line and the
footer tag → re-run `scripts/deploy-r2.sh` (or `publish-github.sh`).

## License

MIT
