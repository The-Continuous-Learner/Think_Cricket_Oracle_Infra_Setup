provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
  region       = var.region
}

module "networking" {
  source           = "./modules/networking"
  project_name     = var.project_name
  compartment_ocid = var.compartment_ocid
  app_port         = var.app_port
}

module "compute" {
  source                  = "./modules/compute"
  project_name            = var.project_name
  compartment_ocid        = var.compartment_ocid
  region                  = var.region
  subnet_id               = module.networking.subnet_id
  ssh_public_key          = var.ssh_public_key
  app_port                = var.app_port
  oci_namespace           = var.oci_namespace
  oci_artifact_bucket     = var.oci_artifact_bucket
  oci_artifact_key        = var.oci_artifact_key
  oci_artifact_access_key = var.oci_artifact_access_key
  oci_artifact_secret_key = var.oci_artifact_secret_key
  db_url                  = var.db_url
  db_username             = var.db_username
  db_password             = var.db_password
}
