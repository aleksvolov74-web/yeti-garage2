"""Record actual commands and results; graphical tests use an isolated X server."""
import json
import os
from pathlib import Path
import select
import subprocess
import time

folder = Path(__file__).resolve().parent
results = []
runner = ['sh', 'tools/run_godot_arm64.sh', '--path', '.']
def run(label, argv, timeout, expected=None, env=None):
    started = time.monotonic()
    with (folder / 'logs' / (label + '.txt')).open('w') as log:
        try:
            process = subprocess.run(argv, stdout=log, stderr=subprocess.STDOUT, timeout=timeout, env=env)
            code = process.returncode
        except subprocess.TimeoutExpired:
            code = 124
    output = (folder / 'logs' / (label + '.txt')).read_text()
    errors = [line for line in output.splitlines() if any(tag in line for tag in ['SCRIPT ERROR:', 'Parse Error:', 'Failed to load script', 'ERROR:', 'Program crashed'])]
    passed = code == 0 and not errors and (expected is None or expected in output)
    results.append(dict(label=label, command=argv, exit_code=code, elapsed=round(time.monotonic()-started, 2), errors=errors, status='PASS' if passed else 'FAIL'))
    (folder / 'test_results.json').write_text(json.dumps(results, indent=2)+'\n')
    print(label, results[-1]['status'], flush=True)
    return passed

run('import', runner + ['--headless', '--import'], 180)
run('storage', runner + ['--headless', '--script', 'tools/validate_storage.gd'], 100, 'STORAGE_VALIDATION=PASS')
run('catalog_3d', runner + ['--headless', '--script', 'tools/validate_3d_catalog.gd'], 180)
run('startup', runner + ['--headless', '--quit-after', '60'], 100)
with (folder / 'logs' / 'xvfb.txt').open('w') as log:
    server = subprocess.Popen(['Xvfb','-displayfd','1','-screen','0','1024x1024x24','-nolisten','tcp'], stdout=subprocess.PIPE, stderr=log)
    try:
        if not select.select([server.stdout], [], [], 15)[0]:
            raise RuntimeError('No X display')
        display = server.stdout.readline().decode().strip()
        env = dict(os.environ, DISPLAY=':'+display, LIBGL_ALWAYS_SOFTWARE='1')
        graphics = runner + ['--display-driver','x11','--rendering-method','gl_compatibility','--audio-driver','Dummy']
        run('desktop_ux', graphics + ['--script','tools/validate_android_ux.gd'], 1200, 'ANDROID_UX_DESKTOP_VALIDATION=PASS', env)
        run('manual_pages', graphics + ['--script','tools/validate_manual_pages.gd'], 1500, 'MANUAL_PAGES_VALIDATION=PASS', env)
    finally:
        server.terminate()
        server.wait(timeout=10)
