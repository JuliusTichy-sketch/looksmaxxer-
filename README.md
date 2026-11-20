# ✨ Looksmaxxer 3000

Ein augenzwinkerndes Idle-/Aufbauspiel im Browser: Bring deinen Charakter vom **NPC** zum **Kosmischen Glow-Wesen**.

## Dateien
| Datei | Wofür |
|---|---|
| `index.html` | Das komplette Spiel |
| `manifest.webmanifest`, `sw.js`, `icon-192.png`, `icon-512.png` | Damit man das Spiel als **App** installieren kann |

## Schnell spielen (ohne Internet)
Doppelklicke auf `index.html`. Fertig.

## Als App installieren
Dafür muss das Spiel einmal **ins Internet hochgeladen** werden (kostenlos):

**Variante A – Netlify Drop (am einfachsten)**
1. Gehe auf https://app.netlify.com/drop und lege dir ein kostenloses Konto an.
2. Ziehe den Ordner mit allen Spieldateien (oder das entpackte ZIP) auf die Seite.
3. Du bekommst eine Adresse wie `https://irgendwas.netlify.app`.

**Variante B – GitHub Pages** (dafür muss das Repository öffentlich sein)
1. Auf GitHub: *Settings → Pages → Branch* auswählen → *Save*.
2. Nach ca. 1 Minute erscheint dort die Adresse.

Dann die Adresse auf dem Handy öffnen:
- **Android (Chrome):** Menü ⋮ → *App installieren*
- **iPhone (Safari):** Teilen □↑ → *Zum Home-Bildschirm*
- **PC (Chrome/Edge):** Installieren-Symbol in der Adresszeile

Die App hat dann ein eigenes Symbol, startet im Vollbild und funktioniert auch offline.

## So spielst du
- **🪞 Glow-Up:** *Daily Routine* klicken, Upgrades kaufen, Titel freischalten, Glow Up (Prestige) machen.
- **💼 Jobs:** Mit einem Timing-Minispiel Geld verdienen. Je höher dein Glow-Score, desto bessere Jobs und mehr Lohn. Im Luxus-Shop gibt es Boosts.
- **🏙️ Stadt:** Herumlaufen (antippen oder Pfeiltasten/WASD), Leute als **Fans** gewinnen, Rivalen und Freunde zum **Mog Battle** herausfordern. Endboss **LEON** besiegen.
- **👥 Freunde:** Freundescode verschicken, Codes von Freunden einfügen, Charaktere vergleichen.
- **🏆 Leaderboard:** Glow-Power, Vermögen, Mog-Siege und Fans im Vergleich.

Der Spielstand wird automatisch im Browser gespeichert.

## 🎮 Roblox-Version
Im Ordner [`roblox/`](roblox/) liegt die Roblox-Version:
- `Looksmaxxer.rbxlx` – in Roblox Studio öffnen (File → Open from File)
- `ANLEITUNG.md` – Schritt-für-Schritt-Anleitung
- `src/` – der Code (Luau); `build_place.py` baut daraus die .rbxlx-Datei neu
