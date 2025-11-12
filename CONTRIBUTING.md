# Contribution Guidelines

This document outlines the conventions and best practices to follow when contributing to
this project. Adhering to these guidelines ensures consistency, quality, and
maintainability.

## Development Environment

This project uses a fully automated development environment based on **VS Code Dev
Containers** and **Devbox**. This approach ensures that all contributors use the exact
same tooling and dependencies, which are defined as code in the repository.

All required tools (linters, `kubectl`, `helm`, etc.) are automatically installed when
the container starts. Please refer to the [**Quick Start** section in the
README.md](./README.md#🚀-quick-start) for instructions on how to launch the
environment.

## Code Style and Quality Checks

We use a variety of linters and validation tools to maintain code quality and
consistency. These tools are managed via `devbox` and are orchestrated into simple
commands using `Task`.

Before submitting any changes, please run the following checks:

- **`task lint`**: Runs all linters for YAML, Markdown, shell scripts, and Dockerfiles.
- **`task check`**: A comprehensive command that runs all linters, manifest validation
  (`kustomize build`, `kubeval`), and security scans (`checkov`, `trufflehog`).

Running `task check` is highly recommended to ensure your contribution passes all
quality gates.

## Architectural Conventions

To maintain a clear and scalable structure, the project follows specific architectural
conventions. Before adding or modifying files, please read the following documents:

- **[Architecture Bootstrap](Docs/architecture/bootstrap.md)** –
  Describes the structure of the **bootstrap layer**, which includes core
  components like the CNI and secret management.
- **[GitOps Topology](Docs/architecture/gitops.md)** – Describes the **GitOps
  structure** for all application stacks managed by ArgoCD, including the "App
  of AppSets" pattern.

## Kubernetes Manifest Conventions

To ensure all Kubernetes resources are explicit, consistent, and easy to manage,
please adhere to the following rules when creating or modifying YAML manifests.

### Defining Requests and Limits

1. **Mandatory Definition:** All deployed workloads (Deployments, StatefulSets,
    etc.) **MUST** define both `requests` and `limits` for CPU and memory. This is
    critical for ensuring cluster stability, predictable performance, and proper
    node scheduling.

2. **CPU Limiting Philosophy:** This project enforces CPU limits. While there is an
    ongoing debate in the Kubernetes community about the effects of CPU limits
    (potential for throttling), this blueprint prioritizes predictable resource
    allocation and total capacity planning. By setting limits, we can provide
    clear hardware recommendations to users and prevent any single workload from
    starving others in a resource-constrained local environment.

> **Note on Exceptions:** The only intentional exception to this rule is the
> `cilium-agent`. As a privileged DaemonSet critical for all node networking,
> applying resource limits can be counter-productive and risk node stability.
> Therefore, it is intentionally deployed without CPU or memory limits.

### Resource Units

All CPU and memory resource values (`requests` and `limits`) **MUST** explicitly
include their units. Unitless integer values are not permitted as they are
ambiguous.

- **CPU:** Use millicores (e.g., `500m` instead of `0.5`).
- **Memory:** Use Mebibytes or Gibibytes (e.g., `512Mi`, `2Gi`).

**Example:**

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

## Helm Chart Values Documentation

### Justification

To maintain consistency and enable the automatic generation of documentation from
comments, all `values.yaml` files for Helm charts in this project **should** follow the
`helm-docs` syntax.

This allows us to treat the `values.yaml` file as the single source of truth for
configuration, from which user-facing documentation can be generated automatically, and
honestly, can be delegated that part to Gemini, Claude, ChatGPT or the LLM that you like!

- **Official Documentation:**
  [helm-docs on GitHub](https://github.com/norwoodj/helm-docs)

### Syntax Usage

The following conventions are the most common and are required for this project:

1. **Sections (`## @section <NAME>`):** Used to create major logical groups for
   parameters. This helps structure the generated documentation.

2. **Section Descriptions (`## @description <TEXT>`):** Used to provide a more detailed
   explanation for a section.

3. **Parameter Comments (`# -- <DESCRIPTION>`):** This is the most important convention.
   Any comment directly above a parameter that should be included in the documentation
   must start with `# --`.

4. **Default Values (`# @default -- <VALUE>`):** Optionally, you can specify the default
   value using this annotation. It is good practice to include it.

## Label Standards

This project enforces strict label standards to ensure consistency, policy compliance,
and resource discoverability across all Kubernetes resources.

### Required Documentation

All contributors **MUST** read and follow the standards defined in:

- **[Label Standards Reference](Docs/reference/labels-standard.md)** – Complete
  label standards, canonical values, and conventions

### Quick Reference

**Canonical Label Values:**

- `owner: platform-team`
- `business-unit: infrastructure`
- `environment: demo`
- `app.kubernetes.io/part-of: idp`

**Namespace Requirements (Enforced by Kyverno):**
All namespaces MUST include: `app.kubernetes.io/part-of`, `owner`, `business-unit`, and
`environment` labels.

**Comment Style for Values Files:**
Use `# @section -- Section Name` (single hash with double dash) for consistency with helm-docs.

### Validation

Before submitting changes:

1. Run `task lint` to validate YAML syntax
2. Run `kustomize build <directory>` to verify kustomization files
3. Check that labels comply with Kyverno policies defined in `Policies/rules/`

### Commit Hygiene and `git bisect`

This project values the use of **atomic commits**.
Each commit must represent a single, logical, and complete change.
While it can be tempting to group many changes into a single commit
before pushing(i did it many times and probably i'll do it again),
this practice severely harms the project's maintainability.

The primary reason for requiring atomic commits is to enable the effective use of `git bisect`,
a powerful tool for finding which commit introduced a bug.

- **With Atomic Commits:** `git bisect` can test each small change in isolation,
  precisely identifying the culprit.
- **With Large Commits:** If a commit contains 5 different changes, `git bisect` can only
  tell us that the bug is "somewhere in that giant commit",
  which is useless and forces manual debugging.

Additionally, atomic commits improve:

- **Easier Code Reviews:** They are faster and easier to review.
- **Safer Reverts:** They allow a specific change to be reverted without
  affecting other functionalities.
