provider "azurerm" {
  skip_provider_registration = "true"
  features {
  }
}

# Create resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}"
  location = "${var.location}"
}

# Create network vnet, subnet and NSG
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/22"]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-subnet-access"
    description                = "Allow access to other Vms on the subnet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Deny-access-from-internet"
    description                = "Deny direct access from the internet"
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
  name                = "${var.prefix}-nic-${var.server_name[count.index]}"
  count               = "${var.vm_count}" 
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

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
  name                    = "${var.prefix}-public-ip-for-lb"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  allocation_method       = "Dynamic"
}

# Create Load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-fe-ipconfig"
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
  name                         = "${var.prefix}-availability-set"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2

  tags = {
    type = "${var.azurerm_availability_set_tag}"
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
  availability_set_id   = azurerm_availability_set.main.id

  network_interface_ids = [
    element(azurerm_network_interface.main.*.id, count.index)
  ]

  #use the image we sourced at the beginnng of the script.
  source_image_id = data.azurerm_image.packer-image.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    type = "${var.vm_type_tag}"
  }
}
