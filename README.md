
# Setup Guide for `document_portal`

## 🚀 **Two Deployment Options**

### Option 1: **Serverless Cloud Run** (Simple, but limited performance)
- ✅ Quick setup, fully managed
- ❌ Limited resources (max 8GB RAM, 4 vCPUs)
- ❌ Cold starts, less control

### Option 2: **Full Infrastructure Control with GKE** (AWS ECS equivalent)
- ✅ Full control over compute resources (up to 96 vCPUs, 360GB RAM)
- ✅ Custom VPC, subnets, networking
- ✅ Auto-scaling, load balancing
- ✅ No cold starts, consistent performance
- ✅ Production-grade infrastructure

---

# 🏗️ **RECOMMENDED: Full Infrastructure Control (GKE)**

This setup provides AWS ECS equivalent infrastructure with complete control over networking, compute, and scaling.

## Prerequisites

### 1. Install Required Tools

**Windows (PowerShell):**
```powershell
# Install Google Cloud CLI
choco install gcloudsdk

# Install Terraform
choco install terraform

# Install kubectl (if not installed with gcloud)
gcloud components install kubectl

# Initialize gcloud
gcloud init
gcloud auth login
```

**Linux/Mac:**
```bash
# Install Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install kubectl
gcloud components install kubectl
```

### 2. GCP Project Setup

### 2. GCP Project Setup
```bash
# Set your project ID
$PROJECT_ID="build-test-468516"  # Your actual project ID
gcloud config set project $PROJECT_ID
gcloud config set compute/region asia-south1
gcloud config set compute/zone asia-south1-b
```

## 🚀 **AUTOMATED DEPLOYMENT (GitHub Actions)**

**✅ FULLY AUTOMATED - Just push to GitHub and everything deploys automatically!**

### **One-Time Setup (Only do this once)**

### **Step 1: Quick GCP Setup**
```powershell
# Install Google Cloud CLI (if not installed)
choco install gcloudsdk

# Login and set project
gcloud auth login
$PROJECT_ID="build-test-468516"
gcloud config set project $PROJECT_ID
gcloud config set compute/region asia-south1
gcloud config set compute/zone asia-south1-b
```

### **Step 2: Enable APIs & Create Service Account**
```bash
# Enable all required APIs
gcloud services enable compute.googleapis.com container.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com cloudbuild.googleapis.com servicenetworking.googleapis.com

# Create service account with all permissions
gcloud iam service-accounts create github-actions --description="Service account for GitHub Actions" --display-name="GitHub Actions"

# Grant all necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/container.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/artifactregistry.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/secretmanager.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/compute.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/editor"

# Create service account key
gcloud iam service-accounts keys create github-actions-key.json --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com
```

### **Step 3: Create API Key Secrets**
```bash
# Create secrets with your actual API keys (replace with real values)
echo -n "your-actual-groq-api-key" | gcloud secrets create GROQ_API_KEY --data-file=-
echo -n "your-actual-hf-token" | gcloud secrets create HF_TOKEN --data-file=-
echo -n "your-actual-google-api-key" | gcloud secrets create GOOGLE_API_KEY --data-file=-
echo -n "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" | gcloud secrets create LANGCHAIN_API_KEY --data-file=-
```

### **Step 4: Setup GitHub Secret**
1. Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `GCP_SERVICE_ACCOUNT_KEY`
4. Value: Copy **entire content** of `github-actions-key.json` file
5. Click **Add secret**

## 🎯 **DEPLOY EVERYTHING (Just Push to GitHub!)**

### **That's it! Now just push to master branch:**
```bash
git add .
git commit -m "Deploy to GKE with full infrastructure"
git push origin master
```

**GitHub Actions will automatically:**
1. ✅ **Plan Infrastructure** - Review Terraform changes
2. ✅ **Deploy Infrastructure** - Create VPC, GKE cluster, service accounts
3. ✅ **Build Docker Image** - Build and push to Artifact Registry  
4. ✅ **Deploy to GKE** - Create Kubernetes secrets and deploy application
5. ✅ **Get External IP** - Show you the URL to access your app

### **Check Deployment Status:**
- Go to GitHub repo → **Actions** tab
- Watch the deployment progress in real-time
- Get your application URL from the final step logs

### **Access Your Application:**
After deployment completes, check the Actions logs for:
```
Application deployed successfully!
External IP: 34.XXX.XXX.XXX
Access your application at: http://34.XXX.XXX.XXX
```

---

# 🛠️ **MANUAL DEPLOYMENT (If you prefer step-by-step control)**

<details>
<summary>Click to expand manual deployment commands (not recommended - use GitHub Actions instead)</summary>

### **Manual Setup Prerequisites**
```powershell
# Install Terraform if needed (GitHub Actions already has this)
choco install terraform

# Set up authentication for Terraform
gcloud auth application-default login
```

### **Manual Terraform Commands**
```bash
# Navigate to terraform directory  
cd terraform

# Initialize Terraform
terraform init

# Plan deployment (review what will be created)
terraform plan

# Apply infrastructure (create everything)
terraform apply
```

### **Manual Application Deployment**
```bash
# Get cluster credentials
gcloud container clusters get-credentials document-portal-cluster --zone=asia-south1-b

# Create Kubernetes secrets from GCP Secret Manager
$GROQ_API_KEY = gcloud secrets versions access latest --secret="GROQ_API_KEY"
$HF_TOKEN = gcloud secrets versions access latest --secret="HF_TOKEN" 
$GOOGLE_API_KEY = gcloud secrets versions access latest --secret="GOOGLE_API_KEY"
$LANGCHAIN_API_KEY = gcloud secrets versions access latest --secret="LANGCHAIN_API_KEY"

kubectl create secret generic groq-api-key --from-literal=api-key="$GROQ_API_KEY"
kubectl create secret generic hf-token --from-literal=token="$HF_TOKEN"
kubectl create secret generic google-api-key --from-literal=api-key="$GOOGLE_API_KEY"
kubectl create secret generic langchain-api-key --from-literal=api-key="$LANGCHAIN_API_KEY"

# Build and push Docker image
$IMAGE_URI = "asia-south1-docker.pkg.dev/$PROJECT_ID/document-portal/document-portal:latest"
gcloud auth configure-docker asia-south1-docker.pkg.dev
docker build -t $IMAGE_URI .
docker push $IMAGE_URI

# Update deployment YAML and deploy
(Get-Content "k8s\deployment.yaml") -replace 'image: .*', "image: $IMAGE_URI" | Set-Content "k8s\deployment.yaml"
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/document-portal --timeout=600s
```

</details>

---

## 📊 **Infrastructure Comparison**
```

# 🛠️ **MANUAL DEPLOYMENT (If you prefer step-by-step control)**

<details>
<summary>Click to expand manual deployment steps</summary>

## Manual Setup Commands

### **Step 1: Install Prerequisites**
```powershell
# Install required tools (Windows)
choco install gcloudsdk terraform

# Or download manually:
# Terraform: https://www.terraform.io/downloads.html
# Google Cloud CLI: https://cloud.google.com/sdk/docs/install-sdk#windows

# Initialize gcloud
gcloud init
gcloud auth login
```

### **Step 2: Configure GCP Project**
```bash
# Set your project
$PROJECT_ID="build-test-468516"
gcloud config set project $PROJECT_ID
gcloud config set compute/region asia-south1
gcloud config set compute/zone asia-south1-b
```

---

## 📊 **Infrastructure Comparison**

| Feature | Cloud Run | GKE (This Setup) |
|---------|-----------|------------------|
| **CPU** | Max 4 vCPUs | Up to 96 vCPUs per node |
| **Memory** | Max 8GB | Up to 360GB per node |
| **Cold Starts** | Yes (0-5 seconds) | No |
| **Auto Scaling** | Basic | Advanced (HPA, VPA, Cluster Autoscaler) |
| **Networking** | Managed | Full VPC control |
| **Load Balancing** | Basic | Advanced (Global Load Balancer) |
| **Cost** | Pay per request | Pay for provisioned resources |
| **Control** | Limited | Full infrastructure control |

## 🎯 **Performance Benefits**

### **Machine Types Available:**
- **e2-standard-4**: 4 vCPUs, 16GB RAM (default)
- **e2-standard-8**: 8 vCPUs, 32GB RAM
- **e2-highmem-16**: 16 vCPUs, 128GB RAM
- **c2-standard-16**: 16 vCPUs, 64GB RAM (compute optimized)

### **Auto-scaling Configuration:**
- **Min nodes**: 1 (cost optimization)
- **Max nodes**: 5 (can handle traffic spikes)
- **Pod autoscaling**: Based on CPU/memory usage
- **Cluster autoscaling**: Adds/removes nodes automatically

## 📋 **Monitoring and Management**

### **Check Deployment Status:**
```bash
# Get cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide

# Check pods
kubectl get pods -o wide

# Check services and ingress
kubectl get services
kubectl get ingress

# Get application logs
kubectl logs -f deployment/document-portal

# Check resource usage
kubectl top nodes
kubectl top pods
```

### **Scaling Commands:**
```bash
# Manual scaling
kubectl scale deployment document-portal --replicas=5

# Update node pool size
gcloud container clusters resize document-portal-cluster --num-nodes=3 --zone=asia-south1-b

# Update machine type (requires recreating node pool)
gcloud container node-pools create high-performance-pool \
  --cluster=document-portal-cluster \
  --zone=asia-south1-b \
  --machine-type=e2-standard-8 \
  --num-nodes=2
```

---

# 📦 **Alternative: Simple Cloud Run Setup**

If you prefer the simple serverless approach (limited performance):

## Local Development Commands
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

# IMPORTANT: Grant Secret Manager Secret Accessor role to Compute Engine service account
# This allows Cloud Run to access the secrets (replace PROJECT_NUMBER with your actual project number)
$PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
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
echo -n "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" | gcloud secrets create LANGCHAIN_API_KEY --data-file=-



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

---

# 🗑️ Cleanup Commands (Delete Everything)

**⚠️ WARNING: These commands will permanently delete all GCP resources and cannot be undone!**

# �️ **Cleanup Commands (Delete Everything)**

**⚠️ WARNING: These commands will permanently delete all GCP resources!**

## **Complete GKE Infrastructure Cleanup**

### **Step 1: Delete Kubernetes Resources**
```bash
# Delete the application deployment
kubectl delete -f k8s/deployment.yaml

# Delete Kubernetes secrets
kubectl delete secret groq-api-key hf-token google-api-key langchain-api-key
```

### **Step 2: Destroy Infrastructure with Terraform**
```bash
# Navigate to terraform directory
cd terraform

# Destroy all infrastructure
terraform destroy

# Clean up Terraform files
Remove-Item -Path ".terraform*" -Recurse -Force
Remove-Item -Path "terraform.tfstate*" -Force
```

### **Step 3: Delete Docker Images**
```bash
# Delete all Docker images in the repository
gcloud artifacts docker images list asia-south1-docker.pkg.dev/build-test-468516/document-portal --format="value(IMAGE_URI)" | ForEach-Object { gcloud artifacts docker images delete $_ --quiet }

# Delete the entire Artifact Registry repository
gcloud artifacts repositories delete document-portal --location=asia-south1 --quiet
```

### **Step 4: Delete GCP Secrets**
```bash
# Delete all secrets
gcloud secrets delete GROQ_API_KEY --quiet
gcloud secrets delete HF_TOKEN --quiet  
gcloud secrets delete GOOGLE_API_KEY --quiet
gcloud secrets delete LANGCHAIN_API_KEY --quiet
```

### **Step 5: Remove Service Account and Permissions**
```bash
# Remove IAM policy bindings
$PROJECT_ID = "build-test-468516"

gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/container.admin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/artifactregistry.admin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/secretmanager.admin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/compute.admin" --quiet

# Delete service account keys
gcloud iam service-accounts keys list --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com --format="value(name)" | ForEach-Object { gcloud iam service-accounts keys delete $_ --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com --quiet }

# Delete service account
gcloud iam service-accounts delete github-actions@$PROJECT_ID.iam.gserviceaccount.com --quiet
```

### **Step 6: Delete Local Files**
```bash
# Delete local service account key file
Remove-Item -Path "github-actions-key.json" -Force -ErrorAction SilentlyContinue
```

### **Step 7: Verification Commands**
```bash
# Verify everything is deleted
gcloud container clusters list --filter="name:document-portal*"
gcloud compute networks list --filter="name:document-portal*"
gcloud artifacts repositories list --location=asia-south1
gcloud secrets list
gcloud iam service-accounts list --filter="email:github-actions@*"
```

### **Step 8: GitHub Cleanup (Manual)**
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Delete secret: `GCP_SERVICE_ACCOUNT_KEY`

## **Quick One-Line Cleanup (Nuclear Option)**
```bash
# ⚠️ DANGER: This will delete EVERYTHING at once
$PROJECT_ID="build-test-468516"; kubectl delete -f k8s/deployment.yaml; kubectl delete secret groq-api-key hf-token google-api-key langchain-api-key; cd terraform; terraform destroy -auto-approve; cd ..; gcloud artifacts repositories delete document-portal --location=asia-south1 --quiet; gcloud secrets delete GROQ_API_KEY HF_TOKEN GOOGLE_API_KEY LANGCHAIN_API_KEY --quiet; gcloud iam service-accounts delete github-actions@$PROJECT_ID.iam.gserviceaccount.com --quiet; Remove-Item -Path "github-actions-key.json", "terraform\.terraform*", "terraform\terraform.tfstate*" -Recurse -Force -ErrorAction SilentlyContinue
```

## ☁️ **Cloud Run Cleanup (Simple Setup)**

Use this if you're using the simple Cloud Run setup:

## Complete Cleanup Script

```bash
# Set your project ID
$PROJECT_ID="build-test-468516"  # Replace with your actual project ID
gcloud config set project $PROJECT_ID

# 1. Delete Cloud Run Service
echo "Deleting Cloud Run service..."
gcloud run services delete document-portal --region=asia-south1 --quiet

# 2. Delete Docker Images from Artifact Registry
echo "Deleting Docker images..."
gcloud artifacts docker images delete asia-south1-docker.pkg.dev/$PROJECT_ID/document-portal/document-portal --delete-tags --quiet

# 3. Delete Artifact Registry Repository
echo "Deleting Artifact Registry repository..."
gcloud artifacts repositories delete document-portal --location=asia-south1 --quiet

# 4. Delete All Secrets
echo "Deleting secrets..."
gcloud secrets delete GROQ_API_KEY --quiet
gcloud secrets delete HF_TOKEN --quiet
gcloud secrets delete GOOGLE_API_KEY --quiet
gcloud secrets delete LANGCHAIN_API_KEY --quiet

# 5. Delete Service Account Keys
echo "Deleting service account keys..."
# List and delete all keys for the service account
gcloud iam service-accounts keys list --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com --format="value(name)" | ForEach-Object {
    gcloud iam service-accounts keys delete $_ --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com --quiet
}

# 6. Remove IAM Policy Bindings
echo "Removing IAM policy bindings..."
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/run.admin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/artifactregistry.admin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/secretmanager.admin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser" --quiet

# Remove Secret Manager Secret Accessor role from Compute Engine service account
$PROJECT_NUMBER = (gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor" --quiet

# 7. Delete Service Account
echo "Deleting service account..."
gcloud iam service-accounts delete github-actions@$PROJECT_ID.iam.gserviceaccount.com --quiet

# 8. Delete Local Files
echo "Deleting local files..."
Remove-Item -Path "github-actions-key.json" -Force -ErrorAction SilentlyContinue

# 9. Optional: Disable APIs (if not used by other services)
echo "Disabling APIs (optional)..."
# gcloud services disable run.googleapis.com --force --quiet
# gcloud services disable artifactregistry.googleapis.com --force --quiet
# gcloud services disable secretmanager.googleapis.com --force --quiet
# gcloud services disable cloudbuild.googleapis.com --force --quiet

echo "✅ Cleanup completed successfully!"
echo "📝 Remember to also delete GitHub repository secrets:"
echo "   - Go to GitHub repo → Settings → Secrets and variables → Actions"
echo "   - Delete: GCP_SERVICE_ACCOUNT_KEY"
```

## Individual Cleanup Commands

If you prefer to delete resources one by one:

### 1. Delete Cloud Run Service
```bash
gcloud run services delete document-portal --region=asia-south1
```

### 2. Delete Docker Images
```bash
# List images first
gcloud artifacts docker images list asia-south1-docker.pkg.dev/$PROJECT_ID/document-portal

# Delete specific image
gcloud artifacts docker images delete asia-south1-docker.pkg.dev/$PROJECT_ID/document-portal/document-portal:TAG_NAME

# Delete all images in repository
gcloud artifacts docker images delete asia-south1-docker.pkg.dev/$PROJECT_ID/document-portal/document-portal --delete-tags
```

### 3. Delete Artifact Registry Repository
```bash
gcloud artifacts repositories delete document-portal --location=asia-south1
```

### 4. Delete Secrets
```bash
gcloud secrets delete GROQ_API_KEY
gcloud secrets delete HF_TOKEN
gcloud secrets delete GOOGLE_API_KEY
gcloud secrets delete LANGCHAIN_API_KEY
```

### 5. Delete Service Account Keys and Account
```bash
# List service account keys
gcloud iam service-accounts keys list --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com

# Delete specific key (replace KEY_ID)
gcloud iam service-accounts keys delete KEY_ID --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com

# Delete service account
gcloud iam service-accounts delete github-actions@$PROJECT_ID.iam.gserviceaccount.com
```

### 6. Remove IAM Policy Bindings
```bash
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/run.admin"
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/artifactregistry.admin"
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/secretmanager.admin"
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"

# Remove Secret Manager Secret Accessor role from Compute Engine service account
$PROJECT_NUMBER = (gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
```

### 7. Delete Local Files
```bash
# Windows PowerShell
Remove-Item -Path "github-actions-key.json" -Force

# Or manually delete the github-actions-key.json file
```

### 8. GitHub Repository Cleanup
**Manual steps required:**
1. Go to your GitHub repository
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Delete the secret: `GCP_SERVICE_ACCOUNT_KEY`

## Verification Commands

After cleanup, verify everything is deleted:

```bash
# Check Cloud Run services
gcloud run services list --region=asia-south1

# Check Artifact Registry repositories
gcloud artifacts repositories list --location=asia-south1

# Check secrets
gcloud secrets list

# Check service accounts
gcloud iam service-accounts list --filter="email:github-actions@*"

# Check for any remaining IAM bindings
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:github-actions@*"
```

## 🚨 Final Warning

**These cleanup commands will:**
- ❌ Delete your deployed application completely
- ❌ Remove all Docker images and container registry
- ❌ Delete all API keys and secrets (cannot be recovered)
- ❌ Remove service accounts and access permissions
- ❌ Delete local service account key files

**Make sure you:**
- ✅ Have backups of any important data
- ✅ Have noted down your API keys if you plan to use them elsewhere
- ✅ Are certain you want to completely remove the project

**Cost Impact:** After cleanup, you will stop incurring charges for these GCP resources.



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