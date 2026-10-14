#!/usr/bin/env bash
# Sets up the Roblox + Claude workspace on a Mac.
# Run in Terminal:
#   curl -fsSL https://raw.githubusercontent.com/carl147258-cmd/Claude/claude/obby-und-leitfaden/scripts/setup-pc.sh | bash
set -euo pipefail

BRANCH="claude/obby-und-leitfaden"
TARGET="$HOME/Desktop/Roblox"

echo "== 1/4 Projekt herunterladen nach $TARGET"
if command -v git >/dev/null 2>&1; then
	if [ -d "$TARGET/.git" ]; then
		git -C "$TARGET" fetch origin "$BRANCH"
		git -C "$TARGET" checkout "$BRANCH"
		git -C "$TARGET" pull origin "$BRANCH"
	else
		git clone --branch "$BRANCH" https://github.com/carl147258-cmd/Claude.git "$TARGET"
	fi
else
	tmp="$(mktemp -d)"
	curl -fsSL "https://github.com/carl147258-cmd/Claude/archive/refs/heads/$BRANCH.zip" -o "$tmp/repo.zip"
	unzip -q "$tmp/repo.zip" -d "$tmp"
	inner="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
	mkdir -p "$TARGET"
	cp -R "$inner/." "$TARGET/"   # keeps your refs/ photos
	rm -rf "$tmp"
fi

echo "== 2/4 Ordner fuer deine Auto-Fotos anlegen"
mkdir -p "$TARGET/refs/auto"
echo "   Fotos hier ablegen: $TARGET/refs/auto"

echo "== 3/4 Claude Code mit Roblox Studio verbinden"
MCP="/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
if ! command -v claude >/dev/null 2>&1; then
	echo "   Claude Code (Befehl 'claude') nicht gefunden. Installieren: https://code.claude.com"
	echo "   Nutzt du die Claude-Desktop-App? Dann in Studio bei 'Quick connect' Claude Desktop einschalten."
elif [ ! -x "$MCP" ]; then
	echo "   Roblox-Studio-Schnittstelle nicht gefunden ($MCP)."
	echo "   Studio aktualisieren, Assistant -> ... -> Manage MCP Servers -> 'Enable Studio as MCP server' einschalten,"
	echo "   dann dieses Skript erneut ausfuehren."
else
	cd "$TARGET"
	if claude mcp list 2>/dev/null | grep -q "Roblox_Studio"; then
		echo "   Schon verbunden."
	else
		claude mcp add Roblox_Studio -- "$MCP"
		echo "   Verbunden (gilt fuer den Ordner $TARGET)."
	fi
fi

echo "== 4/4 Fertig"
echo "Naechste Schritte:"
echo "  1. 4 Fotos deines Autos nach $TARGET/refs/auto legen (Tueren zu, ganzes Auto im Bild)."
echo "  2. Roblox Studio oeffnen (Baseplate), MCP-Server muss eingeschaltet sein."
echo "  3. Im Terminal:  cd \"$TARGET\"  und dann  claude"
echo "  4. Den Auftrag aus docs/LOKAL-STARTEN.md (Abschnitt 5) einfuegen."
