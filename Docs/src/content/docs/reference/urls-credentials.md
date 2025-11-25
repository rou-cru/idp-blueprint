---
title: URLs & Initial Credentials
sidebar:
  label: URLs & Credentials
  order: 3
---

## Service URLs

All services are exposed via Gateway API with wildcard TLS certificates using nip.io DNS. The IP address in the URL is your LAN IP with dots replaced by dashes.

:::tip[Finding Your IP]
The deployment task automatically detects your LAN IP. You can manually find it with:

```bash
ip route get 1.1.1.1 | awk '{print $7; exit}'
```

:::

### URL Pattern (Gateway + nip.io)

All services follow:

```
https://<service>.<ip-with-dashes>.nip.io
```

Use your LAN IP converted to dashes (see tip above). Service hostnames match the component name (e.g., `argocd`, `grafana`, `vault`).

:::note[NodePorts Configuration]
Gateway NodePorts come from `config.toml` (`network.nodeport_http`, `network.nodeport_https`). Check the effective values with:

```bash
task utils:config:print
```

:::

## Credentials

Retrieval and rotation are documented in:

- **Getting Started → Verify** for first login
- **Operate → component runbooks** for ongoing ops

Reference values live in `config.toml` (`[passwords]`) and are synced through Vault + External Secrets. Avoid treating the defaults as production credentials.

---

## Certificate Trust

All services use TLS certificates issued by a local Certificate Authority (CA) managed by cert-manager. Your browser will show security warnings on first visit.

### Trust the Platform CA

To avoid browser warnings, import the platform CA certificate into your system trust store:

**Export the CA Certificate**

```bash
kubectl -n cert-manager get secret idp-demo-ca-secret \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > idp-demo-ca.crt
```

**Import on macOS**:

```bash
# Open Keychain Access
open idp-demo-ca.crt

# Or via command line:
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain idp-demo-ca.crt
```

**Import on Linux (Ubuntu)**:

```bash
sudo cp idp-demo-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

**Import on Windows**:

```powershell
# Open Certificate Manager
certmgr.msc

# Or via PowerShell:
Import-Certificate -FilePath idp-demo-ca.crt `
  -CertStoreLocation Cert:\LocalMachine\Root
```

**Import in Firefox** (uses its own certificate store):

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

This section was removed. Use kubectl get/describe, logs, and port-forward for debugging when needed.
