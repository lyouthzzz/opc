[CmdletBinding()]
param(
    [ValidateSet('', 'claude', 'codex', 'cursor', 'workbuddy', 'agents', 'all')]
    [string]$Target = '',

    [string]$Destination = '',
    [switch]$Force,
    [switch]$NoForce,
    [switch]$DryRun,
    [switch]$NoCommands,
    [switch]$CommandsOnly,
    [switch]$NonInteractive
)

# Native Windows copy installer for this repository's skills and commands.
# Existing different content is replaced by default and backed up first.
# Use NoForce only when automatic replacement is not wanted.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This installer is for Windows. Use install-skills.sh on macOS or Linux.'
}
if ($NoCommands -and $CommandsOnly) {
    throw 'NoCommands and CommandsOnly cannot be used together.'
}
if ($Force -and $NoForce) {
    throw 'Force and NoForce cannot be used together.'
}
if ([string]::IsNullOrWhiteSpace($Target) -and [string]::IsNullOrWhiteSpace($Destination)) {
    throw 'Choose an Agent target or a custom skills destination.'
}
if (-not [string]::IsNullOrWhiteSpace($Target) -and -not [string]::IsNullOrWhiteSpace($Destination)) {
    throw 'Use either Target or Destination, not both.'
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$skillsSource = Join-Path $repositoryRoot 'skills'
$commandsSource = Join-Path $repositoryRoot 'commands'
$userProfile = [System.Environment]::GetFolderPath('UserProfile')
$installSkills = -not $CommandsOnly
$installCommands = -not $NoCommands -and -not [string]::IsNullOrWhiteSpace($Target)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'

function New-Target {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Skills,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Commands
    )
    return [PSCustomObject]@{ Name = $Name; Skills = $Skills; Commands = $Commands }
}

function Get-KnownTarget {
    param([Parameter(Mandatory = $true)][string]$Name)

    switch ($Name) {
        'claude' { return New-Target 'Claude Code' (Join-Path $userProfile '.claude\skills') (Join-Path $userProfile '.claude\commands') }
        'codex' { return New-Target 'Codex' (Join-Path $userProfile '.codex\skills') (Join-Path $userProfile '.codex\prompts') }
        'cursor' { return New-Target 'Cursor' (Join-Path $userProfile '.cursor\skills-cursor') (Join-Path $userProfile '.cursor\commands') }
        'workbuddy' { return New-Target 'WorkBuddy' (Join-Path $userProfile '.workbuddy\skills') (Join-Path $userProfile '.workbuddy\commands') }
        'agents' { return New-Target 'Generic Agent' (Join-Path $userProfile '.agents\skills') (Join-Path $userProfile '.agents\commands') }
    }
}

function Get-FileMap {
    param([Parameter(Mandatory = $true)][string]$Path)

    $map = @{}
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $map[''] = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
        return $map
    }

    $root = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\')
    foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File) {
        $relative = $file.FullName.Substring($root.Length).TrimStart([char[]]'\/')
        $map[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    return $map
}

function Get-DifferenceSummary {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Existing
    )

    $sourceMap = Get-FileMap -Path $Source
    $existingMap = Get-FileMap -Path $Existing
    $added = 0
    $changed = 0
    $removed = 0

    foreach ($key in $sourceMap.Keys) {
        if (-not $existingMap.ContainsKey($key)) {
            $added++
        }
        elseif ($sourceMap[$key] -ne $existingMap[$key]) {
            $changed++
        }
    }
    foreach ($key in $existingMap.Keys) {
        if (-not $sourceMap.ContainsKey($key)) {
            $removed++
        }
    }

    return [PSCustomObject]@{
        IsSame = $added -eq 0 -and $changed -eq 0 -and $removed -eq 0
        Text = "$added new, $changed changed, $removed removed file(s)"
    }
}

function Install-One {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )

    $backup = $null
    if (Test-Path -LiteralPath $TargetPath) {
        $difference = Get-DifferenceSummary -Source $Source -Existing $TargetPath
        if ($difference.IsSame) {
            Write-Host "Current: $DisplayName"
            $script:currentCount++
            return
        }

        if ($DryRun) {
            Write-Host "Would update: $DisplayName ($($difference.Text))"
            return
        }
        if ($NoForce) {
            Write-Host "Skipped: $DisplayName ($($difference.Text))"
            $script:skippedCount++
            return
        }

        $backup = "$TargetPath.bak-opc-$timestamp"
        Move-Item -LiteralPath $TargetPath -Destination $backup
    }

    if ($DryRun) {
        Write-Host "Would install: $DisplayName"
        return
    }

    $parent = Split-Path -Parent $TargetPath
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    try {
        Copy-Item -LiteralPath $Source -Destination $TargetPath -Recurse
        Write-Host "Installed: $DisplayName"
        if ($null -ne $backup) {
            Write-Host "Backup created: $([System.IO.Path]::GetFileName($backup))"
            $script:backupCount++
        }
        $script:installedCount++
    }
    catch {
        if (Test-Path -LiteralPath $TargetPath) {
            Remove-Item -LiteralPath $TargetPath -Recurse -Force
        }
        if ($null -ne $backup -and (Test-Path -LiteralPath $backup)) {
            Move-Item -LiteralPath $backup -Destination $TargetPath
        }
        throw
    }
}

$targets = @()
if (-not [string]::IsNullOrWhiteSpace($Destination)) {
    $targets += New-Target 'Custom Agent' $Destination ''
}
elseif ($Target -eq 'all') {
    foreach ($name in @('claude', 'codex', 'cursor', 'workbuddy', 'agents')) {
        $targets += Get-KnownTarget -Name $name
    }
}
else {
    $targets += Get-KnownTarget -Name $Target
}

$script:installedCount = 0
$script:currentCount = 0
$script:skippedCount = 0
$script:backupCount = 0

foreach ($destinationTarget in $targets) {
    Write-Host "Agent: $($destinationTarget.Name)"

    if ($installSkills) {
        foreach ($skill in Get-ChildItem -LiteralPath $skillsSource -Directory) {
            if (-not (Test-Path -LiteralPath (Join-Path $skill.FullName 'SKILL.md') -PathType Leaf)) {
                continue
            }
            Install-One -Source $skill.FullName -TargetPath (Join-Path $destinationTarget.Skills $skill.Name) -DisplayName $skill.Name
        }
    }

    if ($installCommands -and -not [string]::IsNullOrWhiteSpace($destinationTarget.Commands)) {
        foreach ($command in Get-ChildItem -LiteralPath $commandsSource -File -Filter '*.md') {
            Install-One -Source $command.FullName -TargetPath (Join-Path $destinationTarget.Commands $command.Name) -DisplayName $command.Name
        }
    }
}

Write-Host "Installation summary: $installedCount installed, $currentCount current, $skippedCount skipped, $backupCount backed up."
