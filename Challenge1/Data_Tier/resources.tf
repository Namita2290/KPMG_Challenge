#resource group for data tier resources
resource "azurerm_resource_group" "data_tier_rg" {

    name = "${var.resources_prefix}_data_tier_rg"
    location = var.location
    tags = var.default_resources_tags
}

#vnet for data tier resources
resource "azurerm_virtual_network" "data_tier_vnet" {
  name = "${var.resources_prefix}_data_tier_vnet"
  address_space = [ "10.0.0.0/16" ]
  location = var.location
  resource_group_name = azurerm_resource_group.data_tier_rg.name
  tags = var.default_resources_tags
}

#subnet for data tier resoruces
resource "azurerm_subnet" "data_tier_subnet" {
 name                 = "${var.resources_prefix}_data_tier_subnet"
 resource_group_name  = azurerm_resource_group.data_tier_rg.name
 virtual_network_name = azurerm_virtual_network.data_tier_vnet.name
 address_prefixes       = ["10.0.3.0/24"]
}

#nsg for data tier resources
resource "azurerm_network_security_group" "data_tier_nsg" {
  name                = "${var.resources_prefix}_data_tier_nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.data_tier_rg.name
}

#allow traffic on 1433 for database to data tier subnet
resource "azurerm_network_security_rule" "data_tier_allow_1433_rule" {
  
    name                       = "business-tier-1433-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "1433"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.data_tier_rg.name
    network_security_group_name = azurerm_network_security_group.data_tier_nsg.name
  
}

#allow health check fromm load balancer
resource "azurerm_network_security_rule" "data_tier_lb_probe_rule" {
  
    name                       = "data-tier-lb-probe-allow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.data_tier_rg.name
    network_security_group_name = azurerm_network_security_group.data_tier_nsg.name
  
}

#block access for all resources from its own vnet
resource "azurerm_network_security_rule" "data_tier_block_vnet_rule" {
  
    name                       = "data-tier-allow-lb-probe"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.data_tier_rg.name
    network_security_group_name = azurerm_network_security_group.data_tier_nsg.name
  
}

# nsg and data tuer subnet association
resource "azurerm_subnet_network_security_group_association" "data_tier_nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.data_tier_subnet.id
  network_security_group_id = azurerm_network_security_group.data_tier_nsg.id
}

#data tier load balancer
resource "azurerm_lb" "data_tier_lb" {
 name                = "${var.resources_prefix}_lb"
 location            = var.location
 resource_group_name = azurerm_resource_group.data_tier_rg.name

 tags = var.default_resources_tags
}

#data tier load balancer backend pool
resource "azurerm_lb_backend_address_pool" "data_tier_bapool" {
 loadbalancer_id     = azurerm_lb.data_tier_lb.id
 name                = "data_Tier_BackEndAddressPool"
}

#data tier load balancer probe
resource "azurerm_lb_probe" "data_tier_lb_probe" {
 resource_group_name = azurerm_resource_group.data_tier_rg.name
 loadbalancer_id     = azurerm_lb.data_tier_lb.id
 name                = "ssh-check-probe"
 port                = "22"
}

#data tier load balancer nat rule
resource "azurerm_lb_rule" "data_tier_lbnatrule" {
   resource_group_name            = azurerm_resource_group.data_tier_rg.name
   loadbalancer_id                = azurerm_lb.data_tier_lb.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = "80"
   backend_port                   = "80"
   backend_address_pool_ids        = azurerm_lb_backend_address_pool.data_tier_bapool.id
   frontend_ip_configuration_name = "data_tier_PublicIPAddress"
   probe_id                       = azurerm_lb_probe.data_tier_lb_probe.id
}

#data tier VM's deployed in a scale set
resource "azurerm_linux_virtual_machine_scale_set" "data_tier_vm_scaleset" {

    name = "${var.resources_prefix}_data_tier_scaleset"
    location = var.location
    resource_group_name = azurerm_resource_group.data_tier_rg.name
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
        name    = "${var.resources_prefix}_data_tier_nic"
        primary = true

        ip_configuration {
            name      = "${var.resources_prefix}_internal_nic"
            primary   = true
            subnet_id = azurerm_subnet.data_tier_subnet.id
        }
    }
}