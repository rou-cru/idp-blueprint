---
title: Security & Policy Model
sidebar:
  label: Security & Policy
  order: 3
---

This document describes the security architecture and policy governance model of the IDP Blueprint platform.

## Security Design Principles

The platform's security model is built on three foundational principles:

1. **Defense in Depth:** Multiple layers of security controls, so compromise of one layer doesn't compromise the entire system
2. **Least Privilege:** Components and workloads have only the permissions necessary for their function
3. **Security as Code:** Security policies and configurations are declarative, version-controlled, and automatically enforced

## The CIA Triad Assessment

Security is evaluated through the CIA triad: Confidentiality, Integrity, and Availability. Each dimension has different strengths and areas for improvement in this platform.

### Confidentiality

Confidentiality protects sensitive data from unauthorized access.

**Current state:**

- **Vault:** Centralized secrets management with access control policies
- **External Secrets Operator:** Synchronizes secrets without exposing them in Git
- **RBAC:** Kubernetes role-based access control restricts API access
- **TLS:** Cert-Manager automates certificate issuance for encrypted communication
- **No secrets in Git:** All sensitive data flows through Vault, not committed to repositories

**Gaps:**

- **NetworkPolicies:** The Cilium NetworkPolicy engine is configured but not actively used. Without network segmentation, pods can communicate freely within the cluster, potentially exposing sensitive services.
- **Pod Security Standards:** No Pod Security Admission policies are enforced, allowing privileged containers if misconfigured.
- **Encryption at rest:** Kubernetes Secrets are stored in etcd but not encrypted at rest in this demo configuration.

### Integrity

Integrity ensures data and systems haven't been tampered with.

**Current state:**

- **GitOps (ArgoCD):** Git is the single source of truth. Manual changes are automatically reverted (selfHeal: true). This creates an audit trail and prevents drift.
- **Policy Validation (Kyverno):** Resources are validated against policies before admission to the cluster. Currently runs in `audit` mode for most policies.
- **Immutable Infrastructure:** Containers are immutable. Changes require building new images, not modifying running containers.
- **Image Scanning (Trivy):** Can scan container images for vulnerabilities (integrated but not enforcing gates yet).

**Strengths:**

The combination of GitOps and policy validation creates strong integrity guarantees. Every change is tracked in Git, and Kyverno validates that resources meet defined standards.

**Policy enforcement mode:**

- Helm chart default (`validationFailureAction`) is **audit**; we keep that for most policies to guide without blocking.
- Individual policies can still be `enforce` (e.g., namespace labels) where safety is required.
- If you need stricter gating, change `validationFailureAction` in `Policies/kyverno/values.yaml` and bump specific policies first; document the intent in the commit rather than hardcoding numbers here.

### Availability

Availability ensures systems remain accessible when needed.

**Current state:**

- **Tiered Criticality:** Services are categorized by importance, with scheduling policies that ensure critical components survive node failures (see [Disaster Recovery](../operate/disaster-recovery.md)).
- **Monitoring & Alerting:** Prometheus and Grafana provide visibility into system health.
- **GitOps Reconciliation:** ArgoCD continuously reconciles desired state, automatically repairing drift.

**Gaps:**

- **No High Availability:** Most components run single replicas. This is intentional for the demo/edge environment, but reduces availability.
- **No HorizontalPodAutoscalers:** Applications don't scale automatically based on load.
- **Limited Redundancy:** In a 3-node edge cluster, losing two nodes results in severely degraded functionality.

**Trade-off:**

The platform prioritizes resource efficiency over maximum availability. In edge environments with fixed resources, running multiple replicas of everything isn't viable. Instead, the tiered criticality model ensures the most important components (ArgoCD, Prometheus) survive failures.

## Defense in Depth Layers

The platform implements security across multiple layers:

### Layer 1: Network Security

**Cilium CNI** provides the network layer, with capabilities for:

- **NetworkPolicies:** L3/L4 and L7 network segmentation (currently configured but not used)
- **Hubble:** Network traffic visibility without application instrumentation
- **Service Mesh:** Sidecar-free mesh with potential for mTLS (not yet enabled)

**Current gap:** NetworkPolicies are not implemented. This means pods can communicate freely, which is convenient but less secure. Implementing default-deny NetworkPolicies would significantly improve the confidentiality posture.

### Layer 2: Identity & Access Control

**Vault** stores secrets with access policies.

**External Secrets Operator** synchronizes secrets into Kubernetes using service account authentication. Applications never directly access Vault.

**Kubernetes RBAC** controls who can access the Kubernetes API and what actions they can perform.

### Layer 3: Admission Control

**Kyverno** validates, mutates, and generates resources during admission. Policies enforce:

- Required labels for governance and cost attribution
- Resource limits and requests
- Best practices (e.g., no latest tags)
- Image verification (capability exists, not fully used)

Running in `audit` mode means violations are reported but not blocked. This is a conscious choice to reduce friction while building policy maturity. Policies can be migrated to `enforce` mode as the platform and its users mature.

### Layer 4: Runtime Security

**Trivy** scans container images for vulnerabilities and misconfigurations. It can run in CI pipelines to block vulnerable images or as an operator to periodically scan running workloads.

**Resource Limits:** PriorityClasses and resource limits prevent resource exhaustion attacks.

### Layer 5: Observability & Audit

**Prometheus + Grafana** provide visibility into system behavior, enabling detection of anomalies.

**Loki** aggregates logs, creating an audit trail of events.

**PolicyReports (Kyverno):** Track policy compliance over time via Policy Reporter.

**Git Audit Trail:** All changes flow through Git, creating a complete history.

## Threat Model

Understanding what threats this architecture defends against (and what it doesn't) is important.

### Threats Addressed

1. **Accidental Misconfiguration:** Kyverno policies catch common mistakes before they reach production.
2. **Secret Exposure:** Vault + External Secrets prevent hardcoded secrets in Git or container images.
3. **Unauthorized Changes:** GitOps with selfHeal prevents manual changes from persisting.
4. **Supply Chain Attacks:** Trivy scans can detect vulnerable dependencies in container images.
5. **Resource Exhaustion:** PriorityClasses and resource limits prevent noisy neighbors.

### Threats Not Fully Addressed

1. **Lateral Movement:** Without NetworkPolicies, a compromised pod can access other services.
2. **Privileged Escalation:** No Pod Security Admission means privileged containers are possible if configured.
3. **Data Encryption at Rest:** Secrets in etcd are not encrypted at rest in this configuration.
4. **DDoS:** No rate limiting or DDoS protection at the network level.
5. **Insider Threats:** RBAC provides some protection, but full audit logging and anomaly detection are limited.

## Security Roadmap

Areas for future improvement:

1. **Implement NetworkPolicies:** Start with default-deny and explicitly allow necessary traffic.
2. **Enable Pod Security Standards:** Enforce baseline or restricted policies via Pod Security Admission.
3. **Encrypt Secrets at Rest:** Enable etcd encryption for Kubernetes Secrets.
4. **Enable mTLS:** Use Cilium's service mesh capabilities for encrypted pod-to-pod communication.
5. **Migrate Policies to Enforce Mode:** Gradually move Kyverno policies from `audit` to `enforce` as maturity increases.
6. **Image Signature Verification:** Use Kyverno's image verification to require signed images.
7. **Enhanced Audit Logging:** Configure Kubernetes audit logs and forward to Loki for centralized analysis.

## References

- [Kyverno Component](../components/policy/kyverno/index.md): Policy engine details
- [Vault Component](../components/infrastructure/vault/index.md): Secrets management
- [Disaster Recovery](../operate/disaster-recovery.md): Availability strategy
- [Feature Toggles](../operate/feature-toggles.md): Policy mode configuration
