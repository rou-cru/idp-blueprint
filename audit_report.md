# Reporte de Auditoría del Clúster IDP

## 1. Resumen Ejecutivo
El clúster se encuentra operativo y funcional en su mayor parte. Los componentes críticos del IDP (ArgoCD, Backstage, Vault) están en ejecución (Running). Sin embargo, se ha detectado una **insuficiencia de recursos (Memoria)** que afecta a la observabilidad (Prometheus), y un alto número de **violaciones de políticas de seguridad (Kyverno)** relacionadas con el etiquetado de recursos.

## 2. Estado de Salud (Health Check)

| Componente | Estado | Observaciones |
| :--- | :--- | :--- |
| **Nodos (k3s)** | 🟢 Ready | 3 Nodos activos (1 Server, 2 Agentes). Versión v1.33.4. |
| **Core IDP** | 🟢 Ready | Backstage, ArgoCD, Vault, SonarQube operativos. |
| **Observabilidad** | 🟡 Degradado | **Prometheus (Agent)** en estado `Pending` por falta de memoria RAM. Grafana y Loki están OK. |
| **Red (Cilium)** | 🟢 Ready | Gateway API configurado correctamente. |
| **Seguridad** | 🟠 Alerta | Múltiples violaciones de políticas detectadas en los reportes. |

### 🔴 Problema Crítico: Prometheus Pending
El pod `prometheus-prometheus-kube-prometheus-prometheus-0` no puede ser programado.
*   **Causa:** `0/3 nodes are available: 1 node(s) had untolerated taint... 2 Insufficient memory`.
*   **Impacto:** No se están recolectando métricas nuevas, aunque Grafana está accesible.
*   **Recomendación:** Aumentar la memoria de los nodos del clúster (si es Docker/VM) o reducir los `requests` de memoria en el chart de Prometheus si es un entorno de desarrollo.

## 3. Accesos y Rutas Expuestas
Las herramientas están expuestas a través de **Gateway API** (Cilium) bajo el dominio `192-168-65-16.nip.io`.

| Herramienta | URL de Acceso |
| :--- | :--- |
| **Backstage** | `http://backstage.192-168-65-16.nip.io` |
| **ArgoCD** | `http://argocd.192-168-65-16.nip.io` |
| **Vault** | `http://vault.192-168-65-16.nip.io` |
| **Grafana** | `http://grafana.192-168-65-16.nip.io` |
| **Argo Workflows** | `http://workflows.192-168-65-16.nip.io` |
| **SonarQube** | `http://sonarqube.192-168-65-16.nip.io` |
| **Argo Events** | `http://events.192-168-65-16.nip.io` |
| **Pyrra (SLOs)** | `http://pyrra.192-168-65-16.nip.io` |

## 4. Hallazgos de Seguridad (Kyverno)
Se han detectado 4 ClusterPolicies activas:
*   `audit-business-labels`
*   `audit-namespace-resource-governance`
*   `enforce-namespace-labels`
*   `require-component-labels`

**Situación:** Los `PolicyReports` muestran fallos (`FAIL`) generalizados en casi todos los namespaces (`argocd`, `cicd`, `vault-system`).
**Análisis:** Esto es común cuando se aplican políticas de etiquetado estricto (ej. "todo debe tener label `owner`") sobre Helm Charts de terceros que no traen esas etiquetas por defecto.
**Recomendación:** Revisar si estas políticas deben ser `Enforce` (bloqueantes) o `Audit` (informativas), o aplicar `ClusterPolicyException` para los namespaces de infraestructura.

## 5. Siguientes Pasos Sugeridos
1.  **Investigar Prometheus:** Revisar los recursos disponibles en los nodos (`kubectl top nodes` si metrics-server responde) o ajustar los limits.
2.  **Validar Accesos:** Confirmar carga correcta de las UI de Backstage y ArgoCD desde el navegador.
3.  **Afinar Políticas:** Crear excepciones de Kyverno para reducir el ruido en los reportes de seguridad.
