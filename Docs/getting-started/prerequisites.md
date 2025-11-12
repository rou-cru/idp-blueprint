# Getting Started - Prerequisites

Before deploying the IDP Blueprint, ensure your system meets the following requirements.

## System Requirements

### Minimum Hardware

- **CPU**: 4 cores (6+ recommended)
- **Memory**: 8GB RAM (12GB+ recommended)
- **Storage**: 20GB available disk space
- **OS**: Linux, macOS, or Windows with WSL2

### Software Dependencies

The following software must be installed:

- **Docker**: With Docker Hub login (`docker login`)
- **Git**: Version 2.0 or higher
- **Visual Studio Code**: With Dev Containers extension
- **Docker Desktop**: For macOS/Windows users

> **Note**: This project uses VS Code Dev Containers to provide a pre-configured
> environment with all required tools (kubectl, helm, k3d, task, etc.).

## Docker Hub Authentication

To avoid severe rate limiting from Docker Hub:

1. Create a Docker Hub account if you don't have one
2. Run `docker login` and authenticate with your credentials

## Network Requirements

- Internet access for pulling container images
- Port availability for services (80, 443, 30080, 30443 by default)

## Optional Requirements

For enhanced functionality:

- A modern web browser with developer tools
- An IDE or text editor of your choice
