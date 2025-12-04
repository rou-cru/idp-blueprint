# IDP Blueprint Documentation (Astro/Starlight)

This folder hosts the documentation site built with **Astro 5 + Starlight**.
Use these steps to work on docs locally and keep generated content in sync
with the codebase.

## Quick start

```bash
cd Docs
pnpm install      # first time
pnpm dev          # local site at http://localhost:4321
pnpm build        # outputs ./dist
pnpm preview      # serve the production build locally
```

> Tip: run inside the Dev Container or Devbox so Node/pnpm match the project.

## Layout

- `src/content/docs/` — all doc pages (md/mdx). Sidebar order comes from
  `sidebar.order` in front‑matter.
- `src/partials/helm-docs/` — generated Helm values tables consumed by
  component pages.
- `public/` — static assets (favicons, robots.txt, etc.).

## Regenerating Helm value partials

Component pages embed generated chart values. Refresh them when chart
versions change:

```bash
# from repo root
./Scripts/helm-docs-generate.sh
```

This script updates `src/partials/helm-docs/*_values.generated.md`, which are
imported by the component `.mdx` files.

## Linting & link checks

Run the same checks CI uses before a PR:

```bash
# from repo root
task lint                 # formatting
task check                # full quality suite
./Scripts/docs-linkcheck.sh  # validate outbound links
```

## Authoring guidelines

- Prefer `.mdx` when you need components; `.md` for text‑only pages.
- Keep `title`, optional `sidebar.label`, and `order` consistent to avoid
  sidebar gaps.
- Use relative links to existing files (e.g., `../architecture/overview`),
  not legacy MkDocs paths.
- Large images belong in `src/assets/images/`; reference them with relative
  paths.

## Publishing

`pnpm build` creates `Docs/dist`. Deploy that folder to your static host
(e.g., GitHub Pages, S3/CloudFront). The `docs.yaml` workflow already builds
the site—keep it green after changes.
