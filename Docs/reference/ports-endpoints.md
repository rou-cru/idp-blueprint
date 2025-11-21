# Ports & Endpoints

Reference of network ports and public endpoints used by the platform.

## Core endpoints — nip.io

Format: `https://<service>.<ip-dashed>.nip.io`

Examples for 127.0.0.1:

- ArgoCD: `https://argocd.127-0-0-1.nip.io`
- Grafana: `https://grafana.127-0-0-1.nip.io`
- Vault: `https://vault.127-0-0-1.nip.io`
- Argo Workflows: `https://workflows.127-0-0-1.nip.io`
- SonarQube: `https://sonarqube.127-0-0-1.nip.io`
- Argo Events: `https://events.127-0-0-1.nip.io`
- Pyrra (SLO UI): `https://pyrra.127-0-0-1.nip.io`

## NodePorts — local demo

- HTTP Gateway: value from `config.toml` → `nodeport_http` (default `30080`)
- HTTPS Gateway: value from `config.toml` → `nodeport_https` (default `30443`)
