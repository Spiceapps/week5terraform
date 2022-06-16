# Create virtual network
resource "azurerm_virtual_network" "week5network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create public subnet
resource "azurerm_subnet" "week5subnet" {
  name                 = "myPublicSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.week5network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "week5PrivateSubnet" {
  name                 = "myPrivateSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.week5network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IP for Load Balancer
resource "azurerm_public_ip" "loadbalancerIP" {
   name                         = "publicIPForLB"
   location                     = azurerm_resource_group.rg.location
   resource_group_name          = azurerm_resource_group.rg.name
   allocation_method            = "Static"
 }

#Load Balancer
resource "azurerm_lb" "week5LB" {
   name                = "loadBalancer"
   location            = azurerm_resource_group.rg.location
   resource_group_name = azurerm_resource_group.rg.name

   frontend_ip_configuration {
     name                 = "publicIPAddress"
     public_ip_address_id = azurerm_public_ip.loadbalancerIP.id
   }
 }
resource "azurerm_lb_backend_address_pool" "lb_backendPool" {
   loadbalancer_id     = azurerm_lb.week5LB.id
   name                = "BackEndAddressPool"
 }

#Configure Load Balancer NAT Rules
resource "azurerm_lb_nat_rule" "sshrule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.week5LB.id
  name                           = "SSHAccess"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.week5LB.frontend_ip_configuration[0].name
}

resource "azurerm_lb_nat_rule" "webapprule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.week5LB.id
  name                           = "WebappAccess"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.week5LB.frontend_ip_configuration[0].name
}

resource "azurerm_network_interface_backend_address_pool_association" "example" {
  count                   = var.vmcount
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backendPool.id
  ip_configuration_name   = "primary"
  network_interface_id    = element(azurerm_network_interface.week5NIC.*.id, count.index)
}

# NIC
resource "azurerm_network_interface" "week5NIC" {
   count               = "${var.vmcount}"
   name                = "acctni${count.index}"
   location            = azurerm_resource_group.rg.location
   resource_group_name = azurerm_resource_group.rg.name
      ip_configuration {
     name                          = "mainConfiguration"
     subnet_id                     = azurerm_subnet.week5subnet.id
     private_ip_address_allocation = "Dynamic"
   }
 }

 resource "azurerm_network_interface" "week5DBNIC" {
   name                = "dbNIC"
   location            = azurerm_resource_group.rg.location
   resource_group_name = azurerm_resource_group.rg.name
      ip_configuration {
     name                          = "mainConfiguration"
     subnet_id                     = azurerm_subnet.week5PrivateSubnet.id
     private_ip_address_allocation = "Dynamic"
   }
 }

# Create Network Security Group and rule

resource "azurerm_network_security_group" "Public_nsg" {
  name                = "myPublic_SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "webapp"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8080"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "Private_nsg" {
  name                = "myDB_SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "postgre"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "5432"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

# Connect the public security group to the appVMs network interfaces
resource "azurerm_network_interface_security_group_association" "public_assoc" {
  count = "${var.vmcount}"
  network_interface_id      = azurerm_network_interface.week5NIC[count.index].id
  network_security_group_id = azurerm_network_security_group.Public_nsg.id
}

# Connect the private security group to the dbVM network interface
resource "azurerm_network_interface_security_group_association" "private_assoc" {
  network_interface_id      = azurerm_network_interface.week5DBNIC.id
  network_security_group_id = azurerm_network_security_group.Private_nsg.id
}