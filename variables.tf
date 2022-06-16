variable "resource_group_name_prefix" {
  default       = "rg"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default = "eastus"
  description   = "Location of the resource group."
}

variable "vmcount" {
  type = number
  default = 3  
}

variable "AllowedIPforRemoteSSH" {
  type = string
  default = "84.228.18.103"
}