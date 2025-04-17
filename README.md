# terraform-aurora-azure-bgp-route-reflector

## Usage

Examples for this module along with various configurations can be found in the [examples/](examples/) folder.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.26.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.70.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_resource_names"></a> [azure\_resource\_names](#module\_azure\_resource\_names) | git::https://github.com/gccloudone-aurora-iac/terraform-aurora-azure-resource-names.git | v2.0.0 |
| <a name="module_virtual_network"></a> [virtual\_network](#module\_virtual\_network) | git::https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network.git | v2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apt_repository"></a> [apt\_repository](#input\_apt\_repository) | The information required to pull the 'bird-bgp-daemon' package from the APT repository. | <pre>object({<br>    package_name    = optional(string, "bird-bgp-daemon")<br>    package_version = optional(string, "")<br><br>    credentials = object({<br>      username = string<br>      password = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_azure_resource_attributes"></a> [azure\_resource\_attributes](#input\_azure\_resource\_attributes) | Attributes used to describe Azure resources | <pre>object({<br>    project     = string<br>    environment = string<br>    location    = optional(string, "Canada Central")<br>    instance    = number<br>  })</pre> | n/a | yes |
| <a name="input_bird_bgp_config"></a> [bird\_bgp\_config](#input\_bird\_bgp\_config) | Some of the values required to create the bird-bgp daemon configuration file. | <pre>object({<br>    path = optional(string, "/bgp/config.yml")<br>    values = object({<br>      subnet_patterns                 = list(string)<br>      virtual_network_blocklist       = optional(list(string), [])<br>      subscription_ids                = list(string)<br>      tickrate                        = optional(string, "5m")<br>      bgp_community_tag_start         = optional(number, 100)<br>      cluster_import_allowed_networks = optional(list(string), [])<br>      static_config = object({<br>        local_asn = optional(number, 64512)<br>        bgp_peerings = optional(list(object({<br>          name                = string<br>          asn                 = number<br>          peer_address        = string<br>          import_routes       = optional(bool, false)<br>          export_no_advertise = optional(bool, true)<br>          exported_networks   = optional(list(string), [])<br>        })), [])<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_internal_address_prefixes"></a> [internal\_address\_prefixes](#input\_internal\_address\_prefixes) | The internal address prefixes to use within the NSG rules. | <pre>object({<br>    mazcc_container_subnet          = list(string)<br>    workstations_operator_subnet    = list(string)<br>    management_ingress              = list(string)<br>    internal_boundary_route_servers = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_private_ip_addresses"></a> [private\_ip\_addresses](#input\_private\_ip\_addresses) | The private IP addresses the Route Reflector VMs shoudl have. | `list(string)` | n/a | yes |
| <a name="input_vnet_config"></a> [vnet\_config](#input\_vnet\_config) | The virtual network configuration for the Route Reflector VNet. | <pre>object({<br>    address_space           = list(string)<br>    vnet_peers              = optional(list(string))<br>    dns_servers             = optional(list(string))<br>    ddos_protection_plan_id = optional(string)<br><br>    subnets = object({<br>      route_reflector = object({<br>        subnet_address_prefixes = list(string)<br>        nsg_cluster_bgp_allowed_rules = list(object({<br>          name                              = string<br>          route_server_ip_addresses         = list(string)<br>          node_pool_subnet_address_prefixes = map(list(string))<br>        }))<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_rt_default_virtual_appliance_ip_address"></a> [rt\_default\_virtual\_appliance\_ip\_address](#input\_rt\_default\_virtual\_appliance\_ip\_address) | The default route applied on the subnet user-defined route table. | `string` | `null` | no |
| <a name="input_ssh"></a> [ssh](#input\_ssh) | The admin SSH key for the Route Reflector VMs. | <pre>object({<br>    username   = optional(string, "auradmin")<br>    public_key = string<br>  })</pre> | <pre>{<br>  "public_key": null,<br>  "username": "auradmin"<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for use on Azure resources. | `map(string)` | `{}` | no |
| <a name="input_vm_instances"></a> [vm\_instances](#input\_vm\_instances) | The number of Route Reflector VMs to create. | `number` | `3` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | The size of the Route Reflector VMs | `string` | `"Standard_D2_v5"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azurerm_network_security_group"></a> [azurerm\_network\_security\_group](#output\_azurerm\_network\_security\_group) | n/a |
| <a name="output_route_reflector_network_interfaces"></a> [route\_reflector\_network\_interfaces](#output\_route\_reflector\_network\_interfaces) | n/a |
| <a name="output_route_reflector_vm_user_assigned_managed_identity"></a> [route\_reflector\_vm\_user\_assigned\_managed\_identity](#output\_route\_reflector\_vm\_user\_assigned\_managed\_identity) | n/a |
| <a name="output_route_reflector_vms"></a> [route\_reflector\_vms](#output\_route\_reflector\_vms) | n/a |
| <a name="output_route_table"></a> [route\_table](#output\_route\_table) | n/a |
| <a name="output_virtual_network"></a> [virtual\_network](#output\_virtual\_network) | n/a |
<!-- END_TF_DOCS -->

## History

| Date       | Release | Change                                                                                                                                                                                   |
| ---------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2025-01-25 | v1.0.0  | Initial commit                                                                                                                                                                           |
