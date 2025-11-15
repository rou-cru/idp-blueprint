
# Iteración 4: Análisis de Transversalidad

La transversalidad mide el grado en que la función o el impacto de un componente se extiende a través de diferentes áreas y capas de la plataforma. Un componente altamente transversal es un "asunto transversal" (cross-cutting concern) que afecta a casi todo el sistema, mientras que un componente de baja transversalidad tiene un rol muy localizado y específico.

## Puntuación de Transversalidad por Componente

Se ha asignado una puntuación de 1 (muy localizado) a 10 (muy transversal) a cada componente principal.

| Componente               | Puntuación | Justificación                                                                                             |
| ------------------------ | :--------: | --------------------------------------------------------------------------------------------------------- |
| **Cilium (CNI)**         |     10     | Proporciona la red para cada pod. Su impacto es absoluto y subyacente a todo.                              |
| **Kyverno**              |     9      | Sus políticas pueden gobernar la creación y actualización de cualquier recurso en cualquier namespace.      |
| **Fluent-bit**           |     9      | Como DaemonSet, se ejecuta en cada nodo y recolecta logs de *todos* los componentes sin excepción.          |
| **Vault**                |     8      | Provee un servicio de secretos centralizado que puede ser consumido por cualquier componente del clúster.   |
| **Cert-Manager**         |     8      | Provee un servicio de PKI centralizado para emitir certificados a cualquier servicio que lo necesite.       |
| **Prometheus**           |     7      | Puede monitorear cualquier componente que exponga un `ServiceMonitor`, dándole un alcance muy amplio.       |
| **ArgoCD**               |     7      | Gestiona el estado deseado de la gran mayoría de las aplicaciones e infraestructura de la plataforma.       |
| **Gateway API**          |     6      | Es el punto de entrada único para el tráfico, por lo que todos los servicios expuestos dependen de él.    |
| **Grafana**              |     5      | Aunque consume datos de múltiples fuentes, su impacto se limita a la capa de visualización. No afecta al |
|                          |            | comportamiento de otros servicios.                                                                        |
| **Argo Workflows**       |     4      | Su función, aunque potente, está mayormente confinada al dominio de la automatización y CI/CD.             |
| **SonarQube**            |     2      | Herramienta muy especializada cuyo impacto se limita a la fase de análisis de código en un pipeline de CI. |
| **PostgreSQL (SonarQube)** |     1      | Dependencia totalmente localizada. Solo sirve a SonarQube.                                               |

## Gráfico de Barras de Transversalidad

Este gráfico de barras ordena los componentes por su puntuación de transversalidad, destacando los pilares de la plataforma.

```json
{
  "title": "Puntuación de Transversalidad por Componente",
  "description": "Clasificación de componentes según qué tan transversal es su impacto en la plataforma.",
  "data": {
    "type": "bar",
    "data": {
      "labels": ["Cilium", "Kyverno", "Fluent-bit", "Vault", "Cert-Manager", "Prometheus", "ArgoCD", "Gateway API", "Grafana", "Argo Workflows", "SonarQube", "PostgreSQL"],
      "datasets": [
        {
          "label": "Puntuación de Transversalidad",
          "data": [10, 9, 9, 8, 8, 7, 7, 6, 5, 4, 2, 1],
          "backgroundColor": "rgba(255, 159, 64, 0.6)"
        }
      ]
    },
    "options": {
      "indexAxis": "y",
      "scales": {
        "x": { "min": 0, "max": 10 }
      }
    }
  }
}
```

## Visualización en Plano Cartesiano

Este gráfico compara la transversalidad de un componente con su nivel de especialización, revelando patrones interesantes.

- **Eje X (Nivel de Especialización):** Mide si una herramienta es de propósito general (izquierda) o altamente especializada (derecha).
- **Eje Y (Puntuación de Transversalidad):** El impacto del componente a través de la plataforma.

Se puede observar una tendencia: los componentes más generalistas y de infraestructura tienden a ser más transversales, mientras que las herramientas altamente especializadas tienen un impacto más localizado.

```json
{
  "title": "Transversalidad vs. Especialización",
  "description": "Compara el impacto transversal de un componente con su grado de especialización.",
  "data": {
    "type": "scatter",
    "data": {
      "datasets": [
        {
          "label": "Componentes",
          "data": [
            { "x": 1, "y": 6, "label": "Gateway API" },
            { "x": 1, "y": 10, "label": "Cilium" },
            { "x": 2, "y": 8, "label": "Vault" },
            { "x": 3, "y": 8, "label": "Cert-Manager" },
            { "x": 3, "y": 7, "label": "ArgoCD" },
            { "x": 4, "y": 9, "label": "Fluent-bit" },
            { "x": 5, "y": 4, "label": "Argo Workflows" },
            { "x": 6, "y": 7, "label": "Prometheus" },
            { "x": 6, "y": 5, "label": "Grafana" },
            { "x": 8, "y": 9, "label": "Kyverno" },
            { "x": 9, "y": 2, "label": "SonarQube" },
            { "x": 10, "y": 1, "label": "PostgreSQL" }
          ],
          "backgroundColor": "rgba(75, 192, 192, 0.6)",
          "pointRadius": 10,
          "pointHoverRadius": 15
        }
      ]
    },
    "options": {
      "scales": {
        "x": {
          "title": { "display": true, "text": "<- Propósito General ... Altamente Especializado ->" },
          "min": 0, "max": 11
        },
        "y": {
          "title": { "display": true, "text": "Puntuación de Transversalidad" },
          "min": 0, "max": 11
        }
      },
      "plugins": {
        "tooltip": { "callbacks": { "label": "function(context) { return context.raw.label; }" } }
      }
    }
  }
}
```
