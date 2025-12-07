/**
 * Path normalization utilities
 */

/**
 * Normalizes a path by removing trailing slashes.
 * Preserves the root '/' if the path is just '/'.
 * Returns empty string for undefined/null input.
 * 
 * @param path The path to normalize
 */
export function normalizePath(path: string | undefined | null): string {
  if (!path) return '';
  if (path === '/') return '/';
  // Remove trailing slash
  return path.replace(/\/$/, '');
}

/**
 * Checks if a candidate path matches the current path.
 * Useful for active state in navigation.
 * 
 * @param currentPath The current browser path
 * @param candidateHref The link href to check against
 */
export function isPathActive(currentPath: string, candidateHref: string | undefined): boolean {
  const normCurrent = normalizePath(currentPath);
  const normCandidate = normalizePath(candidateHref);
  
  if (!normCandidate) return false;
  return normCurrent === normCandidate;
}
