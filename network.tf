# ==========================================
# 1. SUBNETS
# ==========================================

resource "azurerm_subnet" "hub_subnet" {
  name                 = "hub-internal"
  resource_group_name  = data.azurerm_resource_group.student_rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "spoke_subnet" {
  name                 = "spoke-internal"
  resource_group_name  = data.azurerm_resource_group.student_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_prod.name
  address_prefixes     = ["10.1.1.0/24"]
}

# ==========================================
# 2. PUBLIC IP (For Hub/Jumpbox only)
# ==========================================

resource "azurerm_public_ip" "hub_ip" {
  name                = "hub-vm-ip"
  location            = data.azurerm_resource_group.student_rg.location
  resource_group_name = data.azurerm_resource_group.student_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ==========================================
# 3. NETWORK INTERFACES (NICs)
# ==========================================

# Hub NIC (Has Public IP)
resource "azurerm_network_interface" "hub_nic" {
  name                = "hub-nic"
  location            = data.azurerm_resource_group.student_rg.location
  resource_group_name = data.azurerm_resource_group.student_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hub_ip.id
  }
}

# Spoke NIC (Private Only - No Public IP)
resource "azurerm_network_interface" "spoke_nic" {
  name                = "spoke-nic"
  location            = data.azurerm_resource_group.student_rg.location
  resource_group_name = data.azurerm_resource_group.student_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ==========================================
# 4. VIRTUAL MACHINES
# ==========================================

# HUB VM (The Jumpbox)
resource "azurerm_linux_virtual_machine" "hub_vm" {
  name                = "hub-vm" # Hyphens only!
  resource_group_name = data.azurerm_resource_group.student_rg.name
  location            = data.azurerm_resource_group.student_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.hub_nic.id]

  admin_password                  = "Password1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# SPOKE VM (The Private Server)
resource "azurerm_linux_virtual_machine" "spoke_vm" {
  name                = "spoke-vm" # Hyphens only!
  resource_group_name = data.azurerm_resource_group.student_rg.name
  location            = data.azurerm_resource_group.student_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.spoke_nic.id]

  admin_password                  = "Password1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# ==========================================
# 5. SECURITY GROUPS (Firewall)
# ==========================================

resource "azurerm_network_security_group" "hub_nsg" {
  name                = "hub-ssh-nsg"
  location            = data.azurerm_resource_group.student_rg.location
  resource_group_name = data.azurerm_resource_group.student_rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "hub_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
}