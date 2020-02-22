resource "random_id" "hash" {
  byte_length = 4
}

locals {
  prefix           = "${lookup(var.tags, "prefix", "changeme")}-${random_id.hash.hex}"
  hostname         = var.ip_hostname ? var.instance_name : "${local.prefix}-${var.instance_name}"
  is_windows_image = var.system_type == "windows" ? "true" : "false"
  bootstrap = var.templatefile != "" ? var.templatefile : templatefile("${path.module}/templates/bootstrap.sh", {
    create_user               = var.create_user,
    user_name                 = var.user_name,
    user_pass                 = var.user_pass,
    user_public_key           = var.user_public_key != "" ? file(var.user_public_key) : var.user_public_key,
    system_type               = var.system_type,
    tmp_path                  = var.tmp_path,
    chef_product_install_url  = var.chef_product_install_url,
    hab_install_url           = var.hab_install_url,
    workstation_chef          = var.workstation_chef,
    chef_product_name         = var.chef_product_name,
    chef_product_version      = var.chef_product_version,
    workstation_hab           = var.workstation_hab,
    hab_version               = var.hab_version,
    install_workstation_tools = var.install_workstation_tools,
    choco_install_url         = var.choco_install_url,
    hostname                  = local.hostname
    helper_files              = var.helper_files,
    ip_hostname               = var.ip_hostname,
    set_hostname              = var.set_hostname,
    populate_hosts            = var.populate_hosts
  })
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

module "network-security-group" {
  source                     = "Azure/network-security-group/azurerm"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location 
  security_group_name        = "nsg-${local.prefix}-${var.instance_name}"
  source_address_prefix      = var.source_address_prefix
  predefined_rules           = var.predefined_rules
  custom_rules               = var.custom_rules
  tags                       = var.tags
}

module "server" {
  source                        = "srb3/compute/azurerm"
  version                       = "2.0.7"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location 
  security_group_id             = module.network-security-group.network_security_group_id
  vnet_subnet_id                = var.vnet_subnet_id
  public_ip_dns                 = var.public_ip_dns
  admin_password                = var.user_pass
  ssh_key                       = var.user_public_key
  remote_port                   = var.remote_port
  admin_username                = var.user_name
  custom_data                   = local.bootstrap
  storage_account_type          = var.storage_account_type
  vm_size                       = var.vm_size
  nb_instances                  = var.nb_instances
  vm_hostname                   = var.instance_name
  vm_os_simple                  = var.vm_os_simple
  vm_os_id                      = var.vm_os_id
  is_windows_image              = local.is_windows_image
  vm_os_publisher               = var.vm_os_publisher
  vm_os_offer                   = var.vm_os_offer
  vm_os_sku                     = var.vm_os_sku
  vm_os_version                 = var.vm_os_version
  allocation_method             = var.allocation_method
  nb_public_ip                  = var.nb_public_ip
  delete_os_disk_on_termination = var.delete_os_disk_on_termination
  data_sa_type                  = var.data_sa_type
  data_disk_size_gb             = var.data_disk_size_gb
  data_disk                     = var.data_disk
  boot_diagnostics              = var.boot_diagnostics
  boot_diagnostics_sa_type      = var.boot_diagnostics_sa_type
  enable_accelerated_networking = var.enable_accelerated_networking
  domain_name_label             = var.domain_name_label
  domain_name_labels            = var.domain_name_labels
  tags                          = var.tags
}

data "azurerm_public_ip" "datasourceip" {
  count               = var.nb_instances
  name                = module.server.public_ip_name[count.index]
  resource_group_name = module.server.vm_resource_group_names[count.index]
}

resource "random_string" "guacamole_access_password" {
  length           = 8
  special          = true
}

### these are outputs created in case you want to plug guacamole-client
# into the created vms

locals {
  user_private_keys = var.user_private_key != "" ? [ for i in range(var.nb_instances) : var.user_private_key ] : []
  sec_type = var.user_private_key != "" ? var.user_pass != "" ? "password" : var.system_type == "windows" ? "password" : "private-key" : "password"
  sec_value = local.sec_type == "password" ? [ for i in range(var.nb_instances) :  var.user_pass ] : [ for i in range(var.nb_instances) : file(var.user_private_key) ]

  output_hostnames = [
    for ip in module.server.network_interface_private_ip :
      "${local.hostname}-${replace(ip, ".", "-")}"
  ]

  win_connections = [
    for ip in module.server.public_ip_address :
    { 
      "name"     = "${local.prefix}-${var.instance_name}-${index(module.server.public_ip_address, ip)}",
      "protocol" = "rdp",
      "params"   = {
        "security"          = "any",
        "ignore-cert"       = "true",
        "hostname"          = module.server.network_interface_private_ip[index(module.server.public_ip_address, ip)],
        "port"              = 3389,
        "username"          = var.user_name,
        "${local.sec_type}" = local.sec_value[index(module.server.public_ip_address, ip)]
      }
    }
  ]
  lin_connections = [
    for ip in module.server.public_ip_address :
    { 
      "name"     = "${local.prefix}-${var.instance_name}-${index(module.server.public_ip_address, ip)}",
      "protocol" = "ssh",
      "params"   = {
        "color-scheme"      = "green-black",
        "hostname"          = module.server.network_interface_private_ip[index(module.server.public_ip_address, ip)],
        "port"              = 22,
        "username"          = var.user_name,
        "${local.sec_type}" = local.sec_value[index(module.server.public_ip_address, ip)]
      }
    }
  ]
  connections = var.system_type == "linux" ? local.lin_connections : local.win_connections
}
