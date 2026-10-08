"""Read-only structural checks for authored art and the water/fire interface."""
from pathlib import Path
from collections import deque
from PIL import Image

ROOT=Path(__file__).resolve().parent
NAMES=("floor_level_01","floor_level_02","floor_level_03",
       "wall","decor","water","water_mask","torch")


def components(mask:Image.Image)->int:
    a=mask.getchannel("A")
    opaque={(x,y) for y in range(a.height) for x in range(a.width)
            if a.getpixel((x,y))>0}
    count=0
    while opaque:
        count+=1
        q=deque([opaque.pop()])
        while q:
            x,y=q.popleft()
            for p in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if p in opaque:
                    opaque.remove(p);q.append(p)
    return count


for name in NAMES:
    source=Image.open(ROOT/f"{name}_source.png").convert("RGBA")
    world=Image.open(ROOT/f"{name}_world2x.png").convert("RGBA")
    assert source.width%16==0
    assert world==source.resize((source.width*2,source.height*2),Image.Resampling.NEAREST)
    assert set(source.getchannel("A").get_flattened_data()).issubset({0,255})
    print(f"{name}: {source.size} → {world.size}, palette={len(set(source.get_flattened_data()))}")

water=Image.open(ROOT/"water_source.png").convert("RGBA")
mask=Image.open(ROOT/"water_mask_source.png").convert("RGBA")
assert water.size==mask.size==(64,80)
water_alpha=water.getchannel("A")
mask_alpha=mask.getchannel("A")
assert all(m==0 or w==255 for m,w in zip(mask_alpha.get_flattened_data(),water_alpha.get_flattened_data()))
assert all(mask_alpha.getpixel((x,y))==0 for y in range(64,80) for x in range(64))

assembled=Image.new("RGBA",(48,48),(0,0,0,0))
for y,row in enumerate(((4,5,6),(11,0,7),(10,9,8))):
    for x,index in enumerate(row):
        part=water.crop(((index%4)*16,(index//4)*16,(index%4+1)*16,(index//4+1)*16))
        assembled.alpha_composite(part,(x*16,y*16))
assert components(assembled)==1, "default pool must be one connected water region"
print("water: same-cell reflection mask only inside visible water; wet row nonreflective; example pool connected")

fire=Image.open(ROOT/"torch_source.png").convert("RGBA")
assert fire.size==(96,24)
frames=[fire.crop((n*16,0,(n+1)*16,24)) for n in range(6)]
assert len({frame.tobytes() for frame in frames})==6
assert all(components(frame)==1 for frame in frames)
base=[frame.crop((0,19,16,24)).tobytes() for frame in frames]
assert len(set(base))==1, "bowl contact point must be fixed across six frames"
print("torch: six distinct connected cels with fixed bowl, no floating flame")
