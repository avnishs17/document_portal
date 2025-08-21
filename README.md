
# Setup Guide for `document_portal`

## Step 1: Create project directory and virtual environment

```bash
mkdir document_portal
cd document_portal
conda create -p env python=3.10.18 -y
conda activate ./env
pip install uv
```

## Step 2: Create a requirements.txt file

```bash
# Step 3: Create basic project structure and files
# Step 4: Add the following to setup.py

```bash
from setuptools import setup,find_packages

with open("requirements.txt") as f:
    requirements = f.read().splitlines()


__version__ = "0.0.0"

REPO_NAME = "document_portal"
AUTHOR_USER_NAME = "avnishs17"
SRC_REPO = "document_portal"
AUTHOR_EMAIL = "avnish1708@gmail.com"


setup(
    name=SRC_REPO,
    version=__version__,
    author=AUTHOR_USER_NAME,
    author_email=AUTHOR_EMAIL,
    description="Document Portal",
    packages=find_packages(),
    install_requires = requirements,
)
```

## Step 5: Install the package in editable mode

```bash
uv pip install -r requirements.txt
```

# Local Development Commands
```bash
# FastAPI development server
uvicorn api.main:app --port 8080 --reload    

# FastAPI production server (local)
uvicorn api.main:app --host 0.0.0.0 --port 8080 --reload
```

---

# Production Deployment Guide (Google Cloud Platform)

## Prerequisites

### 1. GCP Account & Project
- Create a GCP account at https://cloud.google.com/
- Create a new project or use existing one
- Note your PROJECT_ID

### 2. Install Google Cloud CLI

**Windows (PowerShell):**
```powershell
# Visit https://cloud.google.com/sdk/docs/install-sdk#windows and download installer
# Or use chocolatey:
choco install gcloudsdk

# Initialize after installation:
gcloud init
gcloud auth login
```

## Setup Commands

### Step 1: Configure GCP Project
```bash
# Set your project ID (replace with your actual project ID)
$PROJECT_ID="your-actual-project-id"
gcloud config set project $PROJECT_ID
```

### Step 2: Enable Required APIs
```bash
# Enable necessary GCP services
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### Step 3: Create Service Account for GitHub Actions
```bash
# Create service account
gcloud iam service-accounts create github-actions --description="Service account for GitHub Actions" --display-name="GitHub Actions"

# Grant Cloud Run permissions
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/run.admin"

# Grant Artifact Registry permissions
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/artifactregistry.admin"

# Grant Secret Manager permissions
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/secretmanager.admin"

# Grant IAM permissions
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
```

### Step 4: Create Service Account Key
```bash
# Create and download service account key
gcloud iam service-accounts keys create github-actions-key.json --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com
```

### Step 5: Create Secrets in Secret Manager
```bash
# Create secrets for your API keys (replace with your actual values)
echo -n "your-actual-groq-api-key" | gcloud secrets create GROQ_API_KEY --data-file=-
echo -n "your-actual-hf-token" | gcloud secrets create HF_TOKEN --data-file=-
echo -n "your-actual-google-api-key" | gcloud secrets create GOOGLE_API_KEY --data-file=-
echo -n "your-actual-langchain-api-key" | gcloud secrets create LANGCHAIN_API_KEY --data-file=-

# If secrets already exist, update them with new values:
# echo -n "your-actual-groq-api-key" | gcloud secrets versions add GROQ_API_KEY --data-file=-
# echo -n "your-actual-hf-token" | gcloud secrets versions add HF_TOKEN --data-file=-
# echo -n "your-actual-google-api-key" | gcloud secrets versions add GOOGLE_API_KEY --data-file=-
# echo -n "your-actual-langchain-api-key" | gcloud secrets versions add LANGCHAIN_API_KEY --data-file=-
```

### Step 6: Update GitHub Repository

1. **Update workflow file:**
   - Edit `.github/workflows/gcp.yml`
   - Replace `your-gcp-project-id` with your actual PROJECT_ID

2. **Add GitHub Secret:**
   - Go to GitHub repo → Settings → Secrets and variables → Actions
   - Add new repository secret:
     - Name: `GCP_SERVICE_ACCOUNT_KEY`
     - Value: Copy entire content of `github-actions-key.json` file

### Step 7: Local Testing Commands

```bash
# Test Docker build locally
docker build -t document-portal .

# Test Docker run locally
docker run -p 8080:8080 document-portal

# Build for GCP (optional - GitHub Actions will do this automatically)
docker build -t $PROJECT_ID-docker.pkg.dev/$PROJECT_ID/document-portal/document-portal:latest .
```

### Step 8: Manual Deployment (Optional Testing)

```bash
# Build and push manually for testing
gcloud builds submit --tag gcr.io/$PROJECT_ID/document-portal

# Deploy manually to Cloud Run
gcloud run deploy document-portal \
  --image gcr.io/$PROJECT_ID/document-portal \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 8Gi \
  --cpu 4 \
  --set-env-vars="LANGCHAIN_PROJECT=DOCUMENT PORTAL" \
  --set-secrets="GROQ_API_KEY=GROQ_API_KEY:latest,HF_TOKEN=HF_TOKEN:latest,GOOGLE_API_KEY=GOOGLE_API_KEY:latest,LANGCHAIN_API_KEY=LANGCHAIN_API_KEY:latest"

# Get service URL
gcloud run services describe document-portal --region=us-central1 --format='value(status.url)'
```

## What You Need from GCP

### 1. **GCP Project**
   - Create or use existing project
   - Note the PROJECT_ID

### 2. **API Keys/Secrets**
   - GROQ_API_KEY
   - HF_TOKEN (Hugging Face)
   - GOOGLE_API_KEY
   - LANGCHAIN_API_KEY

### 3. **From the Setup Process**
   - Service account key (github-actions-key.json)
   - GitHub secret (GCP_SERVICE_ACCOUNT_KEY)

## Changes Made from AWS to GCP

### Files Removed (No Longer Needed):
1. **`aws.yml`** - AWS ECS deployment workflow → Replaced with `gcp.yml`
2. **`task_definition.json`** - AWS ECS task definition → **NOT NEEDED** for Cloud Run
3. **`template.yml`** - AWS CloudFormation template → **NOT NEEDED** for Cloud Run

### Why No GCP Equivalents Needed:

#### AWS vs GCP Architecture:
- **AWS ECS Fargate**: Requires infrastructure setup (VPC, subnets, security groups, ECS cluster, task definitions)
- **GCP Cloud Run**: Fully serverless - no infrastructure configuration needed

#### Specific File Purposes:
1. **`task_definition.json`** (AWS ECS):
   - Defined container specs, CPU, memory, environment variables
   - **GCP**: All this is handled directly in the `gcloud run deploy` command

2. **`template.yml`** (AWS CloudFormation):
   - Created VPC, subnets, ECS cluster, security groups
   - **GCP**: Cloud Run is serverless - no infrastructure to define

3. **`docker-compose.yml`**:
   - Used for local multi-service development
   - **For this project**: Single service app, not needed
   - **Alternative**: Use `docker run` commands for local testing

### File Changes Required:
1. **`.github/workflows/gcp.yml`** - New workflow file (replaces aws.yml)
2. **Update PROJECT_ID** in workflow file
3. **GitHub Secrets** - Add GCP_SERVICE_ACCOUNT_KEY
4. **Remove AWS files** - No GCP equivalents needed

### Services Mapping:
- **AWS ECR** → **GCP Artifact Registry**
- **AWS ECS Fargate** → **GCP Cloud Run**
- **AWS Secrets Manager** → **GCP Secret Manager**
- **AWS IAM** → **GCP IAM**
- **AWS VPC/Networking** → **NOT NEEDED** (Cloud Run is serverless)

## Monitoring Commands

```bash
# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=document-portal" --limit 50

# Stream logs
gcloud logging tail "resource.type=cloud_run_revision AND resource.labels.service_name=document-portal"

# Get service info
gcloud run services describe document-portal --region=us-central1

# List all services
gcloud run services list

# Update service resources
gcloud run services update document-portal --region=us-central1 --memory=4Gi --cpu=2
```

## Deployment Process

1. **Local Development** → Test locally with uvicorn
2. **Push to Master** → GitHub Actions automatically builds and deploys
3. **Monitor** → Check GitHub Actions and Cloud Run logs
4. **Access** → Service URL provided in deployment logs



Your project default Compute Engine zone has been set to [asia-south1-b].
You can change it by running [gcloud config set compute/zone NAME].

Your project default Compute Engine region has been set to [asia-south1].
You can change it by running [gcloud config set compute/region NAME].

The Google Cloud CLI is configured and ready to use!

* Commands that require authentication will use avnish1708@gmail.com by default
* Commands will reference project `build-test-468516` by default
* Compute Engine commands will use region `asia-south1` by default
* Compute Engine commands will use zone `asia-south1-b` by default

Run `gcloud help config` to learn how to change individual settings

This gcloud configuration is called [personal-account]. You can create additional configurations if you work with multiple accounts and/or projects.
Run `gcloud topic configurations` to learn more.

Some things to try next:

* Run `gcloud --help` to see the Cloud Platform services you can interact with. And run `gcloud help COMMAND` to get help on any gcloud command.
* Run `gcloud topic --help` to learn about advanced features of the CLI like arg files and output formatting
* Run `gcloud cheat-sheet` to see a roster of go-to `gcloud` commands.
PS B:\LLOPS\document_portal> c