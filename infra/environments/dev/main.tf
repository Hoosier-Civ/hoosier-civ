module "supabase" {
  source = "../../modules/supabase"

  organization_id   = var.supabase_organization_id
  environment       = "dev"
  database_password = var.supabase_db_password
  region            = "us-east-1"
  site_url          = "http://localhost:3000"
}

module "firebase" {
  source = "../../modules/firebase"

  project_id  = var.google_project_id
  environment = "dev"
  region      = "us-central1"
}
