"""Render whole-room material repetition studies; never use as game textures."""
from pathlib import Path
from PIL import Image
from build_environment import floor_atlas, wall_atlas, water_atlases, torch_atlas

ROOT=Path(__file__).resolve().parent
W,H=30,17


def crop(atlas:Image.Image,index:int,columns:int)->Image.Image:
    x=(index%columns)*16;y=(index//columns)*16
    return atlas.crop((x,y,x+16,y+16))


def make(level:int)->Image.Image:
    floor=floor_atlas(level)
    wall=wall_atlas()
    water,_=water_atlases()
    torch=torch_atlas()
    canvas=Image.new("RGBA",(W*16,H*16),"#172332")
    for y in range(H):
        for x in range(W):
            # Six 3x3 macro choices, distributed by large patches rather than
            # an independent random dice roll on each 16-pixel tile.
            mx,my=x//3,y//3
            roll=(mx*17+my*29+mx*my*11+level*7)%100
            if roll<72:module=(mx*13+my*19+mx*my*7+level)%8
            elif roll<93:module=8+((mx+2*my)%2)
            else:module=(mx*5+my)%8
            if (x<4 or x>25 or y<3 or y>13) and (mx*3+my+level)%7==0:
                module=11
            if level==1 and x<10 and y<8 and (mx+my)%7==0:
                module=10
            atlas_index=(module%3)*3+x%3+(module//3)*27+(y%3)*9
            canvas.alpha_composite(crop(floor,atlas_index,9),(x*16,y*16))
    # Place one representative pool in each approved corner region.
    ox,oy=((3,3),(23,3),(3,11))[level-1]
    for dy,row in enumerate(((4,5,6),(11,0,7),(10,9,8))):
        for dx,index in enumerate(row):
            canvas.alpha_composite(crop(water,index,4),((ox+dx)*16,(oy+dy)*16))
    for y in range(H):
        for x in range(W):
            if y==0:wall_index=2 if x==0 else 3 if x==W-1 else x%2
            elif y==H-1:wall_index=6 if x==0 else 7 if x==W-1 else 4+x%2
            elif x==0:wall_index=8+y%2
            elif x==W-1:wall_index=10+y%2
            else:continue
            canvas.alpha_composite(crop(wall,wall_index,4),(x*16,y*16))
    flame=torch.crop((0,0,16,24))
    for x,y in ((2,2),(27,2),(2,14),(27,14)):
        canvas.alpha_composite(flame,(x*16,y*16-8))
    return canvas


for level in (1,2,3):
    native=make(level)
    native.save(ROOT/f"full_room_level_{level:02}_native_study.png")
    # 480x272 source becomes 960x544 world; crop off 2 px at each vertical
    # edge solely to inspect the current 960x540 framing.
    world=native.resize((960,544),Image.Resampling.NEAREST)
    world.crop((0,2,960,542)).save(ROOT/f"full_room_level_{level:02}_world_study.png")
