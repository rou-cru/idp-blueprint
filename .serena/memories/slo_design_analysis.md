# Análisis Crítico: Diseño de SLI/SLO del IDP

**Fecha**: 2025-12-19
**Contexto**: Auditoría SRE del stack de observabilidad con enfoque en SLI/SLO implementation

## Resumen Ejecutivo

**Veredicto**: Los SLOs actuales tienen problemas fundamentales de diseño SRE:
- ❌ Miden componentes, no user experience
- ❌ Solo availability (0% latency SLIs)
- ❌ 4 componentes críticos sin SLO
- ❌ Stack de observabilidad no aprovechado
- ❌ 2/6 SLOs técnicamente rotos

## Problemas Fundamentales (Conceptuales)

### 1. Violación de 4 Golden Signals (Google SRE)

**Problema**: 100% de SLOs miden solo availability/errors, 0% miden latency

**Google SRE Workbook dice**: Debes medir Latency + Errors + Traffic + Saturation

**Impacto Real**: Un servicio puede estar "disponible" (99%) pero inutilizable (latency 30s)

**Ejemplo**:
- Gateway actual: 98% requests sin 5xx ✓
- Gateway latency: ??? (no medido) ❌
- User experience: "El portal carga pero tarda 10 segundos" = MALA experiencia aunque SLO pase

### 2. Miden Componentes, No User Experience

**Principio SRE**: SLIs deben medir lo que importa al USUARIO, no al OPERADOR

**Ejemplos actuales vs correctos**:

```
❌ ACTUAL: "ESO sincroniza 97% de secretos correctamente"
   Perspectiva: Operador del sistema
   Problema: No mide si PODS pueden obtener secretos

✅ CORRECTO: "Pods obtienen secretos cuando arrancan 99% del tiempo"
   Perspectiva: Aplicación/Developer
   Mide: Experience end-to-end

---

❌ ACTUAL: "Argo Workflows controller no crashea 99%"
   Perspectiva: Operador de platform
   Problema: Controller up ≠ workflows funcionando

✅ CORRECTO: "CI pipelines completan exitosamente 95% del tiempo"
   Perspectiva: Developer ejecutando CI
   Mide: Success rate real de workflows

---

❌ ACTUAL: "ArgoCD syncs exitosos 95%"
   Perspectiva: GitOps operator
   Problema: Sync exitoso ≠ app funcionando

✅ CORRECTO: "Apps están healthy post-deploy 99%"
   Perspectiva: Developer deployando
   Mide: App health, no solo sync
```

### 3. Componentes Críticos Sin SLO

**Componentes CORE del IDP sin ningún SLO**:

1. **Backstage** (Portal Developer)
   - Criticidad: ALTA - es la puerta de entrada para developers
   - Sin Backstage: No self-service, no app provisioning
   - SLO faltante: UI availability, Scaffolder success rate

2. **Cert-Manager** (Certificate Management)
   - Criticidad: ALTA - sin certificados válidos, no hay TLS
   - Sin Cert-Manager: Services no accesibles via HTTPS
   - SLO faltante: Certificate renewal success, time-to-ready

3. **Kubernetes API Server** (Platform Core)
   - Criticidad: CRÍTICA - sin K8s API, NADA funciona
   - Es literalmente el cerebro del cluster
   - SLO faltante: API availability, API latency p95

4. **Grafana** (Observability Portal)
   - Criticidad: ALTA - sin Grafana, no hay visibilidad
   - Developers ciegos sin dashboards/logs
   - SLO faltante: UI availability, dashboard load time

### 4. No Miden User Journeys

**Principio SRE**: Los usuarios no usan "componentes", ejecutan "journeys"

**Journeys críticos del IDP sin cobertura**:

**Journey 1: "Crear nueva aplicación"**
- Pasos: Backstage → Template → GitHub → ArgoCD → Kubernetes → Healthy
- SLIs necesarios:
  - Backstage UI availability ❌
  - Scaffolder success rate ❌
  - App creation success end-to-end ❌
  - Time to healthy app (latency) ❌
- Situación actual: Solo medimos ArgoCD sync (1 paso de 5)

**Journey 2: "Deploy cambios a producción"**
- Pasos: Git push → ArgoCD detect → Sync → App healthy
- SLIs necesarios:
  - Drift detection time ❌
  - Sync success ✓ (tenemos)
  - App health post-sync ❌
  - Time to deployment (latency) ❌
- Situación actual: Solo medimos sync success

**Journey 3: "Investigar problema via logs"**
- Pasos: Grafana → Loki query → Results
- SLIs necesarios:
  - Grafana UI availability ❌
  - Loki query success ❌
  - Loki query latency p95 ❌
- Situación actual: Solo medimos Loki ingest (write path), no read path

**Journey 4: "Ejecutar CI pipeline"**
- Pasos: Trigger workflow → Execute → SonarQube scan → Success
- SLIs necesarios:
  - Workflow success rate ❌ (medimos controller crashes, no success)
  - SonarQube availability ❌
  - Pipeline duration p95 ❌
- Situación actual: Solo medimos que controller no crashee

## Problemas Técnicos (Implementación)

### Estado Actual de 6 SLOs Implementados

| SLO | Estado | Problema Técnico | Fix Requerido |
|-----|--------|------------------|---------------|
| ExternalSecrets (97%) | 🔴 ROTO | Label `result` no existe en `externalsecret_sync_calls_total` | Usar `externalsecret_sync_calls_error / externalsecret_sync_calls_total` |
| Vault API (97%) | 🔴 ROTO | Label `status` no existe en `vault_core_handle_request_count` | Investigar métricas alternativas o implement relabeling |
| Gateway API (98%) | 🟡 PARCIAL | Funciona pero solo mide errors, no latency | Agregar SLO de latency p95 con `envoy_cluster_upstream_rq_time` |
| Loki Ingest (95%) | 🟡 PARCIAL | Funciona pero solo mide write path, no read | Agregar query latency con `loki_request_duration_seconds{route="query_range"}` |
| ArgoCD Sync (95%) | 🟡 PARCIAL | Sync exitoso ≠ app healthy | Agregar SLO de app health con `argocd_app_info{health_status="Healthy"}` |
| Argo Workflows (99%) | 🟡 PARCIAL | Mide controller crashes, no workflow success | Reemplazar con workflow success rate |

**Resumen**: 2 rotos, 4 incompletos, 0 correctos

### Métricas Reales vs Esperadas

**ExternalSecrets - Problema del label `result`**:
```promql
# ❌ SLO actual (ROTO):
errors: externalsecret_sync_calls_total{result!~"success|succeeded"}
total:  externalsecret_sync_calls_total

# Problema: La métrica NO tiene label `result`
# Métricas reales en ESO v0.20.2:
externalsecret_sync_calls_total{name, namespace, ...}  # Contador total
externalsecret_sync_calls_error{name, namespace, ...}  # Contador errores

# ✅ Fix correcto:
errors: externalsecret_sync_calls_error
total:  externalsecret_sync_calls_total
```

**Vault - Problema del label `status`**:
```promql
# ❌ SLO actual (ROTO):
errors: vault_core_handle_request_count{status="failure"}
total:  vault_core_handle_request_count

# Problema: La métrica NO tiene label `status` en Vault 1.20.4
# Alternativas a investigar:
# 1. vault_core_handle_request_duration_seconds (tiene buckets, inferir errors por timeout?)
# 2. Relabeling desde otras métricas de Vault
# 3. Medir Vault→ESO integration en vez de Vault internal
```

## Stack de Observabilidad: NO Aprovechado

### Recursos Disponibles Pero Sin Usar

**1. Loki - Solo 1 SLO SOBRE Loki, 0 SLIs DESDE Loki**

Tenemos Loki ingesting logs de todo el cluster, pero NO lo usamos para SLIs.

**Oportunidades con Log-based SLIs**:

```logql
# Application Error Rate (log-based)
SLI: Rate de log lines con level=ERROR o FATAL
Target: <1% de total logs
Query: sum(rate({app="myapp"} |= "ERROR" [5m])) / sum(rate({app="myapp"}[5m]))
Ventaja: Captura errores que no generan HTTP 5xx (logic errors, panics)

# Security Event Rate
SLI: Rate de policy violations en Kyverno logs
Target: <0.1%
Query: rate({app="kyverno"} |= "policy violation" [5m])
Ventaja: Security posture visibility

# Crash Loop Detection
SLI: Rate de CrashLoopBackOff en kubelet logs
Target: <1%
Query: Buscar "CrashLoopBackOff" patterns
Ventaja: Early detection de app instability
```

**2. Dashboards - Pyrra genera, pero 0 configurados**

Pyrra auto-genera dashboards de:
- Error Budget consumption
- Burn Rate alerting
- SLO status overview

**Estado actual**: 0 de 19 dashboards en Grafana son de SLO

**Fix**: Configurar Pyrra dashboard provisioning en Grafana sidecar

**3. Synthetic Monitoring - 0 probes activos**

**No tenemos black-box monitoring**. Todos los SLIs son white-box (métricas internas).

**Qué falta**:
```yaml
# Ejemplo: Health Check Prober (usando blackbox-exporter)
- Probe HTTP GET a endpoints críticos cada 1min
- Simula usuario real
- Genera: probe_success, probe_duration_seconds
- Detecta: Fallas que métricas internas no ven (DNS, TLS, routing)

# Ejemplo: User Journey Prober
- Probe que ejecuta journey "create app in Backstage"
- Valida integración end-to-end
- Detecta: Breaking changes en APIs, integration failures
```

**4. Tracing - No existe (Tempo no deployed)**

Sin tracing, no podemos medir latency end-to-end de journeys.

**Impacto**: No sabemos dónde está el bottleneck en "git push → pod healthy"

## SLOs Correctos Recomendados

### TIER 1 - Platform Core (Crítico)

**1. Kubernetes API Server Availability**
```yaml
target: "99.9"  # 99.95% en prod
window: 6h
indicator:
  ratio:
    errors:
      metric: apiserver_request_total{code=~"5.."}
    total:
      metric: apiserver_request_total
```
**Justificación**: Sin K8s API, absolutamente NADA funciona. Es el componente más crítico.

**2. Kubernetes API Server Latency**
```yaml
target: "95"  # 95% de requests <500ms
window: 6h
indicator:
  latency:
    total:
      metric: apiserver_request_duration_seconds_bucket
    threshold: 0.5  # 500ms
    grouping: [verb, resource]
```
**Justificación**: API lenta = cluster inutilizable (kubectl timeouts, reconciliation loops lentos)

**3. ArgoCD Application Health** (NUEVO, complementa sync)
```yaml
target: "99.0"
window: 6h
indicator:
  ratio:
    errors:
      metric: argocd_app_info{health_status!="Healthy"}
    total:
      metric: argocd_app_info
    grouping: [name, project]
```
**Justificación**: Sync exitoso ≠ app funcionando. Esto mide la experiencia real.

**4. Secret Availability End-to-End** (REEMPLAZO de ESO + Vault)
```yaml
target: "99.0"
window: 6h
indicator:
  ratio:
    errors:
      metric: externalsecret_status_condition{type="Ready",status!="True"}
    total:
      metric: externalsecret_status_condition{type="Ready"}
    grouping: [name, namespace]
```
**Justificación**: Mide Vault→ESO→Secret→Pod completo, no solo sync del operador.

**5. Cert-Manager Certificate Readiness** (NUEVO)
```yaml
target: "100"  # 0 tolerance para certs expirados
window: 6h
indicator:
  ratio:
    errors:
      metric: certmanager_certificate_ready_status{condition!="True"}
    total:
      metric: certmanager_certificate_ready_status
    grouping: [name, namespace]
```
**Justificación**: Certificado expirado = servicio inaccesible. 100% target es apropiado.

**6. Gateway Availability** (YA EXISTE, mantener)
```yaml
# Actual está OK
target: "98.0"
window: 6h
indicator:
  ratio:
    errors:
      metric: envoy_cluster_upstream_rq{envoy_response_code=~"5.."}
    total:
      metric: envoy_cluster_upstream_rq
    grouping: [envoy_cluster_name]
```

**7. Gateway Latency p95** (NUEVO)
```yaml
target: "95"  # 95% requests <200ms
window: 6h
indicator:
  latency:
    total:
      metric: envoy_cluster_upstream_rq_time_bucket
    threshold: 0.2  # 200ms
    grouping: [envoy_cluster_name]
```
**Justificación**: Complementa availability. Portal lento = mala experiencia aunque "funcione".

### TIER 2 - Developer Experience

**8. Backstage UI Availability** (NUEVO)
```yaml
target: "99.0"
window: 6h
indicator:
  ratio:
    # Requiere instrumentación custom o synthetic probe
    # Opción 1: Instrumentar Backstage con prometheus middleware
    # Opción 2: Blackbox probe con blackbox-exporter
```
**Justificación**: Sin Backstage UI, developers no pueden self-service.

**9. Backstage Scaffolder Success Rate** (NUEVO)
```yaml
target: "95.0"
window: 6h
indicator:
  ratio:
    # Requiere instrumentación custom en Backstage
    # Métrica: backstage_scaffolder_tasks_total{status="completed|failed"}
```
**Justificación**: Mide success rate de app creation, el journey más crítico del IDP.

**10. Argo Workflows Success Rate** (REEMPLAZO del actual)
```yaml
target: "95.0"
window: 6h
indicator:
  ratio:
    errors:
      metric: argo_workflows_count{status!~"Succeeded|Skipped"}
    total:
      metric: argo_workflows_count
```
**Justificación**: Mide CI/CD pipeline success, no solo si controller crashea.

**11. Grafana UI Availability** (NUEVO)
```yaml
target: "99.0"
window: 6h
indicator:
  ratio:
    errors:
      metric: grafana_http_request_total{status_code=~"5.."}
    total:
      metric: grafana_http_request_total
```
**Justificación**: Sin Grafana, developers ciegos. Critical para observability.

**12. Loki Query Latency** (NUEVO, complementa ingest)
```yaml
target: "95"  # 95% queries <5s
window: 6h
indicator:
  latency:
    total:
      metric: loki_request_duration_seconds_bucket{route="query_range"}
    threshold: 5.0  # 5 seconds
```
**Justificación**: Ingest OK pero query lenta = logs inutilizables para troubleshooting.

**13. Loki Ingest Availability** (YA EXISTE, mantener)
```yaml
# Actual está OK conceptualmente
target: "95.0"
window: 6h
indicator:
  ratio:
    errors:
      metric: loki_request_duration_seconds_count{status_code=~"5..",route=~"(?i).*(push|ingest).*"}
    total:
      metric: loki_request_duration_seconds_count{route=~"(?i).*(push|ingest).*"}
```

### TIER 3 - Advanced (Opcional v2)

**14. Journey: "Time to Production" (Composite SLO)**
```yaml
# Requiere: Tracing con Tempo o synthetic monitoring
# Mide: Tiempo desde git push hasta pod healthy
target: "95"  # 95% deploys <5min
window: 6h
indicator:
  latency:
    # Trace span: git_push → argocd_detect → sync → health_check
    threshold: 300  # 5 minutes
```

**15. Log-based Error Rate**
```yaml
# Requiere: Configurar recording rules desde Loki
target: "99.0"
window: 6h
indicator:
  ratio:
    # LogQL convertido a metric via recording rule
    errors:
      metric: log_messages_total{level=~"ERROR|FATAL"}
    total:
      metric: log_messages_total
```

## Plan de Acción Priorizado

### FASE 1 - Quick Wins (Crítico, 1-2 días)

**Objetivo**: Arreglar SLOs rotos y agregar componentes críticos faltantes

**Tareas**:
1. ✅ **Fix ExternalSecrets SLO**
   - Reemplazar metric con `externalsecret_sync_calls_error / externalsecret_sync_calls_total`
   - Cambiar a medir end-to-end readiness: `externalsecret_status_condition`
   - Complejidad: BAJA (edit YAML)

2. ✅ **Fix Vault SLO**
   - Opción A: Investigar métricas alternativas de Vault
   - Opción B: Reemplazar con Vault→ESO integration metric
   - Opción C: Remover y depender de ESO end-to-end SLO
   - Complejidad: MEDIA (requiere investigación)

3. 🆕 **Add K8s API Server SLO (Availability + Latency)**
   - Crear 2 SLOs: availability y latency p95
   - Métrica: `apiserver_request_total`, `apiserver_request_duration_seconds`
   - Complejidad: BAJA (métrica existe, copy template)

4. 🆕 **Add Cert-Manager SLO**
   - Métrica: `certmanager_certificate_ready_status`
   - Target: 100% (zero tolerance)
   - Complejidad: BAJA

5. 🆕 **Add Grafana UI SLO**
   - Métrica: `grafana_http_request_total` con status_code
   - Complejidad: BAJA

6. 🔧 **Update ArgoCD SLO - Add App Health**
   - Mantener sync SLO existente
   - Agregar nuevo SLO de app health
   - Métrica: `argocd_app_info{health_status}`
   - Complejidad: BAJA

7. 📊 **Configurar Pyrra Dashboards**
   - Habilitar dashboard auto-provisioning en Grafana
   - Verificar aparezcan en Grafana UI
   - Complejidad: MEDIA (requiere entender Pyrra dashboard config)

**Entregables Fase 1**:
- 6 SLOs funcionando correctamente (2 fixes + 4 nuevos)
- Dashboards de Error Budget visibles
- Componentes críticos cubiertos (K8s, Cert-Manager, Grafana)

### FASE 2 - Latency SLIs (Importante, 2-3 días)

**Objetivo**: Agregar SLIs de latency (completar 4 Golden Signals)

**Tareas**:
8. 🆕 **Gateway Latency p95 SLO**
   - Métrica: `envoy_cluster_upstream_rq_time` (histogram)
   - Target: 95% <200ms
   - Complejidad: MEDIA (configurar latency SLO en Pyrra)

9. 🆕 **Loki Query Latency p95 SLO**
   - Métrica: `loki_request_duration_seconds{route="query_range"}`
   - Target: 95% <5s
   - Complejidad: MEDIA

10. 🔧 **Update Argo Workflows - Success Rate**
    - Reemplazar controller availability con workflow success rate
    - Métrica: `argo_workflows_count{status}`
    - Complejidad: MEDIA (verificar métrica existe)

**Entregables Fase 2**:
- 3 SLOs de latency agregados
- Todas las Golden Signals cubiertas (Latency + Errors)
- Workflows miden success, no crashes

### FASE 3 - Advanced (Opcional v2, semanas)

**Objetivo**: Aprovechar stack completo, SLOs avanzados

**Tareas**:
11. 🚀 **Backstage Instrumentación Custom**
    - Agregar prometheus middleware a Backstage
    - Exponer métricas: HTTP requests, scaffolder tasks
    - Crear 2 SLOs: UI availability, scaffolder success
    - Complejidad: ALTA (requiere código custom)

12. 🚀 **Log-based SLIs con Loki**
    - Configurar recording rules: Loki → Prometheus metrics
    - Crear SLOs de error rate basados en logs
    - Complejidad: ALTA (LogQL + recording rules)

13. 🚀 **Synthetic Monitoring**
    - Deploy blackbox-exporter
    - Configurar probes a endpoints críticos
    - Crear SLOs basados en probes
    - Complejidad: ALTA (nueva infra)

14. 🚀 **Journey-based Composite SLOs**
    - Opción A: Deploy Tempo, instrumentar con tracing
    - Opción B: Synthetic probes ejecutando journeys
    - Crear SLO "Time to Production"
    - Complejidad: MUY ALTA (tracing full stack)

15. 🚀 **SonarQube SLO**
    - Instrumentar SonarQube con metrics
    - Crear SLO de availability
    - Complejidad: MEDIA

## Matriz Comparativa Final

| Componente | SLO Actual | ❌ Problema | ✅ SLO Correcto | Fase |
|------------|-----------|-----------|--------------|------|
| **ESO** | Sync 97% | Mide operador, metric rota | Secret avail e2e 99% | 1 |
| **Vault** | API 97% | Label no existe | Vault→ESO integration 99% (o remover) | 1 |
| **Gateway** | Avail 98% | Solo errors | Avail 98% + p95 latency <200ms | 1+2 |
| **ArgoCD** | Sync 95% | Sync ≠ healthy | Sync 95% + App Health 99% | 1 |
| **Workflows** | Controller 99% | Crashes, no success | Workflow success 95% + duration p95 | 2 |
| **Loki** | Ingest 95% | Solo write path | Ingest 95% + Query p95 <5s | 2 |
| **K8s API** | ❌ NONE | Core sin SLO | Avail 99.9% + p95 <500ms | 1 |
| **Cert-Mgr** | ❌ NONE | Crítico sin SLO | Cert ready 100% | 1 |
| **Grafana** | ❌ NONE | Portal sin SLO | UI avail 99% | 1 |
| **Backstage** | ❌ NONE | Portal sin SLO | UI 99% + Scaffolder 95% | 3 |
| **SonarQube** | ❌ NONE | CI tool sin SLO | Avail 99% | 3 |

**Resumen Numérico**:
- Fase 1: 7 SLOs → 6 fixes/adds (crítico)
- Fase 2: +3 SLOs latency (importante)
- Fase 3: +5 SLOs advanced (opcional)
- **Total propuesto**: 15 SLOs vs 6 actuales

## Trade-offs: Demo vs Producción

### Aceptable para Demo (Recursos Limitados)

✅ **Windows 6h vs 28d**: Permite ver burn rates rápido, apropiado para demos
✅ **Targets relajados**: 95-99% vs 99.9-99.99% en prod
✅ **No synthetic monitoring**: Requiere infra adicional (blackbox-exporter)
✅ **No tracing/Tempo**: Consume recursos significativos
✅ **Límites de cardinalidad**: Protege recursos (dropear labels uid, container_id)

### NO Aceptable (Incluso para Demo)

❌ **SLOs técnicamente rotos**: Deben funcionar, no hay excusa
❌ **Componentes críticos sin SLO**: K8s API, Cert-Manager son CORE
❌ **Solo availability, no latency**: Latency es fundamental incluso en demo
❌ **No medir user experience**: Demo debe mostrar CONCEPTO correcto
❌ **No dashboards**: Pyrra genera gratis, configurar es trivial

### Filosofía Correcta para Demo

**El demo debe**:
- ✅ Demostrar PRINCIPIOS SRE correctos
- ✅ Ser EDUCATIVO sobre mejores prácticas
- ✅ Implementar SLOs conceptualmente CORRECTOS
- ✅ Con targets RELAJADOS apropiados para demo
- ✅ Mostrar qué hacer EN PRODUCCIÓN (aunque simplifiquemos implementación)

**El demo NO debe**:
- ❌ Tener SLOs rotos que no funcionan
- ❌ Mostrar anti-patterns como "solo medir availability"
- ❌ Omitir componentes críticos
- ❌ Sacrificar CORRECCIÓN por simplicidad

## Metodología SRE Correcta (Si Empezáramos de Cero)

### 1. Identificar User Journeys (No Componentes)

**Pregunta clave**: "¿Qué HACE un developer en este IDP?"

Respuesta:
- Journey 1: Crear nueva app
- Journey 2: Deploy cambios
- Journey 3: Ver logs/métricas
- Journey 4: Ejecutar CI pipeline

**NO empezar con**: "Qué componentes tenemos?"

### 2. Definir SLIs desde Perspectiva Usuario

**Pregunta clave**: "¿Cuándo considera el usuario que el servicio funciona bien?"

**Ejemplos**:
- ✅ "Puedo crear apps sin errores"
- ✅ "Mis deploys completan en <5min"
- ✅ "Puedo ver logs de mi app cuando falla"
- ❌ "El controller de ArgoCD no crashea" (perspectiva operador)

### 3. Medir 4 Golden Signals (No Solo Availability)

**Para cada journey, medir**:
- **Latency**: ¿Cuánto tarda? (p50, p95, p99)
- **Errors**: ¿Cuántas fallas? (error rate %)
- **Traffic**: ¿Cuánto uso? (requests/sec)
- **Saturation**: ¿Recursos saturados? (CPU, mem, queue depth)

### 4. Priorizar por Criticidad del Journey

**Tier 1**: Platform core (K8s API, secrets, certs)
**Tier 2**: Developer experience (Backstage, GitOps, CI/CD)
**Tier 3**: Observability sobre observability (Prometheus, Loki)

**NO**: Todos los componentes con mismo priority

### 5. White-box + Black-box

**White-box**: Métricas internas (Prometheus)
**Black-box**: Probes externos (synthetic monitoring)

**Ambos necesarios**: White-box diagnostica, black-box detecta

### 6. Dashboards desde Día 1

**Error Budget debe ser VISIBLE**:
- Developers ven cuánto budget queda
- Alerts cuando burn rate alto
- Decisiones basadas en datos (deploy vs estabilizar)

## Referencias y Fuentes

**Google SRE Books**:
- Site Reliability Engineering (Capítulo 4: Service Level Objectives)
- The Site Reliability Workbook (Capítulo 2: Implementing SLOs)

**Principios SRE aplicados**:
- User-centric SLIs (no component-centric)
- 4 Golden Signals (Latency, Traffic, Errors, Saturation)
- Error Budget policy
- Burn rate alerting

**Herramientas del stack**:
- Pyrra v0.7+ (SLO engine)
- Prometheus (metrics collection)
- Loki (log aggregation)
- Grafana (visualization)
- Alertmanager (alerting)
- Argo Events (auto-remediation)

---

**Última actualización**: 2025-12-19
**Estado**: Análisis completado, pendiente implementación Fase 1
