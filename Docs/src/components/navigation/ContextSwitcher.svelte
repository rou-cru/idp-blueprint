<script lang="ts">
  import Icon from '@iconify/svelte';
  import { onMount } from 'svelte';
  import { currentContext, setContext, loadPersistedContext, CONTEXTS } from '../../stores/context';

  let isOpen = $state(false);

  onMount(() => {
    loadPersistedContext();
  });

  function toggleDropdown() {
    isOpen = !isOpen;
  }

  function selectContext(value: typeof $currentContext) {
    setContext(value);
    isOpen = false;
  }

  // Close dropdown when clicking outside
  function handleClickOutside(event: MouseEvent) {
    const target = event.target as HTMLElement;
    const dropdown = document.getElementById('context-switcher');
    if (dropdown && !dropdown.contains(target)) {
      isOpen = false;
    }
  }

  onMount(() => {
    document.addEventListener('click', handleClickOutside);
    return () => {
      document.removeEventListener('click', handleClickOutside);
    };
  });

  const selectedContext = $derived(CONTEXTS.find(c => c.value === $currentContext) || CONTEXTS[0]);
</script>

<div id="context-switcher" class="relative mb-6 px-3">
  <button
    onclick={toggleDropdown}
    class="w-full flex items-center justify-between gap-3 px-4 py-3 bg-bg-elevated border border-border-default rounded-lg text-sm font-medium text-text-primary transition-all duration-200 hover:border-border-hover hover:bg-bg-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-purple focus-visible:ring-offset-2 focus-visible:ring-offset-bg-base"
    aria-expanded={isOpen}
    aria-haspopup="listbox"
  >
    <div class="flex items-center gap-3">
      <Icon icon={selectedContext.icon} width="18" height="18" class="text-brand-purple" />
      <span class="text-left">{selectedContext.label}</span>
    </div>
    <Icon
      icon="lucide:chevron-down"
      width="16"
      height="16"
      class="text-text-tertiary transition-transform duration-200 {isOpen ? 'rotate-180' : ''}"
    />
  </button>

  {#if isOpen}
    <div
      class="absolute top-full left-0 right-0 mt-2 mx-3 bg-bg-elevated border border-border-default rounded-lg shadow-lg overflow-hidden z-50 animate-fade-in"
      role="listbox"
    >
      {#each CONTEXTS as context}
        <button
          onclick={() => selectContext(context.value)}
          class="w-full flex items-center gap-3 px-4 py-3 text-sm text-text-secondary bg-transparent border-0 transition-all duration-200 hover:text-text-primary hover:bg-bg-hover focus-visible:outline-none focus-visible:bg-bg-hover {context.value === $currentContext ? 'text-text-primary bg-bg-active' : ''}"
          role="option"
          aria-selected={context.value === $currentContext}
        >
          <Icon icon={context.icon} width="18" height="18" class={context.value === $currentContext ? 'text-brand-purple' : ''} />
          <span>{context.label}</span>
          {#if context.value === $currentContext}
            <Icon icon="lucide:check" width="16" height="16" class="ml-auto text-brand-purple" />
          {/if}
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  @keyframes fade-in {
    from {
      opacity: 0;
      transform: translateY(-4px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .animate-fade-in {
    animation: fade-in 0.15s ease-out;
  }
</style>
