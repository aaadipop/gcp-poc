resource "random_id" "db_suffix" {
  byte_length   = 2
}

resource "random_id" "db_password" {
  byte_length   = 12
}

# db networking
resource "google_compute_global_address" "private_ip_address" {
  provider      = google-beta
  name          = "cloud-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = var.network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = var.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "instance" {
  provider         = google
  database_version = "POSTGRES_11"
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  name             = "${var.project_id}-sql-instance-${random_id.db_suffix.hex}"
  region           = var.region

  lifecycle {
    prevent_destroy       = true
  }

  settings {
    tier                  = "db-f1-micro"
    disk_autoresize       = true
    availability_type     = "REGIONAL"

    location_preference {
      zone                = var.db_zone
    }

    ip_configuration {
      ipv4_enabled        = false
      private_network     = var.network
    }

    backup_configuration {
      enabled                         = true
      start_time                      = "00:10"
      point_in_time_recovery_enabled  = true
    }
  }
}

# resource "google_sql_database_instance" "instance_replica" {
#   provider                = google
#   database_version        = "POSTGRES_11"
#   depends_on              = [google_service_networking_connection.private_vpc_connection]
#   name                    = "${var.project_id}-sql-instance-${random_id.db_suffix.hex}-replica"
#   master_instance_name    = "${var.project_id}:${google_sql_database_instance.instance.name}"
#   region                  = var.region
#
#   lifecycle {
#     prevent_destroy       = true
#   }
#
#   replica_configuration {
#     failover_target       = false
#   }
#
#   settings {
#     tier                  = "db-f1-micro"
#     disk_autoresize       = true
#     availability_type     = "ZONAL"
#
#     location_preference {
#         zone              = var.db_replica_zone
#     }
#
#     ip_configuration {
#       ipv4_enabled        = false
#       private_network     = var.network
#     }
#
#     backup_configuration {
#       enabled             = false
#     }
#   }
# }

resource "google_sql_user" "app_user" {
  provider                = google
  instance                = google_sql_database_instance.instance.name
  name                    = "${var.project_id}-db-${var.env}-usr"
  password                = random_id.db_password.hex
}

resource "google_sql_database" "app" {
  provider                = google
  name                    = "${var.project_id}-db-${var.env}"
  instance                = google_sql_database_instance.instance.name
}
