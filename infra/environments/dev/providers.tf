terraform {
  required_version = ">= 1.6.0"

  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "supabase" {
  access_token = var.supabase_access_token
}

provider "google" {
  project = var.google_project_id
}

provider "google-beta" {
  project = var.google_project_id
}
