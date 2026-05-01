# Claude Code status line — reads JSON from stdin
# Layout (multi-line):
#   Line 1: spinner  cwd | branch (or (branch wt:wt)) | session_name | +N dirs
#   Line 2: model | effort | thinking | context-bar
#   Line 3: 5hr:N% | 7d:N% | clock | +X -Y

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$inputJson = [Console]::In.ReadToEnd()
try {
    $data = $inputJson | ConvertFrom-Json
} catch {
    exit 0
}

# ---------------------------------------------------------------------------
# Data extraction — every field guarded against null/absent
# ---------------------------------------------------------------------------
$cwd          = if ($data.workspace.current_dir) { $data.workspace.current_dir } elseif ($data.cwd) { $data.cwd } else { "" }
$model        = if ($data.model.display_name)    { $data.model.display_name }    else { "" }
$sessionName  = if ($data.session_name)          { $data.session_name }          else { "" }
$effortLevel  = if ($data.effort.level)          { $data.effort.level }          else { "" }
$thinkEnabled = if ($null -ne $data.thinking -and $data.thinking.enabled -eq $true) { $true } else { $false }
$usedPct      = if ($null -ne $data.context_window -and $null -ne $data.context_window.used_percentage) {
                    $data.context_window.used_percentage
                } else { $null }
$rl5h         = if ($null -ne $data.rate_limits -and $null -ne $data.rate_limits.five_hour) {
                    $data.rate_limits.five_hour.used_percentage
                } else { $null }
$rl7d         = if ($null -ne $data.rate_limits -and $null -ne $data.rate_limits.seven_day) {
                    $data.rate_limits.seven_day.used_percentage
                } else { $null }
$linesAdded   = if ($null -ne $data.cost -and $null -ne $data.cost.total_lines_added)   { [int]$data.cost.total_lines_added }   else { 0 }
$linesRemoved = if ($null -ne $data.cost -and $null -ne $data.cost.total_lines_removed) { [int]$data.cost.total_lines_removed } else { 0 }
$addedDirs    = if ($null -ne $data.workspace -and $null -ne $data.workspace.added_dirs) { @($data.workspace.added_dirs).Count } else { 0 }
$wtName       = if ($data.worktree.branch)              { $data.worktree.branch }
                elseif ($data.workspace.git_worktree)   { $data.workspace.git_worktree }
                else { "" }

# ---------------------------------------------------------------------------
# Current directory — full path
# ---------------------------------------------------------------------------
$shortDir = $cwd

# ---------------------------------------------------------------------------
# Git branch (GIT_OPTIONAL_LOCKS=0 prevents lock-file creation)
# When inside a linked worktree, render as "(<branch> wt:<wtBranch>)"
# ---------------------------------------------------------------------------
$branch = ""
if ($cwd -and (Test-Path $cwd)) {
    $env:GIT_OPTIONAL_LOCKS = "0"
    $gitRef = git -C $cwd symbolic-ref --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitRef) {
        $branch = $gitRef.Trim()
    } else {
        $gitHash = git -C $cwd rev-parse --short HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitHash) {
            $branch = "@" + $gitHash.Trim()
        }
    }
    Remove-Item Env:\GIT_OPTIONAL_LOCKS -ErrorAction SilentlyContinue
}
if ($branch -and $wtName) {
    $branch = "($branch wt:$wtName)"
}

# ---------------------------------------------------------------------------
# Context progress bar  ▓▓▓▓░░░░░░ 42%
# Only rendered after first API call (used_percentage is null pre-call)
# ---------------------------------------------------------------------------
$ctxPart = ""
if ($null -ne $usedPct) {
    $usedInt = [int][Math]::Round($usedPct)
    $filled  = [int]($usedInt / 10)
    $empty   = 10 - $filled
    $bar     = ("▓" * $filled) + ("░" * $empty)
    $ctxPart = "$bar $usedInt%"
}

# ---------------------------------------------------------------------------
# ANSI colors
# ---------------------------------------------------------------------------
$C_DIR     = "`e[0;36m"   # cyan        — cwd
$C_BRANCH  = "`e[0;33m"   # yellow      — git branch
$C_MODEL   = "`e[0;35m"   # magenta     — model
$C_CTX     = "`e[0;32m"   # green       — context bar
$C_SESSION = "`e[1;37m"   # bold white  — session name
$C_EFFORT  = "`e[0;34m"   # blue        — effort level
$C_THINK   = "`e[0;33m"   # yellow      — thinking flag
$C_RATE    = "`e[0;31m"   # red         — rate limits
$C_SPIN    = "`e[0;36m"   # cyan        — spinner
$C_DIFF_A  = "`e[0;32m"   # green       — lines added
$C_DIFF_R  = "`e[0;31m"   # red         — lines removed
$C_DIRS    = "`e[0;34m"   # blue        — added dirs count
$C_CLOCK   = "`e[2;37m"   # dim white   — clock
$C_SEP     = "`e[2m"      # dim         — separator
$C_RST     = "`e[0m"

$SEP = "${C_SEP} | ${C_RST}"

# ---------------------------------------------------------------------------
# Decorative spinner — frame chosen by wall-clock second.
# Animates at 1Hz when settings.json has refreshInterval set; otherwise
# advances only at message boundaries. Not a real "loading" indicator.
# ---------------------------------------------------------------------------
$spinFrames = @('◐','◓','◑','◒')
$spinner = $spinFrames[(Get-Date).Second % $spinFrames.Count]

# ---------------------------------------------------------------------------
# Diff stats, added-dirs count, wall clock
# ---------------------------------------------------------------------------
$diffPart = ""
if ($linesAdded -gt 0 -or $linesRemoved -gt 0) {
    $diffPart = "${C_DIFF_A}+${linesAdded}${C_RST} ${C_DIFF_R}-${linesRemoved}${C_RST}"
}

$dirsPart = ""
if ($addedDirs -gt 0) {
    $dirsPart = "${C_DIRS}+${addedDirs} dirs${C_RST}"
}

$clockPart = "${C_CLOCK}$((Get-Date).ToString('HH:mm'))${C_RST}"

# ---------------------------------------------------------------------------
# Helper: join array with SEP
# ---------------------------------------------------------------------------
function Join-Parts {
    param([string[]]$Parts)
    return ($Parts | Where-Object { $_ -ne "" }) -join $SEP
}

# ---------------------------------------------------------------------------
# Line 1: spinner cwd | git-branch | session_name (if set) | +N dirs
# ---------------------------------------------------------------------------
$line1Parts = @()
if ($shortDir)    { $line1Parts += "${C_DIR}${shortDir}${C_RST}" }
if ($branch)      { $line1Parts += "${C_BRANCH}${branch}${C_RST}" }
if ($sessionName) { $line1Parts += "${C_SESSION}${sessionName}${C_RST}" }
if ($dirsPart)    { $line1Parts += $dirsPart }
$line1 = "${C_SPIN}${spinner}${C_RST} " + (Join-Parts $line1Parts)

# ---------------------------------------------------------------------------
# Line 2: model | effort:level | think:on | context-bar
# ---------------------------------------------------------------------------
$line2Parts = @()
if ($model)        { $line2Parts += "${C_MODEL}${model}${C_RST}" }
if ($effortLevel)  { $line2Parts += "${C_EFFORT}effort:${effortLevel}${C_RST}" }
if ($thinkEnabled) { $line2Parts += "${C_THINK}think:on${C_RST}" }
if ($ctxPart)      { $line2Parts += "${C_CTX}${ctxPart}${C_RST}" }
$line2 = Join-Parts $line2Parts

# ---------------------------------------------------------------------------
# Line 3: 5hr:N% | 7d:N% | clock | +X -Y
# Clock always present so line 3 always renders.
# ---------------------------------------------------------------------------
$line3Parts = @()
if ($null -ne $rl5h) { $line3Parts += "${C_RATE}5hr:$([int][Math]::Round($rl5h))%${C_RST}" }
if ($null -ne $rl7d) { $line3Parts += "${C_RATE}7d:$([int][Math]::Round($rl7d))%${C_RST}" }
$line3Parts += $clockPart
if ($diffPart)     { $line3Parts += $diffPart }
$line3 = Join-Parts $line3Parts

# ---------------------------------------------------------------------------
# Print — skip empty lines, insert a blank line between rendered lines
# ---------------------------------------------------------------------------
$rendered = @($line1, $line2, $line3) | Where-Object { $_ }
for ($i = 0; $i -lt $rendered.Count; $i++) {
    if ($i -gt 0) { Write-Host "" }
    Write-Host $rendered[$i]
}
