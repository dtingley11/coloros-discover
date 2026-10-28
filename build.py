#!/usr/bin/env python3
"""Build a deterministic KernelSU module ZIP from reviewed source files."""
from pathlib import Path
import hashlib
import zipfile

root = Path(__file__).resolve().parent
out = root / 'dist'
out.mkdir(exist_ok=True)
properties = dict(line.split('=', 1) for line in (root / 'module/module.prop').read_text().splitlines() if '=' in line)
destination = out / f"ace6t-discover-{properties['version']}.zip"
with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for path in sorted((root / 'module').iterdir()):
        if not path.is_file():
            raise RuntimeError(f'Unexpected module directory: {path}')
        info = zipfile.ZipInfo(path.name, date_time=(2026, 10, 28, 0, 0, 0))
        info.create_system = 3
        info.external_attr = (0o100755 if path.suffix == '.sh' else 0o100644) << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        archive.writestr(info, path.read_bytes())
digest = hashlib.sha256(destination.read_bytes()).hexdigest()
(out / (destination.name + '.sha256')).write_text(f'{digest}  {destination.name}\n')
print(f'{destination}: {destination.stat().st_size} bytes\nSHA256 {digest}')
