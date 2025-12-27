# Plan de Migración: Cambio de Dashboard de Logs en Backstage UI

## Situación Actual

### Dashboard Actual en Uso
**Archivo:** `UI/packages/app/src/components/catalog/EntityPage.tsx`  
**Componente:** `EntityLokiLogs` (líneas 94-133)  
**Dashboard:** "Loki Kubernetes Logs" (UID: `o6-BGgnnk`)

### Implementación Actual

```typescript
const EntityLokiLogs = () => {
  const classes = useStyles();
  const { entity } = useEntity();
  const config = useApi(configApiRef);
  
  const grafanaUrl = config.getOptionalString('grafana.domain');
  
  if (!grafanaUrl) {
    return (
      <WarningPanel
        title="Integration Disabled"
        message='The "grafana.domain" configuration is missing...'
      />
    );
  }
  
  const annotations = entity.metadata.annotations || {};
  const namespace = annotations['backstage.io/kubernetes-namespace'] || entity.metadata.namespace || 'default';
  
  // Resolve container name:
  // 1. Explicit Grafana log container name (matches Loki label exactly)
  // 2. Kubernetes ID (often matches, but not always e.g. backstage vs backstage-backend)
  // 3. Entity name (fallback)
  const container = annotations['grafana/container-name'] || 
                    annotations['backstage.io/kubernetes-id'] || 
                    entity.metadata.name;
  
  // Dashboard UID: o6-BGgnnk (Loki Kubernetes Logs)
  const dashboardPath = '/d/o6-BGgnnk/loki-kubernetes-logs';
  const queryParams = `?var-namespace=${namespace}&var-container=${container}&kiosk`;
  const src = `${grafanaUrl}${dashboardPath}${queryParams}`;

  return (
    <iframe
      title="Loki Logs"
      src={src}
      className={classes.iframe}
    />
  );
};
```

### Variables Pasadas al Dashboard Actual
- `var-namespace`: Namespace del componente
- `var-container`: Container name (con fallback)
- `kiosk`: Modo kiosk de Grafana

### Problema con Dashboard Actual (o6-BGgnnk)
**Dashboard:** "Loki Kubernetes Logs"

**Variables que acepta:**
- `$query` (textbox)
- `$namespace` (multi-select)
- `$stream` (multi-select)
- `$container` (multi-select)

**Características:**
- ✅ Acepta namespace y container (bien)
- ❌ Solo 2 paneles (muy básico)
- ❌ No tiene análisis avanzado
- ⚠️ Multi-select puede ser confuso para vista de un solo componente

---

## Dashboard Objetivo (Recomendado)

### "Container Log Dashboard" (UID: fRIvzUZMz)

**Variables que acepta:**
- `$namespace` (single select, requerido)
- `$pod` (single select con regex, includeAll)
- `$stream` (single select, includeAll)
- `$searchable_pattern` (textbox)

**Características:**
- ✅ 9 paneles con análisis completo
- ✅ Usa namespace como filtro primario (aislamiento garantizado)
- ✅ Visualizaciones: stats, live logs, pie charts, gauges, graphs
- ⚠️ Usa `pod` en vez de `container` como variable secundaria

---

## Cambios Necesarios

### 1. Cambiar Dashboard UID y Path

**Actual:**
```typescript
const dashboardPath = '/d/o6-BGgnnk/loki-kubernetes-logs';
```

**Nuevo:**
```typescript
const dashboardPath = '/d/fRIvzUZMz/container-log-dashboard';
```

### 2. Cambiar Variables del Query String

**Actual:**
```typescript
const queryParams = `?var-namespace=${namespace}&var-container=${container}&kiosk`;
```

**Nuevo (Opción A - Simple):**
```typescript
const queryParams = `?var-namespace=${namespace}&var-pod=All&var-stream=All&var-searchable_pattern=&kiosk`;
```
- Muestra TODOS los pods del namespace
- Usuario debe filtrar manualmente si quiere un pod específico

**Nuevo (Opción B - Con Pod Pattern):**
```typescript
// Resolve pod pattern:
// 1. Explicit pod pattern annotation (for naming exceptions)
// 2. Kubernetes ID + wildcard (standard convention)
const podPattern = annotations['grafana/pod-pattern'] || 
                  `${annotations['backstage.io/kubernetes-id'] || entity.metadata.name}-.*`;

const queryParams = `?var-namespace=${namespace}&var-pod=${encodeURIComponent(podPattern)}&var-stream=All&var-searchable_pattern=&kiosk`;
```
- Intenta filtrar por pod específico usando pattern
- Requiere agregar `grafana/pod-pattern` para excepciones

**Nuevo (Opción C - Híbrido con Fallback):**
```typescript
// Try to resolve a specific pod pattern, but fallback to "All" if uncertain
const kubernetesId = annotations['backstage.io/kubernetes-id'];
const podPattern = annotations['grafana/pod-pattern'] || 
                  (kubernetesId ? `${kubernetesId}-.*` : 'All');

const queryParams = `?var-namespace=${namespace}&var-pod=${encodeURIComponent(podPattern)}&var-stream=All&var-searchable_pattern=&kiosk`;
```
- Usa pattern si tiene kubernetes-id
- Fallback a "All" si no

### 3. Actualizar Comentarios

**Actual:**
```typescript
// Dashboard UID: o6-BGgnnk (Loki Kubernetes Logs)
```

**Nuevo:**
```typescript
// Dashboard UID: fRIvzUZMz (Container Log Dashboard)
```

### 4. (Opcional) Actualizar Título del Iframe

**Actual:**
```typescript
<iframe
  title="Loki Logs"
  src={src}
  className={classes.iframe}
/>
```

**Nuevo (opcional):**
```typescript
<iframe
  title="Container Logs"
  src={src}
  className={classes.iframe}
/>
```

---

## Implementación Recomendada (Código Completo)

### Opción Recomendada: Híbrida con Fallback

```typescript
const EntityLokiLogs = () => {
  const classes = useStyles();
  const { entity } = useEntity();
  const config = useApi(configApiRef);
  
  const grafanaUrl = config.getOptionalString('grafana.domain');
  
  if (!grafanaUrl) {
    return (
      <WarningPanel
        title="Integration Disabled"
        message='The "grafana.domain" configuration is missing in app-config. Please check your K8s/backstage/backstage/templates/cm-tpl.yaml and ensure DNS_SUFFIX is set.'
      />
    );
  }
  
  const annotations = entity.metadata.annotations || {};
  const namespace = annotations['backstage.io/kubernetes-namespace'] || entity.metadata.namespace || 'default';
  
  // Resolve pod pattern:
  // 1. Explicit pod pattern annotation (for naming exceptions like "prometheus-grafana-.*")
  // 2. Kubernetes ID + wildcard (standard convention: "grafana-.*")
  // 3. Fallback to "All" (show all pods in namespace)
  const kubernetesId = annotations['backstage.io/kubernetes-id'];
  const podPattern = annotations['grafana/pod-pattern'] || 
                    (kubernetesId ? `${kubernetesId}-.*` : 'All');
  
  // Dashboard UID: fRIvzUZMz (Container Log Dashboard)
  const dashboardPath = '/d/fRIvzUZMz/container-log-dashboard';
  const queryParams = `?var-namespace=${namespace}&var-pod=${encodeURIComponent(podPattern)}&var-stream=All&var-searchable_pattern=&kiosk`;
  const src = `${grafanaUrl}${dashboardPath}${queryParams}`;

  return (
    <iframe
      title="Container Logs"
      src={src}
      className={classes.iframe}
    />
  );
};
```

### Explicación de la Lógica

**Resolución del Pod Pattern:**
```typescript
const podPattern = annotations['grafana/pod-pattern'] ||    // Prioridad 1: Pattern explícito
                  (kubernetesId ? `${kubernetesId}-.*` : 'All');  // Prioridad 2: ID + wildcard, Prioridad 3: All
```

**Casos:**
1. **Componente con `grafana/pod-pattern`** (ej: grafana)
   - Usa: `prometheus-grafana-.*` (explícito)
   
2. **Componente con `backstage.io/kubernetes-id`** (ej: loki)
   - Usa: `loki-.*` (standard convention)
   
3. **Componente sin kubernetes-id** (edge case)
   - Usa: `All` (muestra todos los pods del namespace)

---

## Comparación: Antes vs Después

| Aspecto | Dashboard Actual (o6-BGgnnk) | Dashboard Nuevo (fRIvzUZMz) |
|---------|------------------------------|------------------------------|
| **Nombre** | Loki Kubernetes Logs | Container Log Dashboard |
| **Paneles** | 2 (básico) | 9 (completo) |
| **Filtro primario** | namespace + container (multi) | namespace (single) |
| **Filtro secundario** | - | pod (regex pattern) |
| **Variables usadas** | namespace, container | namespace, pod, stream, search |
| **Análisis avanzado** | ❌ No | ✅ Sí (pie charts, gauges, graphs) |
| **Metadata requerida** | namespace, container-name | namespace, kubernetes-id (+ pod-pattern opcional) |
| **Precisión aislamiento** | ⚠️ Depende de container único | ✅ Namespace + pod pattern |

---

## Validación Post-Cambio

### Casos de Prueba

1. **Backstage (namespace: backstage, kubernetes-id: backstage)**
   - URL generada: `?var-namespace=backstage&var-pod=backstage-.*`
   - Resultado esperado: Logs del pod `backstage-*`
   - ✅ Funciona

2. **Grafana (namespace: observability, kubernetes-id: grafana)**
   - Sin `grafana/pod-pattern`: `?var-namespace=observability&var-pod=grafana-.*`
   - Resultado: ❌ No encuentra pods (real: `prometheus-grafana-*`)
   - Con `grafana/pod-pattern: "prometheus-grafana-.*"`: `?var-namespace=observability&var-pod=prometheus-grafana-.*`
   - Resultado: ✅ Funciona

3. **Loki (namespace: observability, kubernetes-id: loki)**
   - URL generada: `?var-namespace=observability&var-pod=loki-.*`
   - Resultado esperado: Logs del pod `loki-*`
   - ✅ Funciona

4. **Componente sin kubernetes-id (edge case)**
   - URL generada: `?var-namespace=observability&var-pod=All`
   - Resultado: Muestra todos los pods de observability
   - ⚠️ No aísla componente, pero no falla

---

## Metadata Adicional Requerida (Post-Migración)

### Componentes con Naming Exceptions

Identificar componentes donde `kubernetes-id` ≠ prefijo del pod name:

**Candidatos conocidos:**
- `grafana` → pods: `prometheus-grafana-*`
  - Agregar: `grafana/pod-pattern: "prometheus-grafana-.*"`
  
- `kube-state-metrics` → pods: `prometheus-kube-state-metrics-*`
  - Agregar: `grafana/pod-pattern: "prometheus-kube-state-metrics-.*"`
  
- `node-exporter` → pods: `prometheus-prometheus-node-exporter-*`
  - Agregar: `grafana/pod-pattern: "prometheus-prometheus-node-exporter-.*"`

**Acción:** Crear script para detectar estos casos automáticamente.

---

## Ventajas del Cambio

1. **✅ Mejores visualizaciones:** 2 paneles → 9 paneles
2. **✅ Análisis completo:** Live logs + stats + charts + graphs
3. **✅ Aislamiento robusto:** namespace garantiza separación
4. **✅ Menos ambigüedad:** No sufre de container duplicados cross-namespace
5. **✅ Metadata disponible:** kubernetes-id ya existe en 40/40 componentes

---

## Desventajas/Limitaciones del Cambio

1. **⚠️ Naming exceptions:** ~10 componentes necesitarán `grafana/pod-pattern`
2. **⚠️ Pod pattern puede ser amplio:** En namespaces compartidos, pattern puede incluir múltiples pods del mismo componente
3. **⚠️ No usa label container:** Menos preciso que filtrar por container name

---

## Rollback Plan

Si el cambio causa problemas:

**Revertir a dashboard anterior:**
```typescript
const dashboardPath = '/d/o6-BGgnnk/loki-kubernetes-logs';
const queryParams = `?var-namespace=${namespace}&var-container=${container}&kiosk`;
```

**No requiere cambios en metadata del Catalog.**

---

## Próximos Pasos Recomendados

1. **Actualizar código en EntityPage.tsx** (cambio de 3 líneas)
2. **Probar con componentes conocidos** (backstage, loki, grafana)
3. **Identificar componentes con naming exceptions** (script)
4. **Agregar `grafana/pod-pattern` a componentes excepcionales** (~10 componentes)
5. **Validar en todos los namespaces**
6. **Documentar convenciones** en memoria/docs

---

## Resumen Ejecutivo

**Cambio:** `o6-BGgnnk` (Loki Kubernetes Logs) → `fRIvzUZMz` (Container Log Dashboard)

**Razón:** Mejores visualizaciones (2 → 9 paneles), análisis más completo, aislamiento más robusto

**Código a cambiar:** 3 líneas en `EntityPage.tsx`

**Metadata adicional:** `grafana/pod-pattern` para ~10 componentes con naming exceptions

**Impacto:** ✅ Positivo - Mejor UX, más información, sin ambigüedad cross-namespace
