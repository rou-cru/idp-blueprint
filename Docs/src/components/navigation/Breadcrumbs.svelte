<script lang="ts">
  import { normalizePath } from '../../utils/paths';

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
    const cleanPath = normalizePath(currentPath);
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

<nav aria-label="Breadcrumb" class="py-3 mb-6 border-b border-border-default">
  <ol class="flex flex-wrap items-center gap-2 list-none p-0 m-0 text-sm leading-tight">
    {#each breadcrumbs as crumb, index (crumb.href)}
      <li class="flex items-center gap-2 group">
        {#if crumb.isCurrentPage}
          <span class="text-text-primary font-medium sm:block {index > 0 && index < breadcrumbs.length - 1 ? 'hidden sm:block' : ''}" aria-current="page">
            {crumb.label}
          </span>
        {:else}
          <a href={crumb.href} class="text-text-tertiary no-underline transition-colors duration-200 relative hover:text-brand-purple focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-purple focus-visible:ring-offset-2 focus-visible:rounded sm:block {index > 0 && index < breadcrumbs.length - 1 ? 'hidden sm:block' : ''}">
            {crumb.label}
          </a>
        {/if}

        {#if index < breadcrumbs.length - 1}
          <span class="flex items-center text-text-tertiary sm:flex {index > 0 && index < breadcrumbs.length - 1 ? 'hidden sm:flex' : ''}" aria-hidden="true">
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
