# Análisis: Dashboard de Métricas para Backstage - "Kubernetes - Deployment Overview"

## Dashboard Analizado

**Nombre:** "Kubernetes - Deployment Overview"  
**UID:** `ORYiYUzmk`  
**Tags:** kubernetes, deployment  
**Paneles:** 12 paneles  

## Variables del Dashboard

### 1. Namespace (Primario)
- **Tipo:** Query (Prometheus)
- **Query:** `label_values(kube_deployment_metadata_generation, namespace)`
- **Label:** "Namespace"
- **Multi-select:** No
- **IncludeAll:** No
- **Datasource:** Prometheus

### 2. Deployment (Secundario, cascadeado)
- **Tipo:** Query (Prometheus)
- **Query:** `label_values(kube_deployment_metadata_generation{namespace="$namespace"}, deployment)`
- **Label:** "Deployment"
- **Multi-select:** No
- **IncludeAll:** No
- **Datasource:** Prometheus
- **Dependencia:** Filtrado por `$namespace`

## Estructura de Variables (Cascada)

```
namespace (primario) → deployment (dependiente)
```

Similar al dashboard de logs que elegimos ("Container Log Dashboard"):
```
namespace (primario) → pod (dependiente)
```

## Paneles y Métricas

### Stats (7 paneles)
1. **Desired Replicas** - `kube_deployment_spec_replicas`
2. **Available Replicas** - `kube_deployment_status_replicas_available`
3. **Observed Generation** - `kube_deployment_status_observed_generation`
4. **Metadata Generation** - `kube_deployment_metadata_generation`
5. **Deployment Create Time** - `time() - kube_deployment_created`
6. **AVG CPU** - `rate(container_cpu_usage_seconds_total)`
7. **AVG Memory** - `container_memory_working_set_bytes`
8. **AVG Network** - `rate(container_network_transmit_bytes_total) + rate(container_network_receive_bytes_total)`

### Time Series (5 paneles)
1. **CPU Usage** - Por pod: `sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="$namespace",pod=~"$deployment-.*"}[2m]))`
2. **Memory Usage** - Por pod: `sum by (pod) (container_memory_working_set_bytes{namespace="$namespace",pod=~"$deployment-.*"})`
3. **Replica Status** - Available, Unavailable, Updated replicas
4. **Spec** - Desired replicas, Paused status

## Alineación con el Catalog de Backstage

### Metadata Disponible en Componentes

**Todos los componentes tienen:**
- `backstage.io/kubernetes-namespace` ✅
- `backstage.io/kubernetes-id` ✅
- `kyverno.io/kind` ✅ (Deployment, StatefulSet, DaemonSet, Gateway)

### Distribución por Tipo de Workload

**Deployments (mayoría):** ~30 componentes
- backstage, grafana, argocd-server, argocd-repo-server, kyverno, etc.

**StatefulSets:** ~5 componentes
- sonarqube, vault, eventbus, argocd-application-controller

**DaemonSets:** ~3 componentes
- node-exporter, cilium-agent, fluent-bit

**Otros:** 
- idp-gateway (Gateway)
- cilium (sin kind específico)

### Problema Identificado: Dashboard Solo Soporta Deployments

**Variables del Dashboard:**
```promql
label_values(kube_deployment_metadata_generation, namespace)
label_values(kube_deployment_metadata_generation{namespace="$namespace"}, deployment)
```

**Queries de Paneles:**
```promql
kube_deployment_spec_replicas{deployment="$deployment",namespace="$namespace"}
kube_deployment_status_replicas_available{deployment="$deployment",namespace="$namespace"}
```

**Todas las métricas usan:**
- `kube_deployment_*` (solo para Deployments)
- `pod=~"$deployment-.*"` (asume naming: deployment-*)

**Consecuencia:**
- ❌ NO funciona para StatefulSets (vault, sonarqube, eventbus, argocd-application-controller)
- ❌ NO funciona para DaemonSets (node-exporter, cilium-agent, fluent-bit)
- ❌ NO funciona para otros tipos (Gateway)
- ✅ Solo funciona para ~30 componentes tipo Deployment

## Problemas Adicionales

### 1. Naming Convention en Queries
```promql
pod=~"$deployment-.*"
```

Asume que los pods se llaman `deployment-name-*`, pero:
- ⚠️ `grafana` → pods: `prometheus-grafana-*` (NO funciona)
- ⚠️ `kube-state-metrics` → pods: `prometheus-kube-state-metrics-*` (NO funciona)
- ✅ `backstage` → pods: `backstage-*` (funciona)

Mismo problema que teníamos con logs.

### 2. Variable "deployment" No Es Genérica

El dashboard espera una variable llamada `$deployment`, pero:
- Para StatefulSets debería ser `$statefulset`
- Para DaemonSets debería ser `$daemonset`
- No es genérico para todos los workload types

## Comparación con Metadata del Catalog

| Metadata Catalog | Variable Dashboard | Match | Observaciones |
|------------------|-------------------|-------|---------------|
| `backstage.io/kubernetes-namespace` | `$namespace` | ✅ Exacto | Funciona para todos |
| `backstage.io/kubernetes-id` | `$deployment` | ⚠️ Aproximado | Solo si es Deployment |
| `kyverno.io/kind` | N/A | ❌ No usado | Dashboard no considera tipo de workload |

## Evaluación de Adecuación

### ✅ Aspectos Positivos

1. **Estructura de variables compatible:**
   - namespace → deployment (similar a namespace → pod en logs)
   - Cascada de dependencias funciona bien
   
2. **Visualizaciones completas:**
   - 12 paneles con métricas relevantes
   - Stats + Time Series
   - CPU, Memory, Network, Replicas
   
3. **Metadata disponible:**
   - namespace y kubernetes-id ya existen en todos los componentes

### ❌ Aspectos Negativos (CRÍTICOS)

1. **Solo soporta Deployments:**
   - Excluye ~10 componentes (StatefulSets, DaemonSets, Gateway)
   - Representa ~25% de los componentes
   
2. **Naming conventions:**
   - Mismo problema que logs: asume `deployment-*`
   - Fallaría para grafana, kube-state-metrics, etc.
   
3. **No es workload-agnostic:**
   - Queries hardcoded a `kube_deployment_*`
   - Necesitaría queries diferentes para cada tipo

## Alternativas de Dashboards

### Opción 1: Buscar Dashboard Workload-Agnostic

Características deseadas:
- Soporta Deployment, StatefulSet, DaemonSet
- Variables: namespace + workload name (genérico)
- Queries adaptables al tipo de workload

### Opción 2: Dashboard por Namespace

En vez de filtrar por deployment específico, filtrar por namespace:
- Muestra métricas agregadas del namespace completo
- Funciona para todos los componentes
- Menos granular pero más universal

### Opción 3: Múltiples Dashboards según Tipo

Mapeo condicional basado en `kyverno.io/kind`:
- Si kind=Deployment → Dashboard A
- Si kind=StatefulSet → Dashboard B
- Si kind=DaemonSet → Dashboard C

Más complejo pero más preciso.

## Búsqueda de Dashboards Alternativos

Voy a revisar qué otros dashboards de Kubernetes están disponibles en Grafana.

### Dashboards Candidatos a Revisar

1. **"Kubernetes / Compute Resources / Namespace (Pods)"**
   - Métricas por namespace y pod
   - Puede ser más genérico
   
2. **"Kubernetes / Compute Resources / Workload"**
   - Si existe, sería ideal (workload-agnostic)
   
3. **"Kubernetes / Compute Resources / Pod"**
   - Métricas por pod individual
   - Muy granular

## Recomendación Preliminar

### ⚠️ "Kubernetes - Deployment Overview" NO ES ADECUADO para integración universal con el Catalog

**Razones:**
1. Solo funciona para ~75% de componentes (Deployments)
2. Excluye StatefulSets, DaemonSets, Gateway
3. Naming conventions problemáticas
4. No adaptable a diferentes workload types

### 🎯 Acción Recomendada

**Buscar dashboard alternativo que:**
1. Funcione con namespace + pod/workload name (genérico)
2. No asuma tipo específico de workload
3. Use queries adaptables o múltiples queries
4. Cubra CPU, Memory, Network para cualquier pod

### 🔍 Dashboards a Investigar

¿Quieres que busque y analice estos dashboards?
1. "Kubernetes / Compute Resources / Namespace (Pods)"
2. "Kubernetes / Compute Resources / Pod"
3. Otros dashboards de Kubernetes disponibles

O ¿prefieres implementar el tab con "Kubernetes - Deployment Overview" solo para componentes tipo Deployment y manejar los otros tipos por separado?

## Implementación Condicional (Si Usamos Este Dashboard)

Si decidimos usar este dashboard a pesar de sus limitaciones:

```typescript
const EntityPrometheusMetrics = () => {
  const { entity } = useEntity();
  const config = useApi(configApiRef);
  
  const grafanaUrl = config.getOptionalString('grafana.domain');
  const annotations = entity.metadata.annotations || {};
  const namespace = annotations['backstage.io/kubernetes-namespace'] || 'default';
  const workloadKind = annotations['kyverno.io/kind'];
  
  // Solo mostrar para Deployments
  if (workloadKind !== 'Deployment') {
    return (
      <WarningPanel
        title="Metrics Not Available"
        message={`Metrics dashboard only supports Deployments. This component is a ${workloadKind}.`}
      />
    );
  }
  
  const deployment = annotations['backstage.io/kubernetes-id'] || entity.metadata.name;
  
  const dashboardPath = '/d/ORYiYUzmk/kubernetes-deployment-overview';
  const queryParams = `?var-namespace=${namespace}&var-deployment=${deployment}&kiosk`;
  const src = `${grafanaUrl}${dashboardPath}${queryParams}`;

  return (
    <iframe
      title="Deployment Metrics"
      src={src}
      className={classes.iframe}
    />
  );
};
```

**Problema:** Solo ~75% de componentes verían métricas.

## Conclusión

**"Kubernetes - Deployment Overview" NO ES ADECUADO** como dashboard universal para métricas en Backstage porque:
- Solo soporta Deployments (excluye 25% de componentes)
- Tiene problemas de naming conventions
- No es workload-agnostic

**Acción siguiente:** Buscar dashboard alternativo más genérico o implementar solución condicional por tipo de workload.
