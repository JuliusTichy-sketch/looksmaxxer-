"""
Baut aus src/ drei Modell-Dateien (.rbxmx) zum Einfügen in ein geöffnetes Spiel
(z. B. wenn "Veröffentlichen als" hängt):
  Modelle/1_Shared.rbxmx               -> in ReplicatedStorage (ersetzt "Shared")
  Modelle/2_ServerScriptService.rbxmx  -> in ServerScriptService (ersetzt "Main" und "Modules")
  Modelle/3_Client.rbxmx               -> in StarterPlayer > StarterPlayerScripts (ersetzt "Client")
Aufruf: python3 build_models.py
"""
import os
import build_place as bp

OUTDIR = os.path.join(bp.HERE, "Modelle")
HEAD = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n')


def write(name, body):
    path = os.path.join(OUTDIR, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(HEAD + body + "</roblox>\n")
    print("Fertig:", path)


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    write("1_Shared.rbxmx", bp.build_children(os.path.join(bp.SRC, "ReplicatedStorage")))
    write("2_ServerScriptService.rbxmx", bp.build_children(os.path.join(bp.SRC, "ServerScriptService")))
    write("3_Client.rbxmx", bp.build_children(os.path.join(bp.SRC, "StarterPlayerScripts")))


if __name__ == "__main__":
    main()
