# 🚀 Document Portal - Full Infrastructure Control (GKE)

## 📋 **Project Information**

**Document Portal** is a FastAPI-based application that provides document analysis and chat capabilities using Large Language Models (LLMs). The application includes:

- **Multi-document chat** - Chat with multiple documents simultaneously
- **Single document analysis** - Deep analysis of individual documents  
- **Document comparison** - Compare and analyze differences between documents
- **AI-powered insights** - Powered by GROQ, Google AI, and LangChain
- **Streamlit UI** - User-friendly web interface for document interaction

### **🔧 Tech Stack:**
- **Backend**: FastAPI (Python)
- **Frontend**: Streamlit
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

# Optional: Database and other configs
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

### **Option 2: Streamlit UI**
```bash
# Run Streamlit frontend
streamlit run streamlit_ui.py --server.port 8501

# Access at: http://localhost:8501
```

### **Option 3: Both Services (Development)**
```bash
# Terminal 1: Run FastAPI backend
uvicorn api.main:app --port 8080 --reload

# Terminal 2: Run Streamlit frontend  
streamlit run streamlit_ui.py --server.port 8501
```

## **🧪 Testing Locally**
```bash
# Test FastAPI health endpoint
curl http://localhost:8080/health

# Test with sample document
# Upload a PDF file through the Streamlit UI at http://localhost:8501
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
2. **Add to GCP Secret Manager** (for production deployment):
   ```bash
   # Create the secret in GCP
   echo "your-langsmith-api-key" | gcloud secrets create LANGCHAIN_API_KEY --data-file=-
   ```
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
   
   # Run both services
   uvicorn api.main:app --port 8080 --reload  # Terminal 1
   streamlit run streamlit_ui.py --server.port 8501  # Terminal 2
   ```
3. **Test changes**: Use http://localhost:8501 to test your application
4. **Deploy**: Push to GitHub → Automatic deployment to GKE

---

# 🏗️ **Production Deployment (GKE)**

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
- **Detects existing resources** - VPC, service accounts, IP addresses
- **Imports automatically** - No conflicts from previous deployments
- **Handles partial deployments** - Gracefully continues from any point
- **No manual cleanup needed** - Smart enough to work with existing infrastructure

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
$PROJECT_ID="build-test-468516"  # Your actual project ID
gcloud config set project $PROJECT_ID
gcloud config set compute/region asia-south1
gcloud config set compute/zone asia-south1-b
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

### **Step 2: Create API Key Secrets**
```bash
# Create secrets with your actual API keys (replace with real values)
echo -n "your-actual-groq-api-key" | gcloud secrets create GROQ_API_KEY --data-file=-
echo -n "your-actual-google-api-key" | gcloud secrets create GOOGLE_API_KEY --data-file=-
```

### **Step 3: Setup GitHub Secret**
1. Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `GCP_SERVICE_ACCOUNT_KEY`
4. Value: Copy **entire content** of `github-actions-key.json` file
5. Click **Add secret**

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
4. ✅ **Build Docker Image** - Builds and pushes to Artifact Registry  
5. ✅ **Deploy to GKE** - Creates Kubernetes secrets and deploys application
6. ✅ **Get External IP** - Shows you the URL to access your app

## **Check Deployment Status:**
- Go to GitHub repo → **Actions** tab
- Watch the deployment progress in real-time
- Get your application URL from the final step logs

## **Access Your Application:**
After deployment completes, check the Actions logs for:
```
Application deployed successfully!
External IP: 34.XXX.XXX.XXX
Access your application at: http://34.XXX.XXX.XXX
```

---

# 📊 **Infrastructure Comparison**

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

---

# 📋 **Monitoring and Management**

## **Check Deployment Status:**
```bash
# Install kubectl to manage cluster
gcloud components install kubectl

# Get cluster credentials
gcloud container clusters get-credentials document-portal-cluster --zone=asia-south1-b

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
gcloud container clusters resize document-portal-cluster --num-nodes=3 --zone=asia-south1-b
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
kubectl delete secret groq-api-key google-api-key
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
gcloud secrets delete GOOGLE_API_KEY --quiet
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
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/iam.serviceAccountAdmin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/resourcemanager.projectIamAdmin" --quiet
gcloud projects remove-iam-policy-binding $PROJECT_ID --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/editor" --quiet

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
$PROJECT_ID="build-test-468516"; kubectl delete -f k8s/deployment.yaml; kubectl delete secret groq-api-key google-api-key; cd terraform; terraform destroy -auto-approve; cd ..; gcloud artifacts repositories delete document-portal --location=asia-south1 --quiet; gcloud secrets delete GROQ_API_KEY GOOGLE_API_KEY --quiet; gcloud iam service-accounts delete github-actions@$PROJECT_ID.iam.gserviceaccount.com --quiet; Remove-Item -Path "github-actions-key.json", "terraform\.terraform*", "terraform\terraform.tfstate*" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 🚨 **Final Warning**

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
