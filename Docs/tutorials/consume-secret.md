# Tutorial: Consume a Secret from Vault

Use External Secrets Operator to sync a secret from Vault to your workload.

## Steps

1) Ensure Vault is initialized and unsealed (`task vault:init`)
2) Define a `ClusterSecretStore` pointing to Vault (if not present)
3) Create an `ExternalSecret` that references a path in Vault
4) Verify the Kubernetes Secret is created/updated
5) Mount the Secret in a Pod and validate at runtime

## References

- [Vault Component](../components/infrastructure/vault/index.md)
- [External Secrets](../components/infrastructure/external-secrets/index.md)
- [Secret Management Flow](../architecture/visual.md#4-secret-management-flow)
