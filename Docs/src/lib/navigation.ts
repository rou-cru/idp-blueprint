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

export const CATEGORY_LABELS: Record<string, string> = {
  'getting-started': 'Getting Started',
  'architecture': 'Architecture',
  'concepts': 'Concepts',
  'operate': 'Operate',
  'components': 'Components',
  'reference': 'Reference',
  // Sub-categories for components
  'infrastructure': 'Infrastructure',
  'observability': 'Observability',
  'cicd': 'CI/CD',
  'security': 'Security',
  'policy': 'Policy',
  'developer-portal': 'Developer Portal',
  'eventing': 'Eventing',
};

// Site metadata
export const siteConfig = {
  title: 'IDP Blueprint',
  description: 'Enterprise-grade Internal Developer Platform Blueprint - Production-ready platform engineering stacks',
  url: 'https://idp-blueprint.roura.xyz',
  social: {
    github: 'https://github.com/rou-cru/idp-blueprint',
  },
};
