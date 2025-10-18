# Меняем только 5 переменных ниже, остальные ни в одном месте можно не изменять
$VLAN = "1197"
$site = "Moscow"
$product = "Mail"
$IPbase = "192.168.11" # Первые три бита подсети (без точки в конце)
$Description = "Product network for mail servers in Moscow"



$DNSSearchSuffix = "domain.local"
$DNSServers = "192.168.1.34", "192.168.1.35", "8.8.8.8", "8.8.4.4"
$LogicalNetwork = Get-SCLogicalNetwork -Name "Virtual_Switch"
$PoolName = $product + " - " + $site + " - " + $VLAN # Называем подсеть по такому принципу: "Продукт - Месторасположение - VLAN ID"
$LogNetDef = Get-SCLogicalNetworkDefinition -Name ("Virtual_Switch_" + $site) -LogicalNetwork $LogicalNetwork
$Subnet = $IPbase + ".0/24"
$StartIP = $IPbase + ".11"
$EndIP = $IPbase + ".180"
$Gateway = New-SCDefaultGateway -IPAddress ($IPbase + ".1") -Automatic
# $NetworkRoute = New-SCNetworkRoute -DestinationPrefix ($IPbase + ".0/24") -NextHop ($IPbase + ".1")



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
    -DefaultGateway $Gateway # -NetworkRoute $NetworkRoute