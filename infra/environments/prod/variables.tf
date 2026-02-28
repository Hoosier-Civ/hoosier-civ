variable "supabase_access_token" {
  description = "Supabase personal access token"
  type        = string
  sensitive   = true
}

variable "supabase_organization_id" {
  description = "Supabase organization ID"
  type        = string
}

variable "supabase_db_password" {
  description = "Supabase database password"
  type        = string
  sensitive   = true
}

variable "google_project_id" {
  description = "Google Cloud project ID for Firebase"
  type        = string
}

variable "anthropic_api_key" {
  description = "Anthropic API key"
  type        = string
  sensitive   = true
}

variable "cicero_api_key" {
  description = "Cicero (Azavea) API key for the lookup-district edge function"
  type        = string
  sensitive   = true
}

