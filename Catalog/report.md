# Auditoría del Software Catalog - IDP Blueprint

**Documento técnico para evaluación y mejora del catálogo de Backstage del Internal Developer Platform**

---

## 1. Resumen Ejecutivo

### Inventario de Entidades
* **catalog/domains/** (1 entidad)
* **catalog/systems/** (7 entidades)
* **catalog/components/** (32 entidades)
* **catalog/apis/** (3 entidades)
* **catalog/resources/** (6 entidades)
* **catalog/users/** (2 entidades)
* **catalog/groups/** (2 entidades)

### Sistemas Identificados
* **idp** (sistema raíz)
* **idp-core** (Portal, Auth)
* **idp-observability** (Monitoring, Logging)
* **idp-security** (Secrets, Policies)
* **idp-orchestration** (GitOps, Workflows)
* **idp-networking** (Ingress, Service Mesh)
* **idp-quality** (Code Analysis)

---

## 2. Alineación con Backstage Entity Model (Spotify)

### ✅ Fortalezas

#### 2.1 Cumplimiento de Schema Básico
* Todas las entidades usan `apiVersion: backstage.io/v1alpha1` correctamente.
* Tipos de entidades válidos (Domain, System, Component, API, Resource, User, Group).
* Campos obligatorios presentes: `metadata.name`, `spec.owner`, `spec.type`.

#### 2.2 Jerarquía de Dominio Correcta
* **Domain:** idp-platform
    * **System:** idp
        * **System:** idp-core
        * **System:** idp-observability
        * **System:** idp-security
        * **System:** idp-orchestration
        * **System:** idp-networking
        * **System:** idp-quality
            * *Components*

#### 2.3 Uso de Relaciones
* **partOf:** Correctamente usado para jerarquía de sistemas.
* **dependsOn:** Utilizado para dependencias de infraestructura.
* **providesApis/consumesApis:** Presente en componentes clave.
* **subComponentOf:** Usado para componentes anidados (ej: grafana → kube-prometheus-stack).

### ⚠️ Hallazgos Críticos

#### 2.4 Inconsistencias en Relaciones

**Problema 1: Duplicación de Entidades**
* Existe `backstage.yaml` Y `idp-backstage.yaml` (potencialmente la misma entidad).
* Existe `dex.yaml` Y `idp-dex.yaml` (potencialmente la misma entidad).
* Esto puede crear confusión en el grafo de dependencias.

> **Ejemplo de inconsistencia:** `backstage.yaml` depende de "dex", mientras que `idp-backstage.yaml` depende de "idp-dex".
> **Recomendación:** Consolidar a una sola entidad por componente real (ej: backstage o eliminar duplicados).

**Problema 2: Nomenclatura de Referencias**
* En `backstage-postgresql.yaml` vs `idp-postgres.yaml` - ¿son diferentes bases de datos o duplicados?
* Las referencias cruzadas pueden estar rotas: `idp-backstage` depende de `idp-postgres`, pero `backstage` depende de `backstage-postgresql`.

---

## 3. Metadata y Tags

### 3.1 Estado Actual de Tags
* ✅ Buena cobertura en componentes de observabilidad: `[dashboard, observability, ui, visualization]`
* ✅ Tags tecnológicos presentes: `[nodejs, go, postgresql, ebpf]`
* ✅ Tags funcionales: `[gitops, cicd, security, networking]`

> **Ejemplos positivos:**
> * grafana.yaml: tags: [dashboard, observability, ui, visualization]
> * vault.yaml: tags: [security, secrets, vault, go]

### ⚠️ Brechas Críticas en Metadata

#### 3.2 Ausencia TOTAL de Tags FinOps
**Hallazgo Crítico:** Ninguna entidad tiene tags relacionados con costos o gestión financiera.

> **Tags FinOps recomendados:**
> * cost-center: platform-engineering
> * budget-owner: platform-team
> * environment: production
> * tier: critical (opciones: critical, high, medium, low)
> * cost-allocation: shared (opciones: shared, dedicated, team-specific)
> * scaling-profile: elastic

**Beneficios de implementar FinOps tags:**
1. Chargebacks/Showbacks a equipos consumidores.
2. Optimización de recursos por tier.
3. Presupuestación y forecasting.
4. Identificación de costos compartidos vs dedicados.

#### 3.3 Annotations Inconsistentes
**Uso de Kubernetes Annotations:**
* ✅ Presente en algunos: `backstage.io/kubernetes-label-selector`, `backstage.io/kubernetes-id`.
* ❌ Ausente en otros componentes que deberían tenerlo.

> **Ejemplo de inconsistencia:**
> * **vault.yaml:** tiene annotations completas.
> * **cilium.yaml:** solo tiene techdocs-ref, falta k8s metadata.

**Problema:** Sin annotations de Kubernetes, el plugin de Kubernetes en Backstage no puede mostrar estado en vivo de pods, recursos, logs.

---

## 4. Dependencias y Flujos de Data

### 4.1 Grafo de Dependencias Identificado
* **idp-gateway** depende de: `cilium`, `cert-manager`
* **backstage** depende de: `dex`, `backstage-postgresql`
* **idp-backstage** depende de: `idp-postgres`, `idp-dex`
* **external-secrets** depende de: `vault`
* **grafana** depende de: `loki`

### ⚠️ Problemas en Dependencias

#### 4.2 Dependencias Faltantes
**Componentes sin dependencias explícitas:**
* `vault.yaml`: No declara dependencias, pero podría depender de storage/postgres.
* `kyverno.yaml`: No declara dependencias.
* `kube-prometheus-stack.yaml`: No declara dependencias (debería depender de node-exporter, kube-state-metrics).

> **Ejemplo:** `kube-prometheus-stack` debería declarar `dependsOn` explícito hacia `node-exporter` y `kube-state-metrics`.

#### 4.3 Flujos de Data No Documentados
**Ausencia de metadata sobre flujos de data:**
* No hay tags indicando flujo de logs: `fluent-bit → loki → grafana`
* No hay tags indicando flujo de métricas: `node-exporter → prometheus → grafana`

> **Recomendación:** Agregar tags como `logging`, `collector`, `data-pipeline-metrics` a los componentes respectivos.

---

## 5. Nomenclatura y Convenciones

### 5.1 Prefijos Inconsistentes
**Problema identificado:**
* Algunos componentes usan prefijo `idp-`: `idp-backstage`, `idp-dex`.
* Otros NO usan prefijo: `backstage`, `dex`, `vault`.

**Impacto:** Confusión sobre qué es "parte del IDP" vs "herramienta independiente" y duplicación potencial.

> **Recomendación:** Adoptar convención clara (Opción B recomendada: Sin prefijo IDP, usar `system: idp-core` para indicar pertenencia).

### 5.2 Nombres con Agregados Innecesarios
**Problema:** Descripciones con sufijos como "- Helm Chart" (ruido).
> **Recomendación:** Mover esa información a annotations (`deployment.method: helm`, `helm.chart: cilium/cilium`).

---

## 6. Validez como Referencia Arquitectónica

### ✅ Fortalezas Arquitectónicas
#### 6.1 Separación de Concerns
* Sistemas bien definidos por responsabilidad (Core, Security, Observability, Networking, Quality, Orchestration).
* Componentes agrupados lógicamente.

#### 6.2 Capas de Abstracción
* Domain (`idp-platform`) - capa de negocio
* System (`idp-*`) - agrupación lógica
* Component - servicios concretos
* Resource - dependencias de infraestructura
* API - contratos de integración

#### 6.3 Representación del IDP
El catálogo representa adecuadamente:
* ✅ Portal de desarrollo (Backstage)
* ✅ GitOps (ArgoCD)
* ✅ Observabilidad (Prometheus, Grafana, Loki)
* ✅ Seguridad (Vault, Kyverno, Trivy)
* ✅ Networking (Cilium, Gateway API)
* ✅ CI/CD (Argo Workflows, SonarQube)

### ⚠️ Brechas Arquitectónicas

#### 6.4 Falta de Service Level Objectives (SLOs)
**Hallazgo:** Existe `pyrra.yaml` (herramienta de SLOs) pero no hay metadata de SLOs en componentes críticos.

> **Recomendación:** Agregar annotations de SLO (`slo.availability.target: "99.5"`, `slo.latency.p99.target: "500ms"`).

#### 6.5 Ausencia de Component Types Específicos
**Problema:** Todos los componentes son `type: service`, perdiendo granularidad.

> **Recomendación:**
> * **grafana:** usar `type: website` (Es una UI)
> * **loki:** usar `type: database` (Es storage de logs)

---

## 7. Aporte de Valor a Usuarios del Portal

### 7.1 Funcionalidades para Desarrolladores
**Valor actual:**
* ✅ Links a dashboards (links: en ArgoCD, Grafana, SonarQube, Argo Workflows).
* ✅ Annotations de Kubernetes para ver pods en vivo.
* ✅ Tech Docs refs (`backstage.io/techdocs-ref`).
* ✅ APIs documentadas (aunque con `paths: {}` vacío).

### ⚠️ Brechas de Valor

#### 7.2 Falta de Contexto para Usuarios
**Metadata ausente que ayudaría a desarrolladores:**

> **Recomendaciones de annotations adicionales:**
> * Contactos: `pagerduty.com/service-id`, `opsgenie.com/team`
> * Documentación: `docs.url`, `runbook.url`
> * Costos: `cloud.google.com/cost-center`, `estimated-monthly-cost`
> * Compliance: `compliance.gdpr`

#### 7.3 APIs Sin Definición Real
**Problema:** Todas las APIs tienen definiciones vacías (`paths: {}`).
**Impacto:** Desarrolladores no pueden ver endpoints ni generar clientes.

> **Recomendación:**
> 1. Para APIs externas (ArgoCD, Grafana), referenciar swagger oficial en `backstage.io/api-spec-url`.
> 2. Para APIs custom (`idp-backstage-api`), documentar endpoints reales.

---

## 8. Hallazgos Adicionales

### 8.1 Componentes Huérfanos
**Componentes sin asociación clara a System:**
* `cilium-agent.yaml`
* `cilium-operator.yaml`
* Componentes internos de ArgoCD (`repo-server`, `application-controller`)

> **Recomendación:** Usar `subComponentOf: argocd` para agruparlos y evitar ruido en el catálogo.

---

## 9. Recomendaciones Prioritarias

### 🔴 Prioridad CRÍTICA
1. **Eliminar duplicados de entidades:** Consolidar `backstage.yaml`/`idp-backstage.yaml` y `dex.yaml`/`idp-dex.yaml`.
2. **Agregar tags FinOps:** Añadir a TODAS las entidades.
3. **Completar annotations de Kubernetes:** Asegurar `kubernetes-id` y `label-selector` en todos los componentes.

### 🟠 Prioridad ALTA
4. **Documentar dependencias faltantes:** Especialmente para `kube-prometheus-stack` y `vault`.
5. **Estandarizar nomenclatura:** Eliminar prefijo `idp-` redundante.
6. **Agregar metadata de deployment:** Indicar si es Helm, Kustomize u Operator.

### 🟡 Prioridad MEDIA
7. **Definir APIs reales:** Conectar Swagger/OpenAPI specs.
8. **Agregar SLOs:** Definir objetivos de disponibilidad y latencia.
9. **Usar component types específicos:** Diferenciar `website`, `library`, `database`.

---

## 10. Scorecard Final

| Dimensión | Score | Comentario |
| :--- | :--- | :--- |
| Alineación con Backstage Model | 7/10 | Buena estructura, pero duplicados y relaciones inconsistentes |
| Metadata y Tags | 4/10 | Tags funcionales OK, pero CERO tags FinOps |
| Dependencias | 6/10 | Algunas bien definidas, muchas faltantes |
| Nomenclatura | 5/10 | Inconsistencia en prefijos y agregados innecesarios |
| Referencia Arquitectónica | 8/10 | Representa bien el IDP, falta granularidad en types |
| Valor para Usuarios | 6/10 | Links y K8s annotations presentes, APIs vacías |
| FinOps Readiness | 1/10 | Crítico: Sin tags de costos, tiers, o budgets |

**SCORE GLOBAL: 5.3/10**
*(Requiere mejoras para producción)*

---

## 11. Plan de Acción Sugerido

### Fase 1 - Quick Wins (1-2 días):
* Eliminar duplicados de entidades.
* Agregar tags FinOps básicos a todas las entidades.  (basado en los tags ya aplicados en los workloads)
* Completar annotations de Kubernetes faltantes.

### Fase 2 - Mejoras de Calidad (3-5 días):
* Documentar dependencias faltantes.
* Estandarizar nomenclatura.
* Agregar metadata de deployment.

### Fase 3 - Valor Agregado (1-2 semanas):
* Definir APIs con specs reales.
* Agregar SLOs a componentes críticos.
* Usar component types específicos.

---

## Conclusión

He completado la auditoría holística del Software Catalog del IDP Blueprint. El catálogo tiene una base sólida arquitectónicamente, pero presenta brechas críticas en **FinOps**, **dependencias incompletas** y **duplicación de entidades**.

El scorecard global de **5.3/10** indica que se necesitan mejoras significativas antes de considerarlo una referencia de producción.