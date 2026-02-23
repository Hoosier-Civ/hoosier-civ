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

