terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com"
  ])

  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_artifact_registry_repository" "insight_agent_repo" {
  location      = var.region
  repository_id = "insight-agent-repo"
  description   = "Docker repository for Insight-Agent service"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}

resource "google_service_account" "insight_agent_sa" {
  account_id   = "insight-agent-sa"
  display_name = "Service Account for Insight-Agent Cloud Run service"
  description  = "Least-privilege service account for Insight-Agent"

  depends_on = [google_project_service.required_apis]
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.insight_agent_sa.email}"

  depends_on = [google_service_account.insight_agent_sa]
}

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

      service_account_name  = google_service_account.insight_agent_sa.email
      container_concurrency = 80
      timeout_seconds       = 300
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

resource "google_cloud_run_service_iam_member" "no_public_access" {
  location = google_cloud_run_service.insight_agent.location
  service  = google_cloud_run_service.insight_agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

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