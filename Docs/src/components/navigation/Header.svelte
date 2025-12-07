<script lang="ts">
  import Icon from '@iconify/svelte';
  import Search from './Search.svelte';
  import { onMount } from 'svelte';
  import { siteConfig } from '../../lib/site-config';
  import { isMobileMenuOpen, toggleMobileMenu } from '../../stores/ui';

  let searchOpen = $state(false);

  function handleMenuToggle() {
    toggleMobileMenu();
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

<header class="fixed top-0 left-0 right-0 z-50 h-header-h bg-ui-backdrop backdrop-blur-header border-b border-border-default">
  <div class="flex items-center justify-between h-full w-full px-6">
    <!-- Mobile menu button -->
    <button
      class="flex items-center justify-center p-2 lg:hidden text-text-secondary rounded-md transition-all duration-200 bg-transparent border-0 cursor-pointer hover:text-text-primary hover:bg-bg-hover"
      onclick={handleMenuToggle}
      aria-label="Toggle menu"
      aria-expanded={$isMobileMenuOpen}
    >
      <Icon icon={$isMobileMenuOpen ? "lucide:x" : "lucide:menu"} width="24" height="24" />
    </button>

    <!-- Logo and title -->
    <a href="/" class="flex items-center gap-3 text-lg font-semibold text-text-primary no-underline transition-opacity duration-200 hover:opacity-90">
      <span class="tracking-tight">{siteConfig.title}</span>
    </a>

    <!-- Navigation actions -->
    <div class="flex items-center gap-2">
      <!-- Search button -->
      <button
        class="flex items-center justify-center p-2 text-text-secondary rounded-md transition-all duration-200 bg-transparent border-0 cursor-pointer no-underline hover:text-text-primary hover:bg-bg-hover"
        onclick={handleSearch}
        aria-label="Search documentation"
        title="Search (⌘K)"
      >
        <Icon icon="lucide:search" width="20" height="20" />
      </button>

      <!-- GitHub link -->
      <a
        href={siteConfig.social.github}
        class="flex items-center justify-center p-2 text-text-secondary rounded-md transition-all duration-200 bg-transparent border-0 cursor-pointer no-underline hover:text-text-primary hover:bg-bg-hover"
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
