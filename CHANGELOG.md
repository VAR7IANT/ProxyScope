# ProxyScope Changelog

## 4.1.1

- Fixed language buttons not responding in some local HTML browser environments
- Removed reliance on `NodeList.forEach` and forced `classList.toggle` behavior
- Added direct button click fallback through `window.ProxyScopeSetLanguage`
- Added compatibility for both `textContent` and `innerText`
- Raised the language switcher stacking level to prevent invisible click blocking

## 4.1.0

- Added an English and Simplified Chinese language selector to the HTML report
- Kept English as the default report language
- Added a top-right language switcher
- Added local language preference persistence through browser `localStorage`
- Added Chinese translations for report sections, status cards, table headers, common values, severity badges, and automatic diagnosis findings
- Kept technical addresses, ports, process names, and route values unchanged for accurate troubleshooting
- Updated the README and report typography for bilingual display

## 4.0.0

- Added a graphical Windows interface
- Added a responsive HTML report
- Added JSON report output
- Added automatic severity-based diagnosis
- Added proxy port owner detection
- Added HTTP and SOCKS5 capability checks
- Improved Wi-Fi adapter detection
- Removed localized `netsh` output from the main report
- Added repository documentation and MIT license
- Added command-line mode

## 3.1.0

- Added English report output
- Added automatic diagnosis
- Added proxy process, route, DNS, and adapter checks
