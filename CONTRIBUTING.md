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

- **[IT/ARCHITECTURE.md](./IT/ARCHITECTURE.md)**: Describes the structure of the
  **bootstrap layer**, which includes core components like the CNI and secret
  management.
- **[K8s/ARCHITECTURE.md](./K8s/ARCHITECTURE.md)**: Describes the **GitOps structure** for
  all application stacks managed by ArgoCD, including the "App of AppSets" pattern.

## Helm Chart Values Documentation

### Justification

To maintain consistency and enable the automatic generation of documentation from
comments, all `values.yaml` files for Helm charts in this project **MUST** follow the
`helm-docs` syntax.

This allows us to treat the `values.yaml` file as the single source of truth for
configuration, from which user-facing documentation can be generated automatically.

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