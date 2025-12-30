variable "location" {}
variable "prefix" {} 
variable "resource_group_name" {} 
variable "base_tags" {} 
#variable "allow_groups" {}
#variable "nsg_rules" {}

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
    priority         = number
    direction        = string
    access           = string
    protocol         = string
    destination_port = number
    source_cidrs     = list(string)
    allow_groups     = optional(list(string), [])
  }))

  # rule-level CIDRs must be valid
  validation {
    condition = alltrue([
      for name, rule in var.nsg_rules :
      alltrue([for c in rule.source_cidrs : can(cidrnetmask(trimspace(c)))])
    ])
    error_message = "One or more NSG rules contain an invalid CIDR in source_cidrs."
  }

  # ports must be sensible
  validation {
    condition = alltrue([
      for name, rule in var.nsg_rules :
      rule.destination_port >= 1 && rule.destination_port <= 65535
    ])
    error_message = "All NSG rules must have a destination_port between 1 and 65535."
  }

  # priorities must be in Azure's range
  validation {
    condition = alltrue([
      for name, rule in var.nsg_rules :
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "All NSG rules must have a priority between 100 and 4096."
  }
}