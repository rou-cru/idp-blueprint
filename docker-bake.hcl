// Overwrite from Task Env vars
variable "IMAGE_NAME" {
  type = string
  default = "idp-blueprint"
}

// Overwrite from Task Env vars
variable "IMAGE_TAG" {
  type = string
  default = "latest"
}

// Just build, use for testing
target "dev" {
  dockerfile = ".devcontainer/Dockerfile"
  context    = "."
  tags       = ["${IMAGE_NAME}:${IMAGE_TAG}"]
  platforms = ["linux/amd64"]
  output = ["type=image"]
}

// Build and Push to Registry
target "release" {
  // Hereda la configuración del target "default".
  inherits = ["dev"]
  output = ["type=image, push=true"] 
}