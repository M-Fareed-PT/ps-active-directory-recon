<#
.SYNOPSIS
    Basic Active Directory reconnaissance tool.

.DESCRIPTION
    When run in a domain-joined environment with the ActiveDirectory module:
      - Enumerates users, groups, admins, locked accounts
    If AD module is not available, falls back to reading a sample JSON file
    (for demo/portfolio purposes).

.NOTES
    Author  : Fareed
    Version : 1.0
#>

[CmdletBinding()]
param(
    [string]$OfflineSamplePath = ".\sample_ad.json",
    [string]$ExportDir = ".\output"
)

if (-not (Test-Path $ExportDir)) {
    New-Item -ItemType Directory -Path $ExportDir | Out-Null
}

function Use-OnlineADRecon {
    Write-Host "[+] ActiveDirectory module found. Running live AD recon..." -ForegroundColor Cyan

    $users      = Get-ADUser -Filter * -Properties LockedOut,PasswordLastSet,LastLogonDate
    $groups     = Get-ADGroup -Filter *
    $admins     = Get-ADGroupMember 'Domain Admins' -Recursive
    $locked     = $users | Where-Object { $_.LockedOut -eq $true }

    $users      | Select-Object Name,SamAccountName,Enabled,LockedOut,PasswordLastSet,LastLogonDate |
                  Export-Csv -Path (Join-Path $ExportDir 'ad_users.csv') -NoTypeInformation -Encoding UTF8

    $groups     | Select-Object Name,GroupScope,GroupCategory |
                  Export-Csv -Path (Join-Path $ExportDir 'ad_groups.csv') -NoTypeInformation -Encoding UTF8

    $admins     | Select-Object Name,SamAccountName,objectClass |
                  Export-Csv -Path (Join-Path $ExportDir 'ad_domain_admins.csv') -NoTypeInformation -Encoding UTF8

    $locked     | Select-Object Name,SamAccountName,LastLogonDate |
                  Export-Csv -Path (Join-Path $ExportDir 'ad_locked_users.csv') -NoTypeInformation -Encoding UTF8

    Write-Host "[+] Live AD recon data exported to $ExportDir" -ForegroundColor Green
}

function Use-OfflineSample {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Warning "Offline sample file not found: $Path"
        return
    }

    Write-Host "[+] Using offline AD sample from $Path" -ForegroundColor Yellow
    $data = Get-Content -Path $Path -Raw | ConvertFrom-Json

    if ($data.Users) {
        $data.Users | Export-Csv -Path (Join-Path $ExportDir 'ad_users_offline.csv') -NoTypeInformation -Encoding UTF8
    }
    if ($data.Groups) {
        $data.Groups | Export-Csv -Path (Join-Path $ExportDir 'ad_groups_offline.csv') -NoTypeInformation -Encoding UTF8
    }
    if ($data.Admins) {
        $data.Admins | Export-Csv -Path (Join-Path $ExportDir 'ad_domain_admins_offline.csv') -NoTypeInformation -Encoding UTF8
    }

    Write-Host "[+] Offline AD data exported to $ExportDir" -ForegroundColor Green
}

# Main logic: try live AD first
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    Use-OnlineADRecon
} else {
    Write-Warning "ActiveDirectory module not found. Falling back to offline sample."
    Use-OfflineSample -Path $OfflineSamplePath
}
