# 🎮 Looksmaxxer 3000 – Roblox-Version: Anleitung

## 1. Was du brauchst
- Einen **PC oder Mac** (Roblox Studio läuft nicht auf iPad/Handy)
- **Roblox Studio** (kostenlos): https://create.roblox.com → „Studio herunterladen“
- Ein Roblox-Konto

## 2. Spiel öffnen
1. Lade die Datei **`Looksmaxxer.rbxlx`** herunter.
2. Starte Roblox Studio und melde dich an.
3. Klicke auf **File → Open from File…** (Datei → Aus Datei öffnen) und wähle `Looksmaxxer.rbxlx`.
4. Im Fenster **Explorer** (rechts) siehst du jetzt:
   - `ReplicatedStorage › Shared` → **Config** (alle Spielwerte), Logic, Util
   - `ServerScriptService` → Main + Modules (der Server-Code)
   - `StarterPlayer › StarterPlayerScripts › Client` (Oberfläche & Effekte)

> Die Karte siehst du im Editor noch **nicht** – sie wird beim Start automatisch gebaut. Drück einfach auf **Play**.

## 3. Einmalige Einstellungen (wichtig!)
1. **Veröffentlichen:** File → **Publish to Roblox** → „Create new game“ → Name z. B. „Looksmaxxer 3000“ → Create.
   (Ohne Veröffentlichung kann Roblox keine Spielstände speichern.)
2. **Speichern in Studio erlauben:** Home → **Game Settings → Security** → **„Enable Studio Access to API Services“** einschalten → Save.
3. **Avatar-Typ R15:** Game Settings → **Avatar** → Avatar Type **R15** (sonst werden die Schultern beim Fitness-Training nicht breiter).
4. **100 Spieler pro Server:** Das stellst du im **Creator Hub** (create.roblox.com) ein: deine Experience → **Places** → Platz anklicken → bei der **Server-Größe / Max Players** 100 eintragen.

## 4. Testen
- **Play** (F5): Du spawnst in Glow City. Probiere: Daily Routine klicken, Upgrades kaufen, 🎁 Geschenkbox öffnen (Taste **E**), Rivale/Boss herausfordern, Portal benutzen.
- **Mit 2 Spielern testen (Mog Battle Spieler gegen Spieler):** Reiter **Test** → bei „Clients and Servers“ **2 Players** wählen → **Start**. Geh mit einem Spieler zum anderen und halte **E** bei „Mog Battle“.
- **Fehler finden:** View → **Output**. Wenn dort etwas Rotes steht, mach einen **Screenshot** und schick ihn mir – ich behebe es.
- Zum Schnell-Testen kannst du dir Aura geben: Im Output-Fenster unten in die Befehlszeile (während Play, Server-Ansicht) eingeben:
  `require(game.ServerScriptService.Modules.DataService).get(game.Players:GetPlayers()[1]).aura = 1e12`

## 5. Sounds einbauen
Roblox erlaubt nur Sounds aus der eigenen Bibliothek (wegen Urheberrecht).
1. Öffne die **Toolbox** (View → Toolbox) → oben **Audio** wählen.
2. Suche nach den Begriffen unten, hör rein (▶), dann **Rechtsklick → „Copy Asset ID“**.
3. Öffne `ReplicatedStorage › Shared › Config`, scrolle zu **Config.Sounds** und füge die ID so ein: `"rbxassetid://123456789"`.

| Eintrag | Wann | Suchbegriffe |
|---|---|---|
| Click | Daily Routine | „pop“, „click“ (ist schon eingestellt) |
| Buy | Upgrade kaufen | „cash register“, „ka-ching“, „coin“ |
| TitleUp | Neuer Titel | „phonk“, „cowbell“, „level up“ |
| BattleStart | Mog Battle beginnt | „vine boom“, „bass boom“, „dramatic“ |
| BattleWin | Mog Battle gewonnen | „phonk drop“, „victory“, „win“ |
| BattleLose | Gemoggt | „sad trombone“, „fail“ |
| Hatch | Box öffnen | „drum roll“ |
| HatchRare | Seltenes Pet | „anime wow“, „choir“, „rare“ |
| Rebirth | Rebirth | „power up“ |
| Error | Fehler | „error“, „bruh“ |
| Notify | Nachricht | „notification“ |

Unter **Config.Music** kannst du für jede der 8 Welten eine Hintergrundmusik eintragen (Suchbegriffe: „phonk“, „lofi“, „chill“, „epic“, „space ambient“).

## 6. Spiel anpassen
Fast alles steht in **Config** – ohne Programmierkenntnisse änderbar:
- Preise, Aura/s und Texte der **40 Upgrades**
- Die **8 Welten** (Multiplikator, Preis, nötige Rebirths, Farben, Licht)
- **Pets** pro Welt (Name, Emoji, Seltenheit) und Box-Preise
- **Rivalen & Bosse** (Stärke = `level` und `rebirths`)
- **Promo-Codes** (`Config.Codes`) – z. B. für Social Media
- Tägliche Belohnungen, Tränke, Rebirth-Shop, Titel

Nach Änderungen: **Play** drücken zum Testen, dann **File → Publish to Roblox**.

## 7. Karte von Hand verschönern (optional)
Die Karte wird per Code gebaut (`Modules › MapBuilder`). Wenn du sie selbst bearbeiten willst:
1. **Play** drücken → im Explorer `Workspace › Map` (und `NPCs`) markieren → **Strg+C**
2. **Stop** → `Workspace` anklicken → **Strg+V**
3. In `ServerScriptService › Main` die Zeile `MapBuilder.build()` lassen, aber in **MapBuilder** die Welt-Bauten nicht doppelt erzeugen – sag mir Bescheid, dann baue ich dir dafür einen Schalter ein.

## 8. Für alle veröffentlichen
1. Creator Hub → deine Experience → **Questionnaire** (Fragebogen zur Altersfreigabe) ausfüllen.
2. Beschreibung, Icon und Thumbnails hochladen.
3. Bei **Privacy/Zugriff** auf **Public** stellen.

## Was ist drin?
- 🪞 Daily Routine, 40 Upgrades in 8 Kategorien (bis Stufe 50), Aura/s, Glow-Score
- 🏷️ 15 Titel als Namensschild über dem Kopf, Glitzer-Aura, breitere Schultern durch Fitness
- 🌍 8 Welten mit eigener Karte, Licht, Portalen und Multiplikatoren
- 🎁 8 Geschenkboxen, 57 Pets (7 Seltenheiten inkl. GEHEIM), Pets folgen dir, Fusionieren zu Gold/Regenbogen/Diamant, Sammelbuch, Pity-System, Ansagen an alle Server
- ⚔️ Mog Battles gegen Spieler (mit Annehmen/Ablehnen), 8 Rivalen, 8 Bosse, Endboss **LEON** (5 % Chance auf „Leons Goldfisch“)
- ♻️ Rebirth + Rebirth-Shop (Pet-Plätze, Glück, Auto-Routine, 3er-Öffnen, Tempo, Offline-Zeit)
- 🏆 Globale Top-500-Rangliste über alle Server + Tafel in Glow City
- 📅 7-Tage-Belohnungen, 🎟️ Promo-Codes (MEWING2026, GIGACHAD, GLOWUP, LEON), 🧪 Tränke
- 😴 Offline-Verdienst, 💾 automatisches Speichern
