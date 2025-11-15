
# Iteración 2: Análisis de Grupos de Responsabilidad

En esta iteración, los componentes del IDP se agrupan en "Grupos de Responsabilidad" lógicos para entender su propósito y cómo sus funciones se superponen. Un componente puede pertenecer a múltiples grupos, lo que revela su rol multifacético en la plataforma.

Se han identificado los siguientes grupos principales:
- **Infraestructura de Plataforma:** Servicios base y fundamentales.
- **Seguridad e Identidad:** Componentes que aseguran la plataforma y gestionan secretos.
- **Políticas y Gobernanza:** Herramientas que aplican y reportan sobre las reglas del clúster.
- **Observabilidad y Monitoreo:** El stack para recolectar, almacenar y visualizar datos del sistema.
- **GitOps y Entrega:** Herramientas para el despliegue y la gestión de aplicaciones.
- **CI/CD y Calidad de Código:** Componentes para la automatización de la integración y el análisis de código.

## Diagrama de Grupos y Componentes

El siguiente diagrama de Mermaid visualiza estos grupos y los componentes que contienen. Nótese cómo componentes como `Vault`, `Kyverno` y `Fluent-bit` actúan como puentes entre diferentes dominios de responsabilidad.

```mermaid
graph TD;
    subgraph " "
        subgraph "Infraestructura de Plataforma"
            direction LR
            infra_col1(Vault, Cert-Manager, External Secrets)
            infra_col2(Gateway API, Fluent-bit)
        end

        subgraph "Seguridad e Identidad"
            direction LR
            sec_col1(Vault, Cert-Manager, External Secrets)
            sec_col2(Kyverno)
        end

        subgraph "Políticas y Gobernanza"
            direction LR
            gov_col1(Kyverno, Policy Reporter)
        end

        subgraph "Observabilidad y Monitoreo"
            direction LR
            obs_col1(Prometheus, Grafana, Loki)
            obs_col2(Fluent-bit)
        end

        subgraph "GitOps y Entrega"
            direction LR
            gitops_col1(ArgoCD, Argo Workflows)
        end

        subgraph "CI/CD y Calidad de Código"
            direction LR
            cicd_col1(Argo Workflows, SonarQube)
        end
    end

    style Infraestructura de Plataforma fill:#e6f2ff,stroke:#333
    style "Seguridad e Identidad" fill:#ffe6e6,stroke:#333
    style "Políticas y Gobernanza" fill:#fff5e6,stroke:#333
    style "Observabilidad y Monitoreo" fill:#e6ffed,stroke:#333
    style "GitOps y Entrega" fill:#f2e6ff,stroke:#333
    style "CI/CD y Calidad de Código" fill:#e6e6e6,stroke:#333
```

## Visualización en Plano Cartesiano

Este gráfico posiciona los componentes en un plano donde el eje X representa el dominio funcional principal y el eje Y representa el nivel de abstracción (desde la infraestructura de bajo nivel hasta las herramientas de cara al desarrollador).

- **Eje X (Dominio Funcional):** Separa los componentes por su propósito principal.
- **Eje Y (Nivel de Abstracción):** Muestra qué tan cerca está un componente del hardware/kernel (bajo) o del desarrollador (alto).

```json
{
  "title": "Mapa de Componentes por Dominio y Abstracción",
  "description": "Visualiza la distribución de componentes según su función principal y su nivel en el stack tecnológico.",
  "data": {
    "type": "scatter",
    "data": {
      "datasets": [
        { "label": "Infraestructura", "data": [{ "x": 1, "y": 2, "label": "Gateway API" }, { "x": 1, "y": 1, "label": "Fluent-bit" }], "backgroundColor": "#e6f2ff" },
        { "label": "Seguridad", "data": [{ "x": 2, "y": 2, "label": "Vault" }, { "x": 2, "y": 3, "label": "Cert-Manager" }, { "x": 2, "y": 4, "label": "External Secrets" }, { "x": 2, "y": 5, "label": "Kyverno" }], "backgroundColor": "#ffe6e6" },
        { "label": "Gobernanza", "data": [{ "x": 3, "y": 5, "label": "Kyverno" }, { "x": 3, "y": 6, "label": "Policy Reporter" }], "backgroundColor": "#fff5e6" },
        { "label": "Observabilidad", "data": [{ "x": 4, "y": 3, "label": "Prometheus" }, { "x": 4, "y": 3, "label": "Loki" }, { "x": 4, "y": 7, "label": "Grafana" }], "backgroundColor": "#e6ffed" },
        { "label": "Entrega/CI-CD", "data": [{ "x": 5, "y": 8, "label": "ArgoCD" }, { "x": 5, "y": 7, "label": "Argo Workflows" }, { "x": 5, "y": 6, "label": "SonarQube" }], "backgroundColor": "#f2e6ff" }
      ]
    },
    "options": {
      "scales": {
        "x": {
          "title": { "display": true, "text": "Dominio Funcional Principal" },
          "min": 0, "max": 6,
          "ticks": { "stepSize": 1, "callback": "function(value, index, values) { return ['','Infra', 'Seguridad', 'Gobernanza', 'Observabilidad', 'Entrega/CI-CD'][value] || ''; }" }
        },
        "y": {
          "title": { "display": true, "text": "Nivel de Abstracción (Bajo -> Alto)" },
          "min": 0, "max": 9
        }
      },
      "plugins": {
        "tooltip": { "callbacks": { "label": "function(context) { return context.raw.label; }" } }
      }
    }
  }
}
```
