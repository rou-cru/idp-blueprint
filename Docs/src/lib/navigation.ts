/**
 * Navigation configuration for the documentation site
 */
import { getCollection } from 'astro:content';
import { SECTION_ORDER } from './site-config';

export interface NavItem {
  label: string;
  href?: string;
  contexts?: ('all' | 'infrastructure' | 'gitops' | 'observability' | 'security')[];
  items?: NavItem[];
}

// Internal interface for sorting to avoid @ts-ignore
interface SortableNavItem extends NavItem {
  order?: number;
  items?: SortableNavItem[];
}

export interface NavSection {
  label: string;
  collapsed: boolean;
  items: NavItem[];
}

// Internal interface for section building
interface SortableNavSection extends NavSection {
  items: SortableNavItem[];
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

export { siteConfig } from './site-config';

// Generate sidebar config dynamically
export async function getSidebarConfig(): Promise<NavSection[]> {
  const docs = await getCollection('docs');
  const sections: Record<string, SortableNavSection> = {};

  // Helper to get or create a section
  const getOrCreateSection = (key: string, label: string, collapsed: boolean = true) => {
    if (!sections[key]) {
      sections[key] = {
        label,
        collapsed,
        items: [],
      };
    }
    return sections[key];
  };

  for (const doc of docs) {
    if (doc.data.sidebar?.hidden) continue;

    const parts = doc.id.split('/');
    const topLevel = parts[0];

    // STRICT NAVIGATION POLICY:
    // Only include sections that are explicitly defined in the global SECTION_ORDER.
    // This automatically filters out 'index' pages, 'assets', utility folders,
    // and any other unconfigured content without needing manual exclusion lists.
    if (!SECTION_ORDER.includes(topLevel)) continue;

    const label = doc.data.sidebar?.label || doc.data.title || doc.id; // Fallback to id if title missing
    const order = doc.data.sidebar?.order || 999;
    const href = `/${doc.slug}`;

    if (topLevel === 'components' && parts.length > 2) {
      // Handle nested components structure: components/infrastructure/argocd
      const subCategory = parts[1];
      const componentsSection = getOrCreateSection('components', CATEGORY_LABELS['components'], true);

      // Map sub-categories to contexts
      const contextMap: Record<string, ('infrastructure' | 'gitops' | 'observability' | 'security')[]> = {
        'infrastructure': ['infrastructure'],
        'cicd': ['gitops'],
        'eventing': ['gitops'],
        'observability': ['observability'],
        'security': ['security'],
        'policy': ['security'],
        'developer-portal': ['infrastructure'], // Could also be 'all'
      };

      const contexts = contextMap[subCategory] || ['all'];

      // Find or create sub-section item
      let subSectionItem = componentsSection.items.find(item => item.label === CATEGORY_LABELS[subCategory]);
      if (!subSectionItem) {
        subSectionItem = {
          label: CATEGORY_LABELS[subCategory] || subCategory,
          contexts: contexts,
          items: []
        };
        componentsSection.items.push(subSectionItem);
      }

      if (subSectionItem.items) {
        subSectionItem.items.push({ label, href, order, contexts });
      }
    } else {
      // Standard sections (getting-started, architecture, etc. are 'all' contexts)
      const sectionLabel = CATEGORY_LABELS[topLevel] || topLevel;
      const section = getOrCreateSection(topLevel, sectionLabel, topLevel !== 'getting-started');
      section.items.push({ label, href, order, contexts: ['all'] });
    }
  }

  // Define section order and sort items
  const sortedSections = Object.entries(sections)
    .map(([key, section]) => ({
      key,
      ...section
    }))
    .sort((a, b) => {
      const aOrder = SECTION_ORDER.indexOf(a.key);
      const bOrder = SECTION_ORDER.indexOf(b.key);
      const aScore = aOrder === -1 ? Number.POSITIVE_INFINITY : aOrder;
      const bScore = bOrder === -1 ? Number.POSITIVE_INFINITY : bOrder;
      return aScore - bScore;
    });

  // Sort items within sections and clean up internal types
  return sortedSections.map(({ key, items, ...rest }) => {
    // Sort items
    items.sort((a, b) => (a.order || 999) - (b.order || 999));

    // Sort nested items (for components) and clean up
    const cleanedItems: NavItem[] = items.map(item => {
      if (item.items) {
        item.items.sort((a, b) => (a.order || 999) - (b.order || 999));
        return {
          label: item.label,
          href: item.href,
          items: item.items.map(subItem => ({
            label: subItem.label,
            href: subItem.href,
            // Exclude order and items if empty/undefined
          }))
        };
      }
      return {
        label: item.label,
        href: item.href,
        // Exclude order
      };
    });

    return {
      ...rest,
      items: cleanedItems
    };
  });
}
