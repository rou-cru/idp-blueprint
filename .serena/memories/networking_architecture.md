# Networking Architecture (validated 2025-12-27)

## Gateway & exposure (repo + cluster)
- Gateway API with Cilium as controller.
- GatewayClass **`cilium-nodeport`** uses `CiliumGatewayClassConfig` set to `service.type: NodePort` (`IT/gateway/gatewayclass.yaml`).
- `idp-gateway` (namespace `kube-system`) uses `gatewayClassName: cilium-nodeport` and wildcard hostname `*.${DNS_SUFFIX}`.
- Cilium creates the gateway Service and it is patched to NodePorts **30080/30443** (`IT/gateway/patch/gateway-service-patch.yaml`).
- Cluster check: Service `cilium-gateway-idp-gateway` is NodePort `30080/30443`.

## DNS & TLS
- `.env` generated from `config.toml` via `Scripts/generate-env.sh`; computes `DNS_SUFFIX=<LAN_IP>.nip.io`.
- Certificate chain: self-signed → `ca-issuer` → wildcard `idp-wildcard-cert` (`IT/gateway/idp-wildcard-cert.yaml`).
- TLS permission granted to Cilium (`IT/gateway/gateway-tls-permission.yaml`).
- Cluster check: `idp-wildcard-cert` is **Ready=True**.

## HTTPRoutes (cluster)
- Routes present: argo-events, argocd, backstage, dex, argo-workflows, sonarqube, grafana, pyrra, vault-ui, plus http→https redirect.
- Hostnames are `*.${DNS_SUFFIX}` derived from `.env`.

## Backstage config rendering (repo)
- `K8s/backstage/backstage/templates/cm-tpl.yaml` contains `${DNS_SUFFIX}` placeholders.
- Job `backstage-config-renderer` renders `app-config.override.yaml` from `idp-vars-backstage` and replaces the override ConfigMap.
- Placeholder ConfigMap (`cm-placeholder.yaml`) exists for initial ArgoCD sync.

## k3d vs production
- k3d: NodePort + host port mapping; no LoadBalancer/L2 announcements.
- Production: switch GatewayClass to LoadBalancer and enable L2 announcements/MetalLB; set fixed domain instead of nip.io.
