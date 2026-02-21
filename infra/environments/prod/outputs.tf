output "supabase_project_id" {
  description = "Prod Supabase project ID"
  value       = module.supabase.project_id
}

output "supabase_url" {
  description = "Prod Supabase project URL"
  value       = module.supabase.project_url
}

output "firebase_android_app_id" {
  description = "Prod Firebase Android app ID"
  value       = module.firebase.android_app_id
}

output "firebase_ios_app_id" {
  description = "Prod Firebase iOS app ID"
  value       = module.firebase.ios_app_id
}
