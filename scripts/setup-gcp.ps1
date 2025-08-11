# GCP setup script for Insight-Agent - gets everything ready for deployment
param([Parameter(Mandatory=$true)][string]$ProjectId)

Write-Host "Setting up GCP for Insight-Agent..." -ForegroundColor Green

# Check if we're logged into GCP
Write-Host "Checking GCP authentication..." -ForegroundColor Yellow
$authStatus = gcloud auth list --filter="status:ACTIVE" --format="value(account)"
if ([string]::IsNullOrEmpty($authStatus)) {
    Write-Host "Please authenticate with GCP..." -ForegroundColor Red
    gcloud auth login
}

# Create a new GCP project for our app
Write-Host "Creating GCP project: $ProjectId" -ForegroundColor Yellow
gcloud projects create $ProjectId --name="Insight Agent Project"
gcloud config set project $ProjectId

# Turn on the APIs we need for Cloud Run and stuff
Write-Host "Enabling required APIs..." -ForegroundColor Yellow
$apis = @("run.googleapis.com", "artifactregistry.googleapis.com", "cloudbuild.googleapis.com", "iam.googleapis.com")
foreach ($api in $apis) { gcloud services enable $api }

# Create a service account for GitHub Actions to use
Write-Host "Creating service account..." -ForegroundColor Yellow
gcloud iam service-accounts create github-actions --display-name="GitHub Actions"
$saEmail = "github-actions@$ProjectId.iam.gserviceaccount.com"

# Give the service account the permissions it needs
$roles = @("roles/run.admin", "roles/artifactregistry.admin", "roles/iam.serviceAccountAdmin")
foreach ($role in $roles) {
    gcloud projects add-iam-policy-binding $ProjectId --member="serviceAccount:$saEmail" --role=$role
}

# Create a key file that GitHub Actions can use
Write-Host "Creating service account key..." -ForegroundColor Yellow
gcloud iam service-accounts keys create key.json --iam-account=$saEmail

Write-Host "Setup complete! Add GCP_PROJECT_ID=$ProjectId and GCP_SA_KEY from key.json to GitHub Secrets" -ForegroundColor Green 