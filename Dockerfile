# Using Python 3.11 slim - smaller image and better security
FROM python:3.11-slim

# Set some env vars - helps with Python and tells the app which port to use
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PORT=8080

# Create a non-root user - security best practice
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install some system deps we'll need
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy requirements first - helps with Docker layer caching
COPY app/requirements.txt .

# Install the Python packages we need
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the actual app code
COPY app/ .

# Give the app user ownership of the app directory
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 8080

# Health check - makes sure the app is actually running
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start the app
CMD ["python", "main.py"] 