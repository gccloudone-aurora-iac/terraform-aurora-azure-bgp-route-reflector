data "azurerm_shared_image" "aurora_ubuntu2204_server_gen2" {
  name                = "aurora-ubuntu2204-server-gen2"
  gallery_name        = "auroralinuxgallery"
  resource_group_name = "hostingops-linux-management-rg"

  provider = azurerm.management
}
