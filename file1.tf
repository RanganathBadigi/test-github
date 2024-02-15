terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "<=3.80,>=3.80"
    }
  }
}
provider "azurerm" {
  features { }
  skip_provider_registration = true
}

resource "azurerm_resource_group" "example" {
  name = "ranga-rg-lab"
  location = "eastus"
}

resource "azurerm_virtual_network" "example" {
  name                = "ranga-rg-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "ranga-rg-network-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "dev-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal-nic"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.iptest.id
  }
}

resource "azurerm_public_ip" "iptest" {
  name = "ip-vm"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  allocation_method = "Static" 
}


resource "azurerm_linux_virtual_machine" "example" {
  name                = "linux-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  admin_password  = "Kyndryl@12345#"
  disable_password_authentication = false

 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


resource "azurerm_network_security_group" "example" {
  name                = "ssh22SecurityGroup"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "RDPrule"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
    }
}
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}
