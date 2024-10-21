Set-DnsClient -InterfaceAlias "vEthernet (WSL)" -ConnectionSpecificSuffix "jade.jacobs.com" -UseSuffixWhenRegistering $True -RegisterThisConnectionsAddress $True
Get-DnsClient
Disable-NetAdapterBinding -Name "vEthernet (WSL)" -ComponentID ms_tcpip6
Get-NetAdapterBinding -Name "vEthernet (WSL)"
Pause