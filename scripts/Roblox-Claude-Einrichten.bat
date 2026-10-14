@echo off
chcp 65001 >nul
title Roblox-Claude einrichten
echo ============================================
echo   Roblox-Claude wird eingerichtet
echo   Vorher in Roblox Studio einschalten:
echo   Assistant - ... - Manage MCP Servers -
echo   "Enable Studio as MCP server"
echo ============================================
echo.
where claude >nul 2>nul
if errorlevel 1 (
  echo == Claude Code fehlt - wird installiert ...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
)
echo.
echo == Projekt laden, Studio verbinden, Desktop-Verknuepfung anlegen ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine'); irm https://raw.githubusercontent.com/carl147258-cmd/Claude/claude/obby-und-leitfaden/scripts/setup-pc.ps1 | iex"
echo.
echo ============================================
echo   Fertig, falls oben keine rote Meldung steht.
echo   Erster Start: Doppelklick auf "Roblox-Claude Remote"
echo   auf dem Desktop. Beim ersten Mal im Browser anmelden.
echo ============================================
pause
