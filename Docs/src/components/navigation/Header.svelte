<script lang="ts">
  import Icon from '@iconify/svelte';
  import Search from './Search.svelte';
  import { onMount } from 'svelte';

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
  }

  function handleSearchClose() {
    searchOpen = false;
  }

  // Keyboard shortcut for search (Cmd+K or Ctrl+K)
  onMount(() => {
    function handleKeydown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        searchOpen = !searchOpen;
      }
    }

    document.addEventListener('keydown', handleKeydown);

    return () => {
      document.removeEventListener('keydown', handleKeydown);
    };
  });
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

</header>

<!-- Search Component -->
<Search bind:open={searchOpen} onClose={handleSearchClose} />

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
</style>
