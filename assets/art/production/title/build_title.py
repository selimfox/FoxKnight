"""FoxKnight hand-stroked, deterministic pixel lettering. No font raster is used."""
from __future__ import annotations
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
for sub in ("native", "export", "preview"):
    (HERE / sub).mkdir(exist_ok=True)

# Each command x0,y0,x1,y1,width on a 32x32 integer grid. The radicals are
# original hand-authored stroke geometry, not a resized CJK font.
A = "5,4,9,7,2;9,7,8,11,2;4,13,8,16,2;8,10,7,21,2;7,21,3,28,2;8,17,11,22,2"
RAW = {
 "狐": A+";15,4,29,4,2;17,5,16,23,2;16,23,13,29,2;27,5,26,21,2;26,21,30,28,2;21,9,20,25,2;20,16,25,16,2;20,25,24,23,2;24,23,29,29,2",
 "狸": A+";15,5,29,5,2;15,5,15,18,2;29,5,29,18,2;15,12,29,12,2;15,18,29,18,2;22,5,22,29,2;14,23,30,23,2;13,29,30,29,2",
 "骑": "3,5,14,5,2;4,6,4,18,2;4,12,13,12,2;3,18,14,18,2;13,6,12,17,2;4,18,3,25,2;3,25,12,25,2;12,22,11,29,2;22,3,22,7,2;17,9,30,9,2;22,9,18,14,2;24,9,29,14,2;17,16,30,16,2;28,16,28,27,2;18,20,24,20,2;18,20,18,26,2;24,20,24,26,2;18,26,24,26,2;28,27,25,29,2",
 "士": "16,4,16,29,3;4,10,28,10,3;3,29,29,29,3",
 "胜": "4,5,13,5,2;4,5,4,23,2;13,5,13,28,2;4,13,13,13,2;4,20,13,20,2;4,23,2,29,2;18,6,29,6,2;18,14,29,14,2;17,21,30,21,2;23,3,23,29,2;16,29,30,29,2",
 "利": "3,9,17,6,2;10,7,10,29,2;2,15,18,15,2;10,16,2,26,2;10,16,17,24,2;23,8,23,22,2;29,4,29,27,2;29,27,25,29,2",
 "失": "12,3,7,12,2;8,11,26,11,2;17,5,17,20,2;4,20,29,20,2;17,20,5,29,2;18,20,29,29,2",
 "败": "3,7,14,7,2;3,7,3,22,2;14,7,14,22,2;7,12,7,20,2;4,22,13,22,2;9,22,3,29,2;11,23,15,27,2;21,4,18,12,2;18,12,30,12,2;27,13,23,22,2;23,22,17,29,2;22,19,30,29,2",
}
INK=(18,23,33,255); EDGE=(88,67,45,255)
GOLD=(214,166,77,255); LIGHT=(255,226,139,255); SPARK=(255,244,194,255)
RED=(204,101,87,255); RED_LIGHT=(255,155,133,255)
def shifted(mask, dx, dy):
    result=Image.new('L',mask.size); result.paste(mask,(dx,dy)); return result
def glyph(ch, failure=False):
    mask=Image.new('L',(36,36)); d=ImageDraw.Draw(mask)
    for command in RAW[ch].split(';'):
        x0,y0,x1,y1,w=map(int,command.split(','))
        d.line((x0+2,y0+1,x1+2,y1+1),fill=255,width=w)
    edge=mask.filter(ImageFilter.MaxFilter(3))
    img=Image.new('RGBA',mask.size)
    img.paste(INK,(0,0,36,36),shifted(edge,1,2))
    img.paste(EDGE,(0,0,36,36),edge)
    img.paste(RED if failure else GOLD,(0,0,36,36),mask)
    img.paste(RED_LIGHT if failure else LIGHT,(0,0,36,36),ImageChops.subtract(mask,shifted(mask,0,1)))
    return img
def wordmark():
    img=Image.new('RGBA',(184,40)); d=ImageDraw.Draw(img)
    d.polygon([(2,23),(5,7),(10,15),(14,5),(16,28)],fill=INK)
    d.line([(3,22),(6,10),(10,17),(14,8)],fill=GOLD,width=1)
    d.line([(3,32),(19,32)],fill=(150,107,55,255))
    for i,ch in enumerate('狐狸骑士'): img.alpha_composite(glyph(ch),(18+i*37,0))
    d=ImageDraw.Draw(img)
    d.line([(164,7),(178,21)],fill=GOLD,width=2)
    d.line([(166,7),(180,21)],fill=LIGHT,width=1)
    d.polygon([(176,19),(183,25),(177,23)],fill=SPARK)
    d.polygon([(72,37),(101,37),(107,39),(70,39)],fill=(99,47,50,255))
    d.line([(78,37),(96,37)],fill=(231,107,93,255))
    return img
def result(word, failure=False):
    img=Image.new('RGBA',(88,38)); d=ImageDraw.Draw(img)
    d.line([(2,18),(8,18)],fill=RED_LIGHT if failure else GOLD)
    d.line([(80,18),(86,18)],fill=RED_LIGHT if failure else GOLD)
    for i,ch in enumerate(word): img.alpha_composite(glyph(ch,failure),(8+i*36,0))
    return img
def focus():
    img=Image.new('RGBA',(64,16)); d=ImageDraw.Draw(img)
    for i in range(4):
        x=16*i
        d.line([(x+1,13),(x+1,2+i%2),(x+12,2+i%2)],fill=(150,107,55,255))
        d.line([(x+3,11),(x+3,4),(x+10,4)],fill=GOLD)
        d.point((x+4+i*2,4),fill=SPARK)
        d.point((x+3,9-i%3),fill=LIGHT)
    return img
def open_glint():
    img=Image.new('RGBA',(128,96)); d=ImageDraw.Draw(img)
    for i,w in enumerate((4,20,46,62,34,0)):
        if not w: continue
        y=i*16
        d.rectangle((64-w,y+7,64+w,y+8),fill=GOLD)
        d.rectangle((66-w,y+6,62+w,y+6),fill=LIGHT)
        if i in (2,3,4):
            d.line([(62,y+2),(66,y+13)],fill=(209,229,230,255))
            d.point((64,y+1),fill=SPARK)
    return img
def fox_crest():
    # Original small fox-head/blade emblem for the otherwise empty menu field.
    img=Image.new('RGBA',(64,64)); d=ImageDraw.Draw(img)
    d.polygon([(6,16),(12,4),(20,13),(31,9),(43,13),(51,4),(58,16),(54,39),(44,50),(32,57),(20,50),(10,39)],fill=INK)
    d.polygon([(10,17),(13,9),(21,17),(31,13),(43,17),(50,9),(54,17),(50,38),(42,46),(32,52),(22,46),(14,38)],fill=GOLD)
    d.polygon([(15,19),(23,23),(32,20),(41,23),(49,19),(48,36),(40,44),(32,48),(24,44),(16,36)],fill=(153,103,58,255))
    d.polygon([(20,30),(27,32),(32,38),(37,32),(44,30),(40,41),(32,47),(24,41)],fill=LIGHT)
    d.rectangle((22,27,25,29),fill=INK); d.rectangle((39,27,42,29),fill=INK)
    d.polygon([(30,38),(34,38),(32,41)],fill=INK)
    d.line([(32,11),(32,49)],fill=(231,224,188,255),width=1)
    d.polygon([(31,10),(33,10),(32,5)],fill=SPARK)
    return img
ASSETS={'foxknight_wordmark':wordmark(),'victory_lettering':result('胜利'),
 'failure_lettering':result('失败',True),'button_focus_corner':focus(),
 'menu_open_glint':open_glint(),'fox_crest':fox_crest()}
for name,img in ASSETS.items():
    img.save(HERE/'native'/f'{name}.png')
    img.resize((img.width*2,img.height*2),Image.Resampling.NEAREST).save(HERE/'export'/f'{name}.png')
META={'version':'1.0','pixel_scale':2,'filter':'nearest','alpha':'binary_0_or_255','assets':{
 'foxknight_wordmark':{'native_size':[184,40],'export_size':[368,80],'viewport_position_960x540':[296,67]},
 'victory_lettering':{'native_size':[88,38],'export_size':[176,76],'viewport_position_960x540':[187,392]},
 'failure_lettering':{'native_size':[88,38],'export_size':[176,76],'viewport_position_960x540':[187,392]},
 'button_focus_corner':{'native_frame':[16,16],'export_frame':[32,32],'frames':4,'layout':'horizontal','loop_ms':640},
 'menu_open_glint':{'native_frame':[128,16],'export_frame':[256,32],'frames':6,'layout':'vertical','frame_ms':60,'loop':False},
 'fox_crest':{'native_size':[64,64],'export_size':[128,128],'anchor':'center'}
}}
(HERE/'atlas.json').write_text(json.dumps(META,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def preview(source,target,erase,item,xy):
    path=ROOT/'output'/source
    if not path.exists(): return
    canvas=Image.open(path).convert('RGBA')
    ImageDraw.Draw(canvas).rectangle(erase,fill=(21,26,36,255))
    canvas.alpha_composite(Image.open(HERE/'export'/f'{item}.png'),xy)
    canvas.save(HERE/'preview'/target)
preview('ui_production_menu.png','menu_960x540.png',(382,73,580,127),'foxknight_wordmark',(296,67))
preview('ui_production_victory_01.png','victory_960x540.png',(211,401,332,462),'victory_lettering',(187,392))
preview('ui_production_failure_01.png','failure_960x540.png',(211,401,332,462),'failure_lettering',(187,392))
menu_with_crest=HERE/'preview'/'menu_960x540.png'
if menu_with_crest.exists():
    canvas=Image.open(menu_with_crest).convert('RGBA')
    canvas.alpha_composite(Image.open(HERE/'export'/'fox_crest.png'),(182,166))
    canvas.save(HERE/'preview'/'menu_with_crest_960x540.png')
print('title assets, metadata, and preview overlays generated')
