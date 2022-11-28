output "web_tier_lb_public_ip" {
  value = azurerm_public_ip.lb_pip_web_tier.ip_address
  description = "ip for the public load balancer"
}