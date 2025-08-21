#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cleanup script for Document Portal GCP infrastructure
.DESCRIPTION
    This script completely removes all GCP infrastructure for the Document Portal project including:
    - Kubernetes deployments and secrets
    - Terraform infrastructure (VPC, GKE cluster, etc.)
    - Docker images and Artifact Registry
    - GCP secrets and service accounts
    - Local files
.PARAMETER ProjectId
    The GCP Project ID to clean up (default: build-test-468516)
.PARAMETER Region
    The GCP region (default: asia-south1)
.PARAMETER Zone
    The GCP zone (default: asia-south1-b)
.PARAMETER Force
    Skip confirmation prompts and force deletion
.EXAMPLE
    .\cleanup-gcp.ps1
.EXAMPLE
    .\cleanup-gcp.ps1 -Force
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectId = "build-test-468516",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "asia-south1",
    
    [Parameter(Mandatory=$false)]
    [string]$Zone = "asia-south1-b",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Color functions for better output
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n🗑️  $Message" -ForegroundColor Red
    Write-Host ("=" * ($Message.Length + 5)) -ForegroundColor Red
}

function Write-Danger {
    param([string]$Message)
    Write-Host "🚨 $Message" -ForegroundColor Red -BackgroundColor Yellow
}

# Check if gcloud is installed
function Test-GcloudInstalled {
    try {
        $null = gcloud version
        return $true
    }
    catch {
        return $false
    }
}

# Check if kubectl is available
function Test-KubectlInstalled {
    try {
        $null = kubectl version --client
        return $true
    }
    catch {
        return $false
    }
}

# Confirmation function
function Get-UserConfirmation {
    param([string]$Message)
    
    if ($Force) {
        Write-Warning "Force mode enabled - skipping confirmation"
        return $true
    }
    
    Write-Warning $Message
    $response = Read-Host "Type 'DELETE' to confirm (or anything else to cancel)"
    return $response -eq "DELETE"
}

# Main cleanup function
function Start-GcpCleanup {
    Write-Danger "DOCUMENT PORTAL GCP INFRASTRUCTURE CLEANUP"
    Write-Danger "THIS WILL PERMANENTLY DELETE ALL RESOURCES!"
    
    if (-not (Get-UserConfirmation "Are you sure you want to delete ALL GCP resources for Document Portal?")) {
        Write-Info "Cleanup cancelled"
        exit 0
    }
    
    # Check prerequisites
    Write-Info "Checking prerequisites..."
    
    if (-not (Test-GcloudInstalled)) {
        Write-Error "Google Cloud CLI (gcloud) is not installed or not in PATH"
        exit 1
    }
    
    Write-Success "Google Cloud CLI found"
    
    # Configure project
    Write-Info "Setting project configuration..."
    try {
        gcloud config set project $ProjectId
        gcloud config set compute/region $Region  
        gcloud config set compute/zone $Zone
        Write-Success "Project configured: $ProjectId"
    }
    catch {
        Write-Error "Failed to configure project"
        exit 1
    }
    
    # Step 1: Delete Kubernetes Resources
    Write-Header "Deleting Kubernetes Resources"
    
    if (Test-KubectlInstalled) {
        Write-Info "Checking for existing GKE cluster..."
        try {
            $clusterExists = gcloud container clusters describe "document-portal-cluster" --zone=$Zone --project=$ProjectId 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Info "Getting GKE credentials..."
                gcloud container clusters get-credentials "document-portal-cluster" --zone=$Zone --project=$ProjectId
                
                Write-Info "Deleting Kubernetes deployments..."
                if (Test-Path "k8s/deployment.yaml") {
                    kubectl delete -f k8s/deployment.yaml --ignore-not-found=true
                    Write-Success "Kubernetes deployment deleted"
                } else {
                    Write-Warning "k8s/deployment.yaml not found, trying generic deletion"
                    kubectl delete deployment document-portal --ignore-not-found=true
                    kubectl delete service document-portal-service --ignore-not-found=true
                    kubectl delete ingress document-portal-ingress --ignore-not-found=true
                }
                
                Write-Info "Deleting Kubernetes secrets..."
                kubectl delete secret groq-api-key --ignore-not-found=true
                kubectl delete secret google-api-key --ignore-not-found=true
                kubectl delete secret langchain-api-key --ignore-not-found=true
                Write-Success "Kubernetes secrets deleted"
            } else {
                Write-Info "No GKE cluster found, skipping Kubernetes cleanup"
            }
        }
        catch {
            Write-Warning "Failed to clean up Kubernetes resources: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "kubectl not found, skipping Kubernetes cleanup"
    }
    
    # Step 2: Destroy Terraform Infrastructure
    Write-Header "Destroying Terraform Infrastructure"
    
    if (Test-Path "terraform") {
        Write-Info "Found terraform directory, destroying infrastructure..."
        try {
            Push-Location "terraform"
            
            # Initialize terraform if needed
            if (-not (Test-Path ".terraform")) {
                Write-Info "Initializing Terraform..."
                terraform init
            }
            
            Write-Info "Destroying all Terraform-managed infrastructure..."
            Write-Warning "This may take 10-15 minutes for GKE cluster deletion..."
            terraform destroy -auto-approve -var="project_id=$ProjectId" -var="region=$Region" -var="zone=$Zone"
            
            Write-Info "Cleaning up Terraform files..."
            Remove-Item -Path ".terraform*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "terraform.tfstate*" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "tfplan" -Force -ErrorAction SilentlyContinue
            
            Write-Success "Terraform infrastructure destroyed"
        }
        catch {
            Write-Warning "Failed to destroy Terraform infrastructure: $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }
    } else {
        Write-Warning "No terraform directory found, skipping Terraform cleanup"
    }
    
    # Step 3: Delete Docker Images and Artifact Registry
    Write-Header "Deleting Docker Images and Artifact Registry"
    
    Write-Info "Checking for Artifact Registry repository..."
    try {
        $repoExists = gcloud artifacts repositories describe "document-portal" --location=$Region --project=$ProjectId 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Deleting all Docker images..."
            $images = gcloud artifacts docker images list "$Region-docker.pkg.dev/$ProjectId/document-portal" --format="value(IMAGE_URI)" 2>$null
            if ($images) {
                foreach ($image in $images) {
                    gcloud artifacts docker images delete $image --quiet --async
                }
                Write-Success "Docker image deletion initiated"
            }
            
            Write-Info "Deleting Artifact Registry repository..."
            gcloud artifacts repositories delete "document-portal" --location=$Region --quiet
            Write-Success "Artifact Registry repository deleted"
        } else {
            Write-Info "No Artifact Registry repository found"
        }
    }
    catch {
        Write-Warning "Failed to clean up Artifact Registry: $($_.Exception.Message)"
    }
    
    # Step 4: Delete GCP Secrets
    Write-Header "Deleting GCP Secrets"
    
    $secrets = @("GROQ_API_KEY", "GOOGLE_API_KEY", "LANGCHAIN_API_KEY")
    
    foreach ($secret in $secrets) {
        try {
            Write-Info "Deleting secret: $secret"
            gcloud secrets delete $secret --quiet 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Secret deleted: $secret"
            } else {
                Write-Info "Secret not found: $secret"
            }
        }
        catch {
            Write-Warning "Failed to delete secret $secret: $($_.Exception.Message)"
        }
    }
    
    # Step 5: Remove Service Account and Permissions
    Write-Header "Removing Service Account and Permissions"
    
    $serviceAccountEmail = "github-actions@$ProjectId.iam.gserviceaccount.com"
    
    Write-Info "Removing IAM policy bindings..."
    $roles = @(
        "roles/container.admin",
        "roles/artifactregistry.admin",
        "roles/secretmanager.admin", 
        "roles/iam.serviceAccountUser",
        "roles/compute.admin",
        "roles/iam.serviceAccountAdmin",
        "roles/resourcemanager.projectIamAdmin",
        "roles/editor"
    )
    
    foreach ($role in $roles) {
        try {
            gcloud projects remove-iam-policy-binding $ProjectId --member="serviceAccount:$serviceAccountEmail" --role="$role" --quiet 2>$null
            Write-Host "  • Removed $role" -ForegroundColor Gray
        }
        catch {
            Write-Host "  • $role (not found)" -ForegroundColor DarkGray
        }
    }
    
    Write-Info "Deleting service account keys..."
    try {
        $keys = gcloud iam service-accounts keys list --iam-account=$serviceAccountEmail --format="value(name)" 2>$null
        if ($keys) {
            foreach ($key in $keys) {
                if ($key -notlike "*system-managed*") {
                    gcloud iam service-accounts keys delete $key --iam-account=$serviceAccountEmail --quiet
                }
            }
            Write-Success "Service account keys deleted"
        }
    }
    catch {
        Write-Info "No service account keys found"
    }
    
    Write-Info "Deleting service account..."
    try {
        gcloud iam service-accounts delete $serviceAccountEmail --quiet 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Service account deleted"
        } else {
            Write-Info "Service account not found"
        }
    }
    catch {
        Write-Warning "Failed to delete service account: $($_.Exception.Message)"
    }
    
    # Step 6: Delete Local Files  
    Write-Header "Deleting Local Files"
    
    $localFiles = @(
        "github-actions-key.json",
        "github-actions-key.json.backup.*"
    )
    
    foreach ($filePattern in $localFiles) {
        try {
            $files = Get-ChildItem -Path $filePattern -ErrorAction SilentlyContinue
            if ($files) {
                foreach ($file in $files) {
                    Remove-Item -Path $file.FullName -Force
                    Write-Success "Deleted: $($file.Name)"
                }
            } else {
                Write-Info "File not found: $filePattern"
            }
        }
        catch {
            Write-Warning "Failed to delete $filePattern: $($_.Exception.Message)"
        }
    }
    
    # Step 7: Verification
    Write-Header "Verification"
    
    Write-Info "Verifying cleanup completion..."
    
    $verificationResults = @()
    
    # Check clusters
    try {
        $clusters = gcloud container clusters list --filter="name:document-portal*" --format="value(name)" 2>$null
        if ([string]::IsNullOrEmpty($clusters)) {
            $verificationResults += "✅ No GKE clusters found"
        } else {
            $verificationResults += "❌ GKE clusters still exist: $clusters"
        }
    } catch {
        $verificationResults += "⚠️  Could not verify GKE clusters"
    }
    
    # Check networks
    try {
        $networks = gcloud compute networks list --filter="name:document-portal*" --format="value(name)" 2>$null
        if ([string]::IsNullOrEmpty($networks)) {
            $verificationResults += "✅ No VPC networks found"
        } else {
            $verificationResults += "❌ VPC networks still exist: $networks"
        }
    } catch {
        $verificationResults += "⚠️  Could not verify VPC networks"
    }
    
    # Check repositories
    try {
        $repos = gcloud artifacts repositories list --location=$Region --filter="name:*document-portal*" --format="value(name)" 2>$null
        if ([string]::IsNullOrEmpty($repos)) {
            $verificationResults += "✅ No Artifact Registry repositories found"
        } else {
            $verificationResults += "❌ Artifact Registry repositories still exist"
        }
    } catch {
        $verificationResults += "⚠️  Could not verify Artifact Registry"
    }
    
    # Check secrets
    try {
        $secretsList = gcloud secrets list --filter="name:(GROQ_API_KEY OR GOOGLE_API_KEY OR LANGCHAIN_API_KEY)" --format="value(name)" 2>$null
        if ([string]::IsNullOrEmpty($secretsList)) {
            $verificationResults += "✅ No API key secrets found"
        } else {
            $verificationResults += "❌ Secrets still exist: $secretsList"
        }
    } catch {
        $verificationResults += "⚠️  Could not verify secrets"
    }
    
    # Check service accounts
    try {
        $accounts = gcloud iam service-accounts list --filter="email:github-actions@*" --format="value(email)" 2>$null
        if ([string]::IsNullOrEmpty($accounts)) {
            $verificationResults += "✅ No GitHub Actions service account found"
        } else {
            $verificationResults += "❌ Service account still exists: $accounts"
        }
    } catch {
        $verificationResults += "⚠️  Could not verify service accounts"
    }
    
    # Display verification results
    foreach ($result in $verificationResults) {
        Write-Host $result
    }
    
    # Final Summary
    Write-Header "Cleanup Complete!"
    
    Write-Success "GCP infrastructure cleanup completed!"
    Write-Info "Summary of actions taken:"
    Write-Host "  • Kubernetes deployments and secrets deleted" -ForegroundColor Gray
    Write-Host "  • Terraform infrastructure destroyed" -ForegroundColor Gray
    Write-Host "  • Docker images and Artifact Registry deleted" -ForegroundColor Gray
    Write-Host "  • GCP secrets deleted" -ForegroundColor Gray
    Write-Host "  • Service account and permissions removed" -ForegroundColor Gray
    Write-Host "  • Local key files deleted" -ForegroundColor Gray
    
    Write-Warning "`n📋 Manual Steps Required:"
    Write-Host "1. Remove 'GCP_SERVICE_ACCOUNT_KEY' from GitHub repository secrets" -ForegroundColor Yellow
    Write-Host "2. Check GCP Console to verify all resources are deleted" -ForegroundColor Yellow
    Write-Host "3. Verify billing has stopped for these resources" -ForegroundColor Yellow
    
    $hasErrors = $verificationResults | Where-Object { $_ -like "❌*" }
    if ($hasErrors) {
        Write-Warning "`n⚠️  Some resources may still exist. Check the verification results above."
        Write-Info "You may need to manually delete remaining resources in GCP Console."
    } else {
        Write-Success "`n🎉 All resources successfully cleaned up!"
    }
}

# Run the cleanup
try {
    Start-GcpCleanup
}
catch {
    Write-Error "Cleanup failed: $($_.Exception.Message)"
    exit 1
}
