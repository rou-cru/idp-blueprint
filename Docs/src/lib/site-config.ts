export const siteConfig = {
  site: import.meta.env.SITE_URL || 'https://idp-blueprint.roura.xyz',
  title: 'IDP Blueprint',
  description:
    'Enterprise-grade Internal Developer Platform Blueprint - Production-ready platform engineering stacks',
  social: {
    github: import.meta.env.GITHUB_URL || 'https://github.com/rou-cru/idp-blueprint',
  },
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
