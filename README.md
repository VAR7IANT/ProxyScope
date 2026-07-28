# ProxyScope

A lightweight, read-only Windows diagnostic utility for proxy settings, DNS, local proxy ports, routes, adapters, and direct connectivity

## Highlights

- Clean graphical interface
- English-only application text
- Responsive HTML report with status cards
- Automatic diagnosis with severity labels
- Local HTTP and SOCKS5 proxy tests
- Windows system proxy request tests
- DNS and direct connectivity checks
- Network adapter, Wi-Fi, process, environment, and route inspection
- JSON report for issue templates and automated analysis
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
5. Review the generated HTML report

Reports are saved to:

```text
Desktop\ProxyScopeReports
```

Each scan creates:

```text
proxy_network_report_YYYYMMDD_HHMMSS.html
proxy_network_report_YYYYMMDD_HHMMSS.json
```

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
│   └── ProxyScope.ps1
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
