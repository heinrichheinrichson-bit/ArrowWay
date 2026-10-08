from pathlib import Path
import math,re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'branding';OUT.mkdir(exist_ok=True)
# Paths are drawn once. Every arrow consists of one shaft and one head.
arrows=[
 ('M230 235 Q206 193 153 177 L126 169',(126,169),(-1,-.3),'#14eff4'),
 ('M226 251 Q185 232 151 213',(151,213),(-1,-.6),'#22caff'),
 ('M145 265 Q128 311 176 354',(176,354),(.75,.8),'#ff35c9'),
 ('M222 276 Q218 304 190 322',(190,322),(-.8,.6),'#ffe02a'),
 ('M256 348 L256 243',(256,243),(0,-1),'#b89aff'),
 ('M246 209 Q243 185 229 169',(229,169),(-.5,-.8),'#b89aff')]
for path,tip,direction,color in arrows[:4]+arrows[5:]:
 # Mirror the geometry, not the arrow direction or head count.
 arrows.append((path,tip,direction,color,'translate(512 0) scale(-1 1)'))
parts=[];mono=[]
for arrow in arrows:
 path,(x,y),(dx,dy),color,*transform=arrow
 length=math.hypot(dx,dy);dx/=length;dy/=length
 bx,by=x-dx*19,y-dy*19
 path=re.sub(r'[-\d.]+ [-\d.]+$', f'{x-dx*10:.2f} {y-dy*10:.2f}', path)
 points=f'{x:.2f},{y:.2f} {bx-dy*11:.2f},{by+dx*11:.2f} {bx+dy*11:.2f},{by-dx*11:.2f}'
 shape=f'<path d="{path}" fill="none" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/><polygon points="{points}" fill="{{c}}" stroke="{{c}}" stroke-width="2" stroke-linejoin="round"/>'
 attr=f' transform="{transform[0]}"' if transform else ''
 glow=''.join(f'<g opacity="{opacity}">{shape.format(c=color,w=width)}</g>' for width,opacity in [(29,.025),(23,.045),(18,.09)])
 parts.append(f'<g{attr}>{glow}{shape.format(c=color,w=13)}</g>')
 mono.append(f'<g{attr}>{shape.format(c="#ffffff",w=13)}</g>')
mark=''.join(parts)
def svg(name,body,view='0 0 512 512'):
 (OUT/name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="{view}">{body}</svg>\n',encoding='utf-8')
svg('mark.svg',mark,'88 104 336 280')
svg('icon.svg','<rect width="512" height="512" fill="#07132d"/><g transform="translate(-77 -77) scale(1.3)">'+mark+'</g>')
svg('adaptive_foreground.svg',mark)
svg('adaptive_background.svg','<rect width="512" height="512" fill="#07132d"/>')
svg('adaptive_monochrome.svg',''.join(mono))
print('Generated 11 single-headed arrows as native SVG assets')
