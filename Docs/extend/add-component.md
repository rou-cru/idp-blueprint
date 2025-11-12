# Add a New Component

How to introduce a new stack component using the existing GitOps patterns.

## Steps

1) Create a directory under the appropriate stack (e.g., `K8s/observability/<name>`)
2) Add Kustomize overlay and optional `helmCharts` entries
3) Add canonical labels and documentation
4) Commit and push; ApplicationSet generates an Application

## References

- [ApplicationSets Patterns](application-sets.md)
- [Helm-docs Conventions](helm-docs-conventions.md)
- [Labels & Metadata](labels-metadata.md)

