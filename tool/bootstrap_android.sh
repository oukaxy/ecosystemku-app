#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create --platforms=android --org com.oukaxy --project-name ecosystemku .
fi

python3 - <<'PY'
import pathlib
import re

app = pathlib.Path('android/app')

for name in ('build.gradle.kts', 'build.gradle'):
    path = app / name
    if not path.exists():
        continue
    text = path.read_text()
    text = text.replace('minSdk = flutter.minSdkVersion', 'minSdk = 26')
    text = text.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 26')
    text = text.replace('com.example.ecosystemku', 'com.oukaxy.ecosystemku')
    path.write_text(text)

manifest = app / 'src/main/AndroidManifest.xml'
text = manifest.read_text()
if 'android.permission.INTERNET' not in text:
    text = text.replace(
        '<application',
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
        1,
    )
text = re.sub(r'android:label="[^"]*"', 'android:label="EcosystemKu"', text)
if 'networkSecurityConfig' not in text:
    text = text.replace(
        '<application',
        '<application android:networkSecurityConfig="@xml/network_security_config"',
        1,
    )
manifest.write_text(text)

xml_dir = app / 'src/main/res/xml'
xml_dir.mkdir(parents=True, exist_ok=True)
(xml_dir / 'network_security_config.xml').write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<network-security-config>\n'
    '  <domain-config cleartextTrafficPermitted="true">\n'
    '    <domain includeSubdomains="false">localhost</domain>\n'
    '    <domain includeSubdomains="false">127.0.0.1</domain>\n'
    '  </domain-config>\n'
    '</network-security-config>\n'
)
PY
