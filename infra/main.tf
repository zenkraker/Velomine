terraform {
  required_version = ">= 1.8.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.61"
    }
  }
}

provider "scaleway" {
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
}

# One private network for the app and the managed database. The database is
# reachable only from this network, never from the public internet.
resource "scaleway_vpc_private_network" "main" {
  region = var.region
  name   = "${var.project_name}-private"
  tags   = [var.project_name, "demo"]
}

resource "scaleway_instance_ip" "app" {
  zone = var.zone
  tags = [var.project_name, "app"]
}

resource "scaleway_instance_security_group" "app" {
  zone                    = var.zone
  name                    = "${var.project_name}-app"
  description             = "Velomine demo: HTTP, HTTPS and SSH from the admin address"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  # Scaleway's default security rules stay on: they block outbound SMTP, and an
  # untrusted account cannot disable them anyway. The demo sends no email.

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 22
    ip_range = var.admin_cidr
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 80
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 443
  }

  tags = [var.project_name, "app"]
}

resource "scaleway_instance_server" "app" {
  zone              = var.zone
  name              = "${var.project_name}-app"
  type              = var.instance_type
  image             = var.instance_image
  ip_id             = scaleway_instance_ip.app.id
  security_group_id = scaleway_instance_security_group.app.id
  state             = "started"
  tags              = [var.project_name, "app"]

  private_network {
    pn_id = scaleway_vpc_private_network.main.id
  }

  user_data = {
    cloud-init = templatefile("${path.module}/cloud-init.yaml", {
      ssh_public_key = var.ssh_public_key
    })
  }
}

# The initial user owns the database and runs the EF Core migrations. A
# separate migration/runtime role is a production hardening step, not needed
# for the demo.
resource "scaleway_rdb_instance" "main" {
  region                    = var.region
  name                      = "${var.project_name}-db"
  node_type                 = var.db_node_type
  engine                    = var.db_engine
  is_ha_cluster             = var.db_ha_enabled
  disable_backup            = false
  backup_schedule_frequency = 24
  backup_schedule_retention = 7
  backup_same_region        = false
  encryption_at_rest        = true
  user_name                 = var.db_user
  password                  = var.db_password

  private_network {
    pn_id       = scaleway_vpc_private_network.main.id
    enable_ipam = true
  }

  tags = [var.project_name, "db"]
}

resource "scaleway_rdb_database" "velomine" {
  region      = var.region
  instance_id = scaleway_rdb_instance.main.id
  name        = var.db_name
}

# Scaleway creates databases owned by `_rdb_superadmin` and revokes CONNECT from
# PUBLIC, so the app user needs an explicit grant before it can connect.
resource "scaleway_rdb_privilege" "app" {
  region        = var.region
  instance_id   = scaleway_rdb_instance.main.id
  database_name = scaleway_rdb_database.velomine.name
  user_name     = var.db_user
  permission    = "all"
}

resource "scaleway_object_bucket" "backups" {
  name   = var.backup_bucket_name
  region = var.backup_region

  versioning {
    enabled = true
  }

  # Restic keeps daily/weekly/monthly snapshots. Expire only the non-current
  # object versions, so a deleted current version can still be recovered.
  lifecycle_rule {
    id      = "expire-noncurrent-versions"
    enabled = true

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  force_destroy = false
  tags = {
    project = var.project_name
    purpose = "backups"
  }
}

resource "scaleway_registry_namespace" "main" {
  region      = var.region
  name        = var.registry_namespace
  description = "Velomine demo container images"
  is_public   = false
}

resource "scaleway_domain_record" "demo" {
  dns_zone = var.domain
  name     = var.demo_host
  type     = "A"
  data     = scaleway_instance_ip.app.address
  ttl      = 300
}

# velomine.eu and www point at the one VPS; Traefik there decides which environment answers them (deploy.sh APEX_ENV:
# the demo until prod launches).
resource "scaleway_domain_record" "root" {
  dns_zone = var.domain
  name     = ""
  type     = "A"
  data     = scaleway_instance_ip.app.address
  ttl      = 300
}

resource "scaleway_domain_record" "www" {
  dns_zone = var.domain
  name     = "www"
  type     = "A"
  data     = scaleway_instance_ip.app.address
  ttl      = 300
}

# --- dev, staging and prod ---------------------------------------------------
#
# Off until there are customers (docs/architecture.md). They run on the same VPS
# (resize var.instance_type first) and the same database instance as the demo,
# each with its own database and user: Scaleway revokes CONNECT from PUBLIC, so
# a user reaches only the database it is granted. To turn them on, uncomment
# this block and the matching variables and outputs, list the environments in
# var.envs, and run `tofu plan`: commented code is not checked by `tofu
# validate`, so check it then.
#
# resource "scaleway_rdb_database" "env" {
#   for_each    = var.envs
#   region      = var.region
#   instance_id = scaleway_rdb_instance.main.id
#   name        = "velomine_${each.key}"
# }
#
# resource "scaleway_rdb_user" "env" {
#   for_each    = var.envs
#   region      = var.region
#   instance_id = scaleway_rdb_instance.main.id
#   name        = "velomine_${each.key}"
#   password    = var.env_db_passwords[each.key]
#   is_admin    = false
# }
#
# # "all" on its own database lets the user create the feature schemas when the
# # app migrates; it has no right on the other environments' databases.
# resource "scaleway_rdb_privilege" "env" {
#   for_each      = var.envs
#   region        = var.region
#   instance_id   = scaleway_rdb_instance.main.id
#   database_name = scaleway_rdb_database.env[each.key].name
#   user_name     = scaleway_rdb_user.env[each.key].name
#   permission    = "all"
# }
#
# resource "scaleway_domain_record" "env" {
#   for_each = var.envs
#   dns_zone = var.domain
#   name     = var.env_hosts[each.key]
#   type     = "A"
#   data     = scaleway_instance_ip.app.address
#   ttl      = 300
# }
