"""Draw diagnostic overlays only. Never writes application images or coordinates."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=Path('build/marker-qa'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
audit = json.loads(Path('data/technical_visual_audit.json').read_text())
font_path = Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
font = ImageFont.truetype(str(font_path), 20) if font_path.exists() else ImageFont.load_default()
rows = []
for node, entry in audit['nodes'].items():
    source = Path(entry['image'].removeprefix('res://'))
    image = Image.open(source).convert('RGB')
    image.thumbnail((1400, 1400))
    draw = ImageDraw.Draw(image)
    for marker in entry['markers']:
        xy = marker.get('corrected_xy') or [marker['x'], marker['y']]
        x, y = xy[0] * image.width, xy[1] * image.height
        status = marker.get('visual_status', 'NEEDS_REVIEW')
        color = '#ff665e' if status == 'FAIL_MARKER' else '#ffd16c' if status == 'NEEDS_REVIEW' else '#40d7d0'
        # Diagnostic view includes suppressed points in red/yellow for review.
        draw.ellipse((x-11, y-11, x+11, y+11), outline=color, width=2)
        draw.line((x-15,y,x+15,y), fill=color, width=1)
        draw.line((x,y-15,x,y+15), fill=color, width=1)
        draw.text((min(x+15, image.width-35), max(0,y-15)), str(marker['number']), fill=color, font=font)
    target = args.output / (node + '.png')
    image.save(target)
    rows.append({'node_id':node, 'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(), 'overlay':str(target), 'markers':len(entry['markers']), 'visual_acceptance':'NOT_RUN'})
(args.output/'index.json').write_text(json.dumps(rows,indent=2)+'\n')
print('OVERLAYS_GENERATED images=%d markers=%d; visual acceptance not implied' % (len(rows), sum(row['markers'] for row in rows)))
