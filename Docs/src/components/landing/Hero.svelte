<script lang="ts">
  import Icon from '@iconify/svelte';
</script>

<section class="relative py-32 px-6 overflow-hidden">
  <!-- Background Glow -->
  <div class="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full max-w-7xl opacity-40 pointer-events-none z-0">
    <div class="absolute top-[-10%] left-[20%] w-[600px] h-[600px] bg-brand-purple/20 blur-[120px] rounded-full mix-blend-screen"></div>
    <div class="absolute top-[10%] right-[20%] w-[500px] h-[500px] bg-brand-purple-dark/20 blur-[100px] rounded-full mix-blend-screen"></div>
  </div>

  <div class="relative z-10 max-w-4xl mx-auto text-center">
    <h1 class="text-5xl md:text-7xl font-bold tracking-tight mb-12 leading-[1.1]">
      <span class="text-transparent bg-clip-text bg-gradient-to-r from-brand-purple-light via-brand-purple to-brand-purple-dark">
        IDP Blueprint
      </span>
    </h1>

    <p class="text-xl md:text-2xl text-text-secondary mb-12 leading-relaxed max-w-3xl mx-auto">
      Open-source reference architecture and working implementation for building production-ready Internal Developer Platforms
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

    <div class="mt-16 pt-8 border-t border-border-subtle/30 flex justify-center gap-8">
        <div class="flex items-center gap-3 text-text-secondary group hover:text-text-primary transition-colors">
          <Icon icon="simple-icons:kubernetes" width="24" height="24" />
          <span class="text-sm font-medium">Kubernetes</span>
        </div>
        <div class="flex items-center gap-3 text-text-secondary group hover:text-text-primary transition-colors">
          <Icon icon="simple-icons:argo" width="24" height="24" />
          <span class="text-sm font-medium">ArgoCD</span>
        </div>
        <div class="flex items-center gap-3 text-text-secondary group hover:text-text-primary transition-colors">
          <Icon icon="simple-icons:cilium" width="24" height="24" />
          <span class="text-sm font-medium">Cilium</span>
        </div>
        <div class="flex items-center gap-3 text-text-secondary group hover:text-text-primary transition-colors">
          <Icon icon="simple-icons:vault" width="24" height="24" />
          <span class="text-sm font-medium">Vault</span>
        </div>
    </div>
  </div>
</section>
