# sonarqube

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) 

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `0.1.0` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| community.enabled | bool | `true` | Enable the community SonarQube edition |
| initFs | object | `{"enabled":true}` | Required initContainer to set filesystem permissions. |
| initFs.enabled | bool | `true` | Enable filesystem permissions init container |
| initSysctl | object | `{"enabled":true}` | Required initContainer to set kernel parameters for Elasticsearch. |
| initSysctl.enabled | bool | `true` | Enable sysctl init container |
| monitoringPasscodeSecretKey | string | `"passcode"` | Key that stores the monitoring passcode |
| monitoringPasscodeSecretName | string | `"sonarqube-monitoring-passcode"` | Secret containing the monitoring passcode |
| persistence.enabled | bool | `true` | Enable persistent volume claims |
| persistence.size | string | `"2Gi"` | PVC size for SonarQube data |
| postgresql | object | `{"priorityClassName":"platform-cicd","resources":{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Configuration for the bundled PostgreSQL database. |
| postgresql.priorityClassName | string | `"platform-cicd"` | Priority class for PostgreSQL pods |
| postgresql.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource requests and limits for the PostgreSQL pod. |
| postgresql.resources.limits.cpu | string | `"250m"` | CPU limit for PostgreSQL |
| postgresql.resources.limits.memory | string | `"256Mi"` | Memory limit for PostgreSQL |
| postgresql.resources.requests.cpu | string | `"100m"` | CPU request for PostgreSQL |
| postgresql.resources.requests.memory | string | `"128Mi"` | Memory request for PostgreSQL |
| setAdminPassword | object | `{"currentPasswordSecretKey":"currentPassword","currentPasswordSecretName":"sonarqube-admin-credentials","enabled":true,"passwordSecretKey":"password","passwordSecretName":"sonarqube-admin-credentials"}` | Admin password from Vault ExternalSecret. |
| setAdminPassword.currentPasswordSecretKey | string | `"currentPassword"` | Key for the existing admin password |
| setAdminPassword.currentPasswordSecretName | string | `"sonarqube-admin-credentials"` | Secret that stores the current password for rotation |
| setAdminPassword.enabled | bool | `true` | Pull admin password from Vault-managed secret |
| setAdminPassword.passwordSecretKey | string | `"password"` | Key within the admin password secret |
| setAdminPassword.passwordSecretName | string | `"sonarqube-admin-credentials"` | Secret containing admin credentials |
| sonarqube.env | list | `[{"name":"SONAR_WEB_JAVAADDITIONALOPTS","value":"-Dsonar.web.proxyScheme=https"}]` | Environment variables for reverse proxy configuration Required when SonarQube is behind a reverse proxy that terminates TLS |
| sonarqube.livenessProbe | object | `{"exec":{"command":["sh","-c","wget --no-proxy --quiet -O /dev/null --timeout=1 --header=\"X-Sonar-Passcode: $SONAR_WEB_SYSTEMPASSCODE\" \"http://localhost:9000/api/system/liveness\""]},"failureThreshold":6,"initialDelaySeconds":60,"periodSeconds":30,"timeoutSeconds":1}` | Liveness probe to check if the SonarQube server is running. |
| sonarqube.livenessProbe.failureThreshold | int | `6` | Number of failures tolerated |
| sonarqube.livenessProbe.initialDelaySeconds | int | `60` | Delay before starting liveness checks |
| sonarqube.livenessProbe.periodSeconds | int | `30` | Frequency of liveness checks |
| sonarqube.livenessProbe.timeoutSeconds | int | `1` | Timeout for each liveness probe |
| sonarqube.priorityClassName | string | `"platform-cicd"` | Priority class for SonarQube pods |
| sonarqube.readinessProbe | object | `{"exec":{"command":["sh","-c","if curl -s -f http://localhost:9000/api/system/status | grep -q -e '\"status\":\"UP\"' -e '\"status\":\"DB_MIGRATION_NEEDED\"' -e '\"status\":\"DB_MIGRATION_RUNNING\"'; then exit 0; fi; exit 1\n"]},"failureThreshold":6,"initialDelaySeconds":60,"periodSeconds":30,"timeoutSeconds":1}` | Readiness probe to check if the SonarQube server is ready to accept traffic. |
| sonarqube.readinessProbe.failureThreshold | int | `6` | Number of readiness failures tolerated |
| sonarqube.readinessProbe.initialDelaySeconds | int | `60` | Delay before starting readiness checks |
| sonarqube.readinessProbe.periodSeconds | int | `30` | Frequency of readiness checks |
| sonarqube.readinessProbe.timeoutSeconds | int | `1` | Timeout for each readiness probe |
| sonarqube.resources | object | `{"limits":{"cpu":"1000m","memory":"1.5Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | Resource requests and limits for the SonarQube server. |
| sonarqube.resources.limits.cpu | string | `"1000m"` | CPU limit for SonarQube |
| sonarqube.resources.limits.memory | string | `"1.5Gi"` | Memory limit for SonarQube |
| sonarqube.resources.requests.cpu | string | `"250m"` | CPU request for SonarQube |
| sonarqube.resources.requests.memory | string | `"1Gi"` | Memory request for SonarQube |

