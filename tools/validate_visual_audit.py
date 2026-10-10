"""Validate preserved two-node batch, then the authorized three-node completion."""
import collections
import hashlib
import json
import subprocess
from pathlib import Path

BASE = '52b973888306662b65606e7bc8d7cd14edae339d'
BEFORE_BATCH = '172652ac9bb6c40d1314e2653fb5f89a85330081'
BATCH = Path('docs/audits/batches/cbzb_2node_reference_batch_v1')
AUTHORIZED = {'engine_bottom_end': '20579026b8fdfe695b90617be379ed55827bb0e8cd91e9e08e2f7a2d9fba488b',
              'boost_group': 'b4a868a08b2af6c111a9f62dd982e99c0afbbe53151065ed8061c2e10c621889'}
MANIFEST_SHA = '79c80b9cb3b341751ad79b900dbe008a9772358bd22fa556bc6b2ffa59ede8a2'

def snapshot(commit, path):
    return subprocess.check_output(['git', 'show', commit + ':' + str(path)])

def nodes(catalog):
    result = {}
    def visit(rows):
        for row in rows:
            if row.get('diagram'): result[row['id']] = row
            visit(row.get('nodes', row.get('children', [])))
    visit(catalog['sections'])
    return result

def own(row):
    return {key: value for key, value in row.items() if key not in ('children', 'nodes')}

manifest_bytes = (BATCH / 'manifest.json').read_bytes()
assert hashlib.sha256(manifest_bytes).hexdigest() == MANIFEST_SHA
manifest = json.loads(manifest_bytes)
supplied = {row['node_id']: row for row in manifest['nodes']}
assert supplied.keys() == AUTHORIZED.keys() and manifest['new_part_ids'] == []
history = json.loads((BATCH / 'integration_history.json').read_text())
assert history['integration_base_commit'] == BEFORE_BATCH and history['manifest_sha256'] == MANIFEST_SHA
historical_bytes = Path('docs/audits/full_marker_visual_review.json').read_bytes()
assert historical_bytes == snapshot(BEFORE_BATCH, 'docs/audits/full_marker_visual_review.json'), 'Historical review was rewritten'
historical = json.loads(historical_bytes)
active = json.loads(snapshot('ff73f211e73db4d3f8f72838eebc97eb0a57810b', 'data/technical_visual_audit.json'))
before_active = json.loads(snapshot(BEFORE_BATCH, 'data/technical_visual_audit.json'))
original = json.loads(snapshot(BASE, 'data/technical_catalog.json'))
before = json.loads(snapshot(BEFORE_BATCH, 'data/technical_catalog.json'))
current = json.loads(snapshot('ff73f211e73db4d3f8f72838eebc97eb0a57810b', 'data/technical_catalog.json'))
a, previous, b = nodes(original), nodes(before), nodes(current)
assert len(current['sections']) == 24 and len(a) == len(b) == len(active['nodes']) == 90
assert a.keys() == b.keys() == active['nodes'].keys()
# Compare the whole catalog with only the two allowed nodes substituted. Parent
# structures and all other fields must remain identical to the pre-batch commit.
expected_catalog = json.loads(json.dumps(before))
expected_nodes = nodes(expected_catalog)
for nid in AUTHORIZED:
    expected_nodes[nid].clear()
    expected_nodes[nid].update(b[nid])
assert expected_catalog == current, 'Catalog change outside the authorized nodes'
markers = historical_changes = batch_moves = 0
changed_image_paths = set()
for nid, row in b.items():
    record = active['nodes'][nid]
    old_review = historical['nodes'][nid]
    assert record['visually_opened'] and record['finding_ru'] and record['source']
    image = row['diagram']['image'].removeprefix('res://')
    actual_hash = hashlib.sha256(Path(image).read_bytes()).hexdigest()
    if nid not in AUTHORIZED:
        assert Path(image).read_bytes() == snapshot(BASE, image), image
        assert record == before_active['nodes'][nid], 'Audit overwritten outside the two nodes: ' + nid
        assert own(row) == own(previous[nid]), 'Non-batch node changed: ' + nid
    else:
        spec = supplied[nid]
        transition = history['nodes'][nid]
        expected_path = 'assets/technical_catalog/engine/engine_bottom_end_cbzb_reference_v1.webp' if nid == 'engine_bottom_end' else spec['app_asset_path']
        assert image == expected_path
        assert history['integration_mapping'][nid]['integrated_asset_path'] == image
        assert history['integration_mapping'][nid]['manifest_asset_path'] == spec['app_asset_path']
        assert actual_hash == spec['image_sha256'] == AUTHORIZED[nid]
        assert transition['before_image_sha256'] == hashlib.sha256(snapshot(BEFORE_BATCH, spec['app_asset_path'])).hexdigest()
        assert transition['after_image_sha256'] == actual_hash == record['image_sha256']
        assert transition['before_catalog_node'] == previous[nid]
        assert transition['before_active_review'] == before_active['nodes'][nid]
        assert transition['after_active_review'] == record
        assert record['architecture_status'] == record['catalog_verification_level'] == 'REFERENCE_ONLY'
        assert record['finding_ru'] == spec['architecture_note_ru'] and record['source'] == row['diagram']['source']
        assert {key: val for key, val in own(row).items() if key != 'diagram'} == {key: val for key, val in own(previous[nid]).items() if key != 'diagram'}
        diagram, prior_diagram = row['diagram'], previous[nid]['diagram']
        assert diagram['verification_level'] == 'REFERENCE_ONLY' and diagram['status'] == 'available'
        assert diagram['asset_note'] == spec['architecture_note_ru']
        permitted = {'verification_level', 'status', 'asset_note', 'source', 'markers', 'image'}
        assert {k:v for k,v in diagram.items() if k not in permitted} == {k:v for k,v in prior_diagram.items() if k not in permitted}
        source, prior_source = diagram['source'], prior_diagram['source']
        assert source['url'] == spec['source_url'] and source['verification_note'] == spec['architecture_note_ru']
        assert source['author'].startswith(manifest['batch_name']) and source['publisher'] and source['license']
        metadata = {'url', 'verification_note', 'author', 'publisher', 'license'}
        assert {k:v for k,v in source.items() if k not in metadata} == {k:v for k,v in prior_source.items() if k not in metadata}
        changed_image_paths.add(image)
    seen = set()
    assert len(row['diagram']['markers']) == len(record['markers']) == len(old_review['markers'])
    for index, (point, original_point, note) in enumerate(zip(row['diagram']['markers'], a[nid]['diagram']['markers'], record['markers'])):
        assert point['number'] == original_point['number'] == note['number']
        assert point['part_id'] == original_point['part_id'] == note['part_id']
        assert point['number'] not in seen and float(point['number']).is_integer()
        seen.add(point['number'])
        assert 0 <= point['x'] <= 1 and 0 <= point['y'] <= 1
        assert note['name_ru'] and note['finding_ru'] and note['documentary_status']
        previous_note = old_review['markers'][index]
        if 'corrected_xy' in previous_note:
            # None of the two replacement nodes contains one of these prior fixes.
            assert nid not in AUTHORIZED
            assert [point['x'], point['y']] == previous_note['corrected_xy']
            assert note.get('post_correction_visual_review')
            historical_changes += 1
        if nid in AUTHORIZED:
            wanted = supplied[nid]['markers'][index]
            assert [point['x'],point['y']] == [wanted['x'],wanted['y']] == [note['x'],note['y']]
            assert note['batch_name_ru'] == wanted['name_ru']
            assert 'REFERENCE_ONLY' in note['documentary_status'] and note['post_replacement_visual_review']
            prior_point = previous[nid]['diagram']['markers'][index]
            assert [prior_point['x'],prior_point['y']] != [point['x'],point['y']]
            batch_moves += 1
        markers += 1
assert markers == 376 and historical_changes == 33 and batch_moves == 10 and len(changed_image_paths) == 2
levels = collections.Counter(row['diagram']['verification_level'] for row in b.values())
assert levels == {'VERIFIED_ARCHITECTURE':55,'REFERENCE_ONLY':35}, levels
remaining = {nid for nid, entry in active['nodes'].items() if entry['architecture_status'] == 'FAIL_ARCHITECTURE'}
assert remaining == set(manifest['remaining_nodes_with_unfixed_architecture']) == {'engine_block_group','engine_upper_end','cylinder_head_group'}
for path in ['project.godot','export_presets.cfg','services/part_catalog_service.gd','data/warning_lights.json','data/dtc_catalog.json']:
    assert Path(path).read_bytes() == snapshot(BEFORE_BATCH, path), 'Unrelated/version data changed: ' + path
print('VISUAL_AUDIT_COVERAGE=PASS nodes=90 markers=376 historical_coordinate_fixes_preserved=33 authorized_image_replacements=2 batch_marker_repositions=10')
print('Historical two-node baseline status totals:', dict(levels))
print('Historical two-node baseline FAIL_ARCHITECTURE:', sorted(remaining))
print('Preserved two-node baseline marker findings:', dict(collections.Counter(m['visual_status'] for e in active['nodes'].values() for m in e['markers'])))
print('PARTIAL_CBZB_BATCH=PASS_REFERENCE_ONLY_NOT_COMPLETE')

old_shared = 'assets/technical_catalog/engine/engine_bottom_end.webp'
assert Path(old_shared).read_bytes() == snapshot(BEFORE_BATCH, old_shared)
assert b['engine_block_group'] == previous['engine_block_group']
assert [nid for nid,row in b.items() if row['diagram']['image'] == b['boost_group']['diagram']['image']] == ['boost_group']
assert history['physical_webp_added'] == history['physical_webp_replaced'] == 1
print('SHARED_IMAGE_ISOLATION=PASS engine_block_group_unchanged=YES physical_webp_added=1 physical_webp_replaced=1')

# The old batch above is checked against its immutable integration commit.
# Now prove that the completion changes only the three newly authorized nodes.
COMPLETION_BASE = 'ff73f211e73db4d3f8f72838eebc97eb0a57810b'
completion_folder = Path('docs/audits/batches/cbzb_3node_reference_batch_v1')
completion_bytes = (completion_folder / 'manifest.json').read_bytes()
assert hashlib.sha256(completion_bytes).hexdigest() == '3dd0ac4a830b3a06883d09df1b23432f947b7c9d99122d1fef6bb9a41bae6be8'
completion = json.loads(completion_bytes)
completion_specs = {s['node_id']: s for s in completion['nodes']}
assert set(completion_specs) == {'engine_block_group','engine_upper_end','cylinder_head_group'}
assert completion['new_part_ids'] == []
completion_history = json.loads((completion_folder / 'integration_history.json').read_text())
COMPLETION_COMMIT = '3cd1b892be568aaac5aea1fe5b2f3bf448427da9'
actual_catalog = json.loads(snapshot(COMPLETION_COMMIT, 'data/technical_catalog.json'))
actual_audit = json.loads(snapshot(COMPLETION_COMMIT, 'data/technical_visual_audit.json'))
baseline_catalog = json.loads(snapshot(COMPLETION_BASE, 'data/technical_catalog.json'))
baseline_audit = json.loads(snapshot(COMPLETION_BASE, 'data/technical_visual_audit.json'))
actual_nodes, baseline_nodes = nodes(actual_catalog), nodes(baseline_catalog)
expected_catalog = json.loads(json.dumps(baseline_catalog))
expected_nodes = nodes(expected_catalog)
expected_audit = json.loads(json.dumps(baseline_audit))
moves = 0
for nid, spec in completion_specs.items():
    row, prior = actual_nodes[nid], baseline_nodes[nid]
    diagram = row['diagram']
    assert own(row) | {'diagram': prior['diagram']} == own(prior), nid
    assert diagram['image'] == 'res://' + spec['app_asset_path']
    assert diagram['verification_level'] == 'REFERENCE_ONLY'
    assert diagram['source']['url'] == spec['source_url']
    assert spec['verification_note_ru'] in diagram['asset_note']
    assert spec['architecture_note_ru'] in diagram['asset_note']
    assert diagram['source']['verification_note'] == diagram['asset_note']
    assert diagram['source']['author'].startswith(completion['batch_name'])
    allowed = {'image','verification_level','source','asset_note','markers'}
    assert {k:v for k,v in diagram.items() if k not in allowed} == {k:v for k,v in prior['diagram'].items() if k not in allowed}
    image_hash = hashlib.sha256(Path(spec['app_asset_path']).read_bytes()).hexdigest()
    assert image_hash == spec['image_sha256']
    review = actual_audit['nodes'][nid]
    assert review['architecture_status'] == review['catalog_verification_level'] == 'REFERENCE_ONLY'
    assert review['image'] == diagram['image'] and review['image_sha256'] == image_hash
    assert review['source'] == diagram['source']
    assert len(diagram['markers']) == spec['marker_count'] == len(review['markers'])
    for p, old, wanted, note in zip(diagram['markers'],prior['diagram']['markers'],spec['markers'],review['markers']):
        assert p == dict(old, x=wanted['x'], y=wanted['y'])
        assert [p['x'],p['y']] == [note['x'],note['y']]
        assert note['part_id'] == p['part_id'] and note['number'] == p['number']
        assert note['visual_status'] == 'PASS_VISUAL' and note['finding_ru'] and note['post_replacement_visual_review']
        assert [p['x'],p['y']] != [old['x'],old['y']]
        moves += 1
    transition = completion_history['nodes'][nid]
    assert transition['before_catalog_node'] == prior
    assert transition['before_active_review'] == baseline_audit['nodes'][nid]
    assert transition['after_active_review'] == review
    expected_nodes[nid]['diagram'] = diagram
    expected_audit['nodes'][nid] = review
expected_audit['change_history'].append(actual_audit['change_history'][-1])
assert actual_catalog == expected_catalog, 'Unrelated catalog data changed'
assert actual_audit == expected_audit, 'Unrelated active review/history changed'
assert actual_audit['change_history'][-1]['modified_node_ids'] == completion['modified_node_ids']
assert moves == 10
for nid in actual_nodes.keys() - completion_specs.keys():
    image = actual_nodes[nid]['diagram']['image'].removeprefix('res://')
    assert Path(image).read_bytes() == snapshot(COMPLETION_BASE, image)
for path in ['assets/technical_catalog/engine/engine_bottom_end.webp','assets/technical_catalog/engine/engine_upper_end.webp','assets/technical_catalog/engine/engine_bottom_end_cbzb_reference_v1.webp','assets/technical_catalog/intake/boost_group.webp','docs/audits/full_marker_visual_review.json','project.godot','export_presets.cfg','services/part_catalog_service.gd','data/warning_lights.json','data/dtc_catalog.json']:
    assert Path(path).read_bytes() == snapshot(COMPLETION_BASE, path), path
levels = collections.Counter(n['diagram']['verification_level'] for n in actual_nodes.values())
assert levels == {'VERIFIED_ARCHITECTURE':52,'REFERENCE_ONLY':38}, levels
assert len(actual_catalog['sections']) == 24 and len(actual_nodes) == 90
assert sum(len(n['diagram']['markers']) for n in actual_nodes.values()) == 376
assert all(Path(n['diagram']['image'].removeprefix('res://')).is_file() for n in actual_nodes.values())
assert not any(r['architecture_status'] == 'FAIL_ARCHITECTURE' for r in actual_audit['nodes'].values())
assert len({actual_nodes[nid]['diagram']['image'] for nid in completion_specs}) == 3
print('CBZB_5NODE_VALIDATION_DATA=PASS sections=24 nodes=90 images=90 markers=376 levels=52/38 active_FAIL_ARCHITECTURE=0 images_added=0 images_replaced=3 physical_webp_added=3 physical_webp_replaced=0 markers_added=0 markers_repositioned=10 new_part_ids=0')

for line in (completion_folder / 'SHA256SUMS').read_text().splitlines():
    digest, filename = line.split(None, 1)
    checked = Path(filename) if filename.startswith('assets/') else completion_folder / filename
    assert hashlib.sha256(checked.read_bytes()).hexdigest() == digest, filename
print('COMPLETION_SHA256SUMS=PASS entries=7')
