function Get-BilingualValue {
    param(
        [AllowNull()][object]$Value,
        [hashtable]$Translations
    )

    $english = if ($null -eq $Value) { "" } else { [string]$Value }
    $chinese = $english

    if ($Translations -and $Translations.ContainsKey($english)) {
        $chinese = [string]$Translations[$english]
    }
    elseif ($english -match "^Failed \((.+)\)$") {
        $chinese = "失败 ($($Matches[1]))"
    }
    elseif ($english -match "^Failed: (.+)$") {
        $chinese = "失败：$($Matches[1])"
    }

    return [PSCustomObject]@{
        English = $english
        Chinese = $chinese
    }
}

function Convert-ObjectListToHtmlTable {
    param(
        [object[]]$Rows,
        [string[]]$Columns,
        [hashtable]$ColumnTranslations,
        [hashtable]$ValueTranslations
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return '<div class="empty" data-en="No data found" data-zh="未找到数据">No data found</div>'
    }

    $header = ($Columns | ForEach-Object {
        $english = [string]$_
        $chinese = if ($ColumnTranslations -and $ColumnTranslations.ContainsKey($english)) {
            [string]$ColumnTranslations[$english]
        }
        else {
            $english
        }

        $englishSafe = ConvertTo-HtmlSafe $english
        $chineseSafe = ConvertTo-HtmlSafe $chinese
        "<th data-en=`"$englishSafe`" data-zh=`"$chineseSafe`">$englishSafe</th>"
    }) -join ""

    $bodyRows = foreach ($row in $Rows) {
        $cells = foreach ($column in $Columns) {
            $translated = Get-BilingualValue -Value $row.$column -Translations $ValueTranslations
            $englishSafe = ConvertTo-HtmlSafe $translated.English
            $chineseSafe = ConvertTo-HtmlSafe $translated.Chinese

            if ($translated.English -eq $translated.Chinese) {
                "<td>$englishSafe</td>"
            }
            else {
                "<td data-en=`"$englishSafe`" data-zh=`"$chineseSafe`">$englishSafe</td>"
            }
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
        [string]$Details,
        [string]$TitleZh = "",
        [string]$DetailsZh = ""
    )

    if ([string]::IsNullOrWhiteSpace($TitleZh)) {
        $TitleZh = $Title
    }

    if ([string]::IsNullOrWhiteSpace($DetailsZh)) {
        $DetailsZh = $Details
    }

    return [PSCustomObject]@{
        Severity  = $Severity
        Title     = $Title
        Details   = $Details
        TitleZh   = $TitleZh
        DetailsZh = $DetailsZh
    }
}

function Write-HtmlReport {
    param(
        [string]$Path,
        [hashtable]$Data
    )

    $severityTranslations = @{
        "Critical" = "严重"
        "Warning"  = "警告"
        "OK"       = "正常"
        "Info"     = "信息"
    }

    $columnTranslations = @{
        "Setting"         = "设置"
        "Value"           = "值"
        "Port"            = "端口"
        "Listening"       = "监听状态"
        "Owner"           = "占用进程"
        "HttpProxy"       = "HTTP 代理"
        "Socks5Proxy"     = "SOCKS5 代理"
        "Test"            = "测试"
        "Success"         = "成功"
        "ExitCode"        = "状态码"
        "Interface"       = "网络接口"
        "Description"     = "描述"
        "Gateway"         = "网关"
        "Status"          = "状态"
        "LinkSpeed"       = "连接速度"
        "MacAddress"      = "MAC 地址"
        "Host"            = "主机"
        "Address"         = "地址"
        "Process"         = "进程"
        "Scope"           = "范围"
        "Name"            = "名称"
        "Destination"     = "目标"
        "NextHop"         = "下一跳"
        "RouteMetric"     = "路由跃点"
        "InterfaceMetric" = "接口跃点"
        "Store"           = "存储"
    }

    $valueTranslations = @{
        "Proxy enabled"                    = "代理启用状态"
        "Proxy server"                     = "代理服务器"
        "Automatic configuration URL"      = "自动配置 URL"
        "Effective Baidu proxy"            = "百度实际使用代理"
        "Effective Google proxy"           = "Google 实际使用代理"
        "Direct Baidu"                     = "百度直连"
        "Direct Microsoft"                 = "Microsoft 直连"
        "Baidu through Windows proxy"      = "通过 Windows 代理访问百度"
        "Google through Windows proxy"     = "通过 Windows 代理访问 Google"
        "Enabled"                          = "已启用"
        "Disabled"                         = "已禁用"
        "Passed"                           = "通过"
        "Failed"                           = "失败"
        "True"                             = "是"
        "False"                            = "否"
        "Resolved"                         = "已解析"
        "No address records"               = "没有地址记录"
        "Not listening"                    = "未监听"
        "(not set)"                        = "未设置"
        "(unknown)"                        = "未知"
        "(none)"                           = "无"
        "Process"                          = "进程"
        "User"                             = "用户"
        "Machine"                          = "系统"
    }

    $findingsHtml = foreach ($finding in $Data.Findings) {
        $className = Get-SeverityClass $finding.Severity
        $severityZh = if ($severityTranslations.ContainsKey($finding.Severity)) {
            $severityTranslations[$finding.Severity]
        }
        else {
            $finding.Severity
        }

        $severityEnSafe = ConvertTo-HtmlSafe $finding.Severity
        $severityZhSafe = ConvertTo-HtmlSafe $severityZh
        $titleEnSafe = ConvertTo-HtmlSafe $finding.Title
        $titleZhSafe = ConvertTo-HtmlSafe $finding.TitleZh
        $detailsEnSafe = ConvertTo-HtmlSafe $finding.Details
        $detailsZhSafe = ConvertTo-HtmlSafe $finding.DetailsZh

        @"
<div class="finding $className">
  <div class="finding-badge" data-en="$severityEnSafe" data-zh="$severityZhSafe">$severityEnSafe</div>
  <div>
    <div class="finding-title" data-en="$titleEnSafe" data-zh="$titleZhSafe">$titleEnSafe</div>
    <div class="finding-details" data-en="$detailsEnSafe" data-zh="$detailsZhSafe">$detailsEnSafe</div>
  </div>
</div>
"@
    }

    $proxyStatusClass = if ($Data.Proxy.Enabled -eq 1) { "warning" } else { "ok" }
    $proxyStatusTextEn = if ($Data.Proxy.Enabled -eq 1) { "Enabled" } else { "Disabled" }
    $proxyStatusTextZh = if ($Data.Proxy.Enabled -eq 1) { "已启用" } else { "已禁用" }

    $directClass = if ($Data.DirectBaidu.Success) { "ok" } else { "critical" }
    $directTextEn = if ($Data.DirectBaidu.Success) { "Passed" } else { "Failed" }
    $directTextZh = if ($Data.DirectBaidu.Success) { "通过" } else { "失败" }

    $systemClass = if ($Data.SystemProxyBaidu.Success) { "ok" } else { "critical" }
    $systemTextEn = if ($Data.SystemProxyBaidu.Success) { "Passed" } else { "Failed" }
    $systemTextZh = if ($Data.SystemProxyBaidu.Success) { "通过" } else { "失败" }

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

    $overallTextEn = if ($criticalCount -gt 0) {
        "Action required"
    }
    elseif ($warningCount -gt 0) {
        "Review recommended"
    }
    else {
        "Healthy"
    }

    $overallTextZh = if ($criticalCount -gt 0) {
        "需要处理"
    }
    elseif ($warningCount -gt 0) {
        "建议检查"
    }
    else {
        "状态正常"
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
  font-family: "Segoe UI", "Microsoft YaHei UI", Inter, Arial, sans-serif;
}
.container {
  max-width: 1180px;
  margin: 0 auto;
  padding: 34px 22px 64px;
}
.hero {
  position: relative;
  background: linear-gradient(135deg, #111827, #374151);
  color: white;
  border-radius: 22px;
  padding: 30px;
  box-shadow: var(--shadow);
}
.language-switcher {
  position: absolute;
  top: 18px;
  right: 18px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px;
  border: 1px solid rgba(255,255,255,.18);
  border-radius: 10px;
  background: rgba(17,24,39,.42);
  backdrop-filter: blur(12px);
}
.language-button {
  border: 0;
  border-radius: 7px;
  padding: 7px 11px;
  background: transparent;
  color: #d1d5db;
  font: inherit;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
}
.language-button:hover {
  color: white;
  background: rgba(255,255,255,.08);
}
.language-button.active {
  color: #111827;
  background: white;
}
.hero-top {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  align-items: flex-start;
  padding-top: 36px;
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
  line-height: 1.6;
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
html[lang="zh-CN"] .card-label {
  text-transform: none;
  letter-spacing: .02em;
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
html[lang="zh-CN"] .finding-badge {
  text-transform: none;
  letter-spacing: .02em;
}
.finding.ok .finding-badge { color: var(--ok); }
.finding.warning .finding-badge { color: var(--warn); }
.finding.critical .finding-badge { color: var(--critical); }
.finding.info .finding-badge { color: var(--info); }
.finding-title { font-weight: 750; margin-bottom: 4px; }
.finding-details { color: #4b5563; line-height: 1.55; }
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
html[lang="zh-CN"] th {
  text-transform: none;
  letter-spacing: .01em;
}
td {
  font-size: 13px;
  color: #374151;
}
tr:last-child td { border-bottom: 0; }
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
  .hero { padding: 22px; }
  .hero-top { padding-top: 48px; }
  .finding { grid-template-columns: 1fr; }
  .language-switcher { top: 14px; right: 14px; }
}
</style>
</head>
<body>
<div class="container">
  <section class="hero">
    <div class="language-switcher" role="group" aria-label="Report language">
      <button type="button" class="language-button active" data-language="en">English</button>
      <button type="button" class="language-button" data-language="zh">中文</button>
    </div>

    <div class="hero-top">
      <div>
        <div class="eyebrow" data-en="Windows diagnostics" data-zh="Windows 网络诊断">Windows diagnostics</div>
        <h1>ProxyScope</h1>
        <div class="subtitle" data-en="A read-only diagnostic report for Windows proxy, DNS, routing, local proxy ports, and direct connectivity." data-zh="只读检测 Windows 系统代理、DNS、路由、本地代理端口和网络直连状态。">A read-only diagnostic report for Windows proxy, DNS, routing, local proxy ports, and direct connectivity.</div>
      </div>
      <div class="overall" data-en="$overallTextEn" data-zh="$overallTextZh">$overallTextEn</div>
    </div>

    <div class="meta">
      <span><span data-en="Version" data-zh="版本">Version</span> $($script:Version)</span>
      <span><span data-en="Generated" data-zh="生成时间">Generated</span> $($Data.Generated)</span>
      <span>$([System.Net.WebUtility]::HtmlEncode($Data.Computer))</span>
      <span><span data-en="Administrator" data-zh="管理员权限">Administrator</span> $($Data.Administrator)</span>
    </div>
  </section>

  <section class="cards">
    <div class="card $overallClass">
      <div class="card-label" data-en="Overall status" data-zh="总体状态">Overall status</div>
      <div class="card-value" data-en="$overallTextEn" data-zh="$overallTextZh">$overallTextEn</div>
    </div>
    <div class="card $proxyStatusClass">
      <div class="card-label" data-en="Windows proxy" data-zh="Windows 代理">Windows proxy</div>
      <div class="card-value" data-en="$proxyStatusTextEn" data-zh="$proxyStatusTextZh">$proxyStatusTextEn</div>
    </div>
    <div class="card $directClass">
      <div class="card-label" data-en="Direct access" data-zh="网络直连">Direct access</div>
      <div class="card-value" data-en="$directTextEn" data-zh="$directTextZh">$directTextEn</div>
    </div>
    <div class="card $systemClass">
      <div class="card-label" data-en="System proxy access" data-zh="系统代理访问">System proxy access</div>
      <div class="card-value" data-en="$systemTextEn" data-zh="$systemTextZh">$systemTextEn</div>
    </div>
  </section>

  <section class="section">
    <h2 data-en="Automatic diagnosis" data-zh="自动诊断">Automatic diagnosis</h2>
    <div class="findings">
      $($findingsHtml -join "`n")
    </div>
  </section>

  <section class="section">
    <h2 data-en="Windows proxy settings" data-zh="Windows 代理设置">Windows proxy settings</h2>
    $(Convert-ObjectListToHtmlTable -Rows $proxyRows -Columns @("Setting", "Value") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="Local proxy ports" data-zh="本地代理端口">Local proxy ports</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.PortRows -Columns @("Port", "Listening", "Owner", "HttpProxy", "Socks5Proxy") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="Connectivity" data-zh="网络连通性">Connectivity</h2>
    $(Convert-ObjectListToHtmlTable -Rows $connectivityRows -Columns @("Test", "Success", "ExitCode") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="Network adapters" data-zh="网络适配器">Network adapters</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.NetworkAdapters -Columns @("Interface", "Description", "IPv4", "IPv6", "Gateway", "DNS") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="Wi-Fi" data-zh="Wi-Fi">Wi-Fi</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.WiFi -Columns @("Interface", "Description", "Status", "LinkSpeed", "MacAddress") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="DNS resolution" data-zh="DNS 解析">DNS resolution</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.DnsRows -Columns @("Host", "Address", "Status") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="Proxy and VPN processes" data-zh="代理与 VPN 进程">Proxy and VPN processes</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.ProcessRows -Columns @("Process", "PID") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="Proxy environment variables" data-zh="代理环境变量">Proxy environment variables</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.EnvironmentRows -Columns @("Scope", "Name", "Value") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <section class="section">
    <h2 data-en="IPv4 routes" data-zh="IPv4 路由">IPv4 routes</h2>
    $(Convert-ObjectListToHtmlTable -Rows $Data.RouteRows -Columns @("Destination", "NextHop", "Interface", "RouteMetric", "InterfaceMetric", "Store") -ColumnTranslations $columnTranslations -ValueTranslations $valueTranslations)
  </section>

  <div class="footer" data-en="Generated by ProxyScope $($script:Version). This tool does not modify network settings." data-zh="由 ProxyScope $($script:Version) 生成。本工具不会修改任何网络设置。">
    Generated by ProxyScope $($script:Version). This tool does not modify network settings.
  </div>
</div>

<script>
(function () {
  var storageKey = "proxyscope-report-language";
  var buttons = document.querySelectorAll("[data-language]");

  function applyLanguage(language) {
    var selected = language === "zh" ? "zh" : "en";
    var attribute = selected === "zh" ? "data-zh" : "data-en";

    document.documentElement.lang = selected === "zh" ? "zh-CN" : "en";
    document.title = selected === "zh" ? "ProxyScope 诊断报告" : "ProxyScope Report";

    document.querySelectorAll("[data-en][data-zh]").forEach(function (element) {
      element.textContent = element.getAttribute(attribute);
    });

    buttons.forEach(function (button) {
      var active = button.getAttribute("data-language") === selected;
      button.classList.toggle("active", active);
      button.setAttribute("aria-pressed", active ? "true" : "false");
    });

    try {
      window.localStorage.setItem(storageKey, selected);
    }
    catch (error) {
    }
  }

  buttons.forEach(function (button) {
    button.addEventListener("click", function () {
      applyLanguage(button.getAttribute("data-language"));
    });
  });

  var initialLanguage = "en";

  try {
    var savedLanguage = window.localStorage.getItem(storageKey);

    if (savedLanguage === "en" || savedLanguage === "zh") {
      initialLanguage = savedLanguage;
    }
  }
  catch (error) {
  }

  applyLanguage(initialLanguage);
})();
</script>
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
