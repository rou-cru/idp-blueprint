# policy-reporter

![Version: latest](https://img.shields.io/badge/Version-latest-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://kyverno.github.io/policy-reporter)

Monitoring and observability for policy engine results

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `latest` |
| **Chart Type** | `application` |
| **Upstream Project** | [policy-reporter](https://kyverno.github.io/policy-reporter) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| policyReporter.resources | object | `{"limits":{"cpu":"200m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the core engine. |
| priorityClassName | string | `"platform-observability"` | Priority class for Policy Reporter |
| ui.enabled | bool | `true` | Enables the deployment of the Policy Reporter UI. |
| ui.resources | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the UI. |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
