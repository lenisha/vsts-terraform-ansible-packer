terraform {
  required_version = ">= 0.11"

  backend "azurerm" {
    storage_account_name = "storeinfraq5nlivodfwwqmm"
    container_name       = "terraform-state"
    key                  = "demo-packer.terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "demo_resource_group" {
  name     = "packerdemocreate"
  location = "Canada Central"

  tags {
    environment = "Packer Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "demo_virtual_network" {
  name                = "packerdemo"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.demo_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.demo_resource_group.name}"

  tags {
    environment = "Packer Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "demo_subnet" {
  name                 = "packerdemo"
  resource_group_name  = "${azurerm_resource_group.demo_resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.demo_virtual_network.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "demo_public_ip" {
  name                         = "packerpublicip"
  location                     = "${azurerm_resource_group.demo_resource_group.location}"
  resource_group_name          = "${azurerm_resource_group.demo_resource_group.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "demopackeriac"

  tags {
    environment = "Packer Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "demo_security_group" {
  name                = "packersecuritygroups"
  location            = "${azurerm_resource_group.demo_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.demo_resource_group.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Packer Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "demo_nic" {
  name                      = "myNIC"
  location                  = "${azurerm_resource_group.demo_resource_group.location}"
  resource_group_name       = "${azurerm_resource_group.demo_resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.demo_security_group.id}"

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = "${azurerm_subnet.demo_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.demo_public_ip.id}"
  }

  tags {
    environment = "Terraform Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.demo_resource_group.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "demo_storage_account" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.demo_resource_group.name}"
  location                 = "${azurerm_resource_group.demo_resource_group.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Terraform Demo"
  }
}

data "azurerm_resource_group" "image" {
  name = "packer-rg"
}

data "azurerm_image" "image" {
  name                = "demoPackerImage"
  resource_group_name = "${data.azurerm_resource_group.image.name}"
}

#resource "azurerm_image" "demo_image" {
#  name                = "demoimage"
#  location            = "${azurerm_resource_group.demo_resource_group.location}"
#  resource_group_name = "${azurerm_resource_group.demo_resource_group.name}"

#  os_disk {
#    os_type  = "Linux"
#    os_state = "Generalized"
#    blob_uri = "${var.baked_image_url}"
#    size_gb  = 30
#  }
#}

# Create virtual machine
resource "azurerm_virtual_machine" "demo_vm" {
  name                  = "packerVM"
  location              = "${azurerm_resource_group.demo_resource_group.location}"
  resource_group_name   = "${azurerm_resource_group.demo_resource_group.name}"
  network_interface_ids = ["${azurerm_network_interface.demo_nic.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_profile_image_reference {
    id = "${data.azurerm_image.image.id}"
  }

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "myvm"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDzWnLrGQrrR/1ghPRWzRVGLi64vMv+h+Wqx1BbgjHBUJd+TmJwrt8jJn7g/lMt9v2nkPU31B5iFeJJei5E/ShPAhxss4N5/J4fP6Uxq3iXcDC9LdC3P4wdQh5bxTYN1ruQtPpmyTPrLpfK++SPu42pAiAoAWdiw7s/WXLzxNALWsl2zrpNqTK9OdrDWmDFeu7PzVGxJ3cPEhPHfxzBTmj87vN5obSGr7uHrmtDwX5+5l6UscyWLdC6q6Wbk/SW8bICfccXJua3yddtXb5sx8jSivo99qusSpE8uUrpzFz9XFlARJQWtO0fsZKnK+yxZktcGNh8FvI89AU7iW4A180z lenisha@Terraform"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.demo_storage_account.primary_blob_endpoint}"
  }

  tags {
    environment = "Terraform Demo"
  }
}

output "vm_ip" {
  value = "${azurerm_public_ip.demo_public_ip.ip_address}"
}

output "vm_dns" {
  value = "http://${azurerm_public_ip.demo_public_ip.domain_name_label}.canadacentral.cloudapp.azure.com"
}
