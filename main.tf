# The basic provider to run against. 
provider "azurerm" {
}

terraform {
  backend "azurerm" {
    resource_group_name  = "Transpose-IT"
    storage_account_name = "tirandomstuff"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
  }
}

# Can also be put in a separate file called 'variables.tf'
variable "location" {}
variable "resource_group" {}
variable "admin_username" {}
variable "sku" {}

# Essentials
resource "azurerm_resource_group" "demo" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "demo-vnet" { 
  name                = "demo-vnet"
  address_space       = ["10.2.0.0/16"]
  resource_group_name = "${azurerm_resource_group.demo.name}"
  location            = "${azurerm_resource_group.demo.location}"
}

resource "azurerm_subnet" "demo-subnet" {
  name                  = "demo-subnet"
  address_prefix        = "10.2.1.0/24"
  resource_group_name   = "${azurerm_resource_group.demo.name}"
  virtual_network_name  = "${azurerm_virtual_network.demo-vnet.name}"
}

resource "azurerm_public_ip" "ti-demo" {
  name                         = "ti-demo-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.demo.name}"
  allocation_method            = "Static"
  domain_name_label            = "ti-demo"
}
resource "azurerm_network_security_group" "ti-demo" {
  name                = "ti-demo-nsg"
  resource_group_name = "${azurerm_resource_group.demo.name}"
  location            = "${var.location}"
  security_rule {
    name                       = "default-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Internal-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface" "ti-demo" {
  name                      = "ti-demo-nic"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.demo.name}"
  network_security_group_id = "${azurerm_network_security_group.ti-demo.id}"

  ip_configuration {
    name                          = "ipconfig-ti-demo"
    subnet_id                     = "${azurerm_subnet.demo-subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.ti-demo.id}"
  }
}
resource "azurerm_virtual_machine" "ti-demo" {
  name                  = "ti-demo"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.demo.name}"
  network_interface_ids = ["${azurerm_network_interface.ti-demo.id}"]
  vm_size               = "${var.sku}"

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.4"
    version   = "latest"
  }

  storage_os_disk {
    name                = "ti-demo-disk"
    os_type             = "linux"
    create_option       = "FromImage"
    caching             = "ReadWrite"
    managed_disk_type   = "Standard_LRS"
  }

  # We reuse the credentials for the VMSS here. 
  os_profile {
    computer_name   = "ti-demo"
    admin_username  = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azadmin/.ssh/authorized_keys"
      key_data = "${file("files/tidemo.pub")}"
    }
  }
  tags = {
    app = "ti-demo"
  }
}