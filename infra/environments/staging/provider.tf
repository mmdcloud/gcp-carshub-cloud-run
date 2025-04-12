terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
  # backend "gcs" {
  #   bucket  = "your-terraform-state-bucket"
  #   prefix  = "staging/terraform"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.location
}
