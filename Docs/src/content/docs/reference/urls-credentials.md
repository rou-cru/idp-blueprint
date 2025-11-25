---
title: URLs & Initial Credentials
sidebar:
  label: URLs & Credentials
  order: 2
---

This page provides a complete reference for accessing platform services and obtaining their credentials after deployment.

## Service URLs

All services are exposed via Gateway API with wildcard TLS certificates using nip.io DNS. The IP address in the URL is your LAN IP with dots replaced by dashes.

:::tip[Finding Your IP]
The deployment task automatically detects your LAN IP. You can manually find it with:
```bash
ip route get 1.1.1.1 | awk '{print $7; exit}'
```
:::

### URL Pattern

All services follow this pattern:
```
https://<service>.<ip-with-dashes>.nip.io
```

**Example**: If your IP is `192.168.1.20`, ArgoCD would be at:
```
https://argocd.192-168-1-20.nip.io
```

### Complete Service List

| Service | URL Template | Default Port | Namespace |
|---------|--------------|--------------|-----------|
| **ArgoCD** | `https://argocd.<ip>.nip.io` | 443 (NodePort 30443) | `argocd` |
| **Grafana** | `https://grafana.<ip>.nip.io` | 443 (NodePort 30443) | `observability` |
| **Prometheus** | `https://prometheus.<ip>.nip.io` | 443 (NodePort 30443) | `observability` |
| **Alertmanager** | `https://alertmanager.<ip>.nip.io` | 443 (NodePort 30443) | `observability` |
| **Vault** | `https://vault.<ip>.nip.io` | 443 (NodePort 30443) | `vault-system` |
| **Argo Workflows** | `https://workflows.<ip>.nip.io` | 443 (NodePort 30443) | `cicd` |
| **SonarQube** | `https://sonarqube.<ip>.nip.io` | 443 (NodePort 30443) | `cicd` |
| **Policy Reporter** | `https://policy-reporter.<ip>.nip.io` | 443 (NodePort 30443) | `kyverno-system` |
| **Backstage** | `https://backstage.<ip>.nip.io` | 443 (NodePort 30443) | `backstage` |
| **Pyrra** | `https://pyrra.<ip>.nip.io` | 443 (NodePort 30443) | `observability` |

:::note[NodePorts Configuration]
The Gateway uses NodePorts configured in `config.toml`:
- `nodeport_http = 30080` (HTTP, redirects to HTTPS)
- `nodeport_https = 30443` (HTTPS)

Ensure these ports are not in use by other services and are allowed by your firewall.
:::

## Initial Credentials

### ArgoCD

**Username**: `admin`

**Password Location**: Synced from Vault via External Secrets

**Default Password** (from `config.toml`):
```toml
[passwords]
argocd_admin = "argo"
```

**Retrieve from Kubernetes**:
```bash
kubectl -n argocd get secret argocd-secret \
  -o jsonpath='{.data.admin\.password}' | base64 -d; echo
```

**First Login**:
1. Navigate to `https://argocd.<your-ip>.nip.io`
2. Accept the self-signed certificate warning
3. Login with username `admin` and the password retrieved above

---

### Grafana

**Username**: `admin`

**Password Location**: Synced from Vault via External Secrets

**Default Password** (from `config.toml`):
```toml
[passwords]
grafana_admin = "admin"
```

**Retrieve from Kubernetes**:
```bash
kubectl -n observability get secret kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

**First Login**:
1. Navigate to `https://grafana.<your-ip>.nip.io`
2. Login with username `admin` and password
3. Datasources (Prometheus, Loki) are pre-configured

---

### Vault

**Access Method**: Root token (local/demo only)

**Initialization**: Vault is automatically initialized by `task vault:init` during deployment

**Root Token Location**: Stored in Kubernetes Secret (local/demo only)

**Retrieve Root Token**:
```bash
kubectl -n vault-system get secret vault-init \
  -o jsonpath='{.data.root-token}' | base64 -d; echo
```

**Unseal Keys** (if needed):
```bash
kubectl -n vault-system get secret vault-init \
  -o jsonpath='{.data.unseal-keys-b64}' | base64 -d
```

**Access Vault UI**:
1. Navigate to `https://vault.<your-ip>.nip.io`
2. Choose "Token" authentication method
3. Paste the root token retrieved above

:::warning[Production Security]
The current setup stores the root token and unseal keys in Kubernetes for convenience in local/demo environments. **This is NOT suitable for production.**

For production:
- Use auto-unseal with cloud KMS
- Distribute unseal keys using Shamir's Secret Sharing
- Rotate root tokens regularly
- Use AppRole or Kubernetes auth instead of root tokens

See [Secrets Management](../architecture/secrets.md#security-considerations) for production hardening.
:::

---

### SonarQube

**Username**: `admin`

**Password Location**: Synced from Vault via External Secrets

**Default Password** (from `config.toml`):
```toml
[passwords]
sonarqube_admin = "admin"
```

**Retrieve from Kubernetes**:
```bash
kubectl -n cicd get secret sonarqube-admin-password \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

**First Login**:
1. Navigate to `https://sonarqube.<your-ip>.nip.io`
2. Login with username `admin` and password
3. You may be prompted to change the password on first login

---

### Argo Workflows

**Authentication**: Uses the same ArgoCD SSO (if configured) or can be accessed directly

**Server Auth Mode**: Server auth mode is configured in the values

**Access**:
```bash
# Port-forward method (if Gateway not ready)
kubectl -n cicd port-forward svc/argo-workflows-server 2746:2746
# Then access: https://localhost:2746
```

**Direct URL**: `https://workflows.<your-ip>.nip.io`

---

### Backstage

**Authentication**: Configured based on your identity provider setup

**Default Access**: The platform deploys Backstage without authentication enabled for demo purposes

**Access**: `https://backstage.<your-ip>.nip.io`

---

## Certificate Trust

All services use TLS certificates issued by a local Certificate Authority (CA) managed by cert-manager. Your browser will show security warnings on first visit.

### Trust the Platform CA

To avoid browser warnings, import the platform CA certificate into your system trust store:

**1. Export the CA Certificate**:
```bash
kubectl -n cert-manager get secret idp-demo-ca-secret \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > idp-demo-ca.crt
```

**2. Import on macOS**:
```bash
# Open Keychain Access
open idp-demo-ca.crt

# Or via command line:
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain idp-demo-ca.crt
```

**3. Import on Linux (Debian/Ubuntu)**:
```bash
sudo cp idp-demo-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

**4. Import on Windows**:
```powershell
# Open Certificate Manager
certmgr.msc

# Or via PowerShell:
Import-Certificate -FilePath idp-demo-ca.crt `
  -CertStoreLocation Cert:\LocalMachine\Root
```

**5. Import in Firefox** (uses its own certificate store):
1. Settings → Privacy & Security → Certificates → View Certificates
2. Authorities → Import
3. Select `idp-demo-ca.crt`
4. Check "Trust this CA to identify websites"

---

## Accessing Services from Other Devices

Services are accessible from other devices on your LAN (phones, tablets, other computers) as long as:

1. **Firewall allows NodePorts**: Ensure ports 30080 and 30443 are allowed
2. **Same network**: Device must be on the same LAN
3. **Use your workstation's IP**: Not `127.0.0.1`, but your actual LAN IP (e.g., `192.168.1.20`)

**Example from phone**:
```
https://grafana.192-168-1-20.nip.io
```

**Check firewall on macOS**:
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

**Check firewall on Linux**:
```bash
sudo ufw status
# Allow if needed:
sudo ufw allow 30080/tcp
sudo ufw allow 30443/tcp
```

---

## Troubleshooting Access Issues

### DNS Not Resolving

**Symptom**: Browser shows "DNS resolution failed" or "server not found"

**Solutions**:
1. Check nip.io is working: `dig 192-168-1-20.nip.io`
2. Try alternative DNS: `8.8.8.8` (Google) or `1.1.1.1` (Cloudflare)
3. Verify your IP format: dashes, not dots (e.g., `192-168-1-20`, not `192.168.1.20`)

### Connection Refused

**Symptom**: "Connection refused" or "Connection timeout"

**Solutions**:
1. Verify Gateway is ready:
   ```bash
   kubectl -n kube-system get gateway idp-gateway
   kubectl -n kube-system wait --for=condition=Programmed gateway/idp-gateway --timeout=300s
   ```
2. Check NodePorts are accessible:
   ```bash
   curl -k https://localhost:30443
   ```
3. Verify firewall allows NodePorts (see above)

### Certificate Errors

**Symptom**: "Your connection is not private" or "Certificate invalid"

**Solutions**:
1. **Expected behavior** for self-signed CA - you can proceed safely in demo environments
2. Import the platform CA certificate (see [Certificate Trust](#certificate-trust) above)
3. Verify certificate was issued:
   ```bash
   kubectl -n cert-manager get certificate
   kubectl describe certificate -n cert-manager idp-wildcard-cert
   ```

### 404 Not Found

**Symptom**: Service URL loads but shows 404 error

**Solutions**:
1. Check HTTPRoute exists:
   ```bash
   kubectl get httproute -A | grep <service-name>
   ```
2. Verify service is running:
   ```bash
   kubectl -n <namespace> get pods
   kubectl -n <namespace> get svc
   ```
3. Check ArgoCD Application is Healthy:
   ```bash
   kubectl -n argocd get applications
   ```

---

## See Also

- [Verify Installation](../getting-started/verify.md) - Post-deployment verification steps
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Ports & Endpoints](ports-endpoints.md) - Complete port reference
- [Gateway API Configuration](../components/infrastructure/gateway-api.mdx) - How routing works
