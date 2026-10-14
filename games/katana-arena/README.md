# Katana-Früchte (katana-arena)

Wie Fruit Ninja, nur in Roblox: Du stehst mit deinem Avatar auf einer schwebenden Plattform. Vor dir fliegen Objekte in Bögen über den Bildschirm. Wisch mit dem Finger (am PC mit gedrückter Maustaste) schnell darüber, um sie zu zerschneiden. Der Schwertarm deines Avatars folgt dabei dem Finger. Plan und Meilensteine stehen in `SPIELPLAN.md`.

## Regeln

- Jedes Objekt gibt Punkte (1 bis 3, je nach Art).
- Kombo-Bonus: Triffst du mindestens 3 Objekte in einem Wisch, gibt es so viele Punkte extra, wie du getroffen hast.
- Jedes verpasste Objekt kostet 1 Leben. Eine getroffene Bombe kostet auch 1 Leben. Du startest mit 3 Leben, bei 0 ist die Runde vorbei.
- Mit der Zeit kommen die Objekte schneller und in größeren Wellen. Bomben erscheinen ab Sekunde 15.
- Am Ende der Runde werden die Punkte zu Münzen (1 Münze pro Punkt).

## Shop

Im Menü öffnet **SHOP** den Laden. Gekaufte Sachen werden sofort ausgerüstet. Preise und Inhalte stehen in `src/shared/Catalog.luau`.

- **Schwerter (7):** Blutmond-Katana (gratis), Jade, Eis, Zuckerstange, Gold-Drache, Laser, Regenbogen. Jedes Schwert hat eigene Farben und eine eigene Wischspur.
- **Objekt-Sets (5):** Früchte (gratis), Gemüse, Süßigkeiten, Spielzeug, Kuscheltiere. Jedes Set hat eigene Schnitt-Effekte: Saft, Zuckerglitzer oder Watte mit Konfetti.
- **Szenerien (6):** Blutmond-Nacht (gratis), Kirschblüten-Tempel, Sonnenstrand, Skyline-Stadt, Unterwasser, Weltraum.

Münzen, Rekord, Gekauftes und Ausgerüstetes werden gespeichert. Das klappt nur in veröffentlichten Places mit aktiviertem API-Zugriff.

## Aufbau (Rojo)

| Datei | Ort in Studio | Aufgabe |
|---|---|---|
| `src/shared/Config.luau` | ReplicatedStorage.Shared.Config | Werte, Kamera, Flugbahn-Formel |
| `src/shared/Catalog.luau` | ReplicatedStorage.Shared.Catalog | Shop-Inhalte und Preise, Objektarten |
| `src/shared/SwordBuilder.luau` | ReplicatedStorage.Shared.SwordBuilder | Baut Schwerter aus Parts |
| `src/shared/ObjectBuilder.luau` | ReplicatedStorage.Shared.ObjectBuilder | Baut alle Objekte (Früchte bis Einhorn) |
| `src/server/init.server.luau` | ServerScriptService.Server | Start |
| `src/server/Arena.luau` | Modul unter Server | Plattformen, Halbkugel-Vorlage (CSG) |
| `src/server/FruitGame.luau` | Modul unter Server | Runden, Flugbahnen, Prüfung jedes Schnitts, Punkte, Leben, Münzen |
| `src/server/PlayerData.luau` | Modul unter Server | Profil speichern (Rekord, Münzen, Besitz, Ausrüstung) |
| `src/server/Shop.luau` | Modul unter Server | Kaufen/Ausrüsten prüfen, Schwert an die Hand des Avatars |
| `src/client/init.client.luau` | StarterPlayerScripts.Client | Kamera hinter dem Avatar, Wisch-Eingabe, Treffer |
| `src/client/Avatar.luau` | Modul unter Client | Schwertarm folgt dem Finger, Leucht-Bogen beim Wischen |
| `src/client/FruitView.luau` | Modul unter Client | Objekte zeichnen, Treffer finden, Hälften, Effekte |
| `src/client/Scenery.luau` | Modul unter Client | Die 6 Szenerien samt Licht |
| `src/client/Hud.luau` | Modul unter Client | Punkte, Münzen, Herzen, Kombo, Menü, Wischspur |
| `src/client/Shop.luau` | Modul unter Client | Shop-Fenster mit 3D-Vorschauen |
| `src/client/Sfx.luau` | Modul unter Client | Sounds |

Der Server ist die Autorität. Er legt jede Flugbahn fest, prüft jeden Schnitt (Existenz, Alter, Reichweite) und jeden Kauf (Preis, Münzen, Besitz). Der Client sendet nur Absichten.

## Testen

In Studio **Test** (F5) drücken, dann **START** klicken und mit gedrückter linker Maustaste durch die Objekte ziehen. Auf dem Handy wischst du mit dem Finger. Zum Testen eignet sich der Geräte-**Simulator**.

Shop testen ohne langes Spielen: Während des Tests in der Befehlsleiste der **Server**-Ansicht `game.Players:GetPlayers()[1]:SetAttribute("StudioGrantCoins", 5000)` eingeben. Das funktioniert nur in Studio, nicht im veröffentlichten Spiel.
