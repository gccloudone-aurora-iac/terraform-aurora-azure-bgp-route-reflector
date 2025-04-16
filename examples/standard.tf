#####################
### Prerequisites ###
#####################

provider "azurerm" {
  features {}
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

##############
### Module ###
##############

module "bgp_route_reflector" {
  source = "../"

  naming_convention = "gc"
  user_defined      = "example"

  azure_resource_attributes = {
    department_code = "Gc"
    owner           = "ABC"
    project         = "aur"
    environment     = "dev"
    location        = "canadacentral"
    instance        = 0
  }

  source_image_id = ""

  # virtual network
  vnet_config = {
    address_space = ["10.0.0.0/16"]
    dns_servers   = ["10.0.0.0", "10.0.0.1"]

    subnets = {
      route_reflector = {
        subnet_address_prefixes = ["10.0.2.0/24"]
        nsg_cluster_bgp_allowed_rules = [{
          name                      = "dev"
          route_server_ip_addresses = ["10.0.0.1", "10.0.0.2"]
          node_pool_subnet_address_prefixes = {
            general = ["32.23.23.23"]
          }
        }]
      }
    }
  }

  internal_address_prefixes = {
    mazcc_container_subnet          = ["1.1.1.1"]
    workstations_operator_subnet    = ["1.1.1.1"]
    internal_boundary_route_servers = ["1.1.1.1", "1.1.1.2"]
    management_ingress              = ["1.1.1.1"]
  }

  # VMs
  vm_size              = "Standard_B1s"
  vm_instances         = 1
  private_ip_addresses = ["10.0.2.5", "10.0.2.6"]
  ssh = {
    public_key = tls_private_key.ssh.public_key_openssh
  }

  # VM extension
  bird_bgp_config = {
    path = "/bgp/config.yml"
    values = {
      subnet_patterns                 = ["general", "system"]
      subscription_ids                = ["test", "system"]
      tickrate                        = "5m"
      cluster_import_allowed_networks = ["2.2.2.2/32"]
      static_config = {
        local_asn = 64512
        bgp_peerings = [
          {
            name                = "route_server_a"
            asn                 = 65515
            peer_address        = "1.1.1.1"
            import_routes       = false
            export_no_advertise = true
            exported_networks   = ["2.2.2.2/32"]
          }
        ]
      }
    }
  }
  apt_repository = {
    credentials = {
      username = "username"
      password = "pass"
    }
  }
}

###############
### Outputs ###
###############

# virtual network

output "virtual_network" {
  value = module.bgp_route_reflector.virtual_network
}

output "route_table" {
  value = module.bgp_route_reflector.route_table
}

output "azurerm_network_security_group" {
  value = module.bgp_route_reflector.azurerm_network_security_group
}

# Route Reflector VM

output "route_reflector_vms" {
  value     = module.bgp_route_reflector.route_reflector_vms
  sensitive = true
}

output "route_reflector_network_interfaces" {
  value = module.bgp_route_reflector.route_reflector_network_interfaces
}
