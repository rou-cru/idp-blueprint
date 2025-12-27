# Análisis: Mapeo de Entidades del Catalog a Filtros de Logs

## Objetivo
Determinar cómo mapear cada entidad del Catalog de Backstage a su configuración de filtro para logs en el dashboard "Container Log Dashboard" de Grafana, de modo que se aísle solo lo asociado a cada entidad.

## Dashboard: Container Log Dashboard (UID: fRIvzUZMz)

### Filtros Disponibles en el Dashboard
El dashboard utiliza variables de Grafana que se consultan dinámicamente desde Loki:

1. **`$namespace`** (Variable tipo query)
   - Query: `label_values({namespace=~".+"}, namespace)`
   - Label: "Namespace"
   - Multi: false
   - IncludeAll: false

2. **`$pod`** (Variable tipo query)
   - Query: `label_values({namespace="$namespace"}, pod)`
   - Label: "Pod"
   - Multi: false
   - IncludeAll: true
   - Dependiente de: namespace

3. **`$stream`** (Variable tipo query)
   - Query: `label_values({namespace="$namespace"}, stream)`
   - Label: "Stream"
   - Multi: false
   - IncludeAll: true
   - Valores típicos: stdout, stderr

4. **`$searchable_pattern`** (Variable tipo textbox)
   - Label: "Search (case insensitive)"
   - Usado para búsqueda de texto en logs

### Queries de los Paneles
Todos los paneles usan LogQL con la estructura base:
```logql
{namespace="$namespace", pod=~"$pod", stream=~"$stream"} |~ "(?i)$searchable_pattern"
```

## Labels Disponibles en Loki

Labels extraídos del datasource Loki actual:
- **namespace**: Namespace de Kubernetes
- **pod**: Nombre completo del pod (incluyendo hash)
- **stream**: stdout o stderr
- **app**: Nombre de la aplicación (extraído de labels k8s)
- **container**: Nombre del contenedor dentro del pod
- **service_name**: Nombre del servicio

### Valores Reales en Loki

**Namespaces disponibles:**
- `argo-events`
- `argocd`
- `backstage`
- `cert-manager`
- `external-secrets-system`
- `kube-system`
- `kyverno-system`
- `observability`
- `security`
- `vault-system`

**Apps disponibles (label `app`):**
- alertmanager, argocd-application-controller, argocd-applicationset-controller
- argocd-notifications-controller, argocd-repo-server, argocd-server
- backstage, cainjector, cilium, dex, eventbus
- external-secrets-webhook, fluent-bit, grafana
- kube-prometheus-stack-prometheus-operator, kube-state-metrics
- loki, policy-reporter, postgresql, prometheus
- prometheus-node-exporter, pyrra, vault-agent-injector

**Containers disponibles (label `container`):**
- alertmanager, application-controller, applicationset-controller
- backstage-backend, cert-manager-cainjector
- cilium-agent, cilium-envoy, cilium-operator
- config-reloader, controller, coredns, dex
- download-dashboards, external-secrets, fluent-bit
- grafana, grafana-sc-dashboard, grafana-sc-datasources
- init-chown-data, init-config-reloader
- kube-prometheus-stack, kube-state-metrics
- kyverno, kyverno-pre, local-path-provisioner
- loki, loki-sc-rules, main, metrics, metrics-server
- node-exporter, notifications-controller, policy-reporter
- postgresql, prometheus, pyrra, pyrra-kubernetes
- reloader, repo-server, server, sidecar-injector
- wait-for-dex, webhook

## Anotaciones Relevantes en Entidades del Catalog

### Anotaciones Kubernetes Estándar (Presentes en TODAS las entidades)
```yaml
backstage.io/kubernetes-id: <identificador>
backstage.io/kubernetes-namespace: <namespace>
backstage.io/kubernetes-label-selector: "<selector>"
```

### Anotaciones Grafana para Logs (Presentes SOLO en 2 componentes)
```yaml
grafana/container-name: <nombre-contenedor>
```

**Componentes con anotación `grafana/container-name`:**
1. **backstage.yaml**
   - `grafana/container-name: backstage-backend`
   - `backstage.io/kubernetes-namespace: backstage`
   
2. **argocd-server.yaml**
   - `grafana/container-name: server`
   - `backstage.io/kubernetes-namespace: argocd`

### Otras Anotaciones Relevantes
```yaml
grafana/dashboard-selector: uid=NClZGd6nA  # Solo en backstage.yaml
grafana/tag: logs                           # Solo en backstage.yaml
```

## Estrategia de Mapeo: Catalog → Filtros de Logs

### Mapeo Directo Disponible

Cada entidad del Catalog tiene las siguientes propiedades que pueden mapearse a labels de Loki:

| Anotación Catalog | Label Loki | Tipo de Match | Observaciones |
|-------------------|------------|---------------|---------------|
| `backstage.io/kubernetes-namespace` | `namespace` | **Exacto** | ✅ Siempre disponible, mapeo 1:1 confiable |
| `backstage.io/kubernetes-id` | `app` o `pod` | **Patrón** | ⚠️  Requiere regex/pattern matching |
| `backstage.io/kubernetes-label-selector` | N/A | **Indirecto** | Requiere consulta a K8s API |
| `grafana/container-name` | `container` | **Exacto** | ⚠️  Solo 2 componentes lo tienen |

### Estrategias de Filtrado por Entidad

#### Estrategia 1: Filtrado por Namespace (Más Simple, Menos Preciso)
**Aplicable a:** Todas las entidades

**LogQL Query:**
```logql
{namespace="<backstage.io/kubernetes-namespace>"}
```

**Pros:**
- ✅ Funciona para todas las entidades
- ✅ Mapeo directo 1:1
- ✅ No requiere procesamiento adicional

**Contras:**
- ❌ Incluye TODOS los pods del namespace
- ❌ No aísla componentes específicos en namespaces compartidos (ej: observability tiene grafana, loki, prometheus, etc.)

**Ejemplo:**
- Entidad: `backstage`
- Namespace: `backstage`
- Query: `{namespace="backstage"}`
- Resultado: Logs de backstage-backend, postgresql, dex

#### Estrategia 2: Filtrado por Namespace + Pattern Matching en Pod (Más Preciso)
**Aplicable a:** Todas las entidades

**LogQL Query:**
```logql
{namespace="<backstage.io/kubernetes-namespace>", pod=~"<kubernetes-id>-.*"}
```

**Pros:**
- ✅ Aísla pods específicos del componente
- ✅ Funciona en namespaces compartidos
- ✅ Usa metadata estándar del Catalog

**Contras:**
- ⚠️  Asume convención de naming: `<kubernetes-id>-<hash>`
- ⚠️  Puede fallar si el pod tiene nombre diferente al kubernetes-id

**Ejemplo:**
- Entidad: `grafana`
- Namespace: `observability`
- kubernetes-id: `grafana`
- Query: `{namespace="observability", pod=~"prometheus-grafana-.*"}`
- **Problema detectado**: El pod real es `prometheus-grafana-*`, no `grafana-*`

#### Estrategia 3: Filtrado por Namespace + Container Name (Más Exacto, Limitado)
**Aplicable a:** Solo entidades con anotación `grafana/container-name`

**LogQL Query:**
```logql
{namespace="<backstage.io/kubernetes-namespace>", container="<grafana/container-name>"}
```

**Pros:**
- ✅ Aísla exactamente el contenedor correcto
- ✅ No depende del nombre del pod
- ✅ Funciona incluso con múltiples contenedores en el pod

**Contras:**
- ❌ Solo 2 componentes tienen esta anotación
- ❌ Requiere agregar anotación a todos los componentes

**Ejemplo:**
- Entidad: `backstage`
- Namespace: `backstage`
- Container: `backstage-backend`
- Query: `{namespace="backstage", container="backstage-backend"}`

#### Estrategia 4: Filtrado por Label Selector (Más Dinámico, Complejo)
**Aplicable a:** Todas las entidades con `kubernetes-label-selector`

**Proceso:**
1. Leer `backstage.io/kubernetes-label-selector` de la entidad
2. Consultar K8s API para obtener pods que coincidan
3. Extraer nombres de pods
4. Construir query LogQL con lista de pods

**LogQL Query:**
```logql
{namespace="<namespace>", pod=~"<pod1>|<pod2>|<pod3>"}
```

**Pros:**
- ✅ Aísla exactamente los pods correctos
- ✅ Maneja cambios en naming conventions
- ✅ Funciona con cualquier label selector

**Contras:**
- ❌ Requiere integración con K8s API
- ❌ Consulta en tiempo real (latencia)
- ❌ Más complejo de implementar

## Problemas Identificados

### 1. Inconsistencia en Naming Conventions
**Problema:** El `kubernetes-id` no siempre coincide con el nombre del pod.

**Ejemplos:**
- **grafana**: kubernetes-id=`grafana`, pero pod=`prometheus-grafana-*`
- **kube-state-metrics**: kubernetes-id=`kube-state-metrics`, pero pod=`prometheus-kube-state-metrics-*`

**Causa:** Helm charts agregan prefijos (ej: chart name "prometheus" → `prometheus-grafana`)

### 2. Falta de Anotación `grafana/container-name`
**Problema:** Solo 2 de ~40 componentes tienen la anotación `grafana/container-name`.

**Componentes con la anotación:**
- backstage
- argocd-server

**Componentes sin la anotación:** Todos los demás (38+)

### 3. Namespaces Compartidos
**Problema:** Múltiples componentes en el mismo namespace.

**Namespaces compartidos:**
- `observability`: grafana, loki, prometheus, alertmanager, kube-state-metrics, node-exporter, pyrra, fluent-bit
- `argocd`: argocd-server, argocd-repo-server, argocd-application-controller
- `kube-system`: cilium, cilium-operator, cilium-agent, hubble-ui, hubble-relay, idp-gateway
- `cicd`: sonarqube, argo-workflows, workflow-controller, argo-server

## Recomendaciones

### Recomendación 1: Agregar Anotación `grafana/container-name` a Todos los Componentes
**Prioridad:** Alta
**Impacto:** Alto

**Acción:**
Agregar la anotación `grafana/container-name` a TODAS las entidades del Catalog.

**Estrategia de implementación:**
1. Para cada componente, identificar el contenedor principal
2. Agregar anotación:
   ```yaml
   annotations:
     grafana/container-name: <nombre-contenedor-principal>
   ```

**Beneficios:**
- Mapeo exacto y confiable
- No depende de naming conventions
- Soporta pods multi-contenedor

**Ejemplo para grafana.yaml:**
```yaml
annotations:
  grafana/container-name: grafana  # Contenedor principal
```

### Recomendación 2: Crear Anotación `grafana/pod-pattern` para Casos Especiales
**Prioridad:** Media
**Impacto:** Medio

**Acción:**
Para componentes donde el pod name no sigue la convención `<kubernetes-id>-*`, agregar:
```yaml
annotations:
  grafana/pod-pattern: "^prometheus-grafana-.*"
```

**Casos de uso:**
- grafana: `prometheus-grafana-*`
- kube-state-metrics: `prometheus-kube-state-metrics-*`
- Cualquier componente desplegado vía sub-chart

### Recomendación 3: Implementar Lógica de Fallback en Backstage Plugin
**Prioridad:** Alta
**Impacto:** Alto

**Algoritmo de selección:**
```
1. Si existe `grafana/container-name`:
   → Usar: {namespace="X", container="Y"}
   
2. Sino, si existe `grafana/pod-pattern`:
   → Usar: {namespace="X", pod=~"Y"}
   
3. Sino, si existe `backstage.io/kubernetes-label-selector`:
   → Consultar K8s API → Obtener pod names → Usar: {namespace="X", pod=~"pod1|pod2|..."}
   
4. Fallback final:
   → Usar: {namespace="X", pod=~"<kubernetes-id>-.*"}
```

### Recomendación 4: Validar Queries Dinámicamente
**Prioridad:** Media
**Impacto:** Medio

**Acción:**
Antes de mostrar el dashboard, validar que la query retorna logs:

```logql
count_over_time({namespace="X", container="Y"}[5m])
```

Si retorna 0, mostrar warning al usuario.

## Propuesta de Implementación

### Fase 1: Agregar Metadata (Manual/Automatizado)
1. Script para detectar contenedor principal de cada componente
2. Actualizar todos los YAMLs del Catalog con `grafana/container-name`
3. Identificar casos especiales que requieren `grafana/pod-pattern`

### Fase 2: Implementar Plugin de Backstage
1. Leer anotaciones de la entidad
2. Construir LogQL query según algoritmo de fallback
3. Generar deeplink a Grafana con variables pre-configuradas

### Fase 3: Validación y Refinamiento
1. Validar que todas las entidades mapean correctamente
2. Agregar tests para casos edge
3. Documentar convenciones

## Ejemplo de Deeplink Generado

Para la entidad `backstage`:

**Metadata:**
```yaml
metadata:
  name: backstage
  annotations:
    backstage.io/kubernetes-namespace: backstage
    grafana/container-name: backstage-backend
```

**Deeplink a Grafana:**
```
https://grafana.192-168-65-16.nip.io/d/fRIvzUZMz/container-log-dashboard?orgId=1&var-namespace=backstage&var-pod=All&var-stream=All&var-searchable_pattern=
```

**Con filtro adicional por container (via query directa a Explore):**
```
https://grafana.192-168-65-16.nip.io/explore?orgId=1&left={"datasource":"Loki","queries":[{"expr":"{namespace=\"backstage\",container=\"backstage-backend\"}","refId":"A"}],"range":{"from":"now-1h","to":"now"}}
```

## Conclusión

**Mapeo Viable:** ✅ Sí, es posible mapear cada entidad del Catalog a sus logs

**Estrategia Óptima:**
1. **Corto plazo:** Usar filtro por namespace + pod pattern (`kubernetes-id`)
2. **Medio plazo:** Agregar `grafana/container-name` a todos los componentes
3. **Largo plazo:** Integración con K8s API para label selector dinámico

**Próximos Pasos:**
1. Validar la propuesta con el equipo
2. Crear script para agregar anotaciones faltantes
3. Implementar lógica de mapeo en Backstage plugin
4. Documentar convenciones y estándares
