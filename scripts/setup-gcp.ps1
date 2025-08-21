#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Setup script for Document Portal GCP infrastructure
.DESCRIPTION
    This script sets up the complete GCP infrastructure for the Document Portal project including:
    - Project configuration
    - API enablement
    - Service account creation with permissions
    - Secret creation for API keys
.PARAMETER ProjectId
    The GCP Project ID to use (default: build-test-468516)
.PARAMETER Region
    The GCP region to use (default: asia-south1)
.PARAMETER Zone
    The GCP zone to use (default: asia-south1-b)
.PARAMETER GroqApiKey
    Your GROQ API key
.PARAMETER GoogleApiKey
    Your Google AI API key
.PARAMETER LangchainApiKey
    Your LangChain API key (optional)
.EXAMPLE
    .\setup-gcp.ps1 -GroqApiKey "your-groq-key" -GoogleApiKey "your-google-key"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectId = "build-test-468516",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "asia-south1",
    
    [Parameter(Mandatory=$false)]
    [string]$Zone = "asia-south1-b"
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
    Write-Host "`n🚀 $Message" -ForegroundColor Magenta
    Write-Host ("=" * ($Message.Length + 4)) -ForegroundColor Magenta
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

# Main setup function
function Start-GcpSetup {
    Write-Header "Document Portal GCP Setup"
    
    # Check prerequisites
    Write-Info "Checking prerequisites..."
    
    if (-not (Test-GcloudInstalled)) {
        Write-Error "Google Cloud CLI (gcloud) is not installed or not in PATH"
        Write-Info "Please install it from: https://cloud.google.com/sdk/docs/install"
        exit 1
    }
    
    Write-Success "Google Cloud CLI found"
    
    # Check authentication
    Write-Info "Checking authentication..."
    try {
        $currentAccount = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
        if ([string]::IsNullOrEmpty($currentAccount)) {
            Write-Warning "No active authentication found"
            Write-Info "Please run: gcloud auth login"
            exit 1
        }
        Write-Success "Authenticated as: $currentAccount"
    }
    catch {
        Write-Error "Failed to check authentication status"
        exit 1
    }
    
    # Configure GCP Project
    Write-Header "Configuring GCP Project"
    
    Write-Info "Setting project configuration..."
    try {
        gcloud config set project $ProjectId
        gcloud config set compute/region $Region
        gcloud config set compute/zone $Zone
        Write-Success "Project configured: $ProjectId"
        Write-Success "Region configured: $Region"
        Write-Success "Zone configured: $Zone"
    }
    catch {
        Write-Error "Failed to configure project settings"
        exit 1
    }
    
    # Enable APIs
    Write-Header "Enabling Required APIs"
    
    $apis = @(
        "compute.googleapis.com",
        "container.googleapis.com", 
        "artifactregistry.googleapis.com",
        "secretmanager.googleapis.com",
        "cloudbuild.googleapis.com",
        "servicenetworking.googleapis.com",
        "cloudresourcemanager.googleapis.com"
    )
    
    Write-Info "Enabling APIs (this may take a few minutes)..."
    try {
        $apiList = $apis -join " "
        gcloud services enable $apiList
        Write-Success "All required APIs enabled"
        
        # List enabled APIs for verification
        Write-Info "Enabled APIs:"
        foreach ($api in $apis) {
            Write-Host "  • $api" -ForegroundColor Gray
        }
    }
    catch {
        Write-Error "Failed to enable APIs"
        exit 1
    }
    
    # Create Service Account
    Write-Header "Creating Service Account"
    
    $serviceAccountName = "github-actions"
    $serviceAccountEmail = "$serviceAccountName@$ProjectId.iam.gserviceaccount.com"
    
    Write-Info "Creating service account: $serviceAccountName"
    try {
        # Check if service account already exists
        $existingAccount = gcloud iam service-accounts describe $serviceAccountEmail 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Warning "Service account already exists: $serviceAccountEmail"
        } else {
            gcloud iam service-accounts create $serviceAccountName --description="Service account for GitHub Actions" --display-name="GitHub Actions"
            Write-Success "Service account created: $serviceAccountEmail"
        }
    }
    catch {
        Write-Error "Failed to create service account"
        exit 1
    }
    
    # Grant Permissions
    Write-Header "Granting Service Account Permissions"
    
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
    
    Write-Info "Granting IAM roles..."
    foreach ($role in $roles) {
        try {
            gcloud projects add-iam-policy-binding $ProjectId --member="serviceAccount:$serviceAccountEmail" --role="$role" --quiet
            Write-Host "  • $role" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Failed to grant role: $role"
        }
    }
    Write-Success "All permissions granted"
    
    # Create Service Account Key
    Write-Header "Creating Service Account Key"
    
    $keyFile = "github-actions-key.json"
    Write-Info "Creating service account key: $keyFile"
    try {
        if (Test-Path $keyFile) {
            Write-Warning "Key file already exists, backing up..."
            Move-Item $keyFile "$keyFile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }
        
        gcloud iam service-accounts keys create $keyFile --iam-account=$serviceAccountEmail
        Write-Success "Service account key created: $keyFile"
        Write-Warning "⚠️  Keep this key file secure and add it to GitHub Secrets as GCP_SERVICE_ACCOUNT_KEY"
    }
    catch {
        Write-Error "Failed to create service account key"
        exit 1
    }
    
    # Create Secrets
    Write-Header "Creating API Key Secrets"
    
    # Prompt for API keys securely
    Write-Info "Please provide your API keys (input will be hidden for security):"
    
    Write-Host "Enter your GROQ API key: " -NoNewline -ForegroundColor Yellow
    $GroqApiKey = Read-Host -AsSecureString
    $GroqApiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($GroqApiKey))
    
    Write-Host "Enter your Google AI API key: " -NoNewline -ForegroundColor Yellow
    $GoogleApiKey = Read-Host -AsSecureString
    $GoogleApiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($GoogleApiKey))
    
    Write-Host "Enter your LangChain API key (optional, press Enter to skip): " -NoNewline -ForegroundColor Yellow
    $LangchainApiKey = Read-Host -AsSecureString
    $LangchainApiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($LangchainApiKey))
    
    Write-Info "Creating GROQ API key secret..."
    try {
        Write-Output $GroqApiKeyPlain | gcloud secrets create GROQ_API_KEY --data-file=- 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GROQ_API_KEY secret created"
        } else {
            Write-Warning "GROQ_API_KEY secret already exists, updating..."
            Write-Output $GroqApiKeyPlain | gcloud secrets versions add GROQ_API_KEY --data-file=-
            Write-Success "GROQ_API_KEY secret updated"
        }
    }
    catch {
        Write-Error "Failed to create GROQ_API_KEY secret"
    }
    
    Write-Info "Creating Google API key secret..."
    try {
        Write-Output $GoogleApiKeyPlain | gcloud secrets create GOOGLE_API_KEY --data-file=- 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GOOGLE_API_KEY secret created"
        } else {
            Write-Warning "GOOGLE_API_KEY secret already exists, updating..."
            Write-Output $GoogleApiKeyPlain | gcloud secrets versions add GOOGLE_API_KEY --data-file=-
            Write-Success "GOOGLE_API_KEY secret updated"
        }
    }
    catch {
        Write-Error "Failed to create GOOGLE_API_KEY secret"
    }
    
    if (-not [string]::IsNullOrEmpty($LangchainApiKeyPlain)) {
        Write-Info "Creating LangChain API key secret..."
        try {
            Write-Output $LangchainApiKeyPlain | gcloud secrets create LANGCHAIN_API_KEY --data-file=- 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "LANGCHAIN_API_KEY secret created"
            } else {
                Write-Warning "LANGCHAIN_API_KEY secret already exists, updating..."
                Write-Output $LangchainApiKeyPlain | gcloud secrets versions add LANGCHAIN_API_KEY --data-file=-
                Write-Success "LANGCHAIN_API_KEY secret updated"
            }
        }
        catch {
            Write-Error "Failed to create LANGCHAIN_API_KEY secret"
        }
    } else {
        Write-Info "LangChain API key not provided, skipping..."
    }
    
    # Clear sensitive variables from memory
    $secretsCreated = "GROQ_API_KEY, GOOGLE_API_KEY"
    if (-not [string]::IsNullOrEmpty($LangchainApiKeyPlain)) {
        $secretsCreated += ", LANGCHAIN_API_KEY"
    }
    $GroqApiKeyPlain = $null
    $GoogleApiKeyPlain = $null
    $LangchainApiKeyPlain = $null
    
    # Final Summary
    Write-Header "Setup Complete!"
    
    Write-Success "GCP infrastructure setup completed successfully!"
    Write-Info "Summary:"
    Write-Host "  • Project: $ProjectId" -ForegroundColor Gray
    Write-Host "  • Region: $Region" -ForegroundColor Gray  
    Write-Host "  • Zone: $Zone" -ForegroundColor Gray
    Write-Host "  • Service Account: $serviceAccountEmail" -ForegroundColor Gray
    Write-Host "  • Key File: $keyFile" -ForegroundColor Gray
    Write-Host "  • APIs Enabled: $(($apis).Count) APIs" -ForegroundColor Gray
    Write-Host "  • IAM Roles: $(($roles).Count) roles granted" -ForegroundColor Gray
    Write-Host "  • Secrets Created: $secretsCreated" -ForegroundColor Gray
    
    Write-Warning "`n📋 Next Steps:"
    Write-Host "1. Add the content of '$keyFile' to GitHub repository secrets as 'GCP_SERVICE_ACCOUNT_KEY'" -ForegroundColor Yellow
    Write-Host "2. Push your code to trigger the GitHub Actions deployment" -ForegroundColor Yellow
    Write-Host "3. Monitor the deployment in GitHub Actions tab" -ForegroundColor Yellow
    
    Write-Info "`n🔗 GitHub Repository Settings:"
    Write-Host "   Go to: Settings → Secrets and variables → Actions → New repository secret" -ForegroundColor Gray
    Write-Host "   Name: GCP_SERVICE_ACCOUNT_KEY" -ForegroundColor Gray
    Write-Host "   Value: [entire content of $keyFile]" -ForegroundColor Gray
}

# Run the setup
try {
    Start-GcpSetup
}
catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}
