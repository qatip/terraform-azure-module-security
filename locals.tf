locals {

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

      destination_ports = sort(distinct(compact([
        for p in try(rule.destination_ports, []) : (
          length(regexall("[^0-9 -]", trim(p, " -"))) == 0 ? (
            length(regexall("[0-9]+", trim(p, " -"))) == 1 ?
            regexall("[0-9]+", trim(p, " -"))[0] :
            length(regexall("[0-9]+", trim(p, " -"))) == 2 ?
            "${min(
              tonumber(regexall("[0-9]+", trim(p, " -"))[0]),
              tonumber(regexall("[0-9]+", trim(p, " -"))[1])
              )}-${max(
              tonumber(regexall("[0-9]+", trim(p, " -"))[0]),
              tonumber(regexall("[0-9]+", trim(p, " -"))[1])
            )}" :
            ""
          ) : ""
        )
      ])))

      destination_ports_dropped = [
        for p in try(rule.destination_ports, []) : p
        if(
          length(trim(p, " -")) > 0 &&
          (
            length(regexall("[^0-9 -]", trim(p, " -"))) > 0 ||
            length(regexall("[0-9]+", trim(p, " -"))) == 0 ||
            length(regexall("[0-9]+", trim(p, " -"))) > 2
          )
        )
      ]
    }
  }

  mod_tags = merge(
    var.base_tags,
   {
     manager = "Peter Smith (SecMod v1.0.1)"
   }
  )

}
