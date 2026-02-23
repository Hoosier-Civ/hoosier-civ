variable "organization_id" {
  description = "Supabase organization ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "database_password" {
  description = "Supabase database password"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Supabase project region"
  type        = string
  default     = "us-east-1"
}

variable "site_url" {
  description = "Site URL for auth redirects"
  type        = string
}

variable "google_civic_api_key" {
  description = "Google Civic Information API key for the lookup-district edge function"
  type        = string
  sensitive   = true
}

variable "anthropic_api_key" {
  description = "Anthropic API key for AI edge functions"
  type        = string
  sensitive   = true
}

variable "supabase_access_token" {
  description = "Supabase personal access token (used by null_resource to set secrets)"
  type        = string
  sensitive   = true
}

