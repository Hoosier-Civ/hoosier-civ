terraform {
  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

resource "supabase_project" "main" {
  organization_id   = var.organization_id
  name              = "hoosierciv-${var.environment}"
  database_password = var.database_password
  region            = var.region
}

resource "supabase_secret" "civic_api_key" {
  project_ref = supabase_project.main.id
  name        = "GOOGLE_CIVIC_API_KEY"
  value       = var.civic_api_key
}

resource "supabase_secret" "district_cache_ttl" {
  project_ref = supabase_project.main.id
  name        = "DISTRICT_CACHE_TTL_DAYS"
  value       = tostring(var.district_cache_ttl_days)
}

resource "supabase_settings" "main" {
  project_ref = supabase_project.main.id

  auth = jsonencode({
    site_url           = var.site_url
    jwt_expiry         = 3600
    enable_signup      = true
    anonymous_sign_ins = { enabled = true }
    email = {
      enable_signup          = true
      enable_confirmations   = var.environment == "prod"
      double_confirm_changes = true
      secure_password_change = true
    }
  })
}
