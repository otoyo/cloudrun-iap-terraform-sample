# cloudrun-iap-terraform-sample

Terraform sample for Cloud Run+Cloud SQL with IAP

## Requirements

* Terraform >= 1.1

## Usage

Create `secret.tfvars` file and put the database password as `db_password` as follows.

```sh
db_password = "your_database_password"
iap_email = "<you>@gmail.com"
domain = "<your.domain>"
```

Plan and Apply with your Google Cloud Project.

```sh
$ terraform plan -var-file="secret.tfvars"
$ terraform apply -var-file="secret.tfvars"
```

Then, go Google Cloud Console and open IAP.

Turn IAP enable and open OAuth configuration from menu.

Copy Client ID and Client Secret and add to `secret.tfvars` like this.

```sh
oauth_client_id = "<client_id>"
oauth_client_secret = "<client_secret>"
```

Add `oauth_client_id` and `oauth_client_secret` with `iap` block to `google_compute_backend_service`.

```diff
+variable "oauth_client_id" {
+  description = "OAuth Client ID"
+  type        = string
+}

+variable "oauth_client_secret" {
+  description = "OAuth Client Secret"
+  type        = string
+}

 resource "google_compute_backend_service" "rails7-cloudrun-iap-sample" {
   name      = "rails7-cloudrun-iap-sample-backend"
 
   protocol  = "HTTP"
   port_name = "http"
   timeout_sec = 30
 
   backend {
     group = google_compute_region_network_endpoint_group.rails7-cloudrun-iap-sample.id
   }
+
+  iap {
+    oauth2_client_id = var.oauth_client_id
+    oauth2_client_secret = var.oauth_client_secret
+  }
 }
```
