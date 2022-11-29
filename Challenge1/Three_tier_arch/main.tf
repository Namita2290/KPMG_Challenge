#invoking web tier module
module "web-tier-module" {
    source = "../web-tier"
    resources_prefix = var.resources_prefix
    location = var.location
    default_resources_tags = var.default_resources_tags
}

#invoking App tier module
module "app-tier-module" {
    source = "../app-tier"
    resources_prefix = var.resources_prefix
    location = var.location
    default_resources_tags = var.default_resources_tags
}

#invoking data tier module
module "data-tier-module" {
    source = "../data-tier"
    resources_prefix = var.resources_prefix
    location = var.location
    default_resources_tags = var.default_resources_tags
}
