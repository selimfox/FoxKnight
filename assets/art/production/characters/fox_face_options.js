// Static, reversible FoxKnight fox-face exploration only.
// Native 32x36 integer pixels -> exact 2x world view. No formal atlas changes.
// Inspired by user-approved cute fox structure; no referenced image pixels used.
const fs=require('fs'),path=require('path');
const pixel=require('./fox_silhouette_study.js');
const W=32,H=36;
const COLORS={
 ink:'#302333',deep:'#6e332f',shade:'#ad4e32',orange:'#ee7b3a',light:'#ffa052',
 darkEar:'#4a2a34',ear:'#f3c5a1',cream:'#fff0d1',creamShade:'#e6d4b9',
 eye:'#31262b',iris:'#754633',shine:'#fff9de',nose:'#3b292c',pink:'#e98b87',
 scarf:'#963a48',scarfHi:'#c45957',steel:'#82919a',steelHi:'#c5c9bd',
 cloth:'#363849',gold:'#e6ba73'};
const rgba=Object.fromEntries(Object.entries(COLORS).map(([name,hex])=>[name,[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16)).concat(255)]));
function make(){return pixel.canvas(W,H)}
function dot(a,x,y,key){if(x<0||y<0||x>=a.w||y>=a.h)return;a.data.set(rgba[key],(y*a.w+x)*4)}
function h(a,x,y,n,key){for(let i=0;i<n;i++)dot(a,x+i,y,key)}
function rect(a,x,y,w,ht,key){for(let j=0;j<ht;j++)h(a,x,y+j,w,key)}
function ellipse(a,cx,cy,rx,ry,key){for(let y=cy-ry;y<=cy+ry;y++)for(let x=cx-rx;x<=cx+rx;x++)if(((x-cx)/rx)**2+((y-cy)/ry)**2<=1)dot(a,x,y,key)}
function stroke(a,coords,key){for(const [x,y] of coords)dot(a,x,y,key)}
function merge(dst,src,x,y){for(let j=0;j<src.h;j++)for(let i=0;i<src.w;i++){const n=(j*src.w+i)*4;if(src.data[n+3])dst.data.set(src.data.subarray(n,n+4),((y+j)*dst.w+x+i)*4)}}

function ear(a,left,tip,high,spread){
 for(let y=tip;y<=tip+high;y++){
  const f=(y-tip)/high,half=Math.max(0,Math.floor(f*spread));
  const cx=left?8-Math.floor(f*1.5):23+Math.floor(f*1.5);
  h(a,cx-half,y,2+half*2,'ink');
  if(y>tip+1)h(a,cx-half+1,y,Math.max(1,half*2),'darkEar');
  if(y>tip+3&&y<tip+high-1)h(a,cx-half+2,y,Math.max(1,half*2-2),'ear');
 }
}
function tail(a,side,up){
 if(side){
  for(let y=22+up;y<=31+up;y++){
   const len=[5,8,10,12,13,12,11,9,7,4][y-22-up];
   h(a,Math.max(0,13-len),y,len,'ink');
   h(a,Math.max(0,13-len)+1,y,Math.max(1,len-2),y>27+up?'cream':'orange');
   if(y>=25+up&&y<=29+up)h(a,Math.max(0,13-len)+2,y,Math.max(1,Math.floor(len/3)),'cream');
  }
 }else{
  for(let y=22+up;y<=31+up;y++){
   const len=[4,7,9,10,11,10,9,7,6,3][y-22-up];
   h(a,21,y,len,'ink');h(a,22,y,Math.max(1,len-2),y>27+up?'cream':'orange');
   if(y>=24+up&&y<=28+up)h(a,23+Math.floor(len*0.55),y,Math.max(1,len-Math.floor(len*0.55)-2),'cream');
  }
 }
}
function knight(a,side,variant){
 tail(a,side,0);
 // Long ears and cheeks stay the identity; armor is deliberately a small accent.
 rect(a,12,27,4,6,'cloth');rect(a,18,27,4,6,'cloth');
 rect(a,11,32,6,2,'ink');rect(a,17,32,6,2,'ink');
 ellipse(a,16,25,8,6,'ink');ellipse(a,16,25,7,5,'scarf');
 rect(a,10,22,12,3,'scarf');h(a,12,22,9,'scarfHi');
 if(variant===1){
  // Softer little knight: shoulder guards + narrow chest badge, not a metal box.
  rect(a,11,25,10,5,'cream');
  rect(a,13,25,6,3,'steel');h(a,14,25,4,'steelHi');
  dot(a,16,26,'gold');h(a,14,29,5,'scarf');
  h(a,9,24,3,'steelHi');h(a,22,24,3,'steelHi');
 }else{
  rect(a,11,25,10,5,'steel');rect(a,12,25,8,2,'steelHi');
  dot(a,16,27,'gold');h(a,15,28,3,'cloth');
 }
 rect(a,8,23,3,6,'ink');rect(a,9,24,2,4,'scarf');
 rect(a,22,23,3,6,'ink');rect(a,22,24,2,4,'scarf');
 // Tiny sheathed blade, not a dominant silhouette or attack preview.
 h(a,24,29,2,'gold');dot(a,26,30,'steelHi');dot(a,27,31,'steel');
}
function cheeks(a,wide,lower){
 // Two separate white lobes taper inward into a small central jaw, not a bar.
 const left=wide?3:4,right=wide?28:27;
 ellipse(a,9,17,wide?6:5,3,'cream');
 ellipse(a,23,17,wide?6:5,3,'cream');
 ellipse(a,16,19,lower?9:8,3,'cream');
 h(a,left,16,2,'cream');h(a,right-1,16,2,'cream');
 h(a,8,20,4,'creamShade');h(a,21,20,4,'creamShade');
}
function front(variant){
 const a=make(),v=variant;
 knight(a,false,v);
 ear(a,true,v===2?0:1,v===2?11:9,v===2?5:4);
 ear(a,false,v===2?0:1,v===2?11:9,v===2?5:4);
 ellipse(a,16,14,v===2?11:12,8,'ink');ellipse(a,16,13,v===2?10:11,7,'orange');
 ellipse(a,15,11,8,4,'light');
 // Cheek tufts interrupt the orange circumference asymmetrically.
 h(a,2,16,4,'ink');h(a,26,16,4,'ink');
 cheeks(a,v!==0,v===1);
 if(v===1){
  stroke(a,[[8,13],[9,12],[10,12],[11,13],[12,13],[20,13],[21,12],[22,12],[23,13],[24,13]],'eye');
  dot(a,7,17,'pink');h(a,8,18,2,'pink');h(a,23,18,2,'pink');dot(a,25,17,'pink');
 }else{
  rect(a,9,12,4,4,'eye');rect(a,20,12,4,4,'eye');
  rect(a,10,12,2,3,'iris');rect(a,21,12,2,3,'iris');
  dot(a,10,12,'shine');dot(a,21,12,'shine');
  if(v===2){dot(a,6,18,'pink');dot(a,26,18,'pink')}
 }
 h(a,15,17,3,'nose');dot(a,16,18,'nose');
 if(v===1)stroke(a,[[14,19],[13,19],[12,18],[18,19],[19,19],[20,18]],'deep');
 else stroke(a,[[15,19],[14,20],[13,20],[18,20],[19,20]],'deep');
 return a;
}
function side(variant){
 const a=make(),v=variant;
 knight(a,true,v);
 // Two ears at different depths and one rounded crown.
 ear(a,true,v===2?1:3,v===2?9:7,3);
 ear(a,false,v===2?0:1,v===2?11:9,4);
 ellipse(a,16,14,v===2?10:11,8,'ink');ellipse(a,17,13,v===2?9:10,7,'orange');
 ellipse(a,16,11,6,4,'light');
 // Short domed muzzle hand-placed row by row: it rounds forward rather than
 // reading as a horizontal white stripe or a long pointed weasel snout.
 [[22,5],[21,8],[19,11],[18,12],[19,10],[21,7]].forEach(([x,w],i)=>h(a,x,15+i,w,'ink'));
 [[23,3],[22,6],[20,9],[19,10],[20,8],[22,5]].forEach(([x,w],i)=>h(a,x,15+i,w,'cream'));
 ellipse(a,17,19,6,3,'cream');
 h(a,10,18,5,'cream');h(a,11,20,4,'creamShade');
 if(v===1){stroke(a,[[19,13],[20,12],[21,12],[22,13],[23,13]],'eye');h(a,18,18,2,'pink')}
 else{rect(a,19,12,4,4,'eye');rect(a,20,12,2,3,'iris');dot(a,20,12,'shine');if(v===2)dot(a,18,17,'pink')}
 h(a,28,17,2,'nose');dot(a,29,18,'nose');
 stroke(a,[[27,19],[26,20],[25,20]],'deep');
 return a;
}
const variants=[
 {id:'A_round_open',label:'round open eyes'},
 {id:'B_smile_cheeks',label:'smiling curved eyes and plump cheeks'},
 {id:'C_tall_ears',label:'tall ears and narrower crown'}
];
const native=pixel.canvas(6*W,H),world=pixel.canvas(6*W*2,H*2),review=pixel.canvas(6*W*4,H*4);
for(let n=0;n<variants.length;n++){
 const f=front(n),s=side(n),entry=variants[n];
 merge(native,f,(n*2)*W,0);merge(native,s,(n*2+1)*W,0);
 merge(world,pixel.scale(f,2),(n*2)*W*2,0);merge(world,pixel.scale(s,2),(n*2+1)*W*2,0);
 merge(review,pixel.scale(f,4),(n*2)*W*4,0);merge(review,pixel.scale(s,4),(n*2+1)*W*4,0);
 fs.writeFileSync(path.join(__dirname,`fox_option_${entry.id}_front_native.png`),pixel.png(f));
 fs.writeFileSync(path.join(__dirname,`fox_option_${entry.id}_side_native.png`),pixel.png(s));
}
fs.writeFileSync(path.join(__dirname,'fox_face_options_native.png'),pixel.png(native));
fs.writeFileSync(path.join(__dirname,'fox_face_options_world2x.png'),pixel.png(world));
fs.writeFileSync(path.join(__dirname,'fox_face_options_review4x.png'),pixel.png(review));
console.log('Built 3 static face variants, front/side, native 32x36 and exact 2x world preview. Formal atlas untouched.');
