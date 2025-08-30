terraform {
  required_version = ">= 1.5"
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
  backend "gcs" {
    bucket = "carshub-terraform-state"
    prefix = "prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.location
}