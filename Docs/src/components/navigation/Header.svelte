<script lang="ts">
  import Icon from '@iconify/svelte';
  import Search from './Search.svelte';
  import { onMount } from 'svelte';
  import { siteConfig } from '../../lib/site-config';
  import { isMobileMenuOpen, toggleMobileMenu } from '../../stores/ui';
  import Button from '../ui/Button.svelte';

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
    <div class="lg:hidden">
      <Button
        variant="icon"
        onclick={handleMenuToggle}
        icon={$isMobileMenuOpen ? "lucide:x" : "lucide:menu"}
        aria-label="Toggle menu"
        aria-expanded={$isMobileMenuOpen}
      />
    </div>

    <!-- Logo and title -->
    <a href="/" class="flex items-center gap-3 text-lg font-semibold text-text-primary no-underline transition-opacity duration-200 hover:opacity-90">
      <span class="tracking-tight">{siteConfig.title}</span>
    </a>

    <!-- Navigation actions -->
    <div class="flex items-center gap-2">
      <!-- Search button -->
      <Button
        variant="icon"
        onclick={handleSearch}
        icon="lucide:search"
        aria-label="Search documentation"
        title="Search (⌘K)"
      />

      <!-- GitHub link -->
      <Button
        href={siteConfig.social.github}
        variant="icon"
        icon="lucide:github"
        target="_blank"
        rel="noopener noreferrer"
        aria-label="View on GitHub"
        title="View on GitHub"
      />
    </div>
  </div>

</header>

<!-- Search Component -->
<Search bind:open={searchOpen} onClose={handleSearchClose} />