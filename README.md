# 🚀 Document Portal - Full Infrastructure Control (GKE)

## 📋 **Project Information**

**Document Portal** is a FastAPI-based application that provides document analysis and chat capabilities using Large Language Models (LLMs). The application includes:

- **Multi-document chat** - Chat with multiple documents simultaneously
- **Single document analysis** - Deep analysis of individual documents  
- **Document comparison** - Compare and analyze differences between documents
- **AI-powered insights** - Powered by GROQ, Google AI, and LangChain
- **Built-in HTML UI** - User-friendly web interface for document interaction

### **🔧 Tech Stack:**
- **Backend**: FastAPI (Python)
- **Frontend**: HTML (built into FastAPI)
- **AI/ML**: GROQ, Google AI, HuggingFace, LangChain
- **Infrastructure**: Google Kubernetes Engine (GKE)
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **IaC**: Terraform

---

# 💻 **Local Development Setup**

## **Prerequisites**

### **1. Install Python Environment Manager**

**Install `uv` (Recommended - Fast Python package manager):**

**Windows (PowerShell):**
```powershell
# Install uv
irm https://astral.sh/uv/install.ps1 | iex

# Or using pip
pip install uv
```

**Linux/Mac:**
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or using pip
pip install uv
```

### **2. Setup Python Environment**
```bash
# Create virtual environment with Python 3.11
uv venv --python 3.11 .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Install dependencies
uv pip install -r requirements.txt
```

### **3. Environment Variables**
Create a `.env` file in the root directory:
```bash
# API Keys (replace with your actual values)
GROQ_API_KEY=your-groq-api-key
GOOGLE_API_KEY=your-google-ai-api-key

# Add other environment variables as needed
```

## **🚀 Run Locally**

### **Option 1: FastAPI Backend Only**
```bash
# Development server with auto-reload
uvicorn api.main:app --port 8080 --reload

# Access at: http://localhost:8080
# API docs at: http://localhost:8080/docs
```

### **Option 2: FastAPI with Built-in UI**
```bash
# Run FastAPI with built-in HTML interface
uvicorn api.main:app --port 8080 --reload

# Access at: http://localhost:8080
# The application includes a built-in HTML interface for document interaction
```

### **Option 3: Production Mode**
```bash
# Run FastAPI in production mode
uvicorn api.main:app --port 8080 --workers 2

# Access at: http://localhost:8080
```

## **🧪 Testing Locally**
```bash
# Test FastAPI health endpoint
curl http://localhost:8080/health

# Test with sample document
# Upload a PDF file through the built-in HTML interface at http://localhost:8080
```

## **📊 LangSmith Tracking (Optional)**

The application supports optional LangSmith tracking for monitoring AI model interactions in production.

### **Configuration**
LangSmith tracking is controlled via `config/config.yaml`:

```yaml
langsmith:
  enabled: true  # Set to false to disable tracking
  project_name: "DOCUMENT_PORTAL"
  environment: "production"
```

### **Setup for Production**
1. **Get LangSmith API Key** from [LangSmith Console](https://smith.langchain.com/)
2. **Add to GitHub Secrets** (for production deployment):
   - Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
   - Create secret: `LANGCHAIN_API_KEY` with your LangSmith API key
3. **Add to local environment** (for development):
   ```bash
   # Windows PowerShell
   $env:LANGCHAIN_API_KEY="your-langsmith-api-key"
   
   # Linux/Mac
   export LANGCHAIN_API_KEY="your-langsmith-api-key"
   ```

### **Behavior**
- ✅ **Both config enabled AND API key provided**: LangSmith tracking active
- ⚠️ **Config enabled BUT no API key**: Tracking disabled, app continues normally  
- ⚠️ **Config disabled**: Tracking disabled regardless of API key
- 📝 **Logs all decisions** for troubleshooting

**Note**: The application works perfectly without LangSmith - it's purely optional for monitoring.

## **🔄 Development Workflow**
1. **Setup once**: Install `uv`, create environment, install dependencies
2. **Daily development**: 
   ```bash
   # Activate environment
   .venv\Scripts\activate  # Windows
   source .venv/bin/activate  # Linux/Mac
   
   # Run FastAPI application
   uvicorn api.main:app --port 8080 --reload
   ```
3. **Test changes**: Use http://localhost:8080 to test your application
4. **Deploy**: Push to GitHub → Automatic deployment to GKE

---

# 🏗️ **Production Deployment (GKE)**

## ⚠️ **IMPORTANT: Configuration Required Before Deployment**

**Before you can deploy this application, you MUST update the following files with your actual GCP project details:**

### **Files to Update:**

1. **`.github/workflows/gke-deploy.yml`** (Line 8):
   ```yaml
   env:
     # ⚠️ IMPORTANT: Replace these dummy values with your actual GCP project details
     # These are placeholder values - you MUST update them before deployment
     GCP_PROJECT_ID: your-gcp-project-id-here  # ← Replace with your actual project ID
     GCP_REGION: us-central1
     GCP_ZONE: us-central1-b
   ```

2. **`terraform/main.tf`** (Line 25):
   ```hcl
   variable "project_id" {
     description = "The GCP project ID"
     type        = string
     # ⚠️ IMPORTANT: Replace this dummy value with your actual GCP project ID
     # This is a placeholder value - you MUST update it before deployment
     default     = "your-gcp-project-id-here"  # ← Replace with your actual project ID
   }
   ```

3. **`k8s/deployment.yaml`** (Lines 23 & 188):
   ```yaml
   # Line 23: Docker image reference
   image: us-central1-docker.pkg.dev/your-gcp-project-id-here/document-portal/document-portal:latest
   
   # Line 188: Service account annotation
   iam.gke.io/gcp-service-account: document-portal-gke-sa@your-gcp-project-id-here.iam.gserviceaccount.com
   ```

### **What You Need:**
- **GCP Project ID**: Your Google Cloud Platform project ID (e.g., `my-awesome-project-123`)
- **GCP Region**: The region where you want to deploy (default: `us-central1`)
- **GCP Zone**: The zone within the region (default: `us-central1-b`)

### **How to Find Your GCP Project ID:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Look at the project selector at the top of the page
3. Your project ID is displayed there (e.g., `my-awesome-project-123`)

---

## 🏗️ **Production-Grade Infrastructure**

This setup provides **AWS ECS equivalent infrastructure** with complete control over networking, compute, and scaling on Google Cloud Platform.

### **✅ What You Get:**
- **Full control** over compute resources (up to 96 vCPUs, 360GB RAM per node)
- **Custom VPC** with subnets and networking control
- **Auto-scaling** Kubernetes cluster with load balancing
- **No cold starts** - consistent performance
- **Production-grade** infrastructure with monitoring

### **🤖 Fully Automated Deployment:**
- Just push to GitHub → Everything deploys automatically
- No manual commands needed after initial setup
- Complete infrastructure created with Terraform
- Application deployed to GKE cluster
- **Smart resource handling** - Automatically imports existing resources to avoid conflicts

### **🔧 Intelligent Resource Management:**
- **Detects existing resources** - VPC, service accounts, IP addresses, GKE clusters
- **Imports automatically** - No conflicts from previous deployments
- **Handles partial deployments** - Gracefully continues from any point
- **No manual cleanup needed** - Smart enough to work with existing infrastructure
- **Updates existing clusters** - Deploys new workloads to existing GKE clusters without recreating them

---

# 🛠️ **Production Setup (One-Time)**

## **Prerequisites for GCP Deployment**

### **1. Install Google Cloud CLI**

**Windows (PowerShell):**
```powershell
# Install Google Cloud CLI
choco install gcloudsdk

# Initialize gcloud
gcloud init
gcloud auth login
```

**Linux/Mac:**
```bash
# Install Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
gcloud auth login
```

### **2. Configure GCP Project**
```bash
# Set your project ID
$PROJECT_ID="your-gcp-project-id"  # Replace with your actual project ID
gcloud config set project $PROJECT_ID
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-b
```

## **Setup Steps**

### **Step 1: Enable APIs & Create Service Account**
```bash
# Enable all required APIs
gcloud services enable compute.googleapis.com container.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com cloudbuild.googleapis.com servicenetworking.googleapis.com cloudresourcemanager.googleapis.com

# Create service account with all permissions
gcloud iam service-accounts create github-actions --description="Service account for GitHub Actions" --display-name="GitHub Actions"

# Grant all necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/container.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/artifactregistry.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/secretmanager.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/compute.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/editor"

# Create service account key
gcloud iam service-accounts keys create github-actions-key.json --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com
```

### **Step 2: Setup GitHub Secrets**
1. Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** for each of the following:

#### **Required Secrets:**
- **Name**: `GCP_SERVICE_ACCOUNT_KEY`
  - **Value**: Copy **entire content** of `github-actions-key.json` file

- **Name**: `GROQ_API_KEY`
  - **Value**: Your actual GROQ API key

- **Name**: `GOOGLE_API_KEY`
  - **Value**: Your actual Google AI API key

#### **Optional Secret (for LangSmith tracking):**
- **Name**: `LANGCHAIN_API_KEY`
  - **Value**: Your actual LangSmith API key (optional)

3. Click **Add secret** for each one

---

# 🚀 **Deploy Everything (Automated)**

## **Just Push to GitHub:**
```bash
git add .
git commit -m "Deploy to GKE with full infrastructure"
git push origin master
```

## **🤖 What Happens Automatically:**
1. ✅ **Plan Infrastructure** - Reviews Terraform changes
2. ✅ **Import Existing Resources** - Automatically imports any existing resources to avoid conflicts
3. ✅ **Deploy Infrastructure** - Creates VPC, GKE cluster, service accounts (or uses existing ones)
4. ✅ **Update Existing Clusters** - Deploys workloads to existing clusters without recreation
5. ✅ **Build Docker Image** - Builds and pushes to Artifact Registry  
6. ✅ **Deploy to GKE** - Creates Kubernetes secrets and deploys application
7. ✅ **Get External IP** - Shows you the URL to access your app

## **Check Deployment Status:**
- Go to GitHub repo → **Actions** tab
- Watch the deployment progress in real-time
- Get your application URL from the final step logs

## **Access Your Application:**
After deployment completes, check the Actions logs for:
```
Application deployed successfully!
External IP: XXX.XXX.XXX.XXX
Access your application at: http://XXX.XXX.XXX.XXX
```

---

# 📋 **Monitoring and Management**

## **Check Deployment Status:**
```bash
# Install kubectl to manage cluster
gcloud components install kubectl

# Get cluster credentials
gcloud container clusters get-credentials document-portal-cluster --zone=us-central1-b

# Check cluster info
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

## **Scaling Commands:**
```bash
# Manual scaling
kubectl scale deployment document-portal --replicas=5

# Update node pool size
gcloud container clusters resize document-portal-cluster --num-nodes=3 --zone=us-central1-b
```

---

# 🗑️ **Cleanup Commands (Delete Everything)**

**⚠️ WARNING: These commands will permanently delete all GCP resources!**

## **Complete GKE Infrastructure Cleanup**

### **Step 1: Delete Kubernetes Resources**
```bash
# Delete the application deployment
kubectl delete -f k8s/deployment.yaml

# Delete Kubernetes secrets
kubectl delete secret groq-api-key google-api-key langchain-api-key
```

### **Step 2: Delete GKE Cluster**
```bash
# Delete the GKE cluster
gcloud container clusters delete document-portal-cluster --zone=us-central1-b --quiet
```

### **Step 3: Delete Artifact Registry**
```bash
# Delete the entire Artifact Registry repository
gcloud artifacts repositories delete document-portal --location=us-central1 --quiet
```

### **Step 4: Delete VPC and Networking Resources**
```bash
# Delete firewall rules
gcloud compute firewall-rules delete document-portal-allow-internal --quiet
gcloud compute firewall-rules delete document-portal-allow-http-https --quiet

# Delete global IP address
gcloud compute addresses delete document-portal-ip --global --quiet

# Delete subnet
gcloud compute networks subnets delete document-portal-subnet --region=us-central1 --quiet

# Delete VPC network (must be last after all dependent resources)
gcloud compute networks delete document-portal-vpc --quiet
```

### **Step 5: Delete GCP Secrets**
```bash
# Delete all secrets
gcloud secrets delete GROQ_API_KEY --quiet
gcloud secrets delete GOOGLE_API_KEY --quiet
gcloud secrets delete LANGCHAIN_API_KEY --quiet
```

### **Step 6: Delete Service Accounts**
```bash
# Delete service accounts
gcloud iam service-accounts delete document-portal-gke-sa@your-gcp-project-id-here.iam.gserviceaccount.com --quiet
gcloud iam service-accounts delete github-actions@your-gcp-project-id-here.iam.gserviceaccount.com --quiet
```

### **Step 7: Verification Commands**
```bash
# Verify everything is deleted
gcloud container clusters list --filter="name:document-portal*"
gcloud compute networks list --filter="name:document-portal*"
gcloud artifacts repositories list --location=us-central1
gcloud secrets list
gcloud iam service-accounts list --filter="email:document-portal*"
```

### **Step 8: GitHub Cleanup (Manual)**
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Delete secrets: `GCP_SERVICE_ACCOUNT_KEY`, `GROQ_API_KEY`, `GOOGLE_API_KEY`, `LANGCHAIN_API_KEY`

## **Quick One-Line Cleanup (Nuclear Option)**
```bash
# ⚠️ DANGER: This will delete EVERYTHING at once
# ⚠️ IMPORTANT: Replace 'your-gcp-project-id-here' with your actual project ID before running
kubectl delete -f k8s/deployment.yaml; kubectl delete secret groq-api-key google-api-key langchain-api-key; gcloud container clusters delete document-portal-cluster --zone=us-central1-b --quiet; gcloud artifacts repositories delete document-portal --location=us-central1 --quiet; gcloud compute firewall-rules delete document-portal-allow-internal document-portal-allow-http-https --quiet; gcloud compute addresses delete document-portal-ip --global --quiet; gcloud compute networks subnets delete document-portal-subnet --region=us-central1 --quiet; gcloud compute networks delete document-portal-vpc --quiet; gcloud secrets delete GROQ_API_KEY GOOGLE_API_KEY LANGCHAIN_API_KEY --quiet; gcloud iam service-accounts delete document-portal-gke-sa@your-gcp-project-id-here.iam.gserviceaccount.com github-actions@your-gcp-project-id-here.iam.gserviceaccount.com --quiet
```

---

## 🚨 **Final Warning**

**These cleanup commands will:**
- ❌ Delete your deployed application completely
- ❌ Remove all Docker images and container registry
- ❌ Delete all API keys and secrets (cannot be recovered)
- ❌ Remove service accounts and access permissions

**Make sure you:**
- ✅ Have backups of any important data
- ✅ Have noted down your API keys if you plan to use them elsewhere
- ✅ Are certain you want to completely remove the project

**Cost Impact:** After cleanup, you will stop incurring charges for these GCP resources.
