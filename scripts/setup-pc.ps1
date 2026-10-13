# Sets up the Roblox + Claude workspace on a Windows PC.
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/carl147258-cmd/Claude/claude/obby-und-leitfaden/scripts/setup-pc.ps1 | iex
$ErrorActionPreference = "Stop"

$Branch = "claude/obby-und-leitfaden"
$Target = Join-Path $HOME "Roblox-Claude"

Write-Host "== 1/4 Projekt herunterladen nach $Target" -ForegroundColor Cyan
if (Get-Command git -ErrorAction SilentlyContinue) {
    $ErrorActionPreference = "Continue"   # git prints progress on stderr
    if (Test-Path (Join-Path $Target ".git")) {
        git -C $Target fetch origin $Branch
        git -C $Target checkout $Branch
        git -C $Target pull origin $Branch
    } else {
        git clone --branch $Branch https://github.com/carl147258-cmd/Claude.git $Target
    }
    if ($LASTEXITCODE -ne 0) { throw "Git-Download fehlgeschlagen" }
    $ErrorActionPreference = "Stop"
} else {
    $zip = Join-Path $env:TEMP "roblox-claude.zip"
    Invoke-WebRequest "https://github.com/carl147258-cmd/Claude/archive/refs/heads/$Branch.zip" -OutFile $zip
    $tmp = Join-Path $env:TEMP "roblox-claude-unzip"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive $zip -DestinationPath $tmp
    $inner = Get-ChildItem $tmp | Select-Object -First 1
    if (Test-Path $Target) {
        Copy-Item (Join-Path $inner.FullName "*") $Target -Recurse -Force   # keeps your refs/ photos
    } else {
        Move-Item $inner.FullName $Target
    }
    Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   (ohne Git heruntergeladen - fuer Updates einfach dieses Skript erneut ausfuehren)"
}

Write-Host "== 2/4 Ordner fuer deine Auto-Fotos anlegen" -ForegroundColor Cyan
$refs = Join-Path $Target "refs\auto"
New-Item -ItemType Directory -Force -Path $refs | Out-Null
Write-Host "   Fotos hier ablegen: $refs"

Write-Host "== 3/4 Claude Code mit Roblox Studio verbinden" -ForegroundColor Cyan
$mcp = Join-Path $env:LOCALAPPDATA "Roblox\mcp.bat"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "   Claude Code (Befehl 'claude') nicht gefunden. Installieren: https://code.claude.com" -ForegroundColor Yellow
    Write-Host "   Nutzt du die Claude-Desktop-App? Dann in Studio bei 'Quick connect' Claude Desktop einschalten."
} elseif (-not (Test-Path $mcp)) {
    Write-Host "   Roblox-Studio-Schnittstelle nicht gefunden ($mcp)." -ForegroundColor Yellow
    Write-Host "   Studio aktualisieren, Assistant -> ... -> Manage MCP Servers -> 'Enable Studio as MCP server' einschalten,"
    Write-Host "   dann dieses Skript erneut ausfuehren."
} else {
    Push-Location $Target
    $ErrorActionPreference = "Continue"   # native stderr output must not abort Windows PowerShell 5.1
    $existing = (claude mcp list 2>&1 | Out-String)
    if ($existing -match "Roblox_Studio") {
        Write-Host "   Schon verbunden."
    } else {
        claude mcp add Roblox_Studio -- cmd.exe /c $mcp
        Write-Host "   Verbunden (gilt fuer den Ordner $Target)."
    }
    Pop-Location
}

Write-Host "== 4/4 Fertig" -ForegroundColor Green
Write-Host "Naechste Schritte:"
Write-Host "  1. 4 Fotos deines Autos nach $refs legen (Tueren zu, ganzes Auto im Bild)."
Write-Host "  2. Roblox Studio oeffnen (Baseplate), MCP-Server muss eingeschaltet sein."
Write-Host "  3. Im Terminal:  cd `"$Target`"   und dann   claude"
Write-Host "  4. Den Auftrag aus docs\LOKAL-STARTEN.md (Abschnitt 5) einfuegen."
