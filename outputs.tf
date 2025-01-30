##########################
### Virtual Network    ###
##########################

output "virtual_network" {
  value = module.virtual_network
}

output "route_table" {
  value = var.rt_default_virtual_appliance_ip_address != null ? azurerm_route_table.default : null
}

output "azurerm_network_security_group" {
  value = azurerm_network_security_group.this
}

##########################
### Route Reflector VM ###
##########################

output "route_reflector_network_interfaces" {
  value = { for index, value in range(var.vm_instances) : index => azurerm_network_interface.this[value] }
}

output "route_reflector_vms" {
  value = { for index, value in range(var.vm_instances) : index => azurerm_linux_virtual_machine.this[value] }
}

output "route_reflector_vm_user_assigned_managed_identity" {
  value = azurerm_user_assigned_identity.vm
}
