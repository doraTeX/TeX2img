"""実際の配布関数が最低OSを更新し、タグ欠落時は元ファイルを壊さないことを検証。"""
from pathlib import Path
import os
import plistlib
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'scripts/release-gui.sh').read_text()
function = source[source.index('publish_gui_appcast() {'):source.index('\narchive_gui\n')]
with tempfile.TemporaryDirectory(prefix='tex2img-appcast-') as directory:
    path = Path(directory)
    contents = path / 'Test.app/Contents'
    contents.mkdir(parents=True)
    (contents / 'Info.plist').write_bytes(plistlib.dumps({'LSMinimumSystemVersion': '12.0'}))
    signer = path / 'sign-update-stub'
    signer.write_text('#!/bin/sh\nprintf \'sparkle:edSignature="TEST-SIGNATURE" length="123"\\n\'\n')
    signer.chmod(0o755)
    key = path / 'test-key-placeholder'
    key.touch()
    dmg = path / 'TeX2img_3.0.2.dmg'
    dmg.touch()
    script = path / 'test.sh'
    script.write_text('set -euo pipefail\n' + function + '\npublish_gui_appcast "$1"\n')
    appcast = path / 'feed.xml'
    env = dict(os.environ, PRODUCT_NAME='TeX2img', APPCAST_XML=str(appcast),
               ARCHIVED_APP=str(contents.parent), SPARKLE_SIGN_UPDATE=str(signer), ED_PRIVATE_KEY=str(key))
    for minimum in ['<sparkle:minimumSystemVersion>10.13</sparkle:minimumSystemVersion>', '']:
        original = f'''<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><item>
{minimum}
<enclosure url="https://example.invalid/TeX2img_2.4.3.dmg"
sparkle:version="2.4.3"
sparkle:edSignature="OLD"
length="1" />
</item></channel></rss>'''
        appcast.write_text(original)
        result = subprocess.run(['bash', str(script), str(dmg)], env=env, capture_output=True, text=True)
        if minimum:
            assert result.returncode == 0, result.stderr
            item = ET.parse(appcast).getroot().find('channel/item')
            assert item.find('{http://www.andymatuschak.org/xml-namespaces/sparkle}minimumSystemVersion').text == '12.0'
            assert item.find('enclosure').attrib['url'].endswith('TeX2img_3.0.2.dmg')
        else:
            assert result.returncode != 0
            assert appcast.read_text() == original
    print('Appcast最低OS反映・タグ欠落時の保護: 成功（実際の配布・鍵へのアクセスなし）')
