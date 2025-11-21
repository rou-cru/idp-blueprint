# backstage

![Version: 2.6.3](https://img.shields.io/badge/Version-2.6.3-informational?style=flat-square)

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `2.6.3` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backstage.appConfig.app.baseUrl | string | `"https://backstage.${DNS_SUFFIX}"` |  |
| backstage.appConfig.app.title | string | `"Backstage"` |  |
| backstage.appConfig.backend.baseUrl | string | `"https://backstage.${DNS_SUFFIX}"` |  |
| backstage.appConfig.backend.cors.origin | string | `"https://backstage.${DNS_SUFFIX}"` |  |
| backstage.appConfig.backend.database.client | string | `"pg"` |  |
| backstage.appConfig.backend.database.connection.database | string | `"backstage"` |  |
| backstage.appConfig.backend.database.connection.host | string | `"backstage-postgresql-hl"` |  |
| backstage.appConfig.backend.database.connection.password | string | `"${POSTGRES_PASSWORD}"` |  |
| backstage.appConfig.backend.database.connection.port | int | `5432` |  |
| backstage.appConfig.backend.database.connection.ssl.enabled | bool | `false` |  |
| backstage.appConfig.backend.database.connection.user | string | `"backstage"` |  |
| backstage.appConfig.backend.listen.port | int | `7007` |  |
| backstage.extraEnv[0].name | string | `"BACKEND_SECRET"` |  |
| backstage.extraEnv[0].valueFrom.secretKeyRef.key | string | `"BACKEND_SECRET"` |  |
| backstage.extraEnv[0].valueFrom.secretKeyRef.name | string | `"backstage-app-secrets"` |  |
| backstage.extraEnv[1].name | string | `"POSTGRES_PASSWORD"` |  |
| backstage.extraEnv[1].valueFrom.secretKeyRef.key | string | `"POSTGRES_PASSWORD"` |  |
| backstage.extraEnv[1].valueFrom.secretKeyRef.name | string | `"backstage-app-secrets"` |  |
| backstage.image.pullPolicy | string | `"IfNotPresent"` |  |
| backstage.image.repository | string | `"backstage/backstage"` |  |
| backstage.image.tag | string | `"latest"` |  |
| backstage.ingress.enabled | bool | `false` |  |
| backstage.priorityClassName | string | `"platform-dashboards"` |  |
| backstage.replicaCount | int | `1` |  |
| backstage.resources.limits.cpu | string | `"1000m"` |  |
| backstage.resources.limits.memory | string | `"1Gi"` |  |
| backstage.resources.requests.cpu | string | `"300m"` |  |
| backstage.resources.requests.memory | string | `"512Mi"` |  |
| backstage.service.port | int | `7007` |  |
| backstage.service.portName | string | `"http"` |  |
| backstage.serviceAccount.create | bool | `true` |  |
| postgresql.auth.database | string | `"backstage"` |  |
| postgresql.auth.existingSecret | string | `"backstage-postgresql"` |  |
| postgresql.auth.secretKeys.adminPasswordKey | string | `"postgres-password"` |  |
| postgresql.auth.secretKeys.userPasswordKey | string | `"password"` |  |
| postgresql.auth.username | string | `"backstage"` |  |
| postgresql.enabled | bool | `true` |  |
| postgresql.primary.persistence.enabled | bool | `true` |  |
| postgresql.primary.persistence.size | string | `"8Gi"` |  |
| postgresql.primary.podAnnotations."argocd.argoproj.io/sync-wave" | string | `"1"` |  |
| postgresql.primary.resources.limits.cpu | string | `"500m"` |  |
| postgresql.primary.resources.limits.memory | string | `"1Gi"` |  |
| postgresql.primary.resources.requests.cpu | string | `"200m"` |  |
| postgresql.primary.resources.requests.memory | string | `"512Mi"` |  |
