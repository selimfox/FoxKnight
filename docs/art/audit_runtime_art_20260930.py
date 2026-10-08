"""Conservative runtime resource inventory; never deletes files.
Includes every scene/script/resource, not just the main-scene dependency tree.
Reports exact res:// paths so dynamic/relative loads still require manual review.
"""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[2]
rows={}
for directory in ('scenes','scripts','tests','assets/art/production'):
    for file in (ROOT/directory).rglob('*'):
        if not file.is_file() or file.suffix not in ('.tscn','.tres','.gd','.gdshader'):continue
        for ref in set(re.findall(r'res://([^"\s\)]+)',file.read_text(encoding='utf-8-sig'))):
            if ref.startswith('assets/art/'):
                rows.setdefault(ref,[]).append(file.relative_to(ROOT).as_posix())
directory_prefixes={path:rows.pop(path) for path in list(rows) if path.endswith('/')}
missing=[path for path in rows if not (ROOT/path).is_file()]
missing_directories=[path for path in directory_prefixes if not (ROOT/path).is_dir()]
report={'scope':'all scripts/scenes/tests/production .tres; exact res paths only',
        'missing':missing,'missing_directories':missing_directories,
        'dynamic_directory_prefixes':directory_prefixes,'references':dict(sorted(rows.items()))}
out=ROOT/'docs/art/RuntimeArtReferences_2026-09-30.json'
out.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'{len(rows)} referenced art files; {len(missing)} missing files; {len(missing_directories)} missing dynamic directories. No files deleted.')
