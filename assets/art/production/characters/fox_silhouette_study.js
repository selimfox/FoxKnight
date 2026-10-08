// Two original low-resolution pixel-grid silhouette studies. No scaling,
// tracing, filters, AI pixels or anti-aliasing are used in either native cel.
// References: user-supplied fox-knight concept (shape only), not copied pixels.
const fs=require('fs'),path=require('path'),zlib=require('zlib');
const root=__dirname;
const palette={
  X:'#222233',o:'#a8492f',O:'#dd713b',H:'#f7a858',W:'#fff0c5',w:'#dfc99f',
  e:'#261f26',b:'#62453a',R:'#833c47',r:'#ba5c57',A:'#5d6875',B:'#9caab1',
  C:'#e4e5d4',G:'#e2bf74',K:'#3b3b4a',P:'#747d89'
};
const rgb=Object.fromEntries(Object.entries(palette).map(([k,c])=>[k,[1,3,5].map(i=>parseInt(c.slice(i,i+2),16)).concat(255)]));
function canvas(w,h){return{w,h,data:new Uint8Array(w*h*4)}}
function dot(a,x,y,c){if(x<0||y<0||x>=a.w||y>=a.h||!rgb[c])return;a.data.set(rgb[c],(y*a.w+x)*4)}
function rows(a,x,y,grid){for(let j=0;j<grid.length;j++)for(let i=0;i<grid[j].length;i++)if(grid[j][i]!=='.')dot(a,x+i,y+j,grid[j][i])}
function merge(dst,src,x,y){for(let j=0;j<src.h;j++)for(let i=0;i<src.w;i++){const k=(j*src.w+i)*4;if(src.data[k+3])dst.data.set(src.data.subarray(k,k+4),((y+j)*dst.w+x+i)*4)}}
function scale(src,n){const a=canvas(src.w*n,src.h*n);for(let y=0;y<src.h;y++)for(let x=0;x<src.w;x++)for(let j=0;j<n;j++)for(let i=0;i<n;i++)a.data.set(src.data.subarray((y*src.w+x)*4,(y*src.w+x+1)*4),((y*n+j)*a.w+x*n+i)*4);return a}

// A: 24x28, small and light; broad white mask and round cheeks occupy most of
// the head. The nose projects only two native pixels beyond the side cheek.
function smallFront(){const a=canvas(24,28);
 rows(a,16,15,['.XXOOOXX','XOOOOWWX','XOOOOWWX','XOOOWWWX','.XOWWWX','..XXXXX']);
 rows(a,6,14,['.XXRRRRXX.','XRRrrRrRRX','XAABCCBAAX','XABBGGBBAX','XAAABBAAAX','.XARRRAX..','.XKKKKX...']);
 rows(a,4,16,['XX','AX','AX','oX','XX']);rows(a,18,16,['XX','XA','XA','Xo','XX']);
 rows(a,7,21,['XXAAX','XAAAX','XKKKX','XXXXXX']);rows(a,13,21,['XAAX','XAAX','XKKX','XXXXX']);
 rows(a,3,2,[
  '..XX........XX..','.XOOX......XOOX.','.XOWOX....XOWOX.','.XOOOXXXXXXOOOX.',
  'XOOOOOOOOOOOOOOX','XHOOOOOOOOOOOOHX','XOOOeWOOOOWeOOOX','XOOOeWOOOOWeOOOX',
  'XOOOWWWWWWWOOOX','XWWWWWWWWWWWWWWX','XWWWWWWeWWWWWWX','.XWWWWWXWWWWWX.','..XWWWWWWWWX...','...XXXXXXXX....'
 ]);
 rows(a,10,12,['..e..','..X..']);return a;
}
function smallSide(){const a=canvas(24,28);
 rows(a,0,16,['..XXXXXX','XOOOOWWX','XOOOOWWX','XOOOWWWX','XOWWWWWX','.XXXXXXX']);
 rows(a,7,14,['.XXRRRRXX.','XRRrrRrRRX','XAABCCBAAX','XABBGGBBAX','XAAABBAAAX','.XARRRAX..','.XKKKKX...']);
 rows(a,6,16,['XX','AX','AX','oX','XX']);rows(a,18,16,['XX','XA','XA','Xo','XX']);
 rows(a,8,21,['XXAAX','XAAAX','XKKKX','XXXXXX']);rows(a,14,21,['XAAX','XAAX','XKKX','XXXXX']);
 rows(a,5,2,[
  '..XX....XX.....','.XOOX..XOOX....','.XOWOXXOWOX....','.XOOOOOOOOOX....',
  'XOOOOOOOOOOOX...','XHOOOOOOOOOOX...','XOOOeWOOOOOOOX..','XOOOeWOOOOOOOX..',
  'XOOOOOWWWWWWWX..','.XOOOWWWWWWWWWX.','..XOWWWWWWeWWX.','...XWWWWWWXWWX..','....XWWWWWWX...','.....XXXXXXX....'
 ]);return a;
}
// B: independently redrawn on a 32x36 canvas. Larger round head and tail;
// shorter proportion of visible armor. The change is deliberate, not A scaled.
function bigFront(){const a=canvas(32,36);
 // The broad tail is a separate mass behind the light breastplate.
 rows(a,20,20,['...XXXXXX','XXOOOOOWWX','XOOOOOWWWX','XOOOOWWWWX','XOOOWWWWWX','XOOOWWWWWX','.XOWWWWWX','..XWWWWWX','...XXXXXX']);
 rows(a,10,21,['.XXRRRRXX.','XRRrrrrRRX','XAABCCBAAX','XAABGGB AAX'.replace(' ',''),'XAAABBAAAX','.XARRR RAX'.replace(' ',''),'..XKKKKX..']);
 rows(a,8,23,['XX','AX','AX','oX','XX']);rows(a,22,23,['XX','XA','XA','Xo','XX']);
 rows(a,10,29,['XAAAX','XAAAX','XKKKX','XXXXXX']);rows(a,17,29,['XAAAX','XAAAX','XKKKX','XXXXXX']);
 rows(a,3,3,[
  '....XXXXX........XXXXX....',
  '...XOOOXX........XXOOOX...',
  '...XOWWOX........XOWWOX...',
  '..XOOOOOXXXXXXXXOOOOOX..',
  '.XOOOOOOOOOOOOOOOOOOOOX.',
  'XHOOOOOOOOOOOOOOOOOOOOHX',
  'XOOOOOOOOOOOOOOOOOOOOOOX',
  'XOOOOOObbXOOOOXbbOOOOOOX',
  'XOOOOOObeXOOOOXebOOOOOOX',
  'XOOOOOObeWOOOOWe bOOOOOOX'.replace(' ',''),
  'XOOOOOOOOOOOOOOOOOOOOOOX',
  'XOWWWOOOOOOOOOOOOOOOWWWX',
  'XWWWWWWWWWWWWWWWWWWWWWWX',
  'XWWWWWWWWWWWWWWWWWWWWWWX',
  '.XWWWWWWWWWWWWWWWWWWWWX.',
  '..XWWWWWWWWWeWWWWWWWWX..',
  '...XWWWWWWWWWXWWWWWWWX...',
  '....XWWWWWWWWWWWWWWX....',
  '......XXXXXXXXXXXX......'
 ]);
 // Pixel-placed cheek tufts and 5x5 eyes; a tiny centered nose and lifted smile.
 rows(a,1,14,['..XWW','XWWWW','WWWWW','.XWWW']);
 rows(a,26,14,['WWX..','WWWWX','WWWWW','WWWX.']);
 rows(a,8,10,['.bbb.','be e b'.replaceAll(' ',''),'beWeb','beeeb','.bbb.']);
 rows(a,19,10,['.bbb.','beeeb','beWeb','beeeb','.bbb.']);
 rows(a,15,18,['XX','eX']);
 rows(a,12,20,['XWW','..X']);rows(a,18,20,['WWX','X..']);
 return a;
}
function bigSide(){const a=canvas(32,36);
 rows(a,0,20,['....XXXXXXXX','..XXOOOOOWWX','XXOOOOOOWWWX','XOOOOOOWWWWX','XOOOOOWWWWWX','XOOOOWWWWWWX','XOOOOWWWWWWX','.XOWWWWWWWX','..XWWWWWWWX','...XXXXXXXX']);
 rows(a,11,21,['.XXRRRRXX.','XRRrrrrRRX','XAABCCBAAX','XAABGGB AAX'.replace(' ',''),'XAAABBAAAX','.XARRR RAX'.replace(' ',''),'..XKKKKX..']);
 rows(a,9,23,['XX','AX','AX','oX','XX']);rows(a,23,23,['XX','XA','XA','Xo','XX']);
 rows(a,11,29,['XAAAX','XAAAX','XKKKX','XXXXXX']);rows(a,18,29,['XAAAX','XAAAX','XKKKX','XXXXXX']);
 rows(a,5,3,[
  '....XXXXX.....XXXXX.....','...XOOOXX.....XXOOOX....',
  '...XOWWOX.....XOWWOX....','..XOOOOOXXXXXXXOOOOOX...',
  '.XOOOOOOOOOOOOOOOOOOOX..','XHOOOOOOOOOOOOOOOOOOOHX.',
  'XOOOOOOOOOOOOOOOOOOOOOOX','XOOOOOOObbXOOOOOOOOOOOOX',
  'XOOOOOOObeXOOOOOOOOOOOOX','XOOOOOOObeWOOOOOOOOOOOOX',
  'XOOOOOOOOOOOOOOOOOOOOOOX','XOWWWOOOOOOOOOOOOOOOWWWX',
  'XWWWWWWWWWWWWWWWWWWWWWWWX','XWWWWWWWWWWWWWWWWWWWWWWWX',
  '.XWWWWWWWWWWWWWWWWWWWWWWX','..XWWWWWWWWWWWWWeWWWWWX.',
  '...XWWWWWWWWWWWWXWWWWX..','....XWWWWWWWWWWWWWWWWX...',
  '......XXXXXXXXXXXXXXX....'
 ]);
 return a;
}
// C is a fresh silhouette, not a recolor of B. Each crown/cheek row was drawn
// at native pixel resolution and deliberately narrows into the lower jaw.
function roundFront(){const a=canvas(32,36);
 rows(a,18,19,['.......XXXXXX','....XXXOOOOOX','..XXOOOOOOOWX','.XOOOOOOWWWWX','XOOOOOOWWWWWX','XOOOOOWWWWWWX','XOOOOOWWWWWWX','.XOOOWWWWWWWX','..XOWWWWWWWX','...XWWWWWWWX','....XWWWWWWX','.....XXXXXXX']);
 rows(a,9,21,['..XXRRRRXX..','.XRRrrrrRRX.','XRRRRRRRRRRRX','XRRAABBAARRRX','XRRAAGGAARRRX','XRRRRRRRRRRRX','.XRRRRRRRRRX.','..XKKKKKKKX..']);
 rows(a,8,22,['XX','RX','RX','oX','XX']);rows(a,23,22,['XX','XR','XR','Xo','XX']);
 rows(a,10,29,['XAAX','XAAX','XKKX','XXXXX']);rows(a,18,29,['XAAX','XAAX','XKKX','XXXXX']);
 rows(a,2,2,[
  '......XX............XX......',
  '.....XOOX..........XOOX.....',
  '....XOWWOX........XOWWOX....',
  '...XOWWWOOX......XOWWWOOX...',
  '....XOOOOOOOOOOOOOOOOOOX....',
  '...XOOOOOOOOOOOOOOOOOOOOX...',
  '..XOOOOOOOOOOOOOOOOOOOOOOX..',
  '.XOOOOOOOOOOOOOOOOOOOOOOOOX.',
  'XHOOOOOOOOOOOOOOOOOOOOOOOOHX',
  'XOOOOOOOOOOOOOOOOOOOOOOOOOOX',
  'XOOOOOOOOOOOOOOOOOOOOOOOOOOX',
  'XOOOOOOOOOOOOOOOOOOOOOOOOOOX',
  'XOWWWWWWOOOOOOOOOOOOWWWWWWOX',
  'XWWWWWWWWWOOOOOOOOWWWWWWWWWX',
  'XWWWWWWWWWWOOOOWWWWWWWWWWWWX',
  '.XWWWWWWWWWWWWWWWWWWWWWWWWX.',
  '..XWWWWWWWWWWWWWWWWWWWWWWX..',
  '....XWWWWWWWWWWWWWWWWWWX....',
  '......XXXXXXXXXXXXXX......'
 ]);
 rows(a,0,15,['.XWW','XWWW','XWWW','.XWW']);
 rows(a,28,15,['WWX.','WWWX','WWWX','WWX.']);
 rows(a,15,13,['OO','OO','OO','oo']);
 rows(a,8,10,['.bbbb.','beeWeb','beeWeb','beeeeb','.bbbb.']);
 rows(a,18,10,['.bbbb.','beeWeb','beeWeb','beeeeb','.bbbb.']);
 rows(a,15,17,['ee','XW']);rows(a,12,19,['.X','X.']);rows(a,19,19,['X.','.X']);
 return a;
}
function roundSide(){const a=canvas(32,36);
 rows(a,0,19,['.......XXXXXX','....XXXXOOOX','..XXOOOOOOOX','.XWWWWOOOOOX','XXWWWWOOOOOOOX','XWWWWWOOOOOOOX','XWWWWWOOOOOOOX','XWWWWWWOOOOOOX','.XWWWWWWOOOOX','..XWWWWWWOOX','...XWWWWWOOX','....XWWWWOX','.....XXXXXX']);
 rows(a,10,21,['..XXRRRRXX..','.XRRrrrrRRX.','XRRRRRRRRRRRX','XRRAABBAARRRX','XRRAAGGAARRRX','XRRRRRRRRRRRX','.XRRRRRRRRRX.','..XKKKKKKKX..']);
 rows(a,8,22,['XX','RX','RX','oX','XX']);rows(a,23,22,['XX','XR','XR','Xo','XX']);
 rows(a,11,29,['XAAX','XAAX','XKKX','XXXXX']);rows(a,19,29,['XAAX','XAAX','XKKX','XXXXX']);
 rows(a,5,2,[
  '.....XX.........XX.....',
  '....XOOX.......XOOX....',
  '...XOWWOX.....XOWWOX...',
  '..XOWWWOOX...XOWWWOOX..',
  '...XOOOOOOOOOOOOOOOX...',
  '..XOOOOOOOOOOOOOOOOOX..',
  '.XOOOOOOOOOOOOOOOOOOOX.',
  'XHOOOOOOOOOOOOOOOOOOOX...',
  'XOOOOOOOOOOOOOOOOOOOOX...',
  'XOOOOOOOOOOOOOOOOOOOOX...',
  'XOOOOOOOOOOOOOOOOOOOOOX..',
  'XOOOOOOOOOOOOOOOOOOOOOOX.',
  'XOWWWOOOOOOOOOOWWWWWWWOX.',
  'XWWWWWWWWWWWWWWWWWWWWWWX.',
  '.XWWWWWWWWWWWWWWWWWWWWWWX',
  '..XWWWWWWWWWWWWWWWWWWWWWe',
  '...XWWWWWWWWWWWWWWWWWWX..',
  '....XWWWWWWWWWWWWWWWWX...',
  '......XWWWWWWWWWWWWX.....',
  '........XXXXXXXXXX......'
 ]);
 rows(a,17,10,['.bbbb.','beeWeb','beeWeb','beeeeb','.bbbb.']);
 rows(a,26,13,['OO','OOO','.OO','..OW']);
 rows(a,28,16,['WWX','WWWe','WX..']);
 return a;
}
function crc(b){let c=~0;for(const n of b){c^=n;for(let k=0;k<8;k++)c=(c>>>1)^((c&1)?0xedb88320:0)}return(~c)>>>0}
function png(a){const sig=Buffer.from([137,80,78,71,13,10,26,10]);function chunk(t,d){const n=Buffer.from(t),l=Buffer.alloc(4),c=Buffer.alloc(4);l.writeUInt32BE(d.length);c.writeUInt32BE(crc(Buffer.concat([n,d])));return Buffer.concat([l,n,d,c])}const ih=Buffer.alloc(13);ih.writeUInt32BE(a.w);ih.writeUInt32BE(a.h,4);ih[8]=8;ih[9]=6;const raw=Buffer.alloc((a.w*4+1)*a.h);for(let y=0;y<a.h;y++)Buffer.from(a.data.subarray(y*a.w*4,(y+1)*a.w*4)).copy(raw,y*(a.w*4+1)+1);return Buffer.concat([sig,chunk('IHDR',ih),chunk('IDAT',zlib.deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))])}
module.exports={palette,canvas,dot,rows,merge,scale,roundFront,roundSide,png};
if(require.main===module){
 const front=roundFront(),side=roundSide();
 for(const [name,cel] of [['front',front],['side',side]]){
  fs.writeFileSync(path.join(root,`round_fox_head_${name}_native.png`),png(cel));
  fs.writeFileSync(path.join(root,`round_fox_head_${name}_review2x.png`),png(scale(cel,2)));
 }
 console.log('Round fox head source study regenerated; full motion is built by build_round_characters.js.');
}
