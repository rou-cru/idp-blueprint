# Backstage (Developer Portal)

- **Chart**: `backstage` (https://backstage.github.io/charts) pin 2.6.3, desplegado vía Kustomize `helmCharts`.
- **Namespace**: `backstage`, con `LimitRange` y `ResourceQuota` alineados a una instancia web + Postgres.
- **Secretos**: ExternalSecrets desde Vault (`secret/backstage/app`, `secret/backstage/postgres`), usando `SecretStore` dedicado y SA `external-secrets`.
- **Base de datos**: Subchart Bitnami PostgreSQL habilitado, PVC 8Gi. Las contraseñas se inyectan vía `existingSecret`.
- **Exposición**: `HTTPRoute` `backstage.${DNS_SUFFIX}` en el gateway de la plataforma (TLS termina en Gateway).
- **Monitoreo**: `ServiceMonitor` etiqueta `prometheus: kube-prometheus` midiendo el servicio `backstage` puerto `http`.
- **Operación**:
  - Desplegar aislado: `task stacks:backstage` (requiere `REPO_URL`/`TARGET_REVISION`).
  - Incluido en despliegue completo (`task stacks:deploy`) vía `fuses.backstage` (`config.toml`).
  - Ajustar `backstage/backstage/values.yaml` para imagen personalizada o integraciones adicionales.
