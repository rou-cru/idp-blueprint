<script lang="ts">
  const props = $props<{ columns?: 1 | 2 | 3 | 4; children?: { default?: (args: Record<string, never>) => unknown } }>();

  const columns = $derived(props.columns ?? 2);
  const children = $derived(props.children);
</script>

<div
  class="card-grid grid-cols-1"
  class:md:grid-cols-2="{columns >= 2}"
  class:lg:grid-cols-3="{columns >= 3}"
  class:lg:grid-cols-4="{columns === 4}"
>
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
