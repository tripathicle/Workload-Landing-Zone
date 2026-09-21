# output "public_ips" {
#   description = "Map of public IPs"
#   value = {
#     for key, ip in azurerm_public_ip.this : key => {
#       id   = ip.id
#       name = ip.name
#     }
#   }
# }
#
# output "firewalls" {
#   description = "Map of Azure Firewalls"
#   value = {
#     for key, firewall in azurerm_firewall.this : key => {
#       id   = firewall.id
#       name = firewall.name
#     }
#   }
# }


