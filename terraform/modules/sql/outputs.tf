output "db_name" {
  value = google_sql_database.app.name
}

output "db_user" {
  value = google_sql_user.app_user.name
}

output "db_pass" {
  value = google_sql_user.app_user.password
  sensitive = true
}

output "db_host" {
  value = google_sql_database_instance.instance.first_ip_address
}
