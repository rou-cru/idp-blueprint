# Logs JSON enablement exclusions (Dec 24, 2025)

## Excluded components and reasons

- SonarQube (K8s/cicd/sonarqube/values.yaml)
  - Status: JSON logging already enabled via `sonarProperties.sonar.log.jsonOutput: true`.
  - Reason excluded: already configured in values; no additional changes required.

- Kyverno (K8s/policies/infrastructure/kyverno/values.yaml)
  - Status: JSON logging already enabled via `features.logging.format: json`.
  - Reason excluded: already configured in values; no additional changes required.

- Backstage (K8s/backstage/backstage/values.yaml)
  - Status: No Helm values toggle for JSON output; requires code change to override root logger.
  - Reason excluded: requires application code change (out of scope).

- External Secrets Operator (IT/external-secrets/values.yaml)
  - Status: Chart exposes `log.level` and `log.timeEncoding` only; no JSON format toggle in values.
  - Reason excluded: chart does not provide JSON log format setting.

- Argo Events (K8s/events/argo-events/values.yaml)
  - Status: Chart values do not expose log format options.
  - Reason excluded: chart does not provide JSON log format setting.
