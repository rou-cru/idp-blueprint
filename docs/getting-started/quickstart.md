# Getting Started - Quick Start

Get your IDP Blueprint up and running in minutes with this quick start guide.

## Step 1: Clone the Repository

```bash
git clone https://github.com/rou-cru/idp-blueprint
cd idp-blueprint
```

## Step 2: Open in VS Code Dev Container

```bash
code .
```

When prompted, click **"Reopen in Container"** to start the development environment.

> **Note**: The first time you do this, it will take a few minutes to download and set up the development environment.

## Step 3: Deploy the Platform

Once inside the Dev Container, run:

```bash
task deploy
```

> **Time**: Deployment takes approximately 5-10 minutes depending on your system and internet connection.

## Step 4: Access the Platform

After deployment completes, you can access the platform components:

- **ArgoCD**: `https://argocd.<your-ip>.nip.io`
- **Grafana**: `https://grafana.<your-ip>.nip.io`
- **Vault**: `https://vault.<your-ip>.nip.io`
- **SonarQube**: `https://sonarqube.<your-ip>.nip.io`
- **Argo Workflows**: `https://workflows.<your-ip>.nip.io`

Default credentials will be available in your local Vault instance.

## Step 5: Explore

- Check the running components in ArgoCD
- View metrics and logs in Grafana
- Run a sample workflow in Argo Workflows
- Try out SonarQube analysis

## What's Next?

- Visit the [Deployment](deployment.md) guide for more detailed information
- Check out the [Architecture](../architecture/overview.md) to understand how everything works
- Explore the different [Components](../components/infrastructure/index.md)