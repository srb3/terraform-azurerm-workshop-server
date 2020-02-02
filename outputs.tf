output "vm_ids" {
  description = "A list of the public ip addresses of the created servers"
  value       = module.server.vm_ids
}

output "resource_group_names" {
  value = module.server.vm_resource_group_names
}

output "server_public_ip" {
  value = data.azurerm_public_ip.datasourceip.*.ip_address
  depends_on = [module.server]
}

output "server_private_ip" {
  description = "A list of the private ip addresses of the created servers"
  value       = module.server.network_interface_private_ip
}

output "public_ip_fqdn" {
  description = "The dns name of the public IP"
  value       = data.azurerm_public_ip.datasourceip.*.fqdn
  depends_on = [module.server]
}

output "public_ip_dns_name" {
  description = "The dns name of the public IP"
  value       = module.server.public_ip_dns_name
}

output "guacamole_user" {
  description = "The name of the user used for remote access"
  value = var.user_name
}

output "guacamole_pass" {
  description = "A generated password that could be used for setting the Guacamole ui login"
  value = random_string.guacamole_access_password.result
}

output "guacamole_connections" {
  description = "A list of client connection detials for consumption by the Guacamole module"
  value       = local.connections
}

#output "password_data" {
#  description = "List of Base-64 encoded encrypted password data for the instance"
#  value       = module.server.password_data
#}

output "hostname" {
  description = "The hostname for each instance if the systems are linux and the set hostname bool is true "
  value       = local.output_hostnames
}
