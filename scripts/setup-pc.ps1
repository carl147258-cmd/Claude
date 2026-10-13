# Sets up the Roblox + Claude workspace on a Windows PC.
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/carl147258-cmd/Claude/claude/obby-und-leitfaden/scripts/setup-pc.ps1 | iex
$ErrorActionPreference = "Stop"

$Branch = "claude/obby-und-leitfaden"
# project folder on the desktop (with OneDrive: C:\Users\<name>\OneDrive\Desktop\Roblox)
$Target = Join-Path ([Environment]::GetFolderPath("Desktop")) "Roblox"
$OldTarget = Join-Path $HOME "Roblox-Claude"   # location used by earlier versions of this script

function Test-NonEmptyDir($path) { (Test-Path $path) -and [bool](Get-ChildItem $path -Force -ErrorAction SilentlyContinue | Select-Object -First 1) }

# move an existing checkout from the old location (keeps git history and refs\ photos)
if ((Test-Path (Join-Path $OldTarget ".git")) -and -not (Test-NonEmptyDir $Target)) {
    try {
        if (Test-Path $Target) { Remove-Item $Target -Force }
        Move-Item $OldTarget $Target -ErrorAction Stop
        Write-Host "== Projekt umgezogen: $OldTarget -> $Target" -ForegroundColor Cyan
    } catch {
        Write-Host "   Umzug nicht moeglich (Ordner in Benutzung?). Remote-Fenster schliessen und Skript erneut starten." -ForegroundColor Yellow
    }
}

Write-Host "== 1/4 Projekt herunterladen nach $Target" -ForegroundColor Cyan
if (Get-Command git -ErrorAction SilentlyContinue) {
    $ErrorActionPreference = "Continue"   # git prints progress on stderr
    if (Test-Path (Join-Path $Target ".git")) {
        git -C $Target fetch origin $Branch
        git -C $Target checkout $Branch
        git -C $Target pull origin $Branch
    } elseif (Test-NonEmptyDir $Target) {
        # folder already holds the user's files: add the project without touching them
        git -C $Target init -q
        git -C $Target remote add origin https://github.com/carl147258-cmd/Claude.git
        git -C $Target fetch origin $Branch
        git -C $Target checkout -b $Branch --track "origin/$Branch"
        if ($LASTEXITCODE -ne 0) { Write-Host "   Gleichnamige Dateien im Ordner verhindern den Download - bitte umbenennen." -ForegroundColor Yellow }
    } else {
        git clone --branch $Branch https://github.com/carl147258-cmd/Claude.git $Target
    }
    if ($LASTEXITCODE -ne 0) { throw "Git-Download fehlgeschlagen" }
    $ErrorActionPreference = "Stop"
} else {
    $zip = Join-Path $env:TEMP "roblox-claude.zip"
    Invoke-WebRequest "https://github.com/carl147258-cmd/Claude/archive/refs/heads/$Branch.zip" -OutFile $zip -UseBasicParsing
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
$oldRefs = Join-Path $OldTarget "refs"
if (Test-Path $oldRefs) {
    Copy-Item (Join-Path $oldRefs "*") (Join-Path $Target "refs") -Recurse -Force
    Write-Host "   Fotos aus $OldTarget uebernommen. Den alten Ordner kannst du loeschen."
}
Write-Host "   Fotos hier ablegen: $refs"

Write-Host "== 3/4 Claude Code mit Roblox Studio verbinden" -ForegroundColor Cyan
$mcp = Join-Path $env:LOCALAPPDATA "Roblox\mcp.bat"
# prefer claude.exe / claude.cmd: an npm-installed claude.ps1 may be blocked by the execution policy
$claude = (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source
# the native installer puts claude.exe in ~\.local\bin, which may not be on PATH yet
$localClaude = Join-Path $HOME ".local\bin\claude.exe"
if (-not $claude -and (Test-Path $localClaude)) {
    $claude = $localClaude
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*\.local\bin*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$(Split-Path $localClaude)", "User")
        Write-Host "   Claude-Ordner zum PATH hinzugefuegt (gilt fuer neue Fenster)."
    }
}
if (-not $claude) {
    Write-Host "   Claude Code (Befehl 'claude') nicht gefunden. Installieren: https://code.claude.com" -ForegroundColor Yellow
    Write-Host "   Nutzt du die Claude-Desktop-App? Dann in Studio bei 'Quick connect' Claude Desktop einschalten."
} elseif (-not (Test-Path $mcp)) {
    Write-Host "   Roblox-Studio-Schnittstelle nicht gefunden ($mcp)." -ForegroundColor Yellow
    # the Roblox Player (games app) is not Studio; Studio ships RobloxStudioBeta.exe
    $studio = Get-ChildItem (Join-Path $env:LOCALAPPDATA "Roblox\Versions") -Recurse -Filter "RobloxStudioBeta.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $studio) {
        Write-Host "   Roblox Studio ist nicht installiert (die normale Roblox-App reicht nicht)." -ForegroundColor Yellow
        Write-Host "   Download: https://create.roblox.com -> 'Start Creating' / 'Studio herunterladen'."
    }
    Write-Host "   In Studio: Assistant -> ... -> Manage MCP Servers -> 'Enable Studio as MCP server' einschalten,"
    Write-Host "   dann dieses Skript erneut ausfuehren."
} else {
    Push-Location $Target
    $ErrorActionPreference = "Continue"   # native stderr output must not abort Windows PowerShell 5.1
    $existing = (& $claude mcp list 2>&1 | Out-String)
    if ($existing -match "Roblox_Studio") {
        Write-Host "   Schon verbunden."
    } else {
        # quote '--' so Windows PowerShell 5.1 passes it through to claude
        & $claude mcp add Roblox_Studio '--' cmd.exe /c $mcp
        if ($LASTEXITCODE -ne 0) { Write-Host "   Verbinden fehlgeschlagen - in Studio 'Quick connect' -> Claude Code nutzen." -ForegroundColor Yellow }
        Write-Host "   Verbunden (gilt fuer den Ordner $Target)."
    }
    Pop-Location
}

Write-Host "== Desktop-Verknuepfung 'Roblox-Claude Remote' anlegen" -ForegroundColor Cyan
$desktop = [Environment]::GetFolderPath("Desktop")
$bat = Join-Path $desktop "Roblox-Claude Remote.bat"
Set-Content -Path $bat -Encoding ASCII -Value @(
    "@echo off",
    "powershell -NoProfile -ExecutionPolicy Bypass -File `"$Target\scripts\start-remote.ps1`""
)
Write-Host "   Doppelklick darauf startet Claude fuer die Fernsteuerung vom Handy."

Write-Host "== 4/4 Fertig" -ForegroundColor Green
Write-Host "Naechste Schritte:"
Write-Host "  1. 4 Fotos deines Autos nach $refs legen (Tueren zu, ganzes Auto im Bild)."
Write-Host "  2. Roblox Studio oeffnen (Baseplate), MCP-Server muss eingeschaltet sein."
Write-Host "  3. Auf dem Desktop 'Roblox-Claude Remote' doppelklicken (startet Claude fuer das Handy)."
Write-Host "  4. Auf dem Handy: Claude-App -> Code -> Sitzung oeffnen -> Auftrag aus docs\LOKAL-STARTEN.md einfuegen."
