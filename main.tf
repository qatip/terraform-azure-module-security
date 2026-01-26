resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.mod_tags
}

resource "azurerm_network_security_rule" "rule" {
  for_each = local.nsg_rules_normalised

  name                    = each.key
  priority                = each.value.priority
  direction               = title(each.value.direction)
  access                  = title(each.value.access)
  protocol                = title(each.value.protocol)
  source_port_range       = "*"
  destination_port_ranges = each.value.destination_ports

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
      error_message = "Rule '${each.key}' contains source CIDR (0.0.0.0/0)."
    }

    precondition {
      condition     = length(each.value.destination_ports) > 0
      error_message = "Rule '${each.key}' has no destination ports after sanitisation."
    }

    precondition {
      condition = alltrue([
        for p in each.value.destination_ports :
        alltrue([
          for n in regexall("[0-9]+", p) :
          tonumber(n) >= 1 && tonumber(n) <= 65535
        ])
      ])
      error_message = "Rule '${each.key}' contains destination ports outside the valid range (1–65535)."
    }
  }
}