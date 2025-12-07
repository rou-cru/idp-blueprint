<script lang="ts">
  import Icon from '@iconify/svelte';
</script>

<section class="relative pt-32 pb-20 lg:pt-48 lg:pb-32 px-6 overflow-hidden">
  <!-- Background Glow -->
  <div class="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full max-w-7xl opacity-40 pointer-events-none z-0">
    <div class="absolute top-[-10%] left-[20%] w-[600px] h-[600px] bg-brand-purple/20 blur-[120px] rounded-full mix-blend-screen"></div>
    <div class="absolute top-[10%] right-[20%] w-[500px] h-[500px] bg-brand-purple-dark/20 blur-[100px] rounded-full mix-blend-screen"></div>
  </div>

  <div class="relative z-10 max-w-4xl mx-auto text-center">
    <div class="inline-flex items-center gap-2 px-3 py-1 mb-8 rounded-full bg-bg-elevated border border-border-subtle text-xs font-medium text-brand-purple-light animate-fade-in">
      <span class="relative flex h-2 w-2">
        <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-brand-purple opacity-75"></span>
        <span class="relative inline-flex rounded-full h-2 w-2 bg-brand-purple"></span>
      </span>
      v1.0 Public Preview
    </div>

    <h1 class="text-5xl md:text-7xl font-bold tracking-tight text-text-primary mb-8 leading-[1.1]">
      The Enterprise <br />
      <span class="text-transparent bg-clip-text bg-gradient-to-r from-brand-purple-light via-brand-purple to-brand-purple-dark">
        IDP Blueprint
      </span>
    </h1>

    <p class="text-xl md:text-2xl text-text-secondary mb-12 leading-relaxed max-w-2xl mx-auto">
      A complete, production-ready Internal Developer Platform reference architecture. 
      Built on Kubernetes, ArgoCD, and GitOps principles.
    </p>

    <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
      <a 
        href="/getting-started/overview/"
        class="h-12 px-8 rounded-lg bg-brand-purple hover:bg-brand-purple-light text-white font-medium flex items-center gap-2 transition-all hover:scale-105 focus:ring-2 focus:ring-brand-purple-light focus:ring-offset-2 focus:ring-offset-bg-base"
      >
        Start Building
        <Icon icon="lucide:arrow-right" width="20" height="20" />
      </a>
      
      <a 
        href="/architecture/overview/"
        class="h-12 px-8 rounded-lg bg-bg-elevated border border-border-default hover:border-border-hover text-text-primary hover:bg-bg-subtle font-medium flex items-center gap-2 transition-all"
      >
        <Icon icon="lucide:layers" width="20" height="20" class="text-text-secondary" />
        View Architecture
      </a>
    </div>

    <div class="mt-16 pt-8 border-t border-border-subtle/30 flex justify-center gap-12 opacity-70 grayscale hover:grayscale-0 transition-all duration-500">
        <!-- Placeholder for Tech Stack Logos (can be added later) -->
        <div class="flex items-center gap-2 text-sm text-text-tertiary font-mono">
           <span>KUBERNETES</span>
           <span class="mx-2">•</span>
           <span>ARGOCD</span>
           <span class="mx-2">•</span>
           <span>CILIUM</span>
           <span class="mx-2">•</span>
           <span>VAULT</span>
        </div>
    </div>
  </div>
</section>
