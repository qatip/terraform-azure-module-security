locals {

  mod_tags = merge(
  var.base_tags,
  {
    manager = "Peter Smith"
  }
  )

  allow_groups_clean = {
    for name, cidrs in var.allow_groups :
    lower(trimspace(name)) => distinct([
      for c in cidrs : trimspace(c)
    ])
  }

  nsg_rules_clean = {
    for k, v in var.nsg_rules :
    replace(
      replace(
        replace(lower(trimspace(k)), " ", "-"),
        "_", "-"
      ),
      ".", "-"
    ) => v
  }

  nsg_rules_normalised = {
    for name, rule in local.nsg_rules_clean :
    name => {
      priority  = rule.priority
      direction = lower(rule.direction)
      access    = lower(rule.access)
      protocol  = lower(rule.protocol)

      allow_groups = [
        for g in try(rule.allow_groups, []) :
        lower(trimspace(g))
      ]

      source_cidrs = distinct([
        for c in rule.source_cidrs : trimspace(c)
      ])

      destination_port = rule.destination_port
    }
  }
}
