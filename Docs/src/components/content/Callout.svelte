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
      bgClass: 'bg-info/10',
      borderClass: 'border-info',
      iconClass: 'text-info',
      titleClass: 'text-info',
    },
    caution: {
      icon: 'lucide:alert-triangle',
      bgClass: 'bg-warning/10',
      borderClass: 'border-warning',
      iconClass: 'text-warning',
      titleClass: 'text-warning',
    },
    danger: {
      icon: 'lucide:alert-octagon',
      bgClass: 'bg-danger/10',
      borderClass: 'border-danger',
      iconClass: 'text-danger',
      titleClass: 'text-danger',
    },
    note: {
      icon: 'lucide:info',
      bgClass: 'bg-dark-900/50',
      borderClass: 'border-dark-700',
      iconClass: 'text-dark-400',
      titleClass: 'text-dark-200',
    },
    warning: {
      icon: 'lucide:alert-triangle',
      bgClass: 'bg-warning/10',
      borderClass: 'border-warning',
      iconClass: 'text-warning',
      titleClass: 'text-warning',
    },
    info: {
      icon: 'lucide:info',
      bgClass: 'bg-info/10',
      borderClass: 'border-info',
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
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    padding: 1rem 1.25rem;
    border-left-width: 3px;
    border-radius: 0.75rem;
    margin: 1.5rem 0;
  }

  .callout-header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .callout-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .callout-title {
    font-size: 0.875rem;
    font-weight: 600;
    margin: 0;
    letter-spacing: -0.01em;
  }

  .callout-content {
    font-size: 0.875rem;
    line-height: 1.6;
    color: rgb(163 163 163);
  }

  .callout-content :global(p) {
    margin: 0;
  }

  .callout-content :global(p + p) {
    margin-top: 0.5rem;
  }

  .callout-content :global(a) {
    color: rgb(139 109 255);
    text-decoration: underline;
    text-decoration-color: rgba(139, 109, 255, 0.3);
  }

  .callout-content :global(a:hover) {
    text-decoration-color: rgba(139, 109, 255, 0.6);
  }

  .callout-content :global(code) {
    background: rgb(23 23 23);
    padding: 0.125rem 0.375rem;
    border-radius: 0.25rem;
    font-size: 0.8125rem;
  }

  .callout-content :global(ul),
  .callout-content :global(ol) {
    margin: 0.5rem 0;
    padding-left: 1.5rem;
  }

  .callout-content :global(li) {
    margin: 0.25rem 0;
  }
</style>
