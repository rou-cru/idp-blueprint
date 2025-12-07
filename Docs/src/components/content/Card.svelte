<script lang="ts">
  import Icon from '@iconify/svelte';

  const props = $props<{
    title: string;
    href?: string;
    icon?: string;
    children?: { default?: (args: Record<string, never>) => unknown };
  }>();

  const title = $derived(props.title);
  const href = $derived(props.href);
  const icon = $derived(props.icon);
  const isLink = $derived(Boolean(href));
  const Component = $derived(isLink ? 'a' : 'div');
  const children = $derived(props.children);
</script>

<svelte:element
  this={Component}
  href={isLink ? href : undefined}
  class="group block p-6 rounded-xl h-full bg-bg-elevated border border-border-default transition-all duration-200 ease-out
    {isLink ? 'no-underline cursor-pointer hover:border-border-hover hover:bg-bg-subtle hover:-translate-y-0.5 hover:shadow-card-hover' : ''}"
>
  <div class="flex flex-col gap-4 h-full">
    {#if icon}
      <div class="flex items-center justify-center flex-shrink-0 w-10 h-10 bg-bg-subtle border border-border-subtle rounded-lg text-text-primary">
        <Icon icon={icon} width="24" height="24" />
      </div>
    {/if}

    <div class="flex flex-col gap-2 flex-1">
      <h3 class="flex items-center gap-2 m-0 text-base font-semibold text-text-primary tracking-tight">
        {title}
        {#if isLink}
          <Icon icon="lucide:arrow-right" width="16" height="16" class="opacity-0 -translate-x-1 text-text-secondary transition-all duration-200 ease-out group-hover:opacity-100 group-hover:translate-x-0" />
        {/if}
      </h3>

      <div class="text-sm leading-relaxed text-text-secondary [&_p]:m-0 [&_p+p]:mt-2 [&_code]:px-1.5 [&_code]:py-0.5 [&_code]:rounded [&_code]:text-xs [&_code]:bg-bg-subtle [&_code]:border [&_code]:border-border-subtle [&_code]:text-text-primary">
        {@render children?.default?.({})}
      </div>
    </div>
  </div>
</svelte:element>
