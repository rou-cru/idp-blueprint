# Security Policy

## Overview

The IDP Blueprint is a reference implementation for Internal Developer Platforms. Security is a critical concern as it includes components for secrets management (Vault), policy enforcement (Kyverno), and infrastructure-as-code.

We take security seriously and appreciate your efforts to responsibly disclose any security vulnerabilities.

## Supported Versions

The following versions of the IDP Blueprint are currently supported with security updates:

| Version | Supported          | Notes |
| ------- | ------------------ | ----- |
| main    | :white_check_mark: | Latest development version |
| Latest release | :white_check_mark: | Current stable release |
| Older releases | :x: | Please upgrade to latest |

**Note:** This is a **reference implementation** intended for learning and development environments. For production deployments, please:

- Review all configurations
- Harden secrets management
- Customize security policies
- Follow your organization's security standards

## Reporting a Vulnerability

We use GitHub's private vulnerability reporting feature. This allows you to report security issues privately.

### How to Report

1. **Preferred Method - GitHub Security Advisories:**
   - Go to the [Security tab](https://github.com/rou-cru/idp-blueprint/security/advisories)
   - Click "Report a vulnerability"
   - Fill in the details using the template provided

2. **Alternative Method - Direct Contact:**
   - If you prefer not to use GitHub's reporting system, email: [REPLACE WITH YOUR EMAIL]
   - Include "[SECURITY]" in the subject line
   - Provide detailed information about the vulnerability

### What to Include

Please include the following in your report:

- **Description** of the vulnerability
- **Steps to reproduce** the issue
- **Impact** assessment (who is affected, what's the severity)
- **Affected components** (e.g., Vault configuration, Kyverno policies, ArgoCD setup)
- **Potential fix** (if you have suggestions)
- **Your contact information** for follow-up questions

### What to Expect

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Resolution Timeline:** Depends on severity and complexity

We aim to:

1. Confirm receipt of your report within 2 business days
2. Provide an initial assessment within 7 days
3. Keep you informed of our progress
4. Credit you in the security advisory (unless you prefer to remain anonymous)

## Security Best Practices

When using the IDP Blueprint, we recommend:

### For Development/Learning Environments

- ✅ Use isolated networks (Docker networks, K3d default setup)
- ✅ Don't expose services to the internet
- ✅ Use strong passwords (change defaults in `config.toml`)
- ✅ Keep components updated (`task destroy && task deploy`)
- ✅ Review Kyverno policies before applying

### For Production-like Environments

- ✅ **Secrets Management:**
  - Don't commit secrets to Git
  - Use proper secret backends (Vault with production backend)
  - Rotate secrets regularly
  - Use External Secrets Operator properly

- ✅ **Network Security:**
  - Implement proper network policies
  - Use Cilium Network Policies
  - Enable TLS everywhere (cert-manager is included)
  - Restrict ingress/egress traffic

- ✅ **Policy Enforcement:**
  - Review and customize Kyverno policies
  - Enable policy enforcement mode (not audit)
  - Add organization-specific policies
  - Monitor policy violations

- ✅ **Access Control:**
  - Change default passwords immediately
  - Use RBAC properly
  - Enable ArgoCD SSO
  - Implement least-privilege access

- ✅ **Monitoring:**
  - Enable security scanning (Trivy)
  - Monitor audit logs
  - Set up alerts for security events
  - Review Grafana dashboards regularly

- ✅ **Updates:**
  - Keep Kubernetes version updated
  - Update Helm charts regularly
  - Monitor security advisories
  - Test updates in dev first

## Known Security Considerations

### Default Passwords

The blueprint includes **default passwords** in `config.toml` for:

- ArgoCD admin
- Grafana admin
- SonarQube admin
- Vault root token (dev mode)

**⚠️ WARNING:** These MUST be changed for any non-local deployment!

### Dev Mode Components

Some components run in **development mode** by default:

- **Vault:** Uses in-memory storage (no persistence, unseals automatically)
- **ArgoCD:** Insecure admin password
- **No authentication** on some services

**⚠️ WARNING:** Do NOT use dev mode in production!

### Exposed Ports

K3d exposes NodePorts `30080` and `30443` by default. These are:

- Safe on localhost
- **Unsafe** if your machine is accessible from network
- Should be restricted with firewall rules

### Secrets in Git

**NEVER commit:**

- Real passwords or API keys
- TLS private keys
- Vault tokens
- Registry credentials
- Any production secrets

The repository includes:

- `.config/lint/.trufflehog-ignore` to prevent common secrets
- `task quality:security` to scan for secrets
- GitHub Actions secret scanning

## Security Scanning

The project includes automated security scanning:

### Local Scanning

```bash
# Run all security scans
task quality:security

# Individual scans
checkov --directory .         # IaC scanning
trufflehog filesystem .       # Secret scanning
```

### CI/CD Scanning

- GitHub Actions runs security scans on every PR
- Checkov scans Kubernetes manifests and Helm charts
- Trufflehog scans for hardcoded secrets
- Dependabot monitors dependencies

## Disclosure Policy

When we receive a security report:

1. We will confirm the vulnerability
2. We will develop a fix
3. We will prepare a security advisory
4. We will release the fix
5. We will publish the advisory

We follow **coordinated disclosure**:

- We will work with you on timing
- Typical embargo: 90 days or until fix is available
- We will credit you (unless you prefer anonymity)

## Hall of Fame

We appreciate security researchers who help us keep the IDP Blueprint secure:

<!-- Add names of security researchers who have reported valid vulnerabilities -->

*No vulnerabilities reported yet*

## Contact

For security concerns:

- **GitHub Security Advisories:** [Report a vulnerability](https://github.com/rou-cru/idp-blueprint/security/advisories/new)
- **Email:** [REPLACE WITH YOUR EMAIL]
- **PGP Key:** [Optional: Add PGP key fingerprint]

For general questions:

- **GitHub Discussions:** <https://github.com/rou-cru/idp-blueprint/discussions>
- **Issues:** <https://github.com/rou-cru/idp-blueprint/issues>

## References

- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NSA Kubernetes Hardening Guide](https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/2716980/nsa-cisa-release-kubernetes-hardening-guidance/)
- [Vault Security Model](https://www.vaultproject.io/docs/internals/security)
- [Kyverno Best Practices](https://kyverno.io/policies/)

---

*Last updated: 2025-11-23*
