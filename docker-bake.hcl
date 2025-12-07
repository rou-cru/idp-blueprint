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

// Variant tags
variable "IMAGE_TAG_MINIMAL" {
  type    = string
  default = "minimal"
}

variable "IMAGE_TAG_OPS" {
  type    = string
  default = "ops"
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
  tags = ["${IMAGE_NAME}:${IMAGE_TAG_MINIMAL}"]
  output = ["type=image"]
}

// Ops variant (cluster utility jobs)
target "ops" {
  inherits = ["default"]
  args = {
    DEVBOX_CONFIG = ".devcontainer/devbox-ops.json"
  }
  tags = ["${IMAGE_NAME}:${IMAGE_TAG_OPS}"]
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

// Release ops image
target "release-ops" {
  inherits = ["ops"]
  output = ["type=image,push=true"]
}

// Dev Portal (Backstage) - Host Build
target "dev-portal" {
  dockerfile = "packages/backend/Dockerfile"
  context    = "UI"
  platforms  = ["linux/amd64"]
  tags       = ["${IMAGE_NAME}-dev-portal:${IMAGE_TAG}"]
  output     = ["type=image"]
}

// Dev Portal (Backstage) - Release with Push
target "dev-portal-release" {
  inherits = ["dev-portal"]
  output   = ["type=image,push=true"]
}
