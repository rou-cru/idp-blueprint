export const siteConfig = {
  site: import.meta.env.SITE_URL || 'https://idp-blueprint.roura.xyz',
  title: 'IDP Blueprint',
  description:
    'Enterprise-grade Internal Developer Platform Blueprint - Production-ready platform engineering stacks',
  social: {
    github: import.meta.env.GITHUB_URL || 'https://github.com/rou-cru/idp-blueprint',
    twitter: import.meta.env.TWITTER_HANDLE || '@rou_cru',
    linkedin: import.meta.env.LINKEDIN_URL || 'https://www.linkedin.com/in/alberto-roura/',
  },
  brandSite: import.meta.env.BRAND_SITE || 'https://roura.xyz',
  ogImage: import.meta.env.OG_IMAGE || 'https://roura.xyz/api/og',
  analytics: {
    umamiId: import.meta.env.UMAMI_ID || '',
  },
};

export const SECTION_ORDER = [
  'getting-started',
  'architecture',
  'concepts',
  'operate',
  'operations',
  'components',
  'reference',
];

export function canonicalUrl(pathname: string): string {
  const base = siteConfig.site.replace(/\/$/, '');
  const path = pathname.startsWith('/') ? pathname : `/${pathname}`;
  return `${base}${path}`;
}

export function isAnalyticsEnabled(): boolean {
  return Boolean(siteConfig.analytics.umamiId);
}
