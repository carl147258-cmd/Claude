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
- Gespeichert: Rekord, Münzen, gekaufte und ausgerüstete Gegenstände, Serie der täglichen Belohnung
- Münzen: 1 Münze pro Punkt am Ende der Runde, plus Bonus des ausgerüsteten Schwerts (gerundet)
- Tempo: schneller Einstieg (erster Kauf nach 2–3 Runden), das teuerste Teil ist ein Langzeitziel (ca. 1,5–3 Stunden). Annahme: ca. 45 Münzen pro Runde, ca. 1.800 pro Stunde.
- Tägliche Belohnung (7-Tage-Serie): 50 · 75 · 100 · 150 · 200 · 250 · 400 Münzen. Wer einen Tag auslässt, fängt wieder bei Tag 1 an.

**Seltenheitsstufen** (Kartenfarbe im Shop): Gewöhnlich (grau) 100–200 · Selten (blau) 450–700 · Episch (lila) 1.200–2.500 · Legendär (gold) 3.500–5.000

| Schwert | Stufe | Preis | Münz-Bonus |
|---|---|---|---|
| Blutmond-Katana | Gewöhnlich | gratis | – |
| Jade-Klinge | Gewöhnlich | 120 | – |
| Zuckerstangen-Schwert | Selten | 450 | +5 % |
| Eis-Klinge | Selten | 700 | +5 % |
| Gold-Drachenschwert | Episch | 1.500 | +10 % |
| Laserschwert | Episch | 2.500 | +15 % |
| Regenbogen-Klinge | Legendär | 5.000 | +25 % |

| Objekt-Set | Stufe | Preis | | Szenerie | Stufe | Preis |
|---|---|---|---|---|---|---|
| Früchte | Gewöhnlich | gratis | | Blutmond-Nacht | Gewöhnlich | gratis |
| Gemüse | Gewöhnlich | 150 | | Kirschblüten-Tempel | Gewöhnlich | 200 |
| Süßigkeiten | Selten | 600 | | Sonnenstrand | Selten | 500 |
| Spielzeug | Episch | 1.200 | | Skyline-Stadt | Episch | 1.200 |
| Kuscheltiere | Legendär | 3.500 | | Unterwasser | Episch | 1.800 |
| | | | | Weltraum | Legendär | 4.500 |

Alles zusammen: 23.920 Münzen (ca. 10–12 Stunden ohne Robux).

## 5. Aussehen & Stimmung
- Bunter Cartoon-Stil, alles aus Roblox-Teilen gebaut
- Ansicht: Kamera hinter dem Avatar; der Schwertarm folgt dem Finger, die Wischspur leuchtet in der Farbe des Schwerts
- Sounds: Schwusch, Schnitt, Splatsch, Kombo, Bombe

## 6. Geld (Robux)
| Art | Angebot | Preis |
|---|---|---|
| Game Pass (einmalig) | Doppelte Münzen (wirkt mit dem Schwert-Bonus zusammen) | 149 R$ |
| Developer Product | 500 Münzen | 25 R$ |
| Developer Product | 1.500 Münzen | 69 R$ |
| Developer Product | 5.000 Münzen | 199 R$ |

Die IDs werden nach dem Anlegen im Creator Dashboard in `src/shared/Catalog.luau` (`Catalog.Robux`) eingetragen. Bis dahin zeigt der Shop „Bald verfügbar“. Keine bezahlten Zufallsboxen, kein Vorteil gegen andere Spieler.

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
- Preise sind Startwerte und lassen sich in `src/shared/Catalog.luau` ändern. Nach den ersten echten Spielern prüfen, wie viele Münzen eine Runde wirklich bringt.
