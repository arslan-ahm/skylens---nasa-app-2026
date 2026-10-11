// Builds the compact offline sky catalog bundled in assets/catalog/.
//
// Usage (from app/):
//   node tool/build_sky_catalog.mjs <hygdata_v40.csv> <constellations.lines.json> <constellations.json> [maxMag]
//
// Sources (download them yourself, they are not committed):
//   HYG v4.0  https://github.com/astronexus/HYG-Database  (CC BY-SA 4.0)
//   d3-celestial constellation data  https://github.com/ofrohn/d3-celestial  (BSD-3-Clause)
//
// Output (all angles in degrees, J2000 equinox):
//   stars.json          {"fields":[...], "rows":[[ra,dec,mag,ci,name,con,bayer,hip], ...]}
//   constellations.json [{"id":"Ori","name":"Orion","label":[ra,dec],"lines":[[[ra,dec],...],...]}, ...]

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const [hygPath, linesPath, constPath, maxMagArg] = process.argv.slice(2);
if (!hygPath || !linesPath || !constPath) {
  console.error('usage: node tool/build_sky_catalog.mjs <hyg.csv> <lines.json> <constellations.json> [maxMag]');
  process.exit(1);
}
const maxMag = Number(maxMagArg ?? 5.5);
const outDir = 'assets/catalog';
mkdirSync(outDir, { recursive: true });

// --- Stars ---------------------------------------------------------------
function parseCsvLine(line) {
  const out = [];
  let cur = '';
  let quoted = false;
  for (const ch of line) {
    if (ch === '"') quoted = !quoted;
    else if (ch === ',' && !quoted) { out.push(cur); cur = ''; }
    else cur += ch;
  }
  out.push(cur);
  return out;
}

const lines = readFileSync(hygPath, 'utf8').split(/\r?\n/);
const header = parseCsvLine(lines[0]);
const col = Object.fromEntries(header.map((h, i) => [h, i]));
const round = (v, d) => Math.round(v * 10 ** d) / 10 ** d;

const rows = [];
for (let i = 1; i < lines.length; i++) {
  if (!lines[i]) continue;
  const f = parseCsvLine(lines[i]);
  if (f[col.proper] === 'Sol') continue;
  const mag = Number(f[col.mag]);
  if (!(mag <= maxMag)) continue;
  rows.push([
    round(Number(f[col.ra]) * 15, 4), // hours -> degrees
    round(Number(f[col.dec]), 4),
    round(mag, 2),
    f[col.ci] === '' ? null : round(Number(f[col.ci]), 2),
    f[col.proper] || null,
    f[col.con] || null,
    f[col.bayer] || null,
    f[col.hip] === '' ? null : Number(f[col.hip]),
  ]);
}
rows.sort((a, b) => a[2] - b[2]);
writeFileSync(
  `${outDir}/stars.json`,
  JSON.stringify({
    source: 'HYG Database v4.0 (astronexus), CC BY-SA 4.0',
    maxMag,
    fields: ['ra', 'dec', 'mag', 'ci', 'name', 'con', 'bayer', 'hip'],
    rows,
  }),
);

// --- Constellations ------------------------------------------------------
// d3-celestial stores RA as a longitude in [-180, 180].
const toRa = (lon) => round(lon < 0 ? lon + 360 : lon, 4);
const linesGeo = JSON.parse(readFileSync(linesPath, 'utf8'));
const constGeo = JSON.parse(readFileSync(constPath, 'utf8'));
const meta = Object.fromEntries(constGeo.features.map((f) => [f.id, f]));

const constellations = linesGeo.features.map((f) => {
  const m = meta[f.id];
  const [lon, lat] = m?.geometry?.coordinates ?? [0, 0];
  return {
    id: f.id,
    name: m?.properties?.en ?? m?.properties?.name ?? f.id,
    label: [toRa(lon), round(lat, 4)],
    lines: f.geometry.coordinates.map((seg) => seg.map(([lo, la]) => [toRa(lo), round(la, 4)])),
  };
});
writeFileSync(
  `${outDir}/constellations.json`,
  JSON.stringify({ source: 'd3-celestial (Olaf Frohn), BSD-3-Clause', constellations }),
);

console.log(`stars: ${rows.length} (mag <= ${maxMag}), constellations: ${constellations.length}`);
