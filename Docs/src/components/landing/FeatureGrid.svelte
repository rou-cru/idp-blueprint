<script lang="ts">
  import Icon from '@iconify/svelte';

  const features = [
    {
      title: "GitOps Native",
      description: "Everything is code. Infrastructure, apps, and policies reconciled automatically via ArgoCD.",
      icon: "lucide:git-branch",
    },
    {
      title: "Policy as Code",
      description: "Kyverno enforces security contracts at the cluster level before deployment.",
      icon: "lucide:shield-check",
    },
    {
      title: "Secure by Design",
      description: "No secrets in Git. Vault integrates with External Secrets Operator to inject credentials securely into Kubernetes Secrets.",
      icon: "lucide:lock",
    },
    {
      title: "Automated Networking",
      description: "Gateway API + Cilium handle traffic with automated TLS certificates via cert-manager.",
      icon: "lucide:network",
    },
    {
      title: "Local to Prod",
      description: "Bootstraps a full enterprise-like environment on your laptop (via k3d) in < 10 minutes.",
      icon: "lucide:laptop",
    },
    {
      title: "Full Observability",
      description: "Day-2 ready. Pre-configured Prometheus, Grafana, Loki, and Fluent-bit stacks with dashboards and SLOs managed as code.",
      icon: "lucide:activity",
    },
    {
        title: "Platform Engineering",
        description: "A reference implementation to compare against your internal stack or start fresh with best practices.",
        icon: "lucide:settings",
        href: "/operate/"
    }
  ];
</script>

<section class="py-24 px-6 bg-bg-base">
  <div class="max-w-7xl mx-auto">
    <div class="mb-12">
      <h2 class="text-3xl md:text-4xl font-bold text-text-primary mb-4">Platform Capabilities</h2>
      <p class="text-text-secondary text-lg max-w-2xl">
        A curated set of best-in-class open source tools, pre-integrated to work together seamlessly.
      </p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 auto-rows-[minmax(280px,auto)]">
      {#each features as feature, i}
        <div 
          class="group relative flex flex-col justify-between p-8 rounded-2xl bg-bg-elevated border border-border-default hover:border-border-hover transition-all duration-300 overflow-hidden h-full"
        >
          <!-- Background Decor -->
          <div class="absolute top-0 right-0 p-6 opacity-10 group-hover:opacity-20 transition-opacity duration-300 grayscale pointer-events-none">
             <Icon icon={feature.icon} width="120" height="120" />
          </div>

          <!-- Header -->
          <div class="relative z-10">
            <div class="w-12 h-12 rounded-xl bg-bg-subtle border border-border-subtle flex items-center justify-center mb-6 text-brand-purple">
                <Icon icon={feature.icon} width="24" height="24" />
            </div>
            
            <h3 class="text-xl font-bold text-text-primary mb-3">{feature.title}</h3>
            <p class="text-text-secondary leading-relaxed text-base">
                {feature.description}
            </p>
          </div>

          <!-- Footer / CTA -->
          {#if feature.href}
            <div class="relative z-10 mt-8 pt-6 border-t border-border-subtle flex items-center text-brand-purple-light text-sm font-medium">
                <span class="mr-2">Explore</span> 
                <Icon icon="lucide:arrow-right" class="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                <a href={feature.href} class="absolute inset-0"><span class="sr-only">Read more about {feature.title}</span></a>
            </div>
          {/if}
        </div>
      {/each}
    </div>
  </div>
</section>
