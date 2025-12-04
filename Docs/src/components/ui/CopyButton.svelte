<script lang="ts">
  import Icon from '@iconify/svelte';

  interface Props {
    text: string;
  }

  let { text }: Props = $props();

  let copied = $state(false);

  async function copyToClipboard() {
    try {
      await navigator.clipboard.writeText(text);
      copied = true;
      setTimeout(() => {
        copied = false;
      }, 2000);
    } catch (err) {
      console.error('Failed to copy text:', err);
    }
  }
</script>

<button
  class="copy-button"
  class:copied={copied}
  onclick={copyToClipboard}
  aria-label={copied ? 'Copied!' : 'Copy code'}
  title={copied ? 'Copied!' : 'Copy code'}
>
  {#if copied}
    <Icon icon="lucide:check" width="16" height="16" />
    <span class="copy-text">Copied!</span>
  {:else}
    <Icon icon="lucide:copy" width="16" height="16" />
    <span class="copy-text">Copy</span>
  {/if}
</button>

<style>
  .copy-button {
    position: absolute;
    top: 0.5rem;
    right: 0.5rem;
    display: flex;
    align-items: center;
    gap: 0.375rem;
    padding: 0.375rem 0.625rem;
    background: rgb(38 38 38);
    border: 1px solid rgb(64 64 64);
    border-radius: 0.375rem;
    color: rgb(163 163 163);
    font-size: 0.75rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
    opacity: 0;
    z-index: 10;
  }

  .copy-button:hover {
    background: rgb(64 64 64);
    color: rgb(250 250 250);
    border-color: rgb(82 82 82);
  }

  .copy-button.copied {
    background: rgba(34, 197, 94, 0.15);
    border-color: rgb(34 197 94);
    color: rgb(34 197 94);
  }

  .copy-text {
    white-space: nowrap;
  }

  /* Show button on parent hover */
  :global(pre:hover) .copy-button {
    opacity: 1;
  }

  /* Always show when copied */
  .copy-button.copied {
    opacity: 1;
  }

  /* Focus state */
  .copy-button:focus-visible {
    outline: 2px solid rgb(108 71 255);
    outline-offset: 2px;
    opacity: 1;
  }
</style>
