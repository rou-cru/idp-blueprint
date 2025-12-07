<script lang="ts">
  import Icon from '@iconify/svelte';
  import type { HTMLButtonAttributes, HTMLAnchorAttributes } from 'svelte/elements';

  type Variant = 'primary' | 'secondary' | 'ghost' | 'icon';
  type Size = 'sm' | 'md' | 'lg' | 'icon-sm' | 'icon-md';

  interface Props {
    href?: string;
    variant?: Variant;
    size?: Size;
    icon?: string;
    class?: string;
    children?: import('svelte').Snippet;
    onclick?: (e: MouseEvent) => void;
    // Permitir props adicionales arbitrarios (aria-label, title, target, etc.)
    [key: string]: any;
  }

  let { 
    href, 
    variant = 'primary', 
    size = 'md', 
    icon, 
    class: className = '', 
    children, 
    onclick,
    ...rest 
  }: Props = $props();

  // Base styles always applied
  const baseStyles = 'not-prose inline-flex items-center justify-center gap-2 rounded-lg font-medium transition-all duration-200 ease-out focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-purple focus-visible:ring-offset-2 focus-visible:ring-offset-bg-base disabled:opacity-50 disabled:cursor-not-allowed';

  // Variant definitions
  const variants: Record<Variant, string> = {
    primary: 'bg-brand-purple text-white border border-white/10 shadow-[0_4px_14px_rgba(108,71,255,0.2)] hover:bg-brand-purple-light hover:shadow-[0_6px_20px_rgba(108,71,255,0.3)] hover:-translate-y-px active:translate-y-0',
    secondary: 'bg-transparent text-text-secondary border border-border-default hover:text-text-primary hover:border-border-hover hover:bg-bg-subtle',
    ghost: 'bg-transparent text-text-secondary hover:text-text-primary hover:bg-bg-subtle border border-transparent',
    icon: 'bg-transparent text-text-secondary hover:text-text-primary hover:bg-bg-hover border-0', // Icon variant is typically ghost-like but for icon buttons
  };

  // Size definitions
  const sizes: Record<Size, string> = {
    sm: 'px-3 py-1.5 text-xs',
    md: 'px-4 py-2 text-sm',
    lg: 'px-8 py-4 text-base',
    'icon-sm': 'p-1',      // For very small icon buttons
    'icon-md': 'p-2',      // Standard icon button
  };

  // Resolve styles
  // If variant is 'icon', default size to 'icon-md' unless specified
  const resolvedSize = $derived(
    variant === 'icon' && size === 'md' ? sizes['icon-md'] : sizes[size]
  );
  
  const classes = $derived(`${baseStyles} ${variants[variant]} ${resolvedSize} ${className}`);
</script>

{#if href}
  <a {href} class={classes} {...rest} {onclick}>
    {#if icon}
      <Icon {icon} width={size === 'sm' ? '16' : '18'} height={size === 'sm' ? '16' : '18'} />
    {/if}
    {#if children}
      {@render children()}
    {/if}
  </a>
{:else}
  <button class={classes} {onclick} type="button" {...rest}>
    {#if icon}
      <!-- Adjust icon size based on button context if needed -->
      <Icon {icon} width={variant === 'icon' ? '20' : '18'} height={variant === 'icon' ? '20' : '18'} />
    {/if}
    {#if children}
      {@render children()}
    {/if}
  </button>
{/if}
