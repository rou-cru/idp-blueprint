<script lang="ts">
  const props = $props<{ columns?: 1 | 2 | 3 | 4; children?: { default?: (args: Record<string, never>) => unknown } }>();

  const columns = $derived(props.columns ?? 2);
  const children = $derived(props.children);

  const gridClass = {
    1: 'grid-cols-1',
    2: 'grid-cols-1 md:grid-cols-2',
    3: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
    4: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-4',
  }[columns];
</script>

<div class="card-grid {gridClass}">
  {@render children?.default?.({})}
</div>

<style>
  .card-grid {
    display: grid;
    gap: 1.5rem;
    margin: 2rem 0;
  }

  /* Ensure proper spacing for nested content */
  .card-grid :global(.card) {
    margin: 0;
  }
</style>
