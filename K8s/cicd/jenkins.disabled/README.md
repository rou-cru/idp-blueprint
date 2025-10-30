# jenkins.disabled

This document lists the configuration parameters for the `jenkins.disabled` component.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agent.containerCap | int | `1` | Container cap (max simultaneous agents). |
| agent.enabled | bool | `true` | Enable Kubernetes agents. |
| agent.idleMinutes | int | `1` | Idle minutes before termination. |
| agent.image | object | `{"repository":"roucru/jenkins","tag":"agent"}` | Custom Jenkins agent image. |
| agent.namespace | string | `"cicd"` | Default namespace for agents. |
| agent.persistence.enabled | bool | `true` |  |
| agent.persistence.size | string | `"8Gi"` |  |
| agent.persistence.storageClassName | string | `"standard"` |  |
| agent.podRetention | string | `"Never"` | Pod retention policy. |
| agent.resources | object | `{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"512m","memory":"1Gi"}}` | Agent resources (builds are resource-intensive). |
| controller.JCasC.authorizationStrategy | string | `"loggedInUsersCanDoAnything:\n  allowAnonymousRead: false"` | Authorization strategy. |
| controller.JCasC.configScripts.appearance-config | string | `"appearance:\n  themeManager:\n    disableUserThemes: false\n    theme: \"dark\"\n"` | Dark theme as default. |
| controller.JCasC.configScripts.kubernetes-cloud | string | `"jenkins:\n  clouds:\n  - kubernetes:\n      name: \"kubernetes\"\n      serverUrl: \"https://kubernetes.default\"\n      namespace: \"cicd\"\n      jenkinsUrl: \"http://jenkins.cicd.svc.cluster.local:8080\"\n      jenkinsTunnel: \"jenkins-agent.cicd.svc.cluster.local:50000\"\n      containerCapStr: \"1\"\n      maxRequestsPerHostStr: \"32\"\n      retentionTimeout: 0\n      connectTimeout: 5\n      readTimeout: 15\n      podLabels:\n      - key: \"app.kubernetes.io/name\"\n        value: \"jenkins-agent\"\n      - key: \"app.kubernetes.io/component\"\n        value: \"build-agent\"\n      - key: \"app.kubernetes.io/part-of\"\n        value: \"idp\"\n      templates: []\n"` | Kubernetes cloud configuration for dynamic agents. |
| controller.JCasC.configScripts.prometheus-config | string | `"unclassified:\n  prometheusConfiguration:\n    path: \"prometheus\"\n    defaultNamespace: \"jenkins\"\n    useAuthenticatedEndpoint: false\n    collectingMetricsPeriodInSeconds: 120\n    countSuccessfulBuilds: true\n    countFailedBuilds: true\n    countUnstableBuilds: true\n    countAbortedBuilds: true\n    countNotBuiltBuilds: true\n    fetchTestResults: true\n    appendParamLabel: false\n    appendStatusLabel: true\n    collectDiskUsage: false\n    collectNodeStatus: true\n    processingDisabledBuilds: false\n    perBuildMetrics: false\n    jobAttributeName: \"jenkins_job\"\n"` | Prometheus metrics configuration. |
| controller.JCasC.configScripts.sonarqube-config | string | `"unclassified:\n  sonarglobalconfiguration:\n    buildWrapperEnabled: true\n    installations:\n      - name: \"SonarQube\"\n        serverUrl: \"http://sonarqube-sonarqube.cicd.svc.cluster.local:9000\"\n        credentialsId: \"sonarqube-token\"\n"` | SonarQube server integration. |
| controller.JCasC.defaultConfig | bool | `true` | Enable default JCasC configuration. |
| controller.JCasC.securityRealm | string | `"local:\n  allowsSignup: false\n  enableCaptcha: false\n  users:\n  - id: \"${chart-admin-username}\"\n    name: \"Jenkins Admin\"\n    password: \"${chart-admin-password}\""` | Security realm (uses admin from existingSecret). |
| controller.admin | object | `{"createSecret":false,"existingSecret":"jenkins-admin-credentials","passwordKey":"jenkins-admin-password","userKey":"jenkins-admin-user","username":"admin"}` | Use existing secret for admin credentials from Vault. |
| controller.admin.username | string | `"admin"` | Admin username (replaces deprecated adminUser). |
| controller.executorMode | string | `"NORMAL"` | Executor mode. |
| controller.healthProbes | bool | `true` |  |
| controller.image | object | `{"pullPolicy":"IfNotPresent","repository":"roucru/jenkins","tag":"master"}` | Custom Jenkins master image. |
| controller.installLatestPlugins | bool | `true` | Install latest versions of dependencies to resolve conflicts automatically. |
| controller.installLatestSpecifiedPlugins | bool | `true` | Install latest versions of explicitly specified plugins. |
| controller.installPlugins[0] | string | `"kubernetes:latest"` |  |
| controller.installPlugins[1] | string | `"workflow-aggregator:latest"` |  |
| controller.installPlugins[2] | string | `"git:latest"` |  |
| controller.installPlugins[3] | string | `"configuration-as-code:latest"` |  |
| controller.installPlugins[4] | string | `"prometheus:latest"` |  |
| controller.installPlugins[5] | string | `"pipeline-graph-view:latest"` |  |
| controller.installPlugins[6] | string | `"dark-theme:latest"` |  |
| controller.installPlugins[7] | string | `"sonar:latest"` |  |
| controller.installPlugins[8] | string | `"kubernetes-credentials-provider:latest"` |  |
| controller.numExecutors | int | `0` | Number of executors on controller (0 = all builds run on agents). |
| controller.overwritePlugins | bool | `true` | Overwrite plugins on upgrade. |
| controller.overwritePluginsFromImage | bool | `true` | Overwrite bundled plugins with installPlugins versions. |
| controller.probes.livenessProbe.failureThreshold | int | `5` |  |
| controller.probes.livenessProbe.httpGet.path | string | `"/login"` |  |
| controller.probes.livenessProbe.httpGet.port | string | `"http"` |  |
| controller.probes.livenessProbe.periodSeconds | int | `10` |  |
| controller.probes.livenessProbe.timeoutSeconds | int | `5` |  |
| controller.probes.readinessProbe.failureThreshold | int | `3` |  |
| controller.probes.readinessProbe.httpGet.path | string | `"/login"` |  |
| controller.probes.readinessProbe.httpGet.port | string | `"http"` |  |
| controller.probes.readinessProbe.periodSeconds | int | `10` |  |
| controller.probes.readinessProbe.timeoutSeconds | int | `5` |  |
| controller.probes.startupProbe.failureThreshold | int | `12` |  |
| controller.probes.startupProbe.httpGet.path | string | `"/login"` |  |
| controller.probes.startupProbe.httpGet.port | string | `"http"` |  |
| controller.probes.startupProbe.periodSeconds | int | `10` |  |
| controller.probes.startupProbe.timeoutSeconds | int | `5` |  |
| controller.resources.limits | object | `{"cpu":"1000m","memory":"2Gi"}` | The maximum resources the Jenkins controller can consume. |
| controller.resources.limits.cpu | string | `"1000m"` | The maximum amount of CPU to allow. |
| controller.resources.limits.memory | string | `"2Gi"` | The maximum amount of memory to allow (Jenkins is memory-intensive). |
| controller.resources.requests | object | `{"cpu":"250m","memory":"512Mi"}` | The minimum resources required for the Jenkins controller. |
| controller.resources.requests.cpu | string | `"250m"` | The amount of CPU to request. |
| controller.resources.requests.memory | string | `"512Mi"` | The amount of memory to request. |
| controller.servicePort | int | `8080` |  |
| controller.serviceType | string | `"ClusterIP"` |  |
| controller.sidecars.configAutoReload.enabled | bool | `true` |  |
| controller.sidecars.configAutoReload.resources.limits.cpu | string | `"100m"` |  |
| controller.sidecars.configAutoReload.resources.limits.memory | string | `"128Mi"` |  |
| controller.sidecars.configAutoReload.resources.requests.cpu | string | `"50m"` |  |
| controller.sidecars.configAutoReload.resources.requests.memory | string | `"64Mi"` |  |
| controller.targetPort | int | `8080` |  |
| rbac.create | bool | `true` | Create RBAC resources. |
| rbac.readSecrets | bool | `true` | Allow Jenkins to read Kubernetes secrets (for kubernetes-credentials-provider). |
| serviceAccount.create | bool | `true` | Create service account. |
| serviceAccount.name | string | `""` | Service account name (auto-generated if empty). |