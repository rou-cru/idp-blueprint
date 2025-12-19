# Chaos Engineering Audit - IDP Blueprint (2025-12-16)

## Executive Summary

Auditoría realizada como Chaos Engineer sobre el IDP Blueprint corriendo en k3d (3 nodos: 1 control-plane, 2 workers). El cluster está en estado saludable general con 21 aplicaciones ArgoCD (20 Synced/Healthy, 1 con sync issues menor). La arquitectura está diseñada para producción pero con trade-offs conscientes para demo local.

**Estado del Cluster:**
- Nodos: 3 activos (1 CP + 2 workers), uso memoria: 57-88% en workers
- Pods: Todos Running/Succeeded, sin crashloops
- ArgoCD Apps: 1 app OutOfSync (cicd-argo-workflows - no crítico), resto Healthy
- Vault: Activo, unsealed, HA mode (single replica), 945 raft commits

## 1. SINGLE POINTS OF FAILURE (SPOFs)

### Críticos Identificados

**Control Plane:**
- ✗ 1 solo nodo control-plane (inherente a k3d)
- ✗ etcd embebido en k3s (sin HA)
- ⚠ CoreDNS: 1 replica (tolerable en demo)

**Datos Stateful:**
- ✗ **Vault**: 1 replica (StatefulSet), almacena root token/unseal keys en K8s Secret
- ✗ **ArgoCD Redis**: 1 replica (Deployment), pérdida = cache loss, no estado crítico
- ✗ **PostgreSQL Backstage**: 1 replica (StatefulSet), sin streaming replication
- ✗ **PostgreSQL SonarQube**: 1 replica (StatefulSet), sin backup automatizado
- ✗ **Loki**: 1 replica (StatefulSet), filesystem backend, 6h retention
- ✗ **Prometheus**: 1 replica (StatefulSet), sin Thanos/remote storage

**GitOps/Control:**
- ⚠ ArgoCD components: todos 1 replica (repo-server, application-controller, server, notifications, applicationset-controller)
- ⚠ External Secrets Operator: componentes con 1-2 replicas

**Networking:**
- ✗ Cilium Operator: 1 replica
- ✗ Gateway: single Gateway resource (idp-gateway), backend Service manejado por Cilium

### Solucionables en Demo

**Alta prioridad (bajo overhead):**
1. **CoreDNS**: Escalar a 2 replicas (change: `IT/k3d-cluster.yaml` o patch post-bootstrap)
2. **ArgoCD Repo Server**: 2 replicas (mejora latencia git clone)
3. **Cilium Operator**: 2 replicas (tolera restart sin interrumpir dataplane)
4. **External Secrets Webhook**: Ya en 2 replicas, pero cert-manager webhook 1 replica

**Media prioridad (overhead moderado):**
5. **Grafana**: 2 replicas con session affinity (overhead: ~100Mi adicional)
6. **ArgoCD Redis**: Redis Sentinel (3 nodos) o switch a Redis HA chart (overhead: ~300Mi)

**Baja prioridad (solo si recursos sobran):**
7. PostgreSQL: streaming replication requiere complejidad alta, considerar solo si se testea DR

## 2. CONFIGURACIÓN DE RECURSOS

### Pods sin Límites de Recursos

Identificados 14 pods sin `limits` o `requests` completos:
- argocd-notifications-controller
- external-secrets-webhook
- Cilium agents/envoy (3 por nodo)
- hubble-ui
- local-path-provisioner
- metrics-server
- policy-reporter
- vault-agent-injector

**Riesgo:** Pueden consumir CPU/memoria sin límite, causando contención o eviction de pods críticos.

**Solución:** Agregar ResourceQuotas por namespace y PriorityClasses (ya existen: platform-critical, platform-observability, platform-dashboards). Parchear deployments con límites conservadores.

### Resource Requests/Limits Observados

Buenos ejemplos:
- PostgreSQL Backstage: 200m CPU / 256Mi → 500m / 1Gi
- Redis ArgoCD: 100m / 128Mi → 250m / 256Mi
- Fluent Bit: 50m / 64Mi → 100m / 128Mi

**Problema:** Agent 0 al 88% memoria (3691Mi/4Gi), indica riesgo de OOMKill bajo carga.

**Solución:** 
1. Ajustar límites de Loki (actual desconocido, verificar `K8s/observability/loki/values.yaml`)
2. Considerar aumentar memoria workers en `IT/k3d-cluster.yaml` si HW lo permite (actualmente sin límite explícito)

## 3. POLÍTICAS DE RED Y SEGURIDAD

### Network Policies: **0 configuradas**

**Riesgo ALTO:** Todo pod puede comunicarse con cualquier otro. Blast radius ilimitado en caso de compromiso.

**Soluciones Implementables:**

1. **Deny-all baseline** por namespace (excepto kube-system):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

2. **Allow-list específica:**
   - Backstage → PostgreSQL (5432)
   - SonarQube → PostgreSQL (5432)
   - Apps → Vault (8200) solo desde namespaces con ESO
   - Observability → scrape targets (metrics ports)
   - ArgoCD → kube-apiserver (necesita gestión de ServiceAccounts)

3. **Cilium NetworkPolicies** (L7): Más expresivas que K8s vanilla, pueden filtrar por HTTP path/method.

**Trade-off demo:** NetworkPolicies incrementan complejidad debugging. Implementar en modo audit primero (logs, no deny).

### Webhooks de Admisión: 18 configurados

Incluyen:
- Kyverno (4 ClusterPolicies activas)
- cert-manager
- External Secrets Operator
- Cilium

**Riesgo:** Failure mode de webhooks puede bloquear deployments. Verificar `failurePolicy: Ignore` en no-críticos.

**Acción:** Revisar timeout y `failurePolicy` de cada webhook:
```bash
kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations -o json | jq -r '.items[] | "\(.metadata.name): \(.webhooks[0].failurePolicy // "not-set")"'
```

## 4. OBSERVABILIDAD Y ALERTAS

### Estado Actual

**Positivo:**
- ✓ Prometheus Operator con 34 PrometheusRules
- ✓ 28 ServiceMonitors configurados
- ✓ 4 SLOs de Pyrra (ExternalSecrets sync 99.9%, Gateway 99.9%, Loki 99%, Vault 99.9%)
- ✓ Loki + Fluent Bit para logs centralizados
- ✓ Grafana con datasources Prometheus + Loki

**Gaps Identificados:**

1. **Sin alertas críticas end-to-end:**
   - No hay alerta de "aplicación de usuario" (ej. Backstage down)
   - Falta blackbox monitoring del Gateway (synthetic checks)

2. **Loki con retención 6h solo:**
   - Investigaciones post-mortem difíciles
   - Considerar aumentar a 24-48h si disco permite

3. **Sin distributed tracing:**
   - No hay Tempo/Jaeger
   - Dificulta troubleshooting de latencia cross-service

4. **Métricas de control-plane limitadas:**
   - etcd metrics disponibles pero sin alertas específicas
   - Scheduler/Controller Manager metrics expuestos pero sin dashboards

### Mejoras Solucionables

**Alta prioridad:**
1. **Blackbox exporter** para synthetic monitoring:
   - HTTP probes a `https://grafana.${DNS_SUFFIX}`, `https://argocd.${DNS_SUFFIX}`
   - Alerta si probe falla 3/3 checks en 1m
   - Overhead: ~20Mi, config simple

2. **Alerta de ArgoCD apps degraded:**
```yaml
- alert: ArgoCDAppUnhealthy
  expr: argocd_app_health_status{health_status!="Healthy"} > 0
  for: 5m
  annotations:
    summary: "ArgoCD app {{ $labels.name }} unhealthy"
```

**Media prioridad:**
3. **Dashboard de SLO burn rate** en Grafana (Pyrra provee métricas, falta dashboard)
4. **Fluent Bit metrics** → Prometheus (puerto 2020 ya expuesto, falta ServiceMonitor)

## 5. BACKUP, RECOVERY Y SECRETOS

### Vault

**Configuración actual:**
- Standalone mode, Raft storage en PVC 1Gi
- Unseal key + root token en K8s Secret `vault-init-keys` (namespace vault-system)
- TLS deshabilitado (`tls_disable="true"`)
- key-shares=1, threshold=1

**Riesgos:**
- ✗ Root token accesible desde cualquier pod con acceso a K8s API
- ✗ Sin backup automatizado de Raft snapshots
- ✗ TLS off = secrets en tránsito en claro
- ✗ Pérdida del PVC = pérdida total de secrets

**Soluciones:**

1. **Raft snapshots automatizados** (ALTA PRIORIDAD):
```bash
# CronJob cada 6h
vault operator raft snapshot save /vault/snapshots/snapshot-$(date +%s).snap
```
   - Almacenar en PVC separado o external storage (MinIO local)

2. **Rotar y eliminar root token del cluster:**
```bash
kubectl delete secret vault-init-keys -n vault-system  # Post-bootstrap
vault token revoke <root-token>
```
   - Generar tokens limitados para ESO roles

3. **Enable Vault TLS** (MEDIA PRIORIDAD en demo):
   - Usar cert-manager para generar cert Vault
   - Update SecretStore URLs a https://
   - Overhead: config adicional, pero mejora security posture

4. **Vault Agent Injector cleanup:**
   - Actualmente desplegado pero no usado (apps usan ESO, no sidecar injection)
   - Considerar desactivar para reducir footprint

### Datos Stateful

**PostgreSQL (Backstage + SonarQube):**
- ✗ Sin backups automatizados
- ✗ PVCs sin snapshots

**Solución:** Velero + restic para backup de PVCs, o CronJob con `pg_dump`:
```yaml
# CronJob ejemplo
schedule: "0 2 * * *"  # 2 AM daily
command: ["pg_dump", "-U", "postgres", "-d", "backstage", "-f", "/backup/backstage-$(date +%Y%m%d).sql"]
# Volume: PVC separado para backups
```

**Prometheus + Loki:**
- Sin remote storage, pérdida del PVC = pérdida de métricas/logs
- Acceptable para demo, pero agregar nota en docs

### GitOps State

**Positivo:**
- ✓ Estado declarativo en Git (repo IDP blueprint)
- ✓ Disaster recovery = `task destroy && task deploy`
- ✓ Vault re-seed automático via `task vault:generate-secrets`

**Gap:**
- Configuraciones manuales post-deploy no rastreadas (ej. cambios en Grafana dashboards via UI)
- Solución: Documentar que cambios via UI se pierden en DR

## 6. DEPENDENCY CHAINS Y FAILURE MODES

### Cadenas Críticas Identificadas

1. **cert-manager → Gateway TLS → Todo el ingress**
   - Failure: cert-manager down = certificados no renuevan (1 año validity)
   - Tolerancia: 30 días antes de expiración (no hay alertas configuradas)
   - Solución: Alerta cuando cert validity < 30d

2. **Vault → ESO → Secrets → App startup**
   - Failure: Vault down = ESO no puede crear secrets, apps en CrashLoopBackOff
   - SLO actual: 99.9% (permite 6.3m downtime/semana)
   - Solución: ExternalSecret con `refreshInterval: 3m` ya configurado, pero considerar 2 replicas Vault (requiere HA Raft)

3. **CoreDNS → Resolución interna → Todo**
   - Failure: CoreDNS down = service discovery falla
   - Single replica = SPOF crítico
   - Solución: 2 replicas CoreDNS (alta prioridad)

4. **Cilium → Networking → Todo**
   - Failure: Cilium agents críticos, pero DaemonSet asegura presencia
   - Cilium Operator: control-plane, 1 replica
   - Solución: 2 replicas Operator (cambio simple)

### Blast Radius Actual

Sin NetworkPolicies, compromise de cualquier pod = acceso lateral ilimitado:
- Pod comprometido puede:
  - Acceder a Vault (http://vault.vault-system:8200)
  - Leer secrets de otros namespaces (si SA tiene RBAC)
  - Port-scan cluster interno
  - Exfiltrar datos de PostgreSQL si conoce credenciales

**Mitigación:** NetworkPolicies + Cilium L7 policies + Kyverno para enforce "no privileged pods".

## 7. PROBLEMAS SOLUCIONABLES PRIORIZADOS

### Tier 1 - Crítico, Bajo Overhead (Implementar YA)

1. **CoreDNS a 2 replicas** (overhead: +50Mi)
2. **Cilium Operator a 2 replicas** (overhead: +100Mi)
3. **Alerta cert-manager certificate expiry < 30d** (config: PrometheusRule)
4. **Alerta ArgoCD app unhealthy** (config: PrometheusRule)
5. **Resource limits para pods críticos sin límites** (14 pods identificados)

**Estimado esfuerzo:** 2-4 horas, +200Mi memoria total

### Tier 2 - Alto Impacto, Overhead Moderado

6. **Vault Raft snapshots automatizados** (CronJob, PVC 2Gi adicional)
7. **NetworkPolicies baseline** (deny-all + allow-list mínima, 10-15 policies)
8. **Blackbox exporter** para synthetic monitoring (+20Mi, 1 Deployment)
9. **ArgoCD Repo Server a 2 replicas** (+300Mi estimado)
10. **PostgreSQL backups** (CronJob pg_dump, PVC 5Gi para backups)

**Estimado esfuerzo:** 1-2 días, +600Mi memoria, +7Gi disco

### Tier 3 - Mejoras Adicionales (Si Recursos Permiten)

11. **Redis ArgoCD HA** (Sentinel 3 nodos, +300Mi)
12. **Grafana 2 replicas** (+100Mi)
13. **Vault TLS habilitado** (cert-manager integration)
14. **Increase Loki retention 6h → 24h** (requiere +6Gi PVC)
15. **Distributed tracing** (Tempo + Grafana datasource, +500Mi)

**Estimado esfuerzo:** 3-5 días, +1Gi memoria, +6Gi disco

### No Solucionables en Demo (Limitaciones k3d)

- ✗ Multi-node control-plane (k3d limitation)
- ✗ etcd HA externo (k3s uses embedded etcd)
- ✗ Cloud LoadBalancer (replaced by NodePort + nip.io)
- ✗ PostgreSQL streaming replication (complejidad alta, requiere Patroni/Stolon)

## 8. RECOMENDACIONES PARA PRODUCCIÓN

Cuando se migre de demo a producción, aplicar:

1. **Infraestructura:**
   - Multi-master control plane (3+ nodos)
   - External etcd cluster (3+ nodos)
   - Cloud LoadBalancer para Gateway (replace NodePort)
   - Node pools separados por workload type

2. **Seguridad:**
   - Vaciar `config.toml` credentials (github_token, registry, passwords)
   - Vault TLS + auto-unseal (Cloud KMS)
   - Vault policy granular por namespace (no `secret/*`)
   - NetworkPolicies completas (deny-by-default)
   - Pod Security Standards (enforce restricted)
   - Rotate root token, store unseal keys externally (HSM)

3. **Alta Disponibilidad:**
   - Todos los componentes stateful a 3 replicas
   - PostgreSQL con Patroni/CloudNativePG
   - Redis con Redis Sentinel o Redis Cluster
   - Prometheus con Thanos sidecar (remote storage)
   - Loki distributed mode (S3 backend)

4. **Observabilidad:**
   - Distributed tracing (Tempo/Jaeger)
   - Log retention 30+ días
   - Metrics retention 15+ días (Thanos)
   - On-call integration (PagerDuty/Opsgenie)
   - SLO dashboards con burn rate alerts

5. **DR/Backup:**
   - Velero scheduled backups (cluster state + PVCs)
   - Vault Enterprise replication o snapshot replication
   - PostgreSQL PITR (Point-in-Time Recovery)
   - GitOps repo en Git provider con HA (GitHub Enterprise/GitLab HA)

6. **Compliance:**
   - Audit logs habilitados (K8s audit + Falco)
   - Secrets encryption at rest (K8s EncryptionConfiguration)
   - Image scanning en CI (Trivy ya presente)
   - SBOM generation (Syft + Grype)

---

**Última actualización:** 2025-12-16  
**Auditor:** Chaos Engineer (análisis automatizado + review manual)  
**Cluster:** k3d-idp-demo (3 nodos, k3s v1.33.4+k3s1)
