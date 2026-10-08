// FoxKnight v2 character source: every form is painted in a 24x28 integer grid.
// The source of all silhouettes is the visible ASCII pixel rows below, not a
// photo, generated image, filter or high-resolution downsample.
const fs=require('fs'),path=require('path'),zlib=require('zlib');
const root=__dirname, W=24,H=28,COLS=8, S=2;
const old=JSON.parse(fs.readFileSync(path.join(root,'frames.json'),'utf8'));
const palette={X:'#181b29',k:'#303447',o:'#a8432e',O:'#e1733c',H:'#f9b35b',W:'#ffe0aa',w:'#d5b489',R:'#743744',r:'#ae5760',A:'#506270',B:'#8ca7a8',C:'#d5e0d3',G:'#eac273',P:'#514354',p:'#887789',V:'#c7dacc',D:'#333344',Q:'#b44d51',q:'#f0d084'};
const rgb=Object.fromEntries(Object.entries(palette).map(([c,h])=>[c,[1,3,5].map(i=>parseInt(h.slice(i,i+2),16)).concat(255)]));
function blank(){return new Uint8Array(W*H*4)}
function px(a,x,y,c){if(x>=0&&y>=0&&x<W&&y<H&&rgb[c])a.set(rgb[c],(y*W+x)*4)}
function rows(a,x,y,map){for(let j=0;j<map.length;j++)for(let i=0;i<map[j].length;i++)if(map[j][i]!=='.')px(a,x+i,y+j,map[j][i])}
function line(a,x,y,n,c){for(let i=0;i<n;i++)px(a,x+i,y,c)}
function mirror(a){const b=blank();for(let y=0;y<H;y++)for(let x=0;x<W;x++)b.set(a.subarray((y*W+x)*4,(y*W+x+1)*4),(y*W+W-1-x)*4);return b}
// Broad cheeks and triangular ears make a fox, not a narrow-muzzled weasel.
// The thick white-tipped tail is separately timed from the planted feet.
const foxHead={
 front:['X............X','XO..........OX','XOr........rOX','XOOX......XOOX','.XOOXXXXXXOOX.','.XOOOOOOOOOOX.','.XHOOHOOHOOHX.','.XOOXOOOOXOOX.','.XOWWWWWWWWOX.','..XWWwWWwWWX..','...XWWWXWWWX...','....XWWWWWX....'],
 side:['..X......X...','..XO.....OX..','..XOr....OX..','..XOOX..XOX..','...XOOOOOOXX','...XHOOOOOOX','...XOOOOOXOX','...XOWWWWWWX','....XWWWWWWX','.....XWWWXWX','......XWWWWX','.......XXXXX'],
 back:['X............X','XO..........OX','XOr........rOX','XOOX......XOOX','.XOOXXXXXXOOX.','.XOOOOOOOOOOX.','.XHOOOOOOOOHX.','.XOOOOOOOOOOX.','..XHOOOOOOHX..','...XOOOOOOX...','....XOOOOX....','.....XXXX.....']
};
const foxBody={
 front:['..XXRRRRRRXX..','.XRrRRRRRRrRX.','.XAABBCCBBAAX.','.XABBCGCBBAAX.','.XAAABBBBAAAX.','..XAAAGAAAX...','..XRRRGRRRX...','...XXXXXXXX...'],
 side:['..XXRRRRRXX...','.XRRrRRRRRX...','.XAABBBCCAX...','.XAABBGCBBX...','.XAAABBBBAAX..','..XAAAGAAAX...','..XRRRGRRRX...','...XXXXXXXX...'],
 back:['..XXRRRRRRXX..','.XRrRRRRRRrRX.','.XAAAAABBBAX..','.XAAARAAABAX..','.XAAARRRAAAX..','..XAAAAAAAX...','..XRRRGRRRX...','...XXXXXXXX...']
};
const legPos=[[[6,21],[14,22]],[[8,22],[13,21]],[[8,22],[15,21]],[[7,21],[13,22]]];
function boots(a,phase,enemy){for(const [x,y] of legPos[phase])rows(a,x,y,enemy?['XPPX','XPPX','XDDX','XXXX']:['XAAX','XAAX','XkkX','XBBXX']);}
function tail(a,d,phase){const sway=[-1,0,2,1][phase];if(d==='side')rows(a,0,14+sway,['WXXXX','WWOOX','WWOOOX','.XOOOX','..XOX']);else if(d==='back')rows(a,14,16+sway,['..XOOOX','.XHOOOX','.XOOOX','.XWOX.','..XWWX','...XXX']);else rows(a,17,15+sway,['..XXX','.XOOX','XOOOWX','XOOOWX','.XOWWX','..XXXX']);}
function fox(dir,pose,f){const a=blank(),d=dir==='left'?'side':dir,walk=pose==='walk',phase=walk?f:(pose==='idle'?0:1),bob=walk?[0,-1,0,-1][f]:(pose==='idle'&&f?1:0);
 tail(a,d,phase);boots(a,phase,false);rows(a,5,13+bob,foxBody[d]);
 const swing=walk?[-2,0,2,0][f]:0;rows(a,3,15+(swing>0?1:0),['XX','AX','AX','OX','X.']);rows(a,18,15+(swing<0?1:0),['XX','XA','XA','XO','.X']);
 rows(a,5,2+bob,foxHead[d]);
 if(pose==='ready'){rows(a,17,12,['..C','..B','.G.','GX.']);rows(a,19,6,['C','C','B','B']);}
 if(pose==='straight'){const [x,y]=[[17,13],[19,12],[20,10],[18,13]][f];rows(a,x,y,['.CC','CB.','G..']);}
 if(pose==='arc'){const [x,y]=[[19,5],[21,9],[21,17],[17,20],[3,17],[2,9]][f];rows(a,x,y,['C','B','G']);if(f>=2&&f<=4){px(a,11,10+bob,'H');px(a,12,10+bob,'O')}}
 return dir==='left'?mirror(a):a;
}
const soldierHead={
 front:['....XXXXXX....','..XXPPPPPPXX..','.XPPPPPPPPPPX.','.XPPpPPPPpPPX.','.XAAAXXXXAAAX.','.XAVVVVVVVVAX.','..XDDDDDDDDX..','...XXPPPPXX...'],
 side:['..XXXXXXXX...','.XPPPPPPPPX..','.XPPpPPPPPX..','.XAAAXXAAAXX.','.XAAVVVVVVAX.','..XDDDDDDDX..','...XPPPPPX...','....XXXXXX...'],
 back:['....XXXXXX....','..XXPPPPPPXX..','.XPPPPPPPPPPX.','.XPPpPPPPpPPX.','.XAAAXXXXAAAX.','.XAAAPPPPA AAX'.replace(' ',''),'..XDDDDDDDDX..','...XXPPPPXX...']
};
const soldierBody=['..XXXPPPPXXX..','.XPAAPPPPAAPX.','.XAAAPPPPA AAX'.replace(' ',''),'.XAAAPVVPA AAX'.replace(' ',''),'.XAAAPPPPA AAX'.replace(' ',''),'..XPPPGPPPX...','..XDDDDDDDX...'];
function soldier(dir,pose,f){const a=blank(),d=dir==='left'?'side':dir;
 if(pose==='death'&&f>=2){rows(a,3,22,f===2?['..XXXPPXXXXXXX..','.XPPPPPPPPPPPX.','..XXXXXXXXXXX..']:['..XXXPPXXXXXX...','.XPPPPPPPPPPX..']);return dir==='left'?mirror(a):a}
 const walk=pose==='chase',phase=walk?f:0,bob=walk?[0,-1,0,-1][f]:(pose==='idle'&&f?1:0);
 boots(a,phase,true);rows(a,4,14+bob,soldierBody);rows(a,3,15+bob,['XX','AX','AX','PX','X.']);rows(a,18,15+bob,['XX','XA','XA','XP','.X']);rows(a,5,5+bob,soldierHead[d]);
 if(pose==='hit'){rows(a,5,10,['q........q','Q........Q']);px(a,12,8,'q')}
 if(pose==='death')rows(a,7,13,['.QPPQ','..XX.']);return dir==='left'?mirror(a):a;
}
function crc(b){let c=~0;for(const n of b){c^=n;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(~c)>>>0}
function png(w,h,a){const sig=Buffer.from([137,80,78,71,13,10,26,10]);function chunk(t,d){const n=Buffer.from(t),l=Buffer.alloc(4),c=Buffer.alloc(4);l.writeUInt32BE(d.length);c.writeUInt32BE(crc(Buffer.concat([n,d])));return Buffer.concat([l,n,d,c])}const ih=Buffer.alloc(13);ih.writeUInt32BE(w);ih.writeUInt32BE(h,4);ih[8]=8;ih[9]=6;const raw=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)Buffer.from(a.subarray(y*w*4,(y+1)*w*4)).copy(raw,y*(w*4+1)+1);return Buffer.concat([sig,chunk('IHDR',ih),chunk('IDAT',zlib.deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))])}
function enlarge(a,w,h,n){const b=new Uint8Array(w*n*h*n*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++)for(let j=0;j<n;j++)for(let i=0;i<n;i++)b.set(a.subarray((y*w+x)*4,(y*w+x+1)*4),((y*n+j)*w*n+x*n+i)*4);return b}
function sheet(kind){const frames=old[kind].frames,w=W*COLS,h=Math.ceil(frames.length/COLS)*H,a=new Uint8Array(w*h*4);frames.forEach((f,n)=>{const cel=kind==='fox'?fox(f.direction,f.animation,f.frame):soldier(f.direction,f.animation,f.frame),ox=n%COLS*W,oy=Math.floor(n/COLS)*H;for(let y=0;y<H;y++)for(let x=0;x<W;x++)a.set(cel.subarray((y*W+x)*4,(y*W+x+1)*4),((oy+y)*w+ox+x)*4)});fs.writeFileSync(path.join(root,'v2_'+kind+'_native.png'),png(w,h,a));fs.writeFileSync(path.join(root,'v2_'+kind+'_world2x.png'),png(w*S,h*S,enlarge(a,w,h,S)));return{native_size:[w,h],world_size:[w*S,h*S],frames};}
const manifest={schema:'foxknight.pixel_character.v2',native_frame:[W,H],native_to_world:S,foot_anchor_native:[12,25],directions:old.directions,palette,fox:sheet('fox'),soldier:sheet('soldier')};
fs.writeFileSync(path.join(root,'v2_frames.json'),JSON.stringify(manifest,null,2)+'\n');
const previewW=W*4*4*4,previewH=H*4*2,preview=new Uint8Array(previewW*previewH*4);
for(let actor=0;actor<2;actor++)for(let direction=0;direction<4;direction++)for(let f=0;f<4;f++){const d=old.directions[direction],cel=actor?soldier(d,'chase',f):fox(d,'walk',f),ox=(direction*4+f)*W*4,oy=actor*H*4;for(let y=0;y<H;y++)for(let x=0;x<W;x++)for(let j=0;j<4;j++)for(let i=0;i<4;i++)preview.set(cel.subarray((y*W+x)*4,(y*W+x+1)*4),((oy+y*4+j)*previewW+ox+x*4+i)*4)}
fs.writeFileSync(path.join(root,'v2_walk_review_4x.png'),png(previewW,previewH,preview));
console.log('Built v2: fox 72 frames; soldier 48 frames; 24x28 native + exact nearest 2x.');
