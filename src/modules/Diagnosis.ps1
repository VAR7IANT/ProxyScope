function Invoke-Diagnosis {
    param(
        [scriptblock]$ProgressCallback
    )

    function Update-Progress {
        param(
            [int]$Percent,
            [string]$Message
        )

        if ($ProgressCallback) {
            & $ProgressCallback $Percent $Message
        }
    }

    Update-Progress 5 "Reading Windows proxy settings"
    $proxy = Get-SystemProxyData

    $effectiveBaiduProxy = "(unknown)"
    $effectiveGoogleProxy = "(unknown)"

    try {
        $systemProxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $effectiveBaiduProxy = $systemProxy.GetProxy([Uri]"https://www.baidu.com").AbsoluteUri
        $effectiveGoogleProxy = $systemProxy.GetProxy([Uri]"https://www.google.com").AbsoluteUri
    }
    catch {
    }

    Update-Progress 15 "Checking local proxy ports"
    $ports = New-Object System.Collections.Generic.List[int]

    foreach ($defaultPort in 10808, 10809) {
        if (-not $ports.Contains($defaultPort)) {
            $ports.Add($defaultPort)
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($proxy.Server)) {
        foreach ($match in [regex]::Matches($proxy.Server, ":(\d{2,5})")) {
            $portValue = [int]$match.Groups[1].Value

            if ($portValue -ge 1 -and $portValue -le 65535 -and -not $ports.Contains($portValue)) {
                $ports.Add($portValue)
            }
        }
    }

    $ports = $ports | Select-Object -Unique | Select-Object -First 8
    $portRows = New-Object System.Collections.Generic.List[object]
    $portLookup = @{}

    $portIndex = 0

    foreach ($port in $ports) {
        $portIndex++
        Update-Progress (15 + [int](20 * $portIndex / [Math]::Max($ports.Count, 1))) "Testing proxy port $port"

        $listening = Test-TcpPort -HostName "127.0.0.1" -Port $port
        $owner = Get-PortOwner -Port $port

        $httpTest = Invoke-CurlCheck @(
            "-I", "-L",
            "--connect-timeout", "3",
            "--max-time", "8",
            "--proxy", "http://127.0.0.1:$port",
            "https://www.google.com"
        )

        $socksTest = Invoke-CurlCheck @(
            "-I", "-L",
            "--connect-timeout", "3",
            "--max-time", "8",
            "--proxy", "socks5h://127.0.0.1:$port",
            "https://www.google.com"
        )

        $row = [PSCustomObject]@{
            Port        = $port
            Listening   = $listening
            Owner       = $owner
            HttpProxy   = $(if ($httpTest.Success) { "Passed" } else { "Failed ($($httpTest.ExitCode))" })
            Socks5Proxy = $(if ($socksTest.Success) { "Passed" } else { "Failed ($($socksTest.ExitCode))" })
        }

        $portRows.Add($row)
        $portLookup[$port] = [PSCustomObject]@{
            Listening    = $listening
            HttpSuccess  = $httpTest.Success
            SocksSuccess = $socksTest.Success
            Owner        = $owner
        }
    }

    Update-Progress 40 "Collecting adapter and Wi-Fi information"
    $networkAdapters = Get-NetworkAdapterData
    $wifi = Get-WiFiData

    Update-Progress 50 "Testing DNS resolution"
    $dnsRows = Get-DnsData

    Update-Progress 60 "Testing direct internet access"
    $directBaidu = Invoke-CurlCheck @(
        "-I", "-L",
        "--connect-timeout", "5",
        "--max-time", "12",
        "--noproxy", "*",
        "https://www.baidu.com"
    )

    $directMicrosoft = Invoke-CurlCheck @(
        "-L",
        "--connect-timeout", "5",
        "--max-time", "12",
        "--noproxy", "*",
        "http://www.msftconnecttest.com/connecttest.txt"
    )

    Update-Progress 70 "Testing Windows system proxy"
    $systemProxyBaidu = Test-WindowsProxyRequest "https://www.baidu.com"
    $systemProxyGoogle = Test-WindowsProxyRequest "https://www.google.com"

    Update-Progress 80 "Checking processes, environment, and routes"
    $processRows = Get-ProxyProcessData
    $environmentRows = Get-ProxyEnvironmentData
    $routeRows = Get-RouteData

    Update-Progress 88 "Building automatic diagnosis"
    $findings = New-Object System.Collections.Generic.List[object]

    if ($proxy.Enabled -eq 1) {
        if ([string]::IsNullOrWhiteSpace($proxy.Server)) {
            $findings.Add((New-Finding "Critical" "System proxy enabled without a server" "Windows proxy is enabled, but no proxy server is configured."))
        }
        else {
            $findings.Add((New-Finding "Info" "Windows system proxy is enabled" "Configured server: $($proxy.Server)"))

            foreach ($match in [regex]::Matches($proxy.Server, "127\.0\.0\.1:(\d{2,5})")) {
                $portValue = [int]$match.Groups[1].Value
                $result = $portLookup[$portValue]

                if ($null -eq $result -or -not $result.Listening) {
                    $findings.Add((New-Finding "Critical" "Configured proxy port is offline" "Windows points to 127.0.0.1:$portValue, but no process is listening on that port."))
                }
                else {
                    $findings.Add((New-Finding "OK" "Configured proxy port is online" "127.0.0.1:$portValue is listening. $($result.Owner)"))

                    if (-not $result.HttpSuccess -and $result.SocksSuccess) {
                        $findings.Add((New-Finding "Warning" "SOCKS-only port used as Windows proxy" "Port $portValue passed SOCKS5 but failed HTTP. Windows manual proxy normally requires an HTTP-compatible or mixed port."))
                    }
                }
            }

            $findings.Add((New-Finding "Warning" "Proxy may remain enabled after the app closes" "If the proxy application exits without clearing Windows proxy settings, browsers and applications may lose internet access."))
        }
    }
    else {
        $findings.Add((New-Finding "OK" "Windows system proxy is disabled" "Applications can use the direct network unless they have their own proxy settings."))
    }

    if ($directBaidu.Success) {
        $findings.Add((New-Finding "OK" "Direct internet access passed" "A forced direct HTTPS request to Baidu succeeded."))
    }
    else {
        $findings.Add((New-Finding "Critical" "Direct internet access failed" "A forced direct HTTPS request to Baidu failed with exit code $($directBaidu.ExitCode)."))
    }

    $baiduDnsSuccess = @($dnsRows | Where-Object {
        $_.Host -eq "www.baidu.com" -and $_.Status -eq "Resolved"
    }).Count -gt 0

    if ($baiduDnsSuccess) {
        $findings.Add((New-Finding "OK" "DNS resolution passed" "Baidu returned one or more address records."))
    }
    else {
        $findings.Add((New-Finding "Critical" "DNS resolution failed" "Baidu did not return a usable address record."))
    }

    if ($directBaidu.Success -and -not $systemProxyBaidu.Success -and $proxy.Enabled -eq 1) {
        $findings.Add((New-Finding "Critical" "Windows proxy blocks otherwise working internet" "Direct access passed, but access through the Windows proxy failed."))
    }

    $radminPersistentDefault = @(
        $routeRows | Where-Object {
            $_.Destination -eq "0.0.0.0/0" -and
            $_.NextHop -like "26.*" -and
            $_.Store -eq "PersistentStore"
        }
    ).Count -gt 0

    if ($radminPersistentDefault) {
        $findings.Add((New-Finding "Warning" "Persistent Radmin default route detected" "A persistent 0.0.0.0/0 route through the 26.x Radmin range may cause intermittent routing problems if priorities change."))
    }

    Update-Progress 94 "Writing reports"
    $outputFolder = Join-Path (Get-DesktopPath) "ProxyScopeReports"

    if (-not (Test-Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $htmlPath = Join-Path $outputFolder "proxy_network_report_$timestamp.html"
    $jsonPath = Join-Path $outputFolder "proxy_network_report_$timestamp.json"

    $isAdministrator = $false

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        $isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
    }

    $data = @{
        Generated            = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Computer             = $env:COMPUTERNAME
        User                 = $env:USERNAME
        Administrator        = $isAdministrator
        Proxy                = $proxy
        EffectiveBaiduProxy  = $effectiveBaiduProxy
        EffectiveGoogleProxy = $effectiveGoogleProxy
        PortRows             = $portRows
        NetworkAdapters      = $networkAdapters
        WiFi                 = $wifi
        DnsRows              = $dnsRows
        DirectBaidu          = $directBaidu
        DirectMicrosoft      = $directMicrosoft
        SystemProxyBaidu     = $systemProxyBaidu
        SystemProxyGoogle    = $systemProxyGoogle
        ProcessRows          = $processRows
        EnvironmentRows      = $environmentRows
        RouteRows            = $routeRows
        Findings             = $findings
    }

    Write-HtmlReport -Path $htmlPath -Data $data
    Write-JsonReport -Path $jsonPath -Data $data

    Update-Progress 100 "Diagnosis complete"

    return [PSCustomObject]@{
        HtmlPath = $htmlPath
        JsonPath = $jsonPath
        Findings = $findings
    }
}
