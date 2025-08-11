# Deployment script for Insight-Agent - handles the whole deployment process
# You can run this manually or as part of your CI/CD pipeline

param(
    [string]$ProjectId = $env:GCP_PROJECT_ID,
    [string]$Region = $env:GCP_REGION,
    [string]$ImageTag = "latest"
)

# Set up some config variables we'll use throughout
$ServiceName = "insight-agent"
$Repository = "insight-agent-repo"

# Functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Make sure gcloud is installed
    try {
        $null = Get-Command gcloud -ErrorAction Stop
    }
    catch {
        Write-Error "gcloud CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check for Docker too
    try {
        $null = Get-Command docker -ErrorAction Stop
    }
    catch {
        Write-Error "Docker is not installed. Please install it first."
        exit 1
    }
    
    # Terraform is optional but nice to have
    try {
        $null = Get-Command terraform -ErrorAction Stop
    }
    catch {
        Write-Warn "Terraform is not installed. Skipping infrastructure deployment."
        $script:SkipTerraform = $true
    }
    
    Write-Info "Prerequisites check completed."
}

function Authenticate-GCP {
    Write-Info "Authenticating with GCP..."
    
    if ([string]::IsNullOrEmpty($ProjectId)) {
        Write-Error "GCP_PROJECT_ID environment variable is not set."
        exit 1
    }
    
    # Set the project we want to work with
    gcloud config set project $ProjectId
    
    # Check if we're already logged in
    $authStatus = gcloud auth list --filter="status:ACTIVE" --format="value(account)"
    if ([string]::IsNullOrEmpty($authStatus)) {
        Write-Info "Please authenticate with GCP..."
        gcloud auth login
    }
    
    Write-Info "GCP authentication completed."
}

function Build-AndPush-Image {
    Write-Info "Building and pushing Docker image..."
    
    # Build the Docker image first
    docker build -t "gcr.io/$ProjectId/$ServiceName`:$ImageTag" .
    
    # Tell Docker how to authenticate with GCP
    gcloud auth configure-docker
    
    # Push it up to the registry
    docker push "gcr.io/$ProjectId/$ServiceName`:$ImageTag"
    
    Write-Info "Docker image built and pushed successfully."
}

function Deploy-Infrastructure {
    if ($script:SkipTerraform) {
        Write-Warn "Skipping infrastructure deployment (Terraform not available)."
        return
    }
    
    Write-Info "Deploying infrastructure with Terraform..."
    
    Push-Location terraform
    
    # Initialize Terraform first
    terraform init
    
    # Plan out what we're going to deploy
    terraform plan `
        -var="project_id=$ProjectId" `
        -var="region=$Region" `
        -var="container_image=gcr.io/$ProjectId/$ServiceName`:$ImageTag" `
        -out=tfplan
    
    # Actually deploy the infrastructure
    terraform apply tfplan
    
    Pop-Location
    
    Write-Info "Infrastructure deployment completed."
}

function Deploy-Service {
    Write-Info "Deploying Cloud Run service..."
    
    # Deploy our app to Cloud Run
    gcloud run deploy $ServiceName `
        --image="gcr.io/$ProjectId/$ServiceName`:$ImageTag" `
        --region=$Region `
        --platform="managed" `
        --allow-unauthenticated=false `
        --port=8080 `
        --memory=512Mi `
        --cpu=1000m `
        --max-instances=10 `
        --min-instances=0
    
    Write-Info "Cloud Run service deployed successfully."
}

function Get-ServiceUrl {
    Write-Info "Getting service URL..."
    
    $script:ServiceUrl = gcloud run services describe $ServiceName `
        --region=$Region `
        --format="value(status.url)"
    
    Write-Info "Service URL: $script:ServiceUrl"
}

function Test-Service {
    Write-Info "Testing the deployed service..."
    
    if ([string]::IsNullOrEmpty($script:ServiceUrl)) {
        Get-ServiceUrl
    }
    
    # Test the health endpoint first
    try {
        $response = Invoke-RestMethod -Uri "$($script:ServiceUrl)/health" -Method Get
        Write-Info "Health check passed!"
    }
    catch {
        Write-Error "Health check failed!"
        exit 1
    }
    
    # Now test the main analyze endpoint
    try {
        $body = @{
            text = "Hello from PowerShell deployment script!"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$($script:ServiceUrl)/analyze" -Method Post -Body $body -ContentType "application/json"
        
        if ($response.word_count) {
            Write-Info "Analyze endpoint test passed!"
            Write-Info "Response: $($response | ConvertTo-Json)"
        }
        else {
            Write-Error "Analyze endpoint test failed!"
            exit 1
        }
    }
    catch {
        Write-Error "Analyze endpoint test failed: $($_.Exception.Message)"
        exit 1
    }
}

# Main function - runs the whole deployment process
function Main {
    Write-Info "Starting Insight-Agent deployment..."
    
    Test-Prerequisites
    Authenticate-GCP
    Build-AndPush-Image
    Deploy-Infrastructure
    Deploy-Service
    Get-ServiceUrl
    Test-Service
    
    Write-Info "Deployment completed successfully!"
    Write-Info "Service is available at: $script:ServiceUrl"
}

# Run the main function
Main 