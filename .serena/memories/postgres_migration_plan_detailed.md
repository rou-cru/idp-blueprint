# Plan Detallado de Migración: PostgreSQL Compartido
## Para: Backstage + SonarQube + Argo Workflows

**Fecha:** 2025-12-16  
**Alcance:** Migración de 2 instancias PostgreSQL separadas + preparación Argo Workflows → 1 instancia compartida  
**Contexto:** Demo <24h, orientación enterprise, resources limitados (~12Gi cluster)

---

## 1. DECISIÓN CONDICIONAL DE DESPLIEGUE

### 1.1 Lógica basada en config.toml fuses

```toml
[fuses]
backstage = true|false
cicd = true|false
```

**Tabla de verdad para deploy database:**

| backstage | cicd | ¿Deploy PostgreSQL? | DBs a crear |
|-----------|------|-------------------|-------------|
| false     | false | **NO** | ninguna |
| true      | false | **SÍ** | backstage |
| false     | true | **SÍ** | sonarqube, argo_workflows |
| true      | true | **SÍ** | backstage, sonarqube, argo_workflows |

**Regla:**  
```bash
DEPLOY_POSTGRES=$(dasel -r toml -f config.toml fuses.backstage -w - || dasel -r toml -f config.toml fuses.cicd -w -)
```

### 1.2 Decisión en Task automation

**Ubicación:** `Task/bootstrap.yaml` nuevo task `database:deploy`

```yaml
database:deploy:
  desc: "Deploy shared PostgreSQL (conditional)"
  vars:
    BACKSTAGE_ENABLED:
      sh: ./Scripts/config-get.sh fuses.backstage
    CICD_ENABLED:
      sh: ./Scripts/config-get.sh fuses.cicd
  preconditions:
    - sh: 'test "{{.BACKSTAGE_ENABLED}}" = "true" || test "{{.CICD_ENABLED}}" = "true"'
      msg: "Skipping PostgreSQL: both backstage and cicd fuses are false"
  cmds:
    - kubectl apply -k IT/database/
    - task: database:wait-ready
    - task: database:init-schemas
```

---

## 2. ESTRUCTURA GitOps

### 2.1 Nueva carpeta IT/database/

```
IT/database/
├── kustomization.yaml          # Orquesta todo el stack
├── namespace.yaml              # Namespace database (wave -3)
├── postgresql-statefulset.yaml # PostgreSQL StatefulSet (wave -2)
├── postgresql-service.yaml     # Service ClusterIP (wave -2)
├── postgresql-configmap.yaml   # Configuración PG (wave -2)
├── init-job.yaml               # Job creación DBs/roles (wave -1)
├── init-configmap.yaml         # Script SQL init (wave -1)
└── README.md                   # Documentación

K8s/backstage/backstage/
├── postgresql-externalsecret.yaml  # ESO para credentials (wave -1)
└── values.yaml                     # postgresql.enabled=false

K8s/cicd/infrastructure/
├── postgresql-externalsecret.yaml  # ESO para SonarQube + Argo (wave -1)

K8s/cicd/sonarqube/
└── values.yaml                     # postgresql.enabled=false, jdbcOverwrite

K8s/cicd/argo-workflows/
└── values.yaml                     # controller.persistence.archive=true
```

### 2.2 Sync Waves explicadas

```
Wave -3: namespace database
  ↓
Wave -2: PostgreSQL StatefulSet + Service + ConfigMap
  ↓ (esperar PostgreSQL ready)
Wave -1: init-job (crea DBs/roles) + ExternalSecrets
  ↓ (esperar secrets sincronizados)
Wave  0: Backstage/SonarQube/ArgoWorkflows despliegan
```

**Rationale:**
- `-3` namespace primero (dependencia de todo)
- `-2` PostgreSQL antes que consumidores
- `-1` init + secrets antes que apps
- `0` apps consumen DB ya lista

---

## 3. ESPECIFICACIÓN TÉCNICA PostgreSQL

### 3.1 Configuración StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: shared-postgresql
  namespace: database
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
spec:
  serviceName: shared-postgresql
  replicas: 1  # Sin HA en demo
  selector:
    matchLabels:
      app: shared-postgresql
  template:
    metadata:
      labels:
        app: shared-postgresql
    spec:
      priorityClassName: platform-infrastructure
      containers:
      - name: postgresql
        image: postgres:15.4  # Compatible SonarQube 13-17
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-superuser
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        resources:
          requests:
            cpu: 500m
            memory: 768Mi
          limits:
            cpu: "1"
            memory: 1200Mi
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: config
          mountPath: /etc/postgresql
        livenessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres"]
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres"]
          initialDelaySeconds: 5
          periodSeconds: 5
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### 3.2 Configuración postgresql.conf

```ini
# IT/database/postgresql-configmap.yaml (montado en /etc/postgresql/)
max_connections = 60
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 4MB
wal_buffers = 16MB
max_wal_size = 1GB
checkpoint_timeout = 15min
random_page_cost = 1.1  # SSD
effective_io_concurrency = 200
default_statistics_target = 100
statement_timeout = 30s
```

### 3.3 Job inicialización

```yaml
# IT/database/init-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-init
  namespace: database
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
    argocd.argoproj.io/hook: Sync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  backoffLimit: 3
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: init
        image: postgres:15.4
        command: ["/bin/bash", "/scripts/init.sh"]
        env:
        - name: PGHOST
          value: shared-postgresql.database.svc.cluster.local
        - name: PGPORT
          value: "5432"
        - name: POSTGRES_SUPERUSER_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-superuser
              key: password
        volumeMounts:
        - name: init-scripts
          mountPath: /scripts
      volumes:
      - name: init-scripts
        configMap:
          name: postgresql-init-scripts
          defaultMode: 0755
```

**Script init.sh:**
```bash
#!/bin/bash
set -euo pipefail

export PGPASSWORD="$POSTGRES_SUPERUSER_PASSWORD"

# Función idempotente: crear DB si no existe
create_database() {
  local dbname=$1
  psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$dbname'" | grep -q 1 || \
    psql -U postgres -c "CREATE DATABASE $dbname"
}

# Función idempotente: crear role si no existe
create_role() {
  local rolename=$1
  local password=$2
  psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '$rolename'" | grep -q 1 || \
    psql -U postgres -c "CREATE ROLE $rolename WITH LOGIN PASSWORD '$password'"
}

# Grant privileges
grant_privileges() {
  local dbname=$1
  local rolename=$2
  psql -U postgres -d "$dbname" -c "GRANT ALL PRIVILEGES ON DATABASE $dbname TO $rolename"
  psql -U postgres -d "$dbname" -c "GRANT ALL ON SCHEMA public TO $rolename"
}

echo "Initializing databases..."

# Backstage
create_database "backstage"
create_role "backstage" "$BACKSTAGE_PASSWORD"
grant_privileges "backstage" "backstage"

# SonarQube
create_database "sonarqube"
create_role "sonarqube" "$SONARQUBE_PASSWORD"
grant_privileges "sonarqube" "sonarqube"

# Argo Workflows
create_database "argo_workflows"
create_role "argo_workflows" "$ARGO_WORKFLOWS_PASSWORD"
grant_privileges "argo_workflows" "argo_workflows"
# Argo necesita permisos CREATE en schema público
psql -U postgres -d "argo_workflows" -c "GRANT CREATE ON SCHEMA public TO argo_workflows"

echo "Database initialization complete"
```

---

## 4. INTEGRACIÓN VAULT + ExternalSecrets

### 4.1 Secrets requeridos

**Vault paths:**
```
secret/database/superuser          → password (PostgreSQL root)
secret/backstage/postgres          → password (app user)
secret/cicd/sonarqube-postgres     → password (app user)
secret/cicd/argo-workflows-postgres → password (app user)
```

### 4.2 Generación en Task

```yaml
# Task/bootstrap.yaml - ampliar vault-generate-secrets
vault-generate-secrets:
  vars:
    SECRETS:
      - path: secret/database/superuser
        key: password
        var: POSTGRES_SUPERUSER_PASSWORD
        enc: base64
        hash: none
      - path: secret/backstage/postgres
        key: password
        var: BACKSTAGE_POSTGRES_PASSWORD
        enc: base64
        hash: none
      - path: secret/cicd/sonarqube-postgres
        key: password
        var: SONARQUBE_POSTGRES_PASSWORD
        enc: base64
        hash: none
      - path: secret/cicd/argo-workflows-postgres
        key: password
        var: ARGO_WORKFLOWS_POSTGRES_PASSWORD
        enc: base64
        hash: none
```

### 4.3 ExternalSecret Backstage

```yaml
# K8s/backstage/backstage/postgresql-externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: backstage-postgresql
  namespace: backstage
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: backstage-secretstore
    kind: SecretStore
  target:
    name: backstage-postgresql
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: secret/backstage/postgres
      property: password
```

**Ajustar values.yaml:**
```yaml
# K8s/backstage/backstage/values.yaml
postgresql:
  enabled: false  # Desactivar subchart

appConfig:
  backend:
    database:
      client: pg
      connection:
        host: shared-postgresql.database.svc.cluster.local
        port: 5432
        user: backstage
        database: backstage
        password: ${POSTGRES_PASSWORD}  # Desde secret
        ssl:
          enabled: false
      pool:
        min: 5
        max: 15
```

### 4.4 ExternalSecret SonarQube

```yaml
# K8s/cicd/infrastructure/sonarqube-postgresql-externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: sonarqube-postgresql
  namespace: cicd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: cicd-secretstore
    kind: SecretStore
  target:
    name: sonarqube-postgresql
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: secret/cicd/sonarqube-postgres
      property: password
```

**Ajustar values.yaml:**
```yaml
# K8s/cicd/sonarqube/values.yaml
postgresql:
  enabled: false  # Desactivar subchart

jdbcOverwrite:
  enable: true
  jdbcUrl: jdbc:postgresql://<shared-postgresql-host>:5432/sonarqube
  jdbcUsername: sonarqube
  jdbcSecretName: sonarqube-postgresql
  jdbcSecretPasswordKey: password

sonarqube:
  env:
  - name: sonar.jdbc.maxActive
    value: "20"
```

### 4.5 ExternalSecret + Config Argo Workflows

```yaml
# K8s/cicd/infrastructure/argo-workflows-postgresql-externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argo-workflows-postgresql
  namespace: cicd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: cicd-secretstore
    kind: SecretStore
  target:
    name: argo-workflows-postgresql
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: secret/cicd/argo-workflows-postgres
      property: username
      default: argo_workflows
  - secretKey: password
    remoteRef:
      key: secret/cicd/argo-workflows-postgres
      property: password
```

**Ajustar values.yaml:**
```yaml
# K8s/cicd/argo-workflows/values.yaml
controller:
  persistence:
    archive: true
    postgresql:
      host: shared-postgresql.database.svc.cluster.local
      port: 5432
      database: argo_workflows
      tableName: argo_archived_workflows
      userNameSecret:
        name: argo-workflows-postgresql
        key: username
      passwordSecret:
        name: argo-workflows-postgresql
        key: password
      sslMode: disable
  workflowDefaults:
    spec:
      ttlStrategy:
        secondsAfterCompletion: 3600
        secondsAfterSuccess: 1800
        secondsAfterFailure: 7200
```

---

## 5. MIGRACIÓN DE DATOS EXISTENTES

### 5.1 Backstage (tiene datos activos)

**Pre-migración: Export desde SQLite embebido actual**

```bash
# Script: Scripts/migrate-backstage-db.sh
#!/bin/bash
set -euo pipefail

echo "Exporting Backstage data from current PostgreSQL..."
kubectl exec -n backstage backstage-postgresql-0 -- \
  pg_dump -U postgres backstage > /tmp/backstage-export.sql

echo "Waiting for shared PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=shared-postgresql -n database --timeout=60s

echo "Importing into shared PostgreSQL..."
kubectl exec -n database shared-postgresql-0 -i -- \
  psql -U backstage backstage < /tmp/backstage-export.sql

echo "Migration complete"
rm /tmp/backstage-export.sql
```

**Integrar en Task:**
```yaml
# Task/bootstrap.yaml
database:migrate-backstage:
  desc: "Migrate Backstage data to shared PostgreSQL"
  preconditions:
    - sh: kubectl get statefulset backstage-postgresql -n backstage
      msg: "Source Backstage PostgreSQL not found"
    - sh: kubectl get statefulset shared-postgresql -n database
      msg: "Target shared PostgreSQL not ready"
  cmds:
    - ./Scripts/migrate-backstage-db.sh
```

### 5.2 SonarQube (tiene datos activos)

```bash
# Script: Scripts/migrate-sonarqube-db.sh
#!/bin/bash
set -euo pipefail

echo "Exporting SonarQube data..."
kubectl exec -n cicd sonarqube-postgresql-0 -- \
  pg_dump -U postgres sonarqube > /tmp/sonarqube-export.sql

echo "Importing into shared PostgreSQL..."
kubectl exec -n database shared-postgresql-0 -i -- \
  psql -U sonarqube sonarqube < /tmp/sonarqube-export.sql

echo "SonarQube migration complete"
rm /tmp/sonarqube-export.sql
```

### 5.3 Argo Workflows (no tiene datos, está desactivado)

**NO requiere migración** - archive se activará desde cero cuando se despliegue.

---

## 6. ORDEN DE EJECUCIÓN COMPLETO

### 6.1 Flujo Task deploy (nuevo)

```yaml
# Taskfile.yaml - actualizar deploy-core
deploy-core:
  cmds:
    # ... pasos existentes bootstrap ...
    - task: bootstrap:it:apply-namespaces  # Incluye database namespace
    - task: bootstrap:it:apply-priorityclasses
    - task: bootstrap:it:apply-cert-manager
    - task: bootstrap:it:apply-cilium
    - task: bootstrap:it:apply-gateway
    - task: bootstrap:it:apply-vault
    - task: bootstrap:vault:init
    - task: bootstrap:vault:generate-secrets  # Ahora incluye DB secrets
    - task: bootstrap:it:apply-external-secrets
    
    # NUEVO: Deploy PostgreSQL condicional
    - task: bootstrap:database:deploy
    
    - task: bootstrap:it:apply-argocd
    - task: bootstrap:argocd:wait-ready
    - task: bootstrap:argocd:login
    
    # NUEVO: Migrar datos ANTES de cambiar apps
    - task: bootstrap:database:migrate-data
    
    # Stacks (usan nueva DB)
    - task: stacks:deploy-bootstrap
    - task: stacks:sync-all
```

### 6.2 Detalle database:deploy

```yaml
# Task/bootstrap.yaml
database:deploy:
  desc: "Deploy shared PostgreSQL (conditional)"
  vars:
    BACKSTAGE_ENABLED:
      sh: ./Scripts/config-get.sh fuses.backstage
    CICD_ENABLED:
      sh: ./Scripts/config-get.sh fuses.cicd
  preconditions:
    - sh: 'test "{{.BACKSTAGE_ENABLED}}" = "true" || test "{{.CICD_ENABLED}}" = "true"'
      msg: "Skipping PostgreSQL: both fuses are false"
  cmds:
    - echo "Deploying shared PostgreSQL..."
    - kubectl apply -k IT/database/
    - task: database:wait-ready
    - task: database:init-schemas

database:wait-ready:
  desc: "Wait for PostgreSQL to be ready"
  cmds:
    - |
      kubectl wait --for=condition=ready pod \
        -l app=shared-postgresql \
        -n database \
        --timeout=180s
    - |
      kubectl exec -n database shared-postgresql-0 -- \
        pg_isready -U postgres

database:init-schemas:
  desc: "Initialize database schemas"
  cmds:
    - kubectl wait --for=condition=complete job/postgresql-init -n database --timeout=120s
    - echo "Database schemas initialized"

database:migrate-data:
  desc: "Migrate existing data to shared PostgreSQL"
  vars:
    BACKSTAGE_ENABLED:
      sh: ./Scripts/config-get.sh fuses.backstage
    CICD_ENABLED:
      sh: ./Scripts/config-get.sh fuses.cicd
  cmds:
    - |
      if [ "{{.BACKSTAGE_ENABLED}}" = "true" ]; then
        task: database:migrate-backstage
      fi
    - |
      if [ "{{.CICD_ENABLED}}" = "true" ]; then
        task: database:migrate-sonarqube
      fi
```

---

## 7. ESTRATEGIA DE ROLLBACK

### 7.1 Snapshot pre-migración

```bash
# Antes de migrar, crear backups
kubectl exec -n backstage backstage-postgresql-0 -- \
  pg_dump -U postgres backstage | gzip > backstage-backup-$(date +%Y%m%d-%H%M%S).sql.gz

kubectl exec -n cicd sonarqube-postgresql-0 -- \
  pg_dump -U postgres sonarqube | gzip > sonarqube-backup-$(date +%Y%m%d-%H%M%S).sql.gz
```

### 7.2 Rollback steps

```bash
# 1. Revertir values.yaml de apps (postgresql.enabled=true)
git revert <commit-sha-migration>

# 2. ArgoCD sync apps (volverán a desplegar sus DBs embebidas)
argocd app sync backstage-backstage
argocd app sync cicd-sonarqube

# 3. Restaurar datos
kubectl exec -n backstage backstage-postgresql-0 -i -- \
  psql -U postgres backstage < backstage-backup-YYYYMMDD-HHMMSS.sql

# 4. Eliminar shared PostgreSQL
kubectl delete -k IT/database/
```

### 7.3 Contingencia: PostgreSQL no arranca

```bash
# Si shared-postgresql no alcanza ready state:
# 1. Revisar logs
kubectl logs -n database shared-postgresql-0

# 2. Verificar PVC
kubectl get pvc -n database

# 3. Si falla init-job, revisar logs y reintent ar
kubectl delete job postgresql-init -n database
kubectl apply -f IT/database/init-job.yaml

# 4. Rollback si no se resuelve
```

---

## 8. VALIDACIÓN POST-MIGRACIÓN

### 8.1 Checklist PostgreSQL

```bash
# 1. PostgreSQL corriendo
kubectl get pods -n database
# Esperar: shared-postgresql-0   1/1     Running

# 2. Databases creadas
kubectl exec -n database shared-postgresql-0 -- psql -U postgres -c "\l"
# Verificar: backstage, sonarqube, argo_workflows

# 3. Roles creados
kubectl exec -n database shared-postgresql-0 -- psql -U postgres -c "\du"
# Verificar: backstage, sonarqube, argo_workflows

# 4. Conexiones activas
kubectl exec -n database shared-postgresql-0 -- \
  psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname"
```

### 8.2 Checklist aplicaciones

```bash
# Backstage
kubectl get pods -n backstage
kubectl logs -n backstage -l app.kubernetes.io/name=backstage --tail=50 | grep -i "database\|postgres"
curl -f https://backstage.${DNS_SUFFIX}/healthcheck

# SonarQube
kubectl get pods -n cicd -l app.kubernetes.io/name=sonarqube
kubectl logs -n cicd -l app.kubernetes.io/name=sonarqube --tail=50 | grep -i "database\|postgres"
curl -f https://sonarqube.${DNS_SUFFIX}/api/system/status

# Argo Workflows (si desplegado)
kubectl get pods -n cicd -l app.kubernetes.io/name=argo-workflows
kubectl logs -n cicd argo-workflow-controller-* --tail=50 | grep -i "archive\|postgres"
```

### 8.3 Tests funcionales

```bash
# Backstage: crear/editar componente en catálogo
# SonarQube: ejecutar análisis de código
# Argo Workflows: ejecutar workflow y verificar archive
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: test-archive-
  namespace: cicd
spec:
  entrypoint: main
  templates:
  - name: main
    container:
      image: alpine:latest
      command: [echo, "Testing archive"]
EOF

# Verificar en PostgreSQL
kubectl exec -n database shared-postgresql-0 -- \
  psql -U argo_workflows argo_workflows -c \
  "SELECT name, phase FROM argo_archived_workflows LIMIT 5"
```

---

## 9. MONITOREO Y OBSERVABILIDAD

### 9.1 ServiceMonitor para PostgreSQL

```yaml
# IT/database/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: shared-postgresql
  namespace: database
  labels:
    prometheus: kube-prometheus
spec:
  selector:
    matchLabels:
      app: shared-postgresql
  endpoints:
  - port: metrics
    interval: 30s
```

### 9.2 Alertas críticas

```yaml
# PrometheusRule for database alerts
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: postgresql-alerts
  namespace: database
spec:
  groups:
  - name: postgresql
    rules:
    - alert: PostgreSQLDown
      expr: up{job="shared-postgresql"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "PostgreSQL instance down"
    
    - alert: PostgreSQLTooManyConnections
      expr: sum(pg_stat_activity_count) > 50
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "PostgreSQL approaching max_connections (60)"
    
    - alert: PostgreSQLHighDiskUsage
      expr: (pg_database_size_bytes / 10737418240) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "PostgreSQL disk usage > 80% of 10Gi PVC"
```

---

## 10. DOCUMENTACIÓN Y RUNBOOKS

### 10.1 README para IT/database/

```markdown
# Shared PostgreSQL Database

## Overview
Single PostgreSQL instance serving Backstage, SonarQube, and Argo Workflows.

## Databases
- `backstage`: Backstage catalog and state
- `sonarqube`: SonarQube analysis data
- `argo_workflows`: Argo Workflows archive

## Connection strings
- Host: `shared-postgresql.database.svc.cluster.local`
- Port: `5432`
- Credentials: Vault via ExternalSecrets

## Operations
- **Backup**: `kubectl exec -n database shared-postgresql-0 -- pg_dump ...`
- **Restore**: `kubectl exec -n database shared-postgresql-0 -i -- psql ...`
- **Logs**: `kubectl logs -n database shared-postgresql-0`
- **Shell**: `kubectl exec -it -n database shared-postgresql-0 -- psql -U postgres`

## Troubleshooting
See: docs/runbooks/postgresql-troubleshooting.md
```

### 10.2 Runbook troubleshooting común

```markdown
# PostgreSQL Troubleshooting

## Pod no arranca
1. Check PVC: `kubectl get pvc -n database`
2. Check logs: `kubectl logs -n database shared-postgresql-0`
3. Check node resources: `kubectl top nodes`

## App no conecta a DB
1. Verify secret exists: `kubectl get secret -n <namespace> <app>-postgresql`
2. Test connectivity: `kubectl run -it --rm debug --image=postgres:15 --restart=Never -- psql -h shared-postgresql.database.svc.cluster.local -U <user> <database>`
3. Check firewall/NetworkPolicy

## Slow queries
1. Check connections: `kubectl exec -n database shared-postgresql-0 -- psql -U postgres -c "SELECT * FROM pg_stat_activity"`
2. Check indexes: `kubectl exec -n database shared-postgresql-0 -- psql -U postgres -d <database> -c "\di"`
3. Analyze query plans: Enable `log_min_duration_statement = 1000` in configmap

## Out of disk space
1. Check PVC: `kubectl exec -n database shared-postgresql-0 -- df -h /var/lib/postgresql/data`
2. Cleanup old data (Argo archive): Run archiveTTL cleanup
3. Expand PVC: Edit pvc/data-shared-postgresql-0 (if supported by storage class)
```

---

## 11. ESTIMACIÓN DE ESFUERZO

| Fase | Tiempo estimado | Responsable |
|------|----------------|-------------|
| 1. Crear manifiestos IT/database/ | 2h | Platform Engineer |
| 2. Configurar Vault secrets | 30min | Platform Engineer |
| 3. Actualizar ExternalSecrets apps | 1h | Platform Engineer |
| 4. Actualizar values.yaml apps | 1h | Platform Engineer |
| 5. Testing en cluster limpio | 1h | Platform Engineer |
| 6. Crear scripts migración datos | 2h | Platform Engineer |
| 7. Ejecutar migración con downtime | 1h | Platform Engineer + Ops |
| 8. Validación post-migración | 1h | QA + Platform Engineer |
| 9. Documentación y runbooks | 1h | Platform Engineer |
| **TOTAL** | **10-11h** | |

**Downtime estimado:** 15-30 minutos (durante migración datos)

---

## 12. SIGUIENTES PASOS

1. ✅ Aprobar este plan técnico
2. ⬜ Crear branch `feature/shared-postgresql`
3. ⬜ Implementar manifiestos IT/database/
4. ⬜ Actualizar Task automation
5. ⬜ Testing en cluster dev
6. ⬜ Crear backups pre-migración
7. ⬜ Ejecutar migración en cluster target
8. ⬜ Validar y monitorear 24h
9. ⬜ Merge a main

---

**Validado:** 2025-12-16  
**Próxima revisión:** Antes de implementación
