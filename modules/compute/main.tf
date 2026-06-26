# ── Latest Oracle Linux 9 ARM64 image ─────────────────────────────────────────

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "oracle_linux_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}

# ── Compute instance ───────────────────────────────────────────────────────────
# VM.Standard.A1.Flex with 4 OCPU + 24 GB is permanently free on OCI.

resource "oci_core_instance" "app" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.project_name}-instance"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux_arm.images[0].id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    display_name     = "${var.project_name}-vnic"
    hostname_label   = var.project_name
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.root}/scripts/startup.sh", {
      oci_namespace           = var.oci_namespace
      oci_artifact_bucket     = var.oci_artifact_bucket
      oci_artifact_key        = var.oci_artifact_key
      oci_artifact_access_key = var.oci_artifact_access_key
      oci_artifact_secret_key = var.oci_artifact_secret_key
      region                  = var.region
      db_url                  = var.db_url
      db_username             = var.db_username
      db_password             = var.db_password
      app_port                = var.app_port
    }))
  }

  timeouts {
    create = "15m"
  }
}
