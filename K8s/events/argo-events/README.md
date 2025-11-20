# Argo Events

Event-driven workflow automation for Kubernetes.

## Overview

Argo Events is the central event mesh for the IDP, enabling reactive automation
across all platform components. It watches Kubernetes resources, schedules tasks,
and triggers Argo Workflows based on events.

## Components

- **Controller**: Manages EventSources, Sensors, and EventBus resources
- **Webhook**: Validates Argo Events custom resources

## Integration Points

Future integrations planned:

- Trivy VulnerabilityReports → Security workflows
- Kyverno PolicyReports → Compliance automation
- ArgoCD Applications → GitOps audit trails
- Cert-Manager Certificates → Expiry notifications
- Calendar-based scheduled jobs

## Values

See `values.yaml` for all configurable parameters with helm-docs annotations.
