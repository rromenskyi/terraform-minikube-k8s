# S3-compatible backend (Backblaze B2 recommended)
terraform {
  backend "s3" {
    bucket = var.backend_bucket

    key    = var.backend_key
    region = var.backend_region

    endpoints = {
      s3 = var.backend_endpoint
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}
