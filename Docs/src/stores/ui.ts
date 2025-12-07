import { atom } from 'nanostores';

/**
 * UI state management for global application UI
 */

// Mobile menu open/close state
export const isMobileMenuOpen = atom<boolean>(false);

// Toggle mobile menu
export function toggleMobileMenu() {
  isMobileMenuOpen.set(!isMobileMenuOpen.get());
}

// Close mobile menu
export function closeMobileMenu() {
  isMobileMenuOpen.set(false);
}

// Open mobile menu
export function openMobileMenu() {
  isMobileMenuOpen.set(true);
}
