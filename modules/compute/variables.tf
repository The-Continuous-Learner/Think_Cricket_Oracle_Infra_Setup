variable "project_name" {
  type = string
}

variable "ad_index" {
  type    = number
  default = 0
}

variable "compartment_ocid" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "app_port" {
  type = number
}

variable "oci_namespace" {
  type = string
}

variable "oci_artifact_bucket" {
  type = string
}

variable "oci_artifact_key" {
  type = string
}

variable "oci_artifact_access_key" {
  type      = string
  sensitive = true
}

variable "oci_artifact_secret_key" {
  type      = string
  sensitive = true
}

variable "db_url" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
