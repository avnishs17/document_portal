# Google Cloud Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Variables
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "build-test-468516"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "asia-south1-b"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "document-portal-cluster"
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "servicenetworking.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Custom VPC Network
resource "google_compute_network" "document_portal_vpc" {
  name                    = "document-portal-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# Subnet for GKE cluster
resource "google_compute_subnetwork" "document_portal_subnet" {
  name          = "document-portal-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
  network       = google_compute_network.document_portal_vpc.name
  project       = var.project_id
  
  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.2.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.3.0.0/16"
  }
}

# Firewall rule to allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "document-portal-allow-internal"
  network = google_compute_network.document_portal_vpc.name
  project = var.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = ["10.1.0.0/24", "10.2.0.0/16", "10.3.0.0/16"]
}

# Firewall rule to allow HTTP/HTTPS traffic
resource "google_compute_firewall" "allow_http_https" {
  name    = "document-portal-allow-http-https"
  network = google_compute_network.document_portal_vpc.name
  project = var.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["document-portal"]
}

# Service Account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "document-portal-gke-sa"
  display_name = "GKE Service Account for Document Portal"
  project      = var.project_id
}

# Grant necessary roles to the GKE service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader",
    "roles/secretmanager.secretAccessor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# GKE Cluster
resource "google_container_cluster" "document_portal_cluster" {
  name     = var.cluster_name
  location = var.zone
  project  = var.project_id
  
  # Network configuration
  network    = google_compute_network.document_portal_vpc.name
  subnetwork = google_compute_subnetwork.document_portal_subnet.name
  
  # IP allocation policy for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Network policy
  network_policy {
    enabled = true
  }
  
  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
  }
  
  # Master auth
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  depends_on = [
    google_project_service.required_apis,
    google_compute_subnetwork.document_portal_subnet
  ]
}

# Node Pool with high-performance machines
resource "google_container_node_pool" "document_portal_nodes" {
  name       = "document-portal-nodes"
  location   = var.zone
  cluster    = google_container_cluster.document_portal_cluster.name
  project    = var.project_id
  
  # Node count configuration
  initial_node_count = 1
  
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  
  # Node configuration
  node_config {
    machine_type = "e2-standard-4"  # 4 vCPUs, 16 GB RAM (much more powerful than Cloud Run)
    disk_size_gb = 50
    disk_type    = "pd-ssd"
    
    # Service account
    service_account = google_service_account.gke_service_account.email
    
    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # Network tags
    tags = ["document-portal"]
    
    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  
  # Management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  depends_on = [google_container_cluster.document_portal_cluster]
}

# Static IP for Load Balancer
resource "google_compute_global_address" "document_portal_ip" {
  name    = "document-portal-ip"
  project = var.project_id
}

# Output values
output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.document_portal_cluster.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.document_portal_cluster.endpoint
  sensitive   = true
}

output "vpc_network" {
  description = "VPC network name"
  value       = google_compute_network.document_portal_vpc.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.document_portal_subnet.name
}

output "static_ip" {
  description = "Static IP address for load balancer"
  value       = google_compute_global_address.document_portal_ip.address
}

output "service_account_email" {
  description = "GKE service account email"
  value       = google_service_account.gke_service_account.email
}
