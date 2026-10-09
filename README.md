# iphone-bridge

Mandare file tra **un PC Windows e un iPhone** (e Android) in locale, senza cloud e senza account.
Non è AirDrop vero: Windows non può parlare il protocollo radio di Apple (AWDL). È la strada pratica che funziona oggi, con [LocalSend](https://localsend.org) (open source, Apache-2.0) e uno script che sistema le cose che di solito la rompono.

*English: a one-command Windows setup (LocalSend + firewall + network profile) and a read-only diagnostic for iPhone/Android ↔ Windows local file transfer. Not real AirDrop.*

## Uso rapido

Su Windows, in PowerShell, dentro questa cartella:

```powershell
.\install.ps1      # installa LocalSend, apre il firewall (solo reti private), crea Documenti\iPhone
.\doctor.ps1       # diagnosi in sola lettura: dice cosa non va
```

Sull'iPhone: installa **LocalSend** dall'App Store, stessa Wi-Fi del PC, apri l'app. Fine.

Se non vuoi installare nulla: apri [pairdrop.net](https://pairdrop.net) su PC e su Safari (stessa Wi-Fi).

## Cosa fa `install.ps1`

| Passo | Dettaglio |
|---|---|
| Installa LocalSend | `winget install LocalSend.LocalSend`, salta se già presente |
| Cartella di ricezione | `Documenti\iPhone` (o `-Folder <percorso>`) |
| Firewall | porta 53317 TCP/UDP, **solo** profili Privato e Dominio |
| Rete Pubblica | chiede se renderla Privata (`-MakeNetworkPrivate` per non chiedere) |

Si rilancia da solo come amministratore. Si può eseguire più volte senza danni. Non tocca altro.

## Portatile debole

LocalSend è leggero e sta fermo quando non trasferisci. Sul portatile:
1. nelle sue impostazioni attiva **Avvia con il sistema** e **Avvia nascosto** (così parte in tray);
2. per file molto grandi (video 4K) usa il cavo Ethernet o il Wi-Fi a 5 GHz: il collo di bottiglia è la rete, non la CPU.

Lo stesso `install.ps1` va bene su entrambi i PC: ognuno compare in LocalSend con il suo nome.

## Se l'iPhone non vede il PC

Lancia `.\doctor.ps1`. Le cause più comuni, in ordine:
1. **Rete Windows "Pubblica"**: Windows nasconde il PC. Rendila Privata (lo fa l'installer).
2. **VPN attiva** (CyberGhost, WireGuard, ecc.): dirotta il traffico locale. Spegnila o abilita la LAN locale.
3. **Wi-Fi diverso o "ospiti"**: PC e iPhone devono avere gli stessi primi 3 numeri di IP.
4. **Isolamento client** sul router (reti ospiti, hotspot pubblici): i dispositivi non si vedono tra loro per scelta del router.
5. **iPhone**: Impostazioni > LocalSend > attiva **Rete locale**, altrimenti iOS blocca la ricerca.

Per farli parlare comunque: in LocalSend sull'iPhone scegli *Invia > Indirizzo* e scrivi l'IP del PC.

## Limiti onesti

- Non compare nel menu Condividi come AirDrop vero; si apre l'app (sull'iPhone esiste anche l'estensione Condividi di LocalSend).
- Su iPhone l'app deve restare aperta durante il trasferimento (limite di iOS).
- Per AirDrop vero da un non-Apple servono Linux + scheda Wi-Fi in modalità monitor ([OWL](https://github.com/seemoo-lab/owl), [omdrop-owl](https://github.com/t4t5/omdrop-owl)): su Windows non è possibile.

## Test

```powershell
powershell -NoProfile -File tests\syntax.ps1
```

## Licenza

MIT. LocalSend ha licenza Apache-2.0 e non è incluso in questo repo: viene scaricato da winget.
