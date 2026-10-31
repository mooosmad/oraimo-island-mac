#!/usr/bin/env python3
"""Prepare (do not upload) a signed Sparkle feed using the local Keychain."""
import datetime
import email.utils
import pathlib
import plistlib
import subprocess
import sys
import xml.etree.ElementTree as ET

root = pathlib.Path(__file__).resolve().parent.parent
app = root / 'dist/Oraimo Island.app'
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
version = info['CFBundleShortVersionString']
archive = root / f'dist/Oraimo-Island-{version}.zip'
if not archive.is_file():
    sys.exit('Run scripts/package-update.sh first.')
sparkle = pathlib.Path(subprocess.check_output([str(root / 'scripts/fetch-sparkle.sh')], text=True).strip())
signer = sparkle / 'bin/sign_update'
account = 'io.github.mooosmad.OraimoIsland'
signature = subprocess.check_output([str(signer), '--account', account, '-p', str(archive)], text=True).strip()
ns = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ET.register_namespace('sparkle', ns)
rss = ET.Element('rss', version='2.0')
channel = ET.SubElement(rss, 'channel')
ET.SubElement(channel, 'title').text = 'Oraimo Island pour Mac'
ET.SubElement(channel, 'link').text = 'https://github.com/mooosmad/oraimo-island-mac'
ET.SubElement(channel, 'language').text = 'fr'
item = ET.SubElement(channel, 'item')
ET.SubElement(item, 'title').text = f'Oraimo Island {version}'
ET.SubElement(item, 'pubDate').text = email.utils.format_datetime(datetime.datetime.now(datetime.timezone.utc))
ET.SubElement(item, f'{{{ns}}}version').text = info['CFBundleVersion']
ET.SubElement(item, f'{{{ns}}}shortVersionString').text = version
ET.SubElement(item, f'{{{ns}}}minimumSystemVersion').text = info['LSMinimumSystemVersion']
ET.SubElement(item, 'description').text = 'Mise à jour Oraimo Island : améliorations et corrections. Téléchargement, installation et relance depuis cette fenêtre.'
ET.SubElement(item, 'enclosure', {
    'url': f'https://github.com/mooosmad/oraimo-island-mac/releases/download/v{version}/{archive.name}',
    f'{{{ns}}}edSignature': signature,
    'length': str(archive.stat().st_size),
    'type': 'application/octet-stream',
})
feed = root / 'dist/appcast.xml'
ET.indent(rss)
ET.ElementTree(rss).write(feed, encoding='utf-8', xml_declaration=True)
subprocess.run([str(signer), '--account', account, str(feed)], check=True)
subprocess.run([str(signer), '--account', account, '--verify', str(feed)], check=True)
subprocess.run([str(signer), '--account', account, '--verify', str(archive), signature], check=True)
print(f'Signed feed ready: {feed}')
