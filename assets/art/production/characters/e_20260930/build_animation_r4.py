"""E native-pixel production. Authored integer-grid parts, no AI image reduction.

Head identity comes from this package's original editable low-grid drawing.
Torso, independent feet, arms, sword and delayed tail are authored per pose.
Every output also has a palette-index text source for individual pixel edits.
"""
from pathlib import Path
import json, math, runpy
from PIL import Image, ImageDraw
from build_e_characters import P, draw_fox_front, draw_fox_side, draw_fox_back

ROOT=Path(__file__).resolve().parent
DIRECTIONS=['front','side','back','left']
def rect(d,c,xy): d.rectangle(xy,fill=P[c])
def poly(d,c,pts): d.polygon(pts,fill=P[c])
def line(d,c,pts,w=1): d.line(pts,fill=P[c],width=w)

def portrait():
    # Original native bust retained; all facial features are freshly pixel drawn.
    portrait_path=ROOT/'build_e_portrait.py'
    context={'__file__':str(portrait_path),'__name__':'portrait_source'}
    exec(compile(portrait_path.read_text(encoding='utf-8').split('assert set(im.tobytes()')[0],str(portrait_path),'exec'),context)
    im=context['im'].copy(); d=ImageDraw.Draw(im)
    poly(d,'fur',[(17,28),(23,29),(28,28),(33,29),(32,34),(27,36),(21,34)])
    poly(d,'fur_lit',[(20,28),(26,28),(30,29),(28,32),(23,32)])
    # Two cream cheeks stay distinct from the central short muzzle.
    poly(d,'cream',[(6,28),(11,27),(15,29),(18,33),(17,36),(12,36),(8,33)])
    poly(d,'cream_lit',[(7,29),(11,28),(15,31),(15,33),(11,33)])
    poly(d,'cream',[(34,29),(40,27),(43,29),(41,33),(36,36),(32,36),(31,34)])
    poly(d,'cream_lit',[(35,30),(39,28),(41,29),(39,32),(35,33)])
    # Amber irises surround narrow pupils; white is one glint, never an eye ring.
    for x,y in [(14,23),(31,22)]:
        poly(d,'fur',[(x-1,y-2),(x+7,y-2),(x+7,y+7),(x-1,y+7)])
        poly(d,'eye',[(x,y+1),(x+2,y),(x+4,y),(x+6,y+2),(x+6,y+4),(x+4,y+6),(x+2,y+6),(x,y+4)])
        poly(d,'iris',[(x+2,y+1),(x+4,y+1),(x+5,y+3),(x+4,y+5),(x+2,y+5)])
        rect(d,'fur_peak',(x+2,y+3,x+2,y+4))
        rect(d,'eye',(x+3,y+2,x+3,y+5))
        d.point((x+2,y+1),fill=P['cream_white'])
        line(d,'fur_dark',[(x,y-1),(x+2,y-2),(x+5,y-1)])
    poly(d,'cream',[(23,34),(27,33),(30,34),(32,36),(29,38),(25,38),(22,36)])
    poly(d,'cream_lit',[(24,35),(28,34),(30,35),(29,37),(25,37)])
    poly(d,'eye',[(26,33),(28,33),(29,34),(28,35),(27,35)])
    d.point((26,33),fill=P['steel_dark'])
    line(d,'deep',[(28,35),(27,37),(25,37),(24,36)])
    return im

HEADS={'front':draw_fox_front(),'side':draw_fox_side(),'back':draw_fox_back()}
def fox(state,index):
    # Draw on a larger working canvas so thick sword-end strokes at x=39
    # remain intact. Padding is added later without scaling any actor pixels.
    im=Image.new('RGBA',(48,48)); d=ImageDraw.Draw(im)
    moving=state in ('walk','ready_walk')
    step=[-2,-1,1,2,1,-1][index%6] if moving else ([1,0][index] if state=='stop' else 0)
    lift=[0,1,1,0,1,1][index%6] if moving else 0
    bob=-lift if moving else (-1 if state=='idle' and index==2 else (index if state=='ready' else 0))
    sway=([0,-1,-1,0,1,1][index%6] if moving else [0,0,-1,0][index%4])
    # Tail attached at hip, rising to cream tip. Delay opposite gait.
    poly(d,'edge',[(25,29),(29,25+sway),(33,22+sway),(37,18+sway),(39,20+sway),(38,25+sway),(34,29),(29,31)])
    poly(d,'fur_dark',[(26,29),(30,26+sway),(35,22+sway),(38,20+sway),(37,25+sway),(33,28),(29,30)])
    poly(d,'fur',[(28,28),(32,24+sway),(36,22+sway),(37,23+sway),(34,27),(30,29)])
    poly(d,'cream',[(35,21+sway),(38,19+sway),(38,23+sway),(36,25+sway),(34,24+sway)])
    poly(d,'cream_lit',[(37,20+sway),(38,20+sway),(37,23+sway),(36,23+sway)])
    # Separately posed upper legs, knees, boot armor and orange paws.
    for x,s,up in [(15,step,lift),(24,-step,1-lift if moving else 0)]:
        poly(d,'edge',[(x-2,29),(x+3,29),(x+3+s,33-up),(x+4+s,35-up),(x-3+s,35-up),(x-2+s,32-up)])
        poly(d,'steel_dark',[(x-1,30),(x+2,30),(x+2+s,33-up),(x-2+s,33-up)])
        rect(d,'steel',(x-2+s,32-up,x+2+s,33-up))
        poly(d,'fur_dark',[(x-2+s,34-up),(x+2+s,34-up),(x+3+s,35-up),(x-3+s,35-up)])
        line(d,'fur_lit',[(x-2+s,35-up),(x+2+s,35-up)])
    poly(d,'edge',[(14,25+bob),(25,25+bob),(27,29),(24,31),(16,31),(12,29)])
    poly(d,'steel_dark',[(15,26+bob),(24,26+bob),(25,29),(22,30),(16,30),(14,29)])
    poly(d,'steel',[(17,26+bob),(23,26+bob),(23,28+bob),(17,29+bob)])
    line(d,'steel_lit',[(18,27+bob),(22,27+bob)])
    line(d,'deep',[(15,30),(25,30)],2); d.point((21,30),fill=P['guard'])
    return im,bob,step

def fox_frame(state,index,direction):
    # Mirror anatomical base for left; body is never rotated for arc motion.
    source_direction='side' if direction=='left' else direction
    im,bob,step=fox(state,index); d=ImageDraw.Draw(im)
    head=HEADS[source_direction]
    mask=Image.new('L',(40,40)); md=ImageDraw.Draw(mask)
    # Exclude tail/sword pixels while retaining authored E face and ears.
    md.polygon([(8,0),(34,0),(34,23),(32,25),(10,25),(8,21)],fill=255)
    head=Image.composite(head,Image.new('RGBA',(40,40)),mask)
    im.alpha_composite(head,(0,bob))
    poly(d,'scarf_dark',[(14,24+bob),(21,25+bob),(27,24+bob),(28,26+bob),(24,29+bob),(16,28+bob),(13,26+bob)])
    poly(d,'scarf',[(15,25+bob),(21,26+bob),(26,25+bob),(26,27+bob),(22,28+bob),(16,27+bob)])
    line(d,'scarf_lit',[(16,25+bob),(21,27+bob),(25,26+bob)])
    poly(d,'scarf_dark',[(15,27),(17,29),(14+step//2,32),(12+step//2,31),(13,29)])
    line(d,'scarf_lit',[(15,28),(14+step//2,30)])
    # Off-hand shoulder and forearm counter swing.
    poly(d,'edge',[(11,25+bob),(14,24+bob),(16,26+bob),(15,29+bob),(12,29+bob),(10,27+bob)])
    poly(d,'steel',[(12,25+bob),(14,25+bob),(15,27+bob),(13,28+bob),(11,27+bob)])
    line(d,'steel_lit',[(12,25+bob),(14,26+bob)])
    hand=(29,29+bob); tip=(37,35)
    if state in ('ready','ready_walk'):
        hand=(29,27+bob); tip=(36,20+bob)
    if state=='cancel':
        hand=[(29,27),(29,29)][index]; tip=[(37,24),(37,35)][index]
    if state=='straight':
        hand=[(29,27),(31,26),(31,27),(29,29)][index]
        tip=[(35,22),(39,23),(39,25),(37,35)][index]
    if state=='arc':
        hand=[(28,26),(27,25),(22,25),(16,27),(22,29),(29,29)][index]
        tip=[(35,20),(24,15),(12,20),(8,30),(23,38),(37,35)][index]
    if state=='post': hand=(29,30); tip=(35,37)
    if state=='walk': hand=(29+step//2,29+bob); tip=(37,34+bob)
    # Upper arm, orange gripping hand and blade all obey the same joint pose.
    line(d,'edge',[(26,26+bob),hand],5)
    line(d,'fur_dark',[(26,26+bob),hand],3)
    rect(d,'fur',(hand[0]-1,hand[1]-1,hand[0]+1,hand[1]+1))
    d.point((hand[0],hand[1]-1),fill=P['fur_lit'])
    vx,vy=tip[0]-hand[0],tip[1]-hand[1]; length=max(math.hypot(vx,vy),1)
    gx,gy=round(-vy/length*2),round(vx/length*2)
    line(d,'edge',[hand,tip],3)
    line(d,'steel',[(hand[0]+round(vx/length*2),hand[1]+round(vy/length*2)),tip],2)
    line(d,'blade',[(hand[0]+round(vx/length*3),hand[1]+round(vy/length*3)),tip])
    line(d,'guard',[(hand[0]+gx,hand[1]+gy),(hand[0]-gx,hand[1]-gy)],1)
    if direction=='back':
        # Back view keeps weapon behind near shoulder, not an invented second hand.
        poly(d,'steel_dark',[(25,25+bob),(28,25+bob),(28,27+bob),(25,28+bob)])
    padded=Image.new('RGBA',(48,48))
    padded.alpha_composite(im,(4,4))
    im=padded
    if direction=='left':
        im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        # Near-side scarf knot is authored separately instead of mirroring all clothing.
        ld=ImageDraw.Draw(im)
        poly(ld,'scarf_dark',[(28,30+bob),(30,32+bob),(32,34+bob),(30,35+bob),(27,32+bob)])
        line(ld,'scarf_lit',[(29,31+bob),(31,33+bob)])
    return im

SP={'edge':'#292738','dark':'#3d3b50','armor':'#625d77','lit':'#90859a','visor':'#94b9bb','boot':'#343746','blade':'#a3adb0'}
def soldier_frame(state,index,direction):
    im=Image.new('RGBA',(32,36)); d=ImageDraw.Draw(im)
    def q(c,pts): d.polygon(pts,fill=SP[c])
    def r(c,xy): d.rectangle(xy,fill=SP[c])
    moving=state=='walk'; step=[-2,-1,1,2,1,-1][index%6] if moving else 0
    bob=-1 if moving and index in (1,2,4,5) else (index if state=='idle' else 0)
    if state=='death':
        drop=[0,2,5,8,11][index]; spread=[0,1,2,3,4][index]
    else: drop=0; spread=0
    top=10+bob+drop
    # Short square silhouette, with mask directional cue and no attack pose.
    for x,s in [(12,step),(20,-step)]:
        q('edge',[(x-2,27),(x+2,27),(x+2+s,31),(x+3+s,33),(x-3+s,33)])
        r('dark',(x-1+s,28,x+1+s,31)); r('boot',(x-2+s,32,x+2+s,33))
    if state=='death' and index>=3:
        im=Image.new('RGBA',(32,36)); d=ImageDraw.Draw(im)
    waist=min(top+18,33)
    q('edge',[(8-spread,top+9),(23+spread,top+9),(25+spread,min(top+17,33)),(22,waist),(10,waist),(6-spread,min(top+17,33))])
    q('dark',[(9-spread,top+10),(22+spread,top+10),(24+spread,min(top+16,32)),(20,waist-1),(11,waist-1),(8-spread,min(top+16,32))])
    q('armor',[(11,top+10),(20,top+10),(21, min(top+15,31)),(16, min(top+18,32)),(11,min(top+15,31))])
    q('lit',[(11,top+10),(19,top+10),(18,top+11),(11,top+12)])
    q('edge',[(10,top),(21,top),(23,top+3),(23,top+9),(20,top+11),(11,top+11),(8,top+8),(8,top+3)])
    q('armor',[(11,top+1),(20,top+1),(22,top+4),(21,top+8),(18,top+10),(11,top+9),(9,top+7),(9,top+4)])
    q('lit',[(11,top+1),(18,top+1),(19,top+2),(11,top+3)])
    if direction=='front': r('edge',(10,top+5,21,top+7)); r('visor',(11,top+5,20,top+5))
    elif direction in ('side','left'): r('edge',(17,top+5,22,top+7)); r('visor',(18,top+5,22,top+5))
    else: r('dark',(12,top+4,18,top+7))
    if state!='death':
        for x,s in [(7,-step//2),(24,step//2)]:
            q('edge',[(x-2,top+9),(x+2,top+9),(x+3+s,top+15),(x-1+s,top+16)])
            q('armor',[(x-1,top+10),(x+1,top+10),(x+2+s,top+14),(x+s,top+15)])
        d.line([(6,top+10),(8,top+10)],fill=SP['lit'])
        d.line([(25,26),(27,31)],fill=SP['edge'],width=3); d.line([(25,27),(27,31)],fill=SP['blade'])
    if state=='hit' and index==0:
        d.line([(10,top),(21,top),(23,top+3)],fill='#e0dbca',width=1)
    if direction=='left': im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return im

FOX={'idle':[200]*4,'walk':[80]*6,'stop':[50]*2,'ready':[250]*2,'ready_walk':[80]*6,'cancel':[40]*2,'straight':[55]*4,'arc':[30,35,40,40,40,35],'post':[200]}
SOLDIER={'idle':[350]*2,'walk':[80]*6,'hit':[50]*2,'death':[45,45,50,55,65]}
def export_actor(actor,spec,draw,size,anchor):
    entries=[]; rows=[]; columns=max(map(len,spec.values()))
    atlas=Image.new('RGBA',(columns*size[0],len(spec)*4*size[1]))
    for state,durations in spec.items():
        for direction in DIRECTIONS:
            row=len(rows); frames=[]
            for i,ms in enumerate(durations):
                frame=draw(state,i,direction); frames.append(frame)
                assert set(frame.tobytes()[3::4])<={0,255}
                atlas.alpha_composite(frame,(i*size[0],row*size[1]))
                entries.append({'animation':state,'direction':direction,'index':i,'duration_ms':ms,'rect':[i*size[0],row*size[1],*size],'foot_anchor':anchor})
            rows.append((state,direction,frames))
            gif_frames=[]
            for fr in frames:
                bg=Image.new('RGBA',size,'#455363'); bg.alpha_composite(fr)
                gif_frames.append(bg.convert('RGB').resize((size[0]*4,size[1]*4),Image.Resampling.NEAREST))
            gif_frames[0].save(ROOT/f'{actor}_{state}_{direction}.gif',save_all=True,append_images=gif_frames[1:],duration=durations,loop=0,disposal=2)
    atlas.save(ROOT/f'{actor}_native.png')
    atlas.resize((atlas.width*2,atlas.height*2),Image.Resampling.NEAREST).save(ROOT/f'{actor}_world2x.png')
    # Native contact sheet preserves every frame, label column uses review-only text.
    sheet=Image.new('RGB',(150+columns*size[0]*3,len(rows)*size[1]*3),'#455363'); sd=ImageDraw.Draw(sheet)
    for row,(state,direction,frames) in enumerate(rows):
        sd.text((5,row*size[1]*3+10),state+'/'+direction,fill='#eee2c7')
        for i,fr in enumerate(frames): sheet.paste(fr.resize((size[0]*3,size[1]*3),Image.Resampling.NEAREST),(150+i*size[0]*3,row*size[1]*3),fr.resize((size[0]*3,size[1]*3),Image.Resampling.NEAREST))
    sheet.save(ROOT/f'{actor}_contact3x.png')
    for state in spec:
        selected=[row for row in rows if row[0]==state]
        state_sheet=Image.new('RGB',(120+columns*size[0]*2,4*size[1]*2),'#455363')
        state_draw=ImageDraw.Draw(state_sheet)
        for row,(_,direction,frames) in enumerate(selected):
            state_draw.text((5,row*size[1]*2+10),state+'/'+direction,fill='#eee2c7')
            for i,fr in enumerate(frames):
                large=fr.resize((size[0]*2,size[1]*2),Image.Resampling.NEAREST)
                state_sheet.paste(large,(120+i*size[0]*2,row*size[1]*2),large)
        state_sheet.save(ROOT/f'{actor}_{state}_contact2x.png')
    # Palette-indexed rows are exact editable sources independent of Pillow draw code.
    colors=sorted(set(atlas.getdata())-{(0,0,0,0)})
    symbols='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+,-/:;<=>?@[]^_{|}~'
    assert len(colors)<len(symbols)
    palette={'.':[0,0,0,0],**{symbols[i]:list(c) for i,c in enumerate(colors)}}
    lookup={tuple(v):k for k,v in palette.items()}
    source={'size':size,'foot_anchor':anchor,'palette':palette,'frames':[]}
    for row,(state,direction,frames) in enumerate(rows):
        for i,fr in enumerate(frames): source['frames'].append({'animation':state,'direction':direction,'index':i,'rows':[''.join(lookup[fr.getpixel((x,y))] for x in range(size[0])) for y in range(size[1])]})
    (ROOT/f'{actor}_pixel_source.json').write_text(json.dumps(source,indent=2),encoding='utf-8')
    return {'native_frame':size,'foot_anchor_native':anchor,'frames':entries}

if __name__=='__main__':
    # runpy uses original portrait output names; route its saves to independent R4 files.
    # portrait() draws original native recipe only, never reads existing PNGs.
    portrait_image=portrait()
    portrait_image.save(ROOT/'e_fox_portrait_r4_native_48.png')
    portrait_image.resize((96,96),Image.Resampling.NEAREST).save(ROOT/'e_fox_portrait_r4_world2x.png')
    for scale in (2,4): portrait_image.resize((48*scale,48*scale),Image.Resampling.NEAREST).save(ROOT/f'e_fox_portrait_r4_review{scale}x.png')
    for direction in DIRECTIONS:
        static=fox_frame('idle',0,direction)
        static.save(ROOT/f'e_fox_r4_{direction}_native.png')
        static.resize((96,96),Image.Resampling.NEAREST).save(ROOT/f'e_fox_r4_{direction}_world2x.png')
    result={'schema':'foxknight.pixel_character.v1','native_to_world':2,'directions':DIRECTIONS}
    result['fox']=export_actor('fox',FOX,fox_frame,[48,48],[24,39])
    result['soldier']=export_actor('soldier',SOLDIER,soldier_frame,[32,36],[16,33])
    (ROOT/'frames.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('Native E production: 132 fox frames, 60 soldier frames; attack 220ms, death 260ms.')
