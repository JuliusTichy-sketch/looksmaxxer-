# Hinweise für Claude

## Vor jeder Änderung
- Zuerst den neuesten Stand holen: `git pull` auf dem Branch `claude/inspiring-cerf-lu4jgq`.
  Das Spiel wird auch aus einer anderen Sitzung (Roblox Studio) aktualisiert, die Werte in die Config einträgt.

## Diese Werte in `roblox/src/ReplicatedStorage/Shared/Config.lua` niemals leeren oder auf 0 zurücksetzen
- `Config.Sounds`: Sound-IDs (nur `Click` bleibt absichtlich leer, der Nutzer will keinen Klick-Sound).
- `Config.Music`: Musik-IDs für alle 8 Welten.
- `Config.GamePasses` und `Config.DevProducts`: die `id`-Werte sind echte, bei Roblox angelegte Produkte
  (Universe 10778030768). Wenn neue Produkte dazukommen, neue Einträge mit `id = 0` anlegen und dem
  Nutzer sagen, dass sie noch bei Roblox erstellt werden müssen – bestehende IDs nicht verändern.

## Nach Änderungen
- `python3 roblox/build_place.py` ausführen, damit `roblox/Looksmaxxer.rbxlx` zum Quellcode passt.

## Zum Spiel
- Roblox-Spiel „Looksmaxxer 3000“, Place-ID 134889286316255, Universe-ID 10778030768, öffentlich ab 16 Jahren.
- Der Nutzer hat keine Programmiererfahrung: Erklärungen auf Deutsch und in einfachen Worten.
