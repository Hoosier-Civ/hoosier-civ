output "supabase_project_id" {
  description = "Dev Supabase project ID"
  value       = module.supabase.project_id
}

output "supabase_url" {
  description = "Dev Supabase project URL"
  value       = module.supabase.project_url
}

output "firebase_android_app_id" {
  description = "Dev Firebase Android app ID"
  value       = module.firebase.android_app_id
}

output "firebase_ios_app_id" {
  description = "Dev Firebase iOS app ID"
  value       = module.firebase.ios_app_id
}
