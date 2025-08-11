# Insight-Agent - GCP Cloud Run Deployment

A production-ready, serverless deployment of the Insight-Agent service on Google Cloud Platform, featuring automated CI/CD, infrastructure as code, and secure configurations.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions  │───▶│  GCP Services   │
│                 │    │   CI/CD Pipeline │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Docker Build    │    │  Cloud Run      │
                       │  & Push to AR    │    │  Service        │
                       └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Terraform      │    │  Artifact       │
                       │  Infrastructure │    │  Registry       │
                       └──────────────────┘    └─────────────────┘
```

### GCP Services Used
- **Cloud Run**: Serverless container platform for running the application
- **Artifact Registry**: Secure Docker image storage
- **Cloud Build**: Automated container building and deployment
- **IAM**: Identity and access management with least-privilege principles

## 🎯 Design Decisions

### Why Cloud Run?
- **Serverless**: No infrastructure management required
- **Auto-scaling**: Scales to zero when not in use, saving costs
- **Security**: Built-in security features and isolation
- **Performance**: Cold start optimization and fast response times

### Security Approach
- **Least-privilege service accounts**: Dedicated service account with minimal permissions
- **No public access**: Service is not publicly accessible by default
- **Container security**: Non-root user, minimal base image
- **Network isolation**: Internal-only access patterns

### CI/CD Strategy
- **GitHub Actions**: Familiar tooling for most developers
- **Automated testing**: Linting, unit tests, and validation
- **Infrastructure as Code**: Terraform for reproducible deployments
- **Immutable deployments**: Each deployment gets a unique image tag

## 🚀 Quick Start

### Prerequisites
- Google Cloud Platform account with billing enabled
- Google Cloud CLI (gcloud) installed and configured
- Terraform >= 1.0 installed
- Docker installed
- GitHub repository with access to GitHub Actions

### 1. Set Up GCP Project

```bash
# Create a new project (or use existing)
gcloud projects create insight-agent-project --name="Insight Agent Project"

# Set the project as default
gcloud config set project insight-agent-project

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable iam.googleapis.com
```

### 2. Create Service Account for CI/CD

```bash
# Create service account
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions Service Account"

# Grant necessary roles
gcloud projects add-iam-policy-binding insight-agent-project \
    --member="serviceAccount:github-actions@insight-agent-project.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding insight-agent-project \
    --member="serviceAccount:github-actions@insight-agent-project.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding insight-agent-project \
    --member="serviceAccount:github-actions@insight-agent-project.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin"

# Create and download key
gcloud iam service-accounts keys create key.json \
    --iam-account=github-actions@insight-agent-project.iam.gserviceaccount.com
```

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_SA_KEY`: The entire content of the `key.json` file from step 2

### 4. Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars file
cat > terraform.tfvars <<EOF
project_id = "insight-agent-project"
region     = "us-central1"
EOF

# Plan and apply
terraform plan
terraform apply
```

### 5. Test the Deployment

```bash
# Get the service URL
gcloud run services describe insight-agent --region=us-central1 --format="value(status.url)"

# Test the health endpoint
curl https://YOUR_SERVICE_URL/health

# Test the analyze endpoint
curl -X POST https://YOUR_SERVICE_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, Cloud Run!"}'
```

## 🔧 Local Development

### Run the Application Locally

```bash
# Install dependencies
cd app
pip install -r requirements.txt

# Run the application
python main.py
```

### Run Tests Locally

```bash
cd app
pip install pytest pytest-asyncio httpx
pytest -v
```

### Build and Test Docker Image

```bash
# Build image
docker build -t insight-agent:latest .

# Run container
docker run -p 8080:8080 insight-agent:latest

# Test locally
curl http://localhost:8080/health
```

## 📁 Project Structure

```
insight-agent/
├── app/                          # Python application
│   ├── main.py                  # FastAPI application
│   ├── requirements.txt         # Python dependencies
│   └── test_main.py            # Unit tests
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output values
│   └── backend.tf              # State backend configuration
├── .github/                     # GitHub Actions workflows
│   └── workflows/
│       └── deploy.yml          # CI/CD pipeline
├── Dockerfile                   # Container definition
└── README.md                   # This file
```

## 🔒 Security Features

- **Non-root container**: Application runs as non-privileged user
- **Least-privilege IAM**: Service accounts with minimal required permissions
- **Private service**: No public internet access by default
- **Secure image registry**: Artifact Registry with IAM controls
- **Encrypted storage**: All data encrypted at rest and in transit

## 📊 Monitoring and Observability

- **Health checks**: Built-in health endpoint for load balancers
- **Structured logging**: JSON-formatted logs for easy parsing
- **Metrics**: Cloud Run provides built-in metrics and monitoring
- **Error handling**: Comprehensive error handling with proper HTTP status codes

## 🚨 Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Ensure the service account has the correct IAM roles
   - Check that the GitHub Actions secret is properly formatted

2. **Container Build Failures**
   - Verify Docker is running locally
   - Check that the Dockerfile syntax is correct

3. **Terraform State Issues**
   - Ensure the GCS bucket exists for the backend
   - Check that the service account has access to the bucket

4. **Service Not Accessible**
   - Verify the IAM policy was applied correctly
   - Check Cloud Run service logs for errors

### Useful Commands

```bash
# View Cloud Run service logs
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=insight-agent" --limit=50

# Check service status
gcloud run services describe insight-agent --region=us-central1

# View recent deployments
gcloud run revisions list --service=insight-agent --region=us-central1
```

## 🔄 CI/CD Pipeline Details

The GitHub Actions workflow performs the following steps:

1. **Test Job**: Runs Python tests and linting
2. **Terraform Validation**: Validates infrastructure configuration
3. **Build and Deploy**: Builds Docker image, pushes to registry, and deploys

### Pipeline Triggers
- Push to `main` branch
- Pull request to `main` branch
- Manual workflow dispatch

### Deployment Process
1. Authenticate with GCP using service account
2. Build Docker image with commit SHA tag
3. Push image to Artifact Registry
4. Apply Terraform configuration
5. Remove public access to ensure security
6. Output deployment information

## 💰 Cost Optimization

- **Cloud Run**: Scales to zero when not in use
- **Artifact Registry**: Pay only for storage and data transfer
- **Terraform state**: Use GCS for state storage (minimal cost)
- **Auto-scaling**: Configured to scale between 0-10 instances

## 🔮 Future Enhancements

- **Custom domain**: Add custom domain with SSL certificate
- **CDN**: Implement Cloud CDN for global performance
- **Monitoring**: Add custom metrics and alerting
- **Multi-region**: Deploy to multiple regions for high availability
- **API Gateway**: Add API Gateway for advanced routing and rate limiting

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Cloud Run logs and metrics
3. Check GitHub Actions workflow execution logs
4. Verify Terraform state and configuration

## 📄 License

This project is provided as-is for educational and demonstration purposes. Please ensure compliance with your organization's security and deployment policies. #   T r i g g e r   d e p l o y m e n t  
 