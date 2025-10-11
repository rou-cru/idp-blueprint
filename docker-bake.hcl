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