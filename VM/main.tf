terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.9.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "xxxx"
  client_id       = "ssssssssss"
  client_secret   = "ddddddddd"
  tenant_id       = "xxxxxsssssssssss"
}

resource "azurerm_resource_group" "rg1" {
  name     = "terraform-demo"
  location = "West Europe"
}

resource "azurerm_storage_account" "database" {
  name                     = "bedatabaseca"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "development"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "demo-vnet"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "demo-subnet" {
  name                 = "demo-subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
    depends_on = [ azurerm_virtual_network.vnet,azurerm_subnet.demo-subnet ]
  name                = "demo-publicip"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "demo-nic" {
  name                = "demo-nic1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "nic-ip-config"
    subnet_id                     = azurerm_subnet.demo-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "demo-nsg"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  
security_rule {
    name                       = "allow-everything"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

  tags = {
    environment = "Production"
  }

}

resource "azurerm_subnet_network_security_group_association" "demo-nsg-association" {
    subnet_id = azurerm_subnet.demo-subnet.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "demo-vm" {
 name = "FEDatabase"
 computer_name = "testlinuxvm1" 
 resource_group_name = azurerm_resource_group.rg1.name
 location = azurerm_resource_group.rg1.location
size = "Standard_Ds1_v2"
admin_username = "azureadmin"
network_interface_ids = [azurerm_network_interface.demo-nic.id]
admin_ssh_key {
  username = "azureadmin"
  public_key = file ("${path.module}/ssh-keys/terraform-azure.pub")
}
os_disk {
  name = "osdisk"
  caching = "ReadWrite"
  storage_account_type = "Standard_LRS"
}
source_image_reference {
  publisher = "RedHat"
  offer = "RHEL"
  sku = "83-gen2"
  version = "latest"
}
custom_data = filebase64("${path.module}/custom-script/init.txt")
}