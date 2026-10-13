# Claude auf deinem PC mit Roblox Studio verbinden

So arbeitet Claude direkt in deinem Studio: bauen, Scripts schreiben, Testspiele starten, Screenshots ansehen. Und das mit dem ganzen Wissen aus diesem Repo (Skill, Lern-Datei, Modelle).

## 1. Repo auf den PC holen (einmalig)

Im Terminal (Windows: „Eingabeaufforderung“ oder PowerShell):

```bash
git clone https://github.com/carl147258-cmd/Claude.git
cd Claude
git checkout claude/obby-und-leitfaden
```

Hast du kein Git, geht es auch so: Auf GitHub den Branch `claude/obby-und-leitfaden` wählen → **Code → Download ZIP** → entpacken.

## 2. Studio mit Claude verbinden (einmalig)

1. Roblox Studio aktualisieren und ein Spiel öffnen (für Tests ein neues **Baseplate**).
2. **Assistant** öffnen → **…** → **Manage MCP Servers** → **Enable Studio as MCP server** einschalten.
3. Unter **Quick connect** den Eintrag **Claude Code** einschalten (oder **Claude Desktop**, je nachdem, was du nutzt).
4. Studio **und** Claude neu starten. In „Manage MCP Servers“ zeigt ein grüner Punkt die Verbindung.

Falls Quick connect Claude Code nicht findet, im Terminal ausführen:
- Windows (Eingabeaufforderung `cmd`): `claude mcp add Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
- Mac: `claude mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`

## 3. Claude im Repo-Ordner starten

```bash
cd Claude
claude
```

Wichtig: im **Repo-Ordner** starten. Nur dann lädt Claude den Roblox-Skill, die Lern-Datei und die `CLAUDE.md`.

## 4. Fotos bereitlegen (für das Auto)

Lege 4 Fotos deines Autos in den Ordner `Claude/refs/auto/` (der Ordner wird nicht hochgeladen, siehe `.gitignore`):
1. `1_vorne_links.jpg`: schräg vorne links
2. `2_seite.jpg`: genau von der Seite
3. `3_hinten_rechts.jpg`: schräg hinten rechts
4. `4_vorne.jpg`: genau von vorne

Türen zu, ganzes Auto im Bild, Kamera etwa auf Hüfthöhe.

## 5. Diesen Auftrag in Claude einfügen

```text
Lies zuerst .claude/skills/roblox-game-dev/SKILL.md, references/lessons-learned.md,
references/autonomous-workflow.md und references/art-audio-animation.md.

Aufgabe: Baue mein Auto so originalgetreu wie möglich als Roblox-Modell nach, OHNE Marke
(kein Logo, kein echtes Kennzeichen, Fantasie-Kennzeichen „RB 2026“).

Vorgehen:
1. Prüfe mit list_roblox_studios die Verbindung zu meinem Studio.
2. Erstelle von jedem Foto in refs/auto/ eine bereinigte Kopie (Logo entfernt, Kennzeichen ersetzt,
   Hintergrund entfernt) und lade sie mit store_image.
3. Erzeuge mit generate_mesh aus dem besten Foto (schräg vorne links) ein texturiertes 3D-Modell.
   Lege vorher ein Part als Bounding-Box mit den echten Maßen an: 16,2 x 5,0 x 6,6 Studs
   (Länge x Höhe x Breite, 1 Stud ≈ 0,28 m).
4. Prüfe das Ergebnis mit screen_capture aus 4 Blickwinkeln (vorne schräg, Seite, hinten schräg, vorne)
   und vergleiche es mit meinen Fotos. Nenne mir ehrlich die Abweichungen.
   Bei Bedarf neu generieren (Prompt/Segmentierung anpassen). Höchstens 3 Versuche, dann frag mich.
5. Segmentiere das Modell in Karosserie, Scheiben, Räder (4 einzeln) und Lichter,
   damit wir es später fahrbar machen können.
6. Trage alles, was nicht auf Anhieb geklappt hat, in lessons-learned.md ein.
Zeig mir zum Schluss Screenshots und frag mich, ob es so passt.
```

## Was kostet das?

- Roblox' eigener Generator (`generate_mesh`) ist **kostenlos**, hat aber ein Tageslimit.
- Claude auf dem PC läuft über dein Claude-Abo.
- Reicht die Qualität nicht, gibt es den Weg über Tripo (ca. 18 Higgsfield-Credits, siehe Leitfaden).
