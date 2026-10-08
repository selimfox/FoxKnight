// FoxKnight hand-authored integer-grid VFX. Run `node build_fx.js` in this directory.
const fs=require('fs'), path=require('path'), zlib=require('zlib');
const N=16,S=2,C=8;
const palette={ice:'#62cceb',iceLight:'#c5f5fb',iceDeep:'#3677a2',amber:'#ee9b3e',amberLight:'#ffe3a1',white:'#fff4d3',steel:'#8c9aaa',smoke:'#536070'};
const color=Object.fromEntries(Object.entries(palette).map(([k,h])=>[k,[1,3,5].map(i=>parseInt(h.slice(i,i+2),16)).concat(255)]));
const blank=()=>new Uint8Array(N*N*4);
function dot(a,x,y,c){if(x>=0&&x<N&&y>=0&&y<N)a.set(color[c],(y*N+x)*4)}
function line(a,x,y,u,v,c){let dx=Math.abs(u-x),sx=x<u?1:-1,dy=-Math.abs(v-y),sy=y<v?1:-1,e=dx+dy;while(true){dot(a,x,y,c);if(x===u&&y===v)break;let q=2*e;if(q>=dy){e+=dy;x+=sx}if(q<=dx){e+=dx;y+=sy}}}
function hit(f){const a=blank(),r=[3,6,7,5,3,1][f];for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,1],[1,-1],[-1,-1]]){const n=dx&&dy?Math.max(1,r-2):r;line(a,8+dx*2,8+dy*2,8+dx*n,8+dy*n,f<3?'white':'steel');if(f<3)dot(a,8+dx*n,8+dy*n,'white')}if(f<4)dot(a,8,8,'white');return a}
function straight(f){const a=blank(),n=[5,10,14,8][f],l=Math.floor((N-n)/2),r=l+n-1;line(a,l,8,r,8,'iceLight');line(a,l+1,9,r-1,9,'ice');if(f>0&&f<3)line(a,l+2,10,r-2,10,'iceDeep');dot(a,r,7,'white');return a}
function arc(f){const a=blank(),n=[3,5,7,4][f];for(let i=0;i<n;i++){const t=-2.1+i*.37+f*.14,x=Math.round(8+Math.cos(t)*6),y=Math.round(8+Math.sin(t)*6);dot(a,x,y,'amberLight');dot(a,x,y+1,'amber');if(i%2===0)dot(a,Math.round(8+Math.cos(t)*5),Math.round(8+Math.sin(t)*5),'white')}return a}
function switchFlash(f,cool){const a=blank(),r=[3,5,7,6][f];for(let i=0;i<12;i++){const t=i*Math.PI/6;dot(a,Math.round(8+Math.cos(t)*r),Math.round(8+Math.sin(t)*r),i%3?(cool?'ice':'amberLight'):'white')}return a}
function death(f){const a=blank(),n=[1,2,4,5,6,7][f];for(const [dx,dy] of [[-1,-1],[1,-1],[-1,1],[1,1],[-1,0],[1,0]])dot(a,8+dx*n,8+dy*n,f<3?'steel':'smoke');if(f<3)dot(a,8,8,'white');return a}
function crc(b){let c=~0;for(const v of b){c^=v;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(~c)>>>0}
function png(w,h,a){const sig=Buffer.from([137,80,78,71,13,10,26,10]);function ch(n,d){const k=Buffer.from(n),l=Buffer.alloc(4),s=Buffer.alloc(4);l.writeUInt32BE(d.length);s.writeUInt32BE(crc(Buffer.concat([k,d])));return Buffer.concat([l,k,d,s])}const ih=Buffer.alloc(13);ih.writeUInt32BE(w);ih.writeUInt32BE(h,4);ih[8]=8;ih[9]=6;const raw=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)Buffer.from(a.subarray(y*w*4,(y+1)*w*4)).copy(raw,y*(w*4+1)+1);return Buffer.concat([sig,ch('IHDR',ih),ch('IDAT',zlib.deflateSync(raw,{level:9})),ch('IEND',Buffer.alloc(0))])}
const groups=[['hit',6,hit],['straight',4,straight],['arc',4,arc],['switch_warm',4,f=>switchFlash(f,false)],['switch_cool',4,f=>switchFlash(f,true)],['death',6,death]], frames=[];
for(const [name,count,draw]of groups)for(let frame=0;frame<count;frame++)frames.push({name,frame,pixels:draw(frame)});
const w=C*N,h=Math.ceil(frames.length/C)*N,native=new Uint8Array(w*h*4),manifest=[];
frames.forEach((f,k)=>{const x=(k%C)*N,y=Math.floor(k/C)*N;for(let j=0;j<N;j++)for(let i=0;i<N;i++)native.set(f.pixels.subarray((j*N+i)*4,(j*N+i+1)*4),((y+j)*w+x+i)*4);const ms=f.name==='hit'?17:(f.name==='straight'||f.name==='arc'?55:45);manifest.push({name:f.name,frame:f.frame,rect:[x,y,N,N],duration_ms:ms})});
const world=new Uint8Array(w*S*h*S*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++)for(let v=0;v<S;v++)for(let u=0;u<S;u++)world.set(native.subarray((y*w+x)*4,(y*w+x+1)*4),((y*S+v)*w*S+x*S+u)*4);
fs.writeFileSync(path.join(__dirname,'fx_native.png'),png(w,h,native));fs.writeFileSync(path.join(__dirname,'fx_world2x.png'),png(w*S,h*S,world));fs.writeFileSync(path.join(__dirname,'frames.json'),JSON.stringify({schema:'foxknight.pixel_fx.v1',native_frame:[N,N],native_to_world:S,palette,frames:manifest},null,2)+'\n');console.log(`Built ${frames.length} VFX frames.`);
