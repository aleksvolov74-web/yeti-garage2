"""Prepare a private, hash-checked ARM64 runtime; never replace system libraries."""
import argparse
import copy
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import posixpath
import tarfile
import tempfile
import urllib.request
import zipfile

GODOT_URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.arm64.zip'
GODOT_ZIP_SHA = '5dd0d86405cf7e8adf79fb6377b38ba682a2846cb378ffe5364f38c01ad29b9d'
GODOT_BINARY_SHA = '3fcb80f4fe794e3859360eb641d8c41d8ffe2c2e54ba1981e55a76851d5ed1f4'
GODOT_NAME = 'Godot_v4.7.2-stable_linux.arm64'

def checked_download(url, destination, digest):
    if not destination.exists():
        partial = destination.with_suffix(destination.suffix + '.part')
        with urllib.request.urlopen(url, timeout=60) as response, partial.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
        if hashlib.sha256(partial.read_bytes()).hexdigest() != digest:
            raise ValueError('Download checksum mismatch: ' + url)
        partial.rename(destination)
    if hashlib.sha256(destination.read_bytes()).hexdigest() != digest:
        raise ValueError('Cached file checksum mismatch: ' + str(destination))

def deb_data(data):
    if not data.startswith(b'!<arch>\n'):
        raise ValueError('Invalid Debian archive')
    offset = 8
    while offset + 60 <= len(data):
        header = data[offset:offset + 60]
        if header[58:60] != b'`\n':
            raise ValueError('Invalid ar member')
        name = header[:16].decode().strip().rstrip('/')
        size = int(header[48:58])
        offset += 60
        member = data[offset:offset + size]
        if name.startswith('data.tar'):
            return member
        offset += size + size % 2
    raise ValueError('Missing Debian data archive')

def extract_private_runtime(data, destination):
    # Android PRoot can emulate hardlinks with symlinks that become cyclic on a
    # repeated extraction. Use relative symlinks for archive hardlink aliases,
    # and replace each prepared file atomically instead of truncating live ELFs.
    with tempfile.TemporaryDirectory(prefix='yeti-deb-extract-') as temporary:
        staging = Path(temporary)
        with tarfile.open(fileobj=io.BytesIO(data), mode='r:*') as content:
            members = []
            for original in content.getmembers():
                member = copy.copy(original)
                if member.islnk():
                    member.type = tarfile.SYMTYPE
                    member.linkname = posixpath.relpath(member.linkname, posixpath.dirname(member.name))
                members.append(member)
            content.extractall(staging, members=members, filter='data')
        for source in sorted(staging.rglob('*')):
            target = destination / source.relative_to(staging)
            if source.is_dir() and not source.is_symlink():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                source.replace(target)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--graphics', action='store_true', help='Also prepare the pinned X11/Mesa libraries')
    parser.add_argument('--runtime-dir', type=Path, default=Path(os.environ.get('YETI_GODOT_RUNTIME', '/tmp/yeti-godot-debian-runtime')))
    parser.add_argument('--godot-dir', type=Path, default=Path('/tmp/godot-4.7.2'))
    args = parser.parse_args()
    if platform.machine() not in ('aarch64', 'arm64'):
        parser.error('This helper is for Linux ARM64 hosts only')
    args.runtime_dir.mkdir(parents=True, exist_ok=True)
    runtime_lock = (args.runtime_dir / '.yeti-runtime.lock').open('a')
    try:
        fcntl.flock(runtime_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        parser.error('Godot is using this runtime; stop its checks before preparing libraries')
    args.godot_dir.mkdir(parents=True, exist_ok=True)
    binary = args.godot_dir / GODOT_NAME
    if not binary.exists():
        archive = args.runtime_dir / 'Godot_v4.7.2-stable_linux.arm64.zip'
        checked_download(GODOT_URL, archive, GODOT_ZIP_SHA)
        with zipfile.ZipFile(archive) as zipped:
            binary.write_bytes(zipped.read(GODOT_NAME))
        binary.chmod(0o755)
    if hashlib.sha256(binary.read_bytes()).hexdigest() != GODOT_BINARY_SHA:
        raise ValueError('Godot binary differs from the official 4.7.2 ARM64 release')
    manifest = json.loads(Path(__file__).with_name('godot_arm64_runtime_packages.json').read_text())
    for package in manifest:
        if package['scope'] == 'graphics' and not args.graphics:
            continue
        archive = args.runtime_dir / package['url'].rsplit('/', 1)[1]
        checked_download(package['url'], archive, package['sha256'])
        extract_private_runtime(deb_data(archive.read_bytes()), args.runtime_dir)
        print(package['package'], package['version'], 'SHA256 OK', flush=True)
    print('Runtime prepared:', args.runtime_dir)
    print('Run: sh tools/run_godot_arm64.sh --headless --path . --import')

if __name__ == '__main__':
    main()
