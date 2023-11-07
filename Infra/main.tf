provider "azurerm" {
  features {
    
  }
}

# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.prefix
  location = var.location
  tags = var.tags
}

# Create network vnet, subnet and NSG
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/22"]
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-NSG"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "Allow-subnet-access"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Deny-access-from-internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    type = "${var.network_security_group_tag}"
  }
}

# Create network interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-network-interface"
  count               = "${var.vm_count}" 
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    type = "${var.network_type_tag}"
  }
}

# Create public ip
resource "azurerm_public_ip" "main" {
  name                    = "${var.prefix}-public-ip"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  allocation_method       = "Dynamic"
}

# Create Load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-LB"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-public-ip-address"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    type = "${var.network_type_tag}"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.prefix}-lb-backend-addr-pool"
  loadbalancer_id     = azurerm_lb.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  ip_configuration_name   = "${var.prefix}-ipconfig"  
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.main[count.index].id
 
}

# Create the virtual machine
resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-availability-set"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 2

  tags = {
    environment = "Production"
  }
}

data "azurerm_image" "packer-image" {
  name                = "UdaPackerImg"
  resource_group_name = var.packer_resource_group
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.vm_count
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm-size
  admin_username                  = var.vm-admin-username
  admin_password                  = var.vm-admin-password
  disable_password_authentication = false
  computer_name                   = "${var.prefix}-vm-${count.index}"

  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  availability_set_id   = azurerm_availability_set.main.id

  #use the image we sourced at the beginnng of the script.
  source_image_id = data.azurerm_image.packer-image.id

  os_disk {
    name                 = "${var.prefix}-vm-${count.index}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    type = "${var.vm_type_tag}"
  }
}
