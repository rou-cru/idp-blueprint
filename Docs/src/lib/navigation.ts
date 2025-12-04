/**
 * Navigation configuration for the documentation site
 * This replaces the previous Starlight sidebar configuration
 */

export interface NavItem {
  label: string;
  href?: string;
  items?: NavItem[];
}

export interface NavSection {
  label: string;
  collapsed: boolean;
  items: NavItem[];
}

export const sidebarConfig: NavSection[] = [
  {
    label: 'Getting Started',
    collapsed: false,
    items: [
      { label: 'Overview', href: '/getting-started/overview' },
      { label: 'Prerequisites', href: '/getting-started/prerequisites' },
      { label: 'Quickstart', href: '/getting-started/quickstart' },
      { label: 'Deployment', href: '/getting-started/deployment' },
      { label: 'Verify Installation', href: '/getting-started/verify' },
    ],
  },
  {
    label: 'Architecture',
    collapsed: true,
    items: [
      { label: 'Overview', href: '/architecture/overview' },
      { label: 'Bootstrap', href: '/architecture/bootstrap' },
      { label: 'Infrastructure', href: '/architecture/infrastructure' },
      { label: 'Applications', href: '/architecture/applications' },
      { label: 'Secrets Management', href: '/architecture/secrets' },
      { label: 'Policies', href: '/architecture/policies' },
      { label: 'Observability', href: '/architecture/observability' },
      { label: 'CI/CD', href: '/architecture/cicd' },
      { label: 'Visual Overview', href: '/architecture/visual' },
      { label: 'Diagrams', href: '/architecture/diagrams.d2' },
    ],
  },
  {
    label: 'Concepts',
    collapsed: true,
    items: [
      { label: 'Overview', href: '/concepts' },
      { label: 'Design Philosophy', href: '/concepts/design-philosophy' },
      { label: 'GitOps Model', href: '/concepts/gitops-model' },
      { label: 'Networking & Gateway', href: '/concepts/networking-gateway' },
      { label: 'Scheduling & Node Pools', href: '/concepts/scheduling-nodepools' },
      { label: 'Security & Policy Model', href: '/concepts/security-policy-model' },
    ],
  },
  {
    label: 'Operate',
    collapsed: true,
    items: [
      { label: 'Add Component', href: '/operate/add-component' },
      { label: 'Application Sets', href: '/operate/application-sets' },
      { label: 'Contracts', href: '/operate/contracts' },
      { label: 'Feature Toggles', href: '/operate/feature-toggles' },
      { label: 'Helm Docs Conventions', href: '/operate/helm-docs-conventions' },
      { label: 'Scaling & Tuning', href: '/operate/scaling-tuning' },
    ],
  },
  {
    label: 'Components',
    collapsed: true,
    items: [
      {
        label: 'Infrastructure',
        items: [
          { label: 'Overview', href: '/components/infrastructure' },
          { label: 'ArgoCD', href: '/components/infrastructure/argocd' },
          { label: 'Cert Manager', href: '/components/infrastructure/cert-manager' },
          { label: 'Cilium', href: '/components/infrastructure/cilium' },
          { label: 'External Secrets', href: '/components/infrastructure/external-secrets' },
          { label: 'Gateway API', href: '/components/infrastructure/gateway-api' },
        ],
      },
      {
        label: 'Observability',
        items: [
          { label: 'Overview', href: '/components/observability' },
          { label: 'Fluent Bit', href: '/components/observability/fluent-bit' },
          { label: 'Grafana', href: '/components/observability/grafana' },
          { label: 'Loki', href: '/components/observability/loki' },
          { label: 'Prometheus', href: '/components/observability/prometheus' },
          { label: 'Pyrra', href: '/components/observability/pyrra' },
        ],
      },
      {
        label: 'CI/CD',
        items: [
          { label: 'Overview', href: '/components/cicd' },
          { label: 'Argo Workflows', href: '/components/cicd/argo-workflows' },
          { label: 'SonarQube', href: '/components/cicd/sonarqube' },
        ],
      },
      {
        label: 'Security',
        items: [
          { label: 'Overview', href: '/components/security' },
          { label: 'Trivy', href: '/components/security/trivy' },
        ],
      },
      {
        label: 'Policy',
        items: [
          { label: 'Overview', href: '/components/policy' },
          { label: 'Kyverno', href: '/components/policy/kyverno' },
          { label: 'Policy Reporter', href: '/components/policy/policy-reporter' },
        ],
      },
      {
        label: 'Developer Portal',
        items: [
          { label: 'Overview', href: '/components/developer-portal' },
          { label: 'Backstage', href: '/components/developer-portal/backstage' },
        ],
      },
      {
        label: 'Eventing',
        items: [
          { label: 'Overview', href: '/components/eventing' },
        ],
      },
    ],
  },
  {
    label: 'Reference',
    collapsed: true,
    items: [
      { label: 'Contributing', href: '/reference/contributing' },
      { label: 'FinOps Tags', href: '/reference/finops-tags' },
      { label: 'Labels Standard', href: '/reference/labels-standard' },
      { label: 'URLs & Credentials', href: '/reference/urls-credentials' },
    ],
  },
];

// Site metadata
export const siteConfig = {
  title: 'IDP Blueprint',
  description: 'Enterprise-grade Internal Developer Platform Blueprint - Production-ready platform engineering stacks',
  url: 'https://idp-blueprint.roura.xyz',
  social: {
    github: 'https://github.com/rou-cru/idp-blueprint',
  },
};
