"""Author the expanded catalog as editable raster regions, not rendered images.

Recipes use broad silhouettes and shared drawing primitives. Variants change
geometry or region layout; duplicate geometry is rejected independently of color.
The Godot generator subsequently packs and solves every accepted source mask.
"""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PALETTE = ['#ff568f', '#39e994', '#65d5ff', '#ffcf67', '#ac83ff', '#ff9666', '#f0f5ff', '#bc8550']


class Canvas:
    def __init__(self, seed):
        self.cells = {}
        self.seed = seed
        self.colors = list(PALETTE)
        self.names = ['Motiv', 'Natur', 'Wasser und Glas', 'Gold und Licht', 'Akzent', 'Warme Fläche', 'Helle Fläche', 'Holz und Erde']

    def shape(self, p, fn):
        for y in range(33):
            for x in range(29):
                if fn(x, y):
                    self.cells[x, y] = p

    def rect(self, p, a, b, c, d):
        self.shape(p, lambda x, y: a <= x <= c and b <= y <= d)

    def oval(self, p, x, y, rx, ry):
        self.shape(p, lambda a, b: ((a-x)/rx)**2 + ((b-y)/ry)**2 <= 1)

    def poly(self, p, points):
        def inside(x, y):
            hit = False
            for (ax, ay), (bx, by) in zip(points, points[1:]+points[:1]):
                cross = (x-ax)*(by-ay)-(y-ay)*(bx-ax)
                if abs(cross) < 1e-8 and min(ax,bx) <= x <= max(ax,bx) and min(ay,by) <= y <= max(ay,by):
                    return True
                if (ay > y) != (by > y) and x < (bx-ax)*(y-ay)/(by-ay)+ax:
                    hit = not hit
            return hit
        self.shape(p, inside)

    def line(self, p, points, width=2.8):
        def near(x,y):
            for (ax,ay),(bx,by) in zip(points,points[1:]):
                dx,dy=bx-ax,by-ay
                t=max(0,min(1,((x-ax)*dx+(y-ay)*dy)/max(.0001,dx*dx+dy*dy)))
                if (x-ax-t*dx)**2+(y-ay-t*dy)**2 <= (width/2)**2:
                    return True
            return False
        self.shape(p, near)

    def cut(self, fn):
        self.cells = {c:p for c,p in self.cells.items() if not fn(*c)}

    def star(self, p, x=14, y=16, r=11, points=5):
        self.poly(p, [(x+math.cos(-math.pi/2+i*math.pi/points)*(r if i%2==0 else r*.48), y+math.sin(-math.pi/2+i*math.pi/points)*(r if i%2==0 else r*.48)) for i in range(points*2)])

    def ring(self,p,x,y,rx,ry,w=3):
        self.shape(p,lambda a,b: ((a-x)/rx)**2+((b-y)/ry)**2<=1 and ((a-x)/max(1,rx-w))**2+((b-y)/max(1,ry-w))**2>=1)

    def finish(self):
        # A colored component of one cell cannot hold a legal arrow.
        for _ in range(10):
            lonely=[c for c,p in self.cells.items() if not any(self.cells.get((c[0]+dx,c[1]+dy))==p for dx,dy in [(0,1),(0,-1),(1,0),(-1,0)])]
            if not lonely: break
            for c in lonely:
                neighbors=[self.cells.get((c[0]+dx,c[1]+dy)) for dx,dy in [(0,1),(0,-1),(1,0),(-1,0)]]
                neighbors=[p for p in neighbors if p is not None]
                if neighbors: self.cells[c]=max(set(neighbors),key=lambda p:(neighbors.count(p),-p))
                else: self.cells.pop(c,None)
        return [[x,y,p] for (x,y),p in sorted(self.cells.items(),key=lambda item:(item[0][1],item[0][0]))]


def face(c, kind, k):
    c.colors[0]={'cat':'#a8b5d9','fox':'#ffad62','dog':'#cda46d','bear':'#c69c66','panda':'#f0f5ff','rabbit':'#edf1ff','mouse':'#c3b0e2','lion':'#ffc957','koala':'#b3c0ce','wolf':'#94b3e6','owl':'#c9a46a'}.get(kind,c.colors[0])
    c.oval(0 if kind!='skull' else 6,14,17,10,11)
    if kind in ['cat','fox','devil','owl','wolf']:
        c.poly(0,[(4,13),(4,3),(11,10)]);c.poly(0,[(17,10),(24,3),(24,13)])
    if kind in ['rabbit','dog']:
        c.oval(0,7,7,3,7);c.oval(0,21,7,3,7)
    if kind in ['bear','panda','mouse','lion','koala']:
        c.oval(0,5,8,4,4);c.oval(0,23,8,4,4)
    if kind=='reindeer':
        c.colors[0]='#cba775'
        for x,sign in [(6,-1),(22,1)]:
            c.line(7,[(x,10),(x,2)],2.5);c.line(7,[(x,6),(x+sign*4,3)],2.5)
    if kind=='lion': c.ring(3,14,17,13,14,4)
    if kind=='vampire': c.poly(4,[(4,9),(7,4),(21,4),(24,9),(14,13)])
    if kind=='zombie': c.rect(1,6,6,18,10)
    eye=4 if kind not in ['skull','devil','zombie'] else 3
    c.oval(eye,9,15,2.5,2);c.oval(eye,19,15,2.5,2)
    c.oval(5,14,21,3,2)
    if kind=='vampire': c.poly(6,[(9,23),(12,23),(10,27)]);c.poly(6,[(16,23),(19,23),(18,27)])
    elif kind=='skull': c.rect(6,9,24,19,29);c.rect(4,10,25,11,27);c.rect(4,17,25,18,27)
    elif kind=='fox': c.poly(6,[(4,20),(11,22),(14,27),(17,22),(24,20),(20,28),(8,28)])
    elif kind=='panda': c.oval(4,9,15,4,4);c.oval(4,19,15,4,4);c.oval(6,9,15,1.5,1.5);c.oval(6,19,15,1.5,1.5)
    elif kind=='owl': c.ring(3,9,15,4,4,2);c.ring(3,19,15,4,4,2);c.poly(5,[(12,21),(16,21),(14,25)])
    elif kind=='robot': c.rect(2,5,7,23,26);c.rect(4,7,13,11,17);c.rect(4,17,13,21,17);c.rect(6,9,22,19,23);c.line(3,[(14,3),(14,7)],3)
    else: c.line(6,[(9,25),(14,27),(19,25)],2)


def flower(c, kind, k):
    c.colors[0]={'sunflower':'#ffdc52','daisy':'#eff8ff','violet':'#aa79ff','orchid':'#cb83ff','aster':'#ab72fa','marigold':'#ffb34f','anemone':'#bd8dff','hyacinth':'#79b5ff','lupin':'#bb82ff'}.get(kind,c.colors[0])
    c.line(1,[(14,14),(14,30)],3)
    c.poly(1,[(13,25),(5,19),(6,25),(13,28)])
    c.poly(1,[(15,22),(23,17),(22,23),(15,26)])
    if kind=='tulip': c.poly(0,[(5,5),(10,8),(14,3),(18,8),(23,5),(21,14),(14,19),(7,14)])
    elif kind=='rose':
        c.oval(0,14,10,9,8);c.ring(4,14,10,6,5,2);c.oval(0,14,10,2.5,2.5)
    elif kind=='lily': c.star(6,14,11,11,6);c.oval(3,14,11,3,3)
    elif kind=='lotus':
        for x,y,rx,ry in [(7,12,4,6),(21,12,4,6),(10,9,4,7),(18,9,4,7),(14,8,4,8)]: c.oval(0,x,y,rx,ry)
        c.oval(3,14,15,5,2)
    else:
        petals={'daisy':6,'sunflower':8,'poppy':4,'violet':5,'orchid':5,'hibiscus':5,'gerbera':8,'aster':7,'marigold':6,'anemone':5}.get(kind,5+k%4)
        for i in range(petals):
            a=i*math.tau/petals;c.oval(0,14+7*math.cos(a),11+7*math.sin(a),3.5,3.5)
        c.oval(3 if kind!='sunflower' else 7,14,11,4,4)
    if kind in ['lavender','hyacinth','lupin']:
        c.cut(lambda x,y:y<20)
        for y in range(5,20,3): c.oval(4 if kind=='lavender' else 0,14,y,2+(y-5)/5,2.5)
    if kind=='bouquet':
        c.poly(2,[(5,17),(23,17),(17,31),(11,31)])
        for x,y in [(7,9),(21,9),(14,5)]:c.oval(0,x,y,5,5);c.oval(3,x,y,2,2)


def scene(c, kind, k):
    c.oval(2,14,28,13,3)
    if kind in ['desert','dunes','oasis','sunset','savanna']:
        c.colors[1]='#f1a653';c.colors[2]='#ffd16e'
        c.oval(1,6+k%5,25,10,6);c.oval(3,21-k%3,27,10,5);c.oval(0,19+k%3,5+k%3,5,5)
        if kind=='oasis': c.oval(2,14,27,6,2);c.line(7,[(7,25),(9,13)],3);c.line(1,[(3,14),(9,12),(15,14)],3)
    elif kind in ['beach','island','lagoon','coast']:
        shift=k%4-1
        c.poly(3,[(3,25),(12+shift,20),(24,25),(25,29),(3,29)])
        c.line(7,[(14+shift,24),(12+shift,9)],3)
        for ex,ey in [(4,8),(8,3),(20,4),(24,10)]: c.line(1,[(ex+shift,ey),(12+shift,9)],3.5)
        c.oval(0,24,6,3,3)
    elif kind in ['waterfall','river','valley','canyon']:
        c.poly(1,[(2,5),(10,6),(12,23),(7,27),(2,25)])
        c.poly(7,[(19,4),(26,6),(26,26),(18,25),(17,11)])
        c.poly(2,[(11,4),(17,4),(16,20),(22,28),(8,29),(13,19)])
        if kind=='waterfall':c.rect(6,12,7,14,19)
    elif kind in ['forest','pinewood','snowforest']:
        for x,y,r in [(6,7+k%3,5),(21,10+k%4,6),(13+k%3,4+k%2,6)]:
            c.rect(7,x-1,y+8,x+1,29);c.poly(1,[(x,y),(x-r,y+12),(x+r,y+12)])
        if kind=='snowforest':c.poly(6,[(14,5),(10,13),(18,13)])
    elif kind in ['volcano','lava']:
        c.poly(7,[(2,29),(10,8),(19,8),(27,29)])
        c.poly(5,[(11,7),(18,7),(17,13),(20,22),(14,17),(10,23),(13,12)])
        c.oval(5,14,3,6,2)
    else:
        peaks=[(7,8+k%4),(18,3+k%6),(25,12)]
        for n,(x,y) in enumerate(peaks[:2+(k%2)]):
            p=4 if n%2 else 1
            c.poly(p,[(max(1,x-9),27),(x,y),(min(27,x+9),27)])
            c.poly(6,[(x,y),(x-3,y+7),(x,y+5),(x+3,y+7)])
        if kind in ['lake','fjord','aurora']:c.oval(2,14,29,11,2)
        if kind in ['sunrise','mountains']:c.oval(3,6,5,4,4)
        if kind=='aurora':c.line(1,[(3,3),(11,6),(19,3),(26,6)],3)
    if kind=='rainbow':
        c.cut(lambda x,y:y<25)
        for p,r in [(0,12),(3,9),(1,6)]:c.shape(p,lambda x,y,r=r:(r-2)**2<=(x-14)**2+(y-25)**2<=r*r and y<25)


def vehicle(c, kind, k):
    if kind in ['plane','jet','glider','seaplane']:
        c.poly(2,[(13,2),(16,2),(17,14),(27,20),(27,23),(17,20),(16,28),(21,31),(9,31),(12,28),(11,20),(2,23),(2,20),(11,14)])
        c.rect(4,13,9,15,16)
        if kind=='jet':c.poly(5,[(12,29),(16,29),(14,32)])
        if kind=='seaplane':c.rect(3,6,27,9,31);c.rect(3,20,27,23,31)
        if kind=='glider':c.rect(6,2,16,27,19);c.rect(4,13,23,15,29)
    elif kind in ['sailboat','ship','submarine','yacht','canoe']:
        c.poly(2,[(2,23),(27,23),(23,29),(7,29)])
        if kind=='sailboat':c.line(7,[(14,5),(14,24)],2.5);c.poly(6,[(12,6),(3,20),(12,20)]);c.poly(0,[(16,7),(25,20),(16,20)])
        elif kind=='submarine':c.oval(3,14,19,12,6);c.line(3,[(14,14),(14,6),(20,6)],3);c.oval(2,8,19,3,3);c.oval(2,20,19,3,3)
        elif kind!='canoe':c.rect(6,7,12,21,23);c.rect(0,12,7,16,12);c.rect(4,8,15,11,18);c.rect(4,17,15,20,18)
    elif kind in ['bicycle','motorbike','scooter']:
        c.ring(2,6,25,5,5,2.5);c.ring(2,22,25,5,5,2.5)
        c.line(0,[(6,25),(12,14),(18,25),(6,25),(19,14),(22,25)],2.5)
        c.line(3,[(19,14),(20,8),(25,8)],3);c.rect(4,9,12,15,14)
        if kind=='motorbike':c.poly(5,[(6,18),(18,13),(23,19),(12,22)])
        if kind=='scooter':c.rect(0,7,24,20,26);c.rect(0,20,10,22,24)
    elif kind in ['train','tram','metro']:
        c.rect(0,5,5,23,27);c.rect(2,7,9,21,16)
        c.rect(4,7,20,10,23);c.rect(4,18,20,21,23)
        c.poly(6,[(8,28),(11,28),(8,32),(5,32)]);c.poly(6,[(17,28),(20,28),(23,32),(20,32)])
        if kind=='tram':c.line(3,[(10,5),(14,1),(18,5)],2)
    elif kind in ['balloon','airship']:
        c.oval(0,14,13,10 if kind=='balloon' else 13,11 if kind=='balloon' else 6)
        c.rect(3,11,25,17,30);c.line(7,[(9,20),(12,26)],2);c.line(7,[(19,20),(16,26)],2)
        c.rect(4,12,4,16,19)
    else:
        c.oval(4,7,26,4,4);c.oval(4,22,26,4,4)
        if kind in ['truck','bus','ambulance','firetruck','camper']:
            c.rect(0,3,9,25,25);c.rect(2,5,12,11,17);c.rect(2,15,12,23,17)
            if kind=='truck':c.rect(3,13,7,26,22)
            if kind=='ambulance':c.rect(6,14,18,22,20);c.rect(6,17,15,19,23)
            if kind=='firetruck':c.line(6,[(6,8),(23,8)],3);c.rect(3,18,3,22,7)
            if kind=='camper':c.rect(3,16,19,22,25)
        else:
            roof=9+k%4
            c.poly(0,[(2,20),(6,18),(9,roof),(19,roof),(23,18),(27,21),(26,26),(2,26)])
            c.poly(2,[(9,roof+2),(18,roof+2),(21,18),(6,18)])
            c.rect(3,3,21,6,23);c.rect(3,24,21,26,23)
            if kind=='racecar':c.rect(6,18,9,26,11);c.rect(6,12,19,15,25)
            if kind=='taxi':c.rect(3,11,roof-3,17,roof)
            if kind=='police':c.rect(2,10,roof-3,14,roof);c.rect(0,15,roof-3,19,roof)
            if kind=='tractor':c.oval(4,22,25,5,5);c.rect(1,15,8,23,19);c.line(7,[(9,17),(9,9)],3)


def device(c, kind, k):
    if kind in ['monitor','tv','laptop','tablet','phone','camera','console','calculator','radio','printer','scanner']:
        a,b,d,e=(3,6,25,22) if kind not in ['phone','tablet','calculator'] else (7,3,21,29)
        c.rect(4,a,b,d,e);c.rect(2,a+2,b+3,d-2,e-3)
        if kind in ['monitor','tv']:c.rect(4,12,22,16,28);c.rect(4,7,28,21,30);c.line(1,[(7,17),(11,13),(16,16),(22,10)],2.5)
        elif kind=='laptop':c.poly(6,[(3,23),(25,23),(28,29),(1,29)]);c.rect(4,11,26,18,27)
        elif kind=='phone':c.rect(6,12,5,16,6);glyph(c,k%20,14,17,6)
        elif kind=='tablet':glyph(c,k%20,14,16,6);c.oval(6,14,27,1.5,1.5)
        elif kind=='camera':c.rect(4,8,3,16,7);c.ring(6,14,15,6,6,2.5);c.oval(0,14,15,3,3);c.rect(3,21,8,24,10)
        elif kind=='calculator':
            c.rect(1,9,7,19,12)
            for y in [16,21,26]:
                for x in [10,15,20]:c.rect(6,x-1,y-1,x+1,y+1)
        elif kind=='radio':c.ring(6,10,15,5,5,2);c.rect(3,18,10,22,12);c.rect(0,19,17,22,19);c.line(6,[(23,6),(26,1)],2)
        elif kind in ['printer','scanner']:c.rect(6,7,2,21,12);c.rect(6,7,20,21,30);c.rect(4,8,24,20,25);c.rect(4,8,28,20,29)
        elif kind=='console':c.rect(6,7,12,13,14);c.rect(6,9,10,11,16);c.oval(0,20,13,2,2)
    elif kind in ['keyboard','synth']:
        c.poly(4,[(3,9),(25,9),(27,25),(1,25)])
        for y in [12,17,22]:
            for x in range(5,25,4):c.rect(6,x,y,x+2,y+2)
        if kind=='synth':c.rect(0,4,5,24,9)
    elif kind in ['mouse','remote']:
        c.oval(2,14,18,8,12);c.line(6,[(14,6),(14,17)],2);c.rect(4,13,10,15,14)
        if kind=='remote':
            for x,y in [(10,19),(18,19),(10,25),(18,25)]:c.oval(0,x,y,2,2)
    elif kind in ['headset','headphones']:
        c.shape(4,lambda x,y:8**2<=(x-14)**2+(y-15)**2<=12**2 and y<19)
        c.rect(0,2,15,7,27);c.rect(0,21,15,26,27)
        if kind=='headset':c.line(6,[(24,25),(20,30),(15,30)],2.5)
    elif kind in ['speaker','server','tower','router','harddisk']:
        c.rect(4,7,3,21,30)
        if kind=='speaker':c.ring(2,14,21,5,5,2);c.oval(0,14,9,3,3)
        elif kind=='router':c.rect(2,4,17,24,28);c.line(6,[(8,17),(6,2)],3);c.line(6,[(20,17),(23,2)],3);c.rect(1,9,23,18,24)
        elif kind=='harddisk':c.oval(6,14,15,6,7);c.line(0,[(19,25),(12,15)],3)
        else:
            for y in range(7,26,5):c.rect(2,9,y,19,y+2)
            if kind=='tower':c.rect(0,11,24,17,27)
    elif kind in ['chip','gpu','motherboard','circuit']:
        c.rect(1,4,6,24,26);c.rect(4,9,11,19,21)
        for x in range(6,25,4):c.line(3,[(x,3),(x,10)],2);c.line(3,[(x,22),(x,30)],2)
        if kind=='gpu':c.ring(6,14,16,5,5,2);c.rect(4,25,9,27,26)
        if kind=='motherboard':c.rect(2,5,7,8,18);c.rect(3,20,8,23,13)
        if kind=='circuit':c.line(2,[(1,16),(9,16),(9,26),(22,26),(22,31)],2)
    elif kind in ['usb','flash','battery','floppy','sdcard']:
        c.rect(4,8,10,20,29);c.rect(6,10,3,18,10)
        if kind=='floppy':c.rect(0,5,4,23,28);c.rect(6,10,4,20,11);c.rect(6,9,20,20,28)
        elif kind=='battery':c.rect(1,10,15,18,24);c.rect(6,12,8,16,12)
        elif kind=='sdcard':c.poly(0,[(8,10),(14,4),(22,4),(22,29),(8,29)]);c.rect(3,12,8,19,11)
        else:c.rect(0,11,15,17,22)
    elif kind=='webcam':c.rect(4,11,20,17,27);c.rect(4,7,27,21,30);c.oval(2,14,12,11,8);c.ring(6,14,12,5,5,2)
    else:object_shape(c,kind,k)


def glyph(c, k, x=14, y=16, r=8, p=3):
    if k%20==0:c.oval(p,x,y,r,r);c.oval(0,x,y,3,3)
    elif k%20==1:c.star(p,x,y,r,5)
    elif k%20==2:c.poly(p,[(x-r,y-r),(x+r,y),(x-r,y+r)])
    elif k%20==3:c.line(p,[(x-r,y+3),(x-r/2,y-4),(x+r/2,y+4),(x+r,y-3)],3)
    elif k%20==4:c.rect(p,x-r,y-5,x+r,y+5);c.poly(0,[(x-r,y-5),(x,y+1),(x+r,y-5)])
    elif k%20==5:c.ring(p,x,y,r,r,3);c.line(0,[(x,y-r+2),(x,y),(x+r-2,y)],2)
    elif k%20==6:c.oval(p,x-3,y-3,5,4);c.oval(p,x+3,y-3,5,4);c.poly(p,[(x-r,y-2),(x+r,y-2),(x,y+r)])
    elif k%20==7:c.line(p,[(x-3,y-r),(x-3,y+r),(x+4,y+r),(x+4,y-r+2)],3);c.oval(p,x-5,y+r,3,2)
    elif k%20==8:c.ring(p,x,y,r,r,3);c.line(0,[(x-5,y+4),(x+5,y-4)],3)
    elif k%20==9:c.rect(p,x-r,y-4,x+r,y+4);c.rect(0,x-2,y-r,x+2,y+r)
    elif k%20==10:c.poly(p,[(x,y-r),(x+r,y),(x,y+r),(x-r,y)]);c.oval(0,x,y,2.5,2.5)
    elif k%20==11:c.oval(p,x,y-3,r,5);c.poly(p,[(x-r,y-3),(x+r,y-3),(x,y+r)])
    elif k%20==12:c.rect(p,x-6,y-6,x+6,y+6);c.rect(0,x-3,y-2,x+3,y+3);c.rect(6,x-6,y-7,x+6,y-4)
    elif k%20==13:c.poly(p,[(x-r,y+4),(x,y-r),(x+r,y+4)]);c.rect(0,x-3,y+4,x+3,y+r)
    elif k%20==14:c.line(p,[(x-7,y+6),(x-7,y-5),(x+7,y-5),(x+7,y+6)],3);c.oval(0,x,y,3,3)
    elif k%20==15:c.poly(p,[(x-r,y-r),(x+r,y-r),(x+4,y+2),(x,y+r),(x-4,y+2)])
    elif k%20==16:c.rect(p,x-7,y-5,x+7,y+6);c.ring(0,x,y,4,4,2)
    elif k%20==17:c.line(p,[(x-r,y+4),(x-r/2,y-5),(x,y+1),(x+r/2,y-5),(x+r,y+4)],3)
    elif k%20==18:c.rect(p,x-6,y-6,x+6,y+6);c.line(0,[(x-6,y-6),(x+6,y+6)],3)
    else:c.star(p,x,y,r,6);c.rect(0,x-2,y-4,x+2,y+4)


def object_shape(c, kind, k):
    c.colors[0]={'pumpkin':'#ff9b35','orange':'#ff9b35','lemon':'#ffed4c','pear':'#d9ee57','pineapple':'#ffd34e','avocado':'#63df86','kiwi':'#70e998','mango':'#ffb449','peach':'#ffa092','plum':'#ae78ed','coconut':'#bd9465'}.get(kind,c.colors[0])
    if kind in ['footprints','snowglobe','egg_star','horse','melonslice']:
        if kind=='footprints':
            c.oval(6,8,21,4,7);c.oval(6,21,13,4,7)
            for x,y in [(5,11),(10,10),(19,3),(24,3)]:c.oval(6,x,y,1.5,2)
        elif kind=='snowglobe':
            c.ring(2,14,14,12,12,2.5);c.poly(1,[(14,5),(7,20),(21,20)]);c.rect(7,12,20,16,24);c.poly(4,[(8,25),(20,25),(24,31),(4,31)])
        elif kind=='egg_star':c.oval(0,14,20,9,10);c.oval(0,14,12,6,8);c.rect(2,6,18,22,22);c.star(3,14,14,5,5)
        elif kind=='melonslice':
            c.poly(1,[(2,6),(26,6),(14,30)]);c.poly(0,[(5,8),(23,8),(14,26)])
            for x,y in [(10,12),(18,12),(14,20)]:c.rect(7,x,y,x+1,y+2)
        else:
            c.oval(7,13,18,8,5);c.line(7,[(19,17),(20,6)],5);c.oval(7,20,6,5,4);c.poly(7,[(20,5),(20,1),(24,5)]);c.line(7,[(6,19),(5,10)],3)
            c.line(7,[(9,21),(7,28)],3);c.line(7,[(17,21),(20,28)],3);c.line(2,[(2,27),(7,31),(20,31),(27,27)],3)
        return
    if kind in ['angel','bell','rocket','kite','candy','sun']:
        if kind=='angel':
            c.poly(6,[(12,12),(3,6),(1,16),(9,21),(14,18),(19,21),(27,16),(25,6),(16,12)])
            c.poly(3,[(12,13),(16,13),(23,30),(5,30)]);c.oval(6,14,9,4,4);c.ring(3,14,3,5,2.5,1.5)
        elif kind=='bell':c.poly(3,[(9,7),(19,7),(22,22),(26,25),(2,25),(6,22)]);c.oval(3,14,7,5,4);c.oval(0,14,28,3,3);c.rect(6,7,21,21,23)
        elif kind=='rocket':c.poly(2,[(14,2),(19,9),(19,25),(9,25),(9,9)]);c.poly(0,[(9,18),(3,27),(9,26)]);c.poly(0,[(19,18),(25,27),(19,26)]);c.oval(4,14,12,3,3);c.poly(3,[(10,26),(18,26),(14,32)])
        elif kind=='kite':c.poly(0,[(14,2),(25,13),(14,24),(3,13)]);c.line(3,[(14,3),(14,24),(21,28),(15,31)],2);c.line(2,[(4,13),(24,13)],2)
        elif kind=='candy':c.poly(3,[(6,11),(1,7),(1,23),(6,20)]);c.poly(3,[(22,11),(27,7),(27,23),(22,20)]);c.oval(0,14,16,9,7);c.rect(6,12,10,15,22)
        else:
            for a in range(8):
                angle=a*math.tau/8;c.line(3,[(14+9*math.cos(angle),16+9*math.sin(angle)),(14+13*math.cos(angle),16+13*math.sin(angle))],2.5)
            c.oval(3,14,16,7,7)
        return
    if kind in ['pumpkin','basket','egg','bauble','melon','orange','pear','pineapple','grapes','lemon','avocado','peach','plum','mango','coconut','kiwi']:
        if kind in ['egg','pear','avocado']:c.oval(0,14,21,9,10);c.oval(0,14,12,5,8)
        else:c.oval(0,14,19,11,10)
        if kind in ['egg','bauble']:c.rect(3,5,15,23,18);c.rect(2,6,23,22,25)
        elif kind=='pumpkin':c.rect(7,12,4,16,10);c.poly(3,[(6,15),(11,15),(9,19)]);c.poly(3,[(17,15),(22,15),(19,19)]);c.line(3,[(8,24),(14,26),(20,24)],3)
        elif kind=='basket':c.ring(7,14,13,10,9,3);c.rect(7,5,15,23,28);c.rect(3,6,20,22,22)
        elif kind=='pineapple':c.poly(1,[(6,9),(8,2),(13,6),(15,1),(18,6),(23,3),(21,10)]);c.line(3,[(6,17),(21,24)],3);c.line(3,[(8,26),(22,16)],3)
        elif kind=='grapes':
            c.cut(lambda x,y:True)
            for x,y in [(8,11),(16,11),(21,17),(11,19),(16,26)]:c.oval(4,x,y,5,5)
            c.poly(1,[(11,5),(21,2),(24,7),(17,9)])
        elif kind in ['avocado','kiwi','coconut']:c.oval(3 if kind=='avocado' else 6,14,19,7,8);c.oval(7,14,21,4,4)
        elif kind in ['lemon','orange','melon']:c.ring(3,14,19,8,7,2);c.line(3,[(7,18),(21,18)],2)
        else:c.line(7,[(14,10),(16,3)],3);c.poly(1,[(16,5),(24,4),(20,9),(15,8)])
        if kind=='bauble':c.rect(7,11,7,17,11);c.ring(3,14,4,3,3,2)
    elif kind in ['ghost','jellyfish']:
        c.oval(6 if kind=='ghost' else 4,14,13,9,10)
        c.poly(6 if kind=='ghost' else 4,[(5,12),(23,12),(24,29),(20,25),(16,29),(12,25),(8,29),(4,26)])
        c.oval(0,10,13,2,3);c.oval(0,18,13,2,3)
        if kind=='jellyfish':c.cut(lambda x,y:y>21);c.line(2,[(7,21),(5,28),(8,31)],3);c.line(2,[(14,21),(14,30)],3);c.line(2,[(21,21),(23,28),(20,31)],3)
    elif kind in ['bat','butterfly','dragonfly','bee']:
        c.poly(4,[(13,13),(5,5),(1,8),(3,20),(9,18),(12,24),(14,21),(16,24),(19,18),(25,20),(27,8),(23,5),(15,13)])
        c.rect(0,12,10,16,27)
        if kind=='butterfly':c.oval(0,7,12,5,6);c.oval(2,21,12,5,6);c.oval(3,8,24,4,4);c.oval(1,20,24,4,4)
        if kind=='bee':c.oval(3,14,18,6,10);c.rect(4,9,14,19,16);c.rect(4,9,21,19,23);c.oval(6,6,11,5,6);c.oval(6,22,11,5,6)
        if kind=='dragonfly':c.line(2,[(3,10),(25,18)],4);c.line(2,[(3,18),(25,10)],4);c.rect(1,13,5,15,29)
    elif kind in ['spider','web','snowflake']:
        p=6 if kind=='snowflake' else 4
        for a in range(6 if kind=='snowflake' else 8):
            ang=a*math.tau/(6 if kind=='snowflake' else 8);c.line(p,[(14,16),(14+12*math.cos(ang),16+12*math.sin(ang))],2.7)
        if kind=='spider':c.oval(0,14,17,5,7)
        else:c.ring(p,14,16,8,8,2);c.ring(p,14,16,4,4,2)
    elif kind in ['hat','witchhat','santahat','helmet','cap','crown']:
        if kind=='crown':c.poly(3,[(3,9),(9,14),(14,3),(19,14),(25,9),(22,28),(6,28)]);c.rect(0,6,22,22,25)
        else:
            c.poly(4 if kind=='witchhat' else 0,[(4,26),(10,8),(16,2),(21,26)])
            c.rect(3 if kind=='witchhat' else 6,3,24,25,29)
            if kind=='santahat':c.oval(6,18,4,4,4)
            if kind=='hat':c.rect(4,8,10,21,24)
            if kind in ['helmet','cap']:c.oval(2,14,18,11,10);c.rect(4,3,24,25,27)
    elif kind in ['gift','book','notebook','letter','map','backpack','suitcase','treasure','lunchbox']:
        c.rect(0,5,8,23,29)
        if kind=='gift':c.rect(3,3,7,25,11);c.rect(3,12,7,16,29);c.ring(3,10,5,4,3,2);c.ring(3,18,5,4,3,2)
        elif kind in ['book','notebook']:c.rect(6,7,9,10,27);c.rect(3,13,13,20,15);c.rect(3,13,21,20,23)
        elif kind in ['backpack','suitcase']:c.ring(7,14,7,5,4,2);c.rect(4,8,18,20,27);c.rect(3,11,21,17,23)
        elif kind=='treasure':c.poly(7,[(5,8),(8,4),(20,4),(23,8),(23,14),(5,14)]);c.rect(3,6,13,22,16);c.rect(3,12,14,16,22)
        elif kind=='map':c.rect(6,5,8,23,29);c.line(1,[(7,25),(12,18),(10,12),(20,10)],3);c.star(0,20,10,4,4)
        elif kind=='letter':c.poly(6,[(5,8),(14,19),(23,8)]);c.line(3,[(5,29),(14,20),(23,29)],2)
        else:c.rect(6,8,13,20,24)
    elif kind in ['tree','fir','christmastree','bonsai']:
        c.rect(7,12,20,16,31)
        if kind=='bonsai':c.oval(1,9,10,7,5);c.oval(1,21,16,6,5);c.line(7,[(14,28),(12,13)],4);c.poly(0,[(5,27),(23,27),(20,31),(8,31)])
        else:
            for y,r in [(3,7),(10,9),(17,11)]:c.poly(1,[(14,y),(14-r,y+11),(14+r,y+11)])
            if kind=='christmastree':
                c.star(3,14,4,4,5)
                for x,y in [(9,17),(18,20),(14,25)]:c.oval(0,x,y,2,2)
                c.line(3,[(8,14),(20,19),(6,24)],2)
    elif kind in ['candle','lantern','lamp','torch','lighthouse']:
        c.rect(3,10,13,18,29)
        if kind in ['candle','torch']:c.oval(5,14,7,4,6);c.oval(3,14,8,2,3)
        elif kind=='lantern':c.rect(7,6,8,22,27);c.rect(3,9,11,19,24);c.poly(4,[(4,8),(14,2),(24,8)]);c.rect(4,5,28,23,30)
        elif kind=='lamp':c.poly(0,[(9,5),(19,5),(25,17),(3,17)]);c.rect(4,6,29,22,31)
        else:c.poly(6,[(10,9),(18,9),(21,29),(7,29)]);c.rect(0,8,20,20,23);c.poly(0,[(7,9),(14,3),(21,9)]);c.rect(3,11,9,17,12)
    elif kind in ['snowman','penguin','doll','robotbody']:
        c.oval(6 if kind!='penguin' else 4,14,23,9,8);c.oval(6 if kind!='penguin' else 4,14,11,6,7)
        c.rect(0,8,15,20,18);c.rect(0,18,17,20,25)
        c.oval(4,11,10,1.5,1.5);c.oval(4,17,10,1.5,1.5);c.poly(5,[(12,13),(19,13),(12,15)])
        if kind=='snowman':c.rect(4,8,3,20,6);c.rect(4,10,1,18,4);c.line(7,[(5,22),(1,17)],3);c.line(7,[(23,22),(27,17)],3)
        elif kind=='penguin':c.oval(6,14,23,5,6);c.oval(5,9,30,4,2);c.oval(5,19,30,4,2)
        elif kind=='robotbody':c.rect(2,8,14,20,28);c.rect(3,11,18,17,22);c.rect(4,4,18,7,25);c.rect(4,21,18,24,25)
        else:c.oval(0,14,23,8,6)
    elif kind in ['cup','mug','glass','bottle','teapot','perfume','vase','flask']:
        if kind in ['bottle','perfume','flask']:c.poly(2,[(11,3),(17,3),(17,12),(23,16),(23,29),(5,29),(5,16),(11,12)]);c.rect(4,10,2,18,5);c.rect(0,8,18,20,25)
        elif kind=='glass':c.poly(2,[(5,5),(23,5),(19,29),(9,29)]);c.poly(0,[(7,14),(21,14),(18,27),(10,27)])
        elif kind=='vase':c.poly(2,[(9,6),(19,6),(17,12),(22,21),(20,29),(8,29),(6,21),(11,12)]);c.rect(0,8,21,20,24)
        else:
            c.ring(2,22,18,5,6,2.5);c.rect(2,5,10,20,26);c.oval(2,12,26,7,3);c.oval(7,12,10,7,2)
            if kind=='teapot':c.oval(0,13,18,9,9);c.poly(0,[(5,17),(1,10),(7,12)]);c.rect(3,9,7,17,10)
            elif kind=='cup':c.rect(3,7,15,18,18)
            else:c.line(6,[(8,6),(10,2)],2);c.line(6,[(16,6),(18,2)],2)
    elif kind in ['cookie','pizza','donut','cake','bread','burger','sandwich','waffle','pancakes','pretzel']:
        if kind in ['cookie','pizza','donut','waffle']:c.oval(3,14,17,12,12)
        elif kind=='cake':c.rect(0,4,16,24,29);c.rect(6,4,16,24,19);c.rect(3,7,9,21,16);c.line(0,[(14,4),(14,10)],3)
        elif kind in ['burger','sandwich','pancakes']:c.oval(3,14,11,11,6);c.rect(1,3,16,25,19);c.rect(7,3,20,25,23);c.oval(3,14,27,11,4)
        elif kind=='pretzel':c.ring(7,8,16,6,9,3);c.ring(7,20,16,6,9,3);c.line(7,[(5,25),(22,12),(23,25),(6,12)],3)
        else:c.oval(3,14,18,12,9);c.line(6,[(7,13),(10,19)],3);c.line(6,[(14,11),(17,17)],3);c.line(6,[(20,13),(22,18)],3)
        if kind=='donut':c.oval(0,14,17,9,9);c.cut(lambda x,y:(x-14)**2+(y-17)**2<3.5**2)
        elif kind=='pancakes':c.colors[1]='#ffe18b';c.colors[7]='#cf985e';c.rect(6,11,6,17,9)
        elif kind=='sandwich':
            c.cut(lambda x,y:True);c.poly(3,[(2,6),(26,6),(26,30)]);c.line(1,[(8,9),(23,23)],3);c.line(7,[(12,9),(23,19)],3)
        elif kind=='pizza':
            for x,y in [(9,10),(21,16),(12,23)]:c.oval(0,x,y,2.5,2.5)
        elif kind=='cookie':
            for x,y in [(8,14),(17,9),(21,23),(11,24)]:c.oval(7,x,y,2,2)
        elif kind=='waffle':
            for a in [8,14,20]:c.line(7,[(a,8),(a,26)],2);c.line(7,[(5,a+3),(23,a+3)],2)
    elif kind in ['key','sword','wand','hammer','wrench','screwdriver','brush','broom','spoon','fork','shovel','rake']:
        c.line(7 if kind in ['broom','brush','shovel','rake'] else 2,[(14,5),(14,30)],3.5)
        if kind=='key':c.ring(3,14,8,7,7,3);c.rect(3,14,23,21,26);c.rect(3,14,29,19,31)
        elif kind in ['sword','wand']:c.poly(6,[(14,1),(18,7),(16,23),(12,23),(10,7)]);c.rect(3,7,23,21,26);c.rect(4,12,27,16,31)
        elif kind=='hammer':c.rect(2,4,5,24,12);c.rect(4,12,20,16,30)
        elif kind=='wrench':c.oval(2,14,8,8,7);c.cut(lambda x,y:10<=x<=18 and y<9);c.oval(2,14,27,4,4)
        elif kind=='screwdriver':c.rect(0,10,19,18,31);c.rect(6,12,3,16,17)
        elif kind in ['brush','broom']:c.poly(3 if kind=='broom' else 0,[(9,19),(19,19),(24,31),(4,31)]);c.rect(4,8,19,20,22)
        elif kind=='fork':c.rect(6,8,8,20,13);c.rect(6,8,2,10,13);c.rect(6,13,2,15,13);c.rect(6,18,2,20,13)
        elif kind=='rake':c.rect(2,3,5,25,8);[c.rect(2,x,5,x+1,13) for x in [3,8,13,18,23]]
        elif kind=='shovel':c.poly(2,[(7,20),(21,20),(20,28),(14,32),(8,28)])
        else:c.oval(6,14,8,7,8)
    elif kind in ['guitar','violin','banjo','ukulele']:
        c.oval(7 if kind!='banjo' else 6,14,24,9,7);c.oval(7,14,17,6,5);c.rect(7,12,3,16,19);c.rect(3,10,1,18,6);c.oval(4,14,23,3,3);c.line(6,[(14,6),(14,28)],2)
        if kind=='violin':c.cut(lambda x,y:y in range(19,22) and (x<9 or x>19));c.line(6,[(25,4),(22,29)],2)
        if kind=='banjo':c.ring(3,14,23,7,7,2)
        if kind=='ukulele':c.rect(0,7,26,21,28)
    elif kind in ['drum','tambourine','maracas','trumpet','saxophone','flute','harp','microphone','musicnote']:
        if kind=='drum':c.rect(0,4,12,24,28);c.oval(6,14,12,10,4);c.line(3,[(5,5),(18,12)],3);c.line(3,[(23,5),(10,12)],3)
        elif kind=='tambourine':c.ring(7,14,17,11,11,4);[c.oval(3,x,y,3,2) for x,y in [(5,12),(23,12),(7,24),(21,24)]]
        elif kind=='maracas':c.line(7,[(8,16),(12,31)],3);c.line(7,[(21,15),(17,31)],3);c.oval(0,7,11,5,8);c.oval(3,22,10,5,8)
        elif kind=='flute':
            c.rect(6,11,2,17,30);c.rect(3,10,3,18,7)
            for y in [11,17,23]:c.oval(4,14,y,2,2)
        elif kind=='trumpet':
            c.line(3,[(2,18),(22,18)],5);c.poly(3,[(19,13),(27,8),(27,27),(19,23)])
            for x in [8,12,16]:c.rect(6,x,9,x+1,20)
        elif kind=='saxophone':c.line(3,[(7,5),(10,5),(10,25),(19,25),(23,19)],4);c.poly(3,[(17,16),(26,14),(25,24),(20,25)]);c.rect(6,7,12,16,15)
        elif kind=='harp':c.poly(7,[(4,3),(25,3),(23,8),(10,31),(5,31)]);c.cut(lambda x,y:x>9 and y>8 and x+y<31);[c.line(3,[(x,8),(x,30-x+10)],2) for x in [12,17,22]]
        elif kind=='microphone':c.line(4,[(14,20),(14,29)],3);c.rect(4,5,29,23,31);c.oval(2,14,11,6,9);c.rect(6,9,10,19,12)
        else:c.line(0,[(12,26),(12,6),(23,4),(23,23)],3);c.oval(0,8,26,5,3);c.oval(0,19,23,5,3)
    elif kind in ['fish','shark','whale','dolphin','seahorse','octopus','crab','starfish','shell','coral']:
        if kind in ['fish','shark','whale','dolphin']:
            ry={'fish':7,'shark':5,'whale':9,'dolphin':4}[kind]
            c.oval(2,12,18,10,ry);c.poly(4,[(21,18),(28,9),(28,27)]);c.oval(6,7,16,2,2)
            if kind!='whale':c.poly(2,[(9,12),(15,5),(17,13)])
            else:c.line(6,[(9,8),(9,2),(4,3)],2.5);c.line(6,[(9,2),(14,3)],2.5)
            if kind=='shark':c.poly(6,[(3,20),(11,20),(7,23)])
            if kind=='dolphin':c.rect(2,1,16,7,19)
        elif kind=='seahorse':c.oval(3,15,16,5,9);c.oval(3,15,6,5,4);c.rect(3,6,5,13,8);c.ring(3,12,26,5,5,2.5);c.poly(4,[(20,13),(26,16),(20,20)])
        elif kind=='octopus':
            c.oval(4,14,11,8,9)
            for x in [4,9,19,24]:c.line(4,[(14,16),(x,24),(x+(-2 if x<14 else 2),29)],3)
            c.oval(6,10,11,2,2);c.oval(6,18,11,2,2)
        elif kind=='crab':c.oval(0,14,20,8,6);c.line(0,[(7,20),(3,12)],3);c.line(0,[(21,20),(25,12)],3);c.ring(0,4,8,4,4,2);c.ring(0,24,8,4,4,2);c.line(3,[(5,28),(9,24),(19,24),(23,28)],3)
        elif kind=='starfish':c.star(5,14,17,13,5);c.oval(3,14,17,3,3)
        elif kind=='shell':c.poly(0,[(4,10),(9,4),(19,4),(24,10),(22,23),(14,30),(6,23)]);[c.line(3,[(x,8),(14,27)],2) for x in [7,14,21]]
        else:
            c.line(0,[(14,30),(14,4)],4)
            for y in [10,19,26]:c.line(0,[(4,y-5),(4,y),(14,y+3),(24,y),(24,y-5)],3)
    elif kind in ['bird','duck','swan','flamingo','parrot','toucan','eagle','robin','peacock','hen','chick','goose','heron','woodpecker','pigeon','sparrow','hummingbird','ostrich','stork']:
        specs={'duck':(20,13,11,23,10,7),'swan':(22,7,11,23,10,6),'flamingo':(20,6,12,20,8,5),'parrot':(20,8,11,22,8,9),'toucan':(19,9,13,22,8,8),'eagle':(17,10,13,22,8,7),'robin':(20,11,13,23,8,7),'hen':(20,13,12,23,10,7),'chick':(17,14,13,24,8,6),'goose':(19,9,11,22,10,7),'heron':(20,6,12,20,8,7),'woodpecker':(21,7,13,22,6,8),'pigeon':(19,10,13,22,8,8),'sparrow':(19,12,14,23,8,6),'hummingbird':(20,12,13,23,7,4),'ostrich':(20,9,12,22,11,7),'stork':(22,6,11,19,9,6),'bird':(20,10,11,22,8,7)}
        hx,hy,bx,by,rx,ry=specs.get(kind,(20,7,12,21,9,7))
        c.colors[0]={'duck':'#64dd8a','swan':'#f1f8ff','chick':'#ffe36b','hen':'#e9b377','goose':'#d7e9ff','heron':'#a7c9dc','stork':'#f0f7ff','pigeon':'#b8b5e0','sparrow':'#c5a375','robin':'#eea368','parrot':'#65ed92','toucan':'#a097df','eagle':'#d6ad7b','woodpecker':'#e6eaf7','ostrich':'#d3c8b5','bird':'#65baff','hummingbird':'#69e6bd'}.get(kind,c.colors[0])
        if kind in ['swan','duck','goose']:c.colors[2]='#f0f6ff' if kind=='swan' else '#c1b38a'
        c.oval(2 if kind in ['swan','duck','goose'] else 0,bx,by,rx,ry)
        c.line(0,[(bx+5,by),(hx,hy+1)],4)
        if kind=='swan':c.line(0,[(16,22),(23,17),(19,12),(hx,hy)],3.5)
        c.oval(0,hx,hy,4 if kind in ['chick','sparrow'] else 5,4)
        c.poly(3,[(min(25,hx+3),hy-1),(28,hy+2),(min(25,hx+3),hy+3)])
        c.oval(6,hx,hy-1,1.5,1.5)
        c.poly(4,[(bx-rx+2,by-3),(bx+5,by),(bx-2,by+4)])
        c.line(7,[(bx-2,by+ry-1),(bx-3,31)],2.5);c.line(7,[(bx+4,by+ry-1),(bx+6,31)],2.5)
        if kind in ['flamingo','stork','heron','ostrich']:c.cut(lambda x,y:y>25);c.line(7,[(10,25),(8,32)],2);c.line(7,[(17,25),(20,32)],2)
        if kind in ['eagle','hummingbird']:c.poly(4,[(10,19),(3,4),(13,12),(18,20)]);c.poly(4,[(15,19),(22,5),(26,15),(19,22)])
        if kind=='peacock':c.oval(1,12,15,11,12);c.rect(2,11,6,14,26);c.oval(2,15,6,4,4);[c.oval(3,x,y,2,3) for x,y in [(5,10),(21,10),(7,20),(19,20)]]
        if kind=='toucan':c.poly(3,[(23,4),(28,8),(25,13),(21,11)])
        if kind in ['hen','rooster']:c.oval(0,20,3,4,2)
    elif kind in ['football','basketball','volleyball','tennisball','baseball','bowling','globe','compass','clock']:
        c.oval(3 if kind=='basketball' else 2,14,17,12,12)
        if kind=='football':c.poly(4,[(10,12),(17,11),(20,18),(14,23),(8,18)]);c.rect(4,3,12,5,18);c.rect(4,23,16,25,23)
        elif kind in ['basketball','volleyball','baseball']:c.line(4,[(2,17),(26,17)],2);c.line(4,[(14,5),(14,29)],2);c.line(4,[(6,8),(10,16),(6,26)],2)
        elif kind=='tennisball':c.line(6,[(5,8),(9,15),(8,23),(5,27)],2.5);c.line(6,[(22,8),(19,15),(20,23),(24,27)],2.5)
        elif kind=='bowling':c.oval(4,10,10,2,2);c.oval(4,17,10,2,2);c.oval(4,14,16,2,2)
        elif kind=='globe':c.poly(1,[(8,8),(15,6),(17,13),(12,17),(7,14)]);c.poly(1,[(18,19),(25,16),(23,25),(17,27)])
        elif kind=='compass':c.poly(0,[(14,7),(19,20),(14,17),(9,27)]);c.poly(6,[(14,27),(9,14),(14,17),(19,7)])
        else:c.line(6,[(14,7),(14,17),(22,21)],3);c.ring(4,14,17,12,12,2)
    elif kind in ['castle','house','church','palace','pagoda','igloo','tent','cabin','windmill','skyscraper','bridge']:
        if kind=='tent':c.poly(0,[(2,30),(14,4),(27,30)]);c.poly(3,[(8,30),(14,14),(21,30)])
        elif kind=='igloo':c.shape(6,lambda x,y:((x-14)/12)**2+((y-28)/15)**2<=1 and y<30);c.rect(2,11,23,17,30);c.line(2,[(4,21),(24,21)],2)
        elif kind=='bridge':c.rect(7,2,7,26,10);c.rect(7,4,10,7,29);c.rect(7,22,10,25,29);c.line(2,[(3,28),(25,28)],3);c.rect(3,11,10,17,14)
        elif kind=='windmill':c.poly(2,[(10,10),(18,10),(22,30),(6,30)]);c.line(3,[(4,4),(24,24)],3);c.line(3,[(24,4),(4,24)],3)
        else:
            c.rect(2,5,13,23,30);c.poly(0,[(2,13),(14,3),(26,13)]);c.rect(3,11,23,17,30)
            c.rect(6,7,17,10,20);c.rect(6,18,17,21,20)
            if kind in ['castle','palace']:c.rect(4,2,6,7,30);c.rect(4,21,6,26,30);c.rect(3,2,3,4,8);c.rect(3,24,3,26,8)
            if kind=='church':c.rect(4,12,3,16,16);c.rect(3,13,1,15,9);c.rect(3,10,3,18,5)
            if kind=='pagoda':c.poly(0,[(1,10),(14,5),(27,10)]);c.poly(0,[(3,20),(14,15),(25,20)])
            if kind=='skyscraper':c.rect(4,8,3,20,30);c.rect(3,13,1,15,4);[c.rect(2,11,y,17,y+2) for y in [7,13,19,25]]
    elif kind in ['trophy','medal','dumbbell','boxing','skate','ski','sled','snowboard','racket','skateboard']:
        if kind=='trophy':c.poly(3,[(7,5),(21,5),(20,19),(14,23),(8,19)]);c.ring(3,6,11,4,5,2);c.ring(3,22,11,4,5,2);c.rect(3,12,22,16,28);c.rect(7,7,28,21,31)
        elif kind=='medal':c.poly(0,[(5,2),(11,2),(17,17),(12,19)]);c.poly(2,[(17,2),(23,2),(16,19),(11,17)]);c.oval(3,14,23,8,8);c.star(6,14,23,4,5)
        elif kind=='dumbbell':c.rect(6,4,14,24,18);c.rect(4,3,8,7,25);c.rect(4,21,8,25,25)
        elif kind=='boxing':c.oval(0,14,13,9,10);c.oval(0,6,18,4,6);c.rect(4,9,24,20,30);c.rect(6,9,25,20,27)
        elif kind=='ski':c.oval(2,9,16,4,15);c.oval(0,20,17,4,14);c.rect(4,7,13,11,19);c.rect(4,18,14,22,20)
        elif kind=='snowboard':c.oval(2,14,16,6,15);c.rect(4,10,8,18,11);c.rect(4,10,22,18,25);c.line(0,[(11,3),(16,16),(12,29)],2.5)
        elif kind=='skateboard':c.oval(2,14,15,13,4);c.oval(4,7,24,3,3);c.oval(4,22,24,3,3);c.line(6,[(7,18),(7,23)],2);c.line(6,[(22,18),(22,23)],2);c.rect(0,9,13,19,17)
        elif kind=='sled':c.rect(7,5,13,24,17);c.line(0,[(7,17),(9,26),(22,26),(23,17)],3);c.line(6,[(2,27),(5,30),(25,30),(27,27),(27,23)],3);c.line(3,[(4,12),(6,6),(21,6)],3)
        elif kind=='racket':c.ring(1,14,11,9,10,3);c.line(4,[(14,20),(14,31)],4);c.line(2,[(7,11),(21,11)],2)
        else:c.poly(0,[(6,7),(15,7),(15,19),(24,22),(25,27),(5,27)]);c.line(6,[(4,31),(25,31)],3);c.line(6,[(9,26),(9,31)],2);c.line(6,[(21,26),(21,31)],2)
    else:
        # Emblem recipes below use distinct internal geometry, never recolors.
        c.oval(4,14,17,12,13)
        glyph(c,k,14,17,9,3)


def skyline(c,k):
    heights=[10+(k*7+i*5)%17 for i in range(5)]
    for i,h in enumerate(heights):
        x=1+i*5;p=[2,4,0,1,5][i]
        c.rect(p,x,32-h,x+4,29)
        for y in range(34-h,27,5):c.rect(3,x+1,y,x+2,y+1)
    center=1+(k%5)*5
    if k%4==0:c.poly(6,[(center,32-heights[k%5]),(center+2,27-heights[k%5]),(center+4,32-heights[k%5])])
    elif k%4==1:c.line(6,[(center+2,32-heights[k%5]),(center+2,26-heights[k%5])],2)
    elif k%4==2:c.oval(6,center+2,30-heights[k%5],2.5,3)
    else:c.rect(6,center,29-heights[k%5],center+4,32-heights[k%5])
    c.rect(2,1,30,27,31)


def compose(c,kind,k):
    if kind.startswith('face:'):face(c,kind.split(':')[1],k)
    elif kind.startswith('flower:'):flower(c,kind.split(':')[1],k)
    elif kind.startswith('scene:'):scene(c,kind.split(':')[1],k)
    elif kind.startswith('vehicle:'):vehicle(c,kind.split(':')[1],k)
    elif kind.startswith('device:'):device(c,kind.split(':')[1],k)
    elif kind=='skyline':skyline(c,k)
    elif kind=='mobile':device(c,'phone',k)
    elif kind.startswith('emblem:'):
        c.oval(4,14,17,12,13);glyph(c,int(kind.split(':')[1]),14,17,9,3)
    else:object_shape(c,kind,k)


# Each entry identifies a subject and a geometry recipe. Shared subjects receive
# structural scene/context variations, rather than new names for a recolor.
GROUPS = [
('halloween','Halloween im Neonlicht',['Halloween','Herbst'],[
('Kürbisgrinsen','pumpkin'),('Freundliches Gespenst','ghost'),('Fledermausflug','bat'),('Hexenhut','witchhat'),('Spinne im Mondlicht','spider'),('Spinnennetz','web'),('Vampirnacht','face:vampire'),('Leuchtender Totenkopf','face:skull'),('Kleine Teufelei','face:devil'),('Zombie mit Pflaster','face:zombie'),('Schwarze Katze','face:cat'),('Gruselschloss','castle'),('Hexenbesen','broom'),('Zaubertrank','bottle'),('Halloweenlaterne','lantern'),('Geisterschlüssel','key'),('Süßes Überraschungspaket','gift'),('Nachteulenblick','face:owl'),('Mystisches Auge','emblem:0'),('Zauberkristall','emblem:10')]),
('christmas','Weihnachtszauber',['Weihnachten','Winter'],[
('Geschmückter Tannenbaum','christmastree'),('Glänzende Weihnachtskugel','bauble'),('Geschenk mit Schleife','gift'),('Nikolausmütze','santahat'),('Kerzenlicht im Advent','candle'),('Lebkuchenfreude','cookie'),('Weihnachtsstern','emblem:1'),('Festliche Laterne','lantern'),('Winterengel','angel'),('Kleine Weihnachtskapelle','church'),('Weihnachtsglöckchen','bell'),('Wunschbrief','letter'),('Festlicher Kakao','mug'),('Spielzeugzug unterm Baum','vehicle:train'),('Schlittenfahrt','sled'),('Funkelnder Eiskristall','snowflake'),('Winterlicher Pinguin','penguin'),('Rentierblick','face:reindeer'),('Schneemann mit Zylinder','snowman'),('Festliche Krone','crown')]),
('winter','Winter und Eis',['Winter','Schnee'],[
('Schneemann im Frost','snowman'),('Kristallstern','snowflake'),('Winterpinguin','penguin'),('Spuren im Schnee','footprints'),('Schneebedeckte Berge','scene:mountains'),('Tannen im Schnee','scene:snowforest'),('Eisblauer Bergsee','scene:lake'),('Nordlicht über Gipfeln','scene:aurora'),('Iglu am Polarkreis','igloo'),('Winterhütte','cabin'),('Schlittschuhe','skate'),('Ski im Pulverschnee','ski'),('Buntes Snowboard','snowboard'),('Rodelspaß','sled'),('Warmer Wintertee','cup'),('Wintermütze','cap'),('Frostlaterne','lantern'),('Eisbärenblick','face:bear'),('Schneekugeltraum','snowglobe'),('Wintersonne','sun')]),
('easter','Ostern und Frühling',['Ostern','Frühling'],[
('Buntes Osterei','egg'),('Osterhase','face:rabbit'),('Osterkorb','basket'),('Kleines Küken','chick'),('Frühlingshenne','hen'),('Tulpe zu Ostern','flower:tulip'),('Narzissenlicht','flower:daisy'),('Frühlingsschmetterling','butterfly'),('Fleißige Frühlingsbiene','bee'),('Ei mit Sternband','egg_star'),('Frühlingsgruß','letter'),('Geschenk zum Osterfest','gift'),('Frühlingslaterne','lantern'),('Karottenkuchen','cake'),('Frühlingsblumenstrauß','flower:bouquet'),('Osterbäumchen','bonsai'),('Frühlingsmaus','face:mouse'),('Regenbogenfrühling','scene:rainbow'),('Frühlingswiese','scene:valley'),('Schokoladengold','emblem:10')]),
('technology','Technik entdecken',['Technik'],[
('Kleiner Roboter','robotbody'),('Roboterkopf','face:robot'),('Neonchip','device:chip'),('Elektronische Leiterbahn','device:circuit'),('Volle Batterie','device:battery'),('Technikkompass','compass'),('Digitale Kamera','device:camera'),('Überwachungsauge','device:webcam'),('Funkstation','device:router'),('Laborflasche','flask'),('Mikrofon für Ideen','microphone'),('Technikleuchte','lamp'),('Technische Uhr','clock'),('Funkradio','device:radio'),('Fernbedienung','device:remote'),('Solarzeichen','emblem:19'),('Magnetisches Feld','emblem:17'),('Energieblitz','emblem:3'),('Digitale Raute','emblem:10'),('Werkzeug der Zukunft','wrench')]),
('computers','Computer und Gaming',['PC','Computer','Gaming','Technik'],[
('Desktopmonitor','device:monitor'),('Laptop unterwegs','device:laptop'),('Mechanische Tastatur','device:keyboard'),('Gamingmaus','device:mouse'),('PC-Gehäuse','device:tower'),('Grafikkarte','device:gpu'),('Mainboard','device:motherboard'),('Prozessor','device:chip'),('USB-Stick','device:usb'),('Klassische Diskette','device:floppy'),('Festplatte','device:harddisk'),('Speicherkarte','device:sdcard'),('Gamingheadset','device:headset'),('Webcam fürs Studio','device:webcam'),('Gaminglautsprecher','device:speaker'),('Spielekonsole','device:console'),('Drucker im Büro','device:printer'),('Server im Rack','device:server'),('Netzwerkrouter','device:router'),('Computertablet','device:tablet')]),
('skylines','Skyline bei Nacht',['Skyline','Stadt','Architektur'],[(title,'skyline') for title in ['Metropole in Pink','Blaue Hafenstadt','Goldene Türme','Violette Abendstadt','Grüne Zukunftsstadt','Türme am Fluss','Dächer im Morgenlicht','Rote Nachtstadt','Silberne Skyline','Stadt unter Sternen','Neonviertel','Hochhäuser am Wasser','Sommerliche Metropole','Winterliche Turmstadt','Türkis am Horizont','Stadt der Lichter','Glas und Gold','Mitternachtsdächer','Bunte Weltenstadt','Stadt im Abendrot']]),
('smartphones','Smartphonewelten',['Smartphone','Technik','Apps'],[(title,'mobile') for title in ['Kamera auf dem Handy','Lieblingsapp','Videozeit','Wetterkurve','Neue Nachricht','Handyuhr','Herz auf dem Display','Musik unterwegs','Navigation am Handy','Gesundheit im Blick','App-Kompass','Standort gefunden','Kalendertermin','Startbildschirm','Videotelefonat','Shopping auf dem Handy','Fotosammlung','Fitnesskurve','Notiz auf dem Display','Einstellungen im Neonlicht']]),
('vehicles','Unterwegs auf Rädern',['Fahrzeuge','Verkehr'],[
('Kleiner Stadtflitzer','vehicle:car'),('Sportwagen im Neonlicht','vehicle:racecar'),('Taxi in der Nacht','vehicle:taxi'),('Polizeiauto','vehicle:police'),('Rettungswagen','vehicle:ambulance'),('Feuerwehrwagen','vehicle:firetruck'),('Großer Reisebus','vehicle:bus'),('Lastwagen','vehicle:truck'),('Camper auf Reisen','vehicle:camper'),('Traktor auf dem Feld','vehicle:tractor'),('Fahrrad im Sommer','vehicle:bicycle'),('Motorradfreiheit','vehicle:motorbike'),('Roller in der Stadt','vehicle:scooter'),('Schnellzug','vehicle:train'),('Straßenbahn','vehicle:tram'),('Metroexpress','vehicle:metro'),('Flugzeug über Wolken','vehicle:plane'),('Düsenjet','vehicle:jet'),('Segelflug','vehicle:glider'),('Wasserflugzeug','vehicle:seaplane')]),
('ocean','Unter dem Meer',['Meer','Wasser','Tiere'],[
('Tropischer Fisch','fish'),('Neonhaifisch','shark'),('Wal im Ozean','whale'),('Delfinsprung','dolphin'),('Kleines Seepferdchen','seahorse'),('Bunter Oktopus','octopus'),('Krabbe am Strand','crab'),('Leuchtende Qualle','jellyfish'),('Seestern im Sand','starfish'),('Perlmuttmuschel','shell'),('Korallengarten','coral'),('Meeresschmetterling','butterfly'),('U-Boot auf Tauchgang','vehicle:submarine'),('Segel im Wind','vehicle:sailboat'),('Schiff auf See','vehicle:ship'),('Yacht im Hafen','vehicle:yacht'),('Kanu auf ruhigem Wasser','vehicle:canoe'),('Leuchtturm im Nebel','lighthouse'),('Insel im Ozean','scene:island'),('Blaue Lagune','scene:lagoon')]),
('animals','Tierische Freunde',['Tiere','Natur'],[(title,'face:'+kind) for title,kind in [('Neugierige Katze','cat'),('Treuer Hund','dog'),('Kleiner Bär','bear'),('Panda im Bambus','panda'),('Fuchs im Wald','fox'),('Hase auf der Wiese','rabbit'),('Maus mit großen Ohren','mouse'),('Koalablick','koala'),('König der Tiere','lion'),('Wolf im Mondlicht','wolf'),('Eule im Baum','owl'),('Tigeraugen','cat'),('Teddy im Kinderzimmer','bear'),('Kleiner Welpe','dog'),('Wüstenfuchs','fox'),('Schneehasenblick','rabbit'),('Waschbärenmaske','panda'),('Hamsterfreund','mouse'),('Kätzchen mit Stern','cat'),('Löwenkind','lion')]]),
('birds','Vogelparadies',['Tiere','Vögel','Natur'],[(title,kind) for title,kind in [('Ente am Teich','duck'),('Schwan auf dem See','swan'),('Flamingo in Pink','flamingo'),('Papagei im Regenwald','parrot'),('Tukan mit Goldschnabel','toucan'),('Adler über Gipfeln','eagle'),('Rotkehlchen','robin'),('Pfau im Garten','peacock'),('Henne auf dem Hof','hen'),('Küken im Frühling','chick'),('Wildgans','goose'),('Reiher am Wasser','heron'),('Specht am Stamm','woodpecker'),('Stadttaube','pigeon'),('Spatz im Garten','sparrow'),('Kolibri im Flug','hummingbird'),('Strauß in der Savanne','ostrich'),('Storch im Sommer','stork'),('Blauer Singvogel','bird'),('Wintervogel','robin')]]),
('bakery','Bäckerei und Süßes',['Essen','Backen'],[
('Pizza aus dem Ofen','pizza'),('Glasierter Donut','donut'),('Schokokeks','cookie'),('Geburtstagstorte','cake'),('Frisches Brot','bread'),('Burgerpause','burger'),('Belegtes Sandwich','sandwich'),('Goldene Waffel','waffle'),('Pfannkuchenstapel','pancakes'),('Ofenwarme Brezel','pretzel'),('Kleine Pralinenschachtel','gift'),('Marmeladenglas','bottle'),('Milch zum Frühstück','glass'),('Bäckerkaffee','cup'),('Kuchenbesteck','fork'),('Honiglöffel','spoon'),('Bunte Süßigkeit','candy'),('Eiswaffelzeichen','emblem:13'),('Süßer Stern','emblem:1'),('Liebesplätzchen','emblem:6')]),
('fruit','Obstkorb in Neon',['Obst','Essen','Natur'],[(title,kind) for title,kind in [('Sonnige Orange','orange'),('Frische Zitrone','lemon'),('Sommermelone','melon'),('Goldene Birne','pear'),('Tropische Ananas','pineapple'),('Violette Trauben','grapes'),('Reife Avocado','avocado'),('Pfirsich im Sommer','peach'),('Dunkle Pflaume','plum'),('Süße Mango','mango'),('Kokosnuss am Strand','coconut'),('Grüne Kiwi','kiwi'),('Obstkorb am Morgen','basket'),('Birne mit Blatt','pear'),('Zitrusfrucht im Anschnitt','orange'),('Melonenscheibe','melonslice'),('Ananas im Sonnenlicht','pineapple'),('Traubenlese','grapes'),('Avocadohälfte','avocado'),('Goldene Pfirsichernte','peach')]]),
('flowers','Blüten und Botanik',['Blumen','Pflanzen','Natur'],[(title,'flower:'+kind) for title,kind in [('Rote Rose','rose'),('Gänseblümchen','daisy'),('Goldene Sonnenblume','sunflower'),('Klatschmohn','poppy'),('Violettes Veilchen','violet'),('Weiße Lilie','lily'),('Orchideenlicht','orchid'),('Hibiskus im Sommer','hibiscus'),('Gerbera in Pink','gerbera'),('Lila Aster','aster'),('Goldene Ringelblume','marigold'),('Anemonenzauber','anemone'),('Lavendelduft','lavender'),('Blaue Hyazinthe','hyacinth'),('Lupine im Garten','lupin'),('Lotus im Teich','lotus'),('Bunter Blumenstrauß','bouquet'),('Tulpe im Abendrot','tulip'),('Dahlienblüte','gerbera'),('Sommerblumen','bouquet')]]),
('workshop','Werkstatt und Garten',['Werkzeuge','Technik','Garten'],[
('Hammer für Ideen','hammer'),('Schraubenschlüssel','wrench'),('Schraubendreher','screwdriver'),('Farbpinsel','brush'),('Gartenbesen','broom'),('Spaten im Garten','shovel'),('Rechen im Herbst','rake'),('Werkstattschlüssel','key'),('Werkzeugkiste','treasure'),('Arbeitshelm','helmet'),('Gartenhandschuh','boxing'),('Messkompass','compass'),('Werkstattlampe','lamp'),('Blumentopf mit Bonsai','bonsai'),('Saatgutpäckchen','letter'),('Gießflasche','bottle'),('Handwerkermesser','sword'),('Farbtopf','cup'),('Werkzeugtasche','backpack'),('Elektrische Werkbank','device:circuit')]),
('music','Musik im Licht',['Musik','Instrumente'],[
('Akustische Gitarre','guitar'),('Kleine Ukulele','ukulele'),('Geige im Scheinwerferlicht','violin'),('Banjo im Sommer','banjo'),('Bunte Trommel','drum'),('Tamburin im Takt','tambourine'),('Maracas für Rhythmus','maracas'),('Goldene Trompete','trumpet'),('Saxofon bei Nacht','saxophone'),('Flötenmelodie','flute'),('Harfe im Licht','harp'),('Bühnenmikrofon','microphone'),('Doppelte Musiknote','musicnote'),('Synthesizer','device:synth'),('Kopfhörer für Melodien','device:headphones'),('Musiklautsprecher','device:speaker'),('Retro-Musikradio','device:radio'),('Plattenspielerzeichen','emblem:0'),('Musik am Display','device:tablet'),('Bühnenstern','emblem:1')]),
('sports','Sport und Bewegung',['Sport'],[
('Fußball im Flutlicht','football'),('Basketballtraining','basketball'),('Volleyball am Strand','volleyball'),('Tennisball im Sommer','tennisball'),('Baseball am Nachmittag','baseball'),('Bowlingabend','bowling'),('Tennisschläger','racket'),('Boxhandschuh','boxing'),('Krafttraining','dumbbell'),('Goldener Pokal','trophy'),('Siegermedaille','medal'),('Skateboardspaß','skateboard'),('Schlittschuhtraining','skate'),('Skitag','ski'),('Snowboardabenteuer','snowboard'),('Fahrradtour','vehicle:bicycle'),('Sporthelm','helmet'),('Startuhr','clock'),('Zielmarkierung','emblem:10'),('Fitnessherz','emblem:6')]),
('toys','Spielzeug und Kindheit',['Spielzeug','Freizeit'],[
('Teddybär im Regal','face:bear'),('Bunte Spielzeugpuppe','doll'),('Spielzeugroboter','robotbody'),('Kleiner Spielzeugzug','vehicle:train'),('Spielzeugauto','vehicle:car'),('Papierflieger','vehicle:glider'),('Schaukelpferd','horse'),('Spielzeugkrone','crown'),('Bunter Drachen','kite'),('Kinderball','volleyball'),('Bauklötze','skyline'),('Spielzeugtrommel','drum'),('Piratenkiste','treasure'),('Puppentässchen','cup'),('Kleines Bilderbuch','book'),('Zauberstab fürs Spielen','wand'),('Spielzeugrakete','rocket'),('Spielkonsole am Abend','device:console'),('Bunter Kreisel','emblem:19'),('Geschenk fürs Kinderzimmer','gift')]),
('travel','Urlaub und Abenteuer',['Urlaub','Reisen'],[
('Reisekoffer','suitcase'),('Rucksackabenteuer','backpack'),('Karte fürs Abenteuer','map'),('Kompass auf Reisen','compass'),('Weltkugel','globe'),('Zelt unterm Sternenhimmel','tent'),('Ferienhütte','cabin'),('Strandurlaub','scene:beach'),('Wüstenoase','scene:oasis'),('Bergtour','scene:mountains'),('Segelurlaub','vehicle:sailboat'),('Heißluftballonfahrt','vehicle:balloon'),('Luftschiffreise','vehicle:airship'),('Reisefotografie','device:camera'),('Camperfreiheit','vehicle:camper'),('Urlaubsbrief','letter'),('Sonnenhut','hat'),('Wasserflasche unterwegs','bottle'),('Abenteuerlaterne','lantern'),('Fernwehschlüssel','key')]),
('fantasy','Märchen und Magie',['Fantasie','Magie'],[
('Märchenschloss','castle'),('Goldene Königskrone','crown'),('Magisches Schwert','sword'),('Sternenzauberstab','wand'),('Hexentrank im Glas','flask'),('Verzauberter Schlüssel','key'),('Schatztruhe der Legenden','treasure'),('Zauberbuch','book'),('Magische Laterne','lantern'),('Zauberhut der Sterne','witchhat'),('Funkelnder Kristall','emblem:10'),('Feenherz','emblem:6'),('Orakelauge','emblem:0'),('Mondkompass','compass'),('Phönix im Licht','eagle'),('Drachenmaske','face:devil'),('Eulenwächter','face:owl'),('Geisterfreund','ghost'),('Zauberblüte','flower:lotus'),('Wald der Wunder','scene:forest')]),
('landscapes','Landschaften und Fernweh',['Landschaften','Natur'],[(title,'scene:'+kind) for title,kind in [('Berge im Morgenlicht','mountains'),('Sonnenaufgang am See','sunrise'),('Bergsee im Tal','lake'),('Fjord im Norden','fjord'),('Wasserfall zwischen Felsen','waterfall'),('Fluss durch das Tal','river'),('Tiefe Schlucht','canyon'),('Weites Tal','valley'),('Wüste im Abendrot','desert'),('Goldene Dünen','dunes'),('Oase im Sand','oasis'),('Sonnenuntergang in der Savanne','savanna'),('Abendsonne am Horizont','sunset'),('Strand mit Palme','beach'),('Kleine Tropeninsel','island'),('Türkisblaue Lagune','lagoon'),('Küste im Sommer','coast'),('Wald am See','forest'),('Dunkler Tannenwald','pinewood'),('Vulkan im Feuerschein','volcano')]]),
('cosmos','Sterne und Zukunft',['Weltall','Technik'],[
('Sternenkompass','compass'),('Planet mit Leuchtkern','emblem:0'),('Kosmischer Kristall','emblem:10'),('Galaktischer Stern','emblem:19'),('Mondstation','device:server'),('Marsroboter','robotbody'),('Raumfahrerhelm','helmet'),('Raumschiffsteuerung','device:console'),('Funkkontakt zur Erde','device:router'),('Planetenerkundung','globe'),('Sternenkarte','map'),('Labor im All','flask'),('Kosmische Batterie','device:battery'),('Raumcomputer','device:laptop'),('Sternenschlüssel','key'),('Sternenblüte','flower:lily'),('Himmelslaterne','lantern'),('Himmelsbrücke','bridge'),('Polarlichtnacht','scene:aurora'),('Leuchtender Zukunftsturm','skyscraper')]),
('cozy','Kleine Wohlfühlmomente',['Zuhause','Gemütlich'],[
('Lesestunde','book'),('Tee am Fenster','teapot'),('Warmes Kerzenlicht','candle'),('Blumenvase im Wohnzimmer','vase'),('Bonsai auf dem Tisch','bonsai'),('Kuschelbär','face:bear'),('Kleine Tischlampe','lamp'),('Brief von Freunden','letter'),('Frühstücksbecher','mug'),('Erinnerungsfoto','device:camera'),('Notizbuch für Ideen','notebook'),('Herzlicher Moment','emblem:6')]),
]


def main():
    source_path=ROOT/'collections/source_masks.json'
    current=json.loads(source_path.read_text(encoding='utf-8-sig'))
    original=[item for item in current if item['collection']['id'] in ['world','garden','taste','space','art']]
    assert len(original)==28
    result=list(original)
    seen=set()
    for group,label,tags,recipes in GROUPS:
        for k,(title,kind) in enumerate(recipes):
            c=Canvas(k)
            compose(c,kind,k)
            if group=='winter' and kind=='face:bear':c.colors[0]='#e6f2ff'
            # Context accents differentiate subjects shared between collections.
            # They are visible scene elements, not arbitrary recolors.
            if group in ['christmas','easter','winter'] and kind not in ['christmastree','snowflake']:
                p=3 if group!='winter' else 6
                c.star(p,4+(k%3),3,2.7,4)
            if group in ['animals','birds','flowers','fruit']:
                # Habitat/plinth geometry also varies, preserving the main silhouette.
                p=1 if group not in ['fruit'] else 7
                c.rect(p,3+k%5,30,24-k%4,31)
                if k>=10:c.star(3,3 if k%2 else 25,4,2.7,4)
            if group in ['technology','computers','cosmos']:
                # Place status lights on the device, rather than floating beside it.
                candidates=[y for y in range(7,29) if sum((x,y) in c.cells for x in range(29))>=8]
                if candidates:
                    y=candidates[k%len(candidates)]
                    xs=[x for x in range(29) if (x,y) in c.cells]
                    x=xs[len(xs)//2]
                    c.shape(3,lambda a,b:(a,b) in c.cells and x-2<=a<=x+1 and y<=b<=y+1)
            if group in ['travel','fantasy','cozy','workshop','sports','toys','bakery']:
                c.oval(3 if group in ['fantasy','toys'] else 2,24 if k%2 else 4,3+k%3,2.3,2.3)
            cells=c.finish()
            signature=hashlib.sha256(json.dumps(cells,separators=(',',':')).encode()).hexdigest()
            if signature in seen:
                # Shared family recipes get an intentional additional scene accent.
                c.rect(6,2+(k%4),1,3+(k%4),3)
                cells=c.finish()
                signature=hashlib.sha256(json.dumps(cells,separators=(',',':')).encode()).hexdigest()
            if signature in seen:raise ValueError('Duplicate geometry: '+title)
            seen.add(signature)
            assert len(cells)>=80,(title,len(cells))
            used={p for _,_,p in cells}
            parts=[{'id':p,'name':c.names[p],'colors':[c.colors[p]]*3} for p in sorted(used)]
            key=f'{group}_{k+1:02d}'
            result.append({'key':key,'collection':{'id':group,'title':label,'order':k+1},'tags':tags,'recipe':kind,'motif':{'title':title,'cells':cells,'parts':parts}})
    assert len(result)==500,len(result)
    assert len({item['motif']['title'] for item in result})==500
    source_path.write_text(json.dumps(result,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
    print(f'{len(result)} motifs in {len(GROUPS)+5} collections; {len(result)-len(original)} new geometry recipes')


if __name__=='__main__':main()
