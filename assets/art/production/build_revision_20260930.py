"""Authored integer-grid UI and slash resources. No bitmap resampling as source.
Run with Pillow. Native source is this geometry plus saved native PNGs.
"""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
UI = ROOT / 'ui/r3_20260930'
FX = ROOT / 'fx/revision_20260930'
P = dict(base='#45586C', hover='#566D80', dark='#2A394C', edge='#B8B6A6',
         ink='#F0E2BD', red='#754951', muted='#73818B')
checks = []

def canvas(size):
    im = Image.new('RGBA', size)
    return im, ImageDraw.Draw(im)

def save(root, name, im):
    for sub in ('native', 'export'):
        (root/sub).mkdir(parents=True, exist_ok=True)
    assert set(im.getchannel('A').getdata()) <= {0, 255}, name
    im.save(root/'native'/f'{name}.png')
    doubled = im.resize((im.width*2, im.height*2), Image.Resampling.NEAREST)
    doubled.save(root/'export'/f'{name}.png')
    assert Image.open(root/'export'/f'{name}.png').tobytes() == doubled.tobytes()
    checks.append(dict(name=name, native=list(im.size), exact_2x=True, hard_alpha=True))

def panel(d, box, body, border=P['edge']):
    x,y,w,h = box
    d.rectangle((x+1,y+1,x+w-2,y+h-1), fill=P['dark'])
    d.polygon([(x+2,y),(x+w-3,y),(x+w-1,y+2),(x+w-1,y+h-4),
               (x+w-3,y+h-2),(x+2,y+h-2),(x,y+h-4),(x,y+2)], fill=border)
    d.rectangle((x+1,y+2,x+w-2,y+h-4),fill=body)
    d.line((x+2,y+1,x+w-3,y+1), fill=body)
    d.line((x+2,y+h-3,x+w-3,y+h-3), fill=body)

def ui():
    im,d=canvas((120,135))
    for row,body in enumerate((P['base'],P['hover'],P['dark'],P['base'],'#3B4B5A')):
        if row!=3:
            panel(d,(0,row*27,120,27),body,P['muted'] if row==4 else P['edge'])
        if row==3:
            y=row*27
            for x,s in ((4,1),(115,-1)):
                d.line((x,y+5,x+4*s,y+5),fill=P['ink'])
                d.line((x,y+5,x,y+9),fill=P['ink'])
    save(UI,'button_states',im)
    for name in ('hud_panel_9slice','result_panel_9slice'):
        im,d=canvas((32,32)); panel(d,(0,0,32,32),P['base']); save(UI,name,im)
    im,d=canvas((260,18)); panel(d,(0,0,260,18),P['base']); save(UI,'hint_ribbon',im)
    im,d=canvas((168,8)); d.line((8,4,159,4),fill=P['edge']); save(UI,'result_divider',im)
    im,d=canvas((16,48))
    # Blade, soldier helmet (not a target diamond), retry.
    d.polygon([(4,12),(11,3),(14,1),(13,5),(6,13)],fill=P['ink'])
    d.line((3,10,8,14),fill=P['edge'],width=2); d.line((3,14,5,12),fill=P['red'],width=2)
    d.polygon([(4,18),(11,18),(13,21),(13,28),(10,30),(4,30),(2,27),(2,21)],fill=P['dark'])
    d.polygon([(5,19),(10,19),(12,22),(11,28),(9,29),(4,28),(3,22)],fill=P['edge'])
    d.rectangle((4,23,11,24),fill=P['dark']); d.line((8,20,8,27),fill=P['ink'])
    d.line([(12,38),(7,35),(3,38),(2,42),(4,46),(10,46),(13,43)], fill=P['ink'],width=2)
    d.polygon([(10,36),(14,36),(14,41)],fill=P['ink']);save(UI,'icons_blade_target_retry',im)
    digits=['111/101/101/101/111','010/110/010/010/111','111/001/111/100/111',
            '111/001/111/001/111','101/101/111/001/001','111/100/111/001/111',
            '111/100/111/101/111','111/001/010/010/010','111/101/111/101/111','111/101/111/001/111']
    im,d=canvas((60,9))
    for n,glyph in enumerate(digits):
        for y,row in enumerate(glyph.split('/')):
            for x,bit in enumerate(row):
                if bit=='1': d.point((n*6+x+1,y+2),fill=P['ink'])
    save(UI,'digits_0_to_9',im)
    im,d=canvas((480,270)); d.rectangle((0,0,479,269),fill='#303F51')
    # Quiet courtyard framing with open, lighter center. No steel ornaments.
    for y in range(0,270,18):
        for x in range(-24 if y//18%2 else 0,480,38):
            if x < 70 or x > 384:
                d.rectangle((x+1,y+1,x+36,y+16),fill='#384A5C')
                d.line((x+3,y+2,x+33,y+2),fill='#425569')
    for x in (56,418):
        d.rectangle((x,42,x+5,233),fill='#263647')
        d.line((x+1,44,x+1,229),fill='#536276')
    for y in range(228,270,14):
        d.line((65,y,414,y),fill='#37495A')
        for x in range(70+(y//14%2)*18,414,52): d.line((x,y,x,y+12),fill='#37495A')
    # Small edge ivy groups stay outside the buttons and title.
    for x,y in [(34,22),(44,55),(421,32),(435,67),(32,211),(447,216)]:
        d.line((x,y,x+4,y+18),fill='#354C48')
        for dx,dy in [(0,0),(4,6),(-2,12)]:
            d.polygon([(x+dx,y+dy),(x+dx+5,y+dy+1),(x+dx+3,y+dy+4),(x+dx-1,y+dy+3)],fill='#64705A')
    save(UI,'menu_base',im)
    im,d=canvas((480,270)); save(UI,'menu_ornaments',im)
    # Authorized Noto glyphs rasterized directly on the native grid: complete CJK
    # structure takes priority over the earlier inaccurate hand-stroked radicals.
    # This is native-size typography, not a claim of a newly authored pixel font.
    font=ImageFont.truetype(str(ROOT/'fonts/NotoSansCJKsc-Regular.otf'),32)
    def glyph(ch):
        im,d=canvas((36,36))
        d.fontmode='1'
        d.text((2,3),ch,font=font,anchor='lt',fill=P['dark'])
        d.text((2,2),ch,font=font,anchor='lt',fill=P['ink'])
        return im
    for name,text,size,start in [('foxknight_wordmark','狐狸骑士',(184,40),18),
                                 ('victory_lettering','胜利',(88,38),8),('failure_lettering','失败',(88,38),8)]:
        im,d=canvas(size)
        for i,ch in enumerate(text): im.alpha_composite(glyph(ch),(start+i*37,0))
        save(UI,name,im)
    contact=Image.new('RGBA',(480,220),'#303F51')
    for i,name in enumerate(('button_states','hud_panel_9slice','icons_blade_target_retry','foxknight_wordmark')):
        part=Image.open(UI/'native'/f'{name}.png'); contact.alpha_composite(part,[(12,12),(146,12),(193,12),(240,12)][i])
    contact.alpha_composite(Image.open(UI/'native/hint_ribbon.png'),(146,76))
    contact.alpha_composite(Image.open(UI/'native/victory_lettering.png'),(146,120))
    contact.alpha_composite(Image.open(UI/'native/failure_lettering.png'),(246,120))
    contact.resize((960,440),Image.Resampling.NEAREST).save(UI/'component_review.png')

def fx():
    # Pixel centers are checked against the actual 55-native-pixel radius.
    atlas=Image.new('RGBA',(720,120))
    for frame in range(6):
        im,d=canvas((120,120)); head=math.radians(-80+frame*66)
        for y in range(120):
            for x in range(120):
                dx,dy=x+.5-60,y+.5-60;r=math.hypot(dx,dy)
                farthest_corner=math.hypot(abs(dx)+.5,abs(dy)+.5)
                if not 12<=r<=55 or farthest_corner>55: continue
                lag=(head-math.atan2(dy,dx))%(2*math.pi)
                if lag>1.5: continue
                taper=max(0,1-lag/1.5)
                outer=55;inner=outer-(2+7*taper)
                if r>=inner:
                    color='#FFF1C5' if r>53 and lag<.45 else '#FFD077' if r>51 else '#EF9B3B' if lag<.9 else '#A85427'
                    d.point((x,y),fill=color)
                elif lag<.12 and r>15:
                    d.point((x,y),fill='#FFD077')
        atlas.alpha_composite(im,(frame*120,0))
        for y in range(120):
            for x in range(120):
                if im.getpixel((x,y))[3]:
                    assert math.hypot(abs(x+.5-60)+.5,abs(y+.5-60)+.5)<=55
    save(FX,'arc_blade',atlas)
    for name,h in [('straight_blade',36),('straight_tip',16)]:
        atlas=Image.new('RGBA',(64,h))
        for f in range(4):
            im,d=canvas((16,h));width=[6,5,4,2][f]
            for y in range(h):
                local=width if name=='straight_blade' else max(0,round(width*(h-1-y)/(h-1)))
                for x in range(8-local,9+local):
                    color='#287D9C' if abs(x-8)==local else '#65CCE6' if abs(x-8)>1 else '#C7F5FA'
                    d.point((x,y),fill=color)
            atlas.alpha_composite(im,(f*16,0))
        save(FX,name,atlas)
    for name in ('hit','death'):
        atlas=Image.new('RGBA',(64,16))
        for f in range(4):
            im,d=canvas((16,16))
            if name=='hit':
                extent=[3,6,4,2][f]
                d.line((8-extent,8,8+extent,8),fill='#C7F5FA')
                d.line((8,8-extent,8,8+extent),fill='#F0E2BD')
                if f<2:d.rectangle((7,7,9,9),fill='#FFF1C5')
            else:
                for x,y in [(4-f,8+f),(10+f,6+f),(7,11+f)]:
                    d.rectangle((x,y,x+1,y+1),fill='#78899A' if f<2 else '#45586C')
            atlas.alpha_composite(im,(16*f,0))
        save(FX,name,atlas)
    manifest=dict(scale=2,layout='horizontal',arc=dict(file='export/arc_blade.png',frames=6,
        native_frame=[120,120],world_frame=[240,240],anchor_world=[120,120],radius_world=110,duration=.22),
        straight=dict(file='export/straight_blade.png',frames=4,world_frame=[32,72],axis='down',duration=.22),
        tip=dict(file='export/straight_tip.png',frames=4,world_frame=[32,32],axis='down'),
        hit=dict(file='export/hit.png',frames=4,world_frame=[32,32],duration=.09),
        death=dict(file='export/death.png',frames=4,world_frame=[32,32],duration=.18))
    (FX/'frames.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    review=Image.new('RGBA',(720,160),'#303F51');review.alpha_composite(Image.open(FX/'native/arc_blade.png'))
    for i,name in enumerate(('straight_blade','straight_tip','hit','death')):
        im=Image.open(FX/'native'/f'{name}.png');review.alpha_composite(im,(i*130,120))
    review.resize((1440,320),Image.Resampling.NEAREST).save(FX/'contact_review.png')

if __name__=='__main__':
    ui();fx()
    (UI/'pixel_checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
    print(f'Wrote and checked {len(checks)} native/export pairs; arc radius <=110 world pixels.')
