terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  
  # Store state in GCS - keeps it safe and shareable
  backend "gcs" {
    bucket = "insight-agent-terraform-state"
    prefix = "terraform/state"
  }
}

# Set up the Google provider - tells Terraform how to talk to GCP
provider "google" {
  project = var.project_id
  region  = var.region
}

# Turn on the APIs we need - Cloud Run, Artifact Registry, etc.
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com"
  ])
  
  service = each.value
  disable_dependent_services = false
  disable_on_destroy = false
}

# Create a place to store our Docker images
resource "google_artifact_registry_repository" "insight_agent_repo" {
  location      = var.region
  repository_id = "insight-agent-repo"
  description   = "Docker repository for Insight-Agent service"
  format        = "DOCKER"
  
  depends_on = [google_project_service.required_apis]
}

# Create a service account for the Cloud Run service - keeps things secure
resource "google_service_account" "insight_agent_sa" {
  account_id   = "insight-agent-sa"
  display_name = "Service Account for Insight-Agent Cloud Run service"
  description  = "Least-privilege service account for Insight-Agent"
  
  depends_on = [google_project_service.required_apis]
}

# Give the service account the permissions it needs
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.insight_agent_sa.email}"
  
  depends_on = [google_service_account.insight_agent_sa]
}

# Create the actual Cloud Run service - this is where our app runs
resource "google_cloud_run_service" "insight_agent" {
  name     = "insight-agent"
  location = var.region
  
  template {
    spec {
      containers {
        image = var.container_image
        
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
        
        ports {
          container_port = 8080
        }
        
        env {
          name  = "PORT"
          value = "8080"
        }
      }
      
      service_account_name = google_service_account.insight_agent_sa.email
      
      # Security stuff - no public access by default
      container_concurrency = 80
      timeout_seconds      = 300
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"
        "autoscaling.knative.dev/maxScale" = "10"
      }
    }
  }
  
  traffic {
    percent         = 100
    latest_revision = true
  }
  
  depends_on = [google_project_service.required_apis]
}

# Set up IAM policy - this will be cleaned up by CI/CD to block public access
resource "google_cloud_run_service_iam_member" "no_public_access" {
  location = google_cloud_run_service.insight_agent.location
  service  = google_cloud_run_service.insight_agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"
  
  # This gets removed by the CI/CD pipeline to make sure no one can access it publicly
  # In production you might want to restrict to specific service accounts or users
}

# Output the service URL - useful for testing and integration
output "service_url" {
  value       = google_cloud_run_service.insight_agent.status[0].url
  description = "The URL of the deployed Cloud Run service"
}

output "artifact_registry_repository" {
  value       = google_artifact_registry_repository.insight_agent_repo.name
  description = "The name of the Artifact Registry repository"
}

output "service_account_email" {
  value       = google_service_account.insight_agent_sa.email
  description = "The email of the service account used by Cloud Run"
} 