# Shared PostgreSQL Migration Plan

Goal: Reemplazar todos los backends SQLite embebidos y las instancias Postgres por-app con una sola instancia PostgreSQL compartida, usada por cualquier stack habilitado. Si un componente puede usar Postgres, lo usará (sin modos opcionales). Si todos los fuses están en false, no se despliega la DB. Backups y seguridad se tratan después (tradeoff de demo).

## Topología y ubicación
- Namespace dedicado: `database` (creado en la capa bootstrap). Aíslalo de stacks de apps.
- Recurso principal: StatefulSet único `shared-postgresql` + Service `shared-postgresql` + PVC.
- GitOps: colocar manifiestos/HelmRelease en `IT/database/` (nueva carpeta) y referenciarlo desde ApplicationSet bootstrap (onda/sync-wave más temprana que los consumidores).
- Secrets: mantenidos en Vault; ExternalSecrets por componente en sus namespaces (backstage, cicd, policies, observability). Paths sugeridos: `secret/<stack>/<app>/postgres`.

## Versiones y compatibilidad
- SonarQube requiere Postgres 13–17; fijar versión de la instancia en ese rango.
- Argo Workflows archive/offload soporta Postgres; requiere permisos `CREATE`/`USAGE` en el esquema.
- Dex soporta Postgres y ejecuta migraciones en arranque.
- Grafana soporta Postgres como backend y permite controlar `max_open_conn`, `max_idle_conn`, `conn_max_lifetime`.
- Policy Reporter soporta Postgres (`database.type: postgres`).

## Consumidores y ajustes requeridos

### Backstage
- Chart: `postgresql.enabled=false` en `K8s/backstage/backstage/values.yaml`. Configurar `appConfig.backend.database.client=pg` y `connection.{host,port,database,user,password}` (ya modelado en values). Usa secret `backstage-postgresql`.
- Requiere rol con `CREATE/ALTER` sobre su DB; ejecuta migraciones al arrancar.
- Pool sugerido: `backend.database.pool.{min,max}` (ej. 5/15) para no agotar `max_connections`.
- readiness/startup: mantener probes actuales; si la DB no está lista, el backend falla rápido—considerar retry/backoff en contenedor si vemos fallos iniciales.
### SonarQube (cicd)
- Chart oficial (SonarSource helm-chart-sonarqube): poner `postgresql.enabled=false` y activar `jdbcOverwrite.enabled=true`; setear `jdbcOverwrite.jdbcUrl`, `jdbcOverwrite.jdbcUsername`, `jdbcOverwrite.jdbcSecretName` (password) o `jdbcPassword`. Valores válidos en `jdbcOverwrite.*` son requeridos para DB externa.
- Versiones soportadas Postgres 13–17; alinear imagen SonarQube con esa versión.
- Migraciones ejecutan en arranque; usar `startupProbe`/init wait-for-db para evitar crash-loop si DB tarda.
- Ajustar pool JDBC (`sonar.jdbc.maxActive`) a ~20 para encajar en `max_connections` global.
### Argo Workflows (cicd)
- Activar archive/offload: en `controller.persistence` set `archive=true` y `postgresql.{host,port,database,tableName,userNameSecret,passwordSecret,sslMode}`. `tableName` requerido (p.ej. `argo_archived_workflows`).
- Permisos: rol con `CREATE` y `USAGE` en schema público; el controller crea tablas (`argo_archived_workflows`, `_labels`, `schema_history`).
- Probes: `startupProbe`/`readiness` que usen `psql -c 'select 1'` con credenciales del secret para evitar migraciones fallidas por falta de conexión.
### Policy Reporter (policies)
- Chart core: `database.type=postgres` (default sqlite). Campos: `database.host`, `database.port` (5432), `database.user`, `database.password`, `database.database`, opcional `database.sslMode`. Eliminar `sqlite.path`.
- Si se usa `database.dsn`, incluir `sslmode` explícito; de lo contrario usar campos separados.
- Pooling: el chart expone `database.maxOpenConns` y `database.maxIdleConns`; fijar valores bajos (ej. 5/2).
### Grafana (observability)
- En `grafana.grafana.ini` sección `[database]`: `type = postgres`, `host = shared-postgresql.database.svc.cluster.local:5432`, `name = grafana`, `user`, `password`, `ssl_mode = disable` (hasta activar TLS).
- Pool: usar parámetros de Grafana `max_open_conn`, `max_idle_conn`, `conn_max_lifetime` (ej. 10 / 5 / 1h) para footprint reducido.
### Dex (portal/backstage)
- `config.storage.type=postgres` y `config.storage.config.{host,port,database,user,password,ssl}` (u `sslmode`). Borrar cualquier referencia a SQLite/file storage.
- Dex corre migraciones en arranque; requiere `CREATE/ALTER` en su DB.

## Bootstrap DB
- Job init (idempotente) que crea DB/roles: `backstage`, `sonarqube`, `argo_workflows`, `policyreporter`, `grafana`, `dex` (pueden quedar ociosos si su fuse está apagado).
- Privilegios: CREATE/ALTER/INSERT en su DB; sin superuser.

## Orden y automatización
- Sync waves: DB (wave 0) -> init Job (0/1) -> ExternalSecrets (wave 1) -> apps (wave 2+). ArgoCD puede manejarlo con annotations y dependencias.
- Readiness: gatear despliegue de apps con checks que validen conexión (`psql`/socket) antes de correr migraciones; evitar carreras cuando varias apps migran a la vez.
- Los Helm charts manejan migraciones si existen credenciales/DB; no se requiere operator. El único custom piece es el Job de roles/DB y la creación del namespace.

## Tabla de verdad (DB compartida requerida)
```
backstage cicd policies observability | ¿Deploy DB?
--------- ---- -------- --------------+-----------
0         0    0        0             | NO
1         0    0        0             | SÍ
0         1    0        0             | SÍ
0         0    1        0             | SÍ
0         0    0        1             | SÍ
1         1    *        *             | SÍ
1         0    1        *             | SÍ
1         0    0        1             | SÍ
0         1    1        *             | SÍ
0         1    0        1             | SÍ
0         0    1        1             | SÍ
1         1    1        1             | SÍ
```
(*) cualquier valor. Regla: despliega PostgreSQL si `backstage OR cicd OR policies OR observability` es verdadero; con todos los fuses apagados no se despliega.

## Notas de capacidad
- Dimensionar Postgres (tope cluster ~12Gi RAM, vida útil garantizada 6h y aceptable hasta 24h): requests 500m CPU / 1Gi RAM; limits 1 vCPU / 1.5Gi; PVC 15–20Gi; `max_connections` 80; `shared_buffers` 256–320Mi; `work_mem` 4Mi; `effective_cache_size` ~1Gi; `maintenance_work_mem` 64Mi; `statement_timeout` 30s; `max_wal_size` 512Mi–1Gi; `checkpoint_timeout` 10–15m. Sin replicas ni operator para footprint.
- Pooling por app (para no exceder 80 conexiones): Backstage 15/5; SonarQube 20/5; Argo Workflows 10/5; Policy Reporter 5/2; Grafana 10/5; Dex 5/2. Total máx ≈65 dejando margen a autovacuum.
- Límites/pods orientativos para caber en ~12Gi clúster:
  - SonarQube: CPU 800m–1 vCPU; RAM 768Mi–1Gi; `sonar.search.javaAdditionalOpts=-Xms512m -Xmx512m`; `ce.task.maxWorkers=1–2`.
  - Backstage: CPU 300–400m; RAM 512–768Mi; `NODE_OPTIONS=--max-old-space-size=384`; pool DB 15/5.
  - Argo Workflows controller/server: CPU 100–250m cada uno; RAM 256–384Mi cada uno; `controller.parallelism=5–8`.
  - Grafana: CPU 150–200m; RAM 256Mi; pool 10/5.
  - Policy Reporter: CPU 100m; RAM 128–192Mi; pool 5/2.
  - Dex: CPU 50–100m; RAM 128Mi; pool 5/2.
  - Postgres: según arriba (1–1.5Gi).
  - Observabilidad (prometheus/grafana/loki/fluent-bit) ajustar retención y scrape a 30–60s para no pasar de presupuesto.

## Riesgos/mitigaciones
- Contención de conexiones: aplicar `pgbouncer` solo si aparece, no inicial. Limitar pools en apps.
- Ventana de soporte: el cluster sólo necesita cero fallos garantizados 6h y funcionamiento aceptable hasta 24h; priorizar configuraciones conservadoras y TTLs cortos (Argo archive, Prometheus) para evitar crecimiento entre recycles.
- Falta de orden: usar readiness/healthchecks hacia DB antes de migraciones y sync-waves estrictas.
- Fallas por ausencia de secret: asegurar ESO wave previa. Apps pueden fallback a Pending hasta que secret exista.
- Despliegues parciales: DB siempre presente si cualquier fuse on; roles existen aunque el stack esté off, no rompe.
- Migración de datos existente: definir export/import por app (pendiente) antes de cortar a la DB compartida.

## Pros y contras (demo <24h, orientación enterprise)
Pros:
- Un solo endpoint DB: facilita observabilidad, parches y eventual reemplazo por un Postgres gestionado externo cambiando solo host/secret.
- Coherencia de concurrencia y transacciones (SQLite fuera): menor riesgo de locks/corrupción en Grafana/Policy Reporter/Dex.
- Menos Pods de base de datos que administrar (frente a múltiples instancias por app).
- Argo Workflows puede offloadear historial fuera de etcd, mejorando consultas y orden del API server.
Contras:
- Huella mayor que SQLite y que dos Postgres pequeños (+0.2–0.4 Gi RAM vs multi-DB “todo activo”).
- IO concentrado en un solo PVC/host; compite con Prometheus/Loki en el mismo SSD.
- Más riesgo de contención si pools no se limitan; offload de Argo aumenta WAL/IO.
- Sin HA/backups de momento (tradeoff demo).

## Estrategia de migración/configuración (GitOps + Task)
1) Introducir `IT/database/` con HelmRelease/manifest para `shared-postgresql` (wave 0) y Job init de roles/DB (wave 0/1).
2) ExternalSecrets por componente (wave 1) apuntando a `secret/<stack>/<app>/postgres`.
3) Ajustar values de cada chart a “DB externa” (desactivar subchart Postgres, pools bajos, `statement_timeout` si aplica).
4) ArgoCD sync-waves: DB -> init Job -> ESO -> apps. Añadir probes de DB (`pg_isready`/`psql`) en apps pesadas (SonarQube, Argo Workflows).
5) Task: actualizar pipeline para incluir database chart antes de stacks; asegurar que `task deploy` respete el orden (bootstrap primero).
6) Durante despliegue: vigilar contención de conexiones; si crash-loop por DB no lista, aumentar `startupProbe` y `initialDelay` en apps.

## AUDITORÍA: Validación contra documentación oficial (2025-12-16)

### Componentes con beneficio REAL y justificado:
✅ **Backstage**: PostgreSQL es MANDATORIO para producción. SQLite solo para dev/demos con reset en cada restart.
✅ **SonarQube**: PostgreSQL 13-17 es el backend oficial soportado. Necesario para persistencia de análisis.

### Componentes con beneficio CUESTIONABLE para demo <24h:
⚠️ **Argo Workflows**: Archive solo guarda historial de ejecuciones (NO logs). Con TTL 1-2h en demo, poco valor.
⚠️ **Policy Reporter**: PostgreSQL reduce presión etcd solo con alto volumen de PolicyReports. En demo con pocas políticas, SQLite suficiente.

### Componentes SIN beneficio justificado para este contexto:
❌ **Grafana**: Beneficio principal es HA multi-instancia. Plan propone 1 instancia = NO aporta valor vs SQLite.
❌ **Dex**: PostgreSQL aporta escalabilidad/persistencia. Demo usa usuarios estáticos en ConfigMap = innecesario.

### IMPACTO RECURSOS verificado en cluster actual (2025-12-16):
- Estado: backstage-postgresql-0 + sonarqube-postgresql-0 corriendo (2 instancias separadas)
- Memoria cluster: agent-0 89% (3755Mi/4Gi), agent-1 70%, server-0 58%
- Plan propone +600Mi RAM adicional en cluster ya al límite
- Contradice objetivo "footprint reducido" para demo <24h del project overview

### RECOMENDACIÓN ARQUITECTURAL:
**Opción pragmática**: PostgreSQL compartido SOLO para Backstage + SonarQube (componentes con justificación técnica real)
- Recursos ajustados: 500m/768Mi request, 1vCPU/1.2Gi limit, PVC 10Gi
- Ahorra ~300-400Mi RAM vs plan completo de 6 componentes
- Mantiene "orientación enterprise" donde tiene sentido técnico real
- Omitir: Grafana (sin HA), Dex (usuarios estáticos), Argo archive (TTL cortos), Policy Reporter (bajo volumen)

## Impactos/consideraciones adicionales
- Alivio en etcd por Argo archive es moderado; no compensa el costo en Postgres, pero mejora consultas/historial.
- SSD único: mantener `max_wal_size` bajo y retenciones cortas en Prometheus/Loki para evitar picos IO coincidentes.
- Sin buckets externos: TTL agresiva en Argo archive, housekeeping de SonarQube; retención Prometheus 1–2 días.
- Futuro cloud DB: con host/sslmode en secrets, el switch sería cambiar endpoint/credenciales manteniendo los mismos charts/values.
