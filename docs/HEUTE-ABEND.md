# Checkliste: PC einrichten und dann vom Handy weiterarbeiten

Ziel: In etwa 10–15 Minuten ist dein Windows-11-PC fertig. Danach läuft Claude dort weiter, Roblox Studio bleibt offen, und du steuerst alles unterwegs über die **Claude-App → Code**.

## Jetzt schon, unterwegs (mit dem Handy)

- [ ] **4 Fotos vom Auto** machen: Türen zu, ganzes Auto im Bild, Handy auf Hüfthöhe
  1. schräg vorne links
  2. genau von der Seite
  3. schräg hinten rechts
  4. genau von vorne
- [ ] In der **Claude-App** mit demselben Konto angemeldet sein wie später am PC.

## Zu Hause am PC (Windows 11)

| # | Schritt | Dauer |
|---|---|---|
| 1 | **Roblox Studio** starten. Updates installieren lassen. Ein Spiel öffnen (für den Test: **New → Baseplate**). | 2 min |
| 2 | In Studio: **Assistant** → **…** → **Manage MCP Servers** → **Enable Studio as MCP server** einschalten. | 1 min |
| 3 | **Claude Code installieren**, falls noch nicht vorhanden: Startmenü → „PowerShell“ öffnen → `irm https://claude.ai/install.ps1 \| iex` → danach PowerShell schließen und neu öffnen → `claude` eingeben → im Browser anmelden → mit `/exit` beenden. | 3 min |
| 4 | **Setup-Skript** in PowerShell ausführen: `irm https://raw.githubusercontent.com/carl147258-cmd/Claude/claude/obby-und-leitfaden/scripts/setup-pc.ps1 \| iex`. Es lädt das Projekt, verbindet Studio und legt die Desktop-Verknüpfung an. | 2 min |
| 5 | **Fotos auf den PC** in den Ordner `C:\Users\<Name>\Roblox-Claude\refs\auto` legen, per **Smartphone-Link** (bei Windows 11 dabei), OneDrive, USB-Kabel oder Mail an dich selbst. | 2 min |
| 6 | **Studio neu starten** und das Spiel wieder öffnen. In „Manage MCP Servers“ sollte bald ein grüner Punkt erscheinen. | 1 min |
| 7 | Auf dem Desktop **„Roblox-Claude Remote“** doppelklicken. Ein Fenster öffnet sich: Claude läuft im Remote-Modus, der PC bleibt wach. **Fenster offen lassen.** | 1 min |
| 8 | **Test vom Handy:** Claude-App → **Code** → die neue Sitzung antippen → schreiben: *„Prüfe die Verbindung zu Roblox Studio (list_roblox_studios) und mach einen Screenshot.“* Kommt ein Screenshot, ist alles bereit. | 2 min |

**Bevor du gehst:** PC **nicht** herunterfahren, Studio und das Remote-Fenster offen lassen. Bildschirm sperren (Windows-Taste + L) ist in Ordnung.

## Unterwegs weitermachen

In der Claude-App (Code → deine Sitzung) den Auftrag aus `docs/LOKAL-STARTEN.md`, Abschnitt 5, einfügen. Claude arbeitet dann auf deinem PC in Studio und schickt dir Screenshots und Fragen.

## Wenn etwas hakt

| Problem | Lösung |
|---|---|
| PowerShell meldet „claude nicht gefunden“ | Schritt 3 wiederholen, PowerShell neu öffnen |
| Kein grüner Punkt in Studio | Studio und das Remote-Fenster schließen, Studio öffnen, Spiel laden, dann Verknüpfung erneut starten |
| Sitzung erscheint nicht in der App | Gleiches Konto am PC und in der App? Remote Control braucht eine aktuelle Claude-Code-Version (Setup-Skript bzw. `claude update`). |
| PC schläft trotzdem ein | Einstellungen → System → Energie → „Bildschirm und Energiesparmodus“ → Energiesparmodus bei Netzbetrieb auf **Nie** |
| Rote Fehlermeldung im Skript | Text abfotografieren oder kopieren und mir schicken |
