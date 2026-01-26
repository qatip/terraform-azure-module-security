variable "location" {}
variable "prefix" {} 
variable "resource_group_name" {} 
variable "base_tags" {} 

variable "allow_groups" {
  description = "Named CIDR allow-lists that NSG rules can reference."
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue([
      for name, cidrs in var.allow_groups :
      alltrue([for c in cidrs : can(cidrnetmask(trimspace(c)))])
    ])
    error_message = "All entries in allow_groups must be valid CIDR blocks."
  }
}

variable "nsg_rules" {
  description = "Map of NSG rules to create."
  type = map(object({
    priority          = number
    direction         = string
    access            = string
    protocol          = string
    destination_ports = list(string)
    source_cidrs      = list(string)
    allow_groups      = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for name, rule in var.nsg_rules :
      alltrue([for c in rule.source_cidrs : can(cidrnetmask(trimspace(c)))])
    ])
    error_message = "One or more NSG rules contain an invalid CIDR in source_cidrs."
  }

  validation {
    condition = alltrue([
      for name, rule in var.nsg_rules :
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "All NSG rules must have a priority between 100 and 4096."
  }

  validation {
    condition = alltrue([
      for _, rule in var.nsg_rules : alltrue([
        for g in rule.allow_groups :
        contains(
          [for k in keys(var.allow_groups) : lower(trimspace(k))],
          lower(trimspace(g))
        )
      ])
    ])
    error_message = "Each nsg_rules[*].allow_groups entry must match a key in var.allow_groups (comparison is trim+lowercase)."
  }

  validation {
    condition = alltrue([
      for d in distinct([
        for r in values(var.nsg_rules) : lower(trimspace(r.direction))
      ]) :
      length([
        for r in values(var.nsg_rules) :
        r.priority
        if lower(trimspace(r.direction)) == d
      ]) == length(distinct([
        for r in values(var.nsg_rules) :
        r.priority
        if lower(trimspace(r.direction)) == d
      ]))
    ])
    error_message = "NSG rule priorities must be unique per direction (e.g., unique within Inbound and within Outbound)."
  }

}
