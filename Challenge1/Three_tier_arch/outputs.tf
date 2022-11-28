output "public_load_balancer_ipaddress" {
  value = module.web-tier-module.web_tier_lb_public_ip
  description = "Returns the IP for public load balancer"
}