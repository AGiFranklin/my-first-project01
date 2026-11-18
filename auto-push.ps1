$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location -LiteralPath $ProjectRoot

$watchFolder = $ProjectRoot
$filter = '*.*'

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchFolder
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$script:pending = $false
$script:timer = New-Object System.Timers.Timer
$script:timer.Interval = 2000
$script:timer.AutoReset = $false
$script:timer.Add_Elapsed({
    $script:timer.Stop()
    if ($script:pending) {
        $script:pending = $false
        try {
            & git add .
            $status = & git status --porcelain
            if ($status) {
                & git commit -m "auto update: auto-sync of changed files"
                & git push origin main
                Write-Host "Pushed to GitHub ✅"
            } else {
                Write-Host "No changes to commit."
            }
        } catch {
            Write-Host "Auto-push failed: $($_.Exception.Message)"
        }
    }
})

$action = {
    $script:pending = $true
    if (-not $script:timer.Enabled) {
        $script:timer.Start()
    }
}

Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action

Write-Host "Auto-push watcher started on $watchFolder"
Write-Host "Press Ctrl+C to stop."
while ($true) { Start-Sleep -Seconds 3600 }
