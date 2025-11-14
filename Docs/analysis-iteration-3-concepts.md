
# Iteración 3: Análisis de Filosofías de Diseño y Distancia Conceptual

Esta iteración expande el análisis más allá de GitOps para identificar un conjunto de filosofías de diseño interconectadas que definen la arquitectura del proyecto. En lugar de una única "distancia", se evalúa la afinidad de cada componente con estos principios fundamentales.

## Principios de Diseño Identificados

1.  **Configuración Declarativa:** Es el principio más fundamental. El estado deseado de *todo* el sistema se describe en manifiestos YAML. Los componentes no se configuran manualmente; en su lugar, los controladores de Kubernetes trabajan para reconciliar el estado real con el estado declarado en el código.
2.  **Infraestructura como Código (IaC):** Una especialización de la configuración declarativa aplicada a la infraestructura. La red (Cilium), los gateways (Gateway API), los certificados (Cert-Manager) y las propias aplicaciones se tratan como código versionable.
3.  **GitOps:** Es la implementación específica de IaC y configuración declarativa adoptada en este proyecto. Utiliza **ArgoCD** para hacer de un repositorio Git la única fuente de la verdad y automatizar la sincronización con el clúster.
4.  **Seguridad como Código (Security as Code):** La seguridad no es una ocurrencia tardía, sino una parte integral del código base. Las políticas de seguridad (`Kyverno`), la rotación de secretos (`External Secrets`) y la PKI (`Cert-Manager`) se definen y auditan como código.
5.  **Observabilidad como Código (Observability as Code):** Los activos de monitoreo, como los `ServiceMonitors` de Prometheus y los dashboards de Grafana (almacenados en `ConfigMaps`), se definen como código, lo que permite versionarlos, reutilizarlos y gestionarlos de forma centralizada.

## Matriz de Afinidad: Componentes vs. Filosofías

La siguiente matriz muestra qué tan fuertemente se alinea cada componente con cada filosofía de diseño.

| Componente         | Conf. Declarativa | IaC       | GitOps    | Seg. como Código | Obs. como Código |
| ------------------ | :---------------: | :-------: | :-------: | :--------------: | :--------------: |
| **ArgoCD**         |        ✓✓✓        |    ✓✓✓    |    ✓✓✓    |        ✓         |        ✓✓        |
| **Kyverno**        |        ✓✓✓        |    ✓✓     |    ✓✓     |       ✓✓✓        |        ✓         |
| **Cert-Manager**   |        ✓✓✓        |    ✓✓     |    ✓✓     |       ✓✓✓        |                  |
| **External Secrets**|        ✓✓✓        |    ✓✓     |    ✓✓     |       ✓✓✓        |                  |
| **Argo Workflows** |        ✓✓✓        |    ✓✓✓    |    ✓✓     |        ✓         |        ✓         |
| **Prometheus**     |        ✓✓✓        |    ✓✓     |    ✓✓     |                  |       ✓✓✓        |
| **Grafana**        |        ✓✓✓        |    ✓✓     |    ✓✓     |                  |       ✓✓✓        |
| **Vault**          |         ✓         |     ✓     |     ✓     |       ✓✓✓        |                  |
| **Gateway API**    |        ✓✓✓        |    ✓✓✓    |    ✓✓     |        ✓         |                  |

**Leyenda:**
- **✓✓✓ (Motor/Pilar):** El componente es un motor central o un pilar para esta filosofía.
- **✓✓ (Implementador):** El componente es un implementador clave o se gestiona directamente bajo esta filosofía.
- **✓ (Relevante):** El componente es relevante o un consumidor de esta filosofía.

## Visualización en Plano Cartesiano

Este gráfico posiciona los componentes en un plano diferente, enfocado en su rol dentro de la plataforma.

- **Eje X (Nivel de Especialización):** Mide si una herramienta es de propósito general (más a la izquierda) o altamente especializada en una función (más a la derecha).
- **Eje Y (Enfoque de la Herramienta):** Mide si la herramienta está orientada a la plataforma y sus operadores (abajo) o a las aplicaciones y sus desarrolladores (arriba).

```json
{
  "title": "Mapa de Componentes por Especialización y Enfoque",
  "description": "Visualiza la distribución de componentes según su grado de especialización y su orientación (plataforma vs. aplicación).",
  "data": {
    "type": "scatter",
    "data": {
      "datasets": [
        {
          "label": "Componentes",
          "data": [
            { "x": 1, "y": 2, "label": "Gateway API" },
            { "x": 2, "y": 1, "label": "Vault" },
            { "x": 3, "y": 8, "label": "ArgoCD" },
            { "x": 4, "y": 3, "label": "Cert-Manager" },
            { "x": 5, "y": 7, "label": "Argo Workflows" },
            { "x": 6, "y": 4, "label": "Prometheus" },
            { "x": 6, "y": 9, "label": "Grafana" },
            { "x": 7, "y": 5, "label": "External Secrets" },
            { "x": 8, "y": 6, "label": "Kyverno" },
            { "x": 9, "y": 6, "label": "SonarQube" }
          ],
          "backgroundColor": "rgba(54, 162, 235, 0.6)",
          "pointRadius": 10,
          "pointHoverRadius": 15
        }
      ]
    },
    "options": {
      "scales": {
        "x": {
          "title": { "display": true, "text": "<- Propósito General ... Altamente Especializado ->" },
          "min": 0, "max": 10
        },
        "y": {
          "title": { "display": true, "text": "<- Foco en Plataforma ... Foco en Aplicación ->" },
          "min": 0, "max": 10
        }
      },
      "plugins": {
        "tooltip": { "callbacks": { "label": "function(context) { return context.raw.label; }" } }
      }
    }
  }
}
```
