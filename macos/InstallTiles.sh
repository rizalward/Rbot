#!/bin/sh
# Real app lives in /Applications. Desktop + Dock tiles point at that path.
# iCloud Desktop eats signed .app bundles (no +x, no _CodeSignature) — never plant there.
set +e
APP="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
if [ ! -d "$APP" ]; then
  APP=$(ls -dt "$HOME/Library/Developer/Xcode/DerivedData/RIZALBOT-"*/Build/Products/Debug/RIZALBOT.app 2>/dev/null | head -1)
fi
if [ ! -d "$APP" ]; then
  echo "No RIZALBOT.app. Press Play in Xcode first."
  exit 0
fi

/usr/bin/killall RIZALBOT >/dev/null 2>&1
sleep 0.2

DEST="/Applications/RIZALBOT.app"
/bin/rm -rf "$DEST"
/bin/cp -R "$APP" "$DEST"
/bin/chmod 755 "$DEST/Contents/MacOS/RIZALBOT" 2>/dev/null
/bin/rm -f "$DEST/Contents/MacOS/"*.debug.dylib "$DEST/Contents/Frameworks/"*.debug.dylib 2>/dev/null
/usr/bin/xattr -d com.apple.quarantine "$DEST" 2>/dev/null
/usr/bin/xattr -dr com.apple.quarantine "$DEST" 2>/dev/null

# Desktop: drop any broken .app, put an alias so the stormling still sits on the desk
/bin/rm -rf "$HOME/Desktop/RIZALBOT.app"
/usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1
tell application "Finder"
  set desk to path to desktop folder
  try
    delete (every item of desk whose name is "RIZALBOT" and class is alias file)
  end try
  try
    delete (every item of desk whose name is "RIZALBOT.app")
  end try
  make alias file to POSIX file "/Applications/RIZALBOT.app" at desk with properties {name:"RIZALBOT"}
end tell
APPLESCRIPT

LS=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
[ -x "$LS" ] && "$LS" -f "$DEST" >/dev/null 2>&1

/usr/bin/python3 - <<'PY'
import os, plistlib, subprocess, tempfile
url = "file:///Applications/RIZALBOT.app/"
try:
    raw = subprocess.check_output(["defaults", "export", "com.apple.dock", "-"])
    data = plistlib.loads(raw)
except Exception:
    raise SystemExit(0)

def is_rizal(tile):
    td = tile.get("tile-data") or {}
    label = str(td.get("file-label") or td.get("file-display-name") or "")
    bid = str(td.get("bundle-identifier") or "")
    fd = td.get("file-data") or {}
    u = str(fd.get("_CFURLString") or "")
    return "rizalbot" in " ".join([label, bid, u]).lower()

kept = [t for t in data.get("persistent-apps", []) if not is_rizal(t)]
kept.append({
    "tile-type": "file-tile",
    "tile-data": {
        "file-data": {"_CFURLString": url, "_CFURLStringType": 15},
        "file-label": "RIZALBOT",
        "bundle-identifier": "io.github.rizaleon.rizalbot.mac",
    },
})
data["persistent-apps"] = kept
fd, path = tempfile.mkstemp(suffix=".plist")
os.close(fd)
with open(path, "wb") as f:
    plistlib.dump(data, f)
subprocess.run(["defaults", "import", "com.apple.dock", path], check=False)
os.unlink(path)
PY

/usr/bin/killall Dock >/dev/null 2>&1
echo "Seated /Applications/RIZALBOT.app — Desktop alias + Dock tile replaced"
exit 0
