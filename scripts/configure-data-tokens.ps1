[CmdletBinding()]
param(
    [ValidateSet('All', 'Tdx', 'Iwencai')]
    [string]$Mode = 'All',

    [ValidateSet('User', 'Process')]
    [string]$Scope = 'User',

    [switch]$NoBrowser,
    [switch]$NonInteractive
)

# Windows-friendly token setup. Secrets are never printed or passed on the
# command line. The default User scope persists values for future Agent runs.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This setup wizard is for Windows. Use configure-data-tokens.sh on macOS or Linux.'
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Keep the script ASCII-compatible with Windows PowerShell 5.1 while showing
# bilingual labels in the native dialog.
$uiSave = '"\u5b89\u5168\u4fdd\u5b58 / Save"' | ConvertFrom-Json
$uiSkip = '"\u8df3\u8fc7 / Skip"' | ConvertFrom-Json
$uiCancel = '"\u53d6\u6d88 / Cancel"' | ConvertFrom-Json
$uiOpen = '"\u6253\u5f00\u83b7\u53d6\u9875\u9762 / Open page"' | ConvertFrom-Json
$uiTdxTitle = '"\u901a\u8fbe\u4fe1 API Key \u914d\u7f6e"' | ConvertFrom-Json
$uiIwencaiTitle = '"\u540c\u82b1\u987a\u95ee\u8d22 API Key \u914d\u7f6e"' | ConvertFrom-Json
$uiSetupTitle = '"OPC \u6570\u636e\u914d\u7f6e"' | ConvertFrom-Json

function Get-EnvironmentTarget {
    if ($Scope -eq 'Process') {
        return [System.EnvironmentVariableTarget]::Process
    }
    return [System.EnvironmentVariableTarget]::User
}

function Get-SavedValue {
    param([Parameter(Mandatory = $true)][string]$Name)

    $target = Get-EnvironmentTarget
    $value = [System.Environment]::GetEnvironmentVariable($Name, $target)
    if ([string]::IsNullOrWhiteSpace($value) -and $target -eq [System.EnvironmentVariableTarget]::User) {
        $value = [System.Environment]::GetEnvironmentVariable($Name, [System.EnvironmentVariableTarget]::Process)
    }
    return $value
}

function Save-EnvironmentValue {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Contains("`r") -or $Value.Contains("`n")) {
        throw "$Name is empty or contains an invalid line break."
    }

    $target = Get-EnvironmentTarget
    [System.Environment]::SetEnvironmentVariable($Name, $Value, $target)
    [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Process)
}

function Open-SetupPage {
    param([Parameter(Mandatory = $true)][string]$Url)

    if (-not $NoBrowser) {
        Start-Process $Url | Out-Null
    }
}

function Read-SecretFromDialog {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$Url
    )

    if ($NonInteractive) {
        return [PSCustomObject]@{ Status = 'Missing'; Secret = $null }
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.Size = New-Object System.Drawing.Size(570, 245)
    $form.MinimumSize = $form.Size
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(22, 20)
    $label.Size = New-Object System.Drawing.Size(510, 70)
    $label.Text = $Message

    $input = New-Object System.Windows.Forms.TextBox
    $input.Location = New-Object System.Drawing.Point(25, 98)
    $input.Size = New-Object System.Drawing.Size(505, 25)
    $input.UseSystemPasswordChar = $true

    $open = New-Object System.Windows.Forms.Button
    $open.Location = New-Object System.Drawing.Point(25, 145)
    $open.Size = New-Object System.Drawing.Size(165, 32)
    $open.Text = $uiOpen
    $open.Enabled = -not $NoBrowser
    $open.Add_Click({ Open-SetupPage -Url $Url })

    $save = New-Object System.Windows.Forms.Button
    $save.Location = New-Object System.Drawing.Point(200, 145)
    $save.Size = New-Object System.Drawing.Size(110, 32)
    $save.Text = $uiSave
    $save.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $skip = New-Object System.Windows.Forms.Button
    $skip.Location = New-Object System.Drawing.Point(320, 145)
    $skip.Size = New-Object System.Drawing.Size(90, 32)
    $skip.Text = $uiSkip
    $skip.DialogResult = [System.Windows.Forms.DialogResult]::Ignore

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Location = New-Object System.Drawing.Point(420, 145)
    $cancel.Size = New-Object System.Drawing.Size(110, 32)
    $cancel.Text = $uiCancel
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $form.Controls.Add($label)
    $form.Controls.Add($input)
    $form.Controls.Add($open)
    $form.Controls.Add($save)
    $form.Controls.Add($skip)
    $form.Controls.Add($cancel)
    $form.AcceptButton = $save
    $form.CancelButton = $cancel
    $form.Add_Shown({ $input.Focus() })

    try {
        $result = $form.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::Ignore) {
            return [PSCustomObject]@{ Status = 'Skipped'; Secret = $null }
        }
        if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
            return [PSCustomObject]@{ Status = 'Cancelled'; Secret = $null }
        }
        $secret = $input.Text.Trim()
        $input.Clear()
        if ([string]::IsNullOrWhiteSpace($secret)) {
            return [PSCustomObject]@{ Status = 'Missing'; Secret = $null }
        }
        return [PSCustomObject]@{ Status = 'Configured'; Secret = $secret }
    }
    finally {
        $form.Dispose()
    }
}

function Configure-Secret {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$Url
    )

    $saved = Get-SavedValue -Name $Name
    if (-not [string]::IsNullOrWhiteSpace($saved)) {
        Save-EnvironmentValue -Name $Name -Value $saved
        $saved = $null
        return 'Configured'
    }

    $result = Read-SecretFromDialog -Title $Title -Message $Message -Url $Url
    if ($result.Status -ne 'Configured') {
        return $result.Status
    }

    Save-EnvironmentValue -Name $Name -Value $result.Secret
    $result.Secret = $null
    return 'Configured'
}

$tdxRequested = $Mode -eq 'All' -or $Mode -eq 'Tdx'
$iwencaiRequested = $Mode -eq 'All' -or $Mode -eq 'Iwencai'

$tdxResult = 'NotRequested'
$iwencaiResult = 'NotRequested'

if ($tdxRequested) {
    $tdxResult = Configure-Secret `
        -Name 'TDX_API_KEY' `
        -Title $uiTdxTitle `
        -Message 'This source is optional. Choose Skip, or open the TDX page, copy the API Key, and paste it below. Your input is hidden.' `
        -Url 'https://www.tdx.com.cn'
}

if ($iwencaiRequested) {
    $iwencaiResult = Configure-Secret `
        -Name 'IWENCAI_API_KEY' `
        -Title $uiIwencaiTitle `
        -Message 'This source is optional. Choose Skip, or open iWencai SkillHub, copy the API Key, and paste it below. Your input is hidden.' `
        -Url 'https://www.iwencai.com/skillhub'
    if ($iwencaiResult -eq 'Configured') {
        Save-EnvironmentValue -Name 'IWENCAI_BASE_URL' -Value 'https://openapi.iwencai.com'
    }
}

$tdxConfigured = -not [string]::IsNullOrWhiteSpace((Get-SavedValue -Name 'TDX_API_KEY'))
$baseConfigured = (Get-SavedValue -Name 'IWENCAI_BASE_URL') -eq 'https://openapi.iwencai.com'
$iwencaiConfigured = -not [string]::IsNullOrWhiteSpace((Get-SavedValue -Name 'IWENCAI_API_KEY'))

function Get-StatusLabel {
    param(
        [Parameter(Mandatory = $true)][string]$Result,
        [Parameter(Mandatory = $true)][bool]$Configured
    )

    if ($Result -eq 'Skipped') { return 'skipped (Agent default data and search)' }
    if ($Result -eq 'Cancelled') { return 'cancelled' }
    if ($Configured) { return 'configured' }
    return 'missing'
}

$tdxLabel = Get-StatusLabel -Result $tdxResult -Configured $tdxConfigured
$iwencaiLabel = Get-StatusLabel -Result $iwencaiResult -Configured $iwencaiConfigured
$baseLabel = if ($iwencaiResult -eq 'Skipped') { 'skipped' } elseif ($iwencaiResult -eq 'Cancelled') { 'cancelled' } elseif ($baseConfigured) { 'configured' } else { 'missing' }

$statusLines = @(
    "TDX_API_KEY: $tdxLabel"
    "IWENCAI_BASE_URL: $baseLabel"
    "IWENCAI_API_KEY: $iwencaiLabel"
)
$statusText = $statusLines -join [Environment]::NewLine

Write-Host $statusText

$tdxHandled = -not $tdxRequested -or $tdxResult -in @('Configured', 'Skipped')
$iwencaiHandled = -not $iwencaiRequested -or $iwencaiResult -in @('Configured', 'Skipped')
$requestedHandled = $tdxHandled -and $iwencaiHandled

if (-not $NonInteractive) {
    $icon = if ($requestedHandled) {
        [System.Windows.Forms.MessageBoxIcon]::Information
    }
    else {
        [System.Windows.Forms.MessageBoxIcon]::Warning
    }
    [System.Windows.Forms.MessageBox]::Show(
        $statusText + [Environment]::NewLine + [Environment]::NewLine + 'Configured sources load after restart. Skipped sources are optional and do not block the skills.',
        $uiSetupTitle,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $icon
    ) | Out-Null
}

if (-not $requestedHandled) {
    exit 2
}
