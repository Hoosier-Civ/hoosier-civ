module "firebase" {
  source = "../../modules/firebase"

  project_id  = var.google_project_id
  environment = "prod"
  region      = "us-central1"
}

module "supabase" {
  source = "../../modules/supabase"

  organization_id         = var.supabase_organization_id
  environment             = "prod"
  database_password       = var.supabase_db_password
  region                  = "us-east-1"
  site_url                = "https://hoosierciv.com"
  supabase_access_token = var.supabase_access_token
  cicero_api_key        = var.cicero_api_key
  anthropic_api_key     = var.anthropic_api_key

}
