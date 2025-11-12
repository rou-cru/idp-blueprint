# sonarqube

![Version: 2025.5.0](https://img.shields.io/badge/Version-2025.5.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://www.sonarsource.com/products/sonarqube)

Code quality and security analysis platform

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `2025.5.0` |
| **Chart Type** | `application` |
| **Upstream Project** | [sonarqube](https://www.sonarsource.com/products/sonarqube) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| community.enabled | bool | `true` |  |
| initFs | object | `{"enabled":true}` | Required initContainer to set filesystem permissions. |
| initSysctl | object | `{"enabled":true}` | Required initContainer to set kernel parameters for Elasticsearch. |
| monitoringPasscodeSecretKey | string | `"passcode"` |  |
| monitoringPasscodeSecretName | string | `"sonarqube-monitoring-passcode"` | Monitoring passcode from Vault ExternalSecret. |
| persistence.enabled | bool | `true` |  |
| persistence.size | string | `"2Gi"` | Minimal size for a demo environment. |
| postgresql | object | `{"priorityClassName":"platform-cicd","resources":{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Configuration for the bundled PostgreSQL database. |
| postgresql.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource requests and limits for the PostgreSQL pod. |
| setAdminPassword | object | `{"currentPasswordSecretKey":"currentPassword","currentPasswordSecretName":"sonarqube-admin-credentials","enabled":true,"passwordSecretKey":"password","passwordSecretName":"sonarqube-admin-credentials"}` | Admin password from Vault ExternalSecret. |
| sonarqube.env | list | `[{"name":"SONAR_WEB_JAVAADDITIONALOPTS","value":"-Dsonar.web.proxyScheme=https"}]` | Environment variables for reverse proxy configuration Required when SonarQube is behind a reverse proxy that terminates TLS |
| sonarqube.livenessProbe | object | `{"exec":{"command":["sh","-c","wget --no-proxy --quiet -O /dev/null --timeout=1 --header=\"X-Sonar-Passcode: $SONAR_WEB_SYSTEMPASSCODE\" \"http://localhost:9000/api/system/liveness\""]},"failureThreshold":6,"initialDelaySeconds":60,"periodSeconds":30,"timeoutSeconds":1}` | Liveness probe to check if the SonarQube server is running. |
| sonarqube.priorityClassName | string | `"platform-cicd"` |  |
| sonarqube.readinessProbe | object | `{"exec":{"command":["sh","-c","if curl -s -f http://localhost:9000/api/system/status | grep -q -e '\"status\":\"UP\"' -e '\"status\":\"DB_MIGRATION_NEEDED\"' -e '\"status\":\"DB_MIGRATION_RUNNING\"'; then exit 0 fi exit 1"]},"failureThreshold":6,"initialDelaySeconds":60,"periodSeconds":30,"timeoutSeconds":1}` | Readiness probe to check if the SonarQube server is ready to accept traffic. |
| sonarqube.resources | object | `{"limits":{"cpu":"1000m","memory":"1.5Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | Resource requests and limits for the SonarQube server. |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
