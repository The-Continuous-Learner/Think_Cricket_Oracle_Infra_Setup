terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }

  # OCI Object Storage backend using S3-compatible API.
  # All values are injected at init time via -backend-config flags in the workflow.
  # OCI does not have a DynamoDB equivalent so state locking is omitted — safe for
  # single-user / single-workflow use.
  backend "s3" {}
}
