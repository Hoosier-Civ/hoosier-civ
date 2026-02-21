terraform {
  required_providers {
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

resource "google_firebase_project" "main" {
  provider = google-beta
  project  = var.project_id
}

resource "google_firebase_android_app" "main" {
  provider     = google-beta
  project      = var.project_id
  display_name = "HoosierCiv Android (${var.environment})"
  package_name = var.environment == "prod" ? "com.hoosierciv.app" : "com.hoosierciv.app.dev"
  depends_on   = [google_firebase_project.main]
}

resource "google_firebase_apple_app" "main" {
  provider     = google-beta
  project      = var.project_id
  display_name = "HoosierCiv iOS (${var.environment})"
  bundle_id    = var.environment == "prod" ? "com.hoosierciv.app" : "com.hoosierciv.app.dev"
  depends_on   = [google_firebase_project.main]
}
