<script lang="ts">
  import Icon from '@iconify/svelte';

  interface Props {
    type?: 'tip' | 'caution' | 'danger' | 'note' | 'warning' | 'info';
    title?: string;
    children?: import('svelte').Snippet;
  }

  let { type = 'note', title, children }: Props = $props();

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
</script>

<div class="flex flex-col gap-3 p-4 my-6 rounded-xl border-l-[3px] animate-fade-in {currentConfig.bgClass} {currentConfig.borderClass}">
  <div class="flex items-center gap-3">
    <div class="flex items-center justify-center flex-shrink-0 {currentConfig.iconClass}">
      <Icon icon={currentConfig.icon} width="20" height="20" />
    </div>
    {#if displayTitle}
      <h5 class="text-sm font-semibold m-0 tracking-tight {currentConfig.titleClass}">{displayTitle}</h5>
    {/if}
  </div>
  <div class="text-sm leading-relaxed text-text-secondary [&_p]:m-0 [&_p+p]:mt-2 [&_a]:text-brand-purple-light [&_a]:underline [&_a]:decoration-brand-purple-light/30 [&_a:hover]:decoration-brand-purple-light/60 [&_code]:px-1.5 [&_code]:py-0.5 [&_code]:rounded [&_code]:text-xs [&_code]:bg-bg-subtle [&_ul]:my-2 [&_ul]:pl-6 [&_ol]:my-2 [&_ol]:pl-6 [&_li]:my-1">
    {@render children?.()}
  </div>
</div>