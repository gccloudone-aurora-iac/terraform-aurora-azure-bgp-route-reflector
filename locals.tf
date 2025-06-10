locals {
  route_reflector_subnet_name = "route-reflector"

  // The number of availability zones in Canada Central
  total_availability_zones_in_region = 1

  node_pool_subnet_address_prefixes = var.vnet_config != null ? flatten([
    for index, rules in var.vnet_config.subnets.route_reflector.nsg_cluster_bgp_allowed_rules : [
      for subnet_name, address_prefixes in rules.node_pool_subnet_address_prefixes : {
        name                    = rules.name
        subnet_name             = subnet_name
        subnet_address_prefixes = address_prefixes
      }
    ]
  ]) : []
}

// Configuration for VM extension
locals {
  # daemon_config = [for private_ip_address in var.private_ip_addresses :
  #   {
  #     path = var.bird_bgp_config.path
  #     authentication = templatefile("${path.module}/config/bird/authentication.env.tftpl", {
  #       tenant_id = azurerm_user_assigned_identity.vm.tenant_id
  #       client_id = azurerm_user_assigned_identity.vm.client_id
  #     })
  #     value = templatefile("${path.module}/config/bird/config.yml.tftpl", {
  #       subnet_patterns                 = jsonencode(var.bird_bgp_config.values.subnet_patterns)
  #       virtual_network_blocklist       = jsonencode(var.bird_bgp_config.values.virtual_network_blocklist)
  #       subscription_ids                = jsonencode(var.bird_bgp_config.values.subscription_ids)
  #       tickrate                        = var.bird_bgp_config.values.tickrate
  #       bgp_community_tag_start         = var.bird_bgp_config.values.bgp_community_tag_start
  #       cluster_import_allowed_networks = jsonencode(var.bird_bgp_config.values.cluster_import_allowed_networks)
  #       local_asn                       = var.bird_bgp_config.values.static_config.local_asn
  #       static_bird_config = yamlencode({
  #         staticBirdConfig = {
  #           birdLocalASN = var.bird_bgp_config.values.static_config.local_asn
  #           staticBGPPeerings = concat(
  #             [
  #               for peering in var.bird_bgp_config.values.static_config.bgp_peerings :
  #               {
  #                 name              = peering.name
  #                 asn               = peering.asn
  #                 peerAddress       = peering.peer_address
  #                 importRoutes      = peering.import_routes
  #                 exportNoAdvertise = peering.export_no_advertise
  #                 exportedNetworks  = peering.exported_networks
  #               }
  #             ],
  #             [
  #               for vm_peer_ip in setsubtract(var.private_ip_addresses, [private_ip_address]) :
  #               {
  #                 name              = azurerm_linux_virtual_machine.this[index(var.private_ip_addresses, vm_peer_ip)].name
  #                 asn               = var.bird_bgp_config.values.static_config.local_asn
  #                 peerAddress       = vm_peer_ip
  #                 importRoutes      = true
  #                 exportNoAdvertise = false
  #                 exportedNetworks  = var.bird_bgp_config.values.cluster_import_allowed_networks
  #               }
  #           ])
  #         }
  #       })
  #     })
  # }]

  # APT configuration files
  # apt_auth_config = templatefile("${path.module}/config/apt/auth.conf.d/artifactory.conf.tftpl", {
  #   artifactory = var.apt_repository.credentials
  # })
  # apt_preferences_config = file("${path.module}/config/apt/preferences.d/95artifactory")

  tags = merge(
    var.tags,
    {
      ModuleName    = "terraform-aurora-azure-bgp-route-reflector",
      ModuleVersion = "v1.0.0",
    }
  )
}
