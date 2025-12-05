<script lang="ts">
  interface Props {
    currentPath: string;
  }

  let { currentPath }: Props = $props();

  interface Breadcrumb {
    label: string;
    href: string;
    isCurrentPage: boolean;
  }

  const breadcrumbs = $derived.by(() => {
    // Remove trailing slash and split path
    const cleanPath = currentPath.replace(/\/$/, '');
    const segments = cleanPath.split('/').filter(Boolean);

    // Always start with Home
    const crumbs: Breadcrumb[] = [
      {
        label: 'Home',
        href: '/',
        isCurrentPage: segments.length === 0,
      },
    ];

    // Build breadcrumbs from path segments
    let accumulatedPath = '';
    segments.forEach((segment, index) => {
      accumulatedPath += `/${segment}`;
      const isLast = index === segments.length - 1;

      // Format label: convert kebab-case to Title Case
      const label = segment
        .split('-')
        .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');

      crumbs.push({
        label,
        href: accumulatedPath,
        isCurrentPage: isLast,
      });
    });

    return crumbs;
  });
</script>

<nav aria-label="Breadcrumb" class="breadcrumbs">
  <ol class="breadcrumb-list">
    {#each breadcrumbs as crumb, index (crumb.href)}
      <li class="breadcrumb-item">
        {#if crumb.isCurrentPage}
          <span class="breadcrumb-current" aria-current="page">
            {crumb.label}
          </span>
        {:else}
          <a href={crumb.href} class="breadcrumb-link">
            {crumb.label}
          </a>
        {/if}

        {#if index < breadcrumbs.length - 1}
          <span class="breadcrumb-separator" aria-hidden="true">
            <svg
              width="16"
              height="16"
              viewBox="0 0 16 16"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M6 12L10 8L6 4"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </span>
        {/if}
      </li>
    {/each}
  </ol>
</nav>

<style>
  .breadcrumbs {
    padding: 0.75rem 0;
    border-bottom: 1px solid var(--color-dark-800);
    margin-bottom: 1.5rem;
  }

  .breadcrumb-list {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.5rem;
    list-style: none;
    padding: 0;
    margin: 0;
    font-size: 0.875rem;
    line-height: 1.25rem;
  }

  .breadcrumb-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .breadcrumb-link {
    color: var(--color-dark-400);
    text-decoration: none;
    transition: color 0.2s ease;
    position: relative;
  }

  .breadcrumb-link:hover {
    color: var(--color-brand-purple);
  }

  .breadcrumb-link:focus-visible {
    outline: 2px solid var(--color-brand-purple);
    outline-offset: 2px;
    border-radius: 0.25rem;
  }

  .breadcrumb-current {
    color: var(--color-dark-100);
    font-weight: 500;
  }

  .breadcrumb-separator {
    display: flex;
    align-items: center;
    color: var(--color-dark-600);
  }

  /* Responsive: Hide breadcrumb labels on small screens except first and last */
  @media (max-width: 640px) {
    .breadcrumb-item:not(:first-child):not(:last-child) .breadcrumb-link,
    .breadcrumb-item:not(:first-child):not(:last-child) .breadcrumb-current {
      display: none;
    }

    .breadcrumb-item:not(:first-child):not(:last-child) .breadcrumb-separator {
      display: none;
    }
  }
</style>
