// @ts-check
import { defineConfig } from 'astro/config';
import d2 from 'astro-d2';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';
import expressiveCode from 'astro-expressive-code';
import icon from 'astro-icon';
import robotsTxt from 'astro-robots-txt';
import favicons from 'astro-favicons';
import yeskunallumami from '@yeskunall/astro-umami';
import mermaid from 'astro-mermaid';
import svelte from '@astrojs/svelte';
import tailwind from '@astrojs/tailwind';
import remarkDirective from 'remark-directive';
import { remarkCallouts } from './src/utils/remark-callouts.ts';

// https://astro.build/config
export default defineConfig({
  site: 'https://idp-blueprint.roura.xyz',
  integrations: [
    // Code highlighting with custom theme
    expressiveCode({
      themes: ['github-dark-dimmed'],
      styleOverrides: {
        borderRadius: '0.75rem',
      },
    }),

    // MDX support with remark plugins
    mdx({
      remarkPlugins: [remarkDirective, remarkCallouts],
    }),

    // Svelte components
    svelte(),

    // Tailwind CSS
    tailwind({
      applyBaseStyles: false, // We'll handle base styles ourselves
    }),

    // D2 diagrams
    d2({
      theme: {
        dark: '200',
      },
      sketch: true,
    }),

    // Other integrations
    mermaid(),
    icon(),
    robotsTxt(),
    favicons(),
    sitemap(),
    yeskunallumami({ id: 'placeholder-id' }),
  ],

  markdown: {
    shikiConfig: {
      theme: 'github-dark-dimmed',
    },
  },
});
