# Makefile for Insight-Agent - makes common tasks easier
.PHONY: help install test lint build run clean deploy-local terraform-init terraform-plan terraform-apply

# Show all available commands
help:
	@echo "Available commands:"
	@echo "  install        - Install Python dependencies"
	@echo "  test           - Run tests"
	@echo "  lint           - Run linting checks"
	@echo "  build          - Build Docker image"
	@echo "  run            - Run application locally"
	@echo "  clean          - Clean up generated files"
	@echo "  deploy-local   - Deploy locally with Docker"
	@echo "  terraform-init - Initialize Terraform"
	@echo "  terraform-plan - Plan Terraform changes"
	@echo "  terraform-apply- Apply Terraform changes"

# Install all the Python packages we need
install:
	cd app && pip install -r requirements.txt
	cd app && pip install pytest pytest-asyncio httpx flake8 black

# Run the test suite
test:
	cd app && python -m pytest -v

# Check code quality with linting tools
lint:
	cd app && flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	cd app && black --check .

# Build the Docker image
build:
	docker build -t insight-agent:latest .

# Run the app locally (without Docker)
run:
	cd app && python main.py

# Clean up generated files and caches
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name ".pytest_cache" -delete
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true

# Deploy the app locally using Docker
deploy-local: build
	docker run -d -p 8080:8080 --name insight-agent insight-agent:latest
	@echo "Service running at http://localhost:8080"
	@echo "Use 'docker stop insight-agent && docker rm insight-agent' to stop"

# Terraform commands for infrastructure management
terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan

terraform-apply:
	cd terraform && terraform apply

# Stop and remove the local Docker container
stop-local:
	docker stop insight-agent || true
	docker rm insight-agent || true

# Show logs from the local container
logs:
	docker logs insight-agent || echo "No local container running"

# Check if the local service is healthy
health:
	curl -f http://localhost:8080/health || echo "Service not responding" 