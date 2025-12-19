# Shared Redis Migration Plan

Goal: Consolidar el uso de Redis en una sola instancia gestionada por nosotros (o fácilmente reemplazable por un endpoint externo) en vez de la instancia embebida del chart de ArgoCD. Mantener footprint bajo para un clúster demo (<24h), pero con patrón enterprise (único endpoint cacheable por varios servicios).

## Posibles consumidores y estado actual
- **ArgoCD**: usa Redis single-instance desplegada por su chart (IT/argocd/values.yaml). Compatible con Redis externo vía valores `redis.enabled=false` + campos de Redis externo (en chart oficial 8.6.0: `redis.url` o `externalRedis.*` / `redis-ha.enabled`). Necesita redis para session/cache del API/server/controller.
- **Backstage**: por defecto cache en memoria; puede usar Redis (`backend.cache.store: redis`, `connection.{host,port,tls}`) para caching de plugins/catalog/permissions. No configurado hoy.
- Otros stacks (SonarQube, Argo Workflows, Grafana, Policy Reporter, Dex, Kyverno, Prometheus, Loki, Vault, ESO): no requieren Redis en sus charts oficiales ni en nuestros values.
- UI/Docs lockfiles contienen libs de Redis (upstash/ioredis) pero la entrega en k8s no las usa.

## Topología y GitOps
- Namespace sugerido: `cache` (bootstrap). Recurso: StatefulSet `shared-redis` + Service `shared-redis` ClusterIP.
- GitOps: carpeta `IT/cache/` con HelmRelease/manifest; sync-wave 0 antes de ArgoCD/Backstage.
- Secrets: Vault/ESO para password (`secret/cache/redis`), montado en cada consumidor.

## Config por componente
- **ArgoCD** (chart 8.6.0):
  - Desactivar redis embebido: `redis.enabled=false` (o `redis-ha.enabled=false`).
  - Apuntar a externo: valores `externalRedis.host`, `externalRedis.port`, `externalRedis.password`, `externalRedis.db`, `externalRedis.useSSL` (nomenclatura según chart upstream); o usar `redis.url` si disponible en esta versión.
  - Asegurar vars/CM: `ARGOCD_REDIS_PASSWORD`, `ARGOCD_REDIS_ADDRESS` propagados a server/repo/controller/appset/notifications.
  - Resources actuales del redis embebido: requests 100m/128Mi, limits 250m/256Mi; se eliminan al migrar.
- **Backstage**:
  - En `app-config`: `backend.cache.store=redis`; `backend.cache.connection.host=shared-redis.cache.svc.cluster.local`, `port=6379`, `tls=false`, `password` desde secret; opcional `database` para namespaces.
  - Chart no trae redis propio, sólo se añaden env/values; sin persistencia requerida (caché).

## Recursos propuestos Redis único (demo <24h, carga baja)
- Requests: 100m CPU / 128Mi RAM; Limits: 300m / 256–384Mi.
- Persistence opcional: desactivada para demo (cache). Si se quiere durabilidad mínima, PVC 1–2Gi.
- `maxmemory-policy`: `allkeys-lru`; `maxmemory` acorde a límite (p.ej. 192Mi) para evitar OOM.
- Conexiones: default 10k; suficiente. TLS off en demo.

## Pros
- Un solo endpoint reutilizable por ArgoCD y futuras caches (Backstage). Fácil de apuntar a un Redis gestionado cloud cambiando host/secret.
- Menos pods “infra” (se elimina redis embebido del chart ArgoCD).
- Comportamiento coherente y mejor caching que memoria local (Backstage).

## Contras / impactos
- Punto único de falla (sin HA/sentinel); aceptable para demo <24h.
- IO/CPU adicional frente a in-memory Backstage, pero pequeño.
- Necesidad de mantener secret y onda de despliegue correcta para ArgoCD (sin redis no arranca).

## Orden de despliegue
1) Deploy `shared-redis` (wave 0) en `cache`.
2) ESO secrets de password en `argocd`, `backstage` (wave 1).
3) ArgoCD y Backstage config apuntando a Redis externo (wave 2).

## Riesgos/mitigaciones
- **No arranque de ArgoCD**: si Redis no está listo o secret falta → usar probes en Redis y sync-waves estrictas.
- **OOM Redis**: fijar `maxmemory` y política LRU; límites de 256–384Mi.
- **Contención**: improbable con carga demo; si aparece, subir a 512Mi o habilitar persistence para evitar RDB fsync picos.

## AUDITORÍA: Validación contra documentación oficial (2025-12-16)

### Redis para ArgoCD:
⚠️ **Beneficio de Redis externo**: Facilita HA con múltiples replicas ArgoCD servidor/controller
- ArgoCD usa Redis para caché de recursos K8s, estados conexión, Git repos (crítico pero volátil)
- CONTEXTO DEMO verificado: 1 sola instancia ArgoCD corriendo (argocd-redis-d9589dffd-c2lkj)
- **CONCLUSIÓN**: Redis compartido NO aporta beneficio vs Redis embebido sin HA

### Redis para Backstage:
⚠️ **Beneficio de Redis**: Ayuda multi-nodo y evita OOM con muchos usuarios concurrentes
- Docs reportan OOM con 4GB RAM en producción multi-usuario
- Redis permite coordinación multi-nodo y job deduplication
- CONTEXTO DEMO verificado: 1 instancia Backstage, cache memory con TTL 10min (ConfigMap)
- **CONCLUSIÓN**: Redis solo beneficia deployment multi-nodo que NO TENEMOS

### IMPACTO RECURSOS verificado:
- Redis ArgoCD actual: 100m/128Mi request, 250m/256Mi limit (embebido funciona bien)
- Plan Redis compartido: 100m/128Mi request, 300m/384Mi limit
- Incremento neto: +128Mi limit sin beneficio funcional en demo single-instance

### RECOMENDACIÓN:
**Mantener status quo**: Redis embebido en ArgoCD suficiente para demo sin HA
- Si en futuro se requiere HA ArgoCD (múltiples replicas), entonces migrar a Redis compartido/externo
- Backstage: activar Redis solo si se escala a múltiples pods (no aplica en demo)
- **NO implementar Redis compartido para demo actual**: añade complejidad sin beneficio medible

## Futuro switch a Redis gestionado (cloud)
- Mantener host/port/password en secret; con cambiar secret/Service se redirige sin tocar charts.
- NetworkPolicies/egress se añadirían más adelante; no en alcance demo.
