"""Validate the actual APK's packaged catalog, symbol imports and Android version."""
import hashlib
import json
import re
import struct
import sys
import zipfile
from pathlib import Path

apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    paths = archive.namelist()
    assert not any(name.startswith('assets/build/') for name in paths), 'Review artifacts were exported into the app'
    for filename in ['technical_catalog.json', 'technical_visual_audit.json', 'warning_lights.json', 'dtc_catalog.json']:
        bundled = archive.read('assets/data/' + filename)
        assert json.loads(bundled) == json.loads(Path('data', filename).read_text()), 'Packaged data mismatch: ' + filename
    imports = [name for name in paths if name.startswith('assets/assets/warning_lights/') and name.endswith('.svg.import')]
    assert len(imports) == 18
    batch = json.loads(Path('docs/audits/batches/cbzb_3node_reference_batch_v1/manifest.json').read_text())
    for spec in batch['nodes']:
        source = spec['app_asset_path']
        assert hashlib.sha256(Path(source).read_bytes()).hexdigest() == spec['image_sha256']
        import_name = 'assets/' + source + '.import'
        imported = archive.read(import_name).decode('utf-8')
        # Godot exports imported textures rather than the source WebP bytes.
        destinations = set(re.findall(r'"(res://[^"\n]+\.ctex)"', imported))
        assert destinations, 'Missing texture remap: ' + source
        for destination in destinations:
            local = Path(destination.removeprefix('res://'))
            bundled = archive.read('assets/' + str(local))
            assert bundled == local.read_bytes(), 'Packaged texture mismatch: ' + source
    print('APK_CBZB_3NODE_TEXTURES=PASS imported_resources=3')
    manifest = archive.read('AndroidManifest.xml')
    offset = 8
    strings = []
    attributes = {}
    while offset < len(manifest):
        kind, header, size = struct.unpack_from('<HHI', manifest, offset)
        if kind == 1:
            count, styles, flags, start, style_start = struct.unpack_from('<IIIII', manifest, offset + 8)
            def length8(index):
                value = manifest[index]
                return (((value & 127) << 8) | manifest[index + 1], index + 2) if value & 128 else (value, index + 1)
            def length16(index):
                value = struct.unpack_from('<H', manifest, index)[0]
                return (((value & 32767) << 16) | struct.unpack_from('<H', manifest, index + 2)[0], index + 4) if value & 32768 else (value, index + 2)
            for index in range(count):
                position = offset + start + struct.unpack_from('<I', manifest, offset + header + index * 4)[0]
                if flags & 256:
                    _, position = length8(position)
                    length, position = length8(position)
                    strings.append(manifest[position:position + length].decode('utf-8'))
                else:
                    length, position = length16(position)
                    strings.append(manifest[position:position + length * 2].decode('utf-16-le'))
        elif kind == 0x102:
            name = struct.unpack_from('<I', manifest, offset + 20)[0]
            if strings[name] == 'manifest':
                attr_start, attr_size, count = struct.unpack_from('<HHH', manifest, offset + 24)
                for index in range(count):
                    position = offset + 16 + attr_start + index * attr_size
                    _, key, raw = struct.unpack_from('<III', manifest, position)
                    value_type = manifest[position + 15]
                    data = struct.unpack_from('<I', manifest, position + 16)[0]
                    attributes[strings[key]] = strings[raw] if raw != 0xffffffff else (strings[data] if value_type == 3 else data)
                break
        offset += size
    assert attributes['versionCode'] == 69, attributes
    assert attributes['versionName'] == '0.20.29', attributes
    assert attributes['package'] == 'com.yetigarage.app', attributes
print('APK_CONTENTS=PASS version=0.20.29 versionCode=69 catalog_and_audit_packaged=YES warning_imports=18 review_artifacts_excluded=YES')
print('APK_SHA256=' + hashlib.sha256(apk.read_bytes()).hexdigest())
