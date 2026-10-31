#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Oraimo Island.app"
codesign --verify --deep --strict "$APP"
otool -L "$APP/Contents/MacOS/OraimoIsland" | grep -q '@rpath/Sparkle.framework/'
python3 - "$APP" <<'PY'
import base64,pathlib,plistlib,subprocess,sys
app=pathlib.Path(sys.argv[1]);p=plistlib.loads((app/'Contents/Info.plist').read_bytes())
for binary in [app/'Contents/MacOS/OraimoIsland',app/'Contents/Frameworks/Sparkle.framework/Sparkle']:
    assert {'arm64','x86_64'}.issubset(subprocess.check_output(['xcrun','lipo','-archs',str(binary)],text=True).split())
assert len(base64.b64decode(p['SUPublicEDKey'],validate=True))==32
assert p['SUFeedURL']=='https://raw.githubusercontent.com/mooosmad/oraimo-island-mac/updates/appcast.xml'
assert p['SURequireSignedFeed'] and p['SUVerifyUpdateBeforeExtraction']
assert not p['SUEnableSystemProfiling'] and p['SUScheduledCheckInterval']==3600
assert (app/'Contents/Resources/Sparkle-LICENSE.txt').is_file()
print('PASS: universal app, embedded Sparkle, signed-feed configuration and licence')
PY
