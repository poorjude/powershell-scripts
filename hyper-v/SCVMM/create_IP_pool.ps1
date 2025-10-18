# Едино для всех IP pool
$LogicalNetwork = Get-SCLogicalNetwork -Name "Virtual_Switch"
$DNSSearchSuffix = "domain.local"
$DNSServers = "192.168.1.34", "192.168.1.35", "8.8.8.8", "8.8.4.4"

# Индивидуально для каждого IP pool
$PoolName = "Mail - Moscow - 1197" # Называем по такому принципу: "Продукт - Месторасположение - VLAN ID"
$Description = "Product network for mail servers in Moscow"
$LogNetDef = Get-SCLogicalNetworkDefinition -Name "Virtual_Switch_Moscow" -LogicalNetwork $LogicalNetwork
$VLAN = "1197"
$Subnet = "192.168.11.0/24"
$StartIP = "192.168.11.11"
$EndIP = "192.168.11.180"
$Gateway = New-SCDefaultGateway -IPAddress "192.168.11.1" -Automatic



$NewSubnetVLAN = New-SCSubnetVLAN -Subnet $Subnet -VLanID $VLAN
# Приписываем VLAN к LogicalNetworkDefinition, если не существует
if ($NewSubnetVLAN -notin $LogNetDef.SubnetVlans) {
    $LogNetDefNewSubnetVLANs = $LogNetDef.SubnetVlans + $NewSubnetVLAN
    Set-SCLogicalNetworkDefinition -LogicalnetworkDefinition $LogNetDef -SubnetVLan $LogNetDefNewSubnetVLANs
}

New-SCStaticIPAddressPool `
    -LogicalNetworkDefinition $LogNetDef `
    -Name $PoolName `
    -Description $Description `
    -Subnet $Subnet `
    -Vlan $VLAN `
    -IPAddressRangeStart $StartIP `
    -IPAddressRangeEnd $EndIP `
    -DNSSearchSuffix $DNSSearchSuffix `
    -DNSServer $DNSServers `
    -DefaultGateway $Gateway