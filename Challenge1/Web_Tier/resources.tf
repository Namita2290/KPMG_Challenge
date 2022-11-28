#resource group for web tier resources
resource "azurerm_resource_group" "web_tier_rg" {

    name = "${var.resources_prefix}_web_tier_rg"
    location = var.location
    tags = var.default_resources_tags
}

#virtual network for web tier
resource "azurerm_virtual_network" "web_tier_vnet" {
  name = "${var.resources_prefix}_web_tier_vnet"
  address_space = [ "10.0.0.0/16" ]
  location = var.location
  resource_group_name = azurerm_resource_group.web_tier_rg.name
  tags = var.default_resources_tags
}

#subnet for web tier
resource "azurerm_subnet" "web_tier_subnet" {
 name                 = "${var.resources_prefix}_web_tier_subnet"
 resource_group_name  = azurerm_resource_group.web_tier_rg.name
 virtual_network_name = azurerm_virtual_network.web_tier_vnet.name
 address_prefixes       = ["10.0.1.0/24"]
}

#network security group for web tier resources
resource "azurerm_network_security_group" "web_tier_nsg" {
  name                = "${var.resources_prefix}_web_tier_nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.web_tier_rg.name
}

#allow http traffic on port 80 to web tier nsg
resource "azurerm_network_security_rule" "web_tier_http_rule" {
  
    name                       = "web-tier-HTTP-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.web_tier_rg.name
    network_security_group_name = azurerm_network_security_group.web_tier_nsg.name
  
}

#allow https traffic on port 443 to web tier nsg
resource "azurerm_network_security_rule" "web_tier_https_rule" {
  
    name                       = "web-tier-HTTPS-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.web_tier_rg.name
    network_security_group_name = azurerm_network_security_group.web_tier_nsg.name
  
}

#allow load balancer probe to web tier nsg
resource "azurerm_network_security_rule" "web_tier_lb_probe_rule" {
  
    name                       = "web-tier-allow-lb-probe"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "LoadBalancer"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.web_tier_rg.name
    network_security_group_name = azurerm_network_security_group.web_tier_nsg.name
  
}

#block all traffic from other resources in the same vnet
resource "azurerm_network_security_rule" "web_tier_block_vnet_rule" {
  
    name                       = "web-tier-allow-lb-probe"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.web_tier_rg.name
    network_security_group_name = azurerm_network_security_group.web_tier_nsg.name
  
}

#subnet and web tier nsg association
resource "azurerm_subnet_network_security_group_association" "web_tier_nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.web_tier_subnet.id
  network_security_group_id = azurerm_network_security_group.web_tier_nsg.id
}

#create public ip for oublic facing load balancer
resource "azurerm_public_ip" "lb_pip_web_tier" {
 name                         = "${var.resources_prefix}_lb_public_ip"
 location                     = var.location
 resource_group_name          = azurerm_resource_group.web_tier_rg.name
 allocation_method            = "Static"
 domain_name_label            = var.resources_prefix
 tags                         = var.default_resources_tags
}

#web tier load balancer
resource "azurerm_lb" "web_tier_lb" {
 name                = "${var.resources_prefix}_web_tier_lb"
 location            = var.location
 resource_group_name = azurerm_resource_group.web_tier_rg.name

 frontend_ip_configuration {
   name                 = "web_tier_PublicIPAddress"
   public_ip_address_id = azurerm_public_ip.lb_pip_web_tier.id
 }

 tags = var.default_resources_tags
}

#web tier load balancer backend pool
resource "azurerm_lb_backend_address_pool" "web_tier_bapool" {
 loadbalancer_id     = azurerm_lb.web_tier_lb.id
 name                = "Web_Tier_BackEndAddressPool"
}

#web tier load balancer probe
resource "azurerm_lb_probe" "web_tier_lb_probe" {
 resource_group_name = azurerm_resource_group.web_tier_rg.name
 loadbalancer_id     = azurerm_lb.web_tier_lb.id
 name                = "ssh-check-probe"
 port                = "22"
}

#web tier load balancer nat rule
resource "azurerm_lb_rule" "web_tier_lbnatrule" {
   resource_group_name            = azurerm_resource_group.web_tier_rg.name
   loadbalancer_id                = azurerm_lb.web_tier_lb.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = "80"
   backend_port                   = "80"
   backend_address_pool_id        = azurerm_lb_backend_address_pool.web_tier_bapool.id
   frontend_ip_configuration_name = "web_tier_PublicIPAddress"
   probe_id                       = azurerm_lb_probe.web_tier_lb_probe.id
}

#web tier vm's created in a scale set
resource "azurerm_linux_virtual_machine_scale_set" "web_tier_vm_scaleset" {

    name = "${var.resources_prefix}_web_tier_scaleset"
    location = var.location
    resource_group_name = azurerm_resource_group.web_tier_rg.name
    sku = "Standard_F2"
    instances = 2

    admin_username = "adminuser"

    admin_ssh_key {
        username   = "adminuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    network_interface {
        name    = "${var.resources_prefix}_web_tier_nic"
        primary = true

        ip_configuration {
            name      = "${var.resources_prefix}_internal_nic"
            primary   = true
            subnet_id = azurerm_subnet.web_tier_subnet.id
        }
    }
}