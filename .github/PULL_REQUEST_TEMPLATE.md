## Description

<!-- Provide a clear and concise description of your changes -->

## Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] 🔧 Configuration change
- [ ] ♻️ Refactoring (no functional changes)
- [ ] 🔒 Security fix
- [ ] ⚡ Performance improvement
- [ ] 🎨 UI/UX improvement
- [ ] 🧪 Test addition/update

## Component(s) Affected

<!-- Mark all that apply -->

- [ ] K3d Cluster
- [ ] ArgoCD / GitOps
- [ ] Cilium / Networking
- [ ] Vault / Secrets Management
- [ ] Kyverno / Policies
- [ ] Observability (Prometheus/Grafana/Loki)
- [ ] CI/CD (Argo Workflows/SonarQube)
- [ ] cert-manager / TLS
- [ ] Gateway API
- [ ] Documentation
- [ ] GitHub Actions / CI
- [ ] Task Automation
- [ ] Scripts
- [ ] Configuration
- [ ] Other: _____________

## Motivation and Context

<!-- Why is this change required? What problem does it solve? -->
<!-- Link to related issue(s) using: Closes #123, Fixes #456, Relates to #789 -->

## Changes Made

<!-- List the specific changes made in this PR -->

-
-
-

## Testing Performed

<!-- Describe the testing you've done -->

- [ ] Local deployment with `task deploy`
- [ ] Tested on clean cluster
- [ ] Tested upgrade path
- [ ] Validated ArgoCD sync
- [ ] Checked component health (`kubectl get pods -A`)
- [ ] Verified logs (`kubectl logs`)
- [ ] Tested rollback scenario
- [ ] Manual testing: <!-- describe what you tested -->
- [ ] Other: _____________

## Quality Checklist

<!-- Verify that quality checks pass -->

- [ ] `task quality:lint` passes (YAML, Shell, Dockerfile, Markdown, Helm)
- [ ] `task quality:validate` passes (Kustomize, Kubeval)
- [ ] `task quality:security` passes (Checkov, Trufflehog)
- [ ] CI pipeline passes
- [ ] No secrets or sensitive data committed
- [ ] Configuration changes documented in `config.toml` (if applicable)
- [ ] Helm chart values documented (if applicable)

## Documentation

<!-- Mark all that apply -->

- [ ] Updated relevant documentation in `/Docs`
- [ ] Updated README.md (if applicable)
- [ ] Updated CONTRIBUTING.md (if applicable)
- [ ] Added/updated code comments for complex logic
- [ ] Updated Helm chart README (if applicable)
- [ ] Updated configuration reference (if applicable)
- [ ] No documentation changes needed

## Breaking Changes

<!-- If this is a breaking change, describe: -->
<!-- - What breaks -->
<!-- - Migration path for users -->
<!-- - Updated version in relevant files -->

N/A or:
-
-

## Screenshots/Logs

<!-- If applicable, add screenshots or relevant logs -->

<details>
<summary>Click to expand</summary>

```
Paste logs or add screenshots here
```

</details>

## Deployment Notes

<!-- Any special deployment considerations? -->
<!-- Configuration changes required? Manual steps? -->

- [ ] No special deployment notes
- [ ] Requires configuration changes: <!-- describe -->
- [ ] Requires manual steps: <!-- describe -->
- [ ] Requires specific order: <!-- describe -->

## Checklist

<!-- Final checks before submitting -->

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code in hard-to-understand areas
- [ ] My changes generate no new warnings
- [ ] I have tested that my changes work as expected
- [ ] I have checked that this PR doesn't introduce security issues
- [ ] I have updated the relevant documentation
- [ ] My commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)

## Additional Notes

<!-- Any additional information that reviewers should know -->
