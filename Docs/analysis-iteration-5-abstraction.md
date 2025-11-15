
# Iteración 5: Análisis de Niveles de Abstracción

Esta iteración final organiza los componentes del IDP en "Niveles de Abstracción". Un nivel de abstracción alto oculta una gran complejidad subyacente, ofreciendo una experiencia de usuario más simple. Un nivel bajo proporciona bloques de construcción fundamentales pero requiere más experiencia para su uso directo. Este análisis culmina con la inclusión de **Backstage** como la capa de abstracción definitiva, unificando la experiencia del desarrollador.

## Las Capas de Abstracción del IDP

La arquitectura se puede visualizar como una serie de capas concéntricas, desde el núcleo de la infraestructura hasta el portal del desarrollador.

-   **Capa 0: Infraestructura Núcleo:** La base absoluta. Aquí reside **Cilium** como CNI, proporcionando la red, y el propio orquestador **Kubernetes**. Son los cimientos invisibles para el usuario final.
-   **Capa 1: Servicios de Plataforma:** Servicios transversales que habilitan funciones críticas. Incluye a **Vault**, **Cert-Manager**, **Gateway API**, **Prometheus**, **Loki** y **Fluent-bit**. Son esenciales para que la plataforma sea segura, observable y accesible.
-   **Capa 2: Motores de Automatización y Gobernanza:** Los "cerebros" que actúan sobre la configuración declarativa. Aquí se encuentran **ArgoCD**, **Kyverno**, **External Secrets** y **Argo Workflows**. Traducen la intención (código) en estado (clúster).
-   **Capa 3: Aplicaciones Orientadas al Desarrollador:** Las interfaces de usuario y APIs específicas de un dominio. **Grafana**, **SonarQube**, **Policy Reporter** y la propia UI de **ArgoCD** viven aquí. Son las herramientas que un desarrollador usaría directamente si no existiera un portal unificado.
-   **Capa 4: Portal Unificado de Desarrollador:** La capa de abstracción total. **Backstage** (asumido) se sitúa aquí, proporcionando un "panel único" que consume las APIs de las capas inferiores para ofrecer una experiencia cohesiva y simplificada (catálogo de software, plantillas, visualización de estado de CI/CD, etc.).

## Diagrama de Capas (Diagrama de Cebolla)

Este diagrama visualiza la jerarquía de abstracción, con el núcleo en el centro y las capas de mayor abstracción envolviéndolo.

```mermaid
graph TD
    subgraph "Capa 4: Portal Unificado"
        direction LR
        Backstage
    end
    subgraph "Capa 3: Aplicaciones de Dominio"
        direction LR
        Grafana -- "consume" --> Prometheus & Loki
        PolicyReporter -- "consume" --> Kyverno
        ArgoCD_UI("ArgoCD UI")
        SonarQube
    end
    subgraph "Capa 2: Motores de Automatización"
        direction LR
        ArgoCD -- "despliega" --> Apps
        Kyverno -- "gobierna" --> Recursos
        ArgoWorkflows -- "ejecuta" --> Pipelines
        ExternalSecrets -- "sincroniza" --> Secretos
    end
    subgraph "Capa 1: Servicios de Plataforma"
        direction LR
        Vault & CertManager("Vault / Cert-Manager")
        Prometheus & Loki
        GatewayAPI("Gateway API")
        FluentBit
    end
    subgraph "Capa 0: Infraestructura Núcleo"
        direction LR
        Cilium & Kubernetes
    end

    %% Estilos para simular capas
    style "Capa 4: Portal Unificado" fill:#cce5ff,stroke:#004085,stroke-width:2px
    style "Capa 3: Aplicaciones de Dominio" fill:#d4edda,stroke:#155724,stroke-width:2px
    style "Capa 2: Motores de Automatización" fill:#fff3cd,stroke:#856404,stroke-width:2px
    style "Capa 1: Servicios de Plataforma" fill:#f8d7da,stroke:#721c24,stroke-width:2px
    style "Capa 0: Infraestructura Núcleo" fill:#e2e3e5,stroke:#383d41,stroke-width:2px
```

## Visualización Final: Mapa Arquitectónico

Este gráfico final combina las dos dimensiones más importantes analizadas: **Transversalidad** y **Nivel de Abstracción**. Proporciona una vista panorámica de la arquitectura de la plataforma.

-   **Eje X (Puntuación de Transversalidad):** Mide el impacto de un componente a través de la plataforma.
-   **Eje Y (Nivel de Abstracción):** Posiciona al componente en la jerarquía de capas.

El gráfico revela cómo los componentes más transversales tienden a ser servicios de plataforma de nivel de abstracción bajo/medio, mientras que las herramientas de cara al usuario son menos transversales pero de mayor abstracción.

```json
{
  "title": "Mapa Arquitectónico Final: Transversalidad vs. Abstracción",
  "description": "Vista holística de la arquitectura de la plataforma, combinando el impacto transversal de cada componente con su nivel en la jerarquía de abstracción.",
  "data": {
    "type": "scatter",
    "data": {
      "datasets": [
        {
          "label": "Componentes",
          "data": [
            { "x": 10, "y": 0, "label": "Cilium" },
            { "x": 9, "y": 2, "label": "Kyverno" },
            { "x": 9, "y": 1, "label": "Fluent-bit" },
            { "x": 8, "y": 1, "label": "Vault" },
            { "x": 8, "y": 1, "label": "Cert-Manager" },
            { "x": 7, "y": 1, "label": "Prometheus" },
            { "x": 7, "y": 2, "label": "ArgoCD" },
            { "x": 6, "y": 1, "label": "Gateway API" },
            { "x": 5, "y": 3, "label": "Grafana" },
            { "x": 4, "y": 2, "label": "Argo Workflows" },
            { "x": 2, "y": 3, "label": "SonarQube" },
            { "x": 1, "y": 3, "label": "PostgreSQL" },
            { "x": 3, "y": 4, "label": "Backstage" }
          ],
          "backgroundColor": "rgba(153, 102, 255, 0.6)",
          "pointRadius": 10,
          "pointHoverRadius": 15
        }
      ]
    },
    "options": {
      "scales": {
        "x": {
          "title": { "display": true, "text": "Puntuación de Transversalidad (Impacto)" },
          "min": 0, "max": 11
        },
        "y": {
          "title": { "display": true, "text": "Nivel de Abstracción" },
          "min": -1, "max": 5,
          "ticks": { "stepSize": 1, "callback": "function(value, index, values) { return ['Capa 0', 'Capa 1', 'Capa 2', 'Capa 3', 'Capa 4'][value] || ''; }" }
        }
      },
      "plugins": {
        "tooltip": { "callbacks": { "label": "function(context) { return context.raw.label; }" } }
      }
    }
  }
}
```
