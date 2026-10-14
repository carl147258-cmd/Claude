# Spielplan: Katana-Früchte

## 1. Idee in einem Satz
Wie Fruit Ninja: Du stehst mit deinem Avatar auf einer schwebenden Plattform, Objekte fliegen in Bögen vor dir über den Bildschirm, du zerschneidest sie per Wisch und kaufst mit den Münzen coolere Schwerter, neue Objekt-Sets und Szenerien.

## 2. Kern-Schleife
Runde starten → Objekte wegwischen (Bomben meiden) → Punkte = Münzen → im Shop kaufen und ausrüsten → nächste Runde mit neuem Look und höherem Rekord

## 3. Zielgruppe & Plattform
- Alter: 16+ zum Start, später alle Altersgruppen
- Hauptgerät: Handy (Wischen mit dem Finger), PC mit gedrückter Maustaste
- Spieler pro Server: 6 (jeder hat seine eigene Plattform)
- Alleine spielbar

## 4. Fortschritt & Belohnungen
- Gespeichert: Rekord, Münzen, gekaufte und ausgerüstete Gegenstände
- Münzen: 1 Münze pro Punkt am Ende der Runde
- Shop (Preise in Münzen, nicht Robux):

| Schwerter | Preis | Objekt-Sets | Preis | Szenerien | Preis |
|---|---|---|---|---|---|
| Blutmond-Katana | gratis | Früchte | gratis | Blutmond-Nacht | gratis |
| Jade-Klinge | 250 | Gemüse | 300 | Kirschblüten-Tempel | 400 |
| Eis-Klinge | 600 | Süßigkeiten | 600 | Sonnenstrand | 700 |
| Zuckerstangen-Schwert | 800 | Spielzeug | 900 | Skyline-Stadt | 1000 |
| Gold-Drachenschwert | 1200 | Kuscheltiere | 1500 | Unterwasser | 1500 |
| Laserschwert | 2500 | | | Weltraum | 2500 |
| Regenbogen-Klinge | 5000 | | | | |

## 5. Aussehen & Stimmung
- Bunter Cartoon-Stil, alles aus Roblox-Teilen gebaut
- Ansicht: Kamera hinter dem Avatar; der Schwertarm folgt dem Finger, die Wischspur leuchtet in der Farbe des Schwerts
- Sounds: Schwusch, Schnitt, Splatsch, Kombo, Bombe

## 6. Geld (Robux)
Vorerst keine Robux-Käufe. Später möglich: Game Pass „doppelte Münzen“. Das entscheidest du.

## 7. Budget in echtem Geld
Keins nötig.

## 8. Meilensteine
| # | Ziel | Fertig, wenn … |
|---|---|---|
| M1 | Fruit-Ninja-Kern mit Avatar | Avatar mit Schwert sichtbar, Objekte fliegen quer, Wischen schneidet, Münzen am Rundenende |
| M2 | Shop & Speichern | Kaufen/Ausrüsten funktioniert, Server prüft Preis und Besitz, wird gespeichert |
| M3 | Schwerter | 7 Schwerter mit eigener Farbe und Wischspur |
| M4 | Objekt-Sets | Früchte, Gemüse, Süßigkeiten, Spielzeug, Kuscheltiere mit eigenen Schnitt-Effekten |
| M5 | Szenerien | 6 Szenerien, wechseln sofort beim Ausrüsten |
| M6 | Feinschliff | flüssig auf dem Handy, keine Fehler im Output |
| M7 | Start | Icon, Beschreibung, veröffentlicht |

## 9. Entscheidungen, die nur du triffst
Name, Preise, Robux-Angebote, Veröffentlichung.

## 10. Offene Fragen / Notizen
- Preise sind Startwerte und lassen sich in `src/shared/Catalog.luau` ändern.
