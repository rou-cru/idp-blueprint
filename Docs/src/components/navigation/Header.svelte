<script lang="ts">
  import { Icon } from '@iconify/svelte';

  interface Props {
    onMenuToggle?: () => void;
    isMobileMenuOpen?: boolean;
  }

  let { onMenuToggle, isMobileMenuOpen = false }: Props = $props();

  let searchOpen = $state(false);

  function handleMenuToggle() {
    if (onMenuToggle) {
      onMenuToggle();
    }
  }

  function handleSearch() {
    searchOpen = !searchOpen;
    // TODO: Implement actual search functionality
  }
</script>

<header class="header">
  <div class="header-container">
    <!-- Mobile menu button -->
    <button
      class="mobile-menu-button"
      onclick={handleMenuToggle}
      aria-label="Toggle menu"
      aria-expanded={isMobileMenuOpen}
    >
      <Icon icon={isMobileMenuOpen ? "lucide:x" : "lucide:menu"} width="24" height="24" />
    </button>

    <!-- Logo and title -->
    <a href="/" class="logo">
      <span class="logo-text">IDP Blueprint</span>
    </a>

    <!-- Navigation actions -->
    <div class="header-actions">
      <!-- Search button -->
      <button
        class="action-button"
        onclick={handleSearch}
        aria-label="Search documentation"
        title="Search (⌘K)"
      >
        <Icon icon="lucide:search" width="20" height="20" />
      </button>

      <!-- GitHub link -->
      <a
        href="https://github.com/rou-cru/idp-blueprint"
        class="action-button"
        target="_blank"
        rel="noopener noreferrer"
        aria-label="View on GitHub"
        title="View on GitHub"
      >
        <Icon icon="lucide:github" width="20" height="20" />
      </a>
    </div>
  </div>

  <!-- Search overlay (placeholder) -->
  {#if searchOpen}
    <div class="search-overlay" onclick={() => searchOpen = false}>
      <div class="search-modal" onclick={(e) => e.stopPropagation()}>
        <div class="search-input-wrapper">
          <Icon icon="lucide:search" width="20" height="20" class="search-icon" />
          <input
            type="text"
            placeholder="Search documentation..."
            class="search-input"
            autofocus
          />
          <kbd class="search-kbd">ESC</kbd>
        </div>
        <div class="search-results">
          <p class="text-dark-400 text-sm p-4">Search coming soon...</p>
        </div>
      </div>
    </div>
  {/if}
</header>

<style>
  .header {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 50;
    background: rgba(10, 10, 10, 0.8);
    backdrop-filter: blur(12px);
    border-bottom: 1px solid rgb(38 38 38);
    height: 4rem;
  }

  .header-container {
    display: flex;
    align-items: center;
    justify-content: space-between;
    max-width: 100%;
    height: 100%;
    padding: 0 1rem;
  }

  .mobile-menu-button {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0.5rem;
    color: rgb(163 163 163);
    border-radius: 0.5rem;
    transition: all 0.2s;
    border: none;
    background: transparent;
    cursor: pointer;
  }

  .mobile-menu-button:hover {
    color: rgb(250 250 250);
    background: rgb(23 23 23);
  }

  @media (min-width: 1024px) {
    .mobile-menu-button {
      display: none;
    }
  }

  .logo {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    text-decoration: none;
    font-weight: 600;
    font-size: 1.125rem;
    color: rgb(250 250 250);
    transition: color 0.2s;
  }

  .logo:hover {
    color: rgb(139 109 255);
  }

  .logo-text {
    letter-spacing: -0.02em;
  }

  .header-actions {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .action-button {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0.5rem;
    color: rgb(163 163 163);
    border-radius: 0.5rem;
    transition: all 0.2s;
    border: none;
    background: transparent;
    cursor: pointer;
    text-decoration: none;
  }

  .action-button:hover {
    color: rgb(250 250 250);
    background: rgb(23 23 23);
  }

  /* Search overlay */
  .search-overlay {
    position: fixed;
    inset: 0;
    z-index: 100;
    background: rgba(10, 10, 10, 0.8);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: flex-start;
    justify-content: center;
    padding-top: 8rem;
  }

  .search-modal {
    width: 100%;
    max-width: 42rem;
    background: rgb(23 23 23);
    border: 1px solid rgb(38 38 38);
    border-radius: 1rem;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    overflow: hidden;
  }

  .search-input-wrapper {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 1rem 1.5rem;
    border-bottom: 1px solid rgb(38 38 38);
  }

  .search-icon {
    color: rgb(163 163 163);
    flex-shrink: 0;
  }

  .search-input {
    flex: 1;
    background: transparent;
    border: none;
    outline: none;
    color: rgb(250 250 250);
    font-size: 1rem;
  }

  .search-input::placeholder {
    color: rgb(115 115 115);
  }

  .search-kbd {
    padding: 0.25rem 0.5rem;
    background: rgb(38 38 38);
    border: 1px solid rgb(64 64 64);
    border-radius: 0.25rem;
    font-size: 0.75rem;
    font-family: ui-monospace, monospace;
    color: rgb(163 163 163);
  }

  .search-results {
    max-height: 24rem;
    overflow-y: auto;
  }
</style>
