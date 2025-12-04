<script lang="ts">
  import { Icon } from '@iconify/svelte';
  import { sidebarConfig } from '../../lib/navigation';
  import type { NavSection } from '../../lib/navigation';

  interface Props {
    currentPath: string;
    isMobileOpen?: boolean;
    onMobileClose?: () => void;
  }

  let { currentPath, isMobileOpen = false, onMobileClose }: Props = $props();

  // Track which sections are expanded
  let expandedSections = $state(new Set<string>(['Getting Started']));

  function toggleSection(sectionLabel: string) {
    if (expandedSections.has(sectionLabel)) {
      expandedSections.delete(sectionLabel);
    } else {
      expandedSections.add(sectionLabel);
    }
    expandedSections = new Set(expandedSections); // Trigger reactivity
  }

  function isActive(href: string | undefined): boolean {
    if (!href) return false;
    // Normalize paths for comparison
    const normalizedCurrent = currentPath.replace(/\/$/, '') || '/';
    const normalizedHref = href.replace(/\/$/, '') || '/';
    return normalizedCurrent === normalizedHref;
  }

  function handleLinkClick() {
    if (onMobileClose) {
      onMobileClose();
    }
  }
</script>

<aside class="sidebar" class:mobile-open={isMobileOpen}>
  <nav class="sidebar-nav">
    {#each sidebarConfig as section}
      <div class="nav-section">
        <button
          class="section-header"
          class:expanded={expandedSections.has(section.label)}
          onclick={() => toggleSection(section.label)}
          aria-expanded={expandedSections.has(section.label)}
        >
          <span class="section-label">{section.label}</span>
          <Icon
            icon="lucide:chevron-down"
            width="16"
            height="16"
            class="chevron"
          />
        </button>

        {#if expandedSections.has(section.label)}
          <div class="section-items">
            {#if section.items.length === 0}
              <p class="empty-message">Coming soon...</p>
            {:else}
              {#each section.items as item}
                <a
                  href={item.href}
                  class="nav-link"
                  class:active={isActive(item.href)}
                  onclick={handleLinkClick}
                >
                  {item.label}
                </a>
              {/each}
            {/if}
          </div>
        {/if}
      </div>
    {/each}
  </nav>
</aside>

<!-- Mobile overlay -->
{#if isMobileOpen}
  <div class="sidebar-overlay" onclick={onMobileClose}></div>
{/if}

<style>
  .sidebar {
    position: fixed;
    left: 0;
    top: 4rem;
    height: calc(100vh - 4rem);
    width: 16rem;
    background: rgb(10 10 10);
    border-right: 1px solid rgb(38 38 38);
    overflow-y: auto;
    z-index: 40;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
  }

  @media (min-width: 1024px) {
    .sidebar {
      transform: translateX(0);
    }
  }

  .sidebar.mobile-open {
    transform: translateX(0);
  }

  .sidebar-nav {
    padding: 1.5rem 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .nav-section {
    display: flex;
    flex-direction: column;
  }

  .section-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 0.625rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 600;
    color: rgb(163 163 163);
    background: transparent;
    border: none;
    border-radius: 0.5rem;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
  }

  .section-header:hover {
    color: rgb(250 250 250);
    background: rgb(23 23 23);
  }

  .section-label {
    letter-spacing: -0.01em;
  }

  .section-header :global(.chevron) {
    transition: transform 0.2s;
    color: rgb(115 115 115);
  }

  .section-header.expanded :global(.chevron) {
    transform: rotate(180deg);
  }

  .section-items {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
    padding-left: 0.5rem;
    margin-top: 0.25rem;
    margin-bottom: 0.5rem;
  }

  .nav-link {
    display: block;
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
    color: rgb(163 163 163);
    text-decoration: none;
    border-radius: 0.5rem;
    transition: all 0.2s;
    border-left: 2px solid transparent;
  }

  .nav-link:hover {
    color: rgb(250 250 250);
    background: rgb(23 23 23);
  }

  .nav-link.active {
    color: rgb(139 109 255);
    background: rgba(108, 71, 255, 0.1);
    border-left-color: rgb(108 71 255);
    font-weight: 500;
  }

  .empty-message {
    padding: 0.5rem 0.75rem;
    font-size: 0.75rem;
    color: rgb(115 115 115);
    font-style: italic;
  }

  /* Mobile overlay */
  .sidebar-overlay {
    position: fixed;
    inset: 0;
    top: 4rem;
    z-index: 39;
    background: rgba(10, 10, 10, 0.8);
    backdrop-filter: blur(4px);
  }

  @media (min-width: 1024px) {
    .sidebar-overlay {
      display: none;
    }
  }

  /* Custom scrollbar for sidebar */
  .sidebar {
    scrollbar-width: thin;
    scrollbar-color: rgb(64 64 64) rgb(23 23 23);
  }

  .sidebar::-webkit-scrollbar {
    width: 0.375rem;
  }

  .sidebar::-webkit-scrollbar-track {
    background: rgb(23 23 23);
  }

  .sidebar::-webkit-scrollbar-thumb {
    background: rgb(64 64 64);
    border-radius: 0.25rem;
  }

  .sidebar::-webkit-scrollbar-thumb:hover {
    background: rgb(82 82 82);
  }
</style>
