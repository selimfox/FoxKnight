// FoxKnight formal character candidate: every cel is authored on a 32x36
// integer pixel grid. No AI downsampling, smoothing, rotations or filters.
// The approved static round fox study supplies only the fixed head silhouette;
// bodies, limbs, tails, weapons and soldier are independently drawn per pose.
const fs=require('fs'),path=require('path');
const study=require('./fox_silhouette_study.js');
const W=32,H=36,SCALE=2,COLS=8,ANCHOR=[16,33];
const palette={...study.palette,
  D:'#242435',U:'#46475b',S:'#718092',L:'#bcc2b6',F:'#da7440',T:'#f8e6b8',
  V:'#51414e',v:'#746276',Q:'#a18da0',M:'#d4c9b3',N:'#95b9bf',J:'#f8df9c',
  Z:'#b7554c'};
const rgba=Object.fromEntries(Object.entries(palette).map(([key,hex])=>[key,[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16)).concat(255)]));
const make=()=>study.canvas(W,H);
function px(a,x,y,key){if(x<0||y<0||x>=W||y>=H||!rgba[key])return;a.data.set(rgba[key],(y*W+x)*4)}
function rect(a,x,y,w,h,key){for(let j=0;j<h;j++)for(let i=0;i<w;i++)px(a,x+i,y+j,key)}
function rows(a,x,y,arr){for(let j=0;j<arr.length;j++)for(let i=0;i<arr[j].length;i++)if(arr[j][i]!=='.')px(a,x+i,y+j,arr[j][i])}
function line(a,x,y,u,v,key){let dx=Math.abs(u-x),dy=-Math.abs(v-y),sx=x<u?1:-1,sy=y<v?1:-1,e=dx+dy;for(;;){px(a,x,y,key);if(x===u&&y===v)break;const q=e*2;if(q>=dy){e+=dy;x+=sx}if(q<=dx){e+=dx;y+=sy}}}
function stamp(dst,src,ox,oy,top=0,bottom=H){for(let y=top;y<bottom;y++)for(let x=0;x<src.w;x++){const si=(y*src.w+x)*4;if(src.data[si+3]){const dx=x+ox,dy=y+oy;if(dx>=0&&dy>=0&&dx<dst.w&&dy<dst.h)dst.data.set(src.data.subarray(si,si+4),(dy*dst.w+dx)*4)}}}
function mirror(a){const b=make();for(let y=0;y<H;y++)for(let x=0;x<W;x++)b.data.set(a.data.subarray((y*W+x)*4,(y*W+x+1)*4),(y*W+(W-1-x))*4);return b}

function foxTail(a,dir,bob,swing){
 if(dir==='side'){
  rows(a,1,21+bob+swing,[
   '.....XXXXXX','...XXOOOOOWX','..XOOOOOOWWX','.XOOOOOOWWWX',
   'XOOOOOOWWWWX','XOOOOOWWWWWX','XOOOWWWWWWWX','.XOWWWWWWWX',
   '..XWWWWWWWX','...XXXXXXXX']);
 }else{
  const x=dir==='back'?21:21;
  rows(a,x,21+bob+swing,[
   '......XXXXX','...XXXOOOOWX','..XOOOOOOWWX','.XOOOOOOWWWX',
   'XOOOOOOWWWWX','XOOOOOWWWWWX','.XOOOWWWWWX','..XOWWWWWWX',
   '...XWWWWWX','....XXXXXX']);
 }
}
function foxLegs(a,pose){
 // Four contact poses: left plant, left lift, right plant, right lift.
 const l=[[-3,0],[0,-1],[2,-2],[0,-1]][pose],r=[[3,-2],[0,-1],[-3,0],[0,-1]][pose];
 rows(a,10+l[0],29+l[1],['.DDDD.','DSSSSD','DSSSSD','DUUUDD','DDDDDD']);
 rows(a,17+r[0],29+r[1],['.DDDD.','DSSSSD','DSSSSD','DUUUDD','DDDDDD']);
 // Native-pixel knees remain attached to the tunic when a boot is raised.
 rows(a,11+l[0],27+l[1],['DSSD','DSSD']);
 rows(a,18+r[0],27+r[1],['DSSD','DSSD']);
}
function foxBody(a,dir,bob,gesture,pose){
 // Broad burgundy tabard and compact chest plate keep the knight readable.
 rows(a,9,20+bob,['...XXXXXRRXXXXX...','..XRRRRRRRRRRRX..','.XRRRRRRRRRRRRRX.','XRRRDUUSS UUDRRRX'.replaceAll(' ',''),
  'XRRDSSLLLSSDRRRX','XRRDSSJJJSSDRRRX','XRRRDUUSS UUDRRRX'.replaceAll(' ',''),'.XRRRRRRRRRRRRRX.','..XRRRRRRRRRRRX..']);
 const lead=gesture==='ready'?-2:gesture==='arc'&&pose>2?2:0;
 const leftSwing=gesture==='walk'?[2,0,-2,0][pose]:0;
 const rightSwing=gesture==='walk'?[-2,0,2,0][pose]:0;
 rows(a,7+lead,22+bob+leftSwing,['.DDDD','DRRRD','DRRRD','DFFFD','DDDDD']);
 rows(a,21+lead,22+bob+rightSwing,['DDDD.','DRRRD','DRRRD','DFFFD','DDDDD']);
 if(dir==='back'){
  rows(a,13,23+bob,['DUUDD','DSSSD','DSSSD','DUDDD']);
 }else{
  rows(a,13,23+bob,['.DLLD.','DLLLLD','DLS SLD'.replace(' ',''),'DLLLLD','.DDDD.']);
 }
}
function foxBackHead(){const a=make();rows(a,2,2,[
 '......XX............XX......','.....XOOX..........XOOX.....',
 '....XOWOX........XOWOX....','...XOOOOX........XOOOOX...',
 '....XOOOOOOOOOOOOOOOOOOX....','...XOOOOOOOOOOOOOOOOOOOOX...',
 '..XOOOOOOOOOOOOOOOOOOOOOOX..','.XOOOOOOOOOOOOOOOOOOOOOOOOX.',
 'XHOOOOOOOOOOOOOOOOOOOOOOOOHX','XOOOOOOOOOOOOOOOOOOOOOOOOOOX',
 'XOOOOOOOOOOOOOOOOOOOOOOOOOOX','XOOOOOOOOOOOOOOOOOOOOOOOOOOX',
 'XOOOOOOOOOOOOOOOOOOOOOOOOOOX','XOOOOOOOOOOOOOOOOOOOOOOOOOOX',
 'XOOOOOOOOOOOOOOOOOOOOOOOOOOX','.XOOOOOOOOOOOOOOOOOOOOOOOOX.',
 '..XOOOOOOOOOOOOOOOOOOOOOOX..','....XOOOOOOOOOOOOOOOOOOX....',
 '......XXXXXXXXXXXXXX......']);
 rows(a,7,10,['..o........o..','.o..........o.','o............o']);
 return a}
const foxHeads={front:study.roundFront(),side:study.roundSide(),back:foxBackHead()};
function foxSword(a,state,frame,dir,bob){
 if(state==='idle'||state==='walk'){
  line(a,25,25+bob,27,31+bob,'G');line(a,27,30+bob,29,32+bob,'L');return;
 }
 const paths=state==='ready'?
  [[[25,23],[27,17],[29,11]],[[25,22],[27,15],[29,8]]]:
 state==='straight'?
  [[[25,23],[27,17],[28,10]],[[25,21],[28,14],[30,6]],[[24,22],[28,18],[31,13]],[[25,23],[27,19],[29,15]]]:
  [[[25,22],[28,16],[29,9]],[[24,23],[28,21],[31,19]],[[23,25],[24,29],[25,33]],[[12,24],[6,27],[2,29]],[[12,22],[5,20],[1,18]],[[13,21],[8,15],[5,9]]];
 const [[hx,hy],[mx,my],[tx,ty]]=paths[Math.min(frame,paths.length-1)];
 line(a,hx,hy,mx,my,'G');line(a,mx,my,tx,ty,'L');px(a,tx,ty,'C');px(a,tx-1,ty,'C');
}
function foxCel(dir,state,frame){
 const a=make(),upper=make(),walk=state==='walk',bob=walk?[0,-1,0,-1][frame]:state==='idle'?[0,-1][frame]:0;
 const pose=walk?frame:0,tailSwing=walk?[1,-2,2,0][frame]:state==='arc'?[0,0,-1,-2,-1,0][frame]:0;
 const sway=walk?[-1,0,1,0][frame]:state==='straight'?[-1,0,2,1][frame]:state==='arc'?[-1,0,1,1,0,-1][frame]:0;
 const drawDir=dir==='left'?'side':dir;
 foxLegs(a,pose);
 foxTail(upper,drawDir,bob,tailSwing);
 foxBody(upper,drawDir,bob,state,pose);
 stamp(upper,foxHeads[drawDir],0,bob,2,21);
 if(state==='straight'){
  // Understated scarf motion gives a visible acceleration and follow-through.
  rows(upper,8-frame%2,20+bob,['RRRR','RRR.','RR..']);
 }else if(state==='arc'){
  rows(upper,7+frame%3,19+bob,['.RRR','RRR.','RR..']);
 }
 foxSword(upper,state,frame,drawDir,bob);
 stamp(a,upper,sway,0);
 return dir==='left'?mirror(a):a;
}

function soldierTail(a,dir,bob){
 // The enemy is armored and intentionally has no fox-like tail.
 if(dir==='back')rows(a,10,22+bob,['.VVVVVVVVVVVV.','VvvvvvvvvvvvvV','VvvvvvvvvvvvvV']);
}
function soldierLegs(a,pose,fall=0){
 const l=[[-3,0],[0,-1],[2,-2],[0,-1]][pose],r=[[3,-2],[0,-1],[-3,0],[0,-1]][pose];
 rows(a,10+l[0],29+l[1]+fall,['.DDDD.','DvvvvD','DvvvvD','DUUUUD','DDDDDD']);
 rows(a,18+r[0],29+r[1]+fall,['.DDDD.','DvvvvD','DvvvvD','DUUUUD','DDDDDD']);
 rows(a,11+l[0],27+l[1]+fall,['DvvD','DvvD']);
 rows(a,19+r[0],27+r[1]+fall,['DvvD','DvvD']);
}
function soldierCel(dir,state,frame){
 const a=make(),chase=state==='chase',bob=chase?[0,-1,0,-1][frame]:state==='idle'?[0,-1][frame]:0;
 const actual=dir==='left'?'side':dir;
 if(state==='death'&&frame>=2){
  rows(a,3,28,['....DDDDDDDDDDDDDDDD....','..DDvvvvvvvvvvvvvvDD..','.DDvvvvvQQvvvvvvvvvDD.','DDDDDDDDDDDDDDDDDDDDDD','..ZZZ.....MM.....ZZZ..']);
  if(frame===3)rows(a,8,30,['DDDDDDDDDDDD','DvvvvvvvvvvD','DDDDDDDDDDDD']);
  return dir==='left'?mirror(a):a;
 }
 soldierLegs(a,chase?frame:0,state==='death'?frame:0);
 soldierTail(a,actual,bob);
 rows(a,9,20+bob,['..DDDDDDDDDD..','.DVvvvvvvvvVD.','DVvvUUUUUUvvVD','DVvUL L L LUvVD'.replaceAll(' ',''),
  'DVvULLMM LLUvVD'.replaceAll(' ',''),'DVvULLMM LLUvVD'.replaceAll(' ',''),'DVvvUUUUUUvvVD','.DVvvvvvvvvVD.','..DDDDDDDDDD..']);
 const leftSwing=chase?[2,0,-2,0][frame]:0,rightSwing=chase?[-2,0,2,0][frame]:0;
 rows(a,7,21+bob+leftSwing,['.DDDD','DvQvD','DvQvD','DVVVD','DDDDD']);
 rows(a,22,21+bob+rightSwing,['DDDD.','DvQvD','DvQvD','DVVVD','DDDDD']);
 if(actual==='front'){
  rows(a,7,6+bob,[
   '.....DDDDDDDD.....','...DDQQQQQQQQDD...','..DQvvvvvvvvvvQD..',
   '.DQvvvvvvvvvvvvQD.','DQvUUUUUUUUUUvQD','DQvUNNNNNNNNUvQD',
   'DQvUNNNNNNNNUvQD','DQvUUUUUUUUUUvQD','.DQvvvvvvvvvvvvQD.',
   '..DQvvvvvvvvvvQD..','...DDQQQQQQQQDD...','.....DDDDDDDD.....']);
  rows(a,13,17+bob,['..MM..','.MMMM.']);
 }else if(actual==='side'){
  rows(a,8,6+bob,[
   '....DDDDDDDD......','..DDQQQQQQQQDD....','.DQvvvvvvvvvvQD...',
   'DQvvvvvvvvvvvvQD..','DQvUUUUUUUUUUvQD.','DQvUUUUUUNNNNvQD.',
   'DQvUUUUUUNNNNvQD.','DQvUUUUUUUUUUvQD.','.DQvvvvvvvvvvQD...',
   '..DQvvvvvvvvQD....','...DDQQQQQDD......','.....DDDDD........']);
 }else{
  rows(a,7,6+bob,[
   '.....DDDDDDDD.....','...DDQQQQQQQQDD...','..DQvvvvvvvvvvQD..',
   '.DQvvvvvvvvvvvvQD.','DQvUUUUUUUUUUvQD','DQvUUUUUUUUUUvQD',
   'DQvUUUUUUUUUUvQD','DQvUUUUUUUUUUvQD','.DQvvvvvvvvvvvvQD.',
   '..DQvvvvvvvvvvQD..','...DDQQQQQQQQDD...','.....DDDDDDDD.....']);
 }
 // Plume is two asymmetric clusters and deliberately stays on the helmet.
 rows(a,13,3+bob,['.DDDD.','DQQQQD','DQvvQD']);
 if(state==='hit'){
  rows(a,5,13+bob,['.JJ......JJ','JJ........JJ','J..........J']);
  if(frame===1)rows(a,11,19+bob,['J......J','.J....J']);
 }
 if(state==='death'&&frame===1)rows(a,9,21,['...ZZZZZZ...','..ZZZZZZZZ..']);
 return dir==='left'?mirror(a):a;
}

const dirs=['front','side','back','left'];
const animations={fox:[['idle',2,220],['walk',4,105],['ready',2,140],['straight',4,70],['arc',6,60]],
 soldier:[['idle',2,260],['chase',4,125],['hit',2,80],['death',4,85]]};
function sheet(kind){
 const frames=[];
 for(const dir of dirs)for(const [animation,count,duration_ms] of animations[kind])for(let frame=0;frame<count;frame++)
  frames.push({animation,direction:dir,frame,duration_ms,pixels:kind==='fox'?foxCel(dir,animation,frame):soldierCel(dir,animation,frame)});
 const width=COLS*W,height=Math.ceil(frames.length/COLS)*H,sheet=study.canvas(width,height),metadata=[];
 frames.forEach((entry,index)=>{const x=(index%COLS)*W,y=Math.floor(index/COLS)*H;
  stamp(sheet,entry.pixels,x,y);
  metadata.push({animation:entry.animation,direction:entry.direction,frame:entry.frame,duration_ms:entry.duration_ms,rect:[x,y,W,H],foot_anchor:ANCHOR});
 });
 fs.writeFileSync(path.join(__dirname,kind+'_native.png'),study.png(sheet));
 const world=study.scale(sheet,SCALE);
 fs.writeFileSync(path.join(__dirname,kind+'_world2x.png'),study.png(world));
 return{native_size:[width,height],world_size:[world.w,world.h],frames:metadata};
}
const manifest={schema:'foxknight.pixel_character.v1',native_frame:[W,H],native_to_world:SCALE,
 foot_anchor_native:ANCHOR,directions:dirs,palette,fox:sheet('fox'),soldier:sheet('soldier')};
fs.writeFileSync(path.join(__dirname,'frames.json'),JSON.stringify(manifest,null,2)+'\n');
const REVIEW_SCALE=4,preview=study.canvas(8*W*REVIEW_SCALE,5*H*REVIEW_SCALE);
const picks=[['fox','front','idle',0],['fox','front','walk',0],['fox','front','walk',1],['fox','front','walk',2],
 ['fox','front','walk',3],['fox','side','ready',1],['fox','side','straight',2],['fox','side','arc',3],
 ['soldier','front','idle',0],['soldier','front','chase',0],['soldier','front','chase',1],['soldier','front','chase',2],
 ['soldier','front','chase',3],['soldier','side','hit',0],['soldier','side','death',1],['soldier','side','death',3],
 ['fox','side','idle',0],['fox','side','walk',0],['fox','side','walk',1],['fox','side','walk',2],
 ['fox','side','walk',3],['fox','back','idle',0],['fox','left','idle',0],['soldier','back','idle',0]];
for(let i=0;i<picks.length;i++){const [kind,dir,animation,frame]=picks[i];
 const cel=kind==='fox'?foxCel(dir,animation,frame):soldierCel(dir,animation,frame);
 study.merge(preview,study.scale(cel,REVIEW_SCALE),(i%8)*W*REVIEW_SCALE,Math.floor(i/8)*H*REVIEW_SCALE);
}
fs.writeFileSync(path.join(__dirname,'character_contact_4x.png'),study.png(preview));
console.log(`Built ${manifest.fox.frames.length} fox and ${manifest.soldier.frames.length} soldier native-grid cels (32x36, 2x export).`);
