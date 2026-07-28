function ConvertTo-HtmlSafe {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-DesktopPath {
    $desktop = [Environment]::GetFolderPath("Desktop")

    if ([string]::IsNullOrWhiteSpace($desktop) -or -not (Test-Path $desktop)) {
        return $env:TEMP
    }

    return $desktop
}

function Test-TcpPort {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$TimeoutMilliseconds = 1400
    )

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $result = $client.BeginConnect($HostName, $Port, $null, $null)
        $connected = $result.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)

        if ($connected -and $client.Connected) {
            $client.EndConnect($result)
            $client.Close()
            return $true
        }

        $client.Close()
        return $false
    }
    catch {
        return $false
    }
}

function Invoke-CurlCheck {
    param(
        [string[]]$Arguments
    )

    try {
        $output = & curl.exe @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE

        return [PSCustomObject]@{
            Success  = ($exitCode -eq 0)
            ExitCode = $exitCode
            Output   = $output.Trim()
        }
    }
    catch {
        return [PSCustomObject]@{
            Success  = $false
            ExitCode = 999
            Output   = $_.Exception.Message
        }
    }
}

function Get-PortOwner {
    param([int]$Port)

    try {
        $listeners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop

        if (-not $listeners) {
            return "Not listening"
        }

        $result = foreach ($listener in $listeners) {
            $processId = $listener.OwningProcess
            $processName = "Unknown"

            try {
                $processName = (Get-Process -Id $processId -ErrorAction Stop).ProcessName
            }
            catch {
            }

            "$($listener.LocalAddress):$Port | PID $processId | $processName"
        }

        return ($result -join "; ")
    }
    catch {
        return "Not listening"
    }
}

function Test-WindowsProxyRequest {
    param([string]$Url)

    try {
        $uri = [Uri]$Url
        $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $selectedProxy = $proxy.GetProxy($uri).AbsoluteUri

        $request = [System.Net.HttpWebRequest]::Create($uri)
        $request.Method = "HEAD"
        $request.AllowAutoRedirect = $true
        $request.Timeout = 10000
        $request.ReadWriteTimeout = 10000
        $request.Proxy = $proxy
        $request.UserAgent = "ProxyScope/$($script:Version)"

        $response = $request.GetResponse()
        $statusCode = [int]$response.StatusCode
        $response.Close()

        return [PSCustomObject]@{
            Success       = $true
            StatusCode    = $statusCode
            SelectedProxy = $selectedProxy
            ErrorMessage  = ""
        }
    }
    catch {
        return [PSCustomObject]@{
            Success       = $false
            StatusCode    = 0
            SelectedProxy = ""
            ErrorMessage  = $_.Exception.Message
        }
    }
}

function Get-SystemProxyData {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    $proxyEnable = 0
    $proxyServer = ""
    $autoConfigUrl = ""

    try {
        $settings = Get-ItemProperty -Path $path -ErrorAction Stop

        if ($null -ne $settings.ProxyEnable) {
            $proxyEnable = [int]$settings.ProxyEnable
        }

        if ($null -ne $settings.ProxyServer) {
            $proxyServer = [string]$settings.ProxyServer
        }

        if ($null -ne $settings.AutoConfigURL) {
            $autoConfigUrl = [string]$settings.AutoConfigURL
        }
    }
    catch {
    }

    return [PSCustomObject]@{
        Enabled       = $proxyEnable
        Server        = $proxyServer
        AutoConfigUrl = $autoConfigUrl
    }
}

function Get-ProxyEnvironmentData {
    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($scope in "Process", "User", "Machine") {
        foreach ($name in "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY") {
            $value = [Environment]::GetEnvironmentVariable($name, $scope)

            $rows.Add([PSCustomObject]@{
                Scope = $scope
                Name  = $name
                Value = $(if ([string]::IsNullOrWhiteSpace($value)) { "(not set)" } else { $value })
            })
        }
    }

    return $rows
}

function Get-ProxyProcessData {
    $pattern = "v2ray|xray|clash|mihomo|sing-box|nekoray|shadowsocks|hiddify|radmin"

    return @(
        Get-Process -ErrorAction SilentlyContinue |
            Where-Object { $_.ProcessName -match $pattern } |
            Sort-Object ProcessName |
            ForEach-Object {
                [PSCustomObject]@{
                    Process = $_.ProcessName
                    PID     = $_.Id
                }
            }
    )
}
