# Estado de Integración Backstage-Grafana (Logs) - Actualizado 2025-12-27

## Tareas Completadas

### 1. Frontend (Código Fuente)
- **Componente Personalizado:** Se ha reemplazado `EntityGrafanaDashboardsCard` por un componente propio `EntityLokiLogs` en `UI/packages/app/src/components/catalog/EntityPage.tsx`.
- **Integración de Iframe:** El nuevo componente renderiza un iframe del dashboard de Grafana en modo "kiosk", permitiendo una experiencia de "Single Pane of Glass".
- **Filtrado Automático:** El componente inyecta dinámicamente los parámetros `var-namespace` y `var-container` en la URL del dashboard.
- **Configuración Dinámica:** La URL de Grafana se obtiene de la clave de configuración `grafana.domain`, la cual es inyectada dinámicamente por la infraestructura de Kubernetes (a través de `app-config.override.yaml`).
- **Resiliencia:** El componente incluye un fallback seguro (devuelve `null`) y un `console.warn` si la configuración de Grafana no está presente, evitando errores fatales.

### 2. Catálogo (Metadatos)
- **Mapeo 1:1 con Loki:** Se ha identificado que el `kubernetes-id` no siempre coincide con la etiqueta `container` en Loki (ej. `backstage` vs `backstage-backend`).
- **Nueva Anotación:** Se ha introducido la anotación `grafana/container-name` para mapear explícitamente el nombre del contenedor esperado por el dashboard.
- **Componentes Actualizados:** 
  - `backstage.yaml`: Añadido `grafana/container-name: backstage-backend`.
  - `argocd-server.yaml`: Añadido `grafana/container-name: server`.

### 3. Infraestructura (Helm/K8s)
- **Configuración de Grafana:** Confirmado que `allow_embedding: true` está habilitado.
- **Dashboard Canónico:** El dashboard utilizado es "Loki Kubernetes Logs" con UID `o6-BGgnnk`.

## Verificación de Diseño
- Se ha validado que el dashboard `o6-BGgnnk` utiliza estrictamente los nombres de variables `namespace` y `container`.
- Se ha validado que los valores en Loki para estos campos corresponden a los nombres técnicos de los contenedores, lo que justifica el uso de la anotación explícita `grafana/container-name`.

## Estado Final
La integración está **completada y validada**. El usuario ahora ve únicamente los logs asociados al elemento del catálogo que está visualizando, filtrados de forma determinista y sin errores de coincidencia.
