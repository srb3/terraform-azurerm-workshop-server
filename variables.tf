########### misc settings ########################

variable "templatefile" {
  description = "A string of commands used to bootstrap the instance" 
  type        = string
  default     = ""
}



########### workstation settings #################

variable "instance_name" {
  description = "A common name to append to all the instances created in this module"
  type        = string
}

variable "set_hostname" {
  description = "Should we set the hostname to the instance name on linux systems"
  type        = bool
  default     = true
}

variable "ip_hostname" {
  description = "Should we append the ip address to help make hostnames unique when creating a batch of linux servers"
  type        = bool
  default     = true
}

variable "populate_hosts" {
  description = "Set an entry in /etc/hosts for equivilent to `echo \"$(hostname -I) $(hostname)\" >> /etc/hosts`"
  type        = bool
  default     = false
}

variable "tmp_path" {
  description = "The location of the temp path to use for downloading installers and executing scripts"
  type        = string
  default     = "/var/tmp/workstation_install"
}

variable "chef_product_install_url" {
  description = "The url to use for installing chef products"
  type        = string
  default     = "https://www.chef.io/chef/install.sh"
}

variable "hab_install_url" {
  description = "The url to use for installing chef habitat"
  type        = string
  default     = "https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh"
}

variable "choco_install_url" {
  description = "The url to use for installing choco"
  type        = string
  default     = "https://chocolatey.org/install.ps1"
}

variable "install_workstation_tools" {
  description = "Should we install general workstation tools"
  type        = bool
  default     = false
}

variable "workstation_hab" {
  description = "Should we install the habitat application"
  type        = bool
  default     = false
}

variable "workstation_chef" {
  description = "Should we install chef related products (chef, chefdk, chef-workstation, inspec)"
  type        = bool
  default     = false
}

variable "chef_product_name" {
  description = "The name of the chef product to install (chef-workstion, chefdk, inspec)"
  type        = string
  default     = "chef-workstation"
}

variable "chef_product_version" {
  description = "The version of the chef product to install"
  type        = string
  default     = "latest"
}

variable "hab_version" {
  description = "The version of the chef habitat to install"
  type        = string
  default     = "latest"
}

variable "helper_files" {
  description = "a json string of file names and there content to create on the target workstation"
  type        = string
  default     = "[]"
}

########### connection settings ##################

variable "user_name" {
  description = "The ssh or winrm user name, used to create users on the target servers, if the create_user variable is set to true"
  type        = string
}

variable "user_pass" {
  description = "The password to set for the ssh or winrm user"
  type        = string
  default     = ""
}

variable "create_user" {
  description = "Should the user be created"
  default     = false
}

variable "user_public_key" {
  description = "If set on linux systems and the create_user variable is true then the content from the file path provided in this variable will be added to the authorized_keys folder of the newly created user"
  type        = string
  default     = ""
}

variable "user_private_key" {
  description = "This needs to be set to the path of the private key pair that matches the provided public key. it is used when creating the guacamole connection data. Setting it allowd the guacamole client/server to ssh to the targets. can be ignored if using ssh passwords"
  type    = string
  default = ""
}

variable "system_type" {
  description = "Choose either linux or windows"
  type        = string
  default     = "linux"
}

########### azure settings #########################

variable "tags" {
  description = "A map of tags to pass through to the vpc, security group and instances"
  type        = map
  default     = {}
}

########### resource group settings #########################

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be used"
}

variable "resource_group_location" {
  description = "The location of the resource group in which the resources will be used"
}
########### security group settings ##############

variable "security_group_name" {
  description = "Network security group name"
  default     = "nsg"
}

variable "predefined_rules" {
  type    = list(any)
  default = []
}

variable "custom_rules" {
  description = "Security rules for the network security group using this format name = [priority, direction, access, protocol, source_port_range, destination_port_range, source_address_prefix, destination_address_prefix, description]"
  type        = list(any)
  default     = []
}

variable "source_address_prefix" {
  type    = list(string)
  default = ["*"]
}

variable "destination_address_prefix" {
  type    = list(string)
  default = ["*"]
}

############ azure instance settings ############

variable "vnet_subnet_id" {
  description = "The subnet id of the virtual network where the virtual machines will reside."
}

variable "public_ip_dns" {
  description = "Optional globally unique per datacenter region domain name label to apply to each public ip address. e.g. thisvar.varlocation.cloudapp.azure.com where you specify only thisvar here. This is an array of names which will pair up sequentially to the number of public ips defined in var.nb_public_ip. One name or empty string is required for every public ip. If no public ip is desired, then set this to an array with a single empty string."
  default     = [""]
}

variable "remote_port" {
  description = "Remote tcp port to be used for access to the vms created via the nsg applied to the nics."
  default     = ""
}

variable "custom_data" {
  description = "The custom data to supply to the machine. This can be used as a cloud-init for Linux systems."
  default     = ""
}

variable "storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options are Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS."
  default     = "Premium_LRS"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_DS1_V2"
}

variable "nb_instances" {
  description = "Specify the number of vm instances"
  default     = "1"
}

variable "vm_os_simple" {
  description = "Specify UbuntuServer, WindowsServer, RHEL, openSUSE-Leap, CentOS, Debian, CoreOS and SLES to get the latest image version of the specified os.  Do not provide this value if a custom value is used for vm_os_publisher, vm_os_offer, and vm_os_sku."
  default     = ""
}

variable "vm_os_id" {
  description = "The resource ID of the image that you want to deploy if you are using a custom image.Note, need to provide system_type = 'windows' for windows custom images."
  default     = ""
}

variable "vm_os_publisher" {
  description = "The name of the publisher of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = ""
}

variable "vm_os_offer" {
  description = "The name of the offer of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = ""
}

variable "vm_os_sku" {
  description = "The sku of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = ""
}

variable "vm_os_version" {
  description = "The version of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "latest"
}

variable "public_ip_address_allocation" {
  description = "This attribute is deprecated, and to be replaced by 'allocation_method'"
  default     = "Dynamic"
}

variable "allocation_method" {
  description = "Defines how an IP address is assigned. Options are Static or Dynamic."
  default     = "Dynamic"
}

variable "nb_public_ip" {
  description = "Number of public IPs to assign corresponding to one IP per vm. Set to 0 to not assign any public IP addresses."
  default     = "1"
}

variable "delete_os_disk_on_termination" {
  type        = bool
  description = "Delete datadisk when machine is terminated"
  default     = false
}

variable "data_sa_type" {
  description = "Data Disk Storage Account type"
  default     = "Standard_LRS"
}

variable "data_disk_size_gb" {
  description = "Storage data disk size size"
  default     = ""
}

variable "data_disk" {
  type        = bool
  description = "Set to true to add a datadisk."
  default     = false
}

variable "boot_diagnostics" {
  type        = bool
  description = "(Optional) Enable or Disable boot diagnostics"
  default     = false
}

variable "boot_diagnostics_sa_type" {
  description = "(Optional) Storage account type for boot diagnostics"
  default     = "Standard_LRS"
}

variable "enable_accelerated_networking" {
  type        = bool
  description = "(Optional) Enable accelerated networking on Network interface"
  default     = false
}

variable "domain_name_label" {
  description = "(Optional) an optional DNS name for the public ip"
  type        = string
  default     = ""
}

variable "domain_name_labels" {
  description = "(Optional) an optional list of DNS names for the public ip"
  type        = list
  default     = []
}
