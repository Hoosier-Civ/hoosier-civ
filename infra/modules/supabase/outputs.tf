output "project_id" {
  description = "Supabase project ID"
  value       = supabase_project.main.id
}

output "project_url" {
  description = "Supabase project API URL"
  value       = "https://${supabase_project.main.id}.supabase.co"
}

output "project_ref" {
  description = "Supabase project ref (used by CLI)"
  value       = supabase_project.main.id
}
