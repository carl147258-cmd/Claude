# Projekt: Roblox-Spiele entwickeln

Dieses Repository dient dazu, Roblox-Spiele (Luau) zu entwerfen und zu programmieren.

- Für jede Roblox-Aufgabe den Skill `roblox-game-dev` (`.claude/skills/roblox-game-dev/SKILL.md`) laden und dessen Workflow und Checkliste befolgen.
- **Aus Fehlern lernen:** Vor jeder Aufgabe die passenden Abschnitte in `.claude/skills/roblox-game-dev/references/lessons-learned.md` lesen. Jede Korrektur (eigene Prüfung, fehlgeschlagener Check oder Feedback des Nutzers) sofort dort als allgemeine Regel eintragen.
- Antworten auf Deutsch; Code-Bezeichner und Code-Kommentare auf Englisch.
- Neue Spiele mit Rojo-Struktur starten: `.claude/skills/roblox-game-dev/templates/rojo-starter/` in einen eigenen Ordner unter `games/<spielname>/` kopieren.
- Immer server-autoritativ arbeiten: der Client sendet nur Absichten, der Server prüft alles.
- Einsteiger-Leitfaden (Kosten, Regeln, Fahrplan): `docs/ROBLOX-LEITFADEN.md`. Referenzprojekt: `games/mein-erstes-obby/`.
- Luau-Code vor jedem Commit prüfen: `scripts/check-luau.sh` (StyLua, Selene, luau-lsp; GitHub Actions führt dasselbe aus). Selene braucht Zugriff auf Roblox-Server; in der Cloud-Sitzung mit `SKIP_SELENE=1` ausführen.
- Ganze Spiele: nach `.claude/skills/roblox-game-dev/references/autonomous-workflow.md` arbeiten (Plan → Meilensteine → Bauen → Prüfen → Bericht). Pro Spiel liegt der Plan in `games/<name>/SPIELPLAN.md` (Vorlage: `docs/SPIELPLAN-VORLAGE.md`).
- Lokal mit Roblox Studio arbeiten (Studio MCP): Anleitung und fertiger Auftrag in `docs/LOKAL-STARTEN.md`. Referenzfotos liegen in `refs/` (nicht im Git).
