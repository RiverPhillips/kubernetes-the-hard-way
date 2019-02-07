resource "azurerm_network_security_group" "kubernetes_nsg" {
  name                = "kubernetes-nsg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_network_security_rule" "ssh_inbound" {
  name                        = "ssh-inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.kubernetes_nsg.name}"
}

resource "azurerm_network_security_rule" "https_inbound" {
  name                        = "https-inbound"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.kubernetes_nsg.name}"
}

resource "azurerm_virtual_network" "kubernetes_vnet" {
  name                = "kubernetes-vnet"
  address_space       = ["10.240.0.0/24"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "kubernetes_subnet" {
  name                 = "kubernetes-subnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "10.240.0.0/24"
  virtual_network_name = "${azurerm_virtual_network.kubernetes_vnet.name}"
}

resource "azurerm_subnet_network_security_group_association" "security_group_association" {
  subnet_id                 = "${azurerm_subnet.kubernetes_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.kubernetes_nsg.id}"
}

resource "azurerm_public_ip" "kubernetes_static_ip" {
  name                = "lb_ip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
}

resource "azurerm_lb" "load_balancer" {
  name                = "kubernetes_lb"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  frontend_ip_configuration {
    name                 = "kubernetes"
    public_ip_address_id = "${azurerm_public_ip.kubernetes_static_ip.id}"
  }
}
