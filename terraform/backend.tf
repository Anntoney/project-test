# Store Terraform state in GCS - keeps it safe and shareable between team members
# You can customize this based on what you need

terraform {
  backend "gcs" {
    bucket = "insight-agent-terraform-state"
    prefix = "terraform/state"
  }
}

# Note: You'll need to create the GCS bucket manually or use a different backend
# For local development, you can comment out the backend block above
# and Terraform will use local state storage 