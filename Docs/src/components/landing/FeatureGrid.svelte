<script lang="ts">
  import Icon from '@iconify/svelte';

  const features = [
    {
      title: "GitOps Delivery",
      icon: "lucide:git-branch",
      color: "#f97316",
      stackIcons: [
        { icon: "simple-icons:argo", label: "Argo CD" },
      ],
    },
    {
      title: "Policy & Governance",
      icon: "lucide:shield-check",
      color: "#22c55e",
      stackIcons: [
        { icon: "lucide:file-shield", label: "Kyverno" },
      ],
    },
    {
      title: "Secrets & Identity",
      icon: "lucide:lock",
      color: "#0ea5e9",
      stackIcons: [
        { icon: "simple-icons:vault", label: "Vault" },
        { icon: "lucide:key-square", label: "External Secrets Operator" },
      ],
    },
    {
      title: "Traffic & TLS",
      icon: "lucide:network",
      color: "#6366f1",
      stackIcons: [
        { icon: "simple-icons:cilium", label: "Cilium" },
        { icon: "lucide:shield-check", label: "cert-manager" },
        { icon: "simple-icons:kubernetes", label: "Gateway API" },
      ],
    },
    {
      title: "Observability & SLOs",
      icon: "lucide:activity",
      color: "#f59e0b",
      stackIcons: [
        { icon: "simple-icons:prometheus", label: "Prometheus" },
        { icon: "simple-icons:grafana", label: "Grafana" },
        { icon: "simple-icons:grafana", label: "Loki" },
        { icon: "simple-icons:fluentbit", label: "Fluent Bit" },
      ],
    },
    {
      title: "Developer Portal",
      icon: "lucide:settings",
      color: "#a855f7",
      href: "/operate/",
      stackIcons: [
        { icon: "simple-icons:backstage", label: "Backstage" },
        { icon: "lucide:key-round", label: "Dex" },
      ],
    }
  ];
</script>

<section class="py-24 px-6 bg-bg-base">
  <div class="max-w-7xl mx-auto">
    <div class="mb-12 text-center max-w-3xl mx-auto">
      <h2 class="text-3xl md:text-4xl font-bold text-text-primary mb-4">Platform Capabilities</h2>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      {#each features as feature, i}
        <div
          class="group relative flex flex-col items-center gap-3 p-5 rounded-lg bg-bg-elevated border border-border-default hover:border-border-hover hover:scale-[1.02] hover:shadow-xl hover:shadow-brand-purple/5 transition-all duration-300 overflow-hidden text-center"
        >
          <!-- Background Decor -->
          <div class="absolute top-0 right-0 p-6 opacity-10 group-hover:opacity-20 transition-opacity duration-300 pointer-events-none" style="color: {feature.color}">
             <Icon icon={feature.icon} width="96" height="96" />
          </div>
          <!-- Header -->
          <div class="relative z-10 flex flex-col items-center gap-3">
            <h3 class="text-xl font-bold text-text-primary">{feature.title}</h3>
            {#if feature.stackIcons}
              <div class="flex flex-wrap justify-center gap-3">
                {#each feature.stackIcons as stack}
                  <div class="flex items-center gap-1 px-3 py-1 rounded-full bg-bg-elevated/50 border border-border-default/50 text-sm text-text-primary">
                    <Icon icon={stack.icon} width="18" height="18" />
                    <span>{stack.label}</span>
                  </div>
                {/each}
              </div>
            {/if}
          </div>

          <!-- Footer / CTA -->
          {#if feature.href}
            <div class="absolute bottom-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300 z-20">
              <Icon icon="lucide:arrow-up-right" width="20" height="20" class="text-brand-purple" />
            </div>
            <a href={feature.href} class="absolute inset-0" aria-label={`Read more about ${feature.title}`}></a>
          {/if}
        </div>
      {/each}
    </div>
  </div>
</section>
