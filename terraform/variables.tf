variable "project_id" {
  description = "Your GCP project ID - where all the resources will live"
  type        = string
}

variable "region" {
  description = "Which GCP region to deploy to - us-central1 is usually a good choice"
  type        = string
  default     = "us-central1"
}

variable "container_image" {
  description = "The Docker image URL - CI/CD will set this automatically"
  type        = string
  default     = "gcr.io/PROJECT_ID/insight-agent:latest"
}

variable "environment" {
  description = "What environment this is - dev, staging, or prod"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
} 