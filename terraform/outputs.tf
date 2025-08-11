output "service_url" {
  description = "The URL of the deployed Cloud Run service"
  value       = google_cloud_run_service.insight_agent.status[0].url
}

output "artifact_registry_repository" {
  description = "The name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.insight_agent_repo.name
}

output "service_account_email" {
  description = "The email of the service account used by Cloud Run"
  value       = google_service_account.insight_agent_sa.email
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region where resources are deployed"
  value       = var.region
} 