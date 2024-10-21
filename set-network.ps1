Set-DnsClient -InterfaceAlias "*" -ConnectionSpecificSuffix "jade.jacobs.com" -UseSuffixWhenRegistering $True -RegisterThisConnectionsAddress $True
Get-DnsClient
Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6
Get-NetAdapterBinding -Name "*" -ComponentID ms_tcpip
Pause