<script lang="ts">
  import { onMount } from 'svelte';

  interface Heading {
    depth: number;
    text: string;
    slug: string;
  }

  interface Props {
    headings: Heading[];
  }

  let { headings }: Props = $props();

  let activeId = $state('');
  let observer: IntersectionObserver | null = null;

  onMount(() => {
    // Set up Intersection Observer to track active heading
    const observerOptions = {
      rootMargin: '-80px 0px -80% 0px',
      threshold: 0,
    };

    observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          activeId = entry.target.id;
        }
      });
    }, observerOptions);

    // Observe all headings
    headings.forEach((heading) => {
      const element = document.getElementById(heading.slug);
      if (element) {
        observer?.observe(element);
      }
    });

    return () => {
      observer?.disconnect();
    };
  });

  function handleClick(slug: string, event: MouseEvent) {
    event.preventDefault();
    const element = document.getElementById(slug);
    if (element) {
      const offset = 80; // Header height
      const elementPosition = element.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.scrollY - offset;

      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth',
      });

      // Update URL without triggering navigation
      window.history.pushState({}, '', `#${slug}`);
      activeId = slug;
    }
  }

  function getIndentClass(depth: number): string {
    switch (depth) {
      case 2:
        return 'pl-0';
      case 3:
        return 'pl-3';
      case 4:
        return 'pl-6';
      default:
        return 'pl-9';
    }
  }
</script>

{#if headings.length > 0}
  <aside class="hidden xl:block h-full">
    <nav class="flex flex-col gap-4">
      <h2 class="text-xs font-semibold uppercase tracking-wider text-text-tertiary">On this page</h2>
      <ul class="flex flex-col gap-1 list-none p-0 m-0">
        {#each headings as heading}
          <li class="{getIndentClass(heading.depth)}">
            <a
              href={`#${heading.slug}`}
              class="block py-1 text-sm text-text-secondary no-underline transition-all duration-200 border-l-2 border-transparent pl-3 -ml-3 hover:text-text-primary"
              class:text-brand-purple-light={activeId === heading.slug}
              class:border-l-brand-purple={activeId === heading.slug}
              class:font-medium={activeId === heading.slug}
              onclick={(e) => handleClick(heading.slug, e)}
            >
              {heading.text}
            </a>
          </li>
        {/each}
      </ul>
    </nav>
  </aside>
{/if}
