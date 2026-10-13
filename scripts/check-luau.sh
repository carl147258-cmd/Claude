#!/usr/bin/env bash
# Format-check, lint and type-check every Rojo project (any folder with default.project.json).
# Usage: scripts/check-luau.sh            (downloads pinned tools into .tools/ on first run)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${TOOLS_DIR:-$ROOT/.tools}"
LUAU_LSP_VERSION=1.70.1
STYLUA_VERSION=2.1.0
ROJO_VERSION=7.4.4
SELENE_VERSION=0.28.0

fetch() { # url, binary name
	if [ ! -x "$TOOLS/$2" ]; then
		mkdir -p "$TOOLS"
		curl -fsSL -o "$TOOLS/$2.zip" "$1"
		unzip -o -q "$TOOLS/$2.zip" -d "$TOOLS"
		rm "$TOOLS/$2.zip"
		chmod +x "$TOOLS/$2"
	fi
}

fetch "https://github.com/JohnnyMorganz/luau-lsp/releases/download/$LUAU_LSP_VERSION/luau-lsp-linux-x86_64.zip" luau-lsp
fetch "https://github.com/JohnnyMorganz/StyLua/releases/download/v$STYLUA_VERSION/stylua-linux-x86_64.zip" stylua
fetch "https://github.com/rojo-rbx/rojo/releases/download/v$ROJO_VERSION/rojo-$ROJO_VERSION-linux-x86_64.zip" rojo
fetch "https://github.com/Kampfkarren/selene/releases/download/$SELENE_VERSION/selene-$SELENE_VERSION-linux.zip" selene
DEFS="$TOOLS/globalTypes-$LUAU_LSP_VERSION.d.luau"
[ -f "$DEFS" ] || curl -fsSL -o "$DEFS" \
	"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$LUAU_LSP_VERSION/scripts/globalTypes.d.luau"

status=0
while IFS= read -r project; do
	dir="$(dirname "$project")"
	echo "== $dir"
	(
		cd "$dir"
		"$TOOLS/stylua" --check src
		if [ "${SKIP_SELENE:-0}" != "1" ]; then
			"$TOOLS/selene" src
		fi
		"$TOOLS/rojo" sourcemap default.project.json -o "$TOOLS/sourcemap.json"
		out="$("$TOOLS/luau-lsp" analyze --definitions="$DEFS" --sourcemap="$TOOLS/sourcemap.json" src 2>&1 | grep -v -e '^\[INFO\]' -e '^\[WARN\]' || true)"
		if [ -n "$out" ]; then
			echo "$out"
			exit 1
		fi
	) || status=1
done < <(find "$ROOT" -name default.project.json -not -path '*/node_modules/*' -not -path "$TOOLS/*" | sort)

exit $status
