"""Validate review coverage and unchanged baseline; does not certify visual accuracy."""
import collections
import json
import subprocess
from pathlib import Path

BASE = '52b973888306662b65606e7bc8d7cd14edae339d'

def nodes(catalog):
    result = {}
    def visit(rows):
        for row in rows:
            if row.get('diagram'): result[row['id']] = row
            visit(row.get('nodes', row.get('children', [])))
    visit(catalog['sections'])
    return result

old = json.loads(subprocess.check_output(['git', 'show', BASE + ':data/technical_catalog.json']))
new = json.loads(Path('data/technical_catalog.json').read_text())
review = json.loads(Path('docs/audits/full_marker_visual_review.json').read_text())
assert review == json.loads(Path('data/technical_visual_audit.json').read_text())
a, b = nodes(old), nodes(new)
assert len(new['sections']) == 24 and len(a) == len(b) == len(review['nodes']) == 90
assert a.keys() == b.keys() == review['nodes'].keys()
markers = 0
changes = 0
for nid, row in b.items():
    record = review['nodes'][nid]
    assert record['visually_opened'] and record['finding_ru'] and record['source']
    image = row['diagram']['image'].removeprefix('res://')
    assert Path(image).read_bytes() == subprocess.check_output(['git', 'show', BASE + ':' + image]), image
    expected = json.loads(json.dumps(a[nid]))
    seen = set()
    assert len(row['diagram']['markers']) == len(record['markers'])
    for index, (point, original, note) in enumerate(zip(row['diagram']['markers'], a[nid]['diagram']['markers'], record['markers'])):
        assert point['number'] == original['number'] == note['number']
        assert point['part_id'] == original['part_id'] == note['part_id']
        assert point['number'] not in seen and float(point['number']).is_integer()
        seen.add(point['number'])
        assert 0 <= point['x'] <= 1 and 0 <= point['y'] <= 1
        assert note['name_ru'] and note['finding_ru'] and note['documentary_status']
        if 'corrected_xy' in note:
            assert [point['x'], point['y']] == note['corrected_xy']
            assert note.get('post_correction_visual_review')
            expected['diagram']['markers'][index]['x'] = point['x']
            expected['diagram']['markers'][index]['y'] = point['y']
            changes += 1
        markers += 1
    own = {key: value for key, value in row.items() if key not in ('children', 'nodes')}
    expected = {key: value for key, value in expected.items() if key not in ('children', 'nodes')}
    assert expected == own, 'Non-coordinate catalog change: ' + nid
assert markers == 376 and changes == 33
icons = json.loads(Path('docs/audits/warning_symbol_review.json').read_text())
print('VISUAL_AUDIT_COVERAGE=PASS nodes=90 markers=376 coordinate_corrections=33 original_images_unchanged=YES')
print('Marker findings:', dict(collections.Counter(m['visual_status'] for e in review['nodes'].values() for m in e['markers'])))
print('Architecture findings:', dict(collections.Counter(e['architecture_status'] for e in review['nodes'].values())))
print('WARNING_SYMBOL_PROVENANCE:', icons.keys())
