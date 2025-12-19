# Estrategia de Chaos Engineering - IDP Blueprint

## 1. FILOSOFÍA Y PRINCIPIOS

### Objetivos
1. **Validar resiliencia** de componentes ante fallos
2. **Identificar SPOFs** mediante experimentos controlados
3. **Mejorar MTTR** (Mean Time To Recovery) documentando comportamientos
4. **Educar al equipo** sobre failure modes y mitigaciones
5. **Incrementar confianza** en el IDP antes de carga de usuario

### Principios de Chaos en Demo
- **Start small, scale gradually:** Comenzar con 1 componente no-crítico
- **Establish baseline:** Conocer comportamiento normal antes de inducir caos
- **Minimize blast radius:** Aislar experimentos, rollback rápido
- **Automate observation:** Usar métricas/logs existentes, no depender de observación manual
- **Document everything:** Cada experimento = runbook actualizado

### Limitaciones del Entorno Demo
- ✗ No multi-región (single k3d cluster)
- ✗ No carga de usuario real (synthetic load requerida)
- ✗ Hardware limitado (evitar exhaustion tests que congelen laptop)
- ✓ Destroy/recreate rápido (`task destroy && task deploy`)
- ✓ GitOps = reproducibilidad perfecta

## 2. FASES DE IMPLEMENTACIÓN

### Fase 0: Preparación (Pre-Chaos)

**Objetivos:**
- Establecer baseline de observabilidad
- Configurar alertas críticas (Tier 1 de audit)
- Definir SLIs/SLOs para cada experimento
- Preparar tooling de chaos

**Tareas:**
1. Implementar mejoras Tier 1 del audit (CoreDNS 2 replicas, etc.)
2. Configurar Grafana dashboards para componentes bajo test:
   - ArgoCD apps health
   - Vault availability
   - Gateway HTTP success rate
   - ESO sync rate
3. Setup synthetic monitoring (blackbox exporter)
4. Instalar herramientas chaos:
   - **Chaos Mesh** (lightweight, CNCF, soporta pod/network/stress chaos)
   - **k6** para load testing HTTP
   - **Toxiproxy** para network chaos (latency, packet loss)

**Criterios de aceptación:**
- [ ] 4 SLOs de Pyrra monitoreados en Grafana
- [ ] Alertas críticas (ArgoCD unhealthy, cert expiry) desplegadas
- [ ] Blackbox probe exitoso a 3 endpoints (ArgoCD, Grafana, Backstage)
- [ ] Chaos Mesh instalado y validado con experimento trivial (sleep pod kill)

### Fase 1: Chaos de Pods (Stateless)

**Duración estimada:** 1-2 días  
**Objetivo:** Validar recuperación automática de workloads stateless

#### Experimento 1.1: Kill ArgoCD Repo Server
```yaml
# chaos-mesh: pod-kill.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: argocd-repo-kill
  namespace: chaos-testing
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - argocd
    labelSelectors:
      app.kubernetes.io/name: argocd-repo-server
  scheduler:
    cron: "@every 5m"
```

**Hipótesis:** ArgoCD puede recuperarse de muerte de repo-server en <30s sin sync failures.

**Métricas clave:**
- `argocd_app_sync_total` (debe mantenerse constante)
- `argocd_app_health_status{health_status="Healthy"}` (no debe caer)
- Time to pod Ready (target: <30s)

**Criterios de éxito:**
- ✓ Repo server recrea en <30s
- ✓ Sin apps marcadas Degraded durante experimento
- ✓ Sync operations continúan (queue puede crecer pero drena post-recovery)

**Rollback:** `kubectl delete podchaos argocd-repo-kill -n chaos-testing`

**Observaciones esperadas:**
- Deployment controller recrea pod inmediatamente
- ArgoCD application-controller puede reportar "connection refused" por 5-15s
- No hay pérdida de estado (Git es source of truth)

---

#### Experimento 1.2: Kill External Secrets Operator
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: eso-controller-kill
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - external-secrets-system
    labelSelectors:
      app.kubernetes.io/name: external-secrets
  scheduler:
    cron: "@every 3m"
```

**Hipótesis:** ExternalSecrets ya sincronizados permanecen válidos; nuevos syncs se retrasan pero recuperan.

**Métricas clave:**
- `externalsecret_sync_calls_total{status="success"}` (debe recuperarse a rate normal)
- SLO Pyrra `externalsecrets-sync-success` (target: 99.9%)
- Secret staleness (verificar `refreshInterval` de 3m se respeta post-recovery)

**Criterios de éxito:**
- ✓ Secrets existentes no se invalidan
- ✓ ESO controller recrea en <20s
- ✓ Syncs pendientes se procesan en <5m post-recovery

**Variante:** Matar cert-manager controller y observar si ESO webhook falla.

---

#### Experimento 1.3: Kill Cilium Operator
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: cilium-operator-kill
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - kube-system
    labelSelectors:
      app.kubernetes.io/name: cilium-operator
```

**Hipótesis:** Dataplane (cilium agents) no afectado, solo control-plane operations (CEP creation, IPAM).

**Métricas clave:**
- Gateway HTTP success rate (debe mantenerse 100%)
- `cilium_operator_ipam_allocation_ops_total` (puede pausar, luego recuperar)
- Pod creation latency (puede incrementar si IPAM espera operator)

**Criterios de éxito:**
- ✓ Tráfico existente no interrumpido
- ✓ Operator recrea en <30s
- ✓ Nuevos pods obtienen IPs post-recovery

**Riesgo:** Si se crean pods durante downtime, pueden quedar en Pending (IPAM blocked). Mitigación: 2 replicas Operator (Tier 1).

---

### Fase 2: Chaos de Datos Stateful

**Duración estimada:** 2-3 días  
**Objetivo:** Validar recuperación de workloads stateful (DBs, Vault, Prometheus)

#### Experimento 2.1: Restart Vault Pod
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: vault-restart
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - vault-system
    labelSelectors:
      app.kubernetes.io/name: vault
```

**Hipótesis:** Vault auto-unseals (key en K8s Secret), ESO tolera downtime de 30s, secrets existentes en apps no expiran.

**Métricas clave:**
- Vault SLO (target 99.9% = max 6.3m downtime/semana)
- `vault_core_unsealed` (debe volver a 1 en <2m)
- ESO sync failures (esperamos spike, luego recovery)
- App readiness (apps con secrets de ESO deben mantener Running)

**Criterios de éxito:**
- ✓ Vault unseals automáticamente en <2m
- ✓ ESO recupera conexión y reinicia syncs en <3m
- ✓ Apps Running no crashean (secrets en memoria/filesystem persisten)

**Failure mode a documentar:**
- Si Vault no unseal automático → manual `vault operator unseal`
- Si apps nuevas se despliegan durante downtime → CrashLoopBackOff hasta Vault up

**Variante:** Delete PVC de Vault (requiere vault init + re-seed secrets). **Destructivo, solo si backup tested.**

---

#### Experimento 2.2: Fill Loki Disk (Stress Chaos)
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: loki-disk-stress
spec:
  mode: one
  selector:
    namespaces:
      - observability
    labelSelectors:
      app.kubernetes.io/name: loki
  stressors:
    workers: 1
  duration: "3m"
  container:
    - loki
```

**Hipótesis:** Loki con 2Gi PVC y 6h retention puede saturarse bajo log flood. Objetivo: validar cleanup automático.

**Pre-requisito:** Generar log flood artificial:
```bash
kubectl run log-generator --image=mingrammer/flog -- -f json -l -d 1s
```

**Métricas clave:**
- `loki_ingester_chunks_flushed_total` (debe incrementar para liberar disk)
- PVC usage: `kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes`
- Loki readiness (si OOM o disk full → pod crashea)

**Criterios de éxito:**
- ✓ Loki retención de 6h purga chunks antiguos automáticamente
- ✓ Si disk llega a 90%, alerta se dispara (crear PrometheusRule)
- ✓ Sin pérdida de logs nuevos (buffered en Fluent Bit)

**Failure mode:**
- Si disk 100% → Loki crashea, Fluent Bit backpressure, logs se pierden
- Mitigación: Aumentar PVC a 4Gi o reducir retention a 3h

---

#### Experimento 2.3: PostgreSQL Backstage Restart
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: postgres-backstage-kill
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - backstage
    labelSelectors:
      app.kubernetes.io/name: postgresql
```

**Hipótesis:** Backstage tolera restart de DB con reconnect, pero requests en vuelo fallan (5xx errors).

**Pre-requisito:** Synthetic load con k6:
```javascript
// k6-backstage.js
import http from 'k6/http';
export let options = { vus: 5, duration: '10m' };
export default function() {
  http.get('https://backstage.${DNS_SUFFIX}/catalog');
  sleep(2);
}
```

**Métricas clave:**
- Backstage pod restarts (esperamos 0, DB restart no debe crashear app)
- HTTP 5xx rate (esperamos spike <10s, luego recovery)
- PostgreSQL recovery time (target <30s)

**Criterios de éxito:**
- ✓ PostgreSQL recrea y acepta conexiones en <30s
- ✓ Backstage no crashea, solo retorna 5xx temporalmente
- ✓ Sin pérdida de datos (transacciones en vuelo se rollback)

**Failure mode:**
- Si Backstage no tiene connection pooling con retry → crash
- Si PVC corrupto → PostgreSQL no inicia → manual intervention

---

### Fase 3: Chaos de Red (Network Chaos)

**Duración estimada:** 2 días  
**Objetivo:** Validar tolerancia a latencia, packet loss, particiones

#### Experimento 3.1: Latency a Vault
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: vault-latency
spec:
  action: delay
  mode: one
  selector:
    namespaces:
      - vault-system
    labelSelectors:
      app.kubernetes.io/name: vault
  delay:
    latency: "500ms"
    correlation: "50"
    jitter: "100ms"
  duration: "5m"
```

**Hipótesis:** ESO tolera latencia <1s (timeouts por defecto 30s), pero sync rate disminuye.

**Métricas clave:**
- `externalsecret_sync_calls_duration_seconds` (debe incrementar)
- ESO controller logs (buscar timeout warnings)
- SLO sync success (debe mantenerse >99%, pero latency aumenta)

**Criterios de éxito:**
- ✓ Sin sync failures (solo slowness)
- ✓ Si latency >30s → timeouts → ESO retries exitosos
- ✓ Apps no afectadas (secrets ya sincronizados)

**Variante:** Latency a ArgoCD API server desde Backstage (validar Backstage ArgoCD plugin resilience).

---

#### Experimento 3.2: Packet Loss al Gateway
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: gateway-packet-loss
spec:
  action: loss
  mode: all
  selector:
    namespaces:
      - kube-system
    labelSelectors:
      app.kubernetes.io/name: cilium-gateway
  loss:
    loss: "10"
    correlation: "25"
  duration: "3m"
```

**Hipótesis:** HTTP clients retransmiten automáticamente, success rate disminuye ligeramente pero no <95%.

**Pre-requisito:** k6 load test contra Gateway endpoints.

**Métricas clave:**
- Blackbox probe success rate (target >95%)
- Gateway HTTP duration (debe incrementar por retransmits)
- TCP retransmissions (`node_netstat_Tcp_RetransSegs`)

**Criterios de éxito:**
- ✓ Success rate >95% (TCP retransmissions compensan)
- ✓ No timeouts completos (30s timeout default de clients)
- ✓ Latency p99 <5s (TCP backoff exponencial)

**Failure mode:**
- Si loss >25% → timeouts masivos
- Si client sin retry logic → 5xx avalanche

---

#### Experimento 3.3: Partition: Backstage ↔ Dex
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: backstage-dex-partition
spec:
  action: partition
  mode: all
  selector:
    namespaces:
      - backstage
    labelSelectors:
      app.kubernetes.io/name: backstage
  direction: to
  target:
    mode: all
    selector:
      namespaces:
        - backstage
      labelSelectors:
        app.kubernetes.io/name: dex
  duration: "2m"
```

**Hipótesis:** Usuarios ya autenticados continúan navegando (session en cookie), nuevos logins fallan.

**Métricas clave:**
- Dex login success rate (debe caer a 0%)
- Backstage HTTP 5xx en `/api/auth/*` (debe incrementar)
- Backstage requests autenticados (deben continuar si session válida)

**Criterios de éxito:**
- ✓ Sessions activas no interrumpidas
- ✓ Nuevos logins retornan 5xx con error message claro
- ✓ Post-partition, logins recuperan inmediatamente

**Mejora:** Implementar retry en Backstage auth plugin (exponential backoff).

---

### Fase 4: Chaos de Recursos (Resource Exhaustion)

**Duración estimada:** 2 días  
**Objetivo:** Validar comportamiento bajo presión de CPU/memoria/disco

#### Experimento 4.1: CPU Starvation en Worker Node
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: node-cpu-stress
spec:
  mode: one
  selector:
    labelSelectors:
      node-role.kubernetes.io/agent: ""
  stressors:
    cpu:
      workers: 4
      load: 80
  duration: "5m"
```

**Hipótesis:** Pods con PriorityClass alta (platform-critical) mantienen CPU, otros thrash.

**Métricas clave:**
- Node CPU usage (debe llegar a 80%)
- Pod CPU throttling: `container_cpu_cfs_throttled_seconds_total`
- Pod evictions (si memory pressure secundaria)
- Latency de apps (Grafana, ArgoCD)

**Criterios de éxito:**
- ✓ Pods críticos (ArgoCD, Vault, Cilium) mantienen <200ms latency
- ✓ Pods sin PriorityClass (ej. Backstage) latency <2s (degraded pero no down)
- ✓ Sin evictions (CPU no causa eviction, solo memory)

**Failure mode:**
- Si todos los pods sin limits → todos sufren equally (fair share)
- Si kube-scheduler/kubelet CPU starved → control plane degrada

---

#### Experimento 4.2: Memory Pressure en Worker Node
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: node-memory-stress
spec:
  mode: one
  selector:
    labelSelectors:
      node-role.kubernetes.io/agent: ""
  stressors:
    memory:
      workers: 4
      size: "3Gi"  # Agent-0 tiene 4Gi, inducir 75% usage
  duration: "3m"
```

**Hipótesis:** Kubelet evict pods sin PriorityClass o con bajo QoS (BestEffort primero).

**Métricas clave:**
- Node memory usage (debe llegar a 75%+)
- Pod evictions: `kube_pod_status_reason{reason="Evicted"}`
- OOMKills: `container_oom_events_total`
- PriorityClass de pods evicted (esperamos BestEffort primero)

**Criterios de éxito:**
- ✓ Pods críticos (ArgoCD, Vault) no evicted (Guaranteed QoS + PriorityClass)
- ✓ Pods BestEffort (si existen) evicted primero
- ✓ Cluster recupera automáticamente post-stress (pods recreados)

**Failure mode:**
- Si stress >90% memoria → kubelet puede crashear (extreme)
- Si sin ResourceQuotas → nueva pod creation puede fallar (ENOMEM)

---

#### Experimento 4.3: Disk Fill en Node
```bash
# Manual, no hay StressChaos para disk
kubectl run disk-filler --image=busybox -- sh -c "dd if=/dev/zero of=/data/fill bs=1M count=15000"
# 15GB fill en node con 20GB free
```

**Hipótesis:** Kubelet detecta disk pressure, cordons node, evict pods.

**Métricas clave:**
- Node condition `DiskPressure` (debe cambiar a True)
- `kubelet_volume_stats_available_bytes` (debe bajar)
- Pod evictions (todos los pods del node afectado)

**Criterios de éxito:**
- ✓ Kubelet cordons node automáticamente
- ✓ Pods se reesquedulan en node sano
- ✓ Critical pods se priorizan en reescheduling

**Cleanup:** `kubectl delete pod disk-filler && kubectl uncordon <node>`

---

### Fase 5: Chaos Compuesto (GameDays)

**Duración:** 1 día (4-6 horas con equipo)  
**Objetivo:** Simular incidentes realistas multi-componente

#### GameDay 1: "Vault Incident"
**Escenario:** Vault PVC corrupto, necesita recreación.

**Pasos:**
1. T+0: Delete Vault PVC (simula corruption)
2. T+1: Vault pod crashea (cannot mount volume)
3. T+5: SRE detecta via alertas (SLO Vault availability <99.9%)
4. T+10: SRE ejecuta runbook:
   - Recrear PVC
   - `task vault:init`
   - `task vault:generate-secrets`
5. T+20: Vault operational, ESO recupera syncs
6. T+30: Todas las apps healthy

**Métricas de éxito:**
- MTTR <30m (Time to vault fully operational)
- Zero data loss (secrets re-seeded desde config.toml)
- Runbook accuracy (si falta paso, actualizar)

**Learning:** Backup de Raft snapshots es crítico (Tier 2 de audit).

---

#### GameDay 2: "Cascading Failure"
**Escenario:** CoreDNS down → service discovery falla → apps crashean.

**Pasos:**
1. T+0: `kubectl scale deploy coredns -n kube-system --replicas=0`
2. T+1: Apps intentan resolver servicios (ej. Backstage → PostgreSQL)
3. T+2: Connection failures → CrashLoopBackOff avalanche
4. T+5: SRE detecta via "múltiples apps unhealthy" alert
5. T+10: SRE identifica CoreDNS down (check fundacional)
6. T+12: `kubectl scale deploy coredns --replicas=2`
7. T+15: DNS recupera, apps reintentan conexión, todo healthy

**Métricas de éxito:**
- MTTR <15m
- SRE identifica root cause en <5m (requiere training)
- Post-incident: CoreDNS escalado a 2 replicas permanentemente

**Learning:** SPOF en infra básica tiene blast radius máximo.

---

#### GameDay 3: "Certificate Expiry"
**Escenario:** Wildcard cert expira, Gateway rechaza conexiones.

**Pasos:**
1. Pre-GameDay: Reducir validity del cert a 1h (edit issuer duration)
2. T+0: Cert expira
3. T+1: Gateway TLS handshake falla, blackbox probe alerta
4. T+5: SRE verifica cert expirado (`kubectl get cert -n kube-system`)
5. T+10: Cert-manager debería auto-renovar, pero falla (simular: scale cert-manager to 0)
6. T+15: SRE escala cert-manager, fuerza renewal (`kubectl delete secret idp-wildcard-cert`)
7. T+20: Nuevo cert emitido, Gateway funcional

**Métricas de éxito:**
- MTTR <20m
- Alert "cert expiry < 30d" desplegada post-incident (prevent recurrence)

**Learning:** Monitorear validity de certs es Tier 1, auto-renewal debe testearse.

---

### Fase 6: Chaos Continuo (Steady State)

**Objetivo:** Mantener resiliencia a largo plazo

**Estrategia:**
1. **Chaos cron jobs** (low-intensity):
   - Weekly: Random pod kill en namespaces no-críticos
   - Monthly: GameDay con equipo (2h)
2. **Drift detection:**
   - Monthly: Re-run audit script, comparar con baseline
   - Alertar si nuevos SPOFs introducidos (ej. nuevo servicio sin replicas)
3. **Runbook verification:**
   - Quarterly: Ejecutar todos los runbooks documentados (disaster recovery)
4. **Chaos as code:**
   - Store experimentos en Git (`K8s/chaos-experiments/`)
   - ArgoCD app para gestionar ChaosEngine CRs

---

## 3. TOOLING Y SETUP

### Chaos Mesh Installation
```bash
# Add Helm repo
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Create namespace
kubectl create ns chaos-testing

# Install Chaos Mesh
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace=chaos-testing \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock \
  --set dashboard.create=true

# Access dashboard
kubectl port-forward -n chaos-testing svc/chaos-dashboard 2333:2333
# http://localhost:2333
```

**Recursos:** ~200Mi memoria, 2 DaemonSet pods + 3 controllers.

### Blackbox Exporter (Synthetic Monitoring)
```yaml
# K8s/observability/blackbox-exporter/values.yaml
config:
  modules:
    http_2xx:
      prober: http
      timeout: 5s
      http:
        valid_status_codes: [200]
        method: GET
        follow_redirects: true
        preferred_ip_protocol: "ip4"

serviceMonitor:
  enabled: true
  targets:
    - name: argocd
      url: https://argocd.${DNS_SUFFIX}
    - name: grafana
      url: https://grafana.${DNS_SUFFIX}
    - name: backstage
      url: https://backstage.${DNS_SUFFIX}
  interval: 30s
```

**Alertas:**
```yaml
# PrometheusRule
- alert: EndpointDown
  expr: probe_success == 0
  for: 2m
  annotations:
    summary: "Endpoint {{ $labels.instance }} down"
```

### k6 Load Testing
```bash
# Install k6
brew install k6  # macOS
# or download from https://k6.io/docs/getting-started/installation/

# Run test
k6 run k6-backstage.js --out influxdb=http://localhost:8086/k6
```

### Toxiproxy (Network Proxy for Chaos)
```yaml
# Deploy Toxiproxy as sidecar to Vault
# Add container to Vault StatefulSet (patch):
- name: toxiproxy
  image: ghcr.io/shopify/toxiproxy:2.5.0
  ports:
  - containerPort: 8474  # API
  - containerPort: 8200  # Proxied Vault port
# Configure proxy: vault:8200 -> localhost:8200 with latency/packet loss
```

**Uso:**
```bash
# Add latency via Toxiproxy API
curl -X POST http://toxiproxy-api:8474/proxies/vault/toxics \
  -d '{"type":"latency","attributes":{"latency":500,"jitter":100}}'
```

---

## 4. MÉTRICAS Y OBSERVABILIDAD

### SLIs Clave por Componente

| Componente | SLI | Target | Métrica Prometheus |
|------------|-----|--------|-------------------|
| Gateway | Availability | 99.9% | `probe_success{job="blackbox"}` |
| Gateway | Latency p99 | <500ms | `probe_duration_seconds{quantile="0.99"}` |
| Vault | Availability | 99.9% | `up{job="vault"}` |
| ArgoCD | App Health | 95% healthy | `argocd_app_health_status{health_status="Healthy"}/count(argocd_app_info)` |
| ESO | Sync Success | 99.9% | `externalsecret_sync_calls_total{status="success"}/externalsecret_sync_calls_total` |
| Loki | Ingest Availability | 99% | Pyrra SLO `loki-ingest-availability` |
| CoreDNS | Query Success | 99.9% | `coredns_dns_responses_total{rcode="NOERROR"}/coredns_dns_responses_total` |

### Dashboards Requeridos

1. **Chaos Experiments Overview:**
   - Active experiments (ChaosEngine status)
   - Blast radius (affected pods/nodes)
   - SLI deviations durante experimento

2. **Incident Response Dashboard:**
   - Top 10 unhealthy resources
   - Recent pod restarts (1h)
   - Alert firing count por severity
   - Runbook links (annotations en Grafana)

3. **Dependency Graph:**
   - Service mesh topology (Cilium + Hubble)
   - Database connections (PostgreSQL clients)
   - Vault client count

### Alerting Strategy

**Tier 0 (Page immediately):**
- Control plane down (API server, etcd)
- >50% pods in namespace CrashLoopBackOff
- Vault sealed

**Tier 1 (Page during business hours):**
- ArgoCD apps unhealthy >5m
- Certificate expiry <7d
- Disk usage >85%

**Tier 2 (Ticket):**
- Pod restart rate >10/hour
- Memory usage >80%
- SLO burn rate elevated

---

## 5. RUNBOOKS Y PLAYBOOKS

### Runbook Template
```markdown
# Runbook: [Component] [Failure Scenario]

## Symptoms
- Alert: [Alert name]
- Observed: [User-facing impact]

## Investigation
1. Check component health: `kubectl get pods -n <namespace>`
2. Review recent logs: `kubectl logs -n <namespace> <pod> --tail=100`
3. Check metrics: [Grafana dashboard link]

## Resolution
### Quick Fix (MTTR <5m)
- [ ] Step 1
- [ ] Step 2

### Full Recovery (MTTR <30m)
- [ ] Step 1
- [ ] Step 2

## Prevention
- Tier [1/2/3] improvement from audit: [Link]

## Post-Incident
- [ ] Update this runbook if steps wrong
- [ ] Document learnings in memory: incident_learnings_YYYY-MM-DD.md
```

### Runbooks Críticos a Crear

1. **Vault Unsealed pero Unavailable** → Restart, check PVC
2. **ArgoCD Apps OutOfSync** → Manual sync, check repo access
3. **Gateway 5xx Avalanche** → Check cilium-gateway pods, cert validity
4. **CoreDNS Down** → Scale up, check configmap
5. **PostgreSQL Cannot Start** → Check PVC, restore from backup
6. **All Pods Pending** → Check node disk/memory, uncordon nodes
7. **Chaos Experiment Stuck** → Force delete ChaosEngine CRs

---

## 6. SCHEDULE Y ROADMAP

### Semana 1-2: Preparación (Fase 0)
- [ ] Implementar mejoras Tier 1 del audit
- [ ] Deploy Chaos Mesh
- [ ] Configurar blackbox exporter + alertas críticas
- [ ] Setup Grafana dashboards SLI
- [ ] Validar destroy/recreate flow funciona (<10m)

### Semana 3: Fase 1 (Pod Chaos)
- [ ] Experimento 1.1: ArgoCD repo server
- [ ] Experimento 1.2: ESO controller
- [ ] Experimento 1.3: Cilium operator
- [ ] Documentar learnings en runbooks

### Semana 4: Fase 2 (Stateful Chaos)
- [ ] Experimento 2.1: Vault restart
- [ ] Experimento 2.2: Loki disk stress
- [ ] Experimento 2.3: PostgreSQL restart
- [ ] Implementar mejoras Tier 2 si blockers encontrados

### Semana 5: Fase 3 (Network Chaos)
- [ ] Experimento 3.1: Vault latency
- [ ] Experimento 3.2: Gateway packet loss
- [ ] Experimento 3.3: Backstage-Dex partition
- [ ] Tune timeouts/retries basado en resultados

### Semana 6: Fase 4 (Resource Chaos)
- [ ] Experimento 4.1: CPU starvation
- [ ] Experimento 4.2: Memory pressure
- [ ] Experimento 4.3: Disk fill
- [ ] Ajustar ResourceQuotas/limits

### Semana 7: Fase 5 (GameDays)
- [ ] GameDay 1: Vault incident (4h, equipo completo)
- [ ] GameDay 2: Cascading failure (3h)
- [ ] GameDay 3: Cert expiry (2h)
- [ ] Retrospectiva: ¿Qué mejorar?

### Semana 8+: Fase 6 (Steady State)
- [ ] Configurar chaos cron jobs
- [ ] Setup drift detection automation
- [ ] Integrar chaos experiments en CI/CD (test pre-merge?)
- [ ] Quarterly GameDay calendar

---

## 7. SUCCESS CRITERIA

### Quantitative
- [ ] 100% de experimentos planificados ejecutados
- [ ] MTTR promedio <30m en GameDays
- [ ] Zero data loss en experiments destructivos (backups validados)
- [ ] 95% de runbooks actualizados con learnings
- [ ] SLOs mantienen targets durante chaos (except experiment target)

### Qualitative
- [ ] Equipo puede diagnosticar fallo de componente en <5m sin ayuda externa
- [ ] Confianza del equipo en el IDP incrementa (survey pre/post)
- [ ] Chaos se percibe como "normal practice" no "scary"
- [ ] Documentation actualizada refleja realidad (no outdated)

---

## 8. CONSIDERACIONES FINALES

### ¿Cuándo NO hacer Chaos?
- Durante demos a stakeholders (obvio)
- Si ya hay incidente activo (no compound failures)
- Sin observabilidad baseline (vuelo ciego)
- Sin rollback plan (irreversible changes)

### Blast Radius Control
- Empezar con namespace aislado (`chaos-testing`)
- Nunca testear múltiples componentes críticos simultáneamente
- Tener "big red button": `kubectl delete -k K8s/chaos-experiments/`

### Comunicación
- Anunciar chaos experiments con 24h antelación (slack/email)
- Durante GameDays: war room (Zoom/Slack huddle)
- Post-chaos: async retrospectiva (documento compartido)

### Iteración
- Cada experimento fallido = learning opportunity
- Si experimento muestra sistema frágil → pause, fix, re-test
- Chaos no es "romper por romper" sino "validar y mejorar"

---

**Última actualización:** 2025-12-16  
**Autor:** Chaos Engineering Strategy Team  
**Revisión:** Quarterly (cada 3 meses)  
**Herramientas:** Chaos Mesh, k6, Toxiproxy, Blackbox Exporter
