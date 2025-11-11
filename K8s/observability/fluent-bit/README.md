# fluent-bit

This document lists the configuration parameters for the `fluent-bit` component.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | list | `["--workdir=/fluent-bit/etc","--config=/fluent-bit/etc/conf/fluent-bit.conf"]` | Arguments for the command |
| command | list | `["/fluent-bit/bin/fluent-bit"]` | Command to run |
| config.filters | string | `"[FILTER]\n    Name kubernetes\n    Match *\n    # -- Enrich logs with Kubernetes metadata.\n    Merge_Log On\n    # -- Do not keep the original log after merging.\n    Keep_Log Off\n    # -- Allow pods to suggest a parser.\n    K8S-Logging.Parser On\n    # -- Allow pods to be excluded from logging.\n    K8S-Logging.Exclude On\n\n# The following Lua filter removes known high-cardinality labels to protect Loki's\n# performance. A 'deny-list' approach is used because it's more performant\n# than a Lua-based 'allow-list' and the built-in Kubernetes filter does not\n# support selective inclusion.\n[FILTER]\n    Name        lua\n    Match       kube.*\n    script      /fluent-bit/scripts/remove_labels.lua\n    call        remove_labels\n"` |  |
| config.inputs | string | `"[INPUT]\n    Name tail\n    Path /var/log/containers/*.log\n    multiline.parser cri\n    Tag kube.*\n    Mem_Buf_Limit 5MB\n    Skip_Long_Lines On\n    # Disable inotify to prevent \"too many open files\" errors\n    # Use stat-based file watching instead\n    Inotify_Watcher false\n    DB /var/fluent-bit/state/flb_kube.db\n    DB.Sync Normal\n    Path_Key filename\n    Ignore_Older 24h\n    Threaded On\n"` |  |
| config.outputs | string | `"[OUTPUT]\n    Name loki\n    Match *\n    Host loki.observability.svc.cluster.local\n    Port 3100\n    # -- Automatically add all Kubernetes labels to the log record.\n    auto_kubernetes_labels true\n    # -- Number of retries before dropping logs.\n    Retry_Limit 5\n"` |  |
| config.service | string | `"[SERVICE]\n    Flush {{ .Values.flush }}\n    Log_Level {{ .Values.logLevel }}\n    HTTP_Server On\n    HTTP_Listen 0.0.0.0\n    HTTP_Port {{ .Values.metricsPort }}\n    Health_Check On\n"` |  |
| daemonSetVolumeMounts | list | `[{"mountPath":"/var/log","name":"varlog"},{"mountPath":"/var/lib/docker/containers","name":"varlibdockercontainers","readOnly":true},{"mountPath":"/var/fluent-bit/state","name":"fluentbitstate"}]` | DaemonSet volume mounts |
| daemonSetVolumes | list | `[{"hostPath":{"path":"/var/log"},"name":"varlog"},{"hostPath":{"path":"/var/lib/docker/containers"},"name":"varlibdockercontainers"},{"hostPath":{"path":"/var/fluent-bit/state"},"name":"fluentbitstate"},{"configMap":{"defaultMode":493,"name":"{{ include \"fluent-bit.fullname\" . }}-scripts"},"name":"scripts"}]` | DaemonSet volumes |
| dashboards.annotations | object | `{}` | Annotations |
| dashboards.deterministicUid | bool | `false` | Deterministic UID |
| dashboards.enabled | bool | `true` | Enable dashboards |
| dashboards.labelKey | string | `"grafana_dashboard"` | Label key for dashboards |
| dashboards.labelValue | int | `1` | Label value |
| dashboards.namespace | string | `""` | Namespace |
| flush | int | `1` | Time to wait before flushing data (in seconds) |
| hotReload.enabled | bool | `true` | Enable hot reload |
| hotReload.extraWatchVolumes | list | `[{"mountPath":"/watch/scripts","name":"scripts"}]` | Extra volumes to watch |
| hotReload.image.digest | string | `nil` | Image digest |
| hotReload.image.pullPolicy | string | `"IfNotPresent"` | Pull policy |
| hotReload.image.repository | string | `"ghcr.io/jimmidyson/configmap-reload"` | Image repository |
| hotReload.image.tag | string | `"v0.15.0"` | Image tag |
| hotReload.resources.limits.cpu | string | `"50m"` | CPU limit |
| hotReload.resources.limits.memory | string | `"32Mi"` | Memory limit |
| hotReload.resources.requests.cpu | string | `"10m"` | CPU request |
| hotReload.resources.requests.memory | string | `"16Mi"` | Memory request |
| hotReload.securityContext.allowPrivilegeEscalation | bool | `false` | Allow privilege escalation |
| hotReload.securityContext.capabilities.drop | list | `["ALL"]` | Dropped capabilities |
| hotReload.securityContext.privileged | bool | `false` | Privileged mode |
| hotReload.securityContext.readOnlyRootFilesystem | bool | `true` | Read-only root filesystem |
| hotReload.securityContext.runAsGroup | int | `65532` | Group ID |
| hotReload.securityContext.runAsNonRoot | bool | `true` | Run as non-root |
| hotReload.securityContext.runAsUser | int | `65532` | User ID |
| kind | string | `"DaemonSet"` | DaemonSet or Deployment |
| livenessProbe.failureThreshold | int | `3` | Failure threshold |
| livenessProbe.httpGet | string | `{"path":"/api/v1/health","port":"http"}` | Probe path |
| livenessProbe.httpGet.path | string | `"/api/v1/health"` | Health check path |
| livenessProbe.httpGet.port | string | `"http"` | Port |
| livenessProbe.initialDelaySeconds | int | `30` | Initial delay seconds |
| livenessProbe.periodSeconds | int | `10` | Period seconds |
| livenessProbe.timeoutSeconds | int | `5` | Timeout seconds |
| logLevel | string | `"info"` | Default log level |
| luaScripts."remove_labels.lua" | string | `"function remove_labels(tag, timestamp, record)\n  if record.kubernetes and record.kubernetes.labels then\n    record.kubernetes.labels['pod-template-hash'] = nil\n    record.kubernetes.labels['controller-revision-hash'] = nil\n  end\n  return 2, timestamp, record\nend\n"` | Lua script to remove high-cardinality labels |
| metricsPort | int | `2020` | Metrics port |
| priorityClassName | string | `"platform-observability"` | Priority class for Fluent Bit pods |
| readinessProbe.failureThreshold | int | `3` | Failure threshold |
| readinessProbe.httpGet | string | `{"path":"/api/v1/health","port":"http"}` | Probe path |
| readinessProbe.httpGet.path | string | `"/api/v1/health"` | Health check path |
| readinessProbe.httpGet.port | string | `"http"` | Port |
| readinessProbe.initialDelaySeconds | int | `10` | Initial delay seconds |
| readinessProbe.periodSeconds | int | `10` | Period seconds |
| readinessProbe.timeoutSeconds | int | `5` | Timeout seconds |
| replicaCount | int | `1` | Only applicable if kind=Deployment |
| resources.limits.cpu | string | `"100m"` | CPU limit |
| resources.limits.memory | string | `"128Mi"` | Memory limit |
| resources.requests.cpu | string | `"50m"` | CPU request |
| resources.requests.memory | string | `"64Mi"` | Memory request |
| serviceMonitor.enabled | bool | `false` | Enable ServiceMonitor |
| volumeMounts | list | `[{"mountPath":"/fluent-bit/etc/conf","name":"config"}]` | Volume mounts |