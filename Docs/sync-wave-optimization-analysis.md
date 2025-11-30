# Análisis y Optimización de Sync Waves

## Resumen Ejecutivo

El deploy actual de Backstage es innecesariamente lento debido a una secuenciación excesiva de sync waves. La optimización propuesta puede reducir el tiempo de deploy aproximadamente **40-50%** al permitir que recursos independientes se desplieguen en paralelo.

## Situación Actual

### Distribución de Sync Waves en Backstage

```
Wave -2: 13 recursos (namespace, RBAC, templates, placeholders)
Wave -1:  7 recursos (SecretStore, ExternalSecrets, Jobs, catalog)
Wave  1:  3 recursos (LimitRange, ResourceQuota, PostgreSQL pods)
Wave  0:  ~ (Backstage app, Dex app - default wave)
```

### Flujo de Deploy Actual

```
Wave -2 (espera hasta completar)
  ├─ namespace
  ├─ dex: RBAC (SA, Role, RoleBinding) + templates + placeholders
  └─ backstage: RBAC (SA, Role, RoleBinding) + templates + placeholders
      ↓ ArgoCD espera que todos completen

Wave -1 (espera hasta completar)
  ├─ backstage-secretstore
  ├─ dex-externalsecret
  ├─ backstage-postgres-externalsecret
  ├─ backstage-app-externalsecret
  ├─ dex job-renderer
  ├─ backstage job-renderer
  └─ catalog-users
      ↓ ArgoCD espera que todos completen (incluyendo jobs!)

Wave 1 (espera hasta completar)
  ├─ limitrange
  ├─ resourcequota
  └─ PostgreSQL pods
      ↓ ArgoCD espera que todos completen

Wave 0 (default)
  ├─ Backstage Helm release
  └─ Dex Helm release
```

## Problemas Identificados

### 1. PostgreSQL Bloqueado Innecesariamente (CRÍTICO)

**Problema:** PostgreSQL está en wave 1, esperando a que se completen TODOS los recursos de wave -1, incluyendo los jobs de renderizado de configuración.

**Realidad:** PostgreSQL solo necesita:
- El namespace (wave -2) ✓
- Su ExternalSecret `backstage-postgres-externalsecret` (wave -1) ✓

**NO necesita:**
- ❌ El job-renderer ni el ConfigMap que genera
- ❌ Los ExternalSecrets de Backstage app o Dex
- ❌ El catalog-users

**Impacto:** PostgreSQL espera ~30-60 segundos adicionales innecesariamente mientras los jobs se ejecutan.

### 2. SecretStore Secuenciado Incorrectamente

**Problema:** El SecretStore está en wave -1 junto con recursos que dependen de él.

**Realidad:** El SecretStore solo necesita:
- El namespace (wave -2) ✓

**Debería estar en:** Wave 0 o incluso wave -1 está OK si los ExternalSecrets están en wave 0.

### 3. LimitRange/ResourceQuota Aplicados Demasiado Tarde

**Problema:** Los governance controls (LimitRange, ResourceQuota) están en wave 1, después de que PostgreSQL ya se desplegó.

**Impacto:** PostgreSQL se despliega SIN limitaciones, luego se aplican los límites. Esto puede causar:
- Estado inconsistente temporalmente
- Potencial para que PostgreSQL consuma más recursos de lo permitido inicialmente

**Debería estar en:** Wave -1 o 0, ANTES de desplegar workloads.

### 4. Job Renderers Bloquean el Flujo

**Problema:** Los jobs están en wave -1, bloqueando el avance a wave 1.

**Realidad:** Los ConfigMaps generados por los jobs solo son necesarios para:
- Backstage app (wave 0)
- Dex app (wave 0)

**Solución:** Los jobs pueden ejecutarse en paralelo con PostgreSQL en wave 0.

## Dependencias Reales (Análisis)

```
namespace (wave -2)
  └─ Requerido por: TODO

SecretStore (necesita: namespace)
  └─ Requerido por: ExternalSecrets

ExternalSecrets (necesita: namespace, SecretStore)
  ├─ backstage-postgres-externalsecret → PostgreSQL
  ├─ backstage-app-externalsecret → Backstage app
  └─ dex-externalsecret → Dex app

Job Renderer RBAC (necesita: namespace)
  └─ Requerido por: Job Renderer

Job Renderer (necesita: namespace, RBAC, templates)
  └─ Genera ConfigMap requerido por: Backstage app, Dex app

PostgreSQL (necesita: namespace, backstage-postgres-externalsecret)
  └─ Requerido por: Backstage app

Backstage app (necesita: PostgreSQL, ConfigMap del job-renderer)
  └─ Aplicación final

LimitRange/ResourceQuota (necesita: namespace)
  └─ Deberían aplicarse ANTES de workloads
```

## Propuesta de Optimización

### Nuevo Flujo de Sync Waves

```
Wave -2: Solo pre-requisitos absolutos
  └─ namespace

Wave -1: Governance y configuración base
  ├─ limitrange
  ├─ resourcequota
  └─ backstage-secretstore

Wave 0: Recursos paralelos (NO dependen entre sí)
  ├─ Grupo A: ExternalSecrets (pueden crearse en paralelo)
  │   ├─ backstage-postgres-externalsecret
  │   ├─ backstage-app-externalsecret
  │   └─ dex-externalsecret
  │
  ├─ Grupo B: Job Renderer (puede ejecutarse en paralelo)
  │   ├─ RBAC (SA, Role, RoleBinding)
  │   ├─ Templates (cm-tpl, vars-placeholder, etc.)
  │   └─ Job
  │
  ├─ Grupo C: PostgreSQL (solo espera ExternalSecret, no espera Job)
  │   └─ PostgreSQL pods
  │
  └─ catalog-users

Wave 1: Aplicaciones finales (esperan PostgreSQL + ConfigMaps)
  ├─ Backstage app (necesita: PostgreSQL + ConfigMap del job)
  └─ Dex app (necesita: ConfigMap del job)
```

### Cambios Específicos por Archivo

#### Archivos a Modificar:

1. **`K8s/backstage/infrastructure/backstage-secretstore.yaml`**
   ```yaml
   # Cambiar de wave -1 a wave -1 (OK como está)
   # O puede ir a wave 0 si ExternalSecrets también van a wave 0
   ```

2. **`K8s/backstage/governance/limitrange.yaml`**
   ```yaml
   annotations:
     argocd.argoproj.io/sync-wave: "-1"  # Cambiar de "1" a "-1"
   ```

3. **`K8s/backstage/governance/resourcequota.yaml`**
   ```yaml
   annotations:
     argocd.argoproj.io/sync-wave: "-1"  # Cambiar de "1" a "-1"
   ```

4. **`K8s/backstage/backstage/values.yaml`** (línea ~136)
   ```yaml
   podAnnotations:
     argocd.argoproj.io/sync-wave: "0"  # Cambiar de "1" a "0"
   ```

5. **`K8s/backstage/backstage/job-renderer.yaml`**
   ```yaml
   # El RBAC (SA, Role, RoleBinding) puede permanecer en wave -2 (OK)
   # O mover a wave -1

   # El Job cambiar de wave -1 a wave 0:
   annotations:
     argocd.argoproj.io/sync-wave: "0"  # Cambiar de "-1" a "0"
   ```

6. **`K8s/backstage/dex/job-renderer.yaml`** (mismo cambio)
   ```yaml
   # El Job cambiar de wave -1 a wave 0:
   annotations:
     argocd.argoproj.io/sync-wave: "0"  # Cambiar de "-1" a "0"
   ```

7. **`K8s/backstage/backstage/catalog-users.yaml`**
   ```yaml
   annotations:
     argocd.argoproj.io/sync-wave: "0"  # Cambiar de "-1" a "0"
   ```

8. **IMPORTANTE: Agregar sync-wave a las apps de Backstage y Dex**

   Necesitamos asegurar que las apps de Helm esperan a que PostgreSQL esté ready.
   Esto puede hacerse mediante un sync-wave en el Helm release o mediante health checks.

### Opción Conservadora (Cambio Mínimo)

Si queremos un cambio menos agresivo, solo modificar:

1. **PostgreSQL de wave 1 → wave 0**
   - Archivos: `K8s/backstage/backstage/values.yaml` (podAnnotations)

2. **LimitRange/ResourceQuota de wave 1 → wave -1**
   - Archivos: `K8s/backstage/governance/*.yaml`

**Mejora esperada:** ~20-30% reducción en tiempo de deploy

### Opción Agresiva (Máxima Optimización)

Aplicar todos los cambios listados arriba.

**Mejora esperada:** ~40-50% reducción en tiempo de deploy

## Aplicar a Otros Componentes

El mismo patrón de optimización se puede aplicar a:

- `K8s/observability/` (mismo patrón)
- `K8s/cicd/` (mismo patrón)
- `K8s/security/` (mismo patrón)
- `K8s/events/` (mismo patrón)

Todos siguen el mismo anti-patrón:
- Wave -2: namespace + templates
- Wave -1: secretstore + externalsecrets + jobs
- Wave 1: limitrange + resourcequota
- Wave 2+: apps

## Verificación Post-Deploy

Después de aplicar cambios, verificar:

```bash
# Ver el orden de sincronización
kubectl get application -n argocd backstage-backstage -o yaml | grep sync-wave

# Ver estado de sincronización
kubectl get application -n argocd -l app.kubernetes.io/part-of=idp

# Verificar que PostgreSQL se despliega antes que Backstage
kubectl get pods -n backstage -w
```

## Riesgos y Mitigaciones

### Riesgo 1: Race Condition en ExternalSecrets

**Escenario:** PostgreSQL inicia antes de que el ExternalSecret esté sincronizado.

**Mitigación:**
- ArgoCD health checks esperan que los ExternalSecrets estén Ready
- Los pods de PostgreSQL tienen `initContainers` o retry logic
- ExternalSecrets tienen `retrySettings` configurados

**Probabilidad:** Baja (ArgoCD maneja esto nativamente)

### Riesgo 2: Job Renderer Falla Silenciosamente

**Escenario:** El job falla pero Backstage se despliega sin el ConfigMap correcto.

**Mitigación:**
- El Helm chart de Backstage debe tener un check que el ConfigMap existe
- Agregar `failurePolicy` al job
- Configurar alertas en ArgoCD para job failures

**Probabilidad:** Media (necesita validación adicional)

### Riesgo 3: Limitaciones No Aplicadas a Tiempo

**Escenario:** PostgreSQL consume recursos antes de que se apliquen LimitRange/ResourceQuota.

**Mitigación:**
- Mover LimitRange/ResourceQuota a wave -1 (propuesta incluida)
- Configurar resource requests/limits en los Helm values

**Probabilidad:** Baja después de la optimización

## Plan de Implementación

### Fase 1: Testing en Local/Dev

1. Aplicar cambios en una rama de desarrollo
2. Probar deploy completo desde cero:
   ```bash
   # Eliminar todo
   kubectl delete namespace backstage
   kubectl delete application -n argocd -l app.kubernetes.io/part-of=backstage

   # Redeploy con nuevos sync waves
   kubectl apply -f K8s/backstage/applicationset-backstage.yaml
   ```
3. Medir tiempos:
   - Tiempo total de deploy
   - Tiempo por wave
   - Errores o warnings

### Fase 2: Validación

1. Verificar que todos los recursos se crean correctamente
2. Verificar que Backstage funciona (login, catálogo, etc.)
3. Verificar que Dex funciona (OIDC)
4. Verificar logs en ArgoCD

### Fase 3: Rollout a Otros Componentes

Aplicar el mismo patrón a:
1. observability (menor riesgo)
2. cicd (riesgo medio)
3. events (menor riesgo)
4. security (menor riesgo)

## Métricas de Éxito

Antes de la optimización (baseline):
```
Total deploy time: ~8-12 minutos
Wave -2: ~30-60s
Wave -1: ~2-4 min (jobs + ExternalSecrets)
Wave 1: ~3-5 min (PostgreSQL)
Wave 0: ~3-5 min (Backstage app)
```

Después de la optimización (esperado):
```
Total deploy time: ~5-7 minutos (-40-50%)
Wave -2: ~30-60s (sin cambio)
Wave -1: ~30-60s (sin jobs)
Wave 0: ~2-3 min (PostgreSQL + jobs en paralelo)
Wave 1: ~2-3 min (Backstage app)
```

## Referencias

- [ArgoCD Sync Waves Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [ArgoCD Resource Hooks](https://argo-cd.readthedocs.io/en/stable/user-guide/resource_hooks/)
- Archivos de configuración:
  - `K8s/backstage/applicationset-backstage.yaml`
  - `K8s/backstage/*/job-renderer.yaml`
  - `K8s/backstage/governance/*.yaml`
  - `K8s/backstage/backstage/values.yaml`
