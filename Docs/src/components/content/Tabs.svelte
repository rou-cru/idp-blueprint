<script lang="ts">
  interface Tab {
    label: string;
    value: string;
  }

  interface Props {
    tabs: Tab[];
    defaultTab?: string;
    children?: { default?: (args: { activeTab: string }) => unknown };
  }

  let { tabs, defaultTab, children }: Props = $props();

  let activeTab = $state(defaultTab || tabs[0]?.value || '');

  function handleTabClick(value: string) {
    activeTab = value;
  }
</script>

<div class="my-8 rounded-xl overflow-hidden border border-border-default bg-bg-elevated">
  <div class="flex gap-1 p-2 overflow-x-auto bg-bg-base border-b border-border-default scrollbar-thin scrollbar-thumb-ui-scrollbar-thumb scrollbar-track-transparent" role="tablist">
    {#each tabs as tab}
      <button
        class="flex-shrink-0 px-3 py-1.5 text-xs font-medium text-text-secondary bg-transparent border-0 rounded-md cursor-pointer transition-all duration-200 whitespace-nowrap hover:text-text-primary hover:bg-bg-hover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-purple focus-visible:ring-offset-2 focus-visible:ring-offset-bg-base"
        class:text-text-primary={activeTab === tab.value}
        class:bg-bg-active={activeTab === tab.value}
        class:shadow-[inset_0_1px_0_0_rgba(255,255,255,0.05)]={activeTab === tab.value}
        role="tab"
        aria-selected={activeTab === tab.value}
        onclick={() => handleTabClick(tab.value)}
      >
        {tab.label}
      </button>
    {/each}
  </div>

  <div class="p-6 [&_pre]:m-0 [&_>_*:first-child]:mt-0 [&_>_*:last-child]:mb-0">
    {@render children?.default?.({ activeTab })}
  </div>
</div>
