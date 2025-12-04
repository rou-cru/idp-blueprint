<script lang="ts">
  import Icon from '@iconify/svelte';

  interface Props {
    title: string;
    href?: string;
    icon?: string;
  }

  let { title, href, icon }: Props = $props();

  const isLink = !!href;
  const Component = isLink ? 'a' : 'div';
</script>

<svelte:element
  this={Component}
  href={isLink ? href : undefined}
  class="card card-hover"
  class:card-link={isLink}
>
  <div class="card-inner">
    {#if icon}
      <div class="card-icon">
        <Icon icon={icon} width="24" height="24" />
      </div>
    {/if}

    <div class="card-content">
      <h3 class="card-title">
        {title}
        {#if isLink}
          <Icon icon="lucide:arrow-right" width="16" height="16" class="card-arrow" />
        {/if}
      </h3>

      {#if children}
        <div class="card-description">
          <slot />
        </div>
      {/if}
    </div>
  </div>
</svelte:element>

<style>
  .card {
    display: block;
    background: rgb(23 23 23);
    border: 1px solid rgb(38 38 38);
    border-radius: 1rem;
    padding: 1.5rem;
    transition: all 0.2s ease;
  }

  .card-link {
    text-decoration: none;
    cursor: pointer;
  }

  .card-link:hover {
    border-color: rgba(108, 71, 255, 0.5);
    background: rgb(31 31 31);
    transform: translateY(-2px);
    box-shadow: 0 8px 16px rgba(108, 71, 255, 0.1);
  }

  .card-inner {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    height: 100%;
  }

  .card-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 3rem;
    height: 3rem;
    background: rgba(108, 71, 255, 0.1);
    border: 1px solid rgba(108, 71, 255, 0.2);
    border-radius: 0.75rem;
    color: rgb(139 109 255);
    flex-shrink: 0;
  }

  .card-content {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    flex: 1;
  }

  .card-title {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 1.125rem;
    font-weight: 600;
    color: rgb(250 250 250);
    margin: 0;
    letter-spacing: -0.02em;
  }

  .card-title :global(.card-arrow) {
    opacity: 0;
    transition: all 0.2s ease;
    transform: translateX(-4px);
    color: rgb(139 109 255);
  }

  .card-link:hover .card-title :global(.card-arrow) {
    opacity: 1;
    transform: translateX(0);
  }

  .card-description {
    font-size: 0.875rem;
    line-height: 1.6;
    color: rgb(163 163 163);
  }

  .card-description :global(p) {
    margin: 0;
  }

  .card-description :global(p + p) {
    margin-top: 0.5rem;
  }

  .card-description :global(code) {
    background: rgb(10 10 10);
    padding: 0.125rem 0.375rem;
    border-radius: 0.25rem;
    font-size: 0.8125rem;
    color: rgb(139 109 255);
  }
</style>
