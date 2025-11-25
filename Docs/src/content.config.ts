import { defineCollection, z } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema({
      extend: z.object({
        seo: z.object({
          title: z.string().optional(),
          description: z.string().optional(),
          canonicalUrl: z.string().url().optional(),
        }).optional(),
      }),
    }),
  }),
};
