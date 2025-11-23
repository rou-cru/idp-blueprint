// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import d2 from 'astro-d2'; // Change to default import

import sitemap from '@astrojs/sitemap';

import mdx from '@astrojs/mdx';

import expressiveCode from 'astro-expressive-code';

import icon from 'astro-icon';

import robotsTxt from 'astro-robots-txt';

import favicons from 'astro-favicons';

import yeskunallumami from '@yeskunall/astro-umami';

import mermaid from 'astro-mermaid';

// https://astro.build/config
export default defineConfig({
  site: 'https://idp-blueprint.roura.xyz',
  integrations: [starlight({
    title: 'IDP Blueprint',
    description: 'Enterprise-grade Internal Developer Platform Blueprint - Production-ready platform engineering stacks',
    social: [
      {
        icon: 'github',
        label: 'GitHub',
        href: 'https://github.com/rou-cru/idp-blueprint',
      },
    ],
    sidebar: [
      {
        label: 'Getting Started',
        collapsed: true,
        autogenerate: { directory: 'getting-started' },
      },
      {
        label: 'Operate',
        collapsed: true,
        autogenerate: { directory: 'operate' },
      },
      {
        label: 'Concepts',
        collapsed: true,
        autogenerate: { directory: 'concepts' },
      },
      {
        label: 'Architecture',
        collapsed: true,
        autogenerate: { directory: 'architecture' },
      },
      {
        label: 'Reference',
        collapsed: true,
        autogenerate: { directory: 'reference' },
      },
      {
        label: 'Components',
        collapsed: true,
        autogenerate: { directory: 'components' },
      },
    ],
    components: {
      Head: './src/components/SeoHead.astro',
      ThemeSelect: './src/components/ThemeSelect.astro', // Disable theme switcher
    },
    pagination: false,
  }), d2({
    theme: {
      dark: '200',
    },
    sketch: true,
  }), sitemap(), expressiveCode(), mdx(), mermaid(), icon(), robotsTxt(), favicons(), yeskunallumami({ id: 'placeholder-id' })],
});
