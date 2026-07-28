function Convert-ObjectListToHtmlTable {
    param(
        [object[]]$Rows,
        [string[]]$Columns
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return '<div class="empty">No data found</div>'
    }

    $header = ($Columns | ForEach-Object {
        "<th>$(ConvertTo-HtmlSafe $_)</th>"
    }) -join ""

    $bodyRows = foreach ($row in $Rows) {
        $cells = foreach ($column in $Columns) {
            $value = $row.$column
            "<td>$(ConvertTo-HtmlSafe $value)</td>"
        }

        "<tr>$($cells -join '')</tr>"
    }

    return @"
<div class="table-wrap">
<table>
<thead><tr>$header</tr></thead>
<tbody>
$($bodyRows -join "`n")
</tbody>
</table>
</div>
"@
}

function Get-SeverityClass {
    param([string]$Severity)

    switch ($Severity) {
        "Critical" { return "critical" }
        "Warning"  { return "warning" }
        "OK"       { return "ok" }
        default    { return "info" }
    }
}

function New-Finding {
    param(
        [string]$Severity,
        [string]$Title,
        [string]$Details
    )

    return [PSCustomObject]@{
        Severity = $Severity
        Title    = $Title
        Details  = $Details
    }
}

function Write-HtmlReport {
    param(
        [string]$Path,
        [hashtable]$Data
    )

    $findingsHtml = foreach ($finding in $Data.Findings) {
        $className = Get-SeverityClass $finding.Severity

        @"
<div class="finding $className">
  <div class="finding-badge">$([System.Net.WebUtility]::HtmlEncode($finding.Severity))</div>
  <div>
    <div class="finding-title">$([System.Net.WebUtility]::HtmlEncode($finding.Title))</div>
    <div class="finding-details">$([System.Net.WebUtility]::HtmlEncode($finding.Details))</div>
  </div>
</div>
"@
    }

    $proxyStatusClass = if ($Data.Proxy.Enabled -eq 1) { "warning" } else { "ok" }
    $proxyStatusText = if ($Data.Proxy.Enabled -eq 1) { "Enabled" } else { "Disabled" }

    $directClass = if ($Data.DirectBaidu.Success) { "ok" } else { "critical" }
    $directText = if ($Data.DirectBaidu.Success) { "Passed" } else { "Failed" }

    $systemClass = if ($Data.SystemProxyBaidu.Success) { "ok" } else { "critical" }
    $systemText = if ($Data.SystemProxyBaidu.Success) { "Passed" } else { "Failed" }

    $criticalCount = @($Data.Findings | Where-Object { $_.Severity -eq "Critical" }).Count
    $warningCount = @($Data.Findings | Where-Object { $_.Severity -eq "Warning" }).Count

    $overallClass = if ($criticalCount -gt 0) {
        "critical"
    }
    elseif ($warningCount -gt 0) {
        "warning"
    }
    else {
        "ok"
    }

    $overallText = if ($criticalCount -gt 0) {
        "Action required"
    }
    elseif ($warningCount -gt 0) {
        "Review recommended"
    }
    else {
        "Healthy"
    }

    $proxyRows = @(
        [PSCustomObject]@{ Setting = "Proxy enabled"; Value = $Data.Proxy.Enabled }
        [PSCustomObject]@{ Setting = "Proxy server"; Value = $(if ($Data.Proxy.Server) { $Data.Proxy.Server } else { "(not set)" }) }
        [PSCustomObject]@{ Setting = "Automatic configuration URL"; Value = $(if ($Data.Proxy.AutoConfigUrl) { $Data.Proxy.AutoConfigUrl } else { "(not set)" }) }
        [PSCustomObject]@{ Setting = "Effective Baidu proxy"; Value = $Data.EffectiveBaiduProxy }
        [PSCustomObject]@{ Setting = "Effective Google proxy"; Value = $Data.EffectiveGoogleProxy }
    )

    $connectivityRows = @(
        [PSCustomObject]@{ Test = "Direct Baidu"; Success = $Data.DirectBaidu.Success; ExitCode = $Data.DirectBaidu.ExitCode }
        [PSCustomObject]@{ Test = "Direct Microsoft"; Success = $Data.DirectMicrosoft.Success; ExitCode = $Data.DirectMicrosoft.ExitCode }
        [PSCustomObject]@{ Test = "Baidu through Windows proxy"; Success = $Data.SystemProxyBaidu.Success; ExitCode = $Data.SystemProxyBaidu.StatusCode }
        [PSCustomObject]@{ Test = "Google through Windows proxy"; Success = $Data.SystemProxyGoogle.Success; ExitCode = $Data.SystemProxyGoogle.StatusCode }
    )

    $html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ProxyScope Report</title>
<style>
:root {
  --bg: #f4f6f8;
  --panel: #ffffff;
  --text: #111827;
  --muted: #6b7280;
  --line: #e5e7eb;
  --ok: #15803d;
  --ok-bg: #ecfdf3;
  --warn: #b45309;
  --warn-bg: #fff7ed;
  --critical: #b91c1c;
  --critical-bg: #fef2f2;
  --info: #1d4ed8;
  --info-bg: #eff6ff;
  --shadow: 0 10px 30px rgba(17, 24, 39, .06);
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: "Segoe UI", Inter, Arial, sans-serif;
}
.container {
  max-width: 1180px;
  margin: 0 auto;
  padding: 34px 22px 64px;
}
.hero {
  background: linear-gradient(135deg, #111827, #374151);
  color: white;
  border-radius: 22px;
  padding: 30px;
  box-shadow: var(--shadow);
}
.hero-top {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  align-items: flex-start;
}
.eyebrow {
  font-size: 12px;
  letter-spacing: .14em;
  text-transform: uppercase;
  color: #cbd5e1;
  font-weight: 700;
}
h1 {
  margin: 8px 0 8px;
  font-size: 32px;
  line-height: 1.15;
}
.subtitle {
  color: #d1d5db;
  max-width: 720px;
}
.overall {
  min-width: 170px;
  text-align: center;
  border-radius: 14px;
  padding: 16px 18px;
  font-weight: 700;
  background: rgba(255,255,255,.12);
  border: 1px solid rgba(255,255,255,.14);
}
.meta {
  margin-top: 22px;
  display: flex;
  flex-wrap: wrap;
  gap: 10px 20px;
  color: #d1d5db;
  font-size: 13px;
}
.cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin: 20px 0;
}
.card {
  background: var(--panel);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 18px;
  box-shadow: var(--shadow);
}
.card-label {
  color: var(--muted);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: .08em;
  font-weight: 700;
}
.card-value {
  margin-top: 8px;
  font-size: 20px;
  font-weight: 750;
}
.card.ok { border-top: 4px solid var(--ok); }
.card.warning { border-top: 4px solid var(--warn); }
.card.critical { border-top: 4px solid var(--critical); }
.section {
  background: var(--panel);
  border: 1px solid var(--line);
  border-radius: 18px;
  padding: 22px;
  margin-top: 18px;
  box-shadow: var(--shadow);
}
.section h2 {
  margin: 0 0 16px;
  font-size: 18px;
}
.findings {
  display: grid;
  gap: 12px;
}
.finding {
  display: grid;
  grid-template-columns: 88px 1fr;
  gap: 14px;
  align-items: start;
  padding: 14px;
  border-radius: 13px;
  border: 1px solid var(--line);
}
.finding.ok { background: var(--ok-bg); border-color: #bbf7d0; }
.finding.warning { background: var(--warn-bg); border-color: #fed7aa; }
.finding.critical { background: var(--critical-bg); border-color: #fecaca; }
.finding.info { background: var(--info-bg); border-color: #bfdbfe; }
.finding-badge {
  font-size: 11px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: .06em;
}
.finding.ok .finding-badge { color: var(--ok); }
.finding.warning .finding-badge { color: var(--warn); }
.finding.critical .finding-badge { color: var(--critical); }
.finding.info .finding-badge { color: var(--info); }
.finding-title { font-weight: 750; margin-bottom: 4px; }
.finding-details { color: #4b5563; line-height: 1.5; }
.table-wrap {
  width: 100%;
  overflow-x: auto;
  border: 1px solid var(--line);
  border-radius: 12px;
}
table {
  width: 100%;
  border-collapse: collapse;
  min-width: 640px;
}
th, td {
  padding: 11px 12px;
  text-align: left;
  border-bottom: 1px solid var(--line);
  vertical-align: top;
}
th {
  background: #f9fafb;
  color: #374151;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: .04em;
}
td {
  font-size: 13px;
  color: #374151;
}
tr:last-child td { border-bottom: 0; }
details {
  border: 1px solid var(--line);
  border-radius: 12px;
  margin-top: 12px;
  overflow: hidden;
}
summary {
  cursor: pointer;
  padding: 14px 16px;
  font-weight: 700;
  background: #f9fafb;
}
.details-body { padding: 14px; }
.empty {
  color: var(--muted);
  padding: 18px;
  border: 1px dashed var(--line);
  border-radius: 12px;
}
.footer {
  color: var(--muted);
  text-align: center;
  font-size: 12px;
  margin-top: 28px;
}
@media (max-width: 900px) {
  .cards { grid-template-columns: repeat(2, 1fr); }
  .hero-top { display: block; }
  .overall { margin-top: 18px; }
}
@media (max-width: 560px) {
  .cards { grid-template-columns: 1fr; }
  h1 { font-size: 26px; }
  .container { padding: 18px 12px 40px; }
  .finding { grid-template-columns: 1fr; }
}
</style>
</head>
<body>
<div class="container">
  <section class="hero">
    <div class="hero-top">
      <div>
        <div class="eyebrow">Windows diagnostics</div>
        <h1>ProxyScope</h1>
        <div class="subtitle">A read-only diagnostic report for Windows proxy, DNS, routing, local proxy ports, and direct connectivity.</div>
      </div>
      <div class="overall">$overallText</div>
    </div>
    <div class="meta">
      <span>Version $($script:Version)</span>
      <span>Generated $($Data.Generated)</span>
      <span>$([System.Net.WebUtility]::HtmlEncode($Data.Computer))</span>
      <span>Administrator $($Data.Administrator)</span>
    </div>
  </section>

  <section class="cards">
    <div class="card $overallClass">
      <div class="card-label">Overall status</div>
      <div class="card-value">$overallText</div>
    </div>
    <div class="card $proxyStatusClass">
      <div class="card-label">Windows proxy</div>
      <div class="card-value">$proxyStatusText</div>
    </div>
    <div class="card $directClass">
      <div class="card-label">Direct access</div>
      <div class="card-value">$directText</div>
    </div>
    <div class="card $systemClass">
      <div class="card-label">System proxy access</div>
      <div class="card-value">$systemText</div>
    </div>
  </section>

  <section class="section">
    <h2>Automatic diagnosis</h2>
    <div class="findings">
      $($findingsHtml -join "`n")
    </div>
  </section>

  <section class="section">
    <h2>Windows proxy settings</h2>
    $(Convert-ObjectListToHtmlTable -Rows $proxyRows -Columns @("Setting", "Value"))
  </section>

  <section class="section">
    <h2>Local proxy ports</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.PortRows -Columns @("Port", "Listening", "Owner", "HttpProxy", "Socks5Proxy"))
  </section>

  <section class="section">
    <h2>Connectivity</h2>
    $(Convert-ObjectListToHtmlTable -Rows $connectivityRows -Columns @("Test", "Success", "ExitCode"))
  </section>

  <section class="section">
    <h2>Network adapters</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.NetworkAdapters -Columns @("Interface", "Description", "IPv4", "IPv6", "Gateway", "DNS"))
  </section>

  <section class="section">
    <h2>Wi-Fi</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.WiFi -Columns @("Interface", "Description", "Status", "LinkSpeed", "MacAddress"))
  </section>

  <section class="section">
    <h2>DNS resolution</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.DnsRows -Columns @("Host", "Address", "Status"))
  </section>

  <section class="section">
    <h2>Proxy and VPN processes</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.ProcessRows -Columns @("Process", "PID"))
  </section>

  <section class="section">
    <h2>Proxy environment variables</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.EnvironmentRows -Columns @("Scope", "Name", "Value"))
  </section>

  <section class="section">
    <h2>IPv4 routes</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.RouteRows -Columns @("Destination", "NextHop", "Interface", "RouteMetric", "InterfaceMetric", "Store"))
  </section>

  <div class="footer">
    Generated by ProxyScope $($script:Version). This tool does not modify network settings.
  </div>
</div>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($Path, $html, [System.Text.UTF8Encoding]::new($false))
}

function Write-JsonReport {
    param(
        [string]$Path,
        [hashtable]$Data
    )

    $Data | ConvertTo-Json -Depth 8 | Set-Content -Path $Path -Encoding UTF8
}
