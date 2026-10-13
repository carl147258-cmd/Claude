# Roblox-Spiele entwickeln: Der komplette Leitfaden

Stand: Oktober 2026. Zahlen zu Kosten und Regeln ändern sich bei Roblox häufig. Prüfe Gebühren, Auszahlungskurse und Veröffentlichungsregeln vor wichtigen Entscheidungen im [Creator Hub](https://create.roblox.com) und im [DevForum](https://devforum.roblox.com/c/updates/announcements).

---

## Inhalt

1. [Das Wichtigste in 60 Sekunden](#1-das-wichtigste-in-60-sekunden)
2. [Was du brauchst](#2-was-du-brauchst)
3. [Kosten – was ist gratis, was kostet Geld](#3-kosten)
4. [Wie du mit Roblox Geld verdienst (und wie viel realistisch ist)](#4-geld-verdienen)
5. [Veröffentlichen: Regeln seit 2026](#5-veröffentlichen-regeln-seit-2026)
6. [Die Herausforderungen – ehrlich](#6-die-herausforderungen)
7. [Fahrplan: Von null zum ersten Spiel](#7-fahrplan)
8. [Unser Projekt: „Mein erstes Obby“](#8-unser-projekt-mein-erstes-obby)
9. [Nach dem Start: Spieler gewinnen und halten](#9-nach-dem-start)
10. [Zusammenarbeit mit Claude: Du planst, Claude baut](#10-zusammenarbeit-mit-claude-du-planst-claude-baut)
11. [Lernquellen](#11-lernquellen)
12. [Quellen dieses Leitfadens](#12-quellen)

---

## 1. Das Wichtigste in 60 Sekunden

- **Ein Spiel zu bauen kostet 0 €.** Roblox Studio, Server, Speicherplatz und Hosting sind kostenlos.
- **Geld kostet es erst, wenn du es willst oder musst:**
  - Werbung schalten
  - Assets kaufen
  - Spiel für **alle Altersgruppen** freischalten (Roblox Plus für 4,99 $/Monat *oder* einmalig 1.000 Robux pro Spiel)
- **Verdienen:** Du bekommst **70 %** der Robux aus Game Passes und Developer Products. Auszahlen lässt du sie über **DevEx** zu ca. **0,0038 $ pro Robux**, ab **30.000 Robux** (≈ 114 $).
- **Die größte Hürde ist nicht die Technik, sondern Sichtbarkeit.** Es gibt Millionen Spiele. Die meisten haben fast keine Spieler. Rechne beim ersten Spiel mit **Lernen statt Einnahmen**.
- **Plan:**
  1. Studio lernen (1–2 Wochen)
  2. Das Obby aus diesem Repo bauen und anpassen (1–2 Wochen)
  3. Mit Freunden testen
  4. Veröffentlichen
  5. Daraus lernen
  6. Nächstes, größeres Spiel

---

## 2. Was du brauchst

| Was | Details |
|---|---|
| **Computer** | **Windows 10/11** oder **macOS**. Roblox Studio läuft **nicht** auf iPad, Handy, Chromebook oder Linux. Eine normale Maus mit Rechtsklick und Mausrad hilft sehr. |
| **Roblox-Account** | Kostenlos. **Unbedingt 2-Schritt-Verifizierung (2FA) einschalten.** Gestohlene Entwickler-Accounts sind ein echtes Problem, und 2FA ist für manche Veröffentlichungen Pflicht. |
| **Roblox Studio** | Kostenlos von [create.roblox.com](https://create.roblox.com) → „Start Creating“. |
| **Alter** | Bauen kann jeder mit Account. Für Veröffentlichung an 16+ brauchst du einen **Alterscheck**: unter 18 per Gesichts-Altersschätzung, ab 18 per Ausweis. Für **DevEx (Auszahlung in echtes Geld)** musst du mindestens 13 sein. **Unter 18: Eltern einbeziehen**, vor allem bei Geld, Ausweis und Steuern. |
| **Zeit** | Realistisch 5–10 Stunden pro Woche, um in 1–2 Monaten ein erstes ordentliches Spiel zu haben. |
| **Optional** | VS Code + Rojo (Code wie ein Profi verwalten), Blender (eigene 3D-Modelle, kostenlos), ein GitHub-Account (Sicherung des Codes, hast du schon). |

---

## 3. Kosten

### Kostenlos

| Posten | Kosten |
|---|---|
| Roblox Studio | 0 € |
| Server / Hosting (egal wie viele Spieler) | 0 € – Roblox bezahlt die Server |
| Spielstände speichern (DataStores) | 0 € (innerhalb der Limits, die mit der Spielerzahl wachsen) |
| Bilder, Sounds, Modelle hochladen | 0 € (mit monatlichen Upload-Limits für Audio) |
| Spiel privat oder für Freunde veröffentlichen | 0 € |
| Spiel für 16+ veröffentlichen | 0 € (Alterscheck nötig) |
| Tools: VS Code, Rojo, Blender, Git | 0 € |

### Kann Geld kosten

| Posten | Kosten | Nötig? |
|---|---|---|
| **Freischaltung „Alle Altersgruppen“** (Kinder unter 16) | **Roblox Plus 4,99 $/Monat** (2 Monate am Stück abonniert → keine Gebühr) **oder** einmalig **1.000 Robux pro Spiel**. Die 1.000 Robux bekommst du nach 3 Monaten zurück, wenn das Spiel nicht moderiert/entfernt wird. | Nur wenn du auch Kinder unter 16 erreichen willst. Zusätzlich braucht dein Spiel vorher eine Mindestzahl stark engagierter 16+-Spieler (siehe Kapitel 5). |
| **Werbung** (Ads Manager, „Sponsored“) | Frei wählbares Budget. Kampagnen starten schon mit wenigen Dollar pro Tag. Bezahlt wird mit Ad Credits, die du mit Geld oder Robux kaufst. | Optional, aber oft der einzige Weg zu den ersten Spielern. |
| **Robux für Tests/Gebühren** | Robux-Pakete im Roblox-Shop, Preis je nach Paket und Plattform | Nur für Gebühr/Werbung |
| **Assets** (Modelle, Musik, Plugins aus dem Creator Store) | Viele gratis, manche kosten Robux | Optional |
| **Gruppe erstellen** (Spiel unter Gruppennamen, Team) | Einmalig Robux-Gebühr | Optional |
| **Freelancer** (Builder, Modeler, Scripter, UI-Designer) | Frei verhandelbar, in Robux oder echtem Geld | Optional, eher später |

**Fazit Kosten:** Dein erstes Spiel kannst du komplett **ohne einen Cent** bauen und an 16+ veröffentlichen. Ein vernünftiges Startbudget, *wenn* du später Werbung testen willst: **20–50 €**. Das ist kein Muss.

---

## 4. Geld verdienen

### Wie das Geld fließt

```
Spieler kauft Game Pass für 100 Robux
        │
        ├── 30 Robux → Roblox (Marktplatz-Gebühr)
        └── 70 Robux → dein Konto (nach einer Wartezeit „pending“)
                │
                └── DevEx: 70 × 0,0038 $ ≈ 0,27 $
```

### Einnahmequellen

| Quelle | Was ist das | Beispiel im Obby |
|---|---|---|
| **Game Pass** | Einmalkauf, gilt für immer | „VIP: Trail + doppelte Sprungkraft“ |
| **Developer Product** | Kann beliebig oft gekauft werden | „Stufe überspringen“ (schon eingebaut!) |
| **Premium Payouts** | Roblox zahlt dir Robux für die **Spielzeit** von Premium-Abonnenten in deinem Spiel | Automatisch, kein Code nötig |
| **Abos** (Subscriptions) | Monatliches Abo im Spiel | Eher für große Spiele |
| **Avatar-Items (UGC)** | Kleidung/Accessoires verkaufen | Später, eigene Bewerbung nötig |
| **Rewarded Video Ads / Immersive Ads** | Werbung im Spiel, Roblox zahlt dir | Nur für berechtigte Spiele |

### DevEx (Robux → echtes Geld)

- Kurs: **0,0038 $ pro verdientem Robux**, gültig seit 5. September 2025. Davor verdiente Robux werden zum alten Kurs von 0,0035 $ ausgezahlt.
- Laut mehreren Rechner-Seiten gilt seit Juni 2026 ein höherer Kurs von etwa **0,0054 $**. Er gilt nur für Robux von **altersverifizierten 18+-Spielern aus den USA**. Das ist nicht offiziell bestätigt, also nicht damit planen.
- **Minimum: 30.000 verdiente Robux** (≈ 114 $).
- Nur *verdiente* Robux zählen. Gekaufte, geschenkte oder Premium-Stipendium-Robux zählen nicht.
- Voraussetzungen: mindestens 13 Jahre, verifizierte E-Mail, Account in gutem Zustand, Steuer-/Zahlungsdaten im DevEx-Portal.
- **Steuern:** DevEx-Einnahmen sind Einkommen. In Deutschland können sie steuerpflichtig sein, bei regelmäßigen Einnahmen ggf. mit Gewerbeanmeldung. **Bei Minderjährigen müssen Eltern das regeln.** Lass dich bei echten Einnahmen von einem Steuerberater beraten. Das hier ist keine Steuerberatung.

### Realistische Erwartung

| Szenario | Was passiert |
|---|---|
| **Erstes Spiel, ohne Werbung** | Oft 0–50 Spieler insgesamt, meist Freunde. Einnahmen ≈ 0. **Das ist normal.** Ziel ist Lernen. |
| **Gutes Spiel + kleine Werbung** | Einige hundert bis tausend Besuche. Vielleicht einige hundert Robux. |
| **Bis zur ersten Auszahlung** | 30.000 Robux = z. B. **429 Verkäufe à 100 Robux**. Das braucht ein Spiel mit regelmäßig Spielern. |
| **Erfolgreiche Spiele** | Werden meist von erfahrenen Teams gebaut, oft nach mehreren gescheiterten Spielen, und ständig aktualisiert. |

---

## 5. Veröffentlichen: Regeln seit 2026

Roblox hat 2025/2026 die Regeln deutlich verschärft, um Kinder besser zu schützen. Aktueller Stand (Einführung ab 19. Mai 2026):

| Stufe | Wer darf spielen | Was du brauchst |
|---|---|---|
| **Persönlich / privat** | Du und Leute, die du einlädst | Account in gutem Zustand |
| **Vertraute Freunde & 16+** | Alle ab 16 Jahren | **Alterscheck**: unter 18 per Gesichtsschätzung, ab 18 per Ausweis |
| **Alle Altersgruppen** (inkl. Roblox Kids 5–8 und Select 9–15) | Alle | ID-Verifizierung/Alterscheck, **2FA**, ausgefüllter **Fragebogen zur Inhaltsreife**, **Roblox Plus/Premium** *oder* einmalige 1.000-Robux-Gebühr, *und* genug stark engagierte, altersgeprüfte 16+-Spieler |

Zur Mindestzahl stark engagierter 16+-Spieler machen die Quellen unterschiedliche Angaben: **250 in 60 Tagen** (Help Center) oder **500 in 30–60 Tagen** (DevForum/Drittseiten). Deinen aktuellen Status siehst du im Creator Hub unter den Einstellungen zur Veröffentlichungs-Berechtigung (Eligibility).

**Was das für dich bedeutet:** Dein Spiel startet realistisch als **16+-Spiel**. Erst wenn es dort genug Spieler hat, kannst du es für Kinder freischalten. Ein Obby ist inhaltlich kinderfreundlich. Den Fragebogen zur Inhaltsreife musst du trotzdem ehrlich ausfüllen.

---

## 6. Die Herausforderungen

| # | Herausforderung | Warum es schwer ist | Was hilft |
|---|---|---|---|
| 1 | **Sichtbarkeit** | Millionen Spiele. Roblox empfiehlt vor allem Spiele, in denen Spieler **lange bleiben und wiederkommen**. | Starke erste Minute, gutes Icon/Thumbnail, regelmäßige Updates, Freunde einladen, kleine Werbetests, TikTok/YouTube-Shorts vom Spiel |
| 2 | **Neue Veröffentlichungsregeln** | Für Spieler unter 16 brauchst du erst genug 16+-Spieler | Erst 16+-Publikum aufbauen, Spiel ab Tag 1 kinderfreundlich halten |
| 3 | **Programmieren lernen (Luau)** | Neue Denkweise: Server vs. Client, Events | Mit fertigem Code starten (unser Obby), kleine Änderungen machen, nachfragen |
| 4 | **Server/Client verstehen** | Wichtigster Anfängerfehler: Logik im falschen Script → funktioniert nicht oder ist hackbar | Regel: **Der Server entscheidet alles, der Client fragt nur.** |
| 5 | **Exploiter (Cheater)** | Cheater können alles am Client verändern und jedes RemoteEvent mit falschen Daten aufrufen | Alles serverseitig prüfen. Unser Obby zählt nur die *nächste* Stufe. |
| 6 | **Datenverlust** | Falsches Speichern = Spieler verlieren Fortschritt = schlechte Bewertungen | Bewährtes Speichersystem (ist eingebaut), mit 2 Spielern und Server-Neustart testen |
| 7 | **Backdoors in Gratis-Modellen** | Modelle aus der Toolbox können **versteckte Schadscripts** enthalten. Damit können andere dein Spiel übernehmen. | Nur vertrauenswürdige Modelle nutzen, jedes Modell nach `Script`/`require(` durchsuchen, Scripts löschen, die du nicht verstehst |
| 8 | **Handys** | Die meisten Spieler spielen am Handy: kleine Bildschirme, keine Tastatur, schwächere Geräte | Große Knöpfe, Testen mit dem **Device Simulator** in Studio, wenige Teile |
| 9 | **Leistung (Lag)** | Zu viele Teile/Scripts → Ruckeln | Teile verankern (Anchored), Effekte auf dem Client, MicroProfiler (Strg+F6) |
| 10 | **Regeln & Moderation** | Verstöße gegen Community-Standards → Spiel oder Account gesperrt | Keine fremden Marken/Musik, Spielertext filtern, keine Links nach außen, ehrlicher Reife-Fragebogen |
| 11 | **Faire Monetarisierung** | Pay-to-win vertreibt Spieler. Glücksspiel-ähnliche Käufe (Lootboxen) sind in manchen Ländern verboten. | Bequemlichkeit und Kosmetik verkaufen. Lootboxen nur mit `PolicyService`-Prüfung. |
| 12 | **Durchhalten** | Erste Spiele floppen fast immer | Klein anfangen, fertig machen, veröffentlichen, nächstes Spiel. **Fertig > perfekt.** |
| 13 | **Account-Sicherheit** | Account weg = Spiel weg | 2FA, nie Cookies oder Passwort teilen, keine „Gratis-Robux“-Seiten |
| 14 | **Code verlieren** | Studio-Dateien gehen kaputt oder verloren | Code in Git/GitHub (dieses Repo), Studio speichert Versionen beim Veröffentlichen |

---

## 7. Fahrplan

### Woche 0: Einrichten (1 Abend)

- [ ] Roblox-Account mit **2FA** absichern.
- [ ] Roblox Studio installieren, einloggen.
- [ ] In Studio über das Menü **Window** die Fenster **Explorer**, **Properties** und **Output** öffnen. Diese drei Fenster brauchst du immer.

### Woche 1–2: Studio-Grundlagen

- [ ] Bewegen in der 3D-Ansicht: rechte Maustaste + WASD, Mausrad.
- [ ] Teile einfügen, verschieben, skalieren, drehen (Tasten: 2 = Verschieben, 3 = Skalieren, 4 = Drehen).
- [ ] Eigenschaften ändern: Farbe, Material, **Anchored**, **CanCollide**.
- [ ] Das erste Script: ein Teil, das bei Berührung tötet.
- [ ] Verstehen: **Script** (Server) vs. **LocalScript** (Client) vs. **ModuleScript** (wiederverwendbarer Code).
- [ ] Offizielle Tutorials: [create.roblox.com/docs/tutorials](https://create.roblox.com/docs/tutorials).

### Woche 2–4: Unser Obby bauen und zu deinem machen

- [ ] Projekt aus `games/mein-erstes-obby/` einrichten (Anleitung siehe Kapitel 8).
- [ ] Spielen, verstehen, Fragen stellen.
- [ ] Anpassen: Farben, Themen, eigene Hindernisse, Anzahl Stufen.
- [ ] Icon (512×512) und 2–3 Thumbnails (1920×1080) erstellen.

### Woche 4–5: Testen und Veröffentlichen

- [ ] Als **privat** veröffentlichen, Speichern testen, mit 2 Spielern testen.
- [ ] Am Handy testen (Device Simulator + echtes Handy).
- [ ] Freunde/Familie spielen lassen. **Beobachte schweigend**, wo sie hängen bleiben.
- [ ] Alterscheck machen → für **16+** veröffentlichen.
- [ ] Fragebogen zur Inhaltsreife ausfüllen, Beschreibung, Genre einstellen.

### Ab Woche 6: Wachsen

- [ ] „Stufe überspringen“ aktivieren, später einen VIP Game Pass.
- [ ] Optional: kleine Werbekampagne (z. B. 5 $/Tag für ein paar Tage) und messen.
- [ ] Analytics im Creator Hub ansehen: Wie lange bleiben Spieler? Bei welcher Stufe hören sie auf?
- [ ] Wöchentlich ein kleines Update.
- [ ] Wenn genug engagierte 16+-Spieler da sind: für alle Altersgruppen freischalten.

---

## 8. Unser Projekt: „Mein erstes Obby“

**Warum ein Obby?** Es ist das beste erste Projekt: wenig Code, sofort spielbar, und es enthält schon alle wichtigen Grundbausteine: Speichern, Server/Client, Monetarisierung und Cheat-Schutz. Viele der erfolgreichsten Roblox-Spiele sind Obbys.

**Wo:** [`games/mein-erstes-obby/`](../games/mein-erstes-obby/) — komplette Einrichtungsanleitung in der [README](../games/mein-erstes-obby/README.md).

**Was schon fertig ist:**

| Funktion | Datei |
|---|---|
| 15 Stufen werden automatisch gebaut, Schwierigkeit steigt | `src/server/CourseBuilder.luau` |
| Fortschritt speichern und laden, Auto-Speichern, Speichern beim Server-Stopp | `src/server/PlayerData.luau` |
| Checkpoints, Respawn am Checkpoint, Schutz vor Überspringen | `src/server/Checkpoints.luau` |
| Lava und verschwindende Plattformen (über Tags) | `src/server/Hazards.luau` |
| Kauf „Stufe überspringen“, sicher gegen Doppel-Gutschriften | `src/server/Monetization.luau` |
| Anzeige „Stufe X / 15“ und Kauf-Knopf, handytauglich | `src/client/init.client.luau` |
| Alle Einstellungen an einem Ort | `src/shared/Config.luau` |

**Geprüft:** Der Code kompiliert und besteht die Luau-Typprüfung gegen die Roblox-API (luau-lsp). Formatiert ist er mit StyLua. **Im echten Roblox Studio wurde er noch nicht gestartet**, da das hier nicht möglich ist. Wenn etwas im Output-Fenster rot erscheint: Fehlermeldung kopieren und mir schicken.

**So sieht der Server/Client-Aufbau aus:**

```
SERVER (entscheidet)                          CLIENT (zeigt an)
─────────────────────                         ─────────────────
CourseBuilder  → baut Parcours ─────────────► sieht Parcours
Checkpoints    → prüft Berührung,
                 setzt Stufe ─► leaderstats ─► Anzeige "Stufe 5/15"
PlayerData     → lädt/speichert
Monetization   ◄──── Roblox-Kaufsystem ◄───── Knopf "Überspringen"
Hazards        → Lava tötet, Plattformen verschwinden
```

---

## 9. Nach dem Start

**Was Roblox misst und belohnt:**

- **Verweildauer pro Sitzung:** Wie lange bleibt ein Spieler?
- **Wiederkehr nach 1 und 7 Tagen (D1/D7):** Kommt er zurück?
- **Qualifizierte Spielrate:** Klickt man aufs Thumbnail *und* bleibt man danach?
- **Käufe** und **soziale Signale**, z. B. mit Freunden spielen.

**Hebel fürs Obby:**

1. **Die erste Minute:** Stufe 1 sofort verständlich, erstes Erfolgserlebnis nach 20 Sekunden.
2. **Ziel immer sichtbar:** „Stufe 5 / 15“ ist schon eingebaut.
3. **Neue Welten nachliefern:** Jede Woche 5–10 neue Stufen geben Spielern einen Grund zurückzukommen.
4. **Tägliche Belohnung**, Bestenlisten, Gruppen-Belohnung („Tritt der Gruppe bei → Trail“).
5. **Thumbnail/Icon:** Klar, farbig, zeigt Gameplay. A/B-Tests im Creator Hub nutzen.
6. **Daten lesen:** Analytics → bei welcher Stufe hören die meisten auf? Diese Stufe leichter machen.

---

## 10. Zusammenarbeit mit Claude: Du planst, Claude baut

### Zwei Arbeitsweisen

| | **A. Claude direkt in Roblox Studio** (empfohlen) | **B. Claude in der Cloud** (so wie jetzt) |
|---|---|---|
| Wie | Claude Code läuft auf deinem PC. Studio ist über die offizielle Roblox-Schnittstelle (Studio MCP) verbunden. | Claude schreibt Code ins GitHub-Repo, du holst ihn in Studio. |
| Was Claude kann | Spielwelt lesen und bauen, Scripts schreiben, **Testspiele selbst starten**, Fehler im Output lesen, **Screenshots ansehen**, Spieler-Eingaben simulieren | Code schreiben, Welten per Code erzeugen, Code automatisch prüfen (Format, Fehler, Typen) |
| Was du machst | Plan geben, Ergebnisse anspielen, Feedback geben, Aktionen bestätigen | Plan geben, Code in Studio übernehmen, testen, Fehler zurückmelden |
| Selbstständigkeit | **Hoch**: Claude prüft selbst, ob es funktioniert | Mittel: Testen in Studio bleibt bei dir |

**Einrichtung A (einmalig, ca. 15 Minuten):**
1. Claude Code auf deinem PC installieren (Anleitung: [code.claude.com](https://code.claude.com)) und dieses GitHub-Repo auf deinen PC klonen.
2. Roblox Studio aktualisieren und dein Spiel öffnen.
3. In Studio: **Assistant** → **…** → **Manage MCP Servers** → **Enable Studio as MCP server** einschalten.
4. Darunter bei **Quick connect** den Eintrag **Claude Code** einschalten.
5. Studio und Claude Code neu starten. Ein grüner Punkt zeigt die Verbindung an.
6. Claude Code im Repo-Ordner starten. Ich lade dann automatisch das ganze Roblox-Wissen aus diesem Repo.

**Sicherheit:** Verbinde nur Programme, denen du vertraust. Die Schnittstelle kann deine geöffneten Spiele verändern. Lege Sicherungen an (File → Save to File) und arbeite an einer Testkopie, nicht am Live-Spiel.

### So läuft ein Projekt ab

1. **Plan:** Du füllst [`SPIELPLAN-VORLAGE.md`](SPIELPLAN-VORLAGE.md) aus, alleine oder mit mir im Gespräch. Was offen ist, schlage ich vor.
2. **„Go“:** Ich setze Meilenstein für Meilenstein um. Jeder Meilenstein ist für sich spielbar.
3. **Bericht:** Nach jedem Meilenstein bekommst du von mir:
   - was gebaut wurde
   - wie du es ausprobierst
   - was ich geprüft habe und was noch offen ist
4. **Feedback:** Du spielst und sagst, was dir gefällt und was nicht. Ich passe an.
5. **Nur du entscheidest:** Idee, Name, Stil, Preise, alles was echtes Geld kostet, und die Veröffentlichung.

### Was Claude kostet

| Posten | Kosten | Hinweis |
|---|---|---|
| Claude-Abo mit Claude Code | **Pro ca. 20 $/Monat**, Max ca. 100 $ oder 200 $/Monat | Für den Start reicht Pro. Max lohnt sich nur bei sehr viel täglicher Arbeit, weil die Nutzungsgrenzen höher sind. Aktuelle Preise: [claude.com/pricing](https://claude.com/pricing) |
| Roblox Studio MCP | 0 € | In Studio eingebaut |
| GitHub, automatische Code-Prüfung | 0 € | Für öffentliche und kleine private Repos im Gratis-Kontingent |

Die Claude-Preise stammen von Vergleichsseiten, nicht direkt von Anthropic. Maßgeblich ist die Preisseite.

### Optional: Automatisch veröffentlichen

Mit einem **Open-Cloud-API-Schlüssel** (Creator Dashboard → Open Cloud → API Keys) kann GitHub jede fertige Version automatisch in ein **Test-Spiel** hochladen. Den Schlüssel trägst du selbst als GitHub-Secret ein. **Schick ihn nie in den Chat.** Das richten wir ein, sobald dein erstes Spiel steht.

---

## 11. Lernquellen

| Quelle | Wofür |
|---|---|
| [Roblox Creator Hub – Docs & Tutorials](https://create.roblox.com/docs) | Offizielle Doku, Einsteiger-Tutorials, API-Referenz |
| [DevForum](https://devforum.roblox.com) | Ankündigungen, Hilfe, Community-Ressourcen |
| [Luau-Sprache](https://luau.org) | Die Programmiersprache selbst |
| YouTube: „Roblox Studio Beginner Tutorial“, z. B. BrawlDev, TheDevKing, GnomeCode | Video-Kurse |
| Dieses Repo + Claude | Fragen stellen, Code erklären lassen, Funktionen einbauen lassen |

---

## 12. Quellen

Die Kosten- und Regelangaben stammen aus diesen Quellen. Wo sie sich widersprechen, steht es oben dabei.

- [Roblox DevForum: New Requirements to Publish and Update Public Experiences](https://devforum.roblox.com/t/new-requirements-to-publish-and-update-public-experiences/4143953)
- [Roblox DevForum: New Publishing Requirements & Evaluation Process for Games](https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166)
- [Roblox DevForum: AMA Publishing Requirements + Roblox Kids & Select](https://devforum.roblox.com/t/ama-publishing-requirements-roblox-kids-select/4580953)
- [Roblox Help: How to Publish Games on Roblox](https://en.help.roblox.com/hc/en-us/articles/203313890-How-to-Publish-Games-on-Roblox)
- [Roblox (RTC auf X): 1.000-Robux-Gebühr statt Plus/Premium-Pflicht](https://x.com/Roblox_RTC/status/2053937371364925595)
- [Roblox Investor Relations: Roblox Plus angekündigt](https://ir.roblox.com/news/news-details/2026/Roblox-Announces-Roblox-Plus-a-New-Subscription-Plan-Offering-Exclusive-Platform-Benefits/default.aspx)
- [Roblox Newsroom: Introducing Roblox Plus](https://about.roblox.com/newsroom/2026/04/introducing-roblox-plus-subscription)
- [Roblox DevForum: Unified Marketplace Fee for Dev Products and Game Passes (30 %)](https://devforum.roblox.com/t/unified-marketplace-fee-for-dev-products-and-game-passes/507109)
- [Roblox Docs: Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager)
- DevEx-Kurs und Minimum (Drittseiten, nicht offiziell): [devex.gg](https://devex.gg/), [BloxToolbox](https://bloxtoolbox.com/pages/tools/devex-cashout-calculator.html), [generalistprogrammer.com](https://generalistprogrammer.com/tools/robux-to-usd-calculator), [bloxsniper.cc](https://bloxsniper.cc/tools/devex-calculator)
- [Roblox Docs: Connect to the Roblox Studio MCP server](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md)
- [Roblox Docs: Usage guide for place publishing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-place-publishing.md)
- [Roblox: place-ci-cd-demo](https://github.com/Roblox/place-ci-cd-demo)
- Claude-Preise (Drittseiten): [superblocks.com](https://www.superblocks.com/blog/claude-code-pricing), [noqta.tn](https://www.noqta.tn/blog/claude-code-pricing-2026)
