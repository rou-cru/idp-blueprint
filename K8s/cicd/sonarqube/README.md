# sonarqube

This document lists the configuration parameters for the `sonarqube` component.

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
| sonarqube.livenessProbe | object | `{"exec":{"command":["sh","-c","wget --no-proxy --quiet -O /dev/null --timeout=1 --header=\"X-Sonar-Passcode: $SONAR_WEB_SYSTEMPASSCODE\" \"http://localhost:9000/api/system/liveness\""]},"failureThreshold":6,"initialDelaySeconds":60,"periodSeconds":30,"timeoutSeconds":1}` | Liveness probe to check if the SonarQube server is running. |
| sonarqube.priorityClassName | string | `"platform-cicd"` |  |
| sonarqube.readinessProbe | object | `{"exec":{"command":["sh","-c","if curl -s -f http://localhost:9000/api/system/status | grep -q -e '\"status\":\"UP\"' -e '\"status\":\"DB_MIGRATION_NEEDED\"' -e '\"status\":\"DB_MIGRATION_RUNNING\"'; then exit 0 fi exit 1"]},"failureThreshold":6,"initialDelaySeconds":60,"periodSeconds":30,"timeoutSeconds":1}` | Readiness probe to check if the SonarQube server is ready to accept traffic. |
| sonarqube.resources | object | `{"limits":{"cpu":"1000m","memory":"1.5Gi"},"requests":{"cpu":"250m","memory":"1Gi"}}` | Resource requests and limits for the SonarQube server. |