# Estrategia de Scheduling para IDP Blueprint

## Problema Central

Diseñar una estrategia de scheduling resiliente para un cluster k3d de 3 nodos con recursos limitados, balanceando eficiencia operacional con capacidad de auto-recuperación ante fallos.

## Restricciones del Entorno

### Recursos Disponibles (Worker Nodes)

- **2 agent nodes** (Agent-0, Agent-1)
- **Límite por nodo:** 4GB RAM
- **Capacidad teórica total:** 8GB
- **Capacidad real útil:** ~6GB (después de overhead de DaemonSets)

### Overhead Inevitable (DaemonSets)

Cada nodo ejecuta:
- Cilium (CNI): 512Mi
- Fluent-bit (logs): 128Mi
- Node-exporter (metrics): 50Mi
- **Total por nodo:** ~690Mi
- **Total cluster (3 nodos):** ~2.07GB

**Conclusión:** ~1GB de RAM "perdida" en cada worker node dado el overhead adicional de kubernetes, no parece que exista forma de evitarlo.

## Workloads Críticos a Distribuir

Ya se ha tomado la decision de que ESO, Vault y Cert-manager viviran en el nodo master junto al resto del control plane pues son dependencias criticas, en realidad no requieren recursos tan variables y de este modo podemos "olvidarnos" de esto. Se ha buscado dar algo de libertad pese a todo para que en un worst-case el control plane base no caiga y por tanto el scheduler pueda aun levantar estos 3 elementos temporalmente en algun nodo disponible. 

Esto entonces nos deja pendiente el planificar la estrategia mas resiliente posible dadas las limitaciones del proyecto y el supuesto de tener todo el IDP activo como estado deseado. Se requiere ser defensivo al Host, en la mayoria de escenarios K3d esta limitado externamente(WSL, MacOS usando Docker Desktop, etc) pero se ha demostrado que existen escenarios donde el cluster si que podria causar afectacion, especificamente se detecto que los nodos tenian un disk pressure que de hecho era por el SSD de un Host Linux que se ejecutaba como server, se espera mitigar esto desde el uso de PV bien definidos pero hay que tener en cuenta como podria impactar esto en el cambio de nodos en scheduling agresivo por incidencia. Esta misma clase de factores deben ser considerados para otros recursos buscando primero defender al Host y luego resiliencia extrema: tener al menos una fraccion del IDP aun funcional es mejor que una caida total o peor aun, afectar al Host.

### Observability Stack (~3.3GB RAM total)

- **Prometheus:** 1Gi (TSDB, alto I/O, crece con métricas)
- **Grafana:** 384Mi (UI, queries)
- **Loki:** 384Mi (logs, crece con ingesta)
- **AlertManager:** 128Mi
- **Pyrra (SLOs):** 128Mi

**Riesgo identificado:** Prometheus y Loki juntos crean SPOF (Single Point of Failure) para todo el monitoreo.

### CI/CD Stack (~1.5GB RAM total)

- **SonarQube:** 1Gi (análisis de código, spiky)
- **PostgreSQL:** 256Mi (DB para SonarQube)
- **Argo Workflows:** 256Mi (pipeline engine)

### Security Stack (~0.3GB RAM total)

- **Trivy Operator:** 256Mi

### GitOps Engine (control-plane aun por definir)

- **ArgoCD:** ~1.2Gi total
  - Controller: 512Mi
  - Server: 256Mi
  - Repo-server: 256Mi
  - Redis: 128Mi
- **Argo Events:**

**Requisito crítico:** ArgoCD debe poder moverse libremente entre nodos. Si ArgoCD cae, el cluster pierde capacidad de self-healing vía GitOps. Esperamos algo similar para el caso de Events.

## Objetivos de la Estrategia

### Resiliencia ante Fallos

**Escenario:** Un nodo (Agent-0 o Agent-1) cae completamente.

**Requisito:**
- Debe quedar al menos **un componente de observability** funcionando
- Prometheus **O** Loki deben sobrevivir
- ArgoCD debe poder evacuar y continuar operando pese a una incidencia seria

### Eficiencia en Operación Normal

**Escenario:** Cluster saludable, todos los nodos disponibles.

**Requisito:**
- Distribución "bonita" y predecible de workloads
- Bin-packing eficiente (~65-70% utilización por nodo)
- Minimizar cross-node traffic cuando sea posible

### Flexibilidad Bajo Presión - IDP antifragil por diseño

**Escenario:** Scheduler sobrecargado (un nodo caído, memory pressure, etc.)

**Requisito:**
- **NO imponer constraints rígidos** que paralicen el scheduler
- Permitir violaciones de "preferencias" si es necesario para mantener workloads vivos
- Priorizar supervivencia > arquitectura perfecta

## PriorityClasses Configuradas

```
platform-critical        (10000)  # Control-plane k8s
platform-infrastructure  (9000)   # ArgoCD, Vault, Cert-manager, ESO
platform-observability   (8000)   # Prometheus, Grafana, Loki
platform-security        (7000)   # Trivy
platform-cicd            (6000)   # SonarQube, Workflows
platform-low             (5000)   # Misc
```

**Implicación:** En caso de resource contention, el scheduler puede expulsar pods de menor prioridad para acomodar los de mayor prioridad.

## Node Labels Actuales (k3d)

```yaml
Agent-0: role=infra
Agent-1: role=apps
```

**Nota:** esto es historico, puede cambiar si se requiere. Se debe mantener el uso de labels por estandarizacion aun si no participan en el schedulling

## Affinity/Anti-Affinity

- **nodeAffinity:** Preferir/requerir scheduling en ciertos nodos - Se tendria que considerar sus sinergias para no ser estricto
- **podAffinity:** Co-locate pods relacionados - Para pulir la distribucion Happy Path que documentamos? quiza debido a sinergias pueda ser util de manera mas general
- **podAntiAffinity:** Separar pods críticos - SPOF prevention, suena la solucion para metricas/logs pero nos estara forzando a que de hecho alguno de los 2 si se pierda en incidencia?

**Tipos:**

- `requiredDuringScheduling`: Hard constraint - puede causar Pending por lo que es problematico, aun asi no se descarta
- `preferredDuringScheduling`: Soft preference - scheduler intenta pero puede ignorar, en principio eso buscamos pero hay que valorar cada caso dada su sinergia con otras cosas

## Variables No Controladas

### Factores que Influyen en el Scheduler (fuera de nuestro control)

1. **Estado dinámico del cluster**
   - Uso real de memoria de pods varia porque el usuario puede hacer despliegues extra como workloads, usar contenedores debug, etc.
   - Pods en estado `Terminating` ocupando recursos, el timing es nuestro enemigo al tener recursos limitados
   - Evictions por disk/memory pressure pueden o no ser peligrosos para el Host, no podemos saber a priori si es gestionable 100% o en realidad hay que dejar caer el IDP por proteccion al Host

2. **Timing de eventos**
   - Orden de llegada de pods al scheduler luego de que ha finalizado el deploy original con Task
   - Preemptions en cascada posibles
   - Node failures, el usuario podria modificar el IDP tanto en sus workloads como los limites fuertes, asumimos que los nodos pueden fallar

3. **Kernel/Docker overhead**
   - Memory reservations del sistema
   - Page cache, buffer cache
   - Overhead de contenedores

4. **Comportamiento de workloads**
   - SonarQube análisis pesados (spikes)
   - Prometheus cardinality explosions
   - Loki log storms
   - Otros eventos de sobrecarga por experimentacion y uso del usuario del proyecto

## Decisión Pendiente

Necesitamos elegir una estrategia que:

1. **Separe Prometheus y Loki** en operación normal, pero una vez que hay caos en el cluster no queda claro la mejor estrategia
2. **NO bloquee el scheduler** cuando el cluster está bajo presión, ante incidencia tendremos que confiar en el scheduler para todo lo que no controlamos o hemos previsto, hay que facilitarle esa tarea. como garantizar eso mientras estamos aplicando una estrategia de schedulling que requerimos forzosamente?

## Notas de Implementación

- Cert-manager, Vault, ESO forzados al control-plane (affinity + tolerations) la mayoria del tiempo, pero podrian llegar a estar en otros nodos cuando estamos proximos a caida total si aun existen nodos
- Límites de memoria: 4GB por nodo (server + 2 agents) para un setup default limitado a 12Gb con uso a tope, pero editable por el usuario
- Buscamos buenas practicas SRE para clusters de produccion reales, aunque adaptando al escenario especifico que tenemos
- A diferencia de un cluster productivo comun donde los workloads desplegados desde el desarrollo interno son la prioridad y el recurso para mantener produccion funcionando ante incidencias puede parecer infinito, aqui estamos ante un cluster mucho mas parecido a un caso Edge Computing donde esta todo obligado a ser autosuficiente, no hay recurso externo para salvarnos

- Obviamente no todo puede ser igual de prioritario si buscamos antifragilidad real, pero esto es un IDP y por tanto "todo importa" porque es un sistema completo por si mismo, de algun modo no solo es Edge Computing, ademas es critical-mision.
