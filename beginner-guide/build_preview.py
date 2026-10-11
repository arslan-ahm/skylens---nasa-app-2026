"""Build the standalone preview (index.html) from the slide sources in src/.

The slides are written in the claude.ai Slides format (one <section> per file,
plus <x-embed> live phone demos and <x-connector> arrows). This script turns
them into one self-contained page you can open by double-clicking.

usage (from anywhere):  python beginner-guide/build_preview.py
"""
import html
import json
import math
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / 'src' / 'project'
OUT = HERE / 'index.html'


def px(style, prop, default):
    m = re.search(rf'(?:^|;)\s*{prop}\s*:\s*([\d.]+)px', style)
    return float(m.group(1)) if m else default


def embed(m):
    """<x-embed> -> sandboxed <iframe srcdoc> (same as the Slides player)."""
    attrs, inner = m.group(1), m.group(2)
    style = re.search(r'style="([^"]*)"', attrs).group(1)
    build = re.search(r'data-build-in="([^"]*)"', attrs)
    b = f' data-build-in="{build.group(1)}"' if build else ''
    return (f'<iframe{b} sandbox="allow-scripts" srcdoc="{html.escape(inner, quote=True)}" '
            f'style="{style};border:0;background:transparent;color-scheme:normal"></iframe>')


def connector(m):
    """<x-connector x1 y1 x2 y2> -> an SVG line with an arrowhead."""
    a = dict(re.findall(r'(\w[\w-]*)="([^"]*)"', m.group(1)))
    x1, y1, x2, y2 = (float(a[k]) for k in ('x1', 'y1', 'x2', 'y2'))
    style = a.get('style', '')
    col = re.search(r'color:\s*(#[0-9A-Fa-f]+|rgba?\([^)]*\))', style)
    col = col.group(1) if col else '#FFFFFF'
    w = px(style, 'border-width', 2)
    ang = math.atan2(y2 - y1, x2 - x1)
    h = 8 + w * 3
    p1 = (x2 - h * math.cos(ang - 0.45), y2 - h * math.sin(ang - 0.45))
    p2 = (x2 - h * math.cos(ang + 0.45), y2 - h * math.sin(ang + 0.45))
    head = (f'<polygon points="{x2},{y2} {p1[0]:.1f},{p1[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}" fill="{col}"/>'
            if a.get('head', 'end') != 'none' else '')
    return (f'<svg style="position:absolute;left:0;top:0;width:1920px;height:1080px;pointer-events:none" '
            f'viewBox="0 0 1920 1080"><line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{col}" '
            f'stroke-width="{w}" stroke-linecap="round"/>{head}</svg>')


def builds(s):
    """data-build-in="rise order 2" -> data-build / data-order for CSS animations."""
    def rep(m):
        kind, *rest = m.group(1).split()
        order = int(rest[rest.index('order') + 1]) if 'order' in rest else 1
        return f'data-build="{kind}" data-order="{order}"'
    return re.sub(r'data-build-in="([^"]*)"', rep, s)


deck = json.loads((SRC / 'deck.json').read_text(encoding='utf8'))
slides = []
for sid in deck['order']:
    s = (SRC / 'slides' / f'{sid}.html').read_text(encoding='utf8')
    s = re.sub(r'<aside>.*?</aside>', '', s, flags=re.S)
    s = re.sub(r'<x-embed([^>]*)>(.*?)</x-embed>', embed, s, flags=re.S)
    s = re.sub(r'<x-connector([^>]*)></x-connector>', connector, s)
    slides.append(builds(s))

fonts = '&'.join('family=' + f['href'].split('family=')[1].split('&')[0] for f in deck['faces'].values())
page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(deck['title'])}</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?{fonts}&display=swap">
<style>
html,body{{margin:0;height:100%;background:#000;overflow:hidden}}
#stage{{position:absolute;left:50%;top:50%;width:1920px;height:1080px;transform-origin:0 0}}
section{{position:absolute;inset:0;box-sizing:border-box;overflow:hidden;opacity:0;visibility:hidden;transition:opacity .6s,visibility .6s}}
section.active{{opacity:1;visibility:visible}}
section *{{margin:0;box-sizing:border-box}}
section ul{{padding-left:1.2em}}
section h1,section h2,section h3{{font-weight:400}}
[data-build]{{opacity:0}}
.active [data-build]{{animation:.8s cubic-bezier(.2,.8,.2,1) both}}
.active [data-build=rise]{{animation-name:rise}}.active [data-build=fade]{{animation-name:fade}}
.active [data-build=pop]{{animation-name:pop}}.active [data-build=left]{{animation-name:lft}}
.active [data-build=right]{{animation-name:rgt}}
@keyframes rise{{from{{opacity:0;transform:translateY(40px)}}to{{opacity:1;transform:none}}}}
@keyframes fade{{from{{opacity:0}}to{{opacity:1}}}}
@keyframes pop{{from{{opacity:0;transform:scale(.7)}}to{{opacity:1;transform:none}}}}
@keyframes lft{{from{{opacity:0;transform:translateX(-60px)}}to{{opacity:1;transform:none}}}}
@keyframes rgt{{from{{opacity:0;transform:translateX(60px)}}to{{opacity:1;transform:none}}}}
#stepbar{{transition:width .8s cubic-bezier(.2,.8,.2,1)}}
#hud{{position:fixed;right:16px;bottom:14px;display:flex;gap:8px;align-items:center;font:400 13px/1 Geist,system-ui,sans-serif;letter-spacing:.04em;color:#807f7f;user-select:none;opacity:.35;transition:opacity .3s}}
#hud:hover{{opacity:1}}
#hud button{{font:inherit;letter-spacing:inherit;color:#fff;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.18);backdrop-filter:blur(12px);border-radius:20px;padding:8px 16px;cursor:pointer}}
#hud button:hover{{border-color:#fff}}
body.light #hud{{color:#666}}body.light #hud button{{color:#000;background:rgba(0,0,0,.04);border-color:rgba(0,0,0,.2)}}
#bar{{position:fixed;left:0;bottom:0;height:2px;background:#22e2a8;transition:width .5s}}
</style></head><body>
<div id="stage">{''.join(slides)}</div>
<div id="bar"></div>
<div id="hud"><span id="n"></span><button id="pv" aria-label="Previous slide">‹</button><button id="nx" aria-label="Next slide">›</button><button id="fs">Full screen</button></div>
<script>
const S=[...document.querySelectorAll('#stage>section')],st=document.getElementById('stage'),n=document.getElementById('n'),bar=document.getElementById('bar');
document.querySelectorAll('[data-order]').forEach(e=>e.style.animationDelay=(0.15+(e.dataset.order-1)*0.3)+'s');
let i=Math.max(0,Math.min(S.length-1,(parseInt(location.hash.slice(1))||1)-1));
function go(k){{i=Math.max(0,Math.min(S.length-1,k));S.forEach((s,j)=>s.classList.toggle('active',j==i));document.body.classList.toggle('light',/^background:#F/i.test(S[i].getAttribute('style')));
n.textContent=String(i+1).padStart(2,'0')+' / '+S.length;bar.style.width=((i+1)/S.length*100)+'%';history.replaceState(null,'','#'+(i+1))}}
function fit(){{const s=Math.min(innerWidth/1920,innerHeight/1080);st.style.transform='scale('+s+') translate(-50%,-50%)'}}
addEventListener('resize',fit);fit();go(i);
addEventListener('keydown',e=>{{if(['ArrowRight','PageDown',' ','Enter'].includes(e.key))go(i+1);if(['ArrowLeft','PageUp','Backspace'].includes(e.key))go(i-1);if(e.key=='Home')go(0);if(e.key=='End')go(S.length-1);if(e.key=='f')document.documentElement.requestFullscreen()}});
document.getElementById('nx').onclick=()=>go(i+1);document.getElementById('pv').onclick=()=>go(i-1);
document.getElementById('fs').onclick=()=>document.documentElement.requestFullscreen();
</script></body></html>'''
OUT.write_text(page, encoding='utf8')
print(f'{len(slides)} slides -> {OUT} ({OUT.stat().st_size // 1024} KB)')
