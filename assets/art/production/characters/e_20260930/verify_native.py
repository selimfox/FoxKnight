"""Structural checks only. Visual acceptance requires contact sheet and game review."""
import json
from pathlib import Path
from PIL import Image
R=Path(__file__).resolve().parent
m=json.loads((R/'frames.json').read_text())
report={}
for actor in ('fox','soldier'):
    native=Image.open(R/f'{actor}_native.png').convert('RGBA')
    world=Image.open(R/f'{actor}_world2x.png').convert('RGBA')
    assert native.resize(world.size,Image.Resampling.NEAREST).tobytes()==world.tobytes()
    assert set(native.tobytes()[3::4])<={0,255}
    source=json.loads((R/f'{actor}_pixel_source.json').read_text())
    states={}; silhouettes={}
    boundary_frames=[]; recovered=[]
    for frame,pixels in zip(m[actor]['frames'],source['frames']):
        x,y,w,h=frame['rect']; original=native.crop((x,y,x+w,y+h))
        recreated=Image.new('RGBA',(w,h))
        recreated.putdata([tuple(source['palette'][p]) for row in pixels['rows'] for p in row])
        assert original.tobytes()==recreated.tobytes(),(actor,frame['animation'],frame['index'])
        assert frame['foot_anchor']==m[actor]['foot_anchor_native']
        if actor=='fox':
            alpha=original.getchannel('A')
            assert alpha.crop((0,0,w,1)).getbbox() is None
            assert alpha.crop((0,h-1,w,h)).getbbox() is None
            assert alpha.crop((0,0,1,h)).getbbox() is None
            assert alpha.crop((w-1,0,w,h)).getbbox() is None
            # Pixels beyond the former 40px work area demonstrate true recovery,
            # rather than padding a previously clipped PNG.
            old_box=(4,4,44,44)
            count=sum(original.getpixel((px,py))[3]>0 for py in range(h) for px in range(w) if not(4<=px<44 and 4<=py<44))
            if count: recovered.append({'state':frame['animation'],'direction':frame['direction'],'index':frame['index'],'recovered_pixels':count})
        k=frame['animation']+'/'+frame['direction']
        states.setdefault(k,[]).append(frame['duration_ms'])
        silhouettes.setdefault(k,set()).add(original.tobytes())
    for k,frames in silhouettes.items():
        if len(states[k])>1: assert len(frames)>1,('No animation',actor,k)
    for direction in m['directions']:
        if actor=='fox':
            assert sum(states['straight/'+direction])==220
            assert sum(states['arc/'+direction])==220
        else:
            assert sum(states['hit/'+direction])==100
            assert sum(states['death/'+direction])==260
    report[actor]={'frame_count':len(m[actor]['frames']),'anchor':m[actor]['foot_anchor_native'],'palette_count':len(source['palette'])-1,'native_atlas_size':list(native.size),'sequences':len(states),'hard_alpha':True,'exact_nearest_2x':True,'source_roundtrip':True,'all_multiframe_states_have_distinct_pixels':True}
    if actor=='fox':
        report[actor]['all_frame_outer_edges_transparent']=True
        report[actor]['formerly_clipped_strokes_recovered']=recovered
portrait=Image.open(R/'e_fox_portrait_r4_native_48.png').convert('RGBA')
assert portrait.size==(48,48)
assert set(portrait.tobytes()[3::4])<={0,255}
report['portrait']={'native_size':[48,48],'hard_alpha':True}
report['visual_acceptance']='Source/contact sheets reviewed; live game review still required. No aesthetic approval inferred.'
print(json.dumps(report,indent=2))
(R/'pixel_checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
