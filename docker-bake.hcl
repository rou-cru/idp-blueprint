// Overwrite from Task Env vars
variable "IMAGE_NAME" {
  type    = string
  default = "roucru/idp-blueprint"
}

// Overwrite from Task Env vars
variable "IMAGE_TAG" {
  type    = string
  default = "latest"
}

// Common configuration
target "default" {
  dockerfile = ".devcontainer/Dockerfile"
  context    = "."
  platforms  = ["linux/amd64"]
}

// Full variant (Dev Container)
target "dev" {
  inherits = ["default"]
  args = {
    DEVBOX_CONFIG = "devbox.json"
  }
  tags = ["${IMAGE_NAME}:${IMAGE_TAG}"]
  output = ["type=image"]
}

// Minimal variant (CI/Jobs)
target "minimal" {
  inherits = ["default"]
  args = {
    DEVBOX_CONFIG = ".devcontainer/devbox-minimal.json"
  }
  tags = ["${IMAGE_NAME}:${IMAGE_TAG}"]
  output = ["type=image"]
}

// Release full image
target "release" {
  inherits = ["dev"]
  output = ["type=image,push=true"]
}

// Release minimal image
target "release-minimal" {
  inherits = ["minimal"]
  output = ["type=image,push=true"]
}

// Jenkins Master variant
target "jenkins-master" {
  dockerfile = "K8s/cicd/jenkins/master.dockerfile"
  context    = "."
  platforms  = ["linux/amd64"]
  tags = ["roucru/jenkins:master"]
  output = ["type=image"]
}

// Jenkins Agent variant
target "jenkins-agent" {
  dockerfile = "K8s/cicd/jenkins/agent.dockerfile"
  context    = "."
  platforms  = ["linux/amd64"]
  tags = ["roucru/jenkins:agent"]
  output = ["type=image"]
}

// Release Jenkins Master image
target "release-jenkins-master" {
  inherits = ["jenkins-master"]
  output = ["type=image,push=true"]
}

// Release Jenkins Agent image
target "release-jenkins-agent" {
  inherits = ["jenkins-agent"]
  output = ["type=image,push=true"]
}

// Group to build both Jenkins images locally
group "jenkins-all" {
  targets = ["jenkins-master", "jenkins-agent"]
}

// Group to release both Jenkins images
group "release-jenkins-all" {
  targets = ["release-jenkins-master", "release-jenkins-agent"]
}
