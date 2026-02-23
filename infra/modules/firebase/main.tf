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

  depends_on = [
    google_project_service.firebase_management,
    google_project_service.identity_toolkit,
  ]
}

# Enable the API Keys API (required before creating API keys via Terraform)
resource "google_project_service" "apikeys" {
  project            = var.project_id
  service            = "apikeys.googleapis.com"
  disable_on_destroy = false
}

# Enable the Google Civic Information API
resource "google_project_service" "civic_info" {
  project            = var.project_id
  service            = "civicinfo.googleapis.com"
  disable_on_destroy = false
}

# Enable the Firebase Management API
resource "google_project_service" "firebase_management" {
  project            = var.project_id
  service            = "firebase.googleapis.com"
  disable_on_destroy = false
}

# Enable the Identity Toolkit API (Firebase Auth)
resource "google_project_service" "identity_toolkit" {
  project            = var.project_id
  service            = "identitytoolkit.googleapis.com"
  disable_on_destroy = false
}

# Restricted API key — scoped to Civic Info only, safe to use server-side
resource "google_apikeys_key" "civic_info" {
  name         = "hoosierciv-civic-info-${var.environment}"
  project      = var.project_id
  display_name = "HoosierCiv Civic Info API (${var.environment})"

  restrictions {
    api_targets {
      service = "civicinfo.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.apikeys,
    google_project_service.civic_info,
  ]
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
