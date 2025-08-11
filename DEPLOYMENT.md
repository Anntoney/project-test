# 🚀 Deployment Guide

## Quick Start

### 1. Install Tools
```powershell
# Install Google Cloud CLI
winget install Google.CloudSDK

# Install Docker Desktop  
winget install Docker.DockerDesktop

# Install Terraform
winget install HashiCorp.Terraform
```

### 2. Setup GCP
```powershell
# Run setup script
.\scripts\setup-gcp.ps1 -ProjectId "your-project-id"
```

### 3. Add GitHub Secrets
- `GCP_PROJECT_ID`: Your project ID
- `GCP_SA_KEY`: Content of key.json

### 4. Deploy
```powershell
# Push to GitHub (triggers CI/CD)
git push origin main

# Or deploy manually
.\scripts\deploy.ps1 -ProjectId "your-project-id"
```

## Manual Steps

1. **Authenticate**: `gcloud auth login`
2. **Create Project**: `gcloud projects create PROJECT_ID`
3. **Enable APIs**: Cloud Run, Artifact Registry, Cloud Build, IAM
4. **Create Service Account**: With proper IAM roles
5. **Deploy Infrastructure**: Using Terraform
6. **Deploy Service**: To Cloud Run

## Testing

```powershell
# Get service URL
gcloud run services describe insight-agent --region=us-central1

# Test endpoints
curl https://YOUR_URL/health
curl -X POST https://YOUR_URL/analyze -d '{"text":"Hello!"}'
``` 