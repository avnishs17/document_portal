# Use official Python image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set workdir
WORKDIR /app

# Install OS dependencies for PDF processing and other requirements
RUN apt-get update && apt-get install -y \
    build-essential \
    poppler-utils \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user with specific UID (matches Kubernetes)
RUN groupadd -r appuser -g 1000 && useradd -r -u 1000 -g appuser appuser

# Copy project files first (needed for -e . in requirements.txt)
COPY . .

# Install Python dependencies with error handling
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Create necessary directories and set ownership
RUN mkdir -p /app/logs /app/data /app/faiss_index && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Run FastAPI with uvicorn (production mode)
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]