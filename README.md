# ProxyScope

A lightweight, read-only Windows diagnostic utility for proxy settings, DNS, local proxy ports, routes, adapters, and direct connectivity

## Highlights

- Premium desktop interface with live scan status and summary cards
- Clear counts for critical findings, warnings, and passed checks
- Dedicated activity log, report-path panel, and quick actions
- English-first application and repository files
- Bilingual HTML report with **English** and **中文**
- English is the default report language
- Top-right report language switch remembers the user's local choice
- Responsive HTML report with status cards
- Automatic diagnosis with bilingual severity labels and explanations
- Local HTTP and SOCKS5 proxy tests
- Windows system proxy request tests
- DNS and direct connectivity checks
- Network adapter, Wi-Fi, process, environment, and route inspection
- JSON report for issue templates and automated analysis
- Windows PowerShell 5.1 syntax validation in GitHub Actions
- No changes to proxy, DNS, route, adapter, firewall, or registry settings

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1
- Administrator permission
- `curl.exe`, included with current Windows versions

## Usage

1. Download or clone the repository
2. Double-click `Run ProxyScope.bat`
3. Accept the administrator prompt
4. Select **Run diagnosis**
5. Review the live status cards and generated HTML report
6. Use the **English / 中文** selector in the top-right corner of the report

Reports are saved to:

```text
Desktop\ProxyScopeReports
```

Each scan creates:

```text
proxy_network_report_YYYYMMDD_HHMMSS.html
proxy_network_report_YYYYMMDD_HHMMSS.json
```

The HTML report stores the selected display language locally in the browser

No language preference is uploaded or written to the Windows registry

## Command-line mode

Run the PowerShell script with `-Cli`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\src\ProxyScope.ps1" -Cli
```

## What the utility checks

- Windows user proxy configuration
- Effective proxy used for selected URLs
- Local ports `10808`, `10809`, and configured proxy ports
- HTTP and SOCKS5 support on each local proxy port
- Owning process for listening proxy ports
- Proxy and VPN-related processes
- Process, user, and machine proxy environment variables
- Network adapter addresses, gateways, and DNS servers
- Wi-Fi adapter state and link speed
- DNS resolution for Baidu and Google
- Forced direct access to Baidu and Microsoft connectivity test
- Requests through the Windows system proxy
- Important IPv4 routes
- Persistent Radmin-style default-route warnings

## Privacy

The utility runs entirely on the local computer

It does not upload reports, credentials, browser data, traffic contents, or personal files

The generated report may contain:

- Computer name
- Windows username
- Local IP addresses
- Network adapter names
- Process names and process IDs
- Proxy addresses
- DNS servers
- Route information

Review a report before posting it publicly

## Repository structure

```text
ProxyScope
├── Run ProxyScope.bat
├── src
│   ├── ProxyScope.ps1
│   └── modules
│       ├── Common.ps1
│       ├── Network.ps1
│       ├── Report.ps1
│       ├── ReportCompatibility.ps1
│       ├── Diagnosis.ps1
│       └── UI.ps1
├── .github
│   └── workflows
│       └── powershell-validation.yml
├── docs
│   └── SECURITY_AND_PRIVACY.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Safety

This project is diagnostic only

It does not automatically repair or modify network settings

## License

MIT
