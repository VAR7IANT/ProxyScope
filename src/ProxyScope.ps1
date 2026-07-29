param(
    [switch]$Cli
)

$ErrorActionPreference = "Continue"
$script:AppName = "ProxyScope"
$script:Version = "4.1.0"
$script:LatestReport = $null

$moduleRoot = Join-Path $PSScriptRoot "modules"

foreach ($moduleName in "Common.ps1", "Network.ps1", "Report.ps1", "Diagnosis.ps1", "UI.ps1") {
    $modulePath = Join-Path $moduleRoot $moduleName

    if (-not (Test-Path $modulePath)) {
        throw "Required module not found: $modulePath"
    }

    . $modulePath
}

if ($Cli) {
    Start-CliMode
}
else {
    Start-GuiMode
}
