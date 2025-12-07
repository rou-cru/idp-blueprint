<script lang="ts">
  import Icon from '@iconify/svelte';

  const props = $props<{
    type?: 'tip' | 'caution' | 'danger' | 'note' | 'warning' | 'info';
    title?: string;
    children?: { default?: (args: Record<string, never>) => unknown };
  }>();

  const type = $derived(props.type ?? 'note');
  const title = $derived(props.title);

  const config = {
    tip: {
      icon: 'lucide:lightbulb',
      bgClass: 'bg-success/10',
      borderClass: 'border-success/30',
      iconClass: 'text-success',
      titleClass: 'text-success',
    },
    caution: {
      icon: 'lucide:alert-triangle',
      bgClass: 'bg-warning/10',
      borderClass: 'border-warning/30',
      iconClass: 'text-warning',
      titleClass: 'text-warning',
    },
    danger: {
      icon: 'lucide:alert-octagon',
      bgClass: 'bg-danger/10',
      borderClass: 'border-danger/30',
      iconClass: 'text-danger',
      titleClass: 'text-danger',
    },
    note: {
      icon: 'lucide:info',
      bgClass: 'bg-bg-subtle',
      borderClass: 'border-border-emphasis',
      iconClass: 'text-text-muted',
      titleClass: 'text-text-secondary',
    },
    warning: {
      icon: 'lucide:alert-triangle',
      bgClass: 'bg-warning/10',
      borderClass: 'border-warning/30',
      iconClass: 'text-warning',
      titleClass: 'text-warning',
    },
    info: {
      icon: 'lucide:info',
      bgClass: 'bg-info/10',
      borderClass: 'border-info/30',
      iconClass: 'text-info',
      titleClass: 'text-info',
    },
  };

  const currentConfig = $derived(config[type]);

  const defaultTitles = {
    tip: 'Tip',
    caution: 'Caution',
    danger: 'Danger',
    note: 'Note',
    warning: 'Warning',
    info: 'Info',
  };

  const displayTitle = $derived(title || defaultTitles[type]);
  const children = $derived(props.children);
</script>

<div class="callout {currentConfig.bgClass} {currentConfig.borderClass} animate-fade-in">
  <div class="callout-header">
    <div class="callout-icon {currentConfig.iconClass}">
      <Icon icon={currentConfig.icon} width="20" height="20" />
    </div>
    {#if displayTitle}
      <h5 class="callout-title {currentConfig.titleClass}">{displayTitle}</h5>
    {/if}
  </div>
  <div class="callout-content">
    {@render children?.default?.({})}
  </div>
</div>

<style>
  .callout {
    @apply flex flex-col gap-3 p-4 my-6;
    @apply rounded-xl border-l-[3px];
  }

  .callout-header {
    @apply flex items-center gap-3;
  }

  .callout-icon {
    @apply flex items-center justify-center flex-shrink-0;
  }

  .callout-title {
    @apply text-sm font-semibold m-0 tracking-tight;
  }

  .callout-content {
    @apply text-sm leading-relaxed text-text-secondary;
  }

  .callout-content :global(p) {
    @apply m-0;
  }

  .callout-content :global(p + p) {
    @apply mt-2;
  }

  .callout-content :global(a) {
    @apply text-brand-purple-light underline decoration-brand-purple-light/30;
  }

  .callout-content :global(a:hover) {
    @apply decoration-brand-purple-light/60;
  }

  .callout-content :global(code) {
    @apply px-1.5 py-0.5 rounded text-xs;
    @apply bg-bg-subtle;
  }

  .callout-content :global(ul),
  .callout-content :global(ol) {
    @apply my-2 pl-6;
  }

  .callout-content :global(li) {
    @apply my-1;
  }
</style>
