# Networking Architecture (validated 2025-12-04)

## Resumen
- Gateway API v1 con Cilium como controlador; exposición por NodePort (k3d) + mapeo host 80→30080 y 443→30443 (`IT/k3d-cluster.yaml`).
- GatewayClass fuerza `service.type: NodePort` (`IT/gateway/gatewayclass.yaml`); Gateway `idp-gateway` en `kube-system` escucha `*.${DNS_SUFFIX}` en 80/443 con TLS terminado vía cert-manager (`IT/gateway/idp-gateway.yaml`).
- Cilium autogenera el Service; se parchea para fijar NodePorts 30080/30443 (`IT/gateway/patch/gateway-service-patch.yaml`) y se valida en `Task/bootstrap.yaml` líneas 271-279.
- Certificación: cadena self-signed -> `ca-issuer` -> wildcard `idp-wildcard-cert` con SAN `*.${DNS_SUFFIX}` (`IT/gateway/idp-wildcard-cert.yaml`); Cilium obtiene permiso de leer el Secret (`IT/gateway/gateway-tls-permission.yaml`).
- HTTPRoutes incluidas (10): argo-events, argo-workflows, argocd, backstage, dex, grafana, pyrra, sonarqube, vault, redirect-http-to-https (ver `IT/gateway/kustomization.yaml`). Redirect usa `sectionName: http` para 301 a HTTPS (`IT/gateway/httproutes/redirect-http-to-https.yaml`).

## Sustitución de variables
- `.env` se genera desde `Scripts/generate-env.sh` usando `config.toml`; calcula `LAN_IP` (auto si vacío), `DNS_SUFFIX=$(LAN_IP con puntos→guiones).nip.io`, `NODEPORT_HTTP/HTTPS` y los exporta.
- `task deploy` carga `.env` y pasa `DNS_SUFFIX` a todas las tareas. `bootstrap:gateway:deploy` hace `kustomize build . | envsubst | kubectl apply` y luego aplica el patch de NodePorts.
- ApplicationSet de Backstage y Dex reciben `DNS_SUFFIX`, `GITHUB_*`, `CLUSTER_NAME` vía patches en `K8s/backstage/applicationset-backstage.yaml`.

## Backstage (DNS_SUFFIX)
- Plantilla de config se almacena en ConfigMap `backstage-config-tpl` (`K8s/backstage/backstage/templates/cm-tpl.yaml`) con placeholders `${DNS_SUFFIX}` y otros.
- Job `backstage-config-renderer` (`K8s/backstage/backstage/job-renderer.yaml`) lee variables de ConfigMap `idp-vars-backstage` (patch con DNS_SUFFIX en el ApplicationSet) y renderiza `app-config.override.yaml` usando `envsubst`, reemplazando el ConfigMap `backstage-app-config-override` consumido por Helm (`values.yaml` `extraAppConfig`).
- ConfigMap placeholder inicial (`cm-placeholder.yaml`) existe solo para que ArgoCD pueda sincronizar antes de renderizar.

## Consideraciones k3d vs producción
- En k3d no se usan LoadBalancers ni L2 announcements (deshabilitado en `IT/cilium/values.yaml`); NodePort + host port mapping es la vía viable.
- Con DNS real/entornos prod se podría cambiar `service.type` a LoadBalancer y habilitar `l2announcements.enabled=true` o MetalLB, y reemplazar `DNS_SUFFIX` por dominio fijo; hoy el código sólo activa HA en ArgoCD cuando `fuses.prod=true` (`Task/bootstrap.yaml` 249-252).

## Diagnóstico rápido
- Comprobar Gateway y Service: `kubectl get gateway idp-gateway -n kube-system` y `kubectl get svc cilium-gateway-idp-gateway -n kube-system -o yaml | grep nodePort`.
- Ver cert: `kubectl describe certificate idp-wildcard-cert -n kube-system` y Secret permisos en `gateway-tls-permission.yaml`.
- Listar rutas: `kubectl get httproute -A` y verificar hostnames con `DNS_SUFFIX` de `.env` (`Scripts/generate-env.sh`).