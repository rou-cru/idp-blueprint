---
title: Localization Plan
sidebar:
  label: Localization
  order: 99
---
---

The docs are English-only today. When we add another language, use Starlight's built-in locales to avoid manual duplication.

## Proposed approach

- Keep `en` as the default locale.
- When a second language is ready, enable Starlight `locales` in `astro.config.mjs` and create a parallel `src/content/<locale>/` tree.
- Use shared assets/components; only content files duplicate per locale.
- Keep navigation labels in English unless the new locale needs its own labels; Starlight reads labels per locale file.

## Minimal steps to add a new locale later

1. Add to `astro.config.mjs`:
   ```js
   // example
   // locales: {
   //   en: { label: 'English' },
   //   es: { label: 'Español' },
   // },
   // defaultLocale: 'en',
   ```
2. Create `src/content/es/` and copy the docs you want translated, preserving frontmatter keys.
3. Translate content; keep slugs/paths consistent so links stay stable.
4. Run `pnpm run build` to confirm locale routing works and navigation renders both languages.

## Editorial guardrails

- All PRs must keep the English version up to date first.
- Translations must match tone (concise, operator-focused) and avoid mixing languages in the same page.
- Prefer separate PRs per locale to keep reviews small.
