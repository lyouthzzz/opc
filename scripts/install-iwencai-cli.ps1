[CmdletBinding()]
param(
    [switch]$Force
)

# Native Windows installer for the official iWencai SkillHub CLI package.
# It downloads only from iwencai.com, validates archive paths, and does not
# execute the Unix installer included in the package.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This installer is for Windows.'
}

$officialZipUrl = 'https://www.iwencai.com/skillhub/static/0.0.4/iwencai-skillhub-cli.zip'
$userProfile = [System.Environment]::GetFolderPath('UserProfile')
$installBase = Join-Path $userProfile '.iwencai-skillhub'
$binDirectory = Join-Path $userProfile '.local\bin'
$wrapperTarget = Join-Path $binDirectory 'iwencai-skillhub-cli.cmd'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'

function Find-PythonLauncher {
    $candidates = @(
        [PSCustomObject]@{ Name = 'py'; Prefix = @('-3') },
        [PSCustomObject]@{ Name = 'python'; Prefix = @() },
        [PSCustomObject]@{ Name = 'python3'; Prefix = @() }
    )

    foreach ($candidate in $candidates) {
        $command = Get-Command $candidate.Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $command) {
            continue
        }

        try {
            $version = & $command.Source @($candidate.Prefix) -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>$null
            if ($LASTEXITCODE -ne 0) {
                continue
            }
            $parts = ([string]$version).Trim().Split('.')
            $major = [int]$parts[0]
            $minor = [int]$parts[1]
            if ($major -gt 3 -or ($major -eq 3 -and $minor -ge 8)) {
                return $candidate
            }
        }
        catch {
            continue
        }
    }

    throw 'Python 3.8 or newer is required. Install Python from python.org, then ask the Agent to continue.'
}

function Add-UserPathEntry {
    param([Parameter(Mandatory = $true)][string]$Directory)

    $userPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
    $entries = @()
    if (-not [string]::IsNullOrWhiteSpace($userPath)) {
        $entries = $userPath.Split(';') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    $alreadyPresent = $false
    foreach ($entry in $entries) {
        if ($entry.TrimEnd('\') -ieq $Directory.TrimEnd('\')) {
            $alreadyPresent = $true
            break
        }
    }

    if (-not $alreadyPresent) {
        $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $Directory } else { "$userPath;$Directory" }
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, [System.EnvironmentVariableTarget]::User)
    }

    $processEntries = $env:Path.Split(';')
    if (-not ($processEntries | Where-Object { $_.TrimEnd('\') -ieq $Directory.TrimEnd('\') })) {
        $env:Path = "$env:Path;$Directory"
    }
}

$existingCommand = Get-Command 'iwencai-skillhub-cli' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $existingCommand -and -not $Force) {
    Write-Host 'iWencai SkillHub CLI: already installed'
    exit 0
}

$python = Find-PythonLauncher
$tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('opc-iwencai-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempDirectory 'iwencai-skillhub-cli.zip'
$extractDirectory = Join-Path $tempDirectory 'extracted'
$installBackup = $null
$wrapperBackup = $null
$installCreated = $false
$wrapperCreated = $false

try {
    New-Item -ItemType Directory -Path $tempDirectory, $extractDirectory -Force | Out-Null
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $officialZipUrl -OutFile $zipPath -UseBasicParsing

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName.Replace('\', '/')
            if ([System.IO.Path]::IsPathRooted($name) -or $name -match '(^|/)\.\.(/|$)' -or $name -match '^[A-Za-z]:') {
                throw 'The official package contains an unsafe archive path. Installation stopped.'
            }
        }
    }
    finally {
        $archive.Dispose()
    }

    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDirectory -Force
    $entryScript = Get-ChildItem -LiteralPath $extractDirectory -Recurse -File -Filter 'aime_skillhub_cli.py' | Select-Object -First 1
    if ($null -eq $entryScript) {
        throw 'The official package does not contain aime_skillhub_cli.py.'
    }

    $packageRoot = $entryScript.Directory.FullName
    $cliSource = Join-Path $packageRoot 'cli'
    $officialInstallScript = Join-Path $packageRoot 'iwencai-install.sh'
    if (-not (Test-Path -LiteralPath $cliSource -PathType Container) -or -not (Test-Path -LiteralPath $officialInstallScript -PathType Leaf)) {
        throw 'The official package layout is incomplete. Installation stopped.'
    }

    if (Test-Path -LiteralPath $installBase) {
        if (-not $Force) {
            throw 'An existing iWencai CLI installation was found. Confirm an update, then run this installer with Force.'
        }
        $installBackup = "$installBase.bak-opc-$timestamp"
        Move-Item -LiteralPath $installBase -Destination $installBackup
    }
    if (Test-Path -LiteralPath $wrapperTarget) {
        if (-not $Force) {
            throw 'An existing iWencai CLI launcher was found. Confirm an update, then run this installer with Force.'
        }
        $wrapperBackup = "$wrapperTarget.bak-opc-$timestamp"
        Move-Item -LiteralPath $wrapperTarget -Destination $wrapperBackup
    }

    New-Item -ItemType Directory -Path $installBase, $binDirectory -Force | Out-Null
    $installCreated = $true
    Copy-Item -LiteralPath $entryScript.FullName -Destination (Join-Path $installBase 'aime_skillhub_cli.py')
    Copy-Item -LiteralPath $cliSource -Destination $installBase -Recurse

    $commandPrefix = if ($python.Prefix.Count -gt 0) { "$($python.Name) $($python.Prefix -join ' ')" } else { $python.Name }
    $wrapperContent = @"
@echo off
setlocal
$commandPrefix "%USERPROFILE%\.iwencai-skillhub\aime_skillhub_cli.py" %*
"@
    $wrapperCreated = $true
    [System.IO.File]::WriteAllText($wrapperTarget, $wrapperContent, [System.Text.Encoding]::ASCII)

    Add-UserPathEntry -Directory $binDirectory
    & $wrapperTarget --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'The iWencai CLI verification failed.'
    }

    Write-Host 'iWencai SkillHub CLI: installed from the official package'
    if ($null -ne $installBackup -or $null -ne $wrapperBackup) {
        Write-Host 'Previous installation: backed up'
    }
}
catch {
    if ($installCreated -and (Test-Path -LiteralPath $installBase)) {
        Remove-Item -LiteralPath $installBase -Recurse -Force
    }
    if ($wrapperCreated -and (Test-Path -LiteralPath $wrapperTarget)) {
        Remove-Item -LiteralPath $wrapperTarget -Force
    }
    if ($null -ne $installBackup -and (Test-Path -LiteralPath $installBackup)) {
        Move-Item -LiteralPath $installBackup -Destination $installBase
    }
    if ($null -ne $wrapperBackup -and (Test-Path -LiteralPath $wrapperBackup)) {
        Move-Item -LiteralPath $wrapperBackup -Destination $wrapperTarget
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $tempDirectory) {
        Remove-Item -LiteralPath $tempDirectory -Recurse -Force
    }
}
