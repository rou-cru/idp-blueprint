# Estado de Integración Backstage-Grafana (Logs) - 2025-12-24

## Tareas Completadas

### 1. Frontend (Código Fuente)
- **Plugin Instalado:** `@backstage-community/plugin-grafana` añadido a `UI/packages/app/package.json`.
- **Interfaz Modificada:** `UI/packages/app/src/components/catalog/EntityPage.tsx` ahora incluye una pestaña "Logs" que renderiza el componente `EntityGrafanaDashboardsCard`.
- **Proxy Configurado:** `UI/app-config.yaml` contiene la ruta `/grafana/api` apuntando a `http://grafana.observability.svc.cluster.local:80/` con inyección de `Authorization: Bearer ${GRAFANA_TOKEN}`.

### 2. Catálogo (Metadatos)
- **Anotaciones de Prueba:** Se añadieron las anotaciones al componente `backstage` en `Catalog/components/backstage.yaml`:
  - `grafana/dashboard-selector: uid=NClZGd6nA` (Loki Logs Dashboard)
  - `grafana/tag: logs`

### 3. Infraestructura (Helm/K8s)
- **Configuración de Grafana:** Se habilitó `allow_embedding: true` en `K8s/observability/kube-prometheus-stack/values.yaml` para permitir que los dashboards se muestren en iFrames dentro de Backstage.

## Tareas Pendientes

### 1. Build & Deploy
- Generar una nueva imagen de Docker para Backstage que incluya el nuevo plugin y los cambios de código.
- Pushear la imagen al registro (`roucru/idp-blueprint-dev-portal:latest`).

### 2. Secretos y Variables de Entorno
- Verificar que el Secret `backstage-app-secrets` en el namespace `backstage` tenga la clave `GRAFANA_TOKEN`.
- El token debe tener rol de `Viewer` en Grafana.

### 3. Verificación de Filtrado
- Validar si el plugin mapea automáticamente las variables del dashboard (`namespace`, `container`) con los metadatos de la entidad de Backstage.
- **Riesgo Identificado:** Si el filtrado automático falla, se deberá reemplazar el componente del plugin por un `IFrame` personalizado en `EntityPage.tsx` que construya la URL con los parámetros `?var-namespace=${namespace}&var-container=${name}`.

### 4. Sincronización
- Sincronizar la aplicación `observability` en ArgoCD para aplicar el cambio de `allow_embedding`.
- Sincronizar la aplicación `backstage` para desplegar la nueva imagen.
