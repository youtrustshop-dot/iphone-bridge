# Controlla che gli script PowerShell si leggano senza errori di sintassi.
$bad = 0
Get-ChildItem (Join-Path $PSScriptRoot '..') -Filter *.ps1 -Recurse | ForEach-Object {
    $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errs)
    if ($errs) { $bad++; Write-Host "ERRORE in $($_.Name): $($errs[0].Message)" } else { Write-Host "ok  $($_.Name)" }
}
exit $bad
