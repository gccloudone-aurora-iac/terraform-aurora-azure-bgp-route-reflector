resource "azurerm_resource_group" "this" {
  name     = module.azure_resource_names.resource_group_name
  location = var.azure_resource_attributes.location

  tags = local.tags
}

module "virtual_network" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network.git?ref=v2.0.0"
  count  = var.vnet_config == null ? 0 : 1

  azure_resource_attributes = var.azure_resource_attributes

  naming_convention = var.naming_convention
  user_defined      = var.user_defined

  resource_group_name = azurerm_resource_group.this.name

  address_space           = var.vnet_config.address_space
  vnet_peers              = var.vnet_config.vnet_peers
  dns_servers             = var.vnet_config.dns_servers
  ddos_protection_plan_id = var.vnet_config.ddos_protection_plan_id

  subnets = [
    {
      name             = local.route_reflector_subnet_name
      address_prefixes = var.vnet_config.subnets.route_reflector.subnet_address_prefixes
    }
  ]

  subnet_route_tables = var.rt_default_virtual_appliance_ip_address != null ? [
    {
      subnet_name    = local.route_reflector_subnet_name
      route_table_id = azurerm_route_table.default[0].id
    }
  ] : []

  subnet_nsgs = var.vnet_config != null ? [
    {
      subnet_name = local.route_reflector_subnet_name
      nsg_id      = azurerm_network_security_group.this[0].id
    }
  ] : []

  tags = local.tags
}

##########################
### Route Reflector VM ###
##########################

resource "tls_private_key" "ssh" {
  count = var.ssh.public_key == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "this" {
  count = var.vm_instances

  name                = "${module.azure_resource_names.network_interface_card_name}-route-reflector-${count.index}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Static"
    subnet_id                     = var.subnet_id
    private_ip_address            = var.private_ip_addresses[count.index % var.vm_instances]
  }

  tags = local.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.vm_instances

  name                = "${module.azure_resource_names.virtual_machine_name}-route-reflector-${count.index}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  size = var.vm_size

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  network_interface_ids = [azurerm_network_interface.this[count.index].id]

  admin_username = var.ssh.username
  admin_ssh_key {
    username   = var.ssh.username
    public_key = trimspace(coalesce(var.ssh.public_key, try(tls_private_key.ssh.0.public_key_openssh, null)))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  zone = (count.index % local.total_availability_zones_in_region) + 1

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags["DoNotShutDownDays"]
    ]
  }
}

############
### RBAC ###
############

resource "azurerm_user_assigned_identity" "vm" {
  name                = "${module.azure_resource_names.managed_identity_name}-route-reflector"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = local.tags
}

# resource "azurerm_role_assignment" "vm_managed_identity_aurora_network_reader" {
#   count = length(var.bird_bgp_config.values.subscription_ids)

#   role_definition_name = "Aurora Network Reader"
#   principal_id         = azurerm_user_assigned_identity.vm.principal_id
#   # Must use a `Subscription Azure Resource ID` instead of simple subscription ID
#   scope = "/subscriptions/${var.bird_bgp_config.values.subscription_ids[count.index]}"
# }

####################################
### Route Reflector VM Extension ###
####################################

# resource "azurerm_virtual_machine_extension" "bgp_route_reflector_setup" {
#   count = var.vm_instances

#   name                 = "bgp_route_reflector_setup"
#   virtual_machine_id   = azurerm_linux_virtual_machine.this[count.index].id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.1"
#   protected_settings = jsonencode({
#     "script" = base64encode(templatefile("${path.module}/config/rr-vm-extension.tftpl", {
#       daemon_config     = local.daemon_config[count.index]
#       apt_auth_config   = local.apt_auth_config
#       apt_preferences   = local.apt_preferences_config
#       package_name      = var.apt_repository.package_name
#       package_version   = var.apt_repository.package_version
#       local_bird_config = var.local_bird_config
#     }))
#   })

#   tags = local.tags
# }
