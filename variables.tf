variable "azure_resource_attributes" {
  description = "Attributes used to describe Azure resources"
  type = object({
    project     = string
    environment = string
    location    = optional(string, "Canada Central")
    instance    = number
  })
  nullable = false
}

variable "tags" {
  description = "Tags for use on Azure resources."
  type        = map(string)
  default     = {}
}

#######################
### Virtual Network ###
#######################

variable "vnet_config" {
  description = "The virtual network configuration for the Route Reflector VNet."
  type = object({
    address_space           = list(string)
    vnet_peers              = optional(list(string))
    dns_servers             = optional(list(string))
    ddos_protection_plan_id = optional(string)

    subnets = object({
      route_reflector = object({
        subnet_address_prefixes = list(string)
        nsg_cluster_bgp_allowed_rules = list(object({
          name                              = string
          route_server_ip_addresses         = list(string)
          node_pool_subnet_address_prefixes = map(list(string))
        }))
      })
    })
  })
}

variable "internal_address_prefixes" {
  description = "The internal address prefixes to use within the NSG rules."
  type = object({
    mazcc_container_subnet          = list(string)
    workstations_operator_subnet    = list(string)
    management_ingress              = list(string)
    internal_boundary_route_servers = list(string)
  })
}

variable "rt_default_virtual_appliance_ip_address" {
  description = "The default route applied on the subnet user-defined route table."
  type        = string
  default     = null
}

##########################
### Route Reflector VM ###
##########################

variable "vm_size" {
  description = "The size of the Route Reflector VMs"
  type        = string
  default     = "Standard_D2_v5"
}

variable "vm_instances" {
  description = "The number of Route Reflector VMs to create."
  type        = number
  default     = 3
}

variable "ssh" {
  description = "The admin SSH key for the Route Reflector VMs."
  type = object({
    username   = optional(string, "auradmin")
    public_key = string
  })
  sensitive = true
  default = {
    username   = "auradmin"
    public_key = null
  }
}

variable "private_ip_addresses" {
  description = "The private IP addresses the Route Reflector VMs shoudl have."
  type        = list(string)
}

variable "bird_bgp_config" {
  description = "Some of the values required to create the bird-bgp daemon configuration file."
  type = object({
    path = optional(string, "/bgp/config.yml")
    values = object({
      subnet_patterns                 = list(string)
      virtual_network_blocklist       = optional(list(string), [])
      subscription_ids                = list(string)
      tickrate                        = optional(string, "5m")
      bgp_community_tag_start         = optional(number, 100)
      cluster_import_allowed_networks = optional(list(string), [])
      static_config = object({
        local_asn = optional(number, 64512)
        bgp_peerings = optional(list(object({
          name                = string
          asn                 = number
          peer_address        = string
          import_routes       = optional(bool, false)
          export_no_advertise = optional(bool, true)
          exported_networks   = optional(list(string), [])
        })), [])
      })
    })
  })
}

variable "apt_repository" {
  description = "The information required to pull the 'bird-bgp-daemon' package from the APT repository."
  type = object({
    package_name    = optional(string, "bird-bgp-daemon")
    package_version = optional(string, "")

    credentials = object({
      username = string
      password = string
    })
  })
  sensitive = true
}

variable "local_bird_config" {
  default = ""
}
