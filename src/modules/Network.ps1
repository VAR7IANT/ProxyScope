function Get-NetworkAdapterData {
    $rows = New-Object System.Collections.Generic.List[object]

    try {
        $configurations = Get-NetIPConfiguration -ErrorAction Stop | Sort-Object InterfaceAlias

        foreach ($configuration in $configurations) {
            $ipv4 = if ($configuration.IPv4Address) {
                (($configuration.IPv4Address | ForEach-Object { $_.IPAddress }) -join ", ")
            }
            else {
                "(none)"
            }

            $ipv6 = if ($configuration.IPv6Address) {
                (($configuration.IPv6Address | ForEach-Object { $_.IPAddress }) -join ", ")
            }
            else {
                "(none)"
            }

            $ipv4Gateway = if ($configuration.IPv4DefaultGateway) {
                ($configuration.IPv4DefaultGateway.NextHop -join ", ")
            }
            else {
                "(none)"
            }

            $dns = if ($configuration.DNSServer.ServerAddresses) {
                ($configuration.DNSServer.ServerAddresses -join ", ")
            }
            else {
                "(none)"
            }

            $rows.Add([PSCustomObject]@{
                Interface   = $configuration.InterfaceAlias
                Description = $configuration.InterfaceDescription
                IPv4        = $ipv4
                IPv6        = $ipv6
                Gateway     = $ipv4Gateway
                DNS         = $dns
            })
        }
    }
    catch {
        $rows.Add([PSCustomObject]@{
            Interface   = "Error"
            Description = $_.Exception.Message
            IPv4        = ""
            IPv6        = ""
            Gateway     = ""
            DNS         = ""
        })
    }

    return $rows
}

function Get-WiFiData {
    $rows = New-Object System.Collections.Generic.List[object]

    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction Stop |
            Where-Object {
                $_.InterfaceDescription -match "Wireless|Wi-Fi|WiFi|802\.11" -or
                $_.Name -match "Wi-Fi|WiFi|WLAN"
            }

        foreach ($adapter in $adapters) {
            $rows.Add([PSCustomObject]@{
                Interface   = $adapter.Name
                Description = $adapter.InterfaceDescription
                Status      = $adapter.Status
                LinkSpeed   = $adapter.LinkSpeed
                MacAddress  = $adapter.MacAddress
            })
        }
    }
    catch {
    }

    return $rows
}

function Get-DnsData {
    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($hostName in "www.baidu.com", "www.google.com") {
        try {
            $records = Resolve-DnsName $hostName -ErrorAction Stop |
                Where-Object { $_.IPAddress }

            if ($records) {
                foreach ($record in $records) {
                    $rows.Add([PSCustomObject]@{
                        Host    = $hostName
                        Address = $record.IPAddress
                        Status  = "Resolved"
                    })
                }
            }
            else {
                $rows.Add([PSCustomObject]@{
                    Host    = $hostName
                    Address = "(none)"
                    Status  = "No address records"
                })
            }
        }
        catch {
            $rows.Add([PSCustomObject]@{
                Host    = $hostName
                Address = ""
                Status  = "Failed: $($_.Exception.Message)"
            })
        }
    }

    return $rows
}

function Get-RouteData {
    $rows = New-Object System.Collections.Generic.List[object]

    try {
        $routes = Get-NetRoute -AddressFamily IPv4 -ErrorAction Stop |
            Sort-Object DestinationPrefix, RouteMetric, InterfaceMetric

        foreach ($route in $routes) {
            if (
                $route.DestinationPrefix -eq "0.0.0.0/0" -or
                $route.DestinationPrefix -eq "127.0.0.0/8" -or
                $route.DestinationPrefix -like "192.168.*" -or
                $route.DestinationPrefix -like "10.*" -or
                $route.DestinationPrefix -like "26.*"
            ) {
                $rows.Add([PSCustomObject]@{
                    Destination     = $route.DestinationPrefix
                    NextHop         = $route.NextHop
                    Interface       = $route.InterfaceAlias
                    RouteMetric     = $route.RouteMetric
                    InterfaceMetric = $route.InterfaceMetric
                    Store           = $route.Store
                })
            }
        }
    }
    catch {
        $rows.Add([PSCustomObject]@{
            Destination     = "Error"
            NextHop         = $_.Exception.Message
            Interface       = ""
            RouteMetric     = ""
            InterfaceMetric = ""
            Store           = ""
        })
    }

    return $rows
}
