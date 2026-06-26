# ── OCI authentication ────────────────────────────────────────────────────────
variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user whose API key is used by Terraform"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API signing key"
  type        = string
}

variable "private_key" {
  description = "PEM contents of the API signing private key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region (e.g. ap-mumbai-1)"
  type        = string
  default     = "ap-mumbai-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy into (use tenancy OCID for root)"
  type        = string
}

# ── App config ────────────────────────────────────────────────────────────────
variable "project_name" {
  description = "Prefix for all resource display names"
  type        = string
  default     = "think-cricket"
}

variable "app_port" {
  description = "Port the Spring Boot app listens on"
  type        = number
  default     = 8080
}

variable "ssh_public_key" {
  description = "Optional SSH public key for emergency instance access. Leave empty to disable SSH."
  type        = string
  default     = ""
}

variable "ad_index" {
  description = "Index of the availability domain to use (0, 1, or 2). Change if AD-0 is out of capacity."
  type        = number
  default     = 0
}

# ── Artifact (jar) — OCI Object Storage ──────────────────────────────────────
variable "oci_namespace" {
  description = "OCI Object Storage namespace (short string, not an OCID)"
  type        = string
}

variable "oci_artifact_bucket" {
  description = "OCI Object Storage bucket containing the Spring Boot jar"
  type        = string
}

variable "oci_artifact_key" {
  description = "Object name for the jar inside the artifact bucket"
  type        = string
  default     = "think-cricket/app.jar"
}

variable "oci_artifact_access_key" {
  description = "Customer Secret Key ID with read access to the artifact bucket"
  type        = string
  sensitive   = true
}

variable "oci_artifact_secret_key" {
  description = "Customer Secret Key with read access to the artifact bucket"
  type        = string
  sensitive   = true
}

# ── Database (Supabase) ───────────────────────────────────────────────────────
variable "db_url" {
  description = "JDBC URL for Supabase (session pooler)"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
