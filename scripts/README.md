# 🛠️ GCP Management Scripts

This directory contains automated scripts to setup and cleanup the complete GCP infrastructure for the Document Portal project.

## 📋 **Available Scripts**

### 🚀 **Setup Script - `setup-gcp.ps1`**
Automatically sets up the complete GCP infrastructure including:
- Project configuration
- API enablement (Compute, Container, Artifact Registry, etc.)
- Service account creation with all required permissions
- Secret creation for API keys
- Service account key generation

### 🗑️ **Cleanup Script - `cleanup-gcp.ps1`**
Completely removes all GCP infrastructure including:
- Kubernetes deployments and secrets
- Terraform-managed infrastructure (VPC, GKE cluster, etc.)
- Docker images and Artifact Registry
- GCP secrets and service accounts
- Local key files

### 🎛️ **Management Script - `manage-gcp.bat`**
Interactive menu-driven script for easy access to setup and cleanup operations.

---

## 🚀 **Quick Start**

### **Option 1: Interactive Menu (Recommended)**
```cmd
# Run the interactive management script
scripts\manage-gcp.bat
```

### **Option 2: Direct PowerShell Execution**

**Setup:**
```powershell
.\scripts\setup-gcp.ps1 -GroqApiKey "your-groq-key" -GoogleApiKey "your-google-key" -LangchainApiKey "your-langchain-key"
```

**Cleanup:**
```powershell
.\scripts\cleanup-gcp.ps1
```

**Force cleanup (skip confirmations):**
```powershell
.\scripts\cleanup-gcp.ps1 -Force
```

---

## 📖 **Detailed Usage**

### **Setup Script Parameters**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `ProjectId` | No | `build-test-468516` | GCP Project ID |
| `Region` | No | `asia-south1` | GCP Region |
| `Zone` | No | `asia-south1-b` | GCP Zone |
| `GroqApiKey` | **Yes** | - | Your GROQ API key |
| `GoogleApiKey` | **Yes** | - | Your Google AI API key |
| `LangchainApiKey` | No | - | Your LangChain API key (optional) |

### **Cleanup Script Parameters**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `ProjectId` | No | `build-test-468516` | GCP Project ID |
| `Region` | No | `asia-south1` | GCP Region |
| `Zone` | No | `asia-south1-b` | GCP Zone |
| `Force` | No | `false` | Skip confirmation prompts |

---

## 📋 **Prerequisites**

### **Required Software:**
1. **Google Cloud CLI** installed and authenticated
   ```powershell
   # Check installation
   gcloud version
   
   # Authenticate if needed
   gcloud auth login
   ```

2. **PowerShell 5.1+** (Windows) or **PowerShell Core 6+** (Cross-platform)

3. **kubectl** (for cleanup operations)
   ```powershell
   # Install via gcloud
   gcloud components install kubectl
   ```

### **Required Permissions:**
- GCP project with billing enabled
- Editor permissions on the project
- Ability to create service accounts and manage IAM

---

## ⚡ **Example Usage**

### **Complete Setup Example:**
```powershell
# Run setup with all parameters
.\scripts\setup-gcp.ps1 `
  -ProjectId "my-project-123" `
  -GroqApiKey "gsk_xyz123..." `
  -GoogleApiKey "AIzaSyD..." `
  -LangchainApiKey "ls__abc456..."
```

### **Custom Project Setup:**
```powershell
# Setup with different project and region
.\scripts\setup-gcp.ps1 `
  -ProjectId "my-custom-project" `
  -Region "us-central1" `
  -Zone "us-central1-a" `
  -GroqApiKey "your-groq-key" `
  -GoogleApiKey "your-google-key"
```

### **Force Cleanup:**
```powershell
# Cleanup without confirmations
.\scripts\cleanup-gcp.ps1 -Force
```

---

## 🔄 **Complete Workflow**

### **1. Initial Setup**
```powershell
# Run setup script
.\scripts\setup-gcp.ps1 -GroqApiKey "your-key" -GoogleApiKey "your-key"

# Add the generated key to GitHub Secrets
# Go to: Repository → Settings → Secrets → Actions
# Add: GCP_SERVICE_ACCOUNT_KEY = [content of github-actions-key.json]
```

### **2. Deploy Application**
```bash
# Push to trigger deployment
git add .
git commit -m "Deploy to GKE"
git push origin master
```

### **3. Monitor Deployment**
- Check GitHub Actions tab for deployment progress
- Get application URL from deployment logs

### **4. Cleanup (when done)**
```powershell
# Complete cleanup
.\scripts\cleanup-gcp.ps1

# Manually remove GitHub secret: GCP_SERVICE_ACCOUNT_KEY
```

---

## 🔍 **What Each Script Does**

### **Setup Script Actions:**
1. ✅ Validates prerequisites (gcloud CLI, authentication)
2. ✅ Configures GCP project, region, and zone
3. ✅ Enables all required APIs (7 APIs)
4. ✅ Creates GitHub Actions service account
5. ✅ Grants 8 IAM roles for complete infrastructure access
6. ✅ Creates service account key file
7. ✅ Creates GCP secrets for API keys
8. ✅ Provides next steps for GitHub configuration

### **Cleanup Script Actions:**
1. 🗑️ Deletes Kubernetes deployments and secrets
2. 🗑️ Destroys Terraform infrastructure (VPC, GKE, etc.)
3. 🗑️ Removes Docker images and Artifact Registry
4. 🗑️ Deletes GCP secrets
5. 🗑️ Removes service account and IAM permissions
6. 🗑️ Cleans up local key files
7. 🗑️ Verifies complete cleanup

---

## 🛡️ **Security Notes**

### **Setup Security:**
- Service account key is created locally - keep it secure
- API keys are stored in GCP Secret Manager (encrypted)
- Service account follows principle of least privilege

### **Cleanup Security:**
- Multiple confirmation prompts to prevent accidental deletion
- Force mode available for automated scenarios
- Verification step ensures complete cleanup

---

## 🔧 **Troubleshooting**

### **Common Setup Issues:**

**"gcloud not found"**
```powershell
# Install Google Cloud CLI
# Windows: https://cloud.google.com/sdk/docs/install-sdk#windows
# Or: choco install gcloudsdk
```

**"Authentication failed"**
```powershell
# Login to Google Cloud
gcloud auth login
gcloud config set project your-project-id
```

**"API not enabled"**
```powershell
# The script enables APIs automatically, but if it fails:
gcloud services enable compute.googleapis.com container.googleapis.com
```

### **Common Cleanup Issues:**

**"kubectl not found"**
```powershell
# Install kubectl
gcloud components install kubectl
```

**"Resources still exist after cleanup"**
- Check GCP Console manually
- Some resources may have dependencies
- Run cleanup script again with `-Force`

**"Permission denied during cleanup"**
- Ensure you have Editor permissions
- Check if resources are being used by other services

---

## 📞 **Support**

### **Script Logs:**
Both scripts provide colored output with detailed progress information:
- ✅ Green: Success operations
- ⚠️ Yellow: Warnings (non-critical)
- ❌ Red: Errors (critical)
- ℹ️ Cyan: Information

### **Manual Verification:**
```powershell
# Check what exists in your project
gcloud container clusters list
gcloud compute networks list
gcloud artifacts repositories list
gcloud secrets list
gcloud iam service-accounts list
```

### **Getting Help:**
```powershell
# Get help for any script
Get-Help .\scripts\setup-gcp.ps1 -Detailed
Get-Help .\scripts\cleanup-gcp.ps1 -Detailed
```
