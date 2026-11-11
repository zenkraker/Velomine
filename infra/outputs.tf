output "app_public_ip" {
  description = "Public IPv4 address of the app VPS."
  value       = scaleway_instance_ip.app.address
}

output "demo_host" {
  description = "Demo hostname."
  value       = "${var.demo_host}.${var.domain}"
}

output "demo_url" {
  description = "Demo URL."
  value       = "https://${var.demo_host}.${var.domain}"
}

output "db_host" {
  description = "Private IP of the managed database."
  value       = scaleway_rdb_instance.main.private_network[0].ip
}

output "db_port" {
  description = "Private port of the managed database."
  value       = scaleway_rdb_instance.main.private_network[0].port
}

output "db_name" {
  description = "Database name."
  value       = scaleway_rdb_database.velomine.name
}

output "db_user" {
  description = "Database user."
  value       = var.db_user
}

output "backup_bucket" {
  description = "Object Storage bucket for backups."
  value       = scaleway_object_bucket.backups.name
}

output "registry_endpoint" {
  description = "Container Registry endpoint."
  value       = scaleway_registry_namespace.main.endpoint
}

output "registry_namespace" {
  description = "Container Registry namespace."
  value       = scaleway_registry_namespace.main.name
}

# --- dev, staging and prod ---------------------------------------------------
# Off until there are customers; uncomment with the block in main.tf.
#
# output "env_databases" {
#   description = "Database and user of each environment."
#   value       = { for env in var.envs : env => { database = scaleway_rdb_database.env[env].name, user = scaleway_rdb_user.env[env].name } }
# }
#
# output "env_urls" {
#   description = "Public address of each environment (Velomine__PublicUrl, and PUBLIC_URL on its GitHub environment)."
#   value       = { for env in var.envs : env => "https://${var.env_hosts[env]}.${var.domain}" }
# }
