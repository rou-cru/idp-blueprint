<script lang="ts">
  import Icon from '@iconify/svelte';

  const props = $props<{
    href: string;
    variant?: 'primary' | 'secondary' | 'ghost';
    icon?: 'arrow-left' | 'arrow-right' | string;
  }>();

  const href = $derived(props.href);
  const variant = $derived(props.variant ?? 'primary');
  const icon = $derived(props.icon);

  // Variant styles map
  const variants = {
    primary: 'bg-brand-purple text-white border border-white/10 shadow-[0_4px_14px_rgba(108,71,255,0.2)] hover:bg-brand-purple-light hover:shadow-[0_6px_20px_rgba(108,71,255,0.3)] hover:-translate-y-px active:translate-y-0',
    secondary: 'bg-transparent text-text-secondary border border-border-default hover:text-text-primary hover:border-border-hover hover:bg-bg-subtle',
    ghost: 'bg-transparent text-text-secondary hover:text-text-primary hover:bg-bg-subtle'
  };
</script>

<a
  href={href}
  class="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-lg text-sm font-medium no-underline transition-all duration-200 ease-out whitespace-nowrap focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-purple focus-visible:ring-offset-2 {variants[variant]}"
>
  {#if icon}
    <Icon icon={icon} width="18" height="18" />
  {/if}

  <span class="leading-none pb-[1px]">
    <slot />
  </span>
</a>
