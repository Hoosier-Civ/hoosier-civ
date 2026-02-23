terraform {
  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "supabase_project" "main" {
  organization_id   = var.organization_id
  name              = "hoosierciv-${var.environment}"
  database_password = var.database_password
  region            = var.region
}

resource "null_resource" "edge_function_secrets" {
  triggers = {
    google_civic_api_key_hash = sha256(var.google_civic_api_key)
    anthropic_api_key_hash    = sha256(var.anthropic_api_key)
  }

  provisioner "local-exec" {
    command = <<EOT
      supabase secrets set \
        GOOGLE_CIVIC_API_KEY=${var.google_civic_api_key} \
        ANTHROPIC_API_KEY=${var.anthropic_api_key} \
        DISTRICT_CACHE_TTL_DAYS=90 \
        --project-ref ${supabase_project.main.id}
    EOT
    environment = {
      SUPABASE_ACCESS_TOKEN = var.supabase_access_token
    }
  }

  depends_on = [supabase_project.main]
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
