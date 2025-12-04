import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

export const collections = {
  docs: defineCollection({
    loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/docs' }),
    schema: z.object({
      title: z.string().optional(),
      description: z.string().optional(),
      sidebar: z.object({
        label: z.string().optional(),
        order: z.number().optional(),
      }).optional(),
      seo: z.object({
        title: z.string().optional(),
        description: z.string().optional(),
        canonicalUrl: z.string().url().optional(),
      }).optional(),
    }),
  }),
};
