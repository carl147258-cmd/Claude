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

# Linux (CI, cloud) or Windows (Git Bash on the user's PC); binaries live in a per-platform folder.
case "$(uname -s)" in
MINGW* | MSYS* | CYGWIN*)
	BIN="$TOOLS/windows"
	EXE=".exe"
	LUAU_LSP_ZIP="luau-lsp-win64.zip"
	STYLUA_ZIP="stylua-windows-x86_64.zip"
	ROJO_ZIP="rojo-$ROJO_VERSION-windows-x86_64.zip"
	SELENE_ZIP="selene-$SELENE_VERSION-windows.zip"
	;;
*)
	BIN="$TOOLS/linux"
	EXE=""
	LUAU_LSP_ZIP="luau-lsp-linux-x86_64.zip"
	STYLUA_ZIP="stylua-linux-x86_64.zip"
	ROJO_ZIP="rojo-$ROJO_VERSION-linux-x86_64.zip"
	SELENE_ZIP="selene-$SELENE_VERSION-linux.zip"
	;;
esac

fetch() { # url, binary name
	if [ ! -x "$BIN/$2$EXE" ]; then
		mkdir -p "$BIN"
		curl -fsSL -o "$BIN/$2.zip" "$1"
		unzip -o -q "$BIN/$2.zip" -d "$BIN"
		rm "$BIN/$2.zip"
		chmod +x "$BIN/$2$EXE"
	fi
}

fetch "https://github.com/JohnnyMorganz/luau-lsp/releases/download/$LUAU_LSP_VERSION/$LUAU_LSP_ZIP" luau-lsp
fetch "https://github.com/JohnnyMorganz/StyLua/releases/download/v$STYLUA_VERSION/$STYLUA_ZIP" stylua
fetch "https://github.com/rojo-rbx/rojo/releases/download/v$ROJO_VERSION/$ROJO_ZIP" rojo
fetch "https://github.com/Kampfkarren/selene/releases/download/$SELENE_VERSION/$SELENE_ZIP" selene
DEFS="$TOOLS/globalTypes-$LUAU_LSP_VERSION.d.luau"
[ -f "$DEFS" ] || curl -fsSL -o "$DEFS" \
	"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$LUAU_LSP_VERSION/scripts/globalTypes.d.luau"

status=0
while IFS= read -r project; do
	dir="$(dirname "$project")"
	echo "== $dir"
	(
		cd "$dir"
		"$BIN/stylua$EXE" --check src || exit 1
		if [ "${SKIP_SELENE:-0}" != "1" ]; then
			"$BIN/selene$EXE" src || exit 1
		fi
		"$BIN/rojo$EXE" sourcemap default.project.json -o "$TOOLS/sourcemap.json" || exit 1
		out="$("$BIN/luau-lsp$EXE" analyze --definitions="$DEFS" --sourcemap="$TOOLS/sourcemap.json" src 2>&1 | grep -v -e '^\[INFO\]' -e '^\[WARN\]' || true)"
		if [ -n "$out" ]; then
			echo "$out"
			exit 1
		fi
	) || status=1
done < <(find "$ROOT" -name default.project.json -not -path '*/node_modules/*' -not -path "$TOOLS/*" | sort)

exit $status
