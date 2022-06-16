output "resource_group_name" {
    value = azurerm_resource_group.rg.name
}
output "public_ip_address" {
  value = azurerm_linux_virtual_machine.myvms.*.public_ip_address
}
output "LoadBalancer_frontend_config" {
  value = azurerm_lb.week5LB.frontend_ip_configuration
}
output "LoadBalancer_private_ips" {
  value = azurerm_lb.week5LB.private_ip_addresses
}
output "vm_password" {
    value = azurerm_linux_virtual_machine.myvms.*.admin_password
    sensitive = true
}