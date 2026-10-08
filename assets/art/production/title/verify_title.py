"""Mechanical checks for exported title art; aesthetic review is separate."""
import json
from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parent
meta=json.loads((root/'atlas.json').read_text(encoding='utf-8'))
for name in meta['assets']:
    native=Image.open(root/'native'/f'{name}.png').convert('RGBA')
    exported=Image.open(root/'export'/f'{name}.png').convert('RGBA')
    assert exported.size==(native.width*2,native.height*2), name
    assert exported.tobytes()==native.resize(exported.size,Image.Resampling.NEAREST).tobytes(), name
    assert set(native.getchannel('A').tobytes()).issubset({0,255}), name
    assert native.getbbox(), name
for name in ('menu','victory','failure'):
    image=Image.open(root/'preview'/f'{name}_960x540.png')
    assert image.size==(960,540), name
print('PASS title atlas size, nearest 2x, binary alpha, and 960x540 previews')
