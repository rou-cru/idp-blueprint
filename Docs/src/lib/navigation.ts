/**
 * Navigation configuration for the documentation site
 * This replaces the previous Starlight sidebar configuration
 */

export interface NavItem {
  label: string;
  href?: string;
  items?: NavItem[];
}

export interface NavSection {
  label: string;
  collapsed: boolean;
  items: NavItem[];
}

export const sidebarConfig: NavSection[] = [
  {
    label: 'Getting Started',
    collapsed: false,
    items: [
      { label: 'Overview', href: '/getting-started/overview' },
      { label: 'Prerequisites', href: '/getting-started/prerequisites' },
      { label: 'Quickstart', href: '/getting-started/quickstart' },
      { label: 'Deployment', href: '/getting-started/deployment' },
      { label: 'Verify Installation', href: '/getting-started/verify' },
    ],
  },
  {
    label: 'Operate',
    collapsed: true,
    items: [
      // Will be populated when we scan the directory
    ],
  },
  {
    label: 'Concepts',
    collapsed: true,
    items: [
      // Will be populated when we scan the directory
    ],
  },
  {
    label: 'Architecture',
    collapsed: true,
    items: [
      // Will be populated when we scan the directory
    ],
  },
  {
    label: 'Reference',
    collapsed: true,
    items: [
      // Will be populated when we scan the directory
    ],
  },
  {
    label: 'Components',
    collapsed: true,
    items: [
      // Will be populated when we scan the directory
    ],
  },
];

// Site metadata
export const siteConfig = {
  title: 'IDP Blueprint',
  description: 'Enterprise-grade Internal Developer Platform Blueprint - Production-ready platform engineering stacks',
  url: 'https://idp-blueprint.roura.xyz',
  social: {
    github: 'https://github.com/rou-cru/idp-blueprint',
  },
};
