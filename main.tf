provider "google" {
  project = "cloudrun-terraform-sample"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-b"
}

#
# Variables
#
variable "db_password" {
  description = "Database user password"
  type        = string
}

#
# Cloud SQL
#
resource "google_sql_database_instance" "rails7" {
  name             = "rails7"
  database_version = "MYSQL_5_7"
  settings {
    tier = "db-f1-micro"
  }

  deletion_protection  = "true"
}

resource "google_sql_database" "rails7_cloudrun_sample" {
  name      = "rails7_cloudrun_sample"
  instance  = google_sql_database_instance.rails7.name
  charset   = "utf8mb4"
  collation = "utf8mb4_bin"
}

resource "google_sql_user" "rails7" {
  name     = "rails7"
  instance = google_sql_database_instance.rails7.name
  host     = "%"
  password = var.db_password
}
