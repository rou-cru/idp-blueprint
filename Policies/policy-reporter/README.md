# policy-reporter

This document lists the configuration parameters for the `policy-reporter` component.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| policyReporter.resources | object | `{"limits":{"cpu":"200m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the core engine. |
| ui.enabled | bool | `true` | Enables the deployment of the Policy Reporter UI. |
| ui.resources | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the UI. |