import { defineCollection, z } from 'astro:content';
export const collections = {
  docs: defineCollection({
    type: 'content',
    schema: z.object({
      title: z.string().optional(),
      description: z.string().optional(),
      layout: z.string().optional(),
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
