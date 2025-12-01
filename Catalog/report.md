# Auditoría del Software Catalog - IDP Blueprint

## Resumen Ejecutivo

1. Inventario de Entidades

Estructura del Catalog:
  ├── domains/        1 entidad
  ├── systems/        7 entidades
  ├── components/     32 entidades
  ├── apis/           3 entidades
  ├── resources/      6 entidades
  ├── users/          2 entidades
  └── groups/         2 entidades

  Sistemas identificados:
  - idp (sistema raíz)
  - idp-core (Portal, Auth)
  - idp-observability (Monitoring, Logging)
  - idp-security (Secrets, Policies)
  - idp-orchestration (GitOps, Workflows)
  - idp-networking (Ingress, Service Mesh)
  - idp-quality (Code Analysis)

## 2. Alineación con Backstage Entity Model (Spotify)

✅ Fortalezas

2.1 Cumplimiento de Schema Básico
  - Todas las entidades usan apiVersion: backstage.io/v1alpha1 correctamente
  - Tipos de entidades válidos (Domain, System, Component, API, Resource, User, Group)
  - Campos obligatorios presentes: metadata.name, spec.owner, spec.type

2.2 Jerarquía de Dominio Correcta
  Domain (idp-platform)
    └── System (idp)
        ├── System (idp-core)
        ├── System (idp-observability)
        ├── System (idp-security)
        ├── System (idp-orchestration)
        ├── System (idp-networking)
        └── System (idp-quality)
            └── Components

2.3 Uso de Relaciones
  - partOf: Correctamente usado para jerarquía de sistemas
  - dependsOn: Utilizado para dependencias de infraestructura
  - providesApis/consumesApis: Presente en componentes clave
  - subComponentOf: Usado para componentes anidados (ej: grafana → kube-prometheus-stack)

> ⚠️ Hallazgos Críticos
2.4 Inconsistencias en Relaciones

Problema 1: Duplicación de Entidades
  - Existe backstage.yaml Y idp-backstage.yaml - potencialmente la misma entidad
  - Existe dex.yaml Y idp-dex.yaml - potencialmente la misma entidad
  - Esto puede crear confusión en el grafo de dependencias

Ejemplo de inconsistencia:

```yaml
  # backstage.yaml depende de "dex"
  dependsOn:
    - component:dex
  # idp-backstage.yaml depende de "idp-dex"
  dependsOn:
    - component:idp-dex
```

> Recomendación: Consolidar a una sola entidad por componente real (ej: backstage o eliminar duplicados).

Problema 2: Nomenclatura de Referencias
  - En backstage-postgresql.yaml vs idp-postgres.yaml - ¿son diferentes bases de datos o duplicados?
  - Referencias cruzadas pueden estar rotas: idp-backstage depende de
 idp-postgres, pero backstage depende de backstage-postgresql

## 3. Metadata y Tags

### 3.1 Estado Actual de Tags

  Cobertura de Tags:
  - ✅ Buena cobertura en componentes de observabilidad: [dashboard, observability, ui, visualization]
  - ✅ Tags tecnológicos presentes: nodejs, go, postgresql, ebpf
  - ✅ Tags funcionales: gitops, cicd, security, networking

  Ejemplos positivos:
  # grafana.yaml - buen uso de tags
  tags: [dashboard, observability, ui, visualization]

  # vault.yaml - tags descriptivos
  tags: [security, secrets, vault, go]

### ⚠️ Brechas Críticas en Metadata

3.2 Ausencia TOTAL de Tags FinOps

  Hallazgo Crítico: Ninguna entidad tiene tags relacionados con costos o gestión financiera.

  Tags FinOps recomendados:
  tags:
    - cost-center:platform-engineering
    - budget-owner:platform-team
    - environment:production
    - tier:critical          # critical, high, medium, low
    - cost-allocation:shared # shared, dedicated, team-specific
    - scaling-profile:elastic # elastic, static, burstable

  Beneficios de implementar FinOps tags:
  1. Chargebacks/Showbacks a equipos consumidores
  2. Optimización de recursos por tier
  3. Presupuestación y forecasting
  4. Identificación de costos compartidos vs dedicados

  3.3 Annotations Inconsistentes

  Uso de Kubernetes Annotations:
  - ✅ Presente en algunos: backstage.io/kubernetes-label-selector, backstage.io/kubernetes-id
  - ❌ Ausente en otros componentes que deberían tenerlo

  Ejemplo de inconsistencia:
  # vault.yaml - tiene annotations completas
  annotations:
    backstage.io/techdocs-ref: dir:.
    backstage.io/kubernetes-id: vault
    backstage.io/kubernetes-namespace: vault
    backstage.io/kubernetes-label-selector: "app.kubernetes.io/instance=vault"

  # cilium.yaml - solo tiene techdocs-ref, falta k8s metadata
  annotations:
    backstage.io/techdocs-ref: dir:.

  Problema: Sin annotations de Kubernetes, el plugin de Kubernetes en Backstage no puede mostrar estado en vivo de pods, recursos, logs.

## 4. Dependencias y Flujos de Data

### 4.1 Grafo de Dependencias Identificado

Dependencias de Infraestructura Core:
  idp-gateway
    ├── depends: cilium
    └── depends: cert-manager

  backstage
    ├── depends: dex
    └── depends: backstage-postgresql

  idp-backstage
    ├── depends: idp-postgres
    ├── depends: idp-dex
    ├── provides: idp-backstage-api
    └── consumes: argocd-api

  external-secrets
    └── depends: vault

  grafana
    └── depends: loki

  ⚠️ Problemas en Dependencias

  4.2 Dependencias Faltantes

  Componentes sin dependencias explícitas:
  - vault.yaml - No declara dependencias, pero podría depender de storage/postgres
  - kyverno.yaml - No declara dependencias
  - kube-prometheus-stack.yaml - No declara dependencias (debería depender de node-exporter, kube-state-metrics)

  Ejemplo de dependencia faltante:
  # kube-prometheus-stack.yaml - ACTUAL
  spec:
    type: service
    lifecycle: production
    owner: platform-team
    system: idp-observability

  # DEBERÍA SER:
  spec:
    type: service
    lifecycle: production
    owner: platform-team
    system: idp-observability
    dependsOn:
      - component:node-exporter
      - component:kube-state-metrics
      - component:prometheus-operator  # si existe

  4.3 Flujos de Data No Documentados

  Ausencia de metadata sobre flujos de data:
  - No hay tags indicando flujo de logs: fluent-bit → loki → grafana
  - No hay tags indicando flujo de métricas: node-exporter → prometheus → grafana
  - No hay tags indicando flujo de eventos: argo-events → eventbus → workflow-controller

  Recomendación: Agregar tags de flujo:
  # fluent-bit.yaml
  tags: [logging, collector, data-pipeline-logs]

  # loki.yaml
  tags: [logging, storage, data-pipeline-logs]

  # node-exporter.yaml
  tags: [metrics, collector, data-pipeline-metrics]

## 5. Nomenclatura y Convenciones

### 5.1 Prefijos Inconsistentes

Problema identificado:
  - Algunos componentes usan prefijo idp-: idp-backstage, idp-dex, idp-postgres
  - Otros NO usan prefijo: backstage, dex, vault, argocd, grafana
  - Recursos mixtos: idp-gateway, idp-postgres vs backstage-postgresql, argocd-redis

Impacto:
  - Confusión sobre qué es "parte del IDP" vs "herramienta independiente"
  - Duplicación potencial (backstage vs idp-backstage)
  - Dificultad para búsquedas y filtros

Recomendación - Adoptar convención clara:

  Opción A - Prefijo solo para componentes custom:
  idp-backstage    # Custom deployment del IDP
  idp-dex          # Custom deployment
  backstage        # Helm chart upstream
  dex              # Helm chart upstream

  Opción B - Sin prefijo IDP, usar tags/system:
  backstage        # El componente
  tags: [idp-core] # Indica pertenencia al IDP
  system: idp-core # Ya indica que es parte del IDP

  Recomiendo Opción B porque:
  1. El campo system: idp-* ya indica pertenencia al IDP
  2. Evita redundancia en nombres
  3. Nombres más limpios y estándar de industria

### 5.2 Nombres con Agregados Innecesarios

Ejemplos de agregados en descripciones:
  # cilium.yaml
  description: "eBPF-based Networking, Security, and Observability - Helm Chart."

  # kyverno.yaml
  description: "Kyverno Policy Engine - Kubernetes-native policy management - Helm Chart."

  Problema: El sufijo "- Helm Chart" es ruido. El tipo de deployment (Helm/Kustomize/Operator) debería estar en metadata, no en descripción.

  Recomendación: Agregar annotation:
  annotations:
    deployment.method: helm
    helm.chart: cilium/cilium
    helm.version: 1.14.5

## 6. Validez como Referencia Arquitectónica

### ✅ Fortalezas Arquitectónicas

  6.1 Separación de Concerns
  - Sistemas bien definidos por responsabilidad (Core, Security, Observability, Networking, Quality, Orchestration)
  - Componentes agrupados lógicamente

  6.2 Capas de Abstracción
  - Domain (idp-platform) - capa de negocio
  - System (idp-*) - agrupación lógica
  - Component - servicios concretos
  - Resource - dependencias de infraestructura
  - API - contratos de integración

  6.3 Representación del IDP
  El catálogo representa adecuadamente:
  - ✅ Portal de desarrollo (Backstage)
  - ✅ GitOps (ArgoCD)
  - ✅ Observabilidad (Prometheus, Grafana, Loki)
  - ✅ Seguridad (Vault, Kyverno, Trivy)
  - ✅ Networking (Cilium, Gateway API)
  - ✅ CI/CD (Argo Workflows, SonarQube)

### ⚠️ Brechas Arquitectónicas

  6.4 Falta de Service Level Objectives (SLOs)

  Hallazgo: Existe pyrra.yaml (herramienta de SLOs) pero no hay metadata de SLOs en componentes críticos.

  Recomendación: Agregar annotations de SLO:
  # idp-backstage.yaml
  annotations:
    slo.availability.target: "99.5"
    slo.latency.p99.target: "500ms"
    slo.error-rate.target: "0.5"
    pyrra.slo: "true"

### ⚠️ Brechas Arquitectónicas

  6.5 Ausencia de Component Types Específicos

  Problema: Todos los componentes son type: service, perdiendo granularidad.

  Backstage soporta tipos más específicos:
  - website - Para frontends
  - library - Para librerías compartidas
  - api - Para backends API-only
  - database - Para bases de datos (actualmente en Resources)

  Recomendación:
  # grafana.yaml
  spec:
    type: website  # Es una UI, no solo un "service"

  # loki.yaml
  spec:
    type: database  # Es storage de logs

### 7. Aporte de Valor a Usuarios del Portal

### 7.1 Funcionalidades para Desarrolladores

Valor actual:
- ✅ Links a dashboards (links: en ArgoCD, Grafana, SonarQube, Argo Workflows)
- ✅ Annotations de Kubernetes para ver pods en vivo
- ✅ Tech Docs refs (backstage.io/techdocs-ref)
- ✅ APIs documentadas (aunque con paths: {} vacío)

Ejemplo positivo:
# grafana.yaml
  links:
    - url: https://grafana.192-168-65-16.nip.io
      title: Grafana Dashboards
      icon: dashboard

  ⚠️ Brechas de Valor

  7.2 Falta de Contexto para Usuarios

  Metadata ausente que ayudaría a desarrolladores:

  # Recomendaciones de annotations adicionales:
  annotations:
    # Contactos y ownership
    pagerduty.com/service-id: "P123ABC"
    opsgenie.com/team: "platform-team"

    # Documentación
    docs.url: "https://confluence.company.com/platform/grafana"
    runbook.url: "https://runbooks.company.com/grafana-incidents"

    # SLIs/SLOs
    datadog.com/dashboard: "https://app.datadoghq.com/dashboard/abc-123"

    # Costs
    cloud.google.com/cost-center: "platform-engineering"
    estimated-monthly-cost: "500"  # USD

    # Compliance
    compliance.gdpr: "true"
    compliance.soc2: "true"

  7.3 APIs Sin Definición Real

  Problema: Todas las APIs tienen definiciones vacías:
  # argocd-api.yaml
  definition: |
    openapi: 3.0.0
    info:
      title: ArgoCD API
      version: 1.0.0
    paths: {}  # <-- VACÍO

  Impacto: Desarrolladores no pueden:
  - Ver endpoints disponibles
  - Generar clientes automáticamente
  - Entender contratos de integración

  Recomendación:
  1. Para APIs externas (ArgoCD, Grafana), referenciar swagger oficial:
  annotations:
    backstage.io/api-spec-url: "https://raw.githubusercontent.com/argoproj/argo-cd/master/api/openapi-spec/swagger.json"

  2. Para APIs custom (idp-backstage-api), documentar endpoints reales.

  ---
  8. Hallazgos Adicionales

  8.1 Componentes Huérfanos

  Componentes sin asociación clara a System:

  Revisando los archivos, la mayoría tienen system: definido, pero debería verificarse:
  - cilium-agent.yaml, cilium-operator.yaml - ¿Duplicados de cilium.yaml?
  - argocd-application-controller.yaml, argocd-repo-server.yaml, argocd-server.yaml - ¿Subcomponentes de argocd.yaml?

  Recomendación: Si son subcomponentes, usar subComponentOf: argocd en lugar de entidades separadas, o agruparlos como "deployments
  internos" no expuestos en el catálogo.

  8.2 Usuarios y Grupos

  Estado: Minimalista pero correcto
  - 2 usuarios: dev, admin
  - 2 grupos: developers, platform-team

  Recomendación para producción:
  - Integrar con IdP real (Okta, Azure AD) vía OIDC
  - Usuarios serían importados automáticamente
  - Mantener grupos en catálogo para ownership

  ---
  9. Recomendaciones Prioritarias

  Prioridad CRÍTICA

  1. Eliminar duplicados de entidades
    - Consolidar: backstage.yaml vs idp-backstage.yaml
    - Consolidar: dex.yaml vs idp-dex.yaml
    - Verificar: backstage-postgresql vs idp-postgres
  2. Agregar tags FinOps a TODAS las entidades
  tags:
    - tier:critical|high|medium|low
    - cost-allocation:shared|dedicated
    - environment:production
  3. Completar annotations de Kubernetes en todos los componentes
  annotations:
    backstage.io/kubernetes-id: <component-name>
    backstage.io/kubernetes-namespace: <namespace>
    backstage.io/kubernetes-label-selector: "app=<name>"

  Prioridad ALTA

  4. Documentar dependencias faltantes
    - kube-prometheus-stack → node-exporter, kube-state-metrics
    - vault → storage/backend
    - Componentes que dependen de cert-manager
  5. Estandarizar nomenclatura
    - Eliminar prefijo idp- redundante (dado que system: idp-* ya lo indica)
    - O mantener consistencia: TODOS con prefijo o NINGUNO
  6. Agregar metadata de deployment
  annotations:
    deployment.method: helm|kustomize|operator
    helm.chart: repo/chart-name
    helm.version: "1.2.3"

  Prioridad MEDIA

  7. Definir APIs reales
    - ArgoCD API: referenciar swagger oficial
    - Grafana API: referenciar swagger oficial
    - Backstage API: documentar plugins expuestos
  8. Agregar SLOs a componentes críticos
  annotations:
    slo.availability.target: "99.5"
    slo.latency.p99.target: "500ms"
  9. Usar component types específicos
    - website para UIs
    - library para componentes compartidos
    - database para data stores
  10. Agregar tags de flujo de data
  tags: [data-pipeline-logs, data-pipeline-metrics, data-pipeline-events]

  ---
  10. Scorecard Final

  | Dimensión                      | Score | Comentario
                                      |
  |--------------------------------|-------|---------------------------------------------------------------|
  | Alineación con Backstage Model | 7/10  | Buena estructura, pero duplicados y relaciones inconsistentes |
  | Metadata y Tags                | 4/10  | Tags funcionales OK, pero CERO tags FinOps                    |
  | Dependencias                   | 6/10  | Algunas bien definidas, muchas faltantes                      |
  | Nomenclatura                   | 5/10  | Inconsistencia en prefijos y agregados innecesarios           |
  | Referencia Arquitectónica      | 8/10  | Representa bien el IDP, falta granularidad en types           |
  | Valor para Usuarios            | 6/10  | Links y K8s annotations presentes, APIs vacías                |
  | FinOps Readiness               | 1/10  | Crítico: Sin tags de costos, tiers, o budgets                 |

  Score Global: 5.3/10 - Requiere mejoras para producción

  ---
  11. Plan de Acción Sugerido

  Fase 1 - Quick Wins (1-2 días):
  - Eliminar duplicados de entidades
  - Agregar tags FinOps básicos a todas las entidades
  - Completar annotations de Kubernetes faltantes

  Fase 2 - Mejoras de Calidad (3-5 días):
  - Documentar todas las dependencias faltantes
  - Estandarizar nomenclatura (eliminar prefijos redundantes)
  - Agregar metadata de deployment (helm, version)
  - Agregar links faltantes a dashboards

  Fase 3 - Valor Agregado (1-2 semanas):
  - Definir APIs con specs reales o referencias
  - Agregar SLOs a componentes tier-1
  - Usar component types específicos
  - Tags de flujo de data
  - Documentación de runbooks y contactos

  ---

## Conclusión

  He completado la auditoría holística del Software Catalog del IDP Blueprint. El catálogo tiene una base sólida arquitectónicamente, con
  buena separación de concerns y jerarquía de dominios/sistemas, pero presenta brechas críticas en FinOps, dependencias incompletas, y
  duplicación de entidades.

  Hallazgos más críticos:

  1. CERO tags FinOps - Imposible hacer chargebacks, cost allocation o tier-based optimization
  2. Duplicación de entidades - backstage vs idp-backstage, dex vs idp-dex
  3. Nomenclatura inconsistente - Prefijos idp- aplicados arbitrariamente
  4. Dependencias incompletas - Muchos componentes no declaran sus dependencias reales
  5. APIs sin definición - Todas tienen paths: {}, sin valor para desarrolladores

  El scorecard global de 5.3/10 indica que el catálogo necesita mejoras significativas antes de considerarse una referencia de producción.

  ¿Quieres que implemente alguna de las recomendaciones? Por ejemplo:
  - Eliminar duplicados y consolidar entidades
  - Agregar tags FinOps a todas las entidades
  - Completar annotations de Kubernetes faltantes
  - Documentar dependencias faltantes