# Security and Privacy

## Read-only behavior

ProxyScope is designed to inspect network state without modifying it

The application does not change:

- Windows system proxy settings
- WinHTTP proxy settings
- DNS servers
- Network adapters
- IPv4 or IPv6 routes
- Firewall rules
- Registry values
- Proxy application settings

## Report contents

Reports may include local diagnostic information such as:

- Computer name
- Windows username
- Local IP addresses
- Adapter names
- DNS server addresses
- Proxy addresses
- Process names and IDs
- Route information

Review reports before sharing them in a public issue

## Network requests

The tool may send diagnostic requests to:

- `https://www.baidu.com`
- `https://www.google.com`
- `http://www.msftconnecttest.com/connecttest.txt`

These requests are used only to compare direct and proxy connectivity

## Reporting a vulnerability

Open a private security advisory in the GitHub repository when possible

Do not include personal diagnostic reports in a public vulnerability report
