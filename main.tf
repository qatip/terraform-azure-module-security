resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.mod_tags
}

resource "azurerm_network_security_rule" "rule" {
  for_each = local.nsg_rules_normalised

  name                   = each.key
  priority               = each.value.priority
  direction              = title(each.value.direction)
  access                 = title(each.value.access)
  protocol               = title(each.value.protocol)
  source_port_range      = "*"
  destination_port_range = each.value.destination_port

  source_address_prefixes = distinct(flatten(concat(
    each.value.source_cidrs,
    [
      for g in each.value.allow_groups :
      lookup(local.allow_groups_clean, g, [])
    ]
  )))

  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name

  lifecycle {
    precondition {
      condition = alltrue([
        for c in distinct(flatten(concat(
          each.value.source_cidrs,
          [
            for g in each.value.allow_groups :
            lookup(local.allow_groups_clean, g, [])
          ]
        ))) : c != "0.0.0.0/0"
      ])
      error_message = "Rule '${each.key}' contains 0.0.0.0/0, which is not permitted."
    }
  }
}