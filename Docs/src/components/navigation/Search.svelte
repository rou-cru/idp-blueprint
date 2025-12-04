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

  onMount(async () => {
    // Load Pagefind library dynamically (only in browser)
    if (typeof window !== 'undefined') {
      try {
        // @ts-ignore - Pagefind is loaded after build
        const pagefindModule = await import(/* @vite-ignore */ '/pagefind/pagefind.js');
        pagefind = pagefindModule;
        await pagefind.init();
      } catch (err) {
        console.warn('Pagefind not available. Run a production build to enable search.');
      }
    }
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
    if (query.trim().length > 0 && pagefind) {
      performSearch(query);
    } else {
      results = [];
    }
  });

  async function performSearch(searchQuery: string) {
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
    class="search-overlay"
    onclick={handleClose}
    aria-hidden="true"
  ></div>

  <!-- Search Modal -->
  <div class="search-modal" role="dialog" aria-modal="true" aria-labelledby="search-title">
    <div class="search-header">
      <svg
        class="search-icon"
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
        class="search-input"
        id="search-title"
        aria-label="Search documentation"
      />

      <button class="search-close" onclick={handleClose} aria-label="Close search">
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
      <div class="search-results">
        {#if isSearching}
          <div class="search-loading">
            <div class="spinner"></div>
            <span>Searching...</span>
          </div>
        {:else if results.length > 0}
          <ul class="results-list" role="listbox">
            {#each results as result, index (result.url)}
              <li
                class="result-item"
                class:selected={index === selectedIndex}
                role="option"
                aria-selected={index === selectedIndex}
              >
                <button
                  class="result-button"
                  onclick={() => handleResultClick(result.url)}
                  onmouseenter={() => (selectedIndex = index)}
                >
                  <div class="result-title">{result.meta?.title || 'Untitled'}</div>
                  {#if result.excerpt}
                    <div class="result-excerpt">{@html result.excerpt}</div>
                  {/if}
                  <div class="result-url">{result.url}</div>
                </button>
              </li>
            {/each}
          </ul>
        {:else}
          <div class="search-empty">
            <svg
              width="48"
              height="48"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4-4"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
            <p>No results found for "<strong>{query}</strong>"</p>
            <p class="search-hint">Try different keywords or check for typos</p>
          </div>
        {/if}
      </div>
    {:else}
      <div class="search-hints">
        <p class="hint-title">Quick tips:</p>
        <ul>
          <li>Use keywords to find what you're looking for</li>
          <li>Navigate results with arrow keys</li>
          <li>Press Enter to open a result</li>
          <li>Press Esc to close</li>
        </ul>
      </div>
    {/if}
  </div>
{/if}

<style>
  .search-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.75);
    backdrop-filter: blur(4px);
    z-index: 1000;
    animation: fadeIn 0.2s ease;
  }

  .search-modal {
    position: fixed;
    top: 20%;
    left: 50%;
    transform: translateX(-50%);
    width: 90%;
    max-width: 42rem;
    max-height: 60vh;
    background: var(--color-dark-900);
    border: 1px solid var(--color-dark-700);
    border-radius: 1rem;
    box-shadow:
      0 20px 25px -5px rgba(0, 0, 0, 0.5),
      0 10px 10px -5px rgba(0, 0, 0, 0.3),
      0 0 0 1px rgba(108, 71, 255, 0.1);
    z-index: 1001;
    display: flex;
    flex-direction: column;
    animation: slideIn 0.2s ease;
  }

  .search-header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 1rem 1.25rem;
    border-bottom: 1px solid var(--color-dark-800);
  }

  .search-icon {
    flex-shrink: 0;
    color: var(--color-dark-400);
  }

  .search-input {
    flex: 1;
    background: transparent;
    border: none;
    outline: none;
    color: var(--color-dark-50);
    font-size: 1rem;
    line-height: 1.5;
  }

  .search-input::placeholder {
    color: var(--color-dark-500);
  }

  .search-close {
    flex-shrink: 0;
    background: transparent;
    border: none;
    color: var(--color-dark-400);
    cursor: pointer;
    padding: 0.25rem;
    border-radius: 0.25rem;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .search-close:hover {
    color: var(--color-dark-100);
    background: var(--color-dark-800);
  }

  .search-results {
    overflow-y: auto;
    max-height: calc(60vh - 5rem);
  }

  .search-loading {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.75rem;
    padding: 3rem;
    color: var(--color-dark-400);
  }

  .spinner {
    width: 1.5rem;
    height: 1.5rem;
    border: 2px solid var(--color-dark-700);
    border-top-color: var(--color-brand-purple);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  .results-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .result-item {
    border-bottom: 1px solid var(--color-dark-800);
  }

  .result-item:last-child {
    border-bottom: none;
  }

  .result-item.selected .result-button {
    background: var(--color-dark-800);
    border-left-color: var(--color-brand-purple);
  }

  .result-button {
    width: 100%;
    text-align: left;
    background: transparent;
    border: none;
    border-left: 3px solid transparent;
    padding: 1rem 1.25rem;
    cursor: pointer;
    transition: all 0.15s ease;
    display: block;
  }

  .result-button:hover {
    background: var(--color-dark-800);
    border-left-color: var(--color-brand-purple);
  }

  .result-title {
    color: var(--color-dark-100);
    font-weight: 500;
    margin-bottom: 0.25rem;
    font-size: 0.9375rem;
  }

  .result-excerpt {
    color: var(--color-dark-400);
    font-size: 0.875rem;
    line-height: 1.5;
    margin-bottom: 0.5rem;
  }

  .result-excerpt :global(mark) {
    background: rgba(108, 71, 255, 0.2);
    color: var(--color-brand-purple-light);
    padding: 0.125rem 0.25rem;
    border-radius: 0.25rem;
  }

  .result-url {
    color: var(--color-dark-500);
    font-size: 0.8125rem;
    font-family: 'Monaco', 'Courier New', monospace;
  }

  .search-empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 3rem 2rem;
    text-align: center;
    color: var(--color-dark-400);
  }

  .search-empty svg {
    margin-bottom: 1rem;
    opacity: 0.5;
  }

  .search-empty p {
    margin: 0.5rem 0;
  }

  .search-empty strong {
    color: var(--color-dark-100);
  }

  .search-hint {
    font-size: 0.875rem;
    color: var(--color-dark-500);
  }

  .search-hints {
    padding: 1.5rem 1.25rem;
    color: var(--color-dark-400);
  }

  .hint-title {
    font-weight: 500;
    color: var(--color-dark-200);
    margin-bottom: 0.75rem;
  }

  .search-hints ul {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .search-hints li {
    padding: 0.5rem 0;
    font-size: 0.875rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .search-hints li::before {
    content: '→';
    color: var(--color-brand-purple);
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  @keyframes slideIn {
    from {
      opacity: 0;
      transform: translateX(-50%) translateY(-1rem);
    }
    to {
      opacity: 1;
      transform: translateX(-50%) translateY(0);
    }
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  @media (max-width: 768px) {
    .search-modal {
      top: 10%;
      max-height: 70vh;
    }
  }
</style>
