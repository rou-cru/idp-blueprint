# Use the latest stable Jenkins LTS image with JDK 21
FROM jenkins/jenkins:lts-jdk21

# Switch to root user for installations
USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        && rm -rf /var/lib/apt/lists/*

# Install Jenkins plugins using the plugin manager
# Plugin list matches installPlugins from jenkins-values.yaml
RUN jenkins-plugin-cli --plugins \
    kubernetes \
    workflow-aggregator \
    git \
    configuration-as-code \
    prometheus \
    pipeline-graph-view \
    dark-theme \
    sonar \
    kubernetes-credentials-provider

# Switch back to the jenkins user
USER jenkins

# Skip initial setup wizard (use CasC instead)
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Expose Jenkins web interface and agent ports
EXPOSE 8080 50000

# Add a healthcheck to verify that the Jenkins UI is responsive.
# This addresses the CKV_DOCKER_2 security finding.
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl --fail http://localhost:8080/login || exit 1
