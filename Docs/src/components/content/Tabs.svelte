<script lang="ts">
  interface Tab {
    label: string;
    value: string;
  }

  interface Props {
    tabs: Tab[];
    defaultTab?: string;
  }

  let { tabs, defaultTab, children }: Props = $props();

  let activeTab = $state(defaultTab || tabs[0]?.value || '');

  function handleTabClick(value: string) {
    activeTab = value;
  }
</script>

<div class="tabs-container">
  <div class="tabs-list" role="tablist">
    {#each tabs as tab}
      <button
        class="tab"
        class:active={activeTab === tab.value}
        role="tab"
        aria-selected={activeTab === tab.value}
        onclick={() => handleTabClick(tab.value)}
      >
        {tab.label}
      </button>
    {/each}
  </div>

  <div class="tabs-content">
    <slot {activeTab} />
  </div>
</div>

<style>
  .tabs-container {
    margin: 2rem 0;
    border: 1px solid rgb(38 38 38);
    border-radius: 1rem;
    overflow: hidden;
    background: rgb(23 23 23);
  }

  .tabs-list {
    display: flex;
    gap: 0;
    border-bottom: 1px solid rgb(38 38 38);
    background: rgb(10 10 10);
    padding: 0.5rem;
    overflow-x: auto;
    scrollbar-width: thin;
  }

  .tabs-list::-webkit-scrollbar {
    height: 0.25rem;
  }

  .tabs-list::-webkit-scrollbar-track {
    background: transparent;
  }

  .tabs-list::-webkit-scrollbar-thumb {
    background: rgb(64 64 64);
    border-radius: 0.25rem;
  }

  .tab {
    flex-shrink: 0;
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
    font-weight: 500;
    color: rgb(163 163 163);
    background: transparent;
    border: none;
    border-radius: 0.5rem;
    cursor: pointer;
    transition: all 0.2s ease;
    white-space: nowrap;
  }

  .tab:hover {
    color: rgb(250 250 250);
    background: rgb(31 31 31);
  }

  .tab.active {
    color: rgb(250 250 250);
    background: rgb(108 71 255);
  }

  .tab:focus-visible {
    outline: 2px solid rgb(108 71 255);
    outline-offset: 2px;
  }

  .tabs-content {
    padding: 1.5rem;
  }

  .tabs-content :global(pre) {
    margin: 0;
  }

  .tabs-content :global(> *:first-child) {
    margin-top: 0;
  }

  .tabs-content :global(> *:last-child) {
    margin-bottom: 0;
  }
</style>
