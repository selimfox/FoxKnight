// Native, hand-placed integer-grid source. Run `node build_sprites.js` here.
const fs=require('fs'),path=require('path'),zlib=require('zlib');
const W=24,H=28,S=2,C=8;
const palette={ink:'#20202c',deep:'#292b3b',shade:'#393d50',steel:'#718596',silver:'#a3b1a9',glint:'#d8dabe',rust:'#a34d32',fur:'#d46c3e',furhi:'#ee9b56',cream:'#f3d09a',pale:'#ffe6b2',gold:'#e8b65f',scarf:'#893b4b',enemy:'#695c6c',enemyhi:'#998091',enemyshade:'#382f42',visor:'#c8e0d1',hit:'#f5dd9b',blood:'#ad514d'};
const rgb=Object.fromEntries(Object.entries(palette).map(([k,v])=>[k,[1,3,5].map(i=>parseInt(v.slice(i,i+2),16)).concat(255)]));
const blank=()=>new Uint8Array(W*H*4);
function px(a,x,y,c){if(x<0||y<0||x>=W||y>=H)return;a.set(rgb[c],(y*W+x)*4)}
function box(a,x,y,w,h,c){for(let j=y;j<y+h;j++)for(let i=x;i<x+w;i++)px(a,i,j,c)}
function oval(a,x,y,rx,ry,c){for(let j=y-ry;j<=y+ry;j++)for(let i=x-rx;i<=x+rx;i++)if(((i-x)/rx)**2+((j-y)/ry)**2<=1)px(a,i,j,c)}
function line(a,x,y,u,v,c){let dx=Math.abs(u-x),sx=x<u?1:-1,dy=-Math.abs(v-y),sy=y<v?1:-1,e=dx+dy;while(1){px(a,x,y,c);if(x===u&&y===v)break;let q=2*e;if(q>=dy){e+=dy;x+=sx}if(q<=dx){e+=dx;y+=sy}}}
// Mirror side poses about the same foot anchor (x=12), not the canvas midpoint.
function left(a){const b=blank();for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(24-x<W)b.set(a.subarray((y*W+x)*4,(y*W+x+1)*4),(y*W+24-x)*4);return b}
function fox(dir,state,t){
 const a=blank(),walk=state==='walk',ready=state==='ready',straight=state==='straight',arc=state==='arc';
 const b=walk?[0,1,0,1][t]:(state==='idle'&&t?1:0),step=walk?[-2,0,2,0][t]:0,lean=straight?[-1,0,2,1][t]:0,turn=arc?[-1,0,1,1,0,-1][t]:0,x=12+lean+turn;
 // Tail, grounded boots, armor, face, arm, sword are independently drawn layers.
 oval(a,x+(dir==='side'?-5:5),18+b+turn,4,3,'ink');oval(a,x+(dir==='side'?-6:6),17+b+turn,3,2,'fur');px(a,x+(dir==='side'?-8:8),16+b+turn,'cream');
 box(a,x-5+step,21,4,4,'ink');box(a,x+1-step,21,4,4,'ink');box(a,x-4+step,22,2,2,'steel');box(a,x+2-step,22,2,2,'steel');box(a,x-6+step,24,5,2,'deep');box(a,x+1-step,24,5,2,'deep');
 oval(a,x,17+b,6,6,'ink');box(a,x-5,13+b,10,9,'deep');box(a,x-4,14+b,8,5,'steel');box(a,x-2,15+b,4,3,'shade');box(a,x-4,20+b,8,2,'rust');px(a,x,20+b,'gold');
 if(dir==='back'){
  box(a,x-4,9+b,8,5,'fur');box(a,x-6,5+b,4,6,'ink');box(a,x+2,5+b,4,6,'ink');box(a,x-5,6+b,2,4,'furhi');box(a,x+3,6+b,2,4,'furhi');box(a,x-3,11+b,6,2,'furhi');
 }else if(dir==='side'){
  box(a,x-5,5+b,7,9,'ink');box(a,x-4,6+b,7,7,'fur');box(a,x-5,3+b,3,5,'ink');box(a,x,4+b,3,5,'ink');box(a,x-4,4+b,1,4,'furhi');box(a,x+1,5+b,1,3,'furhi');box(a,x+1,10+b,4,3,'cream');px(a,x+5,11+b,'ink');px(a,x,9+b,'pale');px(a,x+1,9+b,'ink');
 }else{
  box(a,x-6,6+b,12,8,'ink');box(a,x-5,7+b,10,6,'fur');box(a,x-6,3+b,4,6,'ink');box(a,x+2,3+b,4,6,'ink');box(a,x-5,4+b,2,4,'furhi');box(a,x+3,4+b,2,4,'furhi');box(a,x-3,11+b,6,3,'cream');box(a,x-2,12+b,4,1,'pale');px(a,x-3,9+b,'ink');px(a,x+3,9+b,'ink');px(a,x,12+b,'ink');
 }
 box(a,x-4,13+b,8,2,'scarf');box(a,x+(dir==='side'?-5:3),14+b,2,4,'scarf');
 const arm=(ready||straight||arc)?14:16;box(a,x-7,arm+b,3,5,'ink');box(a,x-6,arm+1+b,2,3,'fur');box(a,x+4,arm+b,3,5,'ink');box(a,x+5,arm+1+b,2,3,'fur');
 if(ready){line(a,x+6,16+b,x+7,11+b,'gold');line(a,x+7,10+b,x+9,5+b,'silver');px(a,x+9,4+b,'pale')}
 if(straight){const q=[[x+7,13],[x+7,11],[x+5,10],[x+7,15]][t];line(a,x+5,17,q[0],q[1],'gold');line(a,q[0],q[1],q[0]+2,q[1]-3,'silver');px(a,q[0]+2,q[1]-3,'pale')}
 if(arc){const hand=[[x+7,10],[x+9,13],[x+8,19],[x-7,20],[x-9,13],[x-5,8]][t],tip=[[x+8,6],[x+10,11],[x+9,23],[x-9,23],[x-10,11],[x-7,5]][t];line(a,x+5,16,hand[0],hand[1],'gold');line(a,hand[0],hand[1],tip[0],tip[1],'silver');px(a,tip[0],tip[1],'pale')}
 return a;
}
function soldier(dir,state,t){
 const a=blank(),chase=state==='chase',hit=state==='hit',death=state==='death',b=chase?[0,1,0,1][t]:0,step=chase?[-2,0,2,0][t]:0,fall=death?[0,1,2,3][t]:0,x=12+(hit?(t?-1:1):0);
 if(death&&t>=2){oval(a,x,23,9,t===2?3:2,'ink');box(a,x-7,22,14,t===2?3:2,'enemyshade');box(a,x-4,21,5,2,'enemyhi');box(a,x+2,22,3,1,'silver');return a}
 box(a,x-5+step,21+fall,4,4-fall,'ink');box(a,x+1-step,21+fall,4,4-fall,'ink');box(a,x-4+step,22+fall,2,2,'enemy');box(a,x+2-step,22+fall,2,2,'enemy');box(a,x-6+step,24,5,2,'enemyshade');box(a,x+1-step,24,5,2,'enemyshade');
 oval(a,x,16+b+fall,6,6,'ink');box(a,x-5,13+b+fall,10,9,'enemyshade');box(a,x-4,14+b+fall,8,6,'enemy');box(a,x-3,15+b+fall,6,2,'enemyhi');box(a,x-1,17+b+fall,2,2,'gold');
 box(a,x-8,14+b+fall,4,6,'ink');box(a,x-7,15+b+fall,3,4,'steel');box(a,x+4,14+b+fall,4,5,'ink');box(a,x+5,15+b+fall,2,3,'enemyhi');
 if(dir==='back'){box(a,x-5,7+b+fall,10,7,'ink');box(a,x-4,8+b+fall,8,5,'enemy');box(a,x-4,6+b+fall,8,2,'steel');box(a,x-2,10+b+fall,4,2,'enemyshade')}
 else if(dir==='side'){box(a,x-5,7+b+fall,10,7,'ink');box(a,x-4,8+b+fall,8,5,'steel');box(a,x-5,6+b+fall,7,2,'enemyhi');box(a,x+1,9+b+fall,4,2,'visor');box(a,x+1,11+b+fall,4,2,'enemyshade')}
 else{box(a,x-6,7+b+fall,12,7,'ink');box(a,x-5,8+b+fall,10,5,'steel');box(a,x-5,6+b+fall,10,2,'enemyhi');box(a,x-4,9+b+fall,8,2,'visor');box(a,x-3,11+b+fall,6,2,'enemyshade')}
 if(hit){box(a,x-6,9+b+fall,12,2,'hit');px(a,x-8,8+fall,'hit');px(a,x+8,12+fall,'hit')}
 if(death&&t===1)box(a,x-5,10+fall,10,2,'blood');return a;
}
function crc(buf){let c=~0;for(const b of buf){c^=b;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(~c)>>>0}
function png(w,h,data){const sig=Buffer.from([137,80,78,71,13,10,26,10]);function chunk(t,d){const name=Buffer.from(t),n=Buffer.alloc(4),v=Buffer.alloc(4);n.writeUInt32BE(d.length);v.writeUInt32BE(crc(Buffer.concat([name,d])));return Buffer.concat([n,name,d,v])}const ih=Buffer.alloc(13);ih.writeUInt32BE(w);ih.writeUInt32BE(h,4);ih[8]=8;ih[9]=6;const raw=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)Buffer.from(data.subarray(y*w*4,(y+1)*w*4)).copy(raw,y*(w*4+1)+1);return Buffer.concat([sig,chunk('IHDR',ih),chunk('IDAT',zlib.deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))])}
const anim={fox:[['idle',2,200],['walk',4,95],['ready',2,120],['straight',4,65],['arc',6,55]],soldier:[['idle',2,240],['chase',4,135],['hit',2,50],['death',4,65]]},dirs=['front','side','back','left'];
function sheet(kind){const entries=[];for(const d of dirs)for(const [name,count,ms]of anim[kind])for(let i=0;i<count;i++){const drawdir=d==='left'?'side':d;const base=kind==='fox'?fox(drawdir,name,i):soldier(drawdir,name,i);entries.push({animation:name,direction:d,frame:i,duration_ms:ms,pixels:d==='left'?left(base):base})}
 const w=C*W,h=Math.ceil(entries.length/C)*H,a=new Uint8Array(w*h*4),meta=[];
 entries.forEach((f,n)=>{const x=n%C*W,y=Math.floor(n/C)*H;for(let j=0;j<H;j++)for(let i=0;i<W;i++)a.set(f.pixels.subarray((j*W+i)*4,(j*W+i+1)*4),((y+j)*w+x+i)*4);meta.push({animation:f.animation,direction:f.direction,frame:f.frame,duration_ms:f.duration_ms,rect:[x,y,W,H],foot_anchor:[12,25]})});
 const big=new Uint8Array(w*S*h*S*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++)for(let v=0;v<S;v++)for(let u=0;u<S;u++)big.set(a.subarray((y*w+x)*4,(y*w+x+1)*4),((y*S+v)*w*S+x*S+u)*4);
 fs.writeFileSync(path.join(__dirname,kind+'_native.png'),png(w,h,a));fs.writeFileSync(path.join(__dirname,kind+'_world2x.png'),png(w*S,h*S,big));return{native_size:[w,h],world_size:[w*S,h*S],frames:meta};}
const manifest={schema:'foxknight.pixel_character.v1',native_frame:[W,H],native_to_world:S,foot_anchor_native:[12,25],directions:dirs,palette,fox:sheet('fox'),soldier:sheet('soldier')};fs.writeFileSync(path.join(__dirname,'frames.json'),JSON.stringify(manifest,null,2)+'\n');console.log(`Built ${manifest.fox.frames.length} fox and ${manifest.soldier.frames.length} soldier frames.`);
