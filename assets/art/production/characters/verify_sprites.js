// Run `node verify_sprites.js` after building. Uses Node built-ins only.
const fs=require('fs'),zlib=require('zlib'),path=require('path'),assert=require('assert');
const root=__dirname,m=JSON.parse(fs.readFileSync(path.join(root,'frames.json')));
function load(name){const b=fs.readFileSync(path.join(root,name)),sig=Buffer.from([137,80,78,71,13,10,26,10]);assert(b.subarray(0,8).equals(sig));let w=0,h=0,ids=[];for(let p=8;p<b.length;){const len=b.readUInt32BE(p),kind=b.toString('ascii',p+4,p+8),d=b.subarray(p+8,p+8+len);if(kind==='IHDR'){w=d.readUInt32BE(0);h=d.readUInt32BE(4);assert.equal(d[9],6)}if(kind==='IDAT')ids.push(d);p+=12+len}const raw=zlib.inflateSync(Buffer.concat(ids)),out=Buffer.alloc(w*h*4);for(let y=0;y<h;y++){assert.equal(raw[y*(w*4+1)],0,'PNG scanline must use filter 0');raw.copy(out,y*w*4,y*(w*4+1)+1,(y+1)*(w*4+1))}return{w,h,pixels:out}}
for(const kind of ['fox','soldier']){
 const n=load(kind+'_native.png'),b=load(kind+'_world2x.png'),meta=m[kind].frames;
 assert.deepEqual([n.w,n.h],m[kind].native_size);assert.deepEqual([b.w,b.h],m[kind].world_size);
 assert.equal(meta.length,kind==='fox'?72:48);assert.equal(b.w,n.w*2);assert.equal(b.h,n.h*2);
 for(const f of meta){const [x,y,w,h]=f.rect;assert.deepEqual([w,h],m.native_frame);assert.deepEqual(f.foot_anchor,m.foot_anchor_native);assert(x>=0&&y>=0&&x+w<=n.w&&y+h<=n.h);let marked=0;for(let j=0;j<h;j++)for(let i=0;i<w;i++){const alpha=n.pixels[((y+j)*n.w+x+i)*4+3];assert(alpha===0||alpha===255);if(alpha)marked++}assert(marked>8,`${kind} ${f.animation} ${f.direction} ${f.frame} empty`)}
 for(let y=0;y<n.h;y++)for(let x=0;x<n.w;x++)for(let v=0;v<2;v++)for(let u=0;u<2;u++){const src=(y*n.w+x)*4,dst=((y*2+v)*b.w+x*2+u)*4;assert(n.pixels.subarray(src,src+4).equals(b.pixels.subarray(dst,dst+4)))}
 // A walk cycle must contain distinct authored cels, not four copies of an idle pose.
 const locomotion=kind==='fox'?'walk':'chase';
 for(const direction of m.directions){
  const sequence=meta.filter(f=>f.animation===locomotion&&f.direction===direction);
  assert.equal(sequence.length,4);
  for(let i=0;i<4;i++){
   const first=sequence[i].rect,next=sequence[(i+1)%4].rect;
   let changed=0;
   for(let y=0;y<first[3];y++)for(let x=0;x<first[2];x++){
    const left=((first[1]+y)*n.w+first[0]+x)*4,right=((next[1]+y)*n.w+next[0]+x)*4;
    if(!n.pixels.subarray(left,left+4).equals(n.pixels.subarray(right,right+4)))changed++;
   }
   assert(changed>=20,`${kind} ${direction} ${locomotion} ${i}: too few altered native pixels (${changed})`);
  }
 }
 console.log(`${kind}: ${meta.length} frames, native ${n.w}x${n.h}, world ${b.w}x${b.h}, hard alpha and nearest 2x OK`);
}
