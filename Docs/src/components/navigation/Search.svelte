<script lang="ts">
  import { onMount } from 'svelte';

  interface Props {
    open?: boolean;
    onClose?: () => void;
  }

  let { open = $bindable(false), onClose }: Props = $props();

  let searchInput: HTMLInputElement | null = $state(null);
  let query = $state('');
  let results = $state<any[]>([]);
  let isSearching = $state(false);
  let selectedIndex = $state(0);
  let pagefind: any = $state(null);

  const pagefindScript = (() => {
    const base = import.meta.env.BASE_URL || '/';
    return `${base.replace(/\/$/, '')}/pagefind/pagefind.js`;
  })();

  async function loadPagefind() {
    if (!import.meta.env.PROD || typeof window === 'undefined') return null;
    if (pagefind) return pagefind;

    await new Promise<void>((resolve, reject) => {
      const script = document.createElement('script');
      script.src = pagefindScript;
      script.async = true;
      script.onload = () => resolve();
      script.onerror = () => reject(new Error('Failed to load pagefind.js'));
      document.head.appendChild(script);
    });

    // @ts-expect-error pagefind attaches to window in prod build
    pagefind = window.pagefind || null;
    if (pagefind?.init) {
      await pagefind.init();
    }
    return pagefind;
  }

  onMount(() => {
    loadPagefind().catch(() =>
      console.warn('Pagefind not available. Run a production build to enable search.')
    );
  });

  // Watch for open state changes to focus input
  $effect(() => {
    if (open && searchInput) {
      // Focus the input when modal opens
      setTimeout(() => searchInput?.focus(), 100);
    }
  });

  // Watch for query changes to perform search
  $effect(() => {
    if (query.trim().length > 0) {
      performSearch(query);
    } else {
      results = [];
    }
  });

  async function performSearch(searchQuery: string) {
    if (!pagefind) {
      await loadPagefind();
    }
    if (!pagefind) return;

    isSearching = true;
    selectedIndex = 0;

    try {
      const search = await pagefind.search(searchQuery);
      const searchResults = await Promise.all(
        search.results.slice(0, 8).map((r: any) => r.data())
      );
      results = searchResults;
    } catch (err) {
      console.error('Search failed:', err);
      results = [];
    } finally {
      isSearching = false;
    }
  }

  function handleClose() {
    open = false;
    query = '';
    results = [];
    selectedIndex = 0;
    onClose?.();
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      handleClose();
    } else if (e.key === 'ArrowDown' && results.length > 0) {
      e.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, results.length - 1);
    } else if (e.key === 'ArrowUp' && results.length > 0) {
      e.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
    } else if (e.key === 'Enter' && results.length > 0 && results[selectedIndex]) {
      e.preventDefault();
      window.location.href = results[selectedIndex].url;
    }
  }

  function handleResultClick(url: string) {
    window.location.href = url;
  }
</script>

{#if open}
  <!-- Modal Overlay -->
  <div
    class="fixed inset-0 bg-ui-backdrop-solid/75 backdrop-blur-sm z-50 animate-in fade-in duration-200"
    onclick={handleClose}
    aria-hidden="true"
  ></div>

  <!-- Search Modal -->
  <div class="fixed top-[20%] left-1/2 -translate-x-1/2 w-[90%] max-w-2xl max-h-[60vh] bg-bg-elevated border border-border-default rounded-xl shadow-2xl z-[51] flex flex-col animate-in zoom-in-95 duration-200 md:max-h-[70vh]" role="dialog" aria-modal="true" aria-labelledby="search-title">
    <div class="flex items-center gap-3 p-4 border-b border-border-default">
      <svg
        class="flex-shrink-0 text-text-tertiary"
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M9 17A8 8 0 1 0 9 1a8 8 0 0 0 0 16zM18 18l-4-4"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>

      <input
        bind:this={searchInput}
        bind:value={query}
        onkeydown={handleKeydown}
        type="text"
        placeholder="Search documentation..."
        class="flex-1 bg-transparent border-0 outline-none text-text-primary text-base placeholder:text-text-tertiary"
        id="search-title"
        aria-label="Search documentation"
      />

      <button class="flex-shrink-0 bg-transparent border-0 text-text-tertiary cursor-pointer p-1 rounded transition-colors duration-200 hover:text-text-primary hover:bg-bg-hover" onclick={handleClose} aria-label="Close search">
        <svg
          width="20"
          height="20"
          viewBox="0 0 20 20"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M15 5L5 15M5 5l10 10"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
      </button>
    </div>

    <!-- Search Results -->
    {#if query.trim().length > 0}
      <div class="overflow-y-auto max-h-[calc(60vh-5rem)] scrollbar-thin scrollbar-thumb-ui-scrollbar-thumb scrollbar-track-transparent">
        {#if isSearching}
          <div class="flex items-center justify-center gap-3 p-12 text-text-tertiary">
            <div class="w-6 h-6 border-2 border-border-default border-t-brand-purple rounded-full animate-spin"></div>
            <span>Searching...</span>
          </div>
        {:else if results.length > 0}
          <ul class="list-none p-0 m-0" role="listbox">
            {#each results as result, index (result.url)}
              <li
                class="border-b border-border-default last:border-0"
                class:bg-bg-hover={index === selectedIndex}
                role="option"
                aria-selected={index === selectedIndex}
              >
                <button
                  class="w-full text-left bg-transparent border-0 border-l-[3px] border-transparent p-4 cursor-pointer transition-all duration-150 block hover:bg-bg-hover hover:border-l-brand-purple"
                  class:border-l-brand-purple={index === selectedIndex}
                  onclick={() => handleResultClick(result.url)}
                  onmouseenter={() => (selectedIndex = index)}
                >
                  <div class="text-text-primary font-medium mb-1 text-[0.9375rem]">{result.meta?.title || 'Untitled'}</div>
                  {#if result.excerpt}
                    <div class="text-text-tertiary text-sm leading-relaxed mb-2 [&_mark]:bg-brand-purple/20 [&_mark]:text-brand-purple-light [&_mark]:px-1 [&_mark]:rounded-sm">{@html result.excerpt}</div>
                  {/if}
                  <div class="text-text-tertiary text-xs font-mono">{result.url}</div>
                </button>
              </li>
            {/each}
          </ul>
        {:else}
          <div class="flex flex-col items-center justify-center p-12 text-center text-text-tertiary">
            <svg
              width="48"
              height="48"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              class="mb-4 opacity-50"
            >
              <path
                d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4-4"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
            <p class="my-2">No results found for "<strong class="text-text-primary">{query}</strong>"</p>
            <p class="text-sm text-text-tertiary">Try different keywords or check for typos</p>
          </div>
        {/if}
      </div>
    {:else}
      <div class="p-6 text-text-tertiary">
        <p class="font-medium text-text-secondary mb-3">Quick tips:</p>
        <ul class="list-none p-0 m-0">
          <li class="py-2 text-sm flex items-center gap-2 before:content-['→'] before:text-brand-purple">Use keywords to find what you're looking for</li>
          <li class="py-2 text-sm flex items-center gap-2 before:content-['→'] before:text-brand-purple">Navigate results with arrow keys</li>
          <li class="py-2 text-sm flex items-center gap-2 before:content-['→'] before:text-brand-purple">Press Enter to open a result</li>
          <li class="py-2 text-sm flex items-center gap-2 before:content-['→'] before:text-brand-purple">Press Esc to close</li>
        </ul>
      </div>
    {/if}
  </div>
{/if}
