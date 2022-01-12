provider "google" {
  project = "cloudrun-iap-terraform-sample"
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

resource "google_sql_database" "rails7-cloudrun-iap-sample" {
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

#
# Cloud Run
#
resource "google_cloud_run_service" "rails7-cloudrun-iap-sample" {
  name     = "rails7-cloudrun-iap-sample"
  location = "asia-northeast1"

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun-terraform-sample/rails7-cloudrun-iap-sample"
        env {
          name  = "RAILS_ENV"
          value = "production"
        }
        env {
          name  = "RAILS_LOG_TO_STDOUT"
          value = "1"
        }
        env {
          name  = "RAILS_SERVE_STATIC_FILES"
          value = "1"
        }
        env {
          name  = "RAILS_MASTER_KEY"
          value_from {
            secret_key_ref {
              name = "rails-master-key"
              key  = "latest"
            }
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "1000"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.rails7.connection_name
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/launch-stage" = "BETA"
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.rails7-cloudrun-iap-sample.location
  project     = google_cloud_run_service.rails7-cloudrun-iap-sample.project
  service     = google_cloud_run_service.rails7-cloudrun-iap-sample.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
