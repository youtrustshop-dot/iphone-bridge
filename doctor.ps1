<#
.SYNOPSIS
  Diagnosi in sola lettura: perche' l'iPhone non vede il PC (o viceversa)?
#>
$ErrorActionPreference = 'SilentlyContinue'
$script:problems = 0
function Ok($m)   { Write-Host "[ok]   $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[!!]   $m" -ForegroundColor Yellow; $script:problems++ }

# LocalSend installato?
$ls = winget list --id LocalSend.LocalSend --exact --accept-source-agreements 2>$null | Select-String 'LocalSend.LocalSend'
if ($ls) { Ok 'LocalSend installato' } else { Warn 'LocalSend non installato: lancia .\install.ps1' }

# In esecuzione e in ascolto sulla porta 53317?
if (Get-Process -Name localsend_app, LocalSend) { Ok 'LocalSend in esecuzione' } else { Warn 'LocalSend non e'' aperto: avvialo' }
if (Get-NetTCPConnection -LocalPort 53317 -State Listen -ErrorAction SilentlyContinue) { Ok 'Porta 53317 in ascolto' } else { Warn 'Nessuno ascolta sulla 53317 (app chiusa o porta cambiata nelle impostazioni)' }

# Firewall
$fw = Get-NetFirewallRule -DisplayName 'LocalSend iPhone Bridge*' | Where-Object Enabled -eq True
if (@($fw).Count -ge 2) { Ok 'Regole firewall presenti' } else { Warn 'Regole firewall mancanti: lancia .\install.ps1 (come amministratore)' }

# Categoria di rete delle connessioni reali
$profiles = Get-NetConnectionProfile | Where-Object {
    $_.IPv4Connectivity -ne 'Disconnected' -and $_.Name -notmatch 'non identificata|Unidentified'
}
foreach ($p in $profiles) {
    if ($p.Name -match 'VPN|WireGuard|CyberGhost|Tailscale|OpenVPN|Proton|Nord') {
        Warn "VPN attiva ('$($p.Name)'): puo' dirottare il traffico locale. Spegnila o abilita la LAN locale per provare."
    } elseif ($p.NetworkCategory -eq 'Public') {
        Warn "Rete '$($p.Name)' = Pubblica: Windows nasconde il PC. Se e' casa tua rendila Privata."
    } else {
        Ok "Rete '$($p.Name)' = $($p.NetworkCategory)"
    }
}

# Indirizzo e subnet (iPhone e PC devono stare nella stessa)
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^(127|169\.254)\.' -and $_.PrefixOrigin -ne 'WellKnown' }
foreach ($i in $ips) { Write-Host "       IP $($i.IPAddress)/$($i.PrefixLength) su $($i.InterfaceAlias)" }
Write-Host '       Sull''iPhone: Impostazioni > Wi-Fi > (i) deve mostrare un IP con gli stessi primi 3 numeri.'

Write-Host ''
if ($script:problems -eq 0) { Write-Host 'Tutto a posto.' -ForegroundColor Green } else { Write-Host "$($script:problems) problema/i da sistemare (vedi sopra)." -ForegroundColor Yellow }
exit $script:problems
