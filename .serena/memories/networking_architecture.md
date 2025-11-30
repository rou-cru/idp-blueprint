# Networking Architecture: Gateway API + Dynamic GitOps

## Visión General

El proyecto usa **Gateway API v1** (no Ingress) con **Cilium** como controlador, combinando datos dinámicos (LAN IP) con manifests GitOps estáticos mediante **variable substitution** en tiempo de deployment.

### Stack de Red

```
k3d cluster
  └─> NodePort mapping (80:30080, 443:30443)
      └─> Gateway Service (cilium-gateway-idp-gateway)
          └─> Gateway (idp-gateway)
              └─> HTTPRoutes (argocd, grafana, vault, etc.)
                  └─> Backend Services
```

## Componentes Clave

### 1. k3d Cluster Configuration

**Archivo**: `IT/k3d-cluster.yaml`

```yaml
ports:
  - port: 80:${NODEPORT_HTTP}      # Host 80 -> Node 30080
    nodeFilters:
      - server:0
  - port: 443:${NODEPORT_HTTPS}    # Host 443 -> Node 30443
    nodeFilters:
      - server:0
```

**Variables substituidas**: `${NODEPORT_HTTP}`, `${NODEPORT_HTTPS}` desde `config.toml`
**Mecanismo**: `envsubst` en `Task/k3d.yaml:29`
**Deshabilitado**: Traefik (`--disable=traefik`) porque usamos Gateway API

### 2. GatewayClass + CiliumGatewayClassConfig

**Archivo**: `IT/gateway/gatewayclass.yaml`

```yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumGatewayClassConfig
metadata:
  name: cilium-nodeport-config
  namespace: kube-system
spec:
  service:
    type: NodePort  # Fuerza NodePort en vez de LoadBalancer
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: cilium-nodeport
spec:
  controllerName: io.cilium/gateway-controller
  parametersRef:
    kind: CiliumGatewayClassConfig
    name: cilium-nodeport-config
```

**Razón NodePort**: k3d usa Docker bridge network; LoadBalancer no funciona sin L2 announcements/MetalLB. En prod real (baremetal/VM), usar LoadBalancer con `l2announcements.enabled: true` en Cilium.

**Por qué no LoadBalancer en k3d**:
- Docker bridge network aisla containers
- L2 announcements disabled (`IT/cilium/values.yaml:111`)
- K3s ServiceLB no aplica a Gateway API
- NodePort + host port mapping es la única opción

### 3. Gateway Principal

**Archivo**: `IT/gateway/idp-gateway.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: idp-gateway
  namespace: kube-system
  annotations:
    cert-manager.io/cluster-issuer: ca-issuer
spec:
  gatewayClassName: cilium-nodeport
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: "*.${DNS_SUFFIX}"      # Variable dinámica!
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.${DNS_SUFFIX}"      # Variable dinámica!
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - name: idp-wildcard-cert   # Secret creado por cert-manager
```

**Variable dinámica**: `${DNS_SUFFIX}` - calculada en tiempo de deployment
**Cálculo DNS_SUFFIX** (`Task/bootstrap.yaml:354-360`):
```bash
DNS_SUFFIX=$(./Scripts/config-get.sh network.lan_ip config.toml)
if [ -z "$DNS_SUFFIX" ]; then
  DNS_SUFFIX=$(ip route get 1.1.1.1 | awk '{print $7}')
fi
DNS_SUFFIX=$(echo "$DNS_SUFFIX" | tr '.' '-').nip.io
# Resultado: 192.168.1.100 -> 192-168-1-100.nip.io
```

**Namespace**: `kube-system` - permite cross-namespace routing sin RBAC adicional
**allowedRoutes.from: All**: Permite HTTPRoutes de cualquier namespace

### 4. Gateway Service Patch (Crítico)

**Archivo**: `IT/gateway/patch/gateway-service-patch.yaml`

**Problema**: Cilium auto-genera Service con NodePorts aleatorios
**Solución**: Patch para fijar NodePorts a valores conocidos

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cilium-gateway-idp-gateway
  namespace: kube-system
spec:
  ports:
    - name: port-80        # Cilium usa "port-{number}", NO "http"
      nodePort: 30080      # Fijado desde config.toml
      port: 80
      protocol: TCP
      targetPort: 80
    - name: port-443
      nodePort: 30443      # Fijado desde config.toml
      port: 443
      protocol: TCP
      targetPort: 443
```

**IMPORTANTE**: Cilium nombra ports como `port-{number}`, NO con listener names (`http`, `https`)

**Aplicación** (`Task/bootstrap.yaml:362-372`):
1. `kustomize build . | envsubst | kubectl apply -f -` (crea Gateway)
2. `sleep 5` (espera creación del Service por Cilium)
3. `kubectl apply -f patch/gateway-service-patch.yaml` (fuerza NodePorts)
4. Verificación de NodePorts aplicados correctamente

### 5. TLS Certificate Management

#### 5.1 Certificate Chain

```
self-signed-issuer (ClusterIssuer)
  └─> idp-demo-ca (Certificate) -> idp-demo-ca-secret (Secret)
      └─> ca-issuer (ClusterIssuer)
          └─> idp-wildcard-cert (Certificate) -> idp-wildcard-cert (Secret)
              └─> Gateway TLS termination
```

**Archivos**:
- `IT/cert-manager/self-signed-issuer.yaml` - Bootstrap issuer
- `IT/cert-manager/idp-demo-ca.yaml` - Root CA cert (ECDSA 256)
- `IT/cert-manager/ca-issuer.yaml` - Production issuer (usa root CA)
- `IT/gateway/idp-wildcard-cert.yaml` - Wildcard cert para todos los servicios

#### 5.2 Wildcard Certificate

**Archivo**: `IT/gateway/idp-wildcard-cert.yaml`

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: idp-wildcard-cert
  namespace: kube-system
spec:
  secretName: idp-wildcard-cert
  duration: 8760h           # 1 año
  renewBefore: 720h         # Renovar 30 días antes
  privateKey:
    rotationPolicy: Always
  commonName: "*.${DNS_SUFFIX}"    # Variable dinámica!
  dnsNames:
    - "*.${DNS_SUFFIX}"            # *.192-168-1-100.nip.io
    - "${DNS_SUFFIX}"              # 192-168-1-100.nip.io
  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
```

**Variable dinámica**: `${DNS_SUFFIX}` - mismo valor que Gateway
**Secreto resultante**: `idp-wildcard-cert` en `kube-system`

#### 5.3 TLS Secret Permission (Cilium-specific)

**Archivo**: `IT/gateway/gateway-tls-permission.yaml`

```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideEnvoyConfig
metadata:
  name: gateway-tls-secrets
spec:
  services:
    - name: idp-gateway
      namespace: kube-system
  resources:
    - kind: Secret
      name: idp-wildcard-cert
      namespace: kube-system
```

**Razón**: Cilium Envoy necesita permiso explícito para leer TLS secrets
**Sin esto**: Gateway no puede terminar TLS, error "secret not found"

### 6. HTTPRoutes

**Patrón estándar** para todos los servicios:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: <service-name>
  namespace: <service-namespace>  # Puede ser diferente a gateway
spec:
  parentRefs:
    - name: idp-gateway
      namespace: kube-system         # Gateway está en kube-system
  hostnames:
    - "<service>.${DNS_SUFFIX}"      # Variable dinámica!
  rules:
    - backendRefs:
        - name: <service-name>       # Service en mismo namespace
          port: 80
```

**HTTPRoutes existentes** (10 total en `IT/gateway/kustomization.yaml:8-17`):
1. `argocd-httproute.yaml` - ArgoCD UI/API
2. `grafana-httproute.yaml` - Grafana dashboards
3. `vault-httproute.yaml` - Vault UI
4. `sonarqube-httproute.yaml` - SonarQube platform
5. `argo-workflows-httproute.yaml` - Workflows UI
6. `argo-events-httproute.yaml` - Events metrics
7. `pyrra-httproute.yaml` - SLO UI
8. `backstage-httproute.yaml` - Developer portal
9. `dex-httproute.yaml` - OIDC provider
10. `redirect-http-to-https.yaml` - HTTP->HTTPS redirect

### 7. HTTP to HTTPS Redirect

**Archivo**: `IT/gateway/httproutes/redirect-http-to-https.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-to-https-redirect
  namespace: kube-system
spec:
  parentRefs:
    - name: idp-gateway
      sectionName: http       # Solo listener HTTP (puerto 80)
  hostnames:
    - "*.${DNS_SUFFIX}"
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
            statusCode: 301
```

**sectionName: http**: Aplica solo al listener HTTP, no HTTPS
**Resultado**: Todo tráfico HTTP redirige a HTTPS automáticamente

## Variable Substitution Flow

### Deployment Flow (`task deploy`)

```
1. config.toml
   ├─> network.lan_ip (puede estar vacío)
   └─> network.nodeport_http/https

2. Taskfile.yaml vars (evaluadas una vez al inicio)
   ├─> LAN_IP (config o auto-detect vía ip route)
   ├─> NODEPORT_HTTP (config)
   └─> NODEPORT_HTTPS (config)

3. Task k3d:k3d:create
   └─> envsubst < k3d-cluster.yaml
       ├─> ${NODEPORT_HTTP} -> 30080
       └─> ${NODEPORT_HTTPS} -> 30443

4. Task bootstrap:gateway:deploy
   ├─> DNS_SUFFIX calculation (Task-level var)
   │   └─> $(LAN_IP | tr '.' '-').nip.io
   ├─> kustomize build | envsubst | kubectl apply
   │   ├─> Gateway: hostname: "*.${DNS_SUFFIX}"
   │   ├─> Certificate: dnsNames: "*.${DNS_SUFFIX}"
   │   └─> HTTPRoutes: hostnames: "<service>.${DNS_SUFFIX}"
   └─> kubectl apply -f patch/gateway-service-patch.yaml

5. Resultado en cluster (ejemplo: LAN_IP=192.168.1.100)
   ├─> Gateway listening: *.192-168-1-100.nip.io
   ├─> Certificate: *.192-168-1-100.nip.io
   └─> HTTPRoutes:
       ├─> argocd.192-168-1-100.nip.io
       ├─> grafana.192-168-1-100.nip.io
       └─> vault.192-168-1-100.nip.io (etc.)
```

### Variable Scopes

**Taskfile.yaml vars** (global, evaluadas al inicio):
- `LAN_IP`, `NODEPORT_HTTP`, `NODEPORT_HTTPS`
- Usadas por: k3d, utils:config:print

**Task-level vars** (evaluadas por task):
- `DNS_SUFFIX` en `bootstrap:gateway:deploy` y `stacks:backstage`
- **Razón**: DNS_SUFFIX puede cambiar si LAN IP cambia mid-deployment
- **Importante**: Backstage necesita DNS_SUFFIX para app-config

**envsubst variables** (substituidas en-stream):
- `${DNS_SUFFIX}`, `${NODEPORT_HTTP}`, `${NODEPORT_HTTPS}`
- Aplicadas vía `envsubst` antes de `kubectl apply`

## Backstage: Caso Especial de DNS_SUFFIX

**Archivos afectados**:
- `K8s/backstage/backstage/app-config.override.yaml`
- `K8s/backstage/dex/values.yaml`

**Problema**: Backstage app-config necesita URLs completas con DNS_SUFFIX

**Solución**: ConfigMap generado por Kustomize + envsubst en stacks:backstage

### app-config.override.yaml (template)

```yaml
app:
  baseUrl: https://backstage.${DNS_SUFFIX}
backend:
  baseUrl: https://backstage.${DNS_SUFFIX}
  cors:
    origin: https://backstage.${DNS_SUFFIX}
auth:
  providers:
    oidc:
      production:
        metadataUrl: https://dex.${DNS_SUFFIX}/.well-known/openid-configuration
```

### Kustomize ConfigMapGenerator

**Archivo**: `K8s/backstage/backstage/kustomization.yaml:17-22`

```yaml
configMapGenerator:
  - name: backstage-app-config-override
    files:
      - app-config.override.yaml
    options:
      disableNameSuffixHash: true  # IMPORTANTE: nombre fijo
```

**disableNameSuffixHash: true**: Evita suffix `-{hash}` en ConfigMap name
**Razón**: Helm values.yaml referencia `backstage-app-config-override` por nombre fijo

### stacks:backstage Task

**Archivo**: `Task/stacks.yaml:74-95`

```yaml
backstage:
  desc: 'Deploy the Backstage Developer Portal via ArgoCD'
  dir: K8s/backstage
  env:
    REPO_URL: '{{.REPO_URL}}'
    TARGET_REVISION: '{{.TARGET_REVISION}}'
    DNS_SUFFIX:                      # Task-level var!
      sh: |
        value=$({{.ROOT_DIR}}/Scripts/config-get.sh network.lan_ip {{.ROOT_DIR}}/{{.CONFIG_FILE}})
        if [ -z "$value" ]; then
          value=$(ip route get 1.1.1.1 | awk '{print $7}')
        fi
        echo "$(echo "$value" | tr '.' '-').nip.io"
  cmds:
    - envsubst < applicationset-backstage.yaml | kubectl apply -f -
```

**Flujo completo**:
1. DNS_SUFFIX calculado en Task
2. `envsubst` substituye en ApplicationSet
3. ArgoCD despliega Backstage ApplicationSet
4. Kustomize genera ConfigMap con `${DNS_SUFFIX}` substituido
5. Pod Backstage monta ConfigMap con URLs correctas

**IMPORTANTE**: ArgoCD no hace envsubst - lo hace el Task antes de aplicar ApplicationSet

## Implicaciones GitOps vs Dynamic Data

### Problema Fundamental

**GitOps**: Manifests en Git deben ser declarativos, inmutables
**Dynamic Data**: LAN IP puede cambiar entre laptops/entornos

### Solución Implementada: Variable Substitution en Deploy-Time

**Archivos con placeholders** (tracked en Git):
- `IT/k3d-cluster.yaml` - `${NODEPORT_HTTP}`, `${NODEPORT_HTTPS}`
- `IT/gateway/*.yaml` - `${DNS_SUFFIX}`
- `K8s/backstage/backstage/app-config.override.yaml` - `${DNS_SUFFIX}`
- `K8s/backstage/dex/values.yaml` - URLs con `${DNS_SUFFIX}`

**Substitución en pipeline** (NO en Git):
- `envsubst` aplica valores desde `config.toml` o auto-detection
- Resultados solo existen in-cluster, nunca committed

**Trade-offs**:
- ✅ Portabilidad: Mismo repo funciona en cualquier LAN IP
- ✅ GitOps friendly: Templates en Git, valores fuera
- ❌ No pure GitOps: `envsubst` es step manual/scripted
- ❌ No drift detection: ArgoCD ve templates, no valores substituidos

### Alternativas Consideradas (NO usadas)

#### 1. ConfigMap/Secret con DNS_SUFFIX
**Rechazado**: Gateway spec no soporta ConfigMapKeyRef en hostname
**Gateway API limitación**: hostnames debe ser static string

#### 2. External-DNS
**No aplicable**: nip.io no es DNS real, es wildcard DNS service
**Uso**: Desarrollo local, no producción

#### 3. Template en ArgoCD
**No usado**: ArgoCD no hace variable substitution nativo
**Opción**: ArgoCD ApplicationSet generators podría generar multiple apps, pero no resuelve DNS_SUFFIX dynamic

#### 4. Kustomize vars/replacements
**Insuficiente**: Requiere conocer valor en `kustomization.yaml`
**Problema**: LAN IP no conocida hasta runtime

### Decisión: envsubst es el Least-Bad Option

**Razones**:
1. Simple, portable (disponible en Devbox)
2. Explícito en Tasks (documentado en código)
3. No requiere operador adicional (Sealed Secrets, etc.)
4. Compatible con ArgoCD para post-substitution
5. nip.io es demo-only; prod real usa DNS real con valores fijos

## Networking en Producción Real

### Cambios Requeridos para Prod

#### 1. DNS Real (NO nip.io)

**config.toml**:
```toml
[network]
lan_ip = ""  # Vacío, no usado en prod
dns_domain = "idp.example.com"
```

**Taskfile vars**:
```yaml
DNS_SUFFIX:
  sh: ./Scripts/config-get.sh network.dns_domain config.toml
# Resultado: idp.example.com (fijo)
```

**Gateway**:
```yaml
hostname: "*.idp.example.com"
```

**DNS externo** (via External-DNS o manual):
```
*.idp.example.com -> LoadBalancer IP
```

#### 2. LoadBalancer en vez de NodePort

**GatewayClass**:
```yaml
spec:
  service:
    type: LoadBalancer
```

**Cilium L2 Announcements** (baremetal):
```yaml
# IT/cilium/values.yaml
l2announcements:
  enabled: true
```

**O MetalLB** (alternativa):
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: gateway-pool
spec:
  addresses:
    - 192.168.1.200-192.168.1.210
```

#### 3. Certificate de CA Pública

**Opción A**: Let's Encrypt

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: cilium  # O dns01 challenge
```

**Opción B**: Enterprise CA (Vault PKI)

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer
spec:
  vault:
    server: https://vault.example.com
    path: pki/sign/kubernetes
    auth:
      kubernetes:
        role: cert-manager
```

#### 4. Fuse prod=true

**config.toml**:
```toml
[fuses]
prod = true
```

**Efectos** (`Task/bootstrap.yaml:328`):
- High availability (múltiples replicas)
- Resource limits más estrictos
- PodDisruptionBudgets
- Affinity rules para spreading

## Debugging Networking Issues

### 1. Verificar DNS_SUFFIX Calculation

```bash
# Manual
LAN_IP=$(./Scripts/config-get.sh network.lan_ip config.toml)
[ -z "$LAN_IP" ] && LAN_IP=$(ip route get 1.1.1.1 | awk '{print $7}')
echo "$(echo "$LAN_IP" | tr '.' '-').nip.io"

# Via Task
task utils:config:print | grep "LAN IP"
```

### 2. Verificar Gateway Ready

```bash
# Gateway status
kubectl get gateway idp-gateway -n kube-system

# Gateway conditions
kubectl describe gateway idp-gateway -n kube-system

# Listeners programmed
kubectl get gateway idp-gateway -n kube-system -o jsonpath='{.status.listeners}'
```

### 3. Verificar NodePorts

```bash
# Service actual ports
kubectl get svc cilium-gateway-idp-gateway -n kube-system -o yaml

# Verificar coincide con config
HTTP_PORT=$(kubectl get svc cilium-gateway-idp-gateway -n kube-system -o jsonpath='{.spec.ports[?(@.name=="port-80")].nodePort}')
HTTPS_PORT=$(kubectl get svc cilium-gateway-idp-gateway -n kube-system -o jsonpath='{.spec.ports[?(@.name=="port-443")].nodePort}')
echo "HTTP=$HTTP_PORT (expected 30080), HTTPS=$HTTPS_PORT (expected 30443)"
```

### 4. Verificar Certificate

```bash
# Certificate ready
kubectl get certificate idp-wildcard-cert -n kube-system

# Certificate details
kubectl describe certificate idp-wildcard-cert -n kube-system

# Secret exists
kubectl get secret idp-wildcard-cert -n kube-system

# Check cert SAN
kubectl get secret idp-wildcard-cert -n kube-system -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text | grep DNS
```

### 5. Verificar HTTPRoute

```bash
# HTTPRoute status
kubectl get httproute -A

# Specific route
kubectl describe httproute argocd-server -n argocd

# Parent refs accepted
kubectl get httproute argocd-server -n argocd -o jsonpath='{.status.parents[0].conditions}'
```

### 6. Test Connectivity

```bash
# From host
curl -k https://argocd.$(task utils:config:print | grep "LAN IP" | awk '{print $3}' | tr '.' '-').nip.io

# From pod (bypass Gateway)
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://argocd-server.argocd.svc.cluster.local

# DNS resolution (nip.io)
dig argocd.192-168-1-100.nip.io
# Should return: 192.168.1.100
```

### 7. Cilium Status

```bash
# Cilium connectivity test
cilium connectivity test

# Envoy config (Gateway controller)
cilium envoy config dump

# Gateway controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=cilium-operator --tail=100 | grep -i gateway
```

### 8. Cert-Manager Troubleshooting

```bash
# Order status (ACME)
kubectl get order -A

# Challenge status
kubectl get challenge -A

# Cert-manager logs
kubectl logs -n cert-manager deploy/cert-manager --tail=100
```

## Common Issues

### Issue 1: Gateway Not Ready

**Síntoma**: `kubectl get gateway` muestra `Programmed=False`

**Causas**:
1. Certificate secret no existe
2. GatewayClass no existe
3. Cilium gateway controller no running

**Fix**:
```bash
# Verificar dependencies
kubectl get gatewayclass cilium-nodeport
kubectl get secret idp-wildcard-cert -n kube-system
kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium-operator
```

### Issue 2: 404 en todas las URLs

**Síntoma**: Gateway accesible pero todas rutas retornan 404

**Causas**:
1. HTTPRoutes no creadas o no attached
2. DNS_SUFFIX mismatch entre Gateway y HTTPRoutes

**Fix**:
```bash
# Verificar HTTPRoutes
kubectl get httproute -A

# Verificar hostname match
kubectl get gateway idp-gateway -n kube-system -o jsonpath='{.spec.listeners[1].hostname}'
kubectl get httproute argocd-server -n argocd -o jsonpath='{.spec.hostnames[0]}'
# Deben coincidir patrón: *.192-168-1-100.nip.io y argocd.192-168-1-100.nip.io
```

### Issue 3: TLS Certificate Error

**Síntoma**: Browser muestra "NET::ERR_CERT_AUTHORITY_INVALID"

**Causas**:
1. Wildcard cert no cubre hostname
2. CA cert no confiada en browser

**Fix**:
```bash
# Exportar CA para browser
task utils:ca:export
# Import idp-demo-ca.crt en browser Trusted Root Certificates

# Verificar cert SANs
kubectl get secret idp-wildcard-cert -n kube-system -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -text | grep -A2 "Subject Alternative Name"
```

### Issue 4: NodePort Patch Failed

**Síntoma**: Task error "NodePort patch failed!"

**Causas**:
1. Service name changed (Cilium update)
2. Sleep insufficient (Service not created yet)
3. RBAC issue

**Fix**:
```bash
# Verificar service name actual
kubectl get svc -n kube-system | grep gateway

# Si cambió, update patch/gateway-service-patch.yaml:15
# Reaplicar
kubectl apply -f IT/gateway/patch/gateway-service-patch.yaml
```

### Issue 5: Backstage Cannot Reach Dex

**Síntoma**: Backstage login fails, Dex unreachable

**Causas**:
1. DNS_SUFFIX not substituted in app-config
2. Dex HTTPRoute missing
3. Network policy blocking

**Fix**:
```bash
# Verificar ConfigMap substituido
kubectl get cm backstage-app-config-override -n backstage -o yaml | grep dex
# Debe mostrar: https://dex.192-168-1-100.nip.io

# Verificar Dex HTTPRoute
kubectl get httproute dex -n backstage

# Test desde Backstage pod
kubectl exec -n backstage deploy/backstage -- curl -k https://dex.192-168-1-100.nip.io/.well-known/openid-configuration
```

## Agregar Nuevo Servicio con HTTPRoute

### Template

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: <service-name>
  namespace: <service-namespace>
  labels:
    app.kubernetes.io/part-of: idp
    app.kubernetes.io/name: <service-name>
    app.kubernetes.io/component: <component-type>
  annotations:
    description: 'HTTPRoute for <service description>'
    contact: platform-team
spec:
  parentRefs:
    - name: idp-gateway
      namespace: kube-system
  hostnames:
    - "<service-subdomain>.${DNS_SUFFIX}"
  rules:
    - matches:                       # Opcional: path matching
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: <backend-service-name>
          port: <backend-port>
          weight: 100                # Opcional: traffic split
```

### Ubicación

**Opción A**: Bootstrap service (IT/gateway/httproutes/)
- Servicios core (ArgoCD, Vault, etc.)
- Aplicados en `bootstrap:gateway:deploy`

**Opción B**: Application service (K8s/<stack>/<component>/)
- Servicios de aplicación (custom apps)
- Aplicados via ArgoCD ApplicationSet

### Kustomization Update

**Si Opción A**:
```yaml
# IT/gateway/kustomization.yaml
resources:
  - httproutes/<service>-httproute.yaml
```

**Si Opción B**:
```yaml
# K8s/<stack>/<component>/kustomization.yaml
resources:
  - httproute.yaml
  - deployment.yaml
  - service.yaml
```

### Variables en HTTPRoute

**Si necesita DNS_SUFFIX**:
- Usar `${DNS_SUFFIX}` placeholder
- Asegurar `envsubst` en Task pipeline

**Si hostname fijo** (prod):
- Hardcodear: `service.idp.example.com`
- No requiere envsubst

### Test

```bash
# Apply
kubectl apply -f httproute.yaml

# Verificar attached
kubectl get httproute <name> -n <namespace> -o jsonpath='{.status.parents[0].conditions}'

# Test
curl -k https://<subdomain>.$(task utils:config:print | grep "LAN IP" | awk '{print $3}' | tr '.' '-').nip.io
```

## Security Considerations

### 1. TLS Everywhere

- **Gateway termina TLS**: HTTPS en edge
- **Backend HTTP**: Service-to-service plain HTTP
- **Razón**: Simplifica cert management, Cilium encripta L3/L4

**Hardening Prod**:
```yaml
# Mutual TLS service-to-service
gatewayAPI:
  secretsNamespace:
    create: true
    name: cilium-secrets
    secrets:
      - name: backend-mtls-ca
```

### 2. Network Policies

**Actual**: Permitido por default (demo)

**Prod**: Default deny + allow explícito
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: <namespace>
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-gateway
  namespace: <namespace>
spec:
  podSelector:
    matchLabels:
      app: <service>
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              io.cilium/app: envoy
```

### 3. Rate Limiting (Cilium L7)

**No implementado**: Demo simplicity

**Prod**:
```yaml
apiVersion: cilium.io/v2
kind: CiliumEnvoyConfig
metadata:
  name: rate-limit-config
spec:
  resources:
    - "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
      stat_prefix: http_local_rate_limiter
      token_bucket:
        max_tokens: 100
        tokens_per_fill: 100
        fill_interval: 60s
```

### 4. WAF (Web Application Firewall)

**No implementado**: Requiere ModSecurity + Cilium

**Prod option**: Cloudflare en front, o Cilium + Envoy Lua filter

## Performance Tuning

### Cilium Gateway Scaling

```yaml
# IT/cilium/values.yaml
envoy:
  enabled: true
  replicas: 3                    # HA
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 512Mi
  priorityClassName: platform-critical
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              io.cilium/app: envoy
          topologyKey: kubernetes.io/hostname
```

### Gateway Resource Limits

**Actual**: Inherited from Cilium operator

**Prod**: Separate deployment
```yaml
spec:
  infrastructure:
    parametersRef:
      group: cilium.io
      kind: CiliumGatewayClassConfig
      name: cilium-loadbalancer-config
# config:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
```

### Connection Tuning

**k3d defaults**: OK para demo (100-200 concurrent connections)

**Prod**:
```yaml
# Gateway listener
- name: https
  protocol: HTTPS
  port: 443
  tls:
    options:
      gateway.envoyproxy.io/listener-keepalive: "enabled"
      gateway.envoyproxy.io/listener-idle-timeout: "300s"
      gateway.envoyproxy.io/max-connections: "10000"
```
