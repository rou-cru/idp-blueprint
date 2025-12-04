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
      threshold: 1.0,
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
      const offsetPosition = elementPosition + window.pageYOffset - offset;

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
  <aside class="toc-container">
    <nav class="toc">
      <h2 class="toc-title">On this page</h2>
      <ul class="toc-list">
        {#each headings as heading}
          <li class={getIndentClass(heading.depth)}>
            <a
              href={`#${heading.slug}`}
              class="toc-link"
              class:active={activeId === heading.slug}
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

<style>
  .toc-container {
    display: none;
  }

  @media (min-width: 1280px) {
    .toc-container {
      display: block;
      position: fixed;
      right: 0;
      top: 4rem;
      width: 14rem;
      height: calc(100vh - 4rem);
      overflow-y: auto;
      border-left: 1px solid rgb(38 38 38);
      padding: 1.5rem 1rem;
    }
  }

  .toc {
    position: sticky;
    top: 1rem;
  }

  .toc-title {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: rgb(115 115 115);
    margin-bottom: 1rem;
  }

  .toc-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 0.375rem;
  }

  .toc-list li {
    line-height: 1.4;
  }

  .toc-link {
    display: block;
    font-size: 0.8125rem;
    color: rgb(163 163 163);
    text-decoration: none;
    transition: color 0.2s;
    padding: 0.25rem 0;
    border-left: 2px solid transparent;
    padding-left: 0.75rem;
    margin-left: -0.75rem;
  }

  .toc-link:hover {
    color: rgb(250 250 250);
  }

  .toc-link.active {
    color: rgb(139 109 255);
    border-left-color: rgb(108 71 255);
    font-weight: 500;
  }

  /* Indentation classes */
  :global(.pl-0) {
    padding-left: 0;
  }

  :global(.pl-3) {
    padding-left: 0.75rem;
  }

  :global(.pl-6) {
    padding-left: 1.5rem;
  }

  :global(.pl-9) {
    padding-left: 2.25rem;
  }

  /* Custom scrollbar */
  .toc-container {
    scrollbar-width: thin;
    scrollbar-color: rgb(64 64 64) transparent;
  }

  .toc-container::-webkit-scrollbar {
    width: 0.375rem;
  }

  .toc-container::-webkit-scrollbar-track {
    background: transparent;
  }

  .toc-container::-webkit-scrollbar-thumb {
    background: rgb(64 64 64);
    border-radius: 0.25rem;
  }

  .toc-container::-webkit-scrollbar-thumb:hover {
    background: rgb(82 82 82);
  }
</style>
