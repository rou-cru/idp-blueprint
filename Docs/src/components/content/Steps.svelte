<div class="steps">
  <slot />
</div>

<style>
  .steps {
    @apply relative ml-4 pl-8 border-l border-border-emphasis;
    counter-reset: step;
  }

  .steps :global(h3) {
    @apply relative mt-8 mb-4;
    counter-increment: step;
  }

  .steps :global(h3)::before {
    content: counter(step);
    @apply absolute flex items-center justify-center;
    @apply w-7 h-7 rounded-full text-sm font-semibold;
    @apply bg-bg-subtle border border-border-emphasis text-text-primary;
    @apply z-10 shadow-[0_0_0_4px_theme('colors.bg.base')];
    left: -2.6rem; /* Aligned with padding + border */
    top: 0.1rem;
  }

  .steps :global(>:first-child h3) {
    @apply mt-0;
  }
</style>
