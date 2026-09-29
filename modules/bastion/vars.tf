variable "bastions" {
  description = "Map of Azure Bastion hosts to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string
    public_ip_key      = string

    sku = optional(string, "Standard")

    copy_paste_enabled     = optional(bool, true)
    file_copy_enabled      = optional(bool, true)
    ip_connect_enabled     = optional(bool, true)
    shareable_link_enabled = optional(bool, false)
    tunneling_enabled      = optional(bool, true)
  }))

  validation {
    condition     = length(var.bastions) > 0
    error_message = "At least one Azure Bastion host must be defined."
  }

  validation {
    condition = alltrue([
      for bastion_key, bastion in var.bastions :
      bastion.sku == "Standard"
    ])

    error_message = "All Azure Bastion hosts must use the Standard SKU."
  }

  validation {
    condition = alltrue([
      for bastion_key, bastion in var.bastions :
      length(trimspace(bastion.name)) > 0
    ])

    error_message = "Each Bastion must define a non-empty name."
  }
}

variable "resource_groups" {
  description = "Resource Groups created by the Resource Group module."

  type = map(object({
    id       = string
    name     = string
    location = string
  }))

  validation {
    condition     = length(var.resource_groups) > 0
    error_message = "At least one Resource Group must be available to the Bastion module."
  }
}

variable "subnets" {
  description = "Subnets created by the Subnet module."

  type = map(object({
    id               = string
    name             = string
    address_prefixes = list(string)
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be available to the Bastion module."
  }
}

variable "public_ips" {
  description = "Public IPs created by the Public IP module."

  type = map(object({
    id                  = string
    name                = string
    ip_address          = string
    resource_group_name = string
    location            = string
    sku                 = string
    allocation_method   = string
  }))

  validation {
    condition     = length(var.public_ips) > 0
    error_message = "At least one Public IP must be available to the Bastion module."
  }
}

variable "tags" {
  description = "Common tags applied to Azure Bastion."

  type    = map(string)
  default = {}
}