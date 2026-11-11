variable "project_id" {
  description = "Scaleway project ID. Can also come from SCW_DEFAULT_PROJECT_ID."
  type        = string
}

variable "region" {
  description = "Scaleway region for the app and managed database."
  type        = string
  default     = "nl-ams"
}

variable "zone" {
  description = "Scaleway zone. Must be in the same region as the private network."
  type        = string
  default     = "nl-ams-1"
}

variable "project_name" {
  description = "Prefix for resource names and tags."
  type        = string
  default     = "velomine-demo"
}

variable "domain" {
  description = "DNS zone managed in Scaleway Domains and DNS."
  type        = string
  default     = "velomine.eu"
}


variable "demo_host" {
  description = "Subdomain for the demo club."
  type        = string
  default     = "demo"
}

variable "instance_type" {
  description = "App VPS type. STARDUST1-S is the cheapest demo size; use DEV1-S before real users."
  type        = string
  default     = "STARDUST1-S"
}

variable "instance_image" {
  description = "Scaleway instance image name."
  type        = string
  default     = "ubuntu_noble"
}

variable "db_node_type" {
  description = "Managed PostgreSQL node type."
  type        = string
  default     = "DB-DEV-S"
}

variable "db_engine" {
  description = "Managed PostgreSQL engine version."
  type        = string
  default     = "PostgreSQL-17"
}

variable "db_ha_enabled" {
  description = "Enable the HA replica. Leave false for the demo."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Database name."
  type        = string
  default     = "velomine"
}

variable "db_user" {
  description = "Initial database user. The app and the migrations use it for the demo."
  type        = string
  default     = "velomine_app"
}

variable "db_password" {
  description = "Database password. Inject with TF_VAR_db_password; never commit it."
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for the deploy user."
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed to reach SSH, for example 203.0.113.10/32."
  type        = string
}

variable "backup_bucket_name" {
  description = "Globally unique Object Storage bucket name for restic backups."
  type        = string
}

variable "backup_region" {
  description = "Region for the backup bucket, different from the app region."
  type        = string
  default     = "fr-par"
}

variable "registry_namespace" {
  description = "Scaleway Container Registry namespace, unique in the region."
  type        = string
  default     = "velomine-demo"
}

# --- dev, staging and prod ---------------------------------------------------
# Off until there are customers; uncomment with the block in main.tf.
#
# variable "envs" {
#   description = "Environments that run besides the demo, on the same VPS and database instance."
#   type        = set(string)
#   default     = ["dev", "staging", "prod"]
# }
#
# variable "env_hosts" {
#   description = "DNS name of each environment under var.domain."
#   type        = map(string)
#   default = {
#     dev     = "dev"
#     staging = "staging"
#     prod    = "app"
#   }
# }
#
# variable "env_db_passwords" {
#   description = "Password of each environment's database user. TF_VAR_env_db_passwords='{dev=\"...\",staging=\"...\",prod=\"...\"}'; never commit them."
#   type        = map(string)
#   sensitive   = true
# }
