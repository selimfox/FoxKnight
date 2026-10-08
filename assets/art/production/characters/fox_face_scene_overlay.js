// Read-only scene-scale comparison. This does not edit level files or sprites.
// It overlays candidate 2x transparent cels on captured 960x540 screenshots.
const fs=require('fs'),path=require('path'),zlib=require('zlib');
const pixel=require('./fox_silhouette_study.js');
function decode(file){
 const b=fs.readFileSync(file),chunks=[];let w=0,h=0,color=0,depth=0;
 for(let p=8;p<b.length;){const n=b.readUInt32BE(p),type=b.toString('ascii',p+4,p+8),chunk=b.subarray(p+8,p+8+n);
  if(type==='IHDR'){w=chunk.readUInt32BE(0);h=chunk.readUInt32BE(4);depth=chunk[8];color=chunk[9]}
  if(type==='IDAT')chunks.push(chunk);p+=12+n;
 }
 if(depth!==8||![2,6].includes(color))throw new Error('Expected 8-bit RGB/RGBA PNG: '+file);
 const bpp=color===2?3:4,stride=w*bpp,raw=zlib.inflateSync(Buffer.concat(chunks));
 const unpack=new Uint8Array(stride*h),out=pixel.canvas(w,h);
 for(let y=0;y<h;y++){
  const filter=raw[y*(stride+1)],start=y*(stride+1)+1;
  for(let x=0;x<stride;x++){
   const a=x>=bpp?unpack[y*stride+x-bpp]:0,
    above=y?unpack[(y-1)*stride+x]:0,
    corner=y&&x>=bpp?unpack[(y-1)*stride+x-bpp]:0;
   let pred=0;
   if(filter===1)pred=a;else if(filter===2)pred=above;else if(filter===3)pred=Math.floor((a+above)/2);
   else if(filter===4){const p=a+above-corner,da=Math.abs(p-a),db=Math.abs(p-above),dc=Math.abs(p-corner);pred=da<=db&&da<=dc?a:db<=dc?above:corner}
   else if(filter!==0)throw new Error('PNG filter '+filter);
   unpack[y*stride+x]=(raw[start+x]+pred)&255;
  }
  for(let x=0;x<w;x++){const s=y*stride+x*bpp,d=(y*w+x)*4;
   out.data[d]=unpack[s];out.data[d+1]=unpack[s+1];out.data[d+2]=unpack[s+2];out.data[d+3]=bpp===4?unpack[s+3]:255;
  }
 }
 return out;
}
function overlay(dst,src,sx,sy,sw,sh,dx,dy){for(let y=0;y<sh;y++)for(let x=0;x<sw;x++){
 const from=((sy+y)*src.w+sx+x)*4,to=((dy+y)*dst.w+dx+x)*4;
 if(src.data[from+3])dst.data.set(src.data.subarray(from,from+4),to);
}}
const root=path.resolve(__dirname,'../../../..');
const sheet=decode(path.join(__dirname,'fox_face_options_world2x.png'));
for(const level of ['01','02','03']){
 const scene=decode(path.join(root,'output',`ui_production_level_${level}.png`));
 for(let n=0;n<3;n++){
  // Front row and side row: A, B, C from left to right at authentic game 2x.
  const cx=340+n*96;
  overlay(scene,sheet,n*128,0,64,72,cx-32,205);
  overlay(scene,sheet,n*128+64,0,64,72,cx-32,339);
 }
 fs.writeFileSync(path.join(__dirname,`fox_face_scene_level_${level}.png`),pixel.png(scene));
}
console.log('Created three 960x540 native-scale comparison overlays. Scenes and formal atlas unchanged.');
