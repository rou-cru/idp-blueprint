# Migration Plan: MkDocs to Astro Starlight

## Context
We are migrating the IDP Blueprint documentation from MkDocs Material to Astro Starlight to achieve a cleaner, more customizable UI (specifically for header/footer control and responsive layout) and to modernize the stack. The project is now using `pnpm`.

## Current State (Branch: `migration/astro-starlight`)
- **Status:** Migration functionally complete. Build passes.
- **Cleanup:** `mkdocs.yml`, `overrides/`, and `site/` directories have been removed from the root.
- **Backup:** `Docs_temp_backup/` has been removed after successful verification.
- **Initialization:** The Astro Starlight project is active in `Docs/`.

## Completed Actions

### 1. Content Restoration
- Moved markdown files to `Docs/src/content/docs/`.
- Ensured directory structure matches the original navigation tree.

### 2. Configuration (Starlight)
- **Navigation:** Replicated the `nav` structure in `Docs/astro.config.mjs`.
- **Title & Metadata:** Set site title and description.
- **Search:** Default search enabled.

### 3. Feature Migration
- **SEO:** implemented via `HeadMeta.astro` and `seo` frontmatter.
- **Diagrams:** `astro-d2` configured and working.
- **Styles:** Custom styles migrated to `Docs/src/styles/custom.css`.
- **Fixes:** Frontmatter additions, asset path fixes, URL configuration.
- **Admonitions & Tabs:** Verified.

### 4. Finalization
- **Footer/Header:** Configured.
- **Clean up:** Backup directory removed.

## Pending / Follow-up Items
- **Syntax Highlighting:** The build produces warnings for missing languages: `promql`, `logql`. These fall back to `txt`. Need to add these languages to the Astro configuration or finding a compatible grammar bundle for `expressive-code`.
