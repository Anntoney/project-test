# Store Terraform state in GCS - keeps it safe and shareable between team members
# You can customize this based on what you need

# Note: Comment out the backend block for local development and CI/CD validation
# Uncomment when you're ready to use remote state storage
# terraform {
#   backend "gcs" {
#     bucket = "insight-agent-terraform-state"
#     prefix = "terraform/state"
#   }
# }

# For now, we'll use local state during development and CI/CD 