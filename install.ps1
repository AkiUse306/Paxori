param(
    [switch]$Uninstall,
    [switch]$Update,
    [switch]$Global,
    [switch]$User,
    [string]$Version = "1.0.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $current = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($Global -and $User) {
    throw "Cannot specify both -Global and -User."
}

$IsAdministrator = Test-IsAdministrator

$AppName      = "Paxori"
$AppVersion   = $Version
$InstallDir   = if ($User) {
    Join-Path $HOME '.paxori'
} elseif ($Global -or $IsAdministrator) {
    "C:\Program Files\Paxori"
} else {
    Join-Path $HOME '.paxori'
}
$LogDir       = "C:\ProgramData\Paxori"
$LogFile      = "$LogDir\install.log"
$ReleaseOwner = "AkiUse306"
$ReleaseRepo  = "Paxori"
$AssetName    = "paxori-$AppVersion-windows.zip"
$ReleaseUrl   = "https://github.com/AkiUse306/Paxori/releases/download/1.0.0/paxori-1.0.0-windows.msi"
$AssetHash    = "sha256:5bbe4ecae6c61315a18f88956b2bbb54b8d44ca35fa5bde30204da0756d8cc0a"
$TempArchive  = "$env:TEMP\paxori-$AppVersion.zip"
$UninstallRegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $time  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line  = "[$time] [$Level] $Message"

    switch ($Level) {
        "INFO"  { Write-Host $line -ForegroundColor Cyan }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "OK"    { Write-Host $line -ForegroundColor Green }
        default  { Write-Host $line }
    }

    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    Add-Content -Path $LogFile -Value $line
}

function Get-InstalledVersion {
    if (Test-Path $UninstallRegPath) {
        return (Get-ItemProperty $UninstallRegPath -ErrorAction SilentlyContinue).DisplayVersion
    }
    return $null
}

function Check-Version {
    $installed = Get-InstalledVersion
    if ($installed) {
        Write-Log "Detected installed version: $installed"

        if ([version]$installed -ge [version]$AppVersion -and -not $Update) {
            Write-Log "$AppName is already up to date." "OK"
            Write-Host "`n$AppName is already installed and up to date." -ForegroundColor Green
            return $false
        }

        Write-Log "Older version detected. Proceeding with upgrade." "WARN"
    }
    return $true
}

function Register-UninstallEntry {
    if (!(Test-Path $UninstallRegPath)) {
        New-Item -Path $UninstallRegPath -Force | Out-Null
    }

    Set-ItemProperty -Path $UninstallRegPath -Name "DisplayName" -Value $AppName
    Set-ItemProperty -Path $UninstallRegPath -Name "DisplayVersion" -Value $AppVersion
    Set-ItemProperty -Path $UninstallRegPath -Name "Publisher" -Value "AkiUse306"
    Set-ItemProperty -Path $UninstallRegPath -Name "InstallLocation" -Value $InstallDir
    Set-ItemProperty -Path $UninstallRegPath -Name "UninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -File `"$InstallDir\\uninstall.ps1`""
}

function Create-UninstallScript {
    $scriptPath = Join-Path $InstallDir 'uninstall.ps1'
    @"
param()

Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'

Remove-Item -LiteralPath '$InstallDir' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path '$UninstallRegPath' -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Paxori has been uninstalled.' -ForegroundColor Green
"@ | Set-Content -Path $scriptPath -Encoding UTF8
}

function Ensure-Administrator {
    if (-not $IsAdministrator) {
        throw "Global installation requires administrator privileges. Run the script from an elevated PowerShell prompt or use -User for a per-user install."
    }
}

if ($Global) {
    Ensure-Administrator
}

function Show-Banner {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host "     $AppName v$AppVersion Installer" -ForegroundColor Magenta
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  - Download Paxori from GitHub releases" -ForegroundColor Yellow
    Write-Host "  - Extract the app into $InstallDir" -ForegroundColor Yellow
    Write-Host "  - Register uninstall metadata" -ForegroundColor Yellow
    Write-Host "  - Log installation activity to $LogFile" -ForegroundColor Yellow
    Write-Host ""
}

function Get-Consent {
    $response = Read-Host "Proceed with installation? (yes/no)"
    if ($response -ne 'yes') {
        Write-Host 'Installation cancelled.' -ForegroundColor Red
        exit 1
    }
}

function Download-Package {
    Write-Log "Downloading release asset from $ReleaseUrl"
    Remove-Item -Path $TempArchive -Force -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $TempArchive -UseBasicParsing
    Write-Log "Downloaded release asset to $TempArchive" "OK"
}

function Confirm-Checksum {
    if ([string]::IsNullOrWhiteSpace($AssetHash)) {
        Write-Log "No checksum configured for release asset; skipping verification." "WARN"
        return
    }

    Write-Log "Verifying SHA-256 checksum..."
    $actual = (Get-FileHash -Path $TempArchive -Algorithm SHA256).Hash
    if ($actual -ne $AssetHash) {
        Write-Log "Checksum mismatch! Expected: $AssetHash  Got: $actual" "ERROR"
        Remove-Item -Path $TempArchive -Force -ErrorAction SilentlyContinue
        throw "Checksum verification failed."
    }
    Write-Log "Checksum verified." "OK"
}

function Extract-Package {
    Write-Log "Extracting package to $InstallDir"
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Expand-Archive -LiteralPath $TempArchive -DestinationPath $InstallDir -Force
    Write-Log "Extraction complete." "OK"
}

function Install-Paxori {
    Write-Log "Installing Paxori"
    Download-Package
    Confirm-Checksum
    Extract-Package
    Create-UninstallScript
    Register-UninstallEntry
    Write-Log "Installation complete." "OK"
    Write-Host "Paxori is installed in $InstallDir" -ForegroundColor Green
}

function Uninstall-Paxori {
    Write-Log "Uninstall requested." "INFO"
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
    }
    if (Test-Path $UninstallRegPath) {
        Remove-Item -Path $UninstallRegPath -Recurse -Force
    }
    Write-Log "Paxori has been removed." "OK"
    Write-Host "Paxori has been uninstalled." -ForegroundColor Green
}

if ($Uninstall) {
    Show-Banner
    Uninstall-Paxori
    return
}

Show-Banner
if (-not (Check-Version)) {
    return
}
Get-Consent
Install-Paxori
