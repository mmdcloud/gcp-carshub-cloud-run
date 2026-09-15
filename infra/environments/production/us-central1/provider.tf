terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "8.2.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
  # backend "gcs" {
  #   bucket = "carshub-terraform-state"
  #   prefix = "prod"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.location
}

provider "google-beta" {
  # Configuration options
}