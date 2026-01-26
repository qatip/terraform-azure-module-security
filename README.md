# Security Module

## Purpose
This module provisions a Network Security Group (NSG) and optional security rules.
It is designed to be consumed by root modules and other modules via outputs.

## Module Contract

### Required Inputs (Root-to-Module Contract)
These values **must** be supplied by the root module.

| Variable               | Type        | Description                                      |
|------------------------|-------------|--------------------------------------------------|
| prefix                 | string      | Naming prefix applied to all resources           |
| location               | string      | Azure region for all resources                   |
| base_tags              | map(string) | Standardised tags applied to all resources       |
| resource_group_name    | string      | Target resource group name                       |

### Optional Inputs (Configuration)

| Variable   | Type        | Default | Description                                      |
|------------|-------------|---------|--------------------------------------------------|
| nsg_rules  | map(object) | {}      | Map of NSG rule definitions                      |

> ⚠️ **Important:** An empty `nsg_rules` map will result in an NSG with no rules.
This is acceptable for baseline deployments but should be constrained in production.

## Outputs

| Output Name | Description                           |
|------------|---------------------------------------|
| nsg_id     | The ID of the Network Security Group  |
| nsg_name   | The name of the Network Security Group|

## Consumption Pattern
Other modules must **not** reference this module directly.
The root module is responsible for:
1. Invoking this module
2. Consuming its outputs
3. Passing outputs into dependent modules

## Versioning
This module follows semantic versioning:
- Patch versions add outputs or defaults
- Minor versions extend rule capabilities
- Major versions may change rule structure or required inputs
