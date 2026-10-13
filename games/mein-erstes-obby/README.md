# Mein erstes Obby

Ein komplettes, spielbares Obby (Hindernis-Parcours) als Startprojekt:

- **15 Stufen** werden automatisch gebaut. Sie werden nach und nach schwerer: Plattformen werden kleiner, liegen versetzt, manche verschwinden.
- **Lava** unter dem Parcours: Wer fällt, stirbt und startet am letzten Checkpoint neu.
- **Fortschritt wird gespeichert** (DataStore). Wer wiederkommt, startet auf seiner Stufe.
- **Bestenliste** oben rechts zeigt die Stufe jedes Spielers.
- **Schutz vor Schummeln**: Eine Stufe zählt nur, wenn der Spieler die *nächste* berührt.
- **„Stufe überspringen“** als Kauf mit Robux (Developer Product). Er ist optional und standardmäßig ausgeschaltet.
- **Handy-taugliche Oberfläche**: Anzeige der Stufe und ein großer Knopf.

## Variante A: Nur Roblox Studio (empfohlen für den Anfang)

1. Roblox Studio öffnen → **New** → Vorlage **Baseplate**.
2. Falls nicht sichtbar: über das Menü **Window** die Fenster **Explorer**, **Properties** und **Output** öffnen.
3. Lege die Objekte genau so an. Im Explorer mit der Maus über den Ordner fahren, auf **⊕** klicken (oder Strg+I) und den Typ eintippen. Umbenennen geht mit F2 oder Doppelklick auf den Namen. Die Namen müssen exakt stimmen.

   | Wo im Explorer | Typ | Name | Inhalt aus Datei |
   |---|---|---|---|
   | ReplicatedStorage | Folder | `Shared` | – |
   | ReplicatedStorage/Shared | ModuleScript | `Config` | `src/shared/Config.luau` |
   | ServerScriptService | **Script** | `Server` | `src/server/init.server.luau` |
   | ServerScriptService/Server | ModuleScript | `CourseBuilder` | `src/server/CourseBuilder.luau` |
   | ServerScriptService/Server | ModuleScript | `PlayerData` | `src/server/PlayerData.luau` |
   | ServerScriptService/Server | ModuleScript | `Checkpoints` | `src/server/Checkpoints.luau` |
   | ServerScriptService/Server | ModuleScript | `Hazards` | `src/server/Hazards.luau` |
   | ServerScriptService/Server | ModuleScript | `Monetization` | `src/server/Monetization.luau` |
   | StarterPlayer/StarterPlayerScripts | **LocalScript** | `Client` | `src/client/init.client.luau` |

   Die ModuleScripts unter `Server` müssen **Kinder** des Scripts `Server` sein. Dafür auf `Server` mit **⊕** ein ModuleScript einfügen.
4. Den Inhalt jeder Datei komplett hineinkopieren. Vorhandenen Code wie `print("Hello world!")` vorher löschen.
5. Oben links auf **Test** klicken (oder F5). Der Parcours erscheint, und du startest auf Stufe 1.

## Variante B: Mit Rojo und VS Code

```bash
rokit install            # installiert rojo, selene, stylua, wally (Versionen aus rokit.toml)
rojo serve               # in Studio: Rojo-Plugin → Connect
```

## Speichern testen

Im unveröffentlichten Studio-Projekt wird **nicht gespeichert**. Das Spiel läuft trotzdem, und im Output-Fenster erscheint eine Warnung. Zum Testen des Speicherns:

1. **File → Publish to Roblox** (zuerst als privates Spiel).
2. **File → Experience Settings → Security → „Enable Studio Access to API Services“** einschalten → **Save**. Mach das nur in einer Testkopie, nicht im Live-Spiel. Studio würde sonst echte Spielstände überschreiben.
3. Spielen, ein paar Stufen schaffen, stoppen, erneut spielen. Du solltest auf deiner Stufe starten.
4. Mit mehreren Spielern testen: oben links im Test-Menü **Server & Clients** wählen, 2 Clients einstellen und auf Play klicken (oder F7).

## „Stufe überspringen“ einschalten

1. [create.roblox.com](https://create.roblox.com) → dein Spiel → **Monetization → Developer Products** → **Create**. Name: „Stufe überspringen“, Preis z. B. 25 Robux.
2. Die **Product ID** kopieren und in `Config.luau` bei `SkipStageProductId` eintragen.
3. Käufe in Studio sind Testkäufe und kosten nichts. Das Gewähren funktioniert nur mit aktiviertem Speichern (siehe oben). Ein Kauf wird erst bestätigt, wenn er gespeichert ist. So geht kein Kauf verloren und keiner wird doppelt gutgeschrieben.

## Sounds, Icon und Thumbnail

Im Ordner `assets/` liegen selbst erzeugte, lizenzfreie Dateien:

| Datei | Zweck |
|---|---|
| `audio/checkpoint.ogg` | Checkpoint erreicht |
| `audio/death.ogg` | In Lava gefallen |
| `audio/finish.ogg` | Ziel erreicht |
| `audio/click.ogg` | Knopf gedrückt |
| `audio/disappear.ogg` | Plattform verschwindet |
| `art/icon_512.png` | Spiel-Icon (Creator Dashboard → dein Spiel → Places/Icon) |
| `art/thumbnail_1920x1080.png` | Vorschaubild für die Spielseite |

So aktivierst du die Sounds:
1. In Studio **Window → Asset Manager → Import** öffnen und die `.ogg`-Dateien auswählen.
2. Nach der Moderationsprüfung zu jedem Sound per Rechtsklick die **Asset ID** kopieren.
3. Die IDs in `Config.luau` unter `Sounds` eintragen. Steht dort 0, bleibt der Sound stumm.

Neu erzeugen oder ändern: `python3 scripts/make_sfx.py games/mein-erstes-obby/assets/audio` und `python3 scripts/make_obby_art.py games/mein-erstes-obby/assets/art`.

## Anpassen

| Was | Wo |
|---|---|
| Anzahl Stufen | `Config.StageCount` |
| Eigener Parcours statt generiertem | In Workspace einen Ordner `Course` mit Unterordner `Checkpoints` anlegen. Darin Parts mit den Namen `1`, `2`, `3`, … ablegen. Der Generator lässt ihn dann in Ruhe. |
| Tödliche Teile | Im Properties-Fenster unter **Tags** den Tag `KillBrick` hinzufügen |
| Verschwindende Plattformen | Tag `Disappearing` |
| Spielstände zurücksetzen | `Config.DataStoreName` ändern (z. B. `ObbyData_v2`) |

## Nächste Ausbaustufen (Ideen)

1. Eigenes Design: Farben, Themenwelten (Lava, Eis, Weltraum), Musik.
2. Game Pass „VIP“: doppelte Sprungkraft oder Trail-Effekt.
3. Tägliche Belohnung und eine Zeit-Bestenliste (OrderedDataStore).
4. Sich bewegende Plattformen, Sprungpads, Förderbänder.
5. Weitere Welten mit je 25 Stufen.
