provider "google" {
  project = "rails7-cloudrun-iap-sample"
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

variable "iap_email" {
  description = "IAP user email"
  type        = string
}

variable "domain" {
  description = "Domain"
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
        image = "gcr.io/rails7-cloudrun-iap-sample/rails7-cloudrun-iap-sample"
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

  autogenerate_revision_name = true
}

#
# Cloud Load Balancing
#
resource "google_compute_global_address" "rails7-cloudrun-iap-sample" {
  name = "rails7-cloudrun-iap-sample-global-address"
}

resource "google_compute_managed_ssl_certificate" "rails7-cloudrun-iap-sample" {
  name = "rails7-cloudrun-iap-sample-cert"

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_region_network_endpoint_group" "rails7-cloudrun-iap-sample" {
  name                  = "rails7-cloudrun-iap-sample-neg"
  region                = "asia-northeast1"
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_service.rails7-cloudrun-iap-sample.name
  }
}

resource "google_compute_backend_service" "rails7-cloudrun-iap-sample" {
  name      = "rails7-cloudrun-iap-sample-backend"

  protocol  = "HTTP"
  port_name = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.rails7-cloudrun-iap-sample.id
  }
}

resource "google_iap_web_backend_service_iam_binding" "rails7-cloudrun-iap-sample" {
  web_backend_service = google_compute_backend_service.rails7-cloudrun-iap-sample.name
  role = "roles/iap.httpsResourceAccessor"
  members = [
    "user:${var.iap_email}",
  ]
}

resource "google_compute_url_map" "rails7-cloudrun-iap-sample" {
  name            = "rails7-cloudrun-iap-sample-urlmap"

  default_service = google_compute_backend_service.rails7-cloudrun-iap-sample.id
}

resource "google_compute_target_https_proxy" "rails7-cloudrun-iap-sample" {
  name   = "rails7-cloudrun-iap-sample-https-proxy"

  url_map          = google_compute_url_map.rails7-cloudrun-iap-sample.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.rails7-cloudrun-iap-sample.id
  ]
}

resource "google_compute_global_forwarding_rule" "rails7-cloudrun-iap-sample" {
  name   = "rails7-cloudrun-iap-sample-forwarding-rule"

  target = google_compute_target_https_proxy.rails7-cloudrun-iap-sample.id
  port_range = "443"
  ip_address = google_compute_global_address.rails7-cloudrun-iap-sample.address
}

# Outputs

output "load_balancer_ip" {
  value = google_compute_global_address.rails7-cloudrun-iap-sample.address
}

output "cloud_run_url" {
  value = element(google_cloud_run_service.rails7-cloudrun-iap-sample.status, 0).url
}
