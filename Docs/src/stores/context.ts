import { atom } from 'nanostores';

/**
 * Context/Stack switcher state management
 * Allows users to filter documentation by platform component context
 */

export type ContextType = 'all' | 'infrastructure' | 'gitops' | 'observability' | 'security';

export const currentContext = atom<ContextType>('all');

export const CONTEXTS = [
  { value: 'all' as const, label: 'All Components', icon: 'lucide:layers' },
  { value: 'infrastructure' as const, label: 'Infrastructure', icon: 'lucide:server' },
  { value: 'gitops' as const, label: 'GitOps & CI/CD', icon: 'lucide:git-branch' },
  { value: 'observability' as const, label: 'Observability', icon: 'lucide:activity' },
  { value: 'security' as const, label: 'Security & Policy', icon: 'lucide:shield' },
] as const;

// Set context and persist to localStorage
export function setContext(context: ContextType) {
  currentContext.set(context);
  if (typeof window !== 'undefined') {
    localStorage.setItem('idp-docs-context', context);
  }
}

// Load context from localStorage on init
export function loadPersistedContext() {
  if (typeof window !== 'undefined') {
    const persisted = localStorage.getItem('idp-docs-context') as ContextType | null;
    if (persisted && CONTEXTS.some(c => c.value === persisted)) {
      currentContext.set(persisted);
    }
  }
}
