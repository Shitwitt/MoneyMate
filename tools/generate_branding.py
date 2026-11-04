#!/usr/bin/env python3
"""Rebuild Tink's user-reference redraw. Dev-only: pip install pillow aggdraw.
Native IDs, widget kinds, database keys, and existing deep links are unchanged.
"""
from pathlib import Path
import json
from PIL import Image
import aggdraw
ROOT = Path(__file__).resolve().parents[1]
HEAD = 'M23 61 C27 42 34 21 43 18 C50 15 70 18 76 22 C84 28 85 48 78 56 Q74 61 64 68 L67 91 Q58 93 47 90 L45 68 L25 66 Q21 66 23 61 Z'
STAR = 'M53 29 Q56 29 57 39 Q60 43 69 46 Q70 48 59 51 Q56 55 53 64 Q50 64 47 53 Q44 50 36 47 Q34 45 47 41 Q50 37 53 29 Z'
# Same control points as TinkMarkPainter, using cubic equivalents for AggDraw.
def draw(size):
    side = 1600
    img = Image.new('RGB',(side,side),'#FAF9F5')
    context = aggdraw.Draw(img)
    scale=side*.80/100; tx=side*.10; ty=side*.03
    def path(ops, fill=None, stroke=None):
        p=aggdraw.Path()
        for op,xy in ops:
            pts=[(tx+v*scale) if i%2==0 else (ty+v*scale) for i,v in enumerate(xy)]
            {'M':p.moveto,'L':p.lineto,'C':p.curveto,'Z':p.close}[op](*pts)
        context.path(p,aggdraw.Brush(fill) if fill else None,aggdraw.Pen(stroke,3.2*scale) if stroke else None)
    path([('M',(23,61)),('C',(27,42,34,21,43,18)),('C',(50,15,70,18,76,22)),('C',(84,28,85,48,78,56)),
        ('C',(75.333,59.333,70.667,63.333,64,68)),('L',(67,91)),('C',(61,92.333,54.333,92,47,90)),
        ('L',(45,68)),('L',(25,66)),('C',(22.333,66,21.667,64.333,23,61)),('Z',())],stroke='#0B0B0F')
    path([('M',(53,29)),('C',(55,29,56.333,32.333,57,39)),('C',(59,41.667,63,44,69,46)),
        ('C',(69.667,47.333,66.333,49,59,51)),('C',(57,53.667,55,58,53,64)),('C',(51,64,49,60.333,47,53)),
        ('C',(45,51,41.333,49,36,47)),('C',(34.667,45.667,38.333,43.667,47,41)),('C',(49,38.333,51,34.333,53,29)),('Z',())],fill='#FFF12B')
    path([('M',(53,37)),('L',(56,45)),('L',(62,47)),('L',(55,50)),('L',(52,57)),('L',(49,49)),('L',(43,46)),('L',(50,44)),('Z',())],fill='#FFF997')
    context.flush()
    return img.resize((size,size),Image.Resampling.LANCZOS)
def save(path,size):
    target=ROOT/path;target.parent.mkdir(parents=True,exist_ok=True);draw(size).save(target,optimize=True)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    save(Path(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'),size)
for name,size in [('favicon.png',48),('icons/Icon-192.png',192),('icons/Icon-512.png',512),('icons/Icon-maskable-192.png',192),('icons/Icon-maskable-512.png',512)]:save(Path('web')/name,size)
iconset=ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((iconset/'Contents.json').read_text())['images']:
    save(iconset.relative_to(ROOT)/item['filename'],round(float(item['size'].split('x')[0])*float(item['scale'][:-1])))
launch=ROOT/'ios/Runner/Assets.xcassets/LaunchImage.imageset'
for item in json.loads((launch/'Contents.json').read_text())['images']:
    save(launch.relative_to(ROOT)/item['filename'],round(96*float(item['scale'][:-1])))
save(Path('assets/branding/mark.png'),1024)
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="24" fill="#FAF9F5"/><g transform="translate(10 3) scale(.8)"><path d="{HEAD}" fill="none" stroke="#0B0B0F" stroke-width="3.2" stroke-linejoin="round" stroke-linecap="round"/><path d="{STAR}" fill="#FFF12B"/><path d="M53 37L56 45L62 47L55 50L52 57L49 49L43 46L50 44Z" fill="#FFF997"/></g></svg>'''
(ROOT/'assets/branding/tink-mark.svg').write_text(svg)
vector=f'''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="100" android:viewportHeight="100">
<group android:translateX="10" android:translateY="3" android:scaleX="0.8" android:scaleY="0.8">
<path android:pathData="{HEAD}" android:fillColor="@android:color/transparent" android:strokeColor="#0B0B0F" android:strokeWidth="3.2" android:strokeLineCap="round" android:strokeLineJoin="round"/>
<path android:pathData="{STAR}" android:fillColor="#FFF12B"/>
<path android:pathData="M53 37L56 45L62 47L55 50L52 57L49 49L43 46L50 44Z" android:fillColor="#FFF997"/>
</group></vector>'''
(ROOT/'android/app/src/main/res/drawable/ic_launcher_foreground.xml').write_text(vector)
mono=vector.replace('#0B0B0F','#FFFFFF').replace('#FFF12B','#FFFFFF').replace('#FFF997','#FFFFFF')
(ROOT/'android/app/src/main/res/drawable/ic_notification.xml').write_text(mono)
print('Rebuilt Android, iOS, web, and editable Tink branding assets.')
