<script lang="ts">
  const props = $props<{
    value: string;
    activeTab?: string;
    children?: { default?: (args: Record<string, never>) => unknown };
  }>();

  const value = $derived(props.value);
  const activeTab = $derived(props.activeTab);
  const children = $derived(props.children);

  const isActive = $derived(activeTab === value);
</script>

{#if isActive}
  <div class="tab-panel" role="tabpanel">
    {@render children?.default?.({})}
  </div>
{/if}

<style>
  .tab-panel {
    animation: fadeIn 0.2s ease;
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(4px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
</style>
