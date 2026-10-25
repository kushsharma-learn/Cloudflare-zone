# ===========================================================================
# PLUMBING — remote state in YOUR Cloudflare R2 bucket (S3-compatible API).
# ---------------------------------------------------------------------------
# Edit ONLY the bucket name + account id in the endpoint. Credentials are NEVER
# stored here — they are passed at execution time (see README). The `key` is NOT
# set here: there is ONE state file PER ZONE, supplied at init time, e.g.:
#   terraform init -backend-config="key=zones/<zone>.tfstate"
# The GitHub Actions workflow does this automatically for every zone folder.
# ===========================================================================
terraform {
  backend "s3" {
    bucket = "tf-state-lb" # <-- your R2 bucket name
    region = "auto"

    endpoints = {
      # Replace with your Cloudflare Account ID.
      s3 = "https://b1d2a86cbf7d5358135fe2674a27b717.r2.cloudflarestorage.com"
    }

    # R2 is not real AWS, so skip the AWS-specific checks.
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

# -------------------------------------------------------------------------
# Credentials (R2 "Manage R2 API Tokens" -> Access Key ID + Secret Access Key)
# are supplied at execution time, NOT in this file. Two options:
#
#   1) Environment variables (recommended):
#        export AWS_ACCESS_KEY_ID="<R2 Access Key ID>"
#        export AWS_SECRET_ACCESS_KEY="<R2 Secret Access Key>"
#        terraform init
#
#   2) Pass them to `terraform init` with -backend-config:
#        terraform init \
#          -backend-config="access_key=<R2 Access Key ID>" \
#          -backend-config="secret_key=<R2 Secret Access Key>"
# -------------------------------------------------------------------------
