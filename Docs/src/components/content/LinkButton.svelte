<script lang="ts">
  import Icon from '@iconify/svelte';

  interface Props {
    href: string;
    variant?: 'primary' | 'secondary' | 'ghost';
    icon?: 'arrow-left' | 'arrow-right' | string;
  }

  let { href, variant = 'primary', icon }: Props = $props();

  const iconMap = {
    'arrow-left': 'lucide:arrow-left',
    'arrow-right': 'lucide:arrow-right',
  };

  const iconName = icon && iconMap[icon as keyof typeof iconMap] ? iconMap[icon as keyof typeof iconMap] : icon;
  const iconPosition = icon === 'arrow-left' ? 'left' : 'right';
</script>

<a href={href} class="link-button link-button-{variant} button-press">
  {#if iconName && iconPosition === 'left'}
    <Icon icon={iconName} width="18" height="18" />
  {/if}

  <span class="link-button-text">
    <slot />
  </span>

  {#if iconName && iconPosition === 'right'}
    <Icon icon={iconName} width="18" height="18" />
  {/if}
</a>

<style>
  .link-button {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    border-radius: 9999px;
    font-size: 0.875rem;
    font-weight: 500;
    text-decoration: none;
    transition: all 0.2s ease;
    white-space: nowrap;
  }

  .link-button:focus-visible {
    outline: none;
    ring: 2px solid rgb(108 71 255);
    ring-offset: 2px;
  }

  /* Primary variant */
  .link-button-primary {
    background: rgb(108 71 255);
    color: rgb(255 255 255);
    box-shadow: 0 4px 14px rgba(108, 71, 255, 0.2);
  }

  .link-button-primary:hover {
    background: rgb(139 109 255);
    box-shadow: 0 6px 20px rgba(108, 71, 255, 0.3);
    transform: translateY(-1px);
  }

  .link-button-primary:active {
    transform: translateY(0);
  }

  /* Secondary variant */
  .link-button-secondary {
    background: transparent;
    color: rgb(163 163 163);
    border: 1px solid rgb(64 64 64);
  }

  .link-button-secondary:hover {
    color: rgb(250 250 250);
    border-color: rgb(82 82 82);
    background: rgb(23 23 23);
  }

  /* Ghost variant */
  .link-button-ghost {
    background: transparent;
    color: rgb(163 163 163);
  }

  .link-button-ghost:hover {
    color: rgb(250 250 250);
    background: rgb(23 23 23);
  }

  .link-button-text {
    line-height: 1;
  }
</style>
