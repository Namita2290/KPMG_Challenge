#resource groups for all App tier resources
resource "azurerm_resource_group" "app_tier_rg" {

    name = "${var.resources_prefix}_app_tier_rg"
    location = var.location
    tags = var.default_resources_tags
}
#vnet for all App tier resources
resource "azurerm_virtual_network" "app_tier_vnet" {
  name = "${var.resources_prefix}_app_tier_vnet"
  address_space = [ "10.0.0.0/16" ]
  location = var.location
  resource_group_name = azurerm_resource_group.app_tier_rg.name
  tags = var.default_resources_tags
}

#subnet for all App tier resources
resource "azurerm_subnet" "app_tier_subnet" {
 name                 = "${var.resources_prefix}_app_tier_subnet"
 resource_group_name  = azurerm_resource_group.app_tier_rg.name
 virtual_network_name = azurerm_virtual_network.app_tier_vnet.name
 address_prefixes       = ["10.0.2.0/24"]
}

#nsg for all App tier resources
resource "azurerm_network_security_group" "app_tier_nsg" {
  name                = "${var.resources_prefix}_app_tier_nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.app_tier_rg.name
}

#allow traffic on port 80 to public load balancer
resource "azurerm_network_security_rule" "app_tier_80_rule" {
  
    name                       = "app-tier-80-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.app_tier_rg.name
    network_security_group_name = azurerm_network_security_group.app_tier_nsg.name
  
}

#allow load balancer to perform health check
resource "azurerm_network_security_rule" "app_tier_lb_probe_rule" {
  
    name                       = "app-tier-HTTPS-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.app_tier_rg.name
    network_security_group_name = azurerm_network_security_group.app_tier_nsg.name
  
}

#block traffic to the business tier from other resoruces in vnet
resource "azurerm_network_security_rule" "app_tier_block_vnet_rule" {
  
    name                       = "app-tier-allow-lb-probe"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.app_tier_rg.name
    network_security_group_name = azurerm_network_security_group.app_tier_nsg.name
  
}

# association of nsg and subnet for business tier
resource "azurerm_subnet_network_security_group_association" "app_tier_nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.app_tier_subnet.id
  network_security_group_id = azurerm_network_security_group.app_tier_nsg.id
}

#App tier load balancer
resource "azurerm_lb" "app_tier_lb" {
 name                = "${var.resources_prefix}_lb"
 location            = var.location
 resource_group_name = azurerm_resource_group.app_tier_rg.name

 tags = var.default_resources_tags
}

#App tier load balancer backend pool
resource "azurerm_lb_backend_address_pool" "app_tier_bapool" {
 loadbalancer_id     = azurerm_lb.app_tier_lb.id
 name                = "app_Tier_BackEndAddressPool"
}

#App tier load balancer probe
resource "azurerm_lb_probe" "app_tier_lb_probe" {
 resource_group_name = azurerm_resource_group.app_tier_rg.name
 loadbalancer_id     = azurerm_lb.app_tier_lb.id
 name                = "ssh-check-probe"
 port                = "22"
}

# azure load balancer nat rule
resource "azurerm_lb_rule" "app_tier_lbnatrule" {
   resource_group_name            = azurerm_resource_group.app_tier_rg.name
   loadbalancer_id                = azurerm_lb.app_tier_lb.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = "80"
   backend_port                   = "80"
   backend_address_pool_id        = azurerm_lb_backend_address_pool.app_tier_bapool.id
   probe_id                       = azurerm_lb_probe.app_tier_lb_probe.id
   frontend_ip_configuration_name = ""
}

#App tier VMs created in a scale set
resource "azurerm_linux_virtual_machine_scale_set" "app_tier_vm_scaleset" {

    name = "${var.resources_prefix}_app_tier_scaleset"
    location = var.location
    resource_group_name = azurerm_resource_group.app_tier_rg.name
    sku = "Standard_F2"
    instances = 3

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
        name    = "${var.resources_prefix}_app_tier_nic"
        primary = true

        ip_configuration {
            name      = "${var.resources_prefix}_internal_nic"
            primary   = true
            subnet_id = azurerm_subnet.app_tier_subnet.id
        }
        
    }
}