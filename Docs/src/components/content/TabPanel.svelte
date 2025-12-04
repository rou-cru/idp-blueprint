<script lang="ts">
  interface Props {
    value: string;
    activeTab?: string;
  }

  let { value, activeTab }: Props = $props();

  const isActive = $derived(activeTab === value);
</script>

{#if isActive}
  <div class="tab-panel" role="tabpanel">
    <slot />
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
