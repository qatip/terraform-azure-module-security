output "nsg_id" {
  value       = azurerm_network_security_group.nsg.id
}

output "module-tags" {
 value = local.mod_tags
 description = "Module tags (teaching aid)."
}
