variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity-1st-azure-devops-project"
}

variable "location" {
  type = string
  description = "The Azure Region in which all resources in this example should be created"
  default = "East US"
}

variable "resource_group" {
  description = "Name of resource group"
  default = "Udacity"
}

variable "tags" {
  description = "The default tags used for the all resources"
  default = {
    "udacity" = "udacity-1st-azure-devops-project"
  }
}

variable "vm-size" {
  type        = string
  description = "VM Size"
  default     = "Standard_D2s_v3"
}

# VM Admin User
variable "vm-admin-username" {
  type        = string
  description = "VM admin User"
  default     = "udacity-admin"
}

# VM Admin Password
variable "vm-admin-password" {
  type        = string
  description = "VM admin Password"
  default     = "UdacityProject1"
}

variable "packer_resource_group" {
  description = "Name of the resource group where the packer image is"
  default     = "Udacity"
  type        = string
}

variable "vm_count" {
  description = "Number of VM resources to create behind the load balancer"
  default     = 2
  type        = number
}

variable "server_name" {
  type = list
  default = ["servera", "serverb"]
}

variable "vm_type_tag" {
  default = "az_linux_vm"
}

variable "network_type_tag" {
  default = "az_network_interface"
}

variable "network_security_group_tag" {
  default = "az_network_security_group"
}

variable "azurerm_lb_tag" {
  default = "az_load_balancer"
}

variable "azurerm_availability_set_tag" {
  default = "az_availability_set"
}

variable "packer_name" {
  default = "packerImage"
}

variable "resource_contain_packer_image" {
  default = "Udacity"
}