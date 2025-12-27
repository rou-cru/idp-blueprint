# Comparación de Dashboards de Loki para Integración con Catalog

## Objetivo
Determinar cuál dashboard de logs es más adecuado para integración con el Software Catalog de Backstage, considerando capacidades de filtrado y alineación con la segmentación del Catalog.

## Dashboards Analizados

### Dashboard 1: "Container Log Dashboard" (UID: fRIvzUZMz)
**Ya analizado previamente**

**Variables:**
- `$namespace` (query, single select, no includeAll)
- `$pod` (query, single select, includeAll)
- `$stream` (query, single select, includeAll)
- `$searchable_pattern` (textbox)

**Query base:**
```logql
{namespace="$namespace", pod=~"$pod", stream=~"$stream"} |~ "(?i)$searchable_pattern"
```

**Paneles:** 9 paneles
- Stats: Total count, pattern count
- Live logs (tail -f style)
- Visualizaciones: Pie charts, gauge, graphs históricos
- Análisis: stderr/stdout distribution, pattern rate per pod

**Características:**
- ✅ Filtrado por namespace (obligatorio)
- ✅ Filtrado por pod (opcional, regex)
- ✅ Filtrado por stream (opcional)
- ✅ Búsqueda de texto
- ✅ Visualizaciones analíticas ricas
- ❌ NO filtra por container name

---

### Dashboard 2: "Kubernetes Logs from Loki" (UID: ae3ec2c4-1c19-4450-9403-226270fe0c4f)

**Descripción:** "Basic dashboard for Kubernetes Logs from Loki. You will need to make your own customizations."

**Variables:**
- `$namespace` (query, single select, includeAll, allValue=".+")
- `$pod` (query, single select, includeAll, allValue=".+")
- `$search` (custom dropdown con valores predefinidos)
  - Valores: "error|fatal", "warn|error|fatal", "fatal", "error", "warn", "info", ".+"

**Query base:**
```logql
{namespace=~"$namespace", pod=~"$pod"} |~ "$search"
```

**Paneles:** 2 paneles (MINIMALISTA)
- Timeseries: count_over_time
- Logs Panel: Vista de logs

**Características:**
- ✅ Filtrado por namespace (opcional, includeAll)
- ✅ Filtrado por pod (opcional, includeAll)
- ✅ Búsqueda predefinida (niveles de severidad)
- ❌ NO filtra por container
- ❌ NO filtra por stream
- ⚠️  Muy básico, diseñado para customización
- ❌ Sin visualizaciones analíticas

**Ventajas:**
- Simple y minimalista
- Permite "All" en namespace y pod (más flexible)
- Búsqueda orientada a severidad (error, warn, info)

**Desventajas:**
- Muy básico, pocos paneles
- Requiere customización
- No tiene análisis avanzado

---

### Dashboard 3: "Logging Dashboard via Loki v2" (UID: fRIvzUZMy)

**Descripción:** "Universal and flexible dashboard for logging. All credits to jor1 for creating the original dashboard (ID: 12611)"

**Variables:**
- `$container` (query, single select, NO includeAll) ⭐ **FILTRO PRIMARIO**
  - Query: `label_values({container=~".+"}, container)`
  - Label: "Service"
- `$pod` (query, single select, includeAll)
  - Query: `label_values({container="$container"}, pod)`
  - Regex filter: `$container.*`
  - **Dependiente de:** container
- `$stream` (query, single select, includeAll)
  - Query: `label_values({container="$container"}, stream)`
  - **Dependiente de:** container
- `$searchable_pattern` (textbox)

**Query base:**
```logql
{container="$container", pod=~"$pod", stream=~"$stream"} |~ "(?i)$searchable_pattern"
```

**Paneles:** 10 paneles (COMPLETO)
- Stats: Total count, pattern count
- Live logs (tail -f style)
- Text panel (información)
- Visualizaciones: 2 Pie charts (stderr/stdout, matched pods), gauge, 3 graphs históricos

**Características:**
- ⭐ **Filtrado por CONTAINER (obligatorio, primario)**
- ✅ Filtrado por pod (opcional, dependiente de container)
- ✅ Filtrado por stream (opcional, dependiente de container)
- ✅ Búsqueda de texto (case insensitive)
- ✅ Visualizaciones analíticas completas
- ❌ NO filtra directamente por namespace
- ⚠️  Variable "Service" apunta a label `container` (naming confuso)

**Ventajas:**
- ⭐ **USA CONTAINER COMO FILTRO PRIMARIO** → Mapeo directo con `grafana/container-name`
- Cascada de dependencias: container → pod → stream
- Visualizaciones muy completas
- Diseño universal y flexible

**Desventajas:**
- No expone namespace como variable (implícito en el container)
- Requiere que el label `container` sea único/identificable

---

### Dashboard 4: "Loki Kubernetes Logs" (UID: o6-BGgnnk)

**Descripción:** "Logs collected from Kubernetes, stored in Loki"

**Variables:**
- `$query` (textbox, label: "Search Query")
- `$namespace` (query, multi-select, includeAll, allValue=".+")
  - Query: `label_values(namespace)`
- `$stream` (query, multi-select, includeAll, allValue=".+")
  - Query: `label_values(stream)`
- `$container` (query, multi-select, includeAll, allValue=".+")
  - Query: `label_values(container)`

**Query base:**
```logql
{namespace=~"$namespace", stream=~"$stream", container=~"$container"} |= "$query"
```

**Paneles:** 2 paneles (MINIMALISTA)
- Timeseries: count_over_time
- Logs Panel: Logs from services running in Kubernetes

**Características:**
- ✅ Filtrado por namespace (opcional, **multi-select**)
- ✅ Filtrado por stream (opcional, **multi-select**)
- ✅ Filtrado por container (opcional, **multi-select**)
- ✅ Búsqueda de texto
- ⚠️  Muy básico, solo 2 paneles
- ⚠️  Variables independientes (sin cascada)
- ❌ Sin visualizaciones analíticas
- ❌ NO filtra por pod

**Ventajas:**
- ⭐ **FILTRA POR CONTAINER**
- Multi-select en todas las variables (muy flexible)
- Permite combinar namespace + container
- Simple y directo

**Desventajas:**
- Demasiado simple, solo 2 paneles
- No tiene análisis avanzado
- Variables no cascadean (puede crear queries vacías)

---

## Comparación de Variables de Filtrado

| Dashboard | Namespace | Pod | Container | Stream | Search | Comentarios |
|-----------|-----------|-----|-----------|--------|--------|-------------|
| **Container Log Dashboard** | ✅ Single (required) | ✅ Single (regex) | ❌ No | ✅ Single | ✅ Textbox | Basado en namespace+pod |
| **Kubernetes Logs from Loki** | ✅ Single (includeAll) | ✅ Single (includeAll) | ❌ No | ❌ No | ✅ Dropdown (severity) | Muy básico |
| **Logging Dashboard v2** | ❌ No | ✅ Single (dependent) | ⭐ **Single (primary)** | ✅ Single (dependent) | ✅ Textbox | **Container-first** |
| **Loki Kubernetes Logs** | ✅ Multi | ❌ No | ✅ Multi | ✅ Multi | ✅ Textbox | Multi-select flexible |

## Comparación de Paneles y Visualizaciones

| Dashboard | Panel Count | Live Logs | Stats | Charts | Graphs | Análisis Avanzado |
|-----------|-------------|-----------|-------|--------|--------|-------------------|
| **Container Log Dashboard** | 9 | ✅ | ✅✅ | ✅✅ (2 pies, 1 gauge) | ✅✅✅ (3 graphs) | ✅ Completo |
| **Kubernetes Logs from Loki** | 2 | ✅ | ❌ | ❌ | ✅ (1 timeseries) | ❌ Básico |
| **Logging Dashboard v2** | 10 | ✅ | ✅✅ | ✅✅✅ (2 pies, 1 gauge) | ✅✅✅ (3 graphs) | ✅ Muy completo |
| **Loki Kubernetes Logs** | 2 | ✅ | ❌ | ❌ | ✅ (1 timeseries) | ❌ Básico |

## Alineación con Segmentación del Catalog

### Estructura del Catalog

**Jerarquía:**
```
Domain → System → Component
```

**Dominios:**
- `infrastructure`
- `observability`
- `security`

**Sistemas:**
- `idp-core` (domain: infrastructure)
- `idp-orchestration` (domain: infrastructure)
- `idp-observability` (domain: observability)
- `idp-security` (domain: security)
- `idp-quality` (domain: infrastructure)
- `idp-networking` (domain: infrastructure)

**Componentes (40+):**
- Cada componente pertenece a un System
- Algunos componentes son sub-componentes de otros (ej: `grafana` → subComponentOf `kube-prometheus-stack`)
- Metadata clave en cada componente:
  - `backstage.io/kubernetes-namespace`
  - `backstage.io/kubernetes-id`
  - `backstage.io/kubernetes-label-selector`
  - `grafana/container-name` (solo 2 componentes actualmente)

### Namespaces vs Componentes

**Distribución de componentes por namespace:**

| Namespace | # Componentes | Componentes |
|-----------|---------------|-------------|
| `observability` | 8 | grafana, loki, kube-prometheus-stack, kube-state-metrics, node-exporter, alertmanager, pyrra, fluent-bit |
| `argocd` | 4 | argocd, argocd-server, argocd-repo-server, argocd-application-controller |
| `kube-system` | 6 | cilium, cilium-agent, cilium-operator, hubble-ui, hubble-relay, idp-gateway |
| `backstage` | 2 | backstage, dex |
| `cicd` | 4 | sonarqube, argo-workflows, workflow-controller, argo-server |
| `argo-events` | 3 | argo-events, argo-events-controller-manager, eventbus |
| `kyverno-system` | 2 | kyverno, policy-reporter |
| `cert-manager` | 1 | cert-manager |
| `external-secrets-system` | 1 | external-secrets |
| `vault-system` | 1 | vault |
| `security` | 1 | trivy-operator |

**Observación crítica:** Múltiples namespaces tienen **varios componentes** → Filtrar solo por namespace NO es suficiente para aislar un componente específico.

### Mapeo: Metadata del Catalog → Labels de Loki

| Catalog Metadata | Label Loki | Tipo Match | Confiabilidad |
|------------------|------------|------------|---------------|
| `backstage.io/kubernetes-namespace` | `namespace` | Exacto | ✅ Alta (siempre presente) |
| `backstage.io/kubernetes-id` | `app` o `pod` (pattern) | Regex | ⚠️  Media (naming inconsistente) |
| `grafana/container-name` | `container` | Exacto | ✅ Alta (cuando existe) |
| `backstage.io/kubernetes-label-selector` | N/A | Via K8s API | ⚠️  Compleja (requiere consulta dinámica) |

## Análisis por Dashboard

### Dashboard 1: "Container Log Dashboard" (namespace-first)

**Estrategia de mapeo:**
```
Catalog entity → Dashboard variables
─────────────────────────────────────
backstage.io/kubernetes-namespace → $namespace
backstage.io/kubernetes-id → $pod (como regex: kubernetes-id-.*)
```

**Pros:**
- ✅ Mapeo directo de namespace
- ✅ Visualizaciones completas
- ✅ Funciona para todos los componentes

**Contras:**
- ❌ Naming inconsistente en pods (ej: `grafana` → `prometheus-grafana-*`)
- ⚠️  En namespaces compartidos, el pod regex puede ser amplio
- ❌ No usa el label `container` (más preciso)

**Adecuación para Catalog:** ⭐⭐⭐ (3/5)
- Funciona, pero requiere manejo de naming conventions

---

### Dashboard 2: "Kubernetes Logs from Loki" (namespace+pod, muy básico)

**Estrategia de mapeo:**
```
Catalog entity → Dashboard variables
─────────────────────────────────────
backstage.io/kubernetes-namespace → $namespace
backstage.io/kubernetes-id → $pod (como regex)
```

**Pros:**
- ✅ includeAll permite flexibilidad
- ✅ Simple y minimalista

**Contras:**
- ❌ Solo 2 paneles, muy básico
- ❌ Mismos problemas de naming que Dashboard 1
- ❌ No aprovecha label `container`
- ❌ Sin análisis avanzado

**Adecuación para Catalog:** ⭐⭐ (2/5)
- Demasiado básico, no aporta valor analítico

---

### Dashboard 3: "Logging Dashboard via Loki v2" (container-first) ⭐⭐⭐⭐⭐

**Estrategia de mapeo:**
```
Catalog entity → Dashboard variables
─────────────────────────────────────
grafana/container-name → $container (PRIMARIO)
(optional) pod pattern → $pod
```

**Pros:**
- ⭐⭐⭐ **MAPEO DIRECTO A CONTAINER** (más preciso que namespace+pod)
- ✅ Visualizaciones MUY completas (10 paneles)
- ✅ Aísla exactamente el contenedor deseado
- ✅ No depende de naming conventions de pods
- ✅ Variables cascadean (container → pod, stream)
- ✅ Funciona en namespaces compartidos sin ambigüedad

**Contras:**
- ⚠️  Requiere agregar `grafana/container-name` a todos los componentes (actualmente solo 2 lo tienen)
- ⚠️  Variable labeled "Service" apunta a `container` (confuso, pero funcional)
- ❌ No expone namespace como variable (implícito en container)

**Adecuación para Catalog:** ⭐⭐⭐⭐⭐ (5/5)
- **ÓPTIMO** si se agrega `grafana/container-name` a todos los componentes
- Alineación perfecta: 1 componente = 1 container name
- Evita problemas de naming y namespaces compartidos

---

### Dashboard 4: "Loki Kubernetes Logs" (multi-select flexible)

**Estrategia de mapeo:**
```
Catalog entity → Dashboard variables
─────────────────────────────────────
backstage.io/kubernetes-namespace → $namespace (multi)
grafana/container-name → $container (multi)
```

**Pros:**
- ⭐ **FILTRA POR CONTAINER**
- ✅ Multi-select permite combinar múltiples componentes
- ✅ Muy flexible (namespace + container)

**Contras:**
- ❌ Solo 2 paneles, muy básico
- ❌ Variables independientes (puede crear queries vacías)
- ❌ No filtra por pod (menos granular)
- ❌ Sin análisis avanzado

**Adecuación para Catalog:** ⭐⭐⭐ (3/5)
- Buena idea (container filter), pero muy básico
- Multi-select útil para vistas agregadas (ej: ver todos los componentes de un System)

---

## Recomendación Final

### 🏆 Dashboard Recomendado: "Logging Dashboard via Loki v2" (UID: fRIvzUZMy)

**Razones:**

1. **⭐ Usa `container` como filtro primario** → Mapeo directo con `grafana/container-name`
   - Aislamiento preciso: 1 componente del Catalog = 1 container en Loki
   - No depende de naming conventions de pods
   - Funciona perfectamente en namespaces compartidos

2. **✅ Visualizaciones completas (10 paneles)**
   - Live logs (tail -f)
   - Stats: Total count, pattern count
   - Análisis: stderr/stdout distribution, pattern matching, rate per pod
   - Muy superior a las opciones básicas (2 paneles)

3. **✅ Alineación con estructura del Catalog**
   - Cada componente del Catalog representa un contenedor (o conjunto de contenedores)
   - El concepto de "Service" (aunque labeled confusamente) mapea naturalmente a "Component"
   - Variables cascadean: container → pod → stream (refinamiento progresivo)

4. **✅ Evita problemas de naming**
   - No asume que `kubernetes-id` == prefijo del pod name
   - Container name es explícito y confiable

5. **✅ Escalable**
   - Funciona hoy con 2 componentes que tienen `grafana/container-name`
   - Fácilmente extensible agregando la anotación a los 38 componentes restantes

### Acción Requerida

**Para implementar esta recomendación:**

1. **Agregar `grafana/container-name` a TODOS los componentes del Catalog**
   - Crear script para detectar contenedor principal de cada componente
   - Actualizar los 38 YAMLs faltantes

2. **Implementar mapeo en Backstage plugin**
   ```typescript
   const containerName = entity.metadata.annotations?.['grafana/container-name'];
   const dashboardUrl = `https://grafana.../d/fRIvzUZMy/logging-dashboard-via-loki-v2?var-container=${containerName}`;
   ```

3. **Fallback para componentes sin anotación**
   - Opción A: Usar "Container Log Dashboard" con namespace+pod pattern
   - Opción B: Mostrar warning: "Logs dashboard not available - missing grafana/container-name annotation"

### Alternativa: Dashboard Secundario

**"Loki Kubernetes Logs" (UID: o6-BGgnnk)** como opción secundaria para:
- **Vistas agregadas:** Ver logs de múltiples componentes de un System/Domain (multi-select)
- **Exploración rápida:** Sin análisis avanzado, solo búsqueda y visualización
- **Casos edge:** Componentes sin `grafana/container-name` (usar namespace filter)

### Comparación Final: Container-first vs Namespace-first

| Aspecto | "Logging Dashboard v2" (container-first) | "Container Log Dashboard" (namespace-first) |
|---------|------------------------------------------|---------------------------------------------|
| **Precisión de aislamiento** | ⭐⭐⭐⭐⭐ Exacto (por container) | ⭐⭐⭐ Aproximado (namespace + pod regex) |
| **Namespaces compartidos** | ✅ Sin problema | ⚠️  Requiere regex preciso |
| **Naming conventions** | ✅ No depende | ❌ Depende (problemas conocidos) |
| **Metadata requerida** | `grafana/container-name` | `backstage.io/kubernetes-namespace` + `kubernetes-id` |
| **Cobertura actual** | ❌ 2/40 componentes | ✅ 40/40 componentes |
| **Visualizaciones** | ⭐⭐⭐⭐⭐ 10 paneles | ⭐⭐⭐⭐ 9 paneles |
| **Complejidad implementación** | ⚠️  Requiere agregar anotaciones | ✅ Funciona hoy |
| **Mantenibilidad largo plazo** | ✅ Alta (metadata explícita) | ⚠️  Media (depende de convenciones) |

## Conclusión

**Dashboard óptimo:** "Logging Dashboard via Loki v2" (container-first)

**Plan de implementación:**
1. **Corto plazo:** Usar "Container Log Dashboard" (namespace-first) para los 40 componentes
2. **Mediano plazo:** Agregar `grafana/container-name` a todos los componentes
3. **Largo plazo:** Migrar a "Logging Dashboard via Loki v2" (container-first) como dashboard principal

**Valor agregado:**
- ⭐ Aislamiento preciso por componente
- ⭐ Análisis completo de logs (10 paneles con métricas)
- ⭐ No depende de naming conventions frágiles
- ⭐ Escalable y mantenible

**Próximo paso:** ¿Crear script para agregar `grafana/container-name` a todos los componentes del Catalog?
