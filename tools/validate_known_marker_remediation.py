"""Verify scope, immutable assets/history, honest findings and APK readiness separately."""
import argparse,collections,copy,hashlib,json,subprocess
from pathlib import Path
BASE='3cd1b892be568aaac5aea1fe5b2f3bf448427da9'
FOLDER=Path('docs/audits/known_marker_remediation_v1')
def snapshot(path):return subprocess.check_output(['git','show',BASE+':'+str(path)])
def load(path):return json.loads(Path(path).read_text())
def nodes(catalog):
 out={}
 def walk(rows):
  for row in rows:
   if 'diagram' in row:out[row['id']]=row
   walk(row.get('nodes',row.get('children',[])))
 walk(catalog['sections']);return out
p=argparse.ArgumentParser();p.add_argument('--require-ready',action='store_true');args=p.parse_args()
r=load(FOLDER/'remediation.json');a=load('data/technical_visual_audit.json');c=load('data/technical_catalog.json')
bc=json.loads(snapshot('data/technical_catalog.json'));ba=json.loads(snapshot('data/technical_visual_audit.json'))
assert load(FOLDER/'baseline_active_audit.json')==ba
bn,cn=nodes(bc),nodes(c);expected=copy.deepcopy(bc);en=nodes(expected)
known={(n,m['number']):m for n,v in ba['nodes'].items() for m in v['markers'] if m['visual_status'] in ('FAIL_MARKER','NEEDS_REVIEW')}
assert collections.Counter(m['visual_status'] for m in known.values())=={'FAIL_MARKER':38,'NEEDS_REVIEW':31}
assert {(m['node_id'],m['number']) for m in r['markers']}==known.keys()
assert len(r['markers'])==69
changed=[]
for rec in r['markers']:
 nid=rec['node_id'];num=rec['number'];old=known[nid,num]
 assert rec['initial_visual_status']==old['visual_status']
 bp=next(m for m in bn[nid]['diagram']['markers'] if m['number']==num)
 cp=next(m for m in cn[nid]['diagram']['markers'] if m['number']==num)
 ap=next(m for m in a['nodes'][nid]['markers'] if m['number']==num)
 assert bp['part_id']==cp['part_id']==rec['part_id']==ap['part_id']
 assert rec['before_xy']==[bp['x'],bp['y']] and rec['after_xy']==[cp['x'],cp['y']]
 assert all(0<=v<=1 for v in rec['after_xy'])
 assert rec['evidence_ru'] and rec['architecture_sources']
 assert rec['documentary_status']=='REFERENCE_ONLY'
 assert hashlib.sha256(Path(rec['image']).read_bytes()).hexdigest()==rec['image_sha256']
 if rec['position_verified']:
  assert ap['visual_status']=='CORRECTED_COORDINATE' and ap['position_verified'] and ap['resolution_class']=='B'
  assert ap['documentary_status']=='REFERENCE_ONLY' and ap['post_correction_visual_review']
  assert rec['before_xy']!=rec['after_xy'];changed.append(rec)
  ep=next(m for m in en[nid]['diagram']['markers'] if m['number']==num);ep.update(x=cp['x'],y=cp['y'])
 else:
  assert cp==bp and ap['visual_status']==old['visual_status'] and not ap['position_verified']
  assert ap['resolution_status']=='NEEDS_IMAGE_REPLACEMENT' and ap['resolution_class'] in ('C','D')
requests={n['node_id']:n for n in r['image_requests']}
for nid,req in requests.items():
 assert a['nodes'][nid]['replacement_required']
 assert req['part_ids']==[m['part_id'] for m in cn[nid]['diagram']['markers']]
 assert req['current_image_path']==bn[nid]['diagram']['image']
 assert len(req['required_markers'])==len(req['part_ids'])
 if bn[nid]['diagram']['verification_level']=='VERIFIED_ARCHITECTURE':
  assert cn[nid]['diagram']['verification_level']=='REFERENCE_ONLY'
  en[nid]['diagram']['verification_level']='REFERENCE_ONLY'
  assert req['error_ru'] in cn[nid]['diagram']['asset_note']
  en[nid]['diagram']['asset_note']=cn[nid]['diagram']['asset_note']
assert expected==c,'Catalog mutation outside reviewed coordinates/explicit downgrades'
for nid in cn:
 image=cn[nid]['diagram']['image'].removeprefix('res://')
 assert Path(image).read_bytes()==snapshot(image),image
 if nid not in r['summary']['modified_node_ids']:assert a['nodes'][nid]==ba['nodes'][nid],nid
for nid in ['engine_bottom_end','boost_group','engine_block_group','engine_upper_end','cylinder_head_group']:
 assert cn[nid]==bn[nid] and a['nodes'][nid]==ba['nodes'][nid],nid
for path in ['docs/audits/full_marker_visual_review.json','services/part_catalog_service.gd','data/dtc_catalog.json','data/warning_lights.json','project.godot','export_presets.cfg']:
 assert Path(path).read_bytes()==snapshot(path),path
assert a['change_history'][:-1]==ba['change_history']
assert len(c['sections'])==24 and len(cn)==90 and sum(len(n['diagram']['markers']) for n in cn.values())==376
levels=collections.Counter(n['diagram']['verification_level'] for n in cn.values())
assert dict(levels)==r['summary']['verification_totals']=={'VERIFIED_ARCHITECTURE':36,'REFERENCE_ONLY':54}
assert len(changed)==r['summary']['markers_corrected']==35
assert len(requests)==r['summary']['nodes_requiring_new_images']==23
assert sum(not m['position_verified'] and m['initial_visual_status']=='FAIL_MARKER' for m in r['markers'])==12
assert sum(not m['position_verified'] and m['initial_visual_status']=='NEEDS_REVIEW' for m in r['markers'])==22
assert sum(n['architecture_status']=='FAIL_ARCHITECTURE' for n in a['nodes'].values())==7
for line in (FOLDER/'SHA256SUMS').read_text().splitlines():
 digest,path=line.split(None,1);assert hashlib.sha256((FOLDER/path).read_bytes()).hexdigest()==digest,path
print('KNOWN_FINDINGS_STATIC_VALIDATION=PASS scope=69 corrected=35 unresolved=34 replacements=23 images_unchanged=90 preserved_CBZB=5 levels=36/54')
print('CATALOG_TECHNICAL_READINESS=INCOMPLETE (12 FAIL_MARKER, 22 NEEDS_REVIEW, 7 rejected architectures; unsafe overlays disabled)')
if args.require_ready:
 raise SystemExit('APK_EXPORT_BLOCKED: replacement images and confirmed marker mappings are still required')
