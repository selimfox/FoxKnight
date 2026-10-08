"""Original native-grid additions to FoxKnight's editable courtyard forms.

The earlier unintegrated v3 pixel form recipes are used as drawing primitives.
They were authored at native resolution; this script selects, adjusts, and
re-composes them on the same grid. There is no image downsampling or noise.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
FORMS = ROOT.parent / "environment"
sys.path.insert(0, str(FORMS))
import pixel_stone_forms as stone
import pixel_water_edge_forms as edge

NATIVE = 16
FLOOR_KINDS = (
    "quiet_a", "quiet_b", "quiet_a_hmirror", "quiet_b_hmirror",
    "quiet_a_vmirror", "quiet_b_vmirror", "quiet_a_turn", "quiet_b_turn",
    "stagger_a", "stagger_b", "wet", "worn"
)
BASE = {
    "joint": "#202D3C", "under": "#293A4C", "shade": "#304254",
    "stone": "#384B5E", "mid": "#405468", "lit": "#52677A",
    "edge": "#687C8A", "chip": "#7B8C96", "moss0": "#263C3D",
    "moss1": "#3A5A51", "moss2": "#607A63", "wet0": "#263C4B",
    "wet1": "#355361", "wet2": "#4C6C76", "void": "#172332",
}
LEVEL = {
    1: {"joint":"#233243","under":"#2D3D50","shade":"#34465A",
        "stone":"#3C5064","mid":"#43586A","lit":"#526779",
        "edge":"#647988","chip":"#788A94","wet0":"#294653",
        "wet1":"#365663","wet2":"#4E7179"},
    2: {"joint":"#2A2E3E","under":"#34394C","shade":"#3D4255",
        "stone":"#494C60","mid":"#525467","lit":"#616476",
        "edge":"#717589","chip":"#81869A","wet0":"#314253",
        "wet1":"#3B5260","wet2":"#526978"},
    3: {"joint":"#202A39","under":"#293747","shade":"#303F50",
        "stone":"#3B4859","mid":"#445467","lit":"#536376",
        "edge":"#637586","chip":"#768696","wet0":"#273E50",
        "wet1":"#324E60","wet2":"#496A77"},
}
WATER = {"body":"#355869","body2":"#315263","deep":"#2B4B5C",
         "wet":"#314B59","shore":"#536B73","line":"#72979C",
         "line2":"#5F848D"}
FIRE = {"outer":"#AA4E2D","orange":"#E88938","gold":"#FFD17A",
        "core":"#FFF0B0","bowl":"#2B303A","rim":"#A08B91",
        "iron":"#4C4E5B"}


def save_pair(name: str, image: Image.Image, force: bool) -> None:
    src = ROOT / f"{name}_source.png"
    dst = ROOT / f"{name}_world2x.png"
    if not force and (src.exists() or dst.exists()):
        raise FileExistsError(f"Source has possible hand edits: {src}")
    assert set(image.getchannel("A").get_flattened_data()).issubset({0,255})
    image.save(src)
    image.resize((image.width*2,image.height*2), Image.Resampling.NEAREST).save(dst)


def palette_map(image: Image.Image, level: int) -> Image.Image:
    """Exact index replacement on native pixels, never a whole-image filter."""
    replacements = {tuple(bytes.fromhex(c[1:])): tuple(bytes.fromhex(
        LEVEL[level].get(name, c)[1:])) for name,c in BASE.items()}
    out = image.copy().convert("RGBA")
    out.putdata([(*replacements.get(px[:3],px[:3]),px[3]) for px in out.get_flattened_data()])
    return out


def floor_atlas(level: int) -> Image.Image:
    # Each group is a 48x48 hand-built composition crossing 16x16 tile cuts.
    # Quiet A/B use the least contrast in the combat centre. Stagger A/B,
    # moisture, and worn blocks live mostly near the arena perimeter.
    calm = [stone.floor_quiet(),stone.floor_quiet_b()]
    forms = (calm
             + [im.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for im in calm]
             + [im.transpose(Image.Transpose.FLIP_TOP_BOTTOM) for im in calm]
             + [im.transpose(Image.Transpose.ROTATE_180) for im in calm])
    forms += [stone.floor_a(),stone.floor_b(),stone.floor_wet(),stone.floor_worn()]
    atlas = Image.new("RGBA",(144,192),(0,0,0,0))
    for index,form in enumerate(forms):
        tile = palette_map(form,level)
        if index < 8:
            # The eight combat-centre modules should read as one calm plane at
            # 960x540, not six individually bevelled stone blocks. Replace
            # specific native palette pixels before any 2x export.
            p = LEVEL[level]
            quiet = {
                tuple(bytes.fromhex(p["joint"][1:])): tuple(bytes.fromhex(p["under"][1:])),
                tuple(bytes.fromhex(p["under"][1:])): tuple(bytes.fromhex(p["shade"][1:])),
                tuple(bytes.fromhex(p["shade"][1:])): tuple(bytes.fromhex(p["stone"][1:])),
                tuple(bytes.fromhex(p["mid"][1:])): tuple(bytes.fromhex(p["stone"][1:])),
                tuple(bytes.fromhex(p["lit"][1:])): tuple(bytes.fromhex(p["mid"][1:])),
            }
            tile.putdata([(*quiet.get(px[:3], px[:3]),px[3]) for px in tile.get_flattened_data()])
        if index == 9:
            # The stagger B recipe includes a moss clump; this macro may be
            # used in the room interior, where green spots would repeat.
            no_moss={
                tuple(bytes.fromhex(BASE["moss0"][1:])):tuple(bytes.fromhex(LEVEL[level]["shade"][1:])),
                tuple(bytes.fromhex(BASE["moss1"][1:])):tuple(bytes.fromhex(LEVEL[level]["stone"][1:])),
                tuple(bytes.fromhex(BASE["moss2"][1:])):tuple(bytes.fromhex(LEVEL[level]["mid"][1:])),
            }
            tile.putdata([(*no_moss.get(px[:3],px[:3]),px[3]) for px in tile.get_flattened_data()])
        draw = ImageDraw.Draw(tile)
        if level == 1 and index == 10:
            draw.line([(9,38),(12,37),(16,38)],fill="#54747A")
        if level == 2 and index == 8:
            draw.line([(8,23),(12,25),(15,24)],fill="#333849")
        if level == 3 and index == 11:
            draw.line([(3,28),(6,26),(9,28),(10,31)],fill="#202A39")
        atlas.alpha_composite(tile,((index%3)*48,(index//3)*48))
    return atlas


def wall_atlas() -> Image.Image:
    # Same 4x3, same one-cell-thick collision envelope as current border.
    atlas=palette_map(stone.wall_border(),1)
    d=ImageDraw.Draw(atlas)
    # A few restrained cracked/older sections; corners keep their silhouette.
    d.line([(23,6),(22,8),(24,10)],fill="#293A4C")
    d.line([(21,33),(23,35),(22,39)],fill="#293A4C")
    return atlas


def decor_atlas() -> Image.Image:
    atlas=palette_map(edge.decor(),1)
    # Edge-only pieces have binary transparency and imply no collision.
    return atlas


def water_mask_tile(index: int) -> Image.Image:
    """20 classes: four centres, eight clockwise shores, four concave, four wet."""
    m=Image.new("L",(16,16),0); d=ImageDraw.Draw(m)
    if index<4:
        d.rectangle((0,0,15,15),fill=255)
    elif index<12:
        # NW, N, NE, E, SE, S, SW, W. Corners have rounded but stepped
        # entries; a single pool can be assembled without a hard oval ring.
        polygons=[
            [(5,15),(15,15),(15,5),(13,5),(11,7),(8,7),(7,10),(5,11)],
            [(0,15),(15,15),(15,7),(12,6),(10,7),(7,5),(5,8),(2,7),(0,9)],
            [(0,9),(3,7),(7,8),(9,10),(8,13),(7,15),(0,15)],
            [(0,0),(7,0),(6,4),(8,7),(6,10),(7,13),(5,15),(0,15)],
            [(0,0),(5,0),(7,3),(9,5),(8,7),(5,9),(0,8)],
            [(0,0),(15,0),(15,8),(12,10),(9,8),(6,10),(3,9),(0,11)],
            [(8,0),(15,0),(15,11),(12,10),(9,9),(7,6),(8,3)],
            [(8,0),(15,0),(15,15),(7,15),(5,12),(7,9),(5,6),(8,3)],
        ]
        d.polygon(polygons[index-4],fill=255)
    elif index<16:
        d.rectangle((0,0,15,15),fill=255)
        notches=[
            [(0,0),(9,0),(7,2),(6,5),(3,6),(0,9)],
            [(6,0),(15,0),(15,9),(12,7),(10,5),(9,2)],
            [(15,6),(15,15),(6,15),(9,12),(10,10),(13,9)],
            [(0,6),(3,9),(6,10),(7,13),(9,15),(0,15)],
        ]
        d.polygon(notches[index-12],fill=0)
    # 16..19 are wet stone, not reflective water.
    return m


def water_atlases() -> tuple[Image.Image,Image.Image]:
    visual=Image.new("RGBA",(64,80),(0,0,0,0))
    reflection=Image.new("RGBA",(64,80),(0,0,0,0))
    for index in range(20):
        offset=((index%4)*16,(index//4)*16)
        tile=Image.new("RGBA",(16,16),(0,0,0,0))
        d=ImageDraw.Draw(tile)
        if index>=16:
            # Shallow wet transition overlays the existing stone floor.
            wet=[
                [(0,11),(4,9),(7,10),(11,8),(15,10),(15,15),(0,15)],
                [(0,0),(5,0),(7,5),(5,9),(7,13),(4,15),(0,15)],
                [(0,0),(15,0),(15,5),(10,7),(6,5),(2,8),(0,6)],
                [(10,0),(15,0),(15,15),(10,15),(8,11),(10,7),(8,4)]
            ][index-16]
            d.polygon(wet,fill=WATER["wet"])
            d.line([(3,12),(6,11),(9,12)] if index==16 else
                   [(3,4),(6,5),(8,4)],fill=WATER["shore"])
        else:
            mask=water_mask_tile(index)
            d.rectangle((0,0,15,15),fill=WATER["body"])
            d.polygon([(0,1),(8,0),(14,3),(12,7),(2,6)],fill=WATER["body2"])
            d.polygon([(2,11),(8,9),(15,12),(15,15),(0,15)],fill=WATER["deep"])
            if index<4:
                if index%3==0: d.line([(3,5),(7,4),(10,5)],fill=WATER["line"])
                elif index%3==1: d.line([(8,12),(12,11),(14,12)],fill=WATER["line2"])
                else: d.line([(2,10),(5,9),(7,10)],fill=WATER["line2"])
            tile.putalpha(mask)
            a=mask.load();pix=tile.load()
            for y in range(16):
                for x in range(16):
                    if not a[x,y]: continue
                    shore=any(0<=x+dx<16 and 0<=y+dy<16 and not a[x+dx,y+dy]
                              for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)))
                    if shore:
                        pix[x,y]=(83,107,115,255)
                    else:
                        reflection.putpixel((offset[0]+x,offset[1]+y),
                                            (255,255,255,255))
        visual.alpha_composite(tile,offset)
    return visual,reflection


def torch_atlas() -> Image.Image:
    atlas=Image.new("RGBA",(96,24),(0,0,0,0))
    silhouettes=[
        [(7,4),(8,7),(10,8),(11,13),(9,17),(5,17),(4,13),(6,10)],
        [(5,6),(7,9),(9,7),(10,11),(11,15),(9,18),(5,18),(4,13)],
        [(8,3),(8,7),(10,10),(9,13),(11,16),(8,18),(5,17),(5,12)],
        [(6,5),(7,8),(9,6),(10,10),(9,13),(11,17),(6,18),(4,14)],
        [(9,4),(8,9),(10,10),(10,15),(8,18),(5,17),(4,12),(6,9)],
        [(7,5),(7,9),(9,8),(10,13),(9,17),(5,18),(4,14),(6,11)],
    ]
    for i,polygon in enumerate(silhouettes):
        cel=Image.new("RGBA",(16,24),(0,0,0,0)); d=ImageDraw.Draw(cel)
        d.polygon(polygon,fill=FIRE["outer"])
        d.polygon([(6,11),(8,9),(9,12),(9,16),(7,18),(5,16)],
                  fill=FIRE["orange"])
        d.polygon([(7,13),(8,11),(8,15),(7,18),(6,16)],fill=FIRE["gold"])
        d.rectangle((7,15,8,17),fill=FIRE["core"])
        # Bowl contact is fixed on all six cels. The flame cannot float.
        d.line((4,18,11,18),fill=FIRE["outer"])
        d.rectangle((3,19,12,20),fill=FIRE["bowl"])
        d.line((4,19,11,19),fill=FIRE["rim"])
        d.polygon([(4,21),(11,21),(10,23),(5,23)],fill=FIRE["iron"])
        atlas.alpha_composite(cel,(i*16,0))
    return atlas


def contact_sheet(force: bool) -> None:
    """A source-scale material comparison, never a game background."""
    native=Image.new("RGBA",(480,270),"#172332")
    water,_=water_atlases();wall=wall_atlas()
    for level in (1,2,3):
        floor=floor_atlas(level);x0=(level-1)*160+8
        for y in range(5):
            for x in range(9):
                m=(0,1,4,6,2,7,5,3,0,
                   3,5,1,0,7,2,4,6,1,
                   1,2,8,8,8,3,5,0,7,
                   4,7,9,9,9,0,2,6,3,
                   6,0,5,4,1,3,7,2,4)[y*9+x]
                if level==3 and y in (0,4) and x in (2,6):m=11
                sx=(m%3)*48+(x%3)*16;sy=(m//3)*48+(y%3)*16
                native.alpha_composite(floor.crop((sx,sy,sx+16,sy+16)),
                                       (x0+x*16,24+y*16))
        for x in range(9):
            sx=(x%2)*16
            native.alpha_composite(wall.crop((sx,0,sx+16,16)),(x0+x*16,8))
        if level==1:
            for y,row in enumerate(((4,5,6),(11,0,7),(10,9,8))):
                for x,i in enumerate(row):
                    sx=(i%4)*16;sy=(i//4)*16
                    native.alpha_composite(water.crop((sx,sy,sx+16,sy+16)),
                                           (x0+14+x*16,33+y*16))
    for suffix,scale in (("native",1),("world2x",2)):
        path=ROOT/f"three_level_material_preview_{suffix}.png"
        if path.exists() and not force:raise FileExistsError(path)
        native.resize((480*scale,270*scale),Image.Resampling.NEAREST).save(path)


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--force",action="store_true")
    args=parser.parse_args()
    for level in (1,2,3):
        save_pair(f"floor_level_{level:02}",floor_atlas(level),args.force)
    save_pair("wall",wall_atlas(),args.force)
    save_pair("decor",decor_atlas(),args.force)
    water,mask=water_atlases()
    save_pair("water",water,args.force)
    save_pair("water_mask",mask,args.force)
    save_pair("torch",torch_atlas(),args.force)
    contact_sheet(args.force)
    for name in ("floor_level_01","floor_level_02","floor_level_03",
                 "wall","decor","water","water_mask","torch"):
        a=Image.open(ROOT/f"{name}_source.png").convert("RGBA")
        b=Image.open(ROOT/f"{name}_world2x.png").convert("RGBA")
        assert b==a.resize(b.size,Image.Resampling.NEAREST)
        assert set(a.getchannel("A").get_flattened_data()).issubset({0,255})
        print(f"{name}: native={a.size}, game={b.size}")


if __name__=="__main__":main()
