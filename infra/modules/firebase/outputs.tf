output "android_app_id" {
  description = "Firebase Android app ID"
  value       = google_firebase_android_app.main.app_id
}

output "ios_app_id" {
  description = "Firebase iOS app ID"
  value       = google_firebase_apple_app.main.app_id
}

output "civic_api_key" {
  description = "Google Civic Info API key (restricted to civicinfo.googleapis.com)"
  value       = google_apikeys_key.civic_info.key_string
  sensitive   = true
}
