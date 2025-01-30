resource "azurerm_route_table" "default" {
  count = var.rt_default_virtual_appliance_ip_address != null ? 1 : 0

  name                = module.azure_resource_prefixes.route_table_prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  route {
    name                   = "${module.azure_resource_prefixes.prefix}-route-default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.rt_default_virtual_appliance_ip_address
  }

  tags = local.tags
}

###########
### NSG ###
###########

resource "azurerm_network_security_group" "this" {
  name                = "${module.azure_resource_prefixes.network_security_group_prefix}-route-reflector"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  dynamic "security_rule" {
    for_each = { for index, value in local.node_pool_subnet_address_prefixes : index => value }
    content {
      name      = "allow-bgp-${security_rule.value.name}-${security_rule.value.subnet_name}-inbound"
      priority  = 100 + security_rule.key
      direction = "Inbound"
      access    = "Allow"
      protocol  = "Tcp"

      source_port_range      = "*"
      destination_port_range = "179"

      source_address_prefixes      = security_rule.value.subnet_address_prefixes
      destination_address_prefixes = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
    }
  }

  dynamic "security_rule" {
    for_each = { for index, value in var.vnet_config.subnets.route_reflector.nsg_cluster_bgp_allowed_rules : index => value }
    content {
      name      = "allow-bgp-${security_rule.value.name}-route-server-outbound"
      priority  = 100 + security_rule.key
      direction = "Outbound"
      access    = "Allow"
      protocol  = "Tcp"

      source_port_range      = "*"
      destination_port_range = "179"

      source_address_prefixes      = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
      destination_address_prefixes = security_rule.value.route_server_ip_addresses
    }
  }

  security_rule {
    name      = "allow-internal-boundary-route-server-outbound"
    priority  = 100 + length(var.vnet_config.subnets.route_reflector.nsg_cluster_bgp_allowed_rules) + 1
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "179"

    source_address_prefixes      = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
    destination_address_prefixes = var.internal_address_prefixes.internal_boundary_route_servers
  }

  security_rule {
    name      = "allow-management-ingress-outbound"
    priority  = 100 + length(var.vnet_config.subnets.route_reflector.nsg_cluster_bgp_allowed_rules) + 2
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "443"

    source_address_prefixes      = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
    destination_address_prefixes = var.internal_address_prefixes.management_ingress
  }

  security_rule {
    name      = "allow-azureresourcemanager-servicetag-outbound"
    priority  = 100 + length(var.vnet_config.subnets.route_reflector.nsg_cluster_bgp_allowed_rules) + 3
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "443"

    source_address_prefixes    = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
    destination_address_prefix = "AzureResourceManager"
  }

  security_rule {
    name      = "allow-bgp-this-subnet-outbound"
    priority  = 100 + length(var.vnet_config.subnets.route_reflector.nsg_cluster_bgp_allowed_rules) + 4
    direction = "Outbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "179"

    source_address_prefixes      = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
    destination_address_prefixes = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
  }

  security_rule {
    name      = "allow-workstationscc-operator-subnet-inbound"
    priority  = 100 + length(local.node_pool_subnet_address_prefixes) + 1
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "22"

    source_address_prefixes      = var.internal_address_prefixes.workstations_operator_subnet
    destination_address_prefixes = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
  }

  security_rule {
    name      = "allow-mazcc-container-subnet-inbound"
    priority  = 100 + length(local.node_pool_subnet_address_prefixes) + 2
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "443"

    source_address_prefixes      = var.internal_address_prefixes.mazcc_container_subnet
    destination_address_prefixes = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
  }

  security_rule {
    name      = "allow-bgp-this-subnet-inbound"
    priority  = 100 + length(local.node_pool_subnet_address_prefixes) + 3
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "179"

    source_address_prefixes      = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
    destination_address_prefixes = module.virtual_network.vnet_subnets["route-reflector"].address_prefixes
  }

  security_rule {
    name      = "deny-vnet-inbound"
    priority  = 4096
    direction = "Inbound"
    access    = "Deny"
    protocol  = "*"

    source_port_range      = "*"
    destination_port_range = "*"

    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name      = "deny-vnet-outbound"
    priority  = 4096
    direction = "Outbound"
    access    = "Deny"
    protocol  = "*"

    source_port_range      = "*"
    destination_port_range = "*"

    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = local.tags
}
