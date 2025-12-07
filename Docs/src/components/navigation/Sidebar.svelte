<script lang="ts">
  import Icon from '@iconify/svelte';
  import type { NavSection, NavItem } from '../../lib/navigation';
  import { isMobileMenuOpen, closeMobileMenu } from '../../stores/ui';
  import { currentContext } from '../../stores/context';
  import ContextSwitcher from './ContextSwitcher.svelte';

  interface Props {
    currentPath: string;
    sidebarConfig: NavSection[];
  }

  let { currentPath, sidebarConfig }: Props = $props();

  // Helper to normalize paths for comparison
  function normalize(path: string | undefined): string {
    if (!path) return '';
    // Remove trailing slash, but preserve root '/'
    return path.replace(/\/$/, '') || '/';
  }

  function isActive(href: string | undefined): boolean {
    const normHref = normalize(href);
    if (!normHref) return false; // Don't match empty hrefs (groups)
    return normalize(currentPath) === normHref;
  }

  // Find which section contains the active link to open it by default
  function getInitialSection(): string | null {
    const normalizedCurrent = normalize(currentPath);
    if (!normalizedCurrent) return null;
    
    // Recursive check for active item
    const hasActiveItem = (items: NavItem[]): boolean => {
      return items.some(item => {
        const normItemHref = normalize(item.href);
        if (normItemHref && normItemHref === normalizedCurrent) return true;
        if (item.items) return hasActiveItem(item.items);
        return false;
      });
    };

    for (const section of sidebarConfig) {
      if (hasActiveItem(section.items)) return section.label;
    }
    // Don't default to the first section blindly, return null if no match
    return null;
  }

  // Track the single expanded section
  let expandedSection = $state<string | null>(getInitialSection());

  function toggleSection(sectionLabel: string) {
    if (expandedSection === sectionLabel) {
      expandedSection = null;
    } else {
      expandedSection = sectionLabel;
    }
  }

  function handleLinkClick() {
    closeMobileMenu();
  }

  // Filter items based on current context
  function filterItemsByContext(items: NavItem[]): NavItem[] {
    if ($currentContext === 'all') return items;

    return items
      .map(item => {
        // Check if item matches current context
        const matchesContext = !item.contexts || item.contexts.includes($currentContext) || item.contexts.includes('all');

        if (!matchesContext) return null;

        // If item has children, filter them recursively
        if (item.items) {
          const filteredChildren = filterItemsByContext(item.items);
          if (filteredChildren.length === 0) return null;
          return { ...item, items: filteredChildren };
        }

        return item;
      })
      .filter((item): item is NavItem => item !== null);
  }

  // Filtered sidebar config based on context
  $: filteredSidebarConfig = sidebarConfig.map(section => ({
    ...section,
    items: filterItemsByContext(section.items)
  })).filter(section => section.items.length > 0);
</script>

{#snippet renderItems(items: NavItem[], depth: number = 0)}
  <div class="flex flex-col gap-0.5">
    {#each items as item}
      {#if item.items && item.items.length > 0}
        <!-- Group / Folder -->
        <div class="flex flex-col">
          <!-- Group Label -->
          <div 
            class="px-3 py-1.5 mt-2 mb-1 text-[0.65rem] font-bold uppercase tracking-wider text-text-tertiary select-none"
            style="padding-left: {depth === 0 ? '0.75rem' : `${depth * 0.75 + 0.75}rem`}"
          >
            {item.label}
          </div>
          <!-- Recursive Children -->
          {@render renderItems(item.items, depth + 1)}
        </div>
      {:else}
        <!-- Leaf Link -->
        <a
          href={item.href}
          class="block py-1.5 rounded-md text-sm text-text-secondary no-underline transition-all duration-200 border border-transparent hover:text-text-primary hover:bg-bg-hover"
          class:text-text-primary={isActive(item.href)}
          class:bg-bg-active={isActive(item.href)}
          class:font-medium={isActive(item.href)}
          style="padding-left: {depth === 0 ? '0.75rem' : `${depth * 0.75 + 0.75}rem`}; padding-right: 0.75rem;"
          onclick={handleLinkClick}
        >
          {item.label}
        </a>
      {/if}
    {/each}
  </div>
{/snippet}

<aside
  class="fixed left-0 z-40 -translate-x-full lg:translate-x-0 transition-transform duration-300 bg-bg-base border-r border-border-default overflow-y-auto top-header-h h-[calc(100vh-theme(spacing.header-h))] w-sidebar-w scrollbar-thin scrollbar-thumb-ui-scrollbar-thumb scrollbar-track-transparent hover:scrollbar-thumb-ui-scrollbar-hover"
  class:translate-x-0={$isMobileMenuOpen}
>
  <div class="pt-6">
    <ContextSwitcher />
  </div>

  <nav class="flex flex-col gap-2 px-6 pb-20">
    {#each filteredSidebarConfig as section}
      <div class="flex flex-col">
        <button
          class="group flex items-center justify-between w-full px-3 py-2 rounded-md text-xs font-semibold uppercase tracking-wider text-text-secondary bg-transparent border-0 cursor-pointer transition-all duration-200 text-left hover:text-text-primary hover:bg-bg-hover"
          class:text-text-primary={expandedSection === section.label}
          onclick={() => toggleSection(section.label)}
          aria-expanded={expandedSection === section.label}
        >
          <span class="section-label">{section.label}</span>
          <Icon
            icon="lucide:chevron-down"
            width="16"
            height="16"
            class="transition-transform duration-200 text-text-tertiary group-hover:text-text-secondary {expandedSection === section.label ? 'rotate-180' : ''}"
          />
        </button>

        {#if expandedSection === section.label}
          <div class="mt-1 mb-3">
            {#if section.items.length === 0}
              <p class="px-3 py-2 text-xs text-text-tertiary italic">Coming soon...</p>
            {:else}
              <!-- Start Recursion -->
              {@render renderItems(section.items, 0)}
            {/if}
          </div>
        {/if}
      </div>
    {/each}
  </nav>
</aside>

<!-- Mobile overlay -->
{#if $isMobileMenuOpen}
  <div
    class="fixed inset-0 z-30 lg:hidden bg-ui-backdrop-solid backdrop-blur-sm top-header-h"
    onclick={closeMobileMenu}
    onkeydown={(e) => e.key === 'Escape' && closeMobileMenu()}
    role="button"
    tabindex="0"
    aria-label="Close sidebar"
  ></div>
{/if}
