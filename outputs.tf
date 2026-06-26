output "instance_public_ip" {
  description = "Public IP of the OCI compute instance"
  value       = module.compute.public_ip
}

output "api_base_url" {
  description = "Base URL for the Think Cricket API"
  value       = "http://${module.compute.public_ip}:${var.app_port}"
}

output "instance_id" {
  description = "OCID of the compute instance"
  value       = module.compute.instance_id
}
