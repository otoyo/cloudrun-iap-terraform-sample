# cloudrun-iap-terraform-sample

Terraform sample for Cloud Run+Cloud SQL with IAP

## Requirements

* Terraform >= 1.1

## Usage

Create `secret.tfvars` file and put the database password as `db_password` as follows.

```sh
db_password = "your_database_password"
```

Plan and Apply with your Google Cloud Project.

```sh
$ terraform plan -var-file="secret.tfvars"
$ terraform apply -var-file="secret.tfvars"
```
