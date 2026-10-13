# Starts Claude Code in Remote Control mode inside the project folder and keeps the PC awake
# while it runs, so the session can be continued from the Claude app on the phone (Code tab).
# Started by double-clicking "Roblox-Claude Remote" on the desktop (created by setup-pc.ps1).
$Target = Join-Path $HOME "Roblox-Claude"
Set-Location $Target

Write-Host "== Projekt aktualisieren" -ForegroundColor Cyan
if (Get-Command git -ErrorAction SilentlyContinue) {
    git pull --ff-only 2>&1 | Out-Host
} else {
    Write-Host "   (ohne Git: fuer Updates setup-pc.ps1 erneut ausfuehren)"
}

# Keep the system awake (no admin needed). Undone automatically when this window closes.
Add-Type -Namespace Win32 -Name Power -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint esFlags);
"@
$ES_CONTINUOUS = [uint32]"0x80000000"
$ES_SYSTEM_REQUIRED = [uint32]"0x00000001"
[void][Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED)
Write-Host "== PC bleibt wach, solange dieses Fenster offen ist" -ForegroundColor Cyan

Write-Host ""
Write-Host "Checkliste:" -ForegroundColor Yellow
Write-Host "  [ ] Roblox Studio ist offen (Spiel/Baseplate geladen)"
Write-Host "  [ ] Assistant -> ... -> Manage MCP Servers: gruener Punkt bei Claude"
Write-Host "  [ ] Fotos liegen in $Target\refs\auto"
Write-Host ""
Write-Host "== Claude Remote Control startet. Auf dem Handy: Claude-App -> Code -> diese Sitzung oeffnen." -ForegroundColor Green
Write-Host "   (Leertaste zeigt einen QR-Code zum Verbinden.)"

$claude = (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $claude) {
    Write-Host "Claude Code nicht gefunden. Installieren:  irm https://claude.ai/install.ps1 | iex" -ForegroundColor Red
    Read-Host "Enter zum Beenden"
    exit 1
}
& $claude remote-control
[void][Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS)
Read-Host "Remote Control beendet. Enter zum Schliessen"
