// Hand-authored native-grid blade effects. No resampling or alpha feathering.
// `node assets/art/production/fx/build_blade_fx.js`
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const HERE = __dirname;
const SCALE = 2;
const PAL = {
  deep_cyan: '#287d9c', cyan: '#65cce6', ice: '#c7f5fa', white: '#fff8df',
  burnt: '#a85427', amber: '#ef9b3b', gold: '#ffd077', warm_white: '#fff1c5',
  impact: '#f7eccb', stone: '#78899a'
};
const RGB = Object.fromEntries(Object.entries(PAL).map(([name, hex]) => [name, [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16)).concat(255)]));

function canvas(w, h) { return { w, h, pixels: new Uint8Array(w * h * 4) }; }
function dot(c, x, y, ink) {
  x = Math.round(x); y = Math.round(y);
  if (x < 0 || y < 0 || x >= c.w || y >= c.h) return;
  c.pixels.set(RGB[ink], (y * c.w + x) * 4);
}
function line(c, x0, y0, x1, y1, ink) {
  x0 = Math.round(x0); y0 = Math.round(y0); x1 = Math.round(x1); y1 = Math.round(y1);
  let dx = Math.abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
  let dy = -Math.abs(y1 - y0), sy = y0 < y1 ? 1 : -1, error = dx + dy;
  while (true) {
    dot(c, x0, y0, ink);
    if (x0 === x1 && y0 === y1) break;
    const e2 = error * 2;
    if (e2 >= dy) { error += dy; x0 += sx; }
    if (e2 <= dx) { error += dx; y0 += sy; }
  }
}
function copy(into, source, ox, oy) {
  for (let y = 0; y < source.h; y++) for (let x = 0; x < source.w; x++) {
    const from = (y * source.w + x) * 4;
    if (!source.pixels[from + 3]) continue;
    into.pixels.set(source.pixels.subarray(from, from + 4), ((y + oy) * into.w + x + ox) * 4);
  }
}
function scaleNearest(c, factor) {
  const out = canvas(c.w * factor, c.h * factor);
  for (let y = 0; y < out.h; y++) for (let x = 0; x < out.w; x++) {
    const source = (Math.floor(y / factor) * c.w + Math.floor(x / factor)) * 4;
    out.pixels.set(c.pixels.subarray(source, source + 4), (y * out.w + x) * 4);
  }
  return out;
}
function crc(buffer) {
  let c = ~0;
  for (const n of buffer) { c ^= n; for (let k = 0; k < 8; k++) c = (c >>> 1) ^ ((c & 1) ? 0xedb88320 : 0); }
  return (~c) >>> 0;
}
function png(c) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  function chunk(name, data) {
    const tag = Buffer.from(name), size = Buffer.alloc(4), checksum = Buffer.alloc(4);
    size.writeUInt32BE(data.length); checksum.writeUInt32BE(crc(Buffer.concat([tag, data])));
    return Buffer.concat([size, tag, data, checksum]);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(c.w); ihdr.writeUInt32BE(c.h, 4); ihdr[8] = 8; ihdr[9] = 6;
  const raw = Buffer.alloc((c.w * 4 + 1) * c.h);
  for (let y = 0; y < c.h; y++) Buffer.from(c.pixels.subarray(y * c.w * 4, (y + 1) * c.w * 4)).copy(raw, y * (c.w * 4 + 1) + 1);
  return Buffer.concat([signature, chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}
function writePng(name, c) { fs.writeFileSync(path.join(HERE, name), png(c)); }

// 16 x 36 native strip, vertical. Repeated strips overlap 8 world pixels so the
// blade does not fracture into isolated dashes. The terminal cap is provided
// as a separate sprite below, not by scaling the strip to arbitrary distance.
function straight(frame) {
  const c = canvas(16, 36);
  const density = [1, 3, 4, 2][frame];
  const reach = [27, 31, 34, 30][frame];
  for (let y = 2; y <= reach; y++) {
    const sway = y < 9 ? -1 : (y > 25 ? 1 : 0);
    const core = 7 + sway;
    dot(c, core - 3, y, 'deep_cyan');
    dot(c, core - 2, y, 'cyan');
    dot(c, core - 1, y, 'ice');
    dot(c, core, y, 'white');
    dot(c, core + 1, y, 'ice');
    dot(c, core + 2, y, 'cyan');
    if (density > 1) dot(c, core + 3, y, 'deep_cyan');
    if (density > 2 && y % 5 < 2) dot(c, core - 4, y, 'deep_cyan');
    if (y % 9 === 0) dot(c, core + 4, y - 1, 'ice');
  }
  // Directional swept edge and tapered tip; not a rectangular fill.
  line(c, 3, 4, 5, 1, 'cyan');
  line(c, 11, 27, 7, Math.min(reach + 1, 35), 'ice');
  dot(c, 8, Math.min(reach + 1, 35), 'white');
  if (frame === 1 || frame === 2) {
    line(c, 12, 9, 14, 5, 'cyan');
    line(c, 2, 26, 0, 29, 'deep_cyan');
  }
  return c;
}
function straightCap(frame) {
  const c = canvas(16, 16);
  const tip = [8, 10, 12, 7][frame];
  line(c, 4, 1, 8, tip, 'cyan');
  line(c, 7, 1, 8, tip + 1, 'white');
  line(c, 10, 1, 8, tip, 'ice');
  line(c, 12, 2, 9, tip - 2, 'deep_cyan');
  dot(c, 8, Math.min(tip + 1, 15), 'white');
  return c;
}
function arc(frame) {
  const c = canvas(96, 96), cx = 48, cy = 48;
  const lead = [-Math.PI * .42, Math.PI * .08, Math.PI * .58, Math.PI * 1.08][frame];
  const start = lead - 1.40, radius = 39;
  // One travelling crescent, not an always-on ring and not a targeting outline.
  for (let deg = 0; deg <= 90; deg++) {
    const t = start + deg * Math.PI / 180;
    const fade = deg < 11 ? 0 : deg > 82 ? 1 : 2;
    for (let band = -4; band <= 4; band++) {
      if (fade === 0 && Math.abs(band) > 1) continue;
      if (fade === 1 && Math.abs(band) > 3) continue;
      const r = radius + band;
      const ink = Math.abs(band) <= 1 ? (fade === 2 ? 'warm_white' : 'gold') :
        Math.abs(band) <= 3 ? (fade === 2 ? 'gold' : 'amber') : 'burnt';
      dot(c, cx + Math.cos(t) * r, cy + Math.sin(t) * r, ink);
    }
  }
  // Sharp forward wedge and deliberately sparse retreating cinders.
  for (let j = 0; j < 7; j++) {
    const t = lead - j * .045;
    dot(c, cx + Math.cos(t) * (radius + 2 + Math.min(j, 3)), cy + Math.sin(t) * (radius + 2 + Math.min(j, 3)), j < 3 ? 'warm_white' : 'gold');
  }
  for (let j = 0; j < 8; j++) {
    const t = start - .16 - j * .16;
    const r = radius - 4 - (j % 3) * 3;
    dot(c, cx + Math.cos(t) * r, cy + Math.sin(t) * r, j < 3 ? 'gold' : 'amber');
  }
  // Small inner sweep hints at fox rotation without inventing a second radius.
  for (let deg = 0; deg < 28; deg += 2) {
    const t = lead - .82 + deg * Math.PI / 180;
    dot(c, cx + Math.cos(t) * 29, cy + Math.sin(t) * 29, 'amber');
  }
  return c;
}
function hit(frame) {
  const c = canvas(24, 24), cx = 12, cy = 12;
  const reach = [3, 7, 10, 8, 5, 2][frame];
  const arms = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, 1], [1, -1], [-1, -1]];
  for (const [dx, dy] of arms) {
    const len = dx && dy ? reach - 2 : reach;
    if (len < 1) continue;
    const tx = cx + dx * len, ty = cy + dy * len;
    line(c, cx + dx * 2, cy + dy * 2, tx, ty, frame < 3 ? 'warm_white' : 'stone');
    if (frame < 4) dot(c, tx, ty, frame < 2 ? 'white' : 'impact');
  }
  if (frame < 3) {
    for (let y = -2; y <= 2; y++) for (let x = -2; x <= 2; x++) {
      if (Math.abs(x) + Math.abs(y) < (frame === 0 ? 2 : 4)) dot(c, cx + x, cy + y, frame === 0 ? 'white' : 'impact');
    }
  }
  if (frame > 1 && frame < 5) {
    dot(c, cx - reach, cy - Math.max(reach - 3, 0), 'amber');
    dot(c, cx + reach, cy + Math.max(reach - 4, 0), 'cyan');
  }
  return c;
}

const batches = [
  { name: 'straight_blade', w: 16, h: 36, frames: 4, time: 55, draw: straight, anchor: [8, 0] },
  { name: 'straight_tip', w: 16, h: 16, frames: 4, time: 55, draw: straightCap, anchor: [8, 0] },
  { name: 'arc_blade', w: 96, h: 96, frames: 4, time: 55, draw: arc, anchor: [48, 48] },
  { name: 'blade_hit', w: 24, h: 24, frames: 6, time: 35, draw: hit, anchor: [12, 12] }
];
const manifest = { schema: 'foxknight.blade_fx.v1', scale: SCALE, palette: PAL, effects: [] };
const previews = [];
for (const batch of batches) {
  const sheet = canvas(batch.w * batch.frames, batch.h);
  for (let i = 0; i < batch.frames; i++) {
    const frame = batch.draw(i);
    let opaque = 0;
    for (let y = 0; y < frame.h; y++) for (let x = 0; x < frame.w; x++) {
      const alpha = frame.pixels[(y * frame.w + x) * 4 + 3];
      if (alpha !== 0 && alpha !== 255) throw new Error(`${batch.name} frame ${i} has soft alpha`);
      if (!alpha) continue;
      opaque++;
      if (batch.name === 'arc_blade' && Math.hypot(x - 48, y - 48) > 44.5)
        throw new Error(`Arc frame ${i} paints beyond its 90-world-pixel visual envelope at ${x},${y}`);
    }
    if (!opaque) throw new Error(`${batch.name} frame ${i} is blank`);
    copy(sheet, frame, batch.w * i, 0);
  }
  writePng(batch.name + '_source.png', sheet);
  writePng(batch.name + '.png', scaleNearest(sheet, SCALE));
  previews.push({ batch, frames: Array.from({length: batch.frames}, (_, i) => scaleNearest(batch.draw(i), SCALE)) });
  manifest.effects.push({ name: batch.name, native_frame: [batch.w, batch.h], world_frame: [batch.w * SCALE, batch.h * SCALE], frames: batch.frames, frame_ms: batch.time, anchor_native: batch.anchor, anchor_world: batch.anchor.map(n => n * SCALE), source: batch.name + '_source.png', export: batch.name + '.png' });
}
// Inspection-only contact sheet: 2x *game-sized* frames on a dark scene-like
// backing. Rows: straight blade, straight tip, arc blade, hit; 0-5 left-right.
const cell = 200, contact = canvas(cell * 6, cell * previews.length);
for (let y = 0; y < contact.h; y++) for (let x = 0; x < contact.w; x++) {
  const base = (y * contact.w + x) * 4;
  const tint = ((Math.floor(x / cell) + Math.floor(y / cell)) % 2) ? [20, 29, 43, 255] : [16, 24, 36, 255];
  contact.pixels.set(tint, base);
}
previews.forEach(({ frames }, row) => frames.forEach((frame, col) => copy(contact, frame, col * cell + Math.floor((cell - frame.w) / 2), row * cell + Math.floor((cell - frame.h) / 2))));
writePng('blade_contact_2x.png', contact);
fs.writeFileSync(path.join(HERE, 'blade_frames.json'), JSON.stringify(manifest, null, 2) + '\n');
console.log('Built hand-pixelled straight, arc and impact FX.');
