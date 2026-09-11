#!/bin/sh
# Replace Desktop + Applications + Dock tiles with this build. Same paths every time.
set +e
APP="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
if [ ! -d "$APP" ]; then
  APP=$(ls -dt "$HOME/Library/Developer/Xcode/DerivedData/RIZALBOT-"*/Build/Products/Debug/RIZALBOT.app 2>/dev/null | head -1)
fi
if [ ! -d "$APP" ]; then
  echo "No RIZALBOT.app to install. Press Play in Xcode first."
  exit 0
fi

/usr/bin/killall RIZALBOT >/dev/null 2>&1
sleep 0.2

plant() {
  DEST="$1"
  /bin/rm -rf "$DEST"
  /bin/cp -R "$APP" "$DEST"
  /bin/rm -f "$DEST/Contents/MacOS/"*.debug.dylib "$DEST/Contents/Frameworks/"*.debug.dylib 2>/dev/null
  /usr/bin/xattr -cr "$DEST" 2>/dev/null
  /usr/bin/touch "$DEST"
}

plant "$HOME/Desktop/RIZALBOT.app"
plant "/Applications/RIZALBOT.app"

LS=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
[ -x "$LS" ] && "$LS" -f "$HOME/Desktop/RIZALBOT.app" "/Applications/RIZALBOT.app" >/dev/null 2>&1

/usr/bin/python3 - <<'PY'
import os, plistlib, subprocess, tempfile
from pathlib import Path

url = (Path.home() / "Desktop" / "RIZALBOT.app").as_uri()
if not url.endswith("/"):
    url += "/"
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
    blob = " ".join([label, bid, u]).lower()
    return "rizalbot" in blob

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
echo "Tiles updated: Desktop + Applications + Dock"
exit 0
