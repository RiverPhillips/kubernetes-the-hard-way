locals {
  worker_count = 3
}

resource "azurerm_availability_set" "worker_as" {
  name                = "worker-as"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  managed             = true
}

resource "azurerm_public_ip" "worker_public_ip" {
  count               = "${local.worker_count}"
  name                = "worker-${count.index}-pip"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "worker_nic" {
  count               = "${local.worker_count}"
  name                = "worker-${count.index}-nic"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "worker-${count.index}-private-ip"
    subnet_id                     = "${azurerm_subnet.kubernetes_subnet.id}"
    private_ip_address            = "10.240.0.2${count.index}"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = "${azurerm_public_ip.worker_public_ip.*.id[count.index]}"
  }
}

resource "azurerm_virtual_machine" "worker_vm" {
  count                 = "${local.worker_count}"
  name                  = "worker-${count.index}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  location              = "${azurerm_resource_group.rg.location}"
  network_interface_ids = ["${azurerm_network_interface.worker_nic.*.id[count.index]}"]
  availability_set_id   = "${azurerm_availability_set.worker_as.id}"
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "worker-${count.index}-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "worker-${count.index}"
    admin_username = "kuberoot"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys = [{
      key_data = "${file("~/.ssh/id_rsa.pub")}"
      path     = "/home/kuberoot/.ssh/authorized_keys"
    }]
  }
}
