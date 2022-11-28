variable "resources_prefix" {
    description = "name to uniquely identify all resources"
    type=string
}

variable "location" {
  
  description = "location where resources will be deployed"
  type=string
  default = "East US"
}

variable "default_resources_tags" {
  
  type = map
  description = "default tags for all resources"
}