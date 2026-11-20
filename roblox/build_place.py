"""
Baut aus dem Ordner src/ eine Roblox-Datei (Looksmaxxer.rbxlx),
die man in Roblox Studio mit "Datei > Öffnen" laden kann.

Regeln (wie bei Rojo):
  ordner/                -> Folder
  name.server.lua        -> Script
  name.client.lua        -> LocalScript
  name.lua               -> ModuleScript
  ordner/init.client.lua -> der Ordner wird ein LocalScript (andere Dateien darin = Kinder)
  ordner/init.server.lua -> der Ordner wird ein Script
  ordner/init.lua        -> der Ordner wird ein ModuleScript

Aufruf: python3 build_place.py
"""
import os
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
OUT = os.path.join(HERE, "Looksmaxxer.rbxlx")

# Welche Ordner in src/ zu welchem Roblox-Dienst gehören
SERVICES = [
    ("ReplicatedStorage", "ReplicatedStorage", None),
    ("ServerScriptService", "ServerScriptService", None),
    ("StarterPlayerScripts", "StarterPlayer", "StarterPlayerScripts"),
]

_ref = [0]


def ref():
    _ref[0] += 1
    return "RBX%08X" % _ref[0]


def cdata(text):
    # "]]>" darf in CDATA nicht vorkommen
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(cls, name, source=None, children=""):
    props = '<string name="Name">%s</string>' % escape(name)
    if source is not None:
        props += '<ProtectedString name="Source">%s</ProtectedString>' % cdata(source)
    return '<Item class="%s" referent="%s"><Properties>%s</Properties>%s</Item>\n' % (cls, ref(), props, children)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def script_class(filename):
    if filename.endswith(".server.lua"):
        return "Script", filename[: -len(".server.lua")]
    if filename.endswith(".client.lua"):
        return "LocalScript", filename[: -len(".client.lua")]
    if filename.endswith(".lua"):
        return "ModuleScript", filename[: -len(".lua")]
    return None, None


def build_dir(path, name):
    entries = sorted(os.listdir(path))
    init = None
    for cand, cls in (("init.server.lua", "Script"), ("init.client.lua", "LocalScript"), ("init.lua", "ModuleScript")):
        if cand in entries:
            init = (cand, cls)
    children = ""
    for e in entries:
        full = os.path.join(path, e)
        if init and e == init[0]:
            continue
        if os.path.isdir(full):
            children += build_dir(full, e)
        else:
            cls, nm = script_class(e)
            if cls:
                children += item(cls, nm, read(full))
    if init:
        return item(init[1], name, read(os.path.join(path, init[0])), children)
    return item("Folder", name, None, children)


def build_children(path):
    out = ""
    for e in sorted(os.listdir(path)):
        full = os.path.join(path, e)
        if os.path.isdir(full):
            out += build_dir(full, e)
        else:
            cls, nm = script_class(e)
            if cls:
                out += item(cls, nm, read(full))
    return out


def main():
    body = ""
    for folder, service, sub in SERVICES:
        path = os.path.join(SRC, folder)
        if not os.path.isdir(path):
            continue
        children = build_children(path)
        if sub:
            children = item(sub, sub, None, children)
        body += item(service, service, None, children)
    xml = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
           + body + "</roblox>\n")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(xml)
    print("Fertig:", OUT, "(%d Objekte)" % _ref[0])


if __name__ == "__main__":
    main()
