# Claude Code statusline installer.
#
# Copies statusline-command.ps1 into ~/.claude/ and patches settings.json so
# Claude Code calls it. Other settings keys are preserved.
#
# Requires PowerShell 7+ (uses ConvertFrom-Json -AsHashtable).
#
# Usage:
#   pwsh -NoProfile -File ./install.ps1
#
# Optional overrides (testing or non-default Claude layout):
#   pwsh -NoProfile -File ./install.ps1 -ClaudeDir C:/some/.claude

param(
    [string]$ClaudeDir = (Join-Path $env:USERPROFILE ".claude")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

$srcScript = Join-Path $PSScriptRoot "statusline-command.ps1"
$dstScript = Join-Path $ClaudeDir   "statusline-command.ps1"

if (-not (Test-Path $srcScript)) {
    throw "Cannot find $srcScript — run install.ps1 from the export folder."
}

Copy-Item -Path $srcScript -Destination $dstScript -Force
Write-Host "Wrote   $dstScript"

# Patch settings.json — preserve existing keys, replace only statusLine.
$settingsPath = Join-Path $ClaudeDir "settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
} else {
    $settings = [ordered]@{}
}

# Forward slashes keep the command portable across pwsh and bash.
$dstScriptFwd = $dstScript -replace '\\','/'
$settings.statusLine = [ordered]@{
    type            = "command"
    command         = "pwsh -NoProfile -File $dstScriptFwd"
    refreshInterval = 1
}

$settings | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsPath -Encoding UTF8
Write-Host "Patched $settingsPath"
Write-Host ""
Write-Host "statusLine block:"
$settings.statusLine | ConvertTo-Json
