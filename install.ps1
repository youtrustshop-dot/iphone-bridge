<#
.SYNOPSIS
  Prepara un PC Windows a ricevere e inviare file con un iPhone (o Android) tramite LocalSend.
.DESCRIPTION
  1. installa LocalSend con winget (se manca)
  2. crea la cartella di ricezione
  3. apre il firewall per LocalSend (porta 53317 TCP/UDP, solo reti private)
  4. se la rete attuale e' "Pubblica", propone di renderla "Privata"
  Si rilancia da solo come amministratore se serve. Idempotente: si puo' rilanciare.
.PARAMETER Folder
  Cartella dove salvare i file ricevuti. Default: Documenti\iPhone.
.PARAMETER Status
  Non cambia nulla: mostra solo la diagnosi (come doctor.ps1).
.PARAMETER MakeNetworkPrivate
  Rende Privata la rete attiva senza chiedere.
#>
[CmdletBinding()]
param(
    [string]$Folder = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'iPhone'),
    [switch]$Status,
    [switch]$MakeNetworkPrivate
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($Status) { & (Join-Path $here 'doctor.ps1'); return }

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')
}

if (-not (Test-Admin)) {
    Write-Host 'Servono i permessi di amministratore (firewall). Riapro la finestra elevata...'
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$($MyInvocation.MyCommand.Path)`"", '-Folder', "`"$Folder`"")
    if ($MakeNetworkPrivate) { $argList += '-MakeNetworkPrivate' }
    Start-Process powershell -Verb RunAs -ArgumentList $argList -Wait
    return
}

# 1. LocalSend
$installed = winget list --id LocalSend.LocalSend --exact --accept-source-agreements 2>$null | Select-String 'LocalSend.LocalSend'
if ($installed) {
    Write-Host '[ok] LocalSend gia'' installato'
} else {
    Write-Host 'Installo LocalSend...'
    winget install --id LocalSend.LocalSend --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget install fallito (codice $LASTEXITCODE)" }
    Write-Host '[ok] LocalSend installato'
}

# 2. Cartella di ricezione
New-Item -ItemType Directory -Force -Path $Folder | Out-Null
Write-Host "[ok] Cartella di ricezione: $Folder"

# 3. Firewall (solo profilo Privato e Dominio: mai sulle reti pubbliche)
$rules = @(
    @{ Name = 'LocalSend iPhone Bridge TCP'; Protocol = 'TCP' },
    @{ Name = 'LocalSend iPhone Bridge UDP'; Protocol = 'UDP' }
)
foreach ($r in $rules) {
    if (-not (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Action Allow `
            -Protocol $r.Protocol -LocalPort 53317 -Profile Private, Domain | Out-Null
    }
}
Write-Host '[ok] Firewall: porta 53317 aperta sulle reti private'

# 4. Rete pubblica = LocalSend non vede i dispositivi
$pub = Get-NetConnectionProfile | Where-Object {
    $_.NetworkCategory -eq 'Public' -and $_.IPv4Connectivity -ne 'Disconnected' -and $_.Name -notmatch 'VPN|WireGuard|CyberGhost|Tailscale|non identificata|Unidentified'
}
foreach ($p in $pub) {
    $go = $MakeNetworkPrivate
    if (-not $go) {
        $ans = Read-Host "La rete '$($p.Name)' e' Pubblica. Renderla Privata? (solo se e' la tua rete di casa) [s/N]"
        $go = $ans -match '^(s|si|y|yes)$'
    }
    if ($go) {
        Set-NetConnectionProfile -InterfaceIndex $p.InterfaceIndex -NetworkCategory Private
        Write-Host "[ok] '$($p.Name)' ora e' Privata"
    } else {
        Write-Host "[--] '$($p.Name)' resta Pubblica: l'iPhone potrebbe non vedere il PC"
    }
}

Write-Host ''
Write-Host 'Fatto. Ultimi passi, una volta sola, dentro LocalSend > Impostazioni:'
Write-Host "  - Destinazione: $Folder"
Write-Host '  - Avvia con il sistema: attivo (sul portatile anche "Avvia nascosto")'
Write-Host 'Poi esegui .\doctor.ps1 per controllare che sia tutto verde.'
