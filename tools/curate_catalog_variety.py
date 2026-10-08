"""Distinct hand-authored, bilingual catalog scenes. Prepare masks for bake_catalog_variety.gd."""
import json,re
from pathlib import Path
from build_catalog_masks import Canvas
ROOT=Path(__file__).resolve().parents[1]
WHITE='#e9f5ff';BLUE='#52caff';AQUA='#42efd2';GOLD='#ffd95a';ORANGE='#ffa051';RED='#ff526c';GREEN='#65ef91';WOOD='#d99c64';PURPLE='#b994ff';DARK='#7296cc';PINK='#ff85bc'
class Art(Canvas):
 def __init__(self):super().__init__(0);self.colors=[];self.names=[]
 def part(self,name,color):self.names.append(name);self.colors.append(color);return len(self.colors)-1
 def hole(self,x,y,rx,ry):self.cut(lambda a,b:((a-x)/rx)**2+((b-y)/ry)**2<1)
 def windows(self,p,x,y,n=3,w=2,h=3,step=4):
  for i in range(n):self.rect(p,x+i*step,y,x+i*step+w-1,y+h-1)
 def palm(self,x,y,s=1):
  t=self.part('Palmenstamm',WOOD);l=self.part('Palmwedel',GREEN);self.line(t,[(x,y),(x-s,y-7*s),(x+s,y-14*s)],2.5*s)
  for dx,dy in [(-6,2),(-5,-2),(0,-4),(5,-2),(6,2)]:self.line(l,[(x+s,y-14*s),(x+dx*s,y+dy*s-14*s)],2.8*s)
 def house(self,x,y,w,h,color,roofcolor=ORANGE):
  wall=self.part('Fassade',color);roof=self.part('Dach',roofcolor);glass=self.part('Fenster',BLUE)
  self.rect(wall,x,y,x+w,y+h);self.poly(roof,[(x-1,y),(x+w/2,y-5),(x+w+1,y)]);self.windows(glass,x+2,y+3,max(1,int(w/4)),2,3)
 def wave(self,y):
  p=self.part('Wellen',BLUE);self.line(p,[(2,y),(8,y-1),(14,y+1),(20,y),(26,y+1)],2)
RECIPES=[]
def path(group,i):return f'res://collections/levels/{group}_{i:02d}_{group}_{i:02d}.json'
def add(location,title,en,draw,text,english,category=None):
 a=Art();draw(a);cells=a.finish();used=sorted({p for _,_,p in cells});assert len(cells)>=75,(title,len(cells))
 RECIPES.append({'path':location,'title':title,'english_title':en,'motif':{'title':title,'cells':cells,'parts':[{'id':p,'name':a.names[p],'colors':[a.colors[p]]} for p in used]},'discovery':{'kind':'Ein kleiner Gedanke','text':text},'english_discovery':{'kind':'A little thought','text':english},'category':category})
def mirror(a):
 m=a.part('Spiegelrahmen',AQUA);g=a.part('Spiegelglas',BLUE);h=a.part('Griff',WHITE);a.oval(m,11,11,8,8);a.oval(g,11,11,5,5);a.line(h,[(16,17),(24,29)],4);a.line(h,[(7,11),(11,7)],2.4)
add('res://collections/levels/expanded_medicine_05_03_new_mouth_watering.json','Der Zahnarztspiegel','The Dental Mirror',mirror,'Manchmal braucht man einen kleinen Spiegel, um die Dinge aus einem neuen Blickwinkel zu sehen.','Sometimes a small mirror is all it takes to see things from a new angle.')
def river(a):
 e=a.part('Uferwiesen',GREEN);r=a.part('Flusslauf',BLUE);k=a.part('Felsen',PURPLE);a.poly(e,[(2,7),(12,3),(25,7),(27,29),(2,29)]);a.line(r,[(17,4),(11,10),(18,17),(9,23),(4,29)],5);a.poly(k,[(2,9),(5,3),(9,9)]);a.poly(k,[(21,8),(24,2),(27,8)])
add(path('landscapes',6),'Fluss durch das Tal','River Through the Valley',river,'Dieser Fluss nimmt einen Umweg. Die Landschaft scheint damit vollkommen einverstanden.','This river takes the scenic route. The landscape seems perfectly happy with that.')
def waterfall(a):
 r=a.part('Felswände',PURPLE);w=a.part('Wasserfall',BLUE);m=a.part('Gischt',WHITE);g=a.part('Moos',GREEN)
 a.poly(r,[(2,5),(11,2),(12,24),(4,25)]);a.poly(r,[(17,2),(27,6),(24,24),(17,24)]);a.rect(w,12,4,16,23);a.oval(w,14,27,10,4);a.rect(g,2,5,10,7);a.rect(g,18,5,26,7);a.line(m,[(14,7),(14,20)],2);a.oval(m,14,24,6,2)
add(path('landscapes',5),'Wasserfall zwischen Felsen','Waterfall Between the Rocks',waterfall,'Eine kleine Pause für dich. Der Wasserfall hat offenbar andere Pläne.','A little break for you. The waterfall clearly has other plans.')
def lagoon(a):
 w=a.part('Lagunenwasser',AQUA);s=a.part('Sandbank',GOLD);g=a.part('Grünes Ufer',GREEN);a.oval(w,14,18,12,11)
 a.poly(s,[(2,10),(7,4),(21,4),(27,12),(26,24),(22,27),(19,21),(22,13),(18,9),(9,9),(6,15),(9,24),(5,27),(2,21)]);a.line(g,[(5,11),(8,6),(19,6),(23,11)],3)
add(path('ocean',20),'Blaue Lagune','Blue Lagoon',lagoon,'Die Sandbank zieht einen Bogen. Das Wasser darf in der Mitte einfach still sein.','The sandbank forms an arc. The water in the middle can simply be still.')
def beach(a):
 s=a.part('Strand',GOLD);u=a.part('Sonnenschirm',PINK);p=a.part('Schirmstange',WHITE);c=a.part('Liegestuhl',AQUA)
 a.oval(s,14,28,12,3);a.line(p,[(9,12),(9,27)],2.5);a.poly(u,[(2,12),(5,6),(10,3),(16,7),(18,12)]);a.line(c,[(18,15),(21,22),(27,22),(18,22),(16,28)],3);a.line(p,[(22,23),(25,28)],2.4)
add(path('travel',8),'Strandurlaub','Beach Holiday',beach,'Die Liege ist frei. Für die nächsten paar Gedanken ist kein Termin vorgesehen.','The deckchair is free. Your next few thoughts have no appointments.')
def fjord(a):
 r=a.part('Steile Fjordwände',DARK);s=a.part('Schneekappen',WHITE);w=a.part('Fjordwasser',BLUE);g=a.part('Bewachsene Hänge',GREEN)
 a.poly(r,[(2,4),(8,2),(10,16),(6,29),(2,29)]);a.poly(r,[(20,1),(27,4),(27,29),(22,26),(17,12)]);a.poly(w,[(13,9),(16,9),(21,29),(7,29)]);a.poly(s,[(2,4),(8,2),(9,6),(3,7)]);a.poly(s,[(20,1),(27,4),(26,7),(20,5)]);a.line(g,[(4,12),(7,16),(4,23)],3);a.line(g,[(22,11),(25,18),(23,24)],3)
add(path('landscapes',4),'Fjord im Norden','Northern Fjord',fjord,'Die Berge rücken nah zusammen. Für das Wasser bleibt trotzdem ein Weg.','The mountains draw close together. There is still a way through for the water.')
def palmbeach(a):
 s=a.part('Strandsichel',GOLD);a.poly(s,[(2,25),(14,22),(27,26),(24,29),(3,29)]);a.palm(17,25,1.25);a.wave(31)
add(path('landscapes',14),'Strand mit Palme','Palm Beach',palmbeach,'Die Palme hat keinen Urlaub gebucht. Sie sieht trotzdem aus, als wäre sie längst angekommen.','The palm never booked a holiday. It still looks as if it has already arrived.')
def volcanoisland(a):
 w=a.part('Meer',BLUE);r=a.part('Vulkan',PURPLE);l=a.part('Kraterglut',ORANGE);g=a.part('Inselufer',GREEN);a.oval(w,14,27,12,4);a.poly(r,[(4,24),(11,7),(17,7),(25,24)]);a.rect(l,11,7,17,10);a.line(l,[(15,10),(12,16),(17,22)],2.8);a.oval(g,14,25,11,2)
add(path('landscapes',15),'Tropische Vulkaninsel','Tropical Volcano Island',volcanoisland,'Eine Insel mit eigenem kleinen Feuer. Zum Glück bleibt es heute im Bild.','An island with a little fire of its own. Fortunately, today it stays in the picture.')
def lighthouse(a):
 r=a.part('Klippe',WOOD);t=a.part('Leuchtturm',WHITE);s=a.part('Turmstreifen',RED);g=a.part('Laterne',GOLD)
 a.poly(r,[(3,26),(9,21),(20,22),(26,30),(2,30)]);a.poly(t,[(9,22),(11,7),(17,7),(19,22)]);a.rect(s,10,14,18,17);a.rect(g,10,4,18,7);a.poly(s,[(9,4),(14,1),(19,4)]);a.wave(31)
add(path('landscapes',16),'Leuchtturm auf der Klippe','Lighthouse on the Cliff',lighthouse,'Man muss nicht den ganzen Weg beleuchten. Manchmal reicht ein Licht, das sagt: Hier entlang.','You do not have to light the whole way. Sometimes one light saying “this way” is enough.')
def huts(a):a.house(2,13,9,12,PINK,BLUE);a.house(16,9,10,16,AQUA,GOLD);a.wave(30)
add(path('landscapes',17),'Strandhütten im Sommer','Summer Beach Huts',huts,'Zwei kleine Hütten, zwei große Ferienpläne. Der wichtigste steht noch nicht im Kalender.','Two little huts, two big holiday plans. The most important one is not on the calendar yet.')
def oasis(a):
 s=a.part('Oasensand',GOLD);w=a.part('Oasenbecken',AQUA);a.oval(s,14,26,12,4);a.oval(w,14,25,7,2);a.palm(7,24,.95);a.palm(23,24,.8)
add(path('travel',9),'Wüstenoase','Desert Oasis',oasis,'Viel Sand und ein kleines Stück Wasser. Plötzlich wirkt die ganze Landschaft freundlicher.','A lot of sand and a little patch of water. Suddenly the whole landscape feels friendlier.')
def mesa(a):
 e=a.part('Tafelberge',ORANGE);s=a.part('Abendsonne',PINK);g=a.part('Wüstensand',GOLD);a.oval(s,20,9,6,6);a.poly(e,[(2,9),(10,9),(12,22),(2,23)]);a.poly(e,[(15,18),(17,14),(25,14),(27,25),(14,25)]);a.line(g,[(2,29),(11,26),(20,29),(27,27)],4)
add(path('landscapes',9),'Wüste im Abendrot','Desert Afterglow',mesa,'Die Schatten werden länger. Selbst die Wüste scheint sich auf einen ruhigeren Ton zu einigen.','The shadows grow longer. Even the desert seems to settle on a quieter tone.')
def dunes(a):
 p=a.part('Hintere Dünen',PINK);q=a.part('Goldene Dünen',GOLD);r=a.part('Warme Sandkante',ORANGE)
 a.poly(p,[(2,17),(10,7),(15,11),(23,5),(27,17),(27,29),(2,29)]);a.poly(q,[(2,21),(8,17),(14,19),(21,12),(27,17),(27,29),(2,29)]);a.poly(r,[(2,27),(10,22),(16,25),(23,20),(27,23),(27,29),(2,29)])
add(path('landscapes',10),'Goldene Dünen','Golden Dunes',dunes,'Ein Hügel legt sich hinter den nächsten. Der Horizont hat heute weiche Kanten.','One hill settles behind the next. Today the horizon has soft edges.')
def camelwell(a):
 c=a.part('Kamel',ORANGE);w=a.part('Brunnen',WOOD);b=a.part('Wasser',AQUA);s=a.part('Sand',GOLD)
 a.oval(c,11,17,7,4);a.oval(c,11,13,3,4);a.line(c,[(16,18),(19,9),(23,9)],3.5);a.line(c,[(7,19),(6,27)],3);a.line(c,[(14,19),(15,27)],3);a.line(c,[(5,16),(2,13)],2.5);a.rect(w,21,23,27,29);a.rect(b,21,23,27,24);a.line(s,[(2,30),(19,30)],2)
add(path('landscapes',11),'Kamel am Wüstenbrunnen','Camel at the Desert Well',camelwell,'Dieser Zwischenstopp ist kein Umweg. Das Kamel würde die Sache vermutlich genauso sehen.','This stop is no detour. The camel would probably see it the same way.')
def savanna(a):
 t=a.part('Akazienstamm',WOOD);l=a.part('Akazienkrone',GREEN);s=a.part('Abendsonne',ORANGE);g=a.part('Savannengras',GOLD)
 a.oval(s,23,15,4,4);a.line(t,[(12,29),(12,15),(7,11)],3);a.line(t,[(12,17),(18,10)],3);a.oval(l,12,9,11,4);a.line(g,[(2,30),(27,30)],3)
add(path('landscapes',12),'Sonnenuntergang in der Savanne','Savanna Sunset',savanna,'Ein Baum spannt seinen grünen Schirm auf. Die Sonne braucht heute keinen Platz darunter.','A tree opens its green umbrella. Today the sun needs no place beneath it.')
def goal(a):
 p=a.part('Torpfosten',WHITE);n=a.part('Tornetz',BLUE);b=a.part('Fußball',WHITE);g=a.part('Spielfeld',GREEN);a.line(p,[(2,23),(2,4),(24,4),(24,23)],3)
 for x in [7,12,17,22]:a.line(n,[(x,7),(x,20)],2)
 for y in [10,15,20]:a.line(n,[(5,y),(21,y)],2)
 a.oval(b,21,26,5,5);patch=a.part('Ballmuster',DARK);a.oval(patch,21,26,2.2,2.2);a.line(g,[(2,30),(13,30)],2)
add(path('sports',1),'Fußball im Flutlicht','Football Under the Floodlights',goal,'Das Tor steht noch. Der Ball auch. Für einen kurzen Moment muss niemand hinterherlaufen.','The goal is still standing. So is the ball. For a moment, nobody has to chase it.')
def basket(a):
 b=a.part('Rückwand',WHITE);p=a.part('Stütze',PURPLE);r=a.part('Korbring',RED);n=a.part('Netz',BLUE);o=a.part('Basketball',ORANGE)
 a.rect(b,3,3,20,13);a.cut(lambda x,y:5<=x<=18 and 5<=y<=10);a.rect(p,10,13,12,29);a.line(r,[(5,14),(19,14)],3);a.line(n,[(6,16),(9,22),(16,22),(18,16)],2);a.oval(o,23,25,4,4);a.line(p,[(5,30),(18,30)],2)
add(path('sports',2),'Basketballtraining','Basketball Practice',basket,'Der Korb wartet geduldig. Er nimmt es nicht persönlich, wenn ein Wurf ein paar Anläufe braucht.','The hoop waits patiently. It never takes it personally when a shot needs a few attempts.')
def volleyball(a):
 p=a.part('Netzpfosten',PURPLE);n=a.part('Volleyballnetz',WHITE);b=a.part('Volleyball',GOLD);s=a.part('Sand',ORANGE);a.rect(p,2,10,4,28);a.rect(p,24,10,26,28)
 for y in [12,16,20]:a.rect(n,5,y,23,y+1)
 for x in [7,12,17,22]:a.rect(n,x,12,x+1,21)
 a.oval(b,19,5,4,4);a.oval(s,14,30,12,2)
add(path('sports',3),'Volleyball am Strand','Beach Volleyball',volleyball,'Das Netz teilt den Strand. Den Spaß muss es glücklicherweise nicht halbieren.','The net divides the beach. Luckily, it does not have to divide the fun.')
def court(a):
 f=a.part('Tennisplatz',GREEN);l=a.part('Spielfeldlinien',WHITE);n=a.part('Netz',BLUE);b=a.part('Tennisball',GOLD)
 a.rect(f,3,3,25,29);a.rect(l,5,5,23,27);a.rect(f,7,7,21,25);a.rect(l,7,14,21,16);a.rect(l,13,7,15,25);a.rect(n,3,15,25,17);a.oval(b,21,24,3,3)
add(path('sports',4),'Tennisplatz von oben','Tennis Court from Above',court,'So viele Linien und trotzdem Platz für einen Überraschungsball.','So many lines, and still room for a surprise shot.')
def baseball(a):
 g=a.part('Fanghandschuh',WOOD);b=a.part('Baseball',WHITE);s=a.part('Ballnaht',RED);a.oval(g,13,21,10,9)
 for x,y in [(4,10),(9,6),(14,5),(19,7)]:a.line(g,[(x,y),(x+1,19)],4)
 a.line(g,[(22,23),(26,15)],4);a.oval(b,14,20,6,6);a.line(s,[(11,16),(10,20),(12,24)],2)
add(path('sports',5),'Baseball am Nachmittag','Afternoon Baseball',baseball,'Der Handschuh hat den Ball aufgefangen. Du hast die Pause dazwischen verdient.','The glove has caught the ball. You have earned the pause in between.')
def bowling(a):
 w=a.part('Kegel',WHITE);s=a.part('Kegelringe',RED);b=a.part('Bowlingkugel',PURPLE)
 for x,y in [(6,3),(16,5),(23,12)]:a.oval(w,x,y+2,2.3,3);a.poly(w,[(x-1,y+4),(x+1,y+4),(x+3,y+14),(x-3,y+14)]);a.rect(s,x-1,y+6,x+1,y+7)
 a.oval(b,8,25,7,6);a.hole(7,22,1.5,1.5);a.hole(11,24,1.5,1.5)
add(path('sports',6),'Bowlingabend','Bowling Night',bowling,'Alle Kegel stehen noch. Es ist die kleine Ruhe vor einem ziemlich vergnüglichen Durcheinander.','All the pins are still standing. A little calm before a rather cheerful mess.')
def steamship(a):
 h=a.part('Rumpf',BLUE);d=a.part('Decks',WHITE);f=a.part('Schornsteine',RED);s=a.part('Dampf',PURPLE)
 a.poly(h,[(2,23),(27,23),(22,30),(7,30)]);a.rect(d,6,17,23,22);a.rect(d,9,13,21,16)
 for x in [10,17]:a.rect(f,x,7,x+3,12);a.oval(s,x+1,4,3,2)
 a.wave(32)
add(path('ocean',15),'Ozeandampfer mit Schornsteinen','Ocean Liner with Funnels',steamship,'Dieses Schiff hat Platz für viele Geschichten. Heute darf deine ein kleines Kapitel dazu bekommen.','This ship has room for many stories. Today yours can add a little chapter.')
def yacht(a):
 h=a.part('Yachtrumpf',WHITE);g=a.part('Panoramafenster',BLUE);d=a.part('Deck',GOLD);w=a.part('Hafenwasser',AQUA)
 a.poly(h,[(2,21),(27,21),(23,28),(7,28)]);a.poly(h,[(8,20),(11,12),(20,12),(24,20)]);a.poly(g,[(12,14),(19,14),(22,19),(10,19)]);a.rect(d,9,10,20,12);a.rect(w,2,30,26,31)
add(path('ocean',16),'Yacht im Hafen','Yacht in the Harbour',yacht,'Die Yacht liegt still. Auch ein schöner Aufbruch darf mit einer Pause beginnen.','The yacht lies still. Even a lovely departure can begin with a pause.')
def pirate(a):
 h=a.part('Holzrumpf',WOOD);m=a.part('Masten',GOLD);s=a.part('Segel',WHITE);f=a.part('Piratenflagge',PURPLE)
 a.poly(h,[(2,24),(26,24),(23,30),(7,30)]);a.rect(m,11,3,13,25);a.rect(m,21,9,23,25);a.poly(s,[(4,9),(10,9),(10,21),(3,20)]);a.poly(s,[(14,9),(20,9),(20,21),(14,22)]);a.rect(f,13,2,22,6);a.wave(32)
add(path('travel',11),'Piratenschiff unter Segeln','Pirate Ship Under Sail',pirate,'Heute wurde kein Schatz ausgegraben. Dafür hast du dieses Schiff ans Licht gebracht.','No treasure was dug up today. But you brought this ship to light.')
def anchor(a):
 p=a.part('Anker',BLUE);r=a.part('Ankerring',GOLD);a.ring(r,14,5,4,4,2.3);a.rect(p,13,9,15,26);a.rect(p,7,12,21,14);a.line(p,[(3,20),(6,26),(14,30),(22,26),(25,20)],3.5);a.poly(p,[(1,22),(3,16),(7,21)]);a.poly(p,[(21,21),(25,16),(27,22)])
add('res://collections/levels/variety_anchor.json','Anker im Hafen','Harbour Anchor',anchor,'Ein Anker ist eine Einladung, einen Moment zu bleiben. Du musst nicht sofort weiter.','An anchor is an invitation to stay a moment. You do not have to move on immediately.','travel_03')
def helicopter(a):
 b=a.part('Hubschrauber',GOLD);g=a.part('Cockpit',BLUE);r=a.part('Rotoren',WHITE);s=a.part('Kufen',PURPLE)
 a.oval(b,10,17,8,6);a.poly(b,[(15,15),(25,11),(26,14),(16,20)]);a.poly(g,[(3,14),(8,12),(9,17),(3,18)]);a.rect(r,9,7,11,11);a.rect(r,2,5,22,7);a.line(r,[(25,8),(25,17)],2.5);a.line(s,[(5,22),(5,26),(18,26)],3);a.line(s,[(13,23),(13,26)],2.5)
add(path('vehicles',17),'Hubschrauber über Wolken','Helicopter Above the Clouds',helicopter,'Ein Rotor zeichnet Kreise. Dein Weg durch das Rätsel ist gerade an seinem Ziel angekommen.','A rotor draws circles. Your route through this puzzle has just reached its destination.')
def jet(a):
 t=a.part('Kondensstreifen',WHITE);w=a.part('Flügel',PURPLE);b=a.part('Jet',BLUE);a.line(t,[(2,30),(10,20)],3);a.line(t,[(8,32),(15,22)],2.5);a.poly(w,[(6,17),(21,7),(23,20),(16,19),(12,23)]);a.poly(b,[(10,23),(24,2),(26,2),(22,18),(17,24)]);a.poly(w,[(11,22),(15,26),(19,25),(17,20)])
add(path('vehicles',18),'Düsenjet mit Kondensstreifen','Jet with a Vapour Trail',jet,'Ein heller Strich bleibt am Himmel zurück. Nicht jeder schöne Weg braucht ein Schild.','A bright line remains in the sky. Not every beautiful route needs a sign.')
def glider(a):
 w=a.part('Lange Tragflächen',WHITE);b=a.part('Rumpf',PINK);g=a.part('Cockpit',BLUE);a.poly(w,[(1,13),(27,8),(27,11),(2,17)]);a.poly(b,[(12,3),(15,3),(18,29),(15,30)]);a.rect(g,13,6,15,10);a.poly(w,[(10,25),(22,23),(23,26),(10,28)])
add(path('vehicles',19),'Segelflug','Soaring',glider,'Die langen Flügel tragen eine leise Reise. Der nächste Gedanke darf ruhig genauso leicht sein.','Long wings carry a quiet journey. Your next thought can be just as light.')
def seaplane(a):
 p=a.part('Flugzeug',ORANGE);g=a.part('Cockpit',BLUE);f=a.part('Schwimmer',WHITE);w=a.part('Flügel',GOLD)
 a.poly(p,[(2,13),(21,13),(25,8),(27,8),(26,20),(7,20)]);a.poly(p,[(8,13),(11,8),(17,8),(20,13)]);a.rect(g,12,9,16,12);a.poly(w,[(11,16),(23,20),(18,23),(8,18)]);a.line(f,[(7,24),(21,24)],3);a.line(f,[(10,28),(25,28)],3);a.line(f,[(9,21),(9,24)],2);a.wave(32)
add(path('vehicles',20),'Wasserflugzeug','Seaplane',seaplane,'Dieses Flugzeug hat sich einen besonderen Parkplatz ausgesucht. Das Wasser scheint nichts dagegen zu haben.','This plane has chosen a rather special parking spot. The water seems happy with it.')
def paperplane(a):
 w=a.part('Papierflügel',WHITE);b=a.part('Papierfalte',BLUE);p=a.part('Schattenseite',PURPLE);a.poly(w,[(2,9),(27,2),(16,30),(12,18)]);a.poly(b,[(2,9),(12,18),(27,2)]);a.poly(p,[(12,18),(16,30),(17,13),(27,2)])
add('res://collections/levels/expanded_travel_04_02_new_glider.json','Papierflieger im Aufwind','Paper Plane on the Breeze',paperplane,'Ein Blatt Papier hatte heute größere Pläne. Du hast ihnen Flügel gegeben.','A sheet of paper had bigger plans today. You gave them wings.')
def car(a,kind):
 color={'city':AQUA,'sport':PURPLE,'taxi':GOLD,'police':BLUE,'ambulance':WHITE,'fire':RED,'bus':ORANGE,'truck':GREEN,'camper':PINK}[kind]
 b=a.part('Karosserie',color);g=a.part('Scheiben',BLUE if kind!='police' else AQUA);w=a.part('Reifen',DARK);m=a.part('Felgen und Licht',WHITE)
 if kind=='sport':a.poly(b,[(2,21),(6,16),(17,14),(23,18),(27,20),(26,26),(2,26)]);a.poly(g,[(9,16),(16,16),(21,20),(6,20)]);a.rect(m,23,16,27,17)
 elif kind=='city':a.poly(b,[(4,19),(7,9),(19,9),(23,18),(26,20),(26,27),(3,27)]);a.rect(g,8,12,13,18);a.rect(g,16,12,20,18)
 elif kind=='police':
  a.poly(b,[(6,11),(9,7),(20,7),(23,11),(24,27),(5,27)]);a.rect(g,9,11,20,17);a.rect(m,6,22,23,24);a.rect(w,4,25,7,30);a.rect(w,22,25,25,30);lamp=a.part('Blaulicht',BLUE);a.rect(lamp,9,3,20,5);a.rect(m,6,19,9,21);a.rect(m,20,19,23,21)
 elif kind=='taxi':
  a.poly(b,[(2,19),(7,18),(10,11),(18,11),(22,18),(27,20),(27,26),(2,26)]);a.poly(g,[(11,13),(17,13),(20,18),(9,18)]);l=a.part('Dachzeichen',BLUE if kind=='police' else WHITE);a.rect(l,12,7,18,9);a.rect(m,3,22,26,23)
 elif kind in ['ambulance','camper']:
  a.poly(b,[(2,6),(19,6),(26,16),(26,27),(2,27)] if kind=='ambulance' else [(2,12),(4,8),(17,8),(23,15),(26,18),(26,27),(2,27)]);a.poly(g,[(20,11),(24,16),(24,19),(19,19)] if kind=='ambulance' else [(18,12),(23,17),(23,20),(18,20)])
  if kind=='ambulance':
   c=a.part('Rotes Kreuz',RED);a.rect(c,6,15,14,17);a.rect(c,9,12,11,20);a.rect(g,4,7,14,9)
  else:a.rect(g,5,12,13,17);d=a.part('Tür',WHITE);a.rect(d,15,19,17,26);a.rect(m,2,23,13,24);a.poly(m,[(4,7),(7,2),(15,7)])
 elif kind=='fire':
  a.rect(b,2,14,18,26);a.poly(b,[(19,10),(24,10),(27,16),(27,26),(19,26)]);a.rect(g,21,12,24,17);a.rect(m,2,5,18,6);a.rect(m,2,10,18,11)
  for x in range(3,18,4):a.rect(m,x,6,x+1,9)
 elif kind=='bus':a.rect(b,2,5,26,27);a.windows(g,4,8,5,3,9,4);a.rect(m,4,22,23,23)
 elif kind=='truck':a.rect(b,2,6,17,25);a.poly(b,[(19,12),(24,12),(27,18),(27,26),(19,26)]);a.rect(g,20,14,24,18);a.rect(m,3,9,16,10)
 for x in ([7,22] if kind not in ['sport','city'] else [7,21]):a.oval(w,x,27,3.5,3.5);a.oval(m,x,27,1.7,1.7)
texts={
'city':('Die Stadt ist groß. Für diesen kleinen Flitzer findet sich bestimmt noch eine Lücke.','The city is big. There is bound to be a gap for this little runabout.'),
'sport':('Auch ein schneller Wagen darf stehen bleiben. Dieser Moment gehört dir.','Even a fast car can stand still. This moment is yours.'),
 'taxi':('Das Taxi wartet. Du darfst dir das Ziel für den nächsten kleinen Ausflug aussuchen.','The taxi is waiting. You can choose the destination for your next little outing.'),
 'police':('Heute braucht niemand eine Sirene. Ein gelöstes Rätsel darf auch leise gefeiert werden.','No one needs a siren today. A solved puzzle can be celebrated quietly too.'),
 'ambulance':('Platz machen, wenn Hilfe unterwegs ist. Platz lassen, wenn jemand eine Pause braucht.','Make room when help is on the way. Leave room when someone needs a break.'),
 'fire':('Eine Leiter reicht weiter, wenn unten jemand aufpasst. Gute Wege entstehen oft gemeinsam.','A ladder reaches further when someone looks after the bottom. Good routes often take teamwork.'),
 'bus':('So viele Fenster, so viele mögliche Geschichten. Deine darf heute ein bisschen leuchten.','So many windows, so many possible stories. Today yours can shine a little.'),
 'truck':('Nicht jede wertvolle Ladung passt in eine Kiste. Geduld zum Beispiel.','Not every valuable load fits in a box. Patience, for instance.'),
 'camper':('Das Zuhause hat Räder bekommen. Der Kalender darf ein paar freie Felder behalten.','Home has grown wheels. The calendar can keep a few empty spaces.')}
for i,(kind,title,en) in enumerate([('city','Kleiner Stadtflitzer','Little City Runabout'),('sport','Sportwagen im Neonlicht','Sports Car in Neon'),('taxi','Taxi in der Nacht','Night Taxi'),('police','Polizeiauto','Police Car'),('ambulance','Rettungswagen','Ambulance'),('fire','Feuerwehrwagen','Fire Engine'),('bus','Großer Reisebus','Coach'),('truck','Lastwagen','Lorry'),('camper','Camper auf Reisen','Camper on the Road')],1):add(path('vehicles',i),title,en,lambda a,k=kind:car(a,k),*texts[kind])
def tractor(a):
 b=a.part('Traktor',GREEN);g=a.part('Kabine',BLUE);w=a.part('Reifen',DARK);r=a.part('Felgen',GOLD);m=a.part('Auspuff',WHITE);a.rect(b,6,15,24,24);a.rect(b,5,5,15,17);a.rect(g,8,8,13,15);a.rect(m,21,10,23,16);a.oval(w,8,24,6,6);a.oval(r,8,24,3,3);a.oval(w,24,26,3.5,3.5);a.oval(r,24,26,1.6,1.6)
add(path('vehicles',10),'Traktor auf dem Feld','Tractor in the Field',tractor,'Ein großes Rad, ein kleines Rad. Zum Vorankommen müssen nicht alle gleich aussehen.','One big wheel, one little wheel. Moving forward does not mean everyone has to look alike.')
def bike(a,kind):
 w=a.part('Räder',BLUE);f=a.part('Rahmen',AQUA if kind=='bicycle' else ORANGE if kind=='motorbike' else PINK);s=a.part('Sitz und Lenker',WHITE)
 for x in [6,23]:a.ring(w,x,25,5,5,2.7)
 if kind=='bicycle':a.line(f,[(6,25),(12,15),(17,25),(6,25),(21,15),(23,25)],2.5);a.line(s,[(9,13),(14,13)],2.5);a.line(s,[(20,10),(22,10),(21,16)],2.5)
 elif kind=='motorbike':a.poly(f,[(6,21),(10,15),(18,16),(23,22),(17,24),(10,24)]);a.line(s,[(8,14),(15,14)],3);a.line(s,[(19,16),(22,9),(25,9)],2.5)
 else:a.line(f,[(6,25),(19,25),(20,11)],4);a.poly(f,[(5,24),(6,15),(12,15),(12,22)]);a.line(s,[(5,13),(13,13)],3);a.rect(f,20,8,25,11);a.line(s,[(21,6),(24,6)],2)
for i,k,t,en in [(11,'bicycle','Fahrrad im Sommer','Summer Bicycle'),(12,'motorbike','Motorradfreiheit','Motorbike Freedom'),(13,'scooter','Roller in der Stadt','City Scooter')]:add(path('vehicles',i),t,en,lambda a,k=k:bike(a,k),'Zwei Räder, ein kleiner Aufbruch. Der nächste Weg muss nicht weit sein.','Two wheels, a little departure. The next journey does not have to be far.')
def train(a,kind):
 b=a.part('Zug',WHITE if kind=='express' else GOLD if kind=='tram' else PURPLE);g=a.part('Fenster',BLUE);r=a.part('Schienen',DARK);c=a.part('Akzentstreifen',RED if kind=='express' else AQUA)
 if kind=='express':a.poly(b,[(2,11),(19,11),(26,19),(27,24),(2,24)]);a.windows(g,4,13,4,3,4,4);a.rect(c,2,21,24,23);a.rect(r,2,28,27,30)
 elif kind=='tram':a.rect(b,7,7,23,27);a.poly(b,[(7,7),(3,11),(3,24),(7,27)]);a.rect(g,10,10,20,17);a.rect(c,10,21,20,23);a.line(r,[(4,32),(9,28),(22,28),(27,32)],2);a.line(r,[(13,7),(10,3),(17,3),(15,7)],2)
 else:a.ring(r,14,16,12,14,3);a.poly(b,[(8,16),(11,12),(18,12),(21,16),(21,28),(8,28)]);a.rect(g,11,16,18,21);a.rect(c,10,24,19,25);a.line(r,[(6,32),(10,29),(19,29),(23,32)],3)
for i,k,t,en in [(14,'express','Schnellzug','High-Speed Train'),(15,'tram','Straßenbahn','Tram'),(16,'metro','Metroexpress','Metro Express')]:add(path('vehicles',i),t,en,lambda a,k=k:train(a,k),'Ein Zug zieht seine Spur. Du hast heute deinen eigenen Weg durch ein kleines Durcheinander gefunden.','A train follows its track. Today you found your own way through a little tangle.')
def tracks(a):
 r=a.part('Stahlschienen',WHITE);w=a.part('Schwellen',WOOD)
 for y in range(8,31,4):s=2+(y-8)*.38;a.line(w,[(14-s,y),(14+s,y)],2.5)
 a.line(r,[(11,3),(3,31)],3);a.line(r,[(17,3),(25,31)],3)
add('res://collections/levels/variety_rail_tracks.json','Gleise in die Ferne','Tracks into the Distance',tracks,'Zwei Linien nähern sich am Horizont. Manchmal sieht ein langer Weg von hier aus ganz klein aus.','Two lines draw together on the horizon. Sometimes a long journey looks very small from here.','travel_02')
def bridge(a):
 s=a.part('Brückenbogen',WOOD);t=a.part('Zug auf der Brücke',RED);g=a.part('Zugfenster',BLUE);w=a.part('Fluss',AQUA);a.rect(s,2,16,26,28);a.hole(14,27,8,9);a.rect(t,4,8,24,14);a.windows(g,6,10,5,2,3,4);a.rect(s,2,15,26,17);a.line(w,[(3,31),(26,31)],3)
add('res://collections/levels/variety_rail_bridge.json','Zug auf der Bogenbrücke','Train on the Arch Bridge',bridge,'Oben fährt ein Zug, unten zieht das Wasser weiter. Zwei Reisen teilen sich einen stillen Augenblick.','A train passes above; water moves on below. Two journeys share one quiet moment.','travel_02')
def canyon(a):
 r=a.part('Schluchtwände',ORANGE);s=a.part('Tiefe Felsschatten',PURPLE);w=a.part('Fluss in der Tiefe',BLUE);a.poly(r,[(2,3),(10,6),(12,13),(9,24),(11,30),(2,30)]);a.poly(r,[(18,2),(26,4),(27,30),(18,30),(20,22),(17,13)]);a.line(s,[(5,9),(7,16),(4,24)],2.5);a.line(s,[(24,8),(21,15),(24,26)],2.5);a.line(w,[(14,8),(14,15),(12,23),(15,30)],3)
add(path('landscapes',7),'Tiefe Schlucht','Deep Canyon',canyon,'Die Schlucht lässt nur einen schmalen Weg frei. Das Wasser scheint ihn gefunden zu haben.','The canyon leaves only a narrow way through. The water seems to have found it.')
def valley(a):
 h=a.part('Grüne Talhänge',GREEN);m=a.part('Bergflanken',PURPLE);p=a.part('Weg durchs Tal',GOLD);s=a.part('Schneegipfel',WHITE);a.poly(m,[(2,4),(6,3),(12,19),(20,6),(25,4),(27,28),(2,28)]);a.poly(h,[(2,17),(10,21),(15,19),(23,16),(27,27),(2,30)]);a.line(p,[(17,20),(15,24),(10,28),(12,31)],3);a.poly(s,[(2,4),(6,3),(8,8),(3,8)]);a.poly(s,[(20,6),(25,4),(26,9),(21,10)])
add(path('landscapes',8),'Weites Tal','Wide Valley',valley,'Hier darf der Blick weiter werden. Der Weg hat Zeit, eine kleine Kurve zu machen.','Here your gaze can wander further. The path has time for a little bend.')
def city(a,k):
 w=a.part('Baukörper',PURPLE);l=a.part('Fensterlicht',GOLD);s=a.part('Helle Architektur',WHITE);b=a.part('Wasser und Glas',BLUE);r=a.part('Dächer',ORANGE)
 if k=='street':
  a.poly(w,[(2,3),(10,7),(10,25),(2,30)]);a.poly(b,[(19,5),(27,1),(27,30),(19,25)]);a.line(s,[(14,18),(12,31)],2)
  for x,y in [(4,9),(4,18),(22,7),(22,17)]:a.windows(l,x,y,1,3,4)
 elif k=='harbour':a.rect(w,2,17,10,26);a.rect(s,5,5,7,16);a.line(s,[(6,5),(22,5),(22,17)],2.5);a.poly(r,[(12,22),(27,22),(24,27),(16,27)]);a.rect(b,2,29,27,31)
 elif k=='domes':
  for x,y,h in [(3,16,13),(12,10,19),(22,18,11)]:a.rect(s,x,y,x+4,y+h);a.oval(l,x+2,y-3,3,4);a.line(r,[(x+2,y-8),(x+2,y-6)],2)
 elif k=='oldtown':a.house(2,13,8,16,PINK,ORANGE);a.house(12,8,8,21,GOLD,PURPLE);a.house(22,17,5,12,AQUA,RED)
 elif k=='citybridge':a.rect(w,2,3,7,13);a.rect(r,21,7,26,15);a.rect(s,2,17,26,20);a.line(s,[(3,12),(9,16),(18,16),(25,12)],2.5);a.rect(b,2,24,26,29);a.windows(l,3,6,1,2,4);a.windows(l,22,9,1,3,4)
 elif k=='rooftops':a.house(2,17,12,13,PINK,PURPLE);a.house(15,12,12,18,GOLD,ORANGE);a.rect(s,19,3,21,10);a.rect(s,5,8,7,13)
 elif k=='viaduct':
  a.rect(w,2,17,27,30)
  for x in [7,21]:a.hole(x,29,4,8)
  a.rect(r,3,8,26,14);a.windows(l,5,10,5,2,3,4);a.rect(s,2,15,27,17)
 elif k=='needle':a.line(s,[(14,2),(14,29)],3);a.oval(b,14,11,6,3);a.rect(w,2,18,7,29);a.rect(w,22,14,27,29);a.rect(l,23,18,25,25)
 elif k=='observatory':a.oval(b,14,15,9,8);a.rect(s,5,15,23,27);a.rect(r,3,28,25,30);a.rect(l,11,19,17,24);a.line(s,[(17,8),(23,3)],3);a.oval(l,4,4,2,2)
 elif k=='shop':
  a.rect(w,3,9,25,29);a.rect(l,3,4,25,8);a.rect(s,5,14,23,16);a.rect(b,5,19,13,26);a.rect(r,17,19,23,28)
  for x in [6,12,18]:a.rect(r,x,5,x+2,7)
 elif k=='sailtowers':a.poly(s,[(3,25),(12,4),(12,25)]);a.poly(b,[(16,25),(17,1),(27,25)]);a.rect(w,3,28,12,30);a.rect(l,17,28,25,30)
 elif k=='market':a.house(2,9,7,13,GOLD,RED);a.house(20,9,7,13,PINK,PURPLE);a.oval(s,14,28,8,3);a.rect(b,13,16,15,25);a.oval(b,14,14,4,2)
 elif k=='snowcity':a.rect(w,4,8,9,29);a.rect(w,19,4,24,29);a.rect(r,10,20,18,29);a.rect(s,3,7,10,9);a.rect(s,18,3,25,5);a.rect(s,10,19,18,21);a.rect(l,6,12,7,21);a.rect(l,21,9,22,19)
 elif k=='artdeco':a.rect(b,3,23,25,30);a.rect(b,6,16,22,22);a.rect(b,9,9,19,15);a.rect(l,12,3,16,8);a.rect(s,13,11,15,29)
 elif k=='wheelcity':
  a.ring(l,17,12,10,10,2.5);a.line(s,[(17,12),(10,29),(24,29)],3)
  for points in [[(8,7),(26,17)],[(8,17),(26,7)],[(17,2),(17,22)]]:a.line(r,points,2)
  a.rect(w,2,23,7,30);a.rect(b,10,29,25,31)
  for x,y in [(17,2),(26,12),(17,21),(8,12)]:a.rect(s,x-1,y,x+1,y+2)
 elif k=='glassgold':a.poly(b,[(2,27),(6,4),(12,9),(12,27)]);a.poly(l,[(17,27),(17,10),(23,2),(27,27)]);a.line(s,[(10,17),(20,17)],3);a.rect(w,3,29,26,31)
 elif k=='moonroofs':a.oval(l,22,6,5,5);a.hole(24,4,4,4);a.poly(w,[(2,23),(8,15),(14,23),(21,17),(27,24),(27,30),(2,30)]);a.rect(b,9,24,12,28);a.rect(s,4,12,6,19)
 elif k=='colourtown':
  for x,y,c in [(2,9,PINK),(9,5,AQUA),(16,9,GOLD),(23,6,PURPLE)]:
   facade=a.part('Kanalhaus',c);a.rect(facade,x,y,min(x+5,28),23);a.oval(facade,x+2.5,y,2.5,3);a.windows(l,x+1,y+3,1,3,3);a.rect(s,x+2,19,x+3,23)
  a.rect(b,2,26,27,28);a.line(b,[(3,31),(11,30),(19,31),(27,30)],2)
 elif k=='gate':a.oval(r,14,9,8,8);a.rect(s,3,14,25,29);a.hole(14,29,5,10);a.rect(w,2,10,7,29);a.rect(w,21,10,26,29);a.rect(l,4,17,5,24);a.rect(l,23,17,24,24)
city_items=[(1,'street','Neonstraße zwischen Hochhäusern','Neon Street Between Towers'),(2,'harbour','Blaue Hafenstadt','Blue Harbour City'),(3,'domes','Goldene Kuppeltürme','Golden Domed Towers'),(4,'oldtown','Altstadt im Abendlicht','Old Town at Dusk'),(6,'citybridge','Brücke über den Stadtfluss','Bridge Over the City River'),(7,'rooftops','Dächer im Morgenlicht','Rooftops in Morning Light'),(8,'viaduct','Stadtbahn bei Nacht','City Railway at Night'),(9,'needle','Silberne Skyline','Silver Skyline'),(10,'observatory','Sternwarte über der Stadt','Observatory Above the City'),(11,'shop','Neonviertel','Neon District'),(12,'sailtowers','Hochhäuser am Wasser','Towers by the Water'),(13,'market','Marktplatz im Sommer','Summer Market Square'),(14,'snowcity','Winterliche Turmstadt','Winter Tower City'),(15,'artdeco','Türkis am Horizont','Turquoise on the Horizon'),(16,'wheelcity','Riesenrad über der Stadt','Ferris Wheel Above the City'),(17,'glassgold','Glas und Gold','Glass and Gold'),(18,'moonroofs','Mitternachtsdächer','Midnight Rooftops'),(19,'colourtown','Buntes Viertel am Kanal','Colourful Canal Quarter'),(20,'gate','Stadttor im Abendrot','City Gate in the Afterglow')]
thoughts={
'street':('Zwischen hohen Häusern bleibt ein Weg frei. Manchmal reicht es, den nächsten hellen Schritt zu sehen.','A path remains between the tall buildings. Sometimes seeing the next bright step is enough.'),
'harbour':('Am Hafen kommen Wege zusammen. Für einen Augenblick darf auch deine Reise hier anlegen.','Journeys meet at the harbour. For a moment, yours can dock here too.'),
'domes':('Diese Türme tragen goldene Gedanken. Deiner darf gern dazwischen Platz nehmen.','These towers wear golden thoughts. Yours is welcome to settle among them.'),
'oldtown':('Kein Dach ist ganz wie das andere. Gerade deshalb passen sie so schön zusammen.','No roof is quite like another. That is precisely why they fit so beautifully together.'),
'citybridge':('Eine Brücke beginnt an zwei Ufern. Ein guter Gedanke darf auch einmal die Seite wechseln.','A bridge begins on two banks. A good thought can change sides now and then.'),
'rooftops':('Oben wird es schon hell. Unten darf der Tag noch ein bisschen Anlauf nehmen.','It is already getting light up above. Down below, the day can take its time.'),
'viaduct':('Über den Bögen fährt die Nacht weiter. Für dich hält sie gerade einen kleinen Moment an.','Night travels on above the arches. For you, it pauses for a little moment.'),
'needle':('Ein Turm zeigt nach oben. Dein Erfolg braucht heute keine zusätzliche Höhe.','A tower points upwards. Your success needs no extra height today.'),
'observatory':('Über den Dächern bleibt Platz für Fragen. Nicht jede davon muss heute eine Antwort bekommen.','Above the rooftops there is room for questions. Not every one needs an answer today.'),
'shop':('Ein kleines Schaufenster, ein großes Leuchten. Manchmal genügt ein einziger freundlicher Blick.','A little shop window, a big glow. Sometimes one friendly glance is enough.'),
'sailtowers':('Die Häuser stehen, als wollten sie Segel setzen. Das Wasser übernimmt derweil die Bewegung.','The buildings stand as if about to set sail. Meanwhile, the water does the moving.'),
'market':('Der Brunnen hat keine Einkaufsliste. Er steht einfach da und macht den Platz ein wenig schöner.','The fountain has no shopping list. It simply stands there, making the square a little lovelier.'),
'snowcity':('Der Schnee hat die Dächer leiser gemacht. Du darfst die Gedanken darunter kurz zur Ruhe legen.','Snow has quietened the rooftops. You can let the thoughts beneath them rest for a moment.'),
'artdeco':('Stufe für Stufe wird der Turm schmaler. Schritt für Schritt wurde dein Rätsel klarer.','Step by step the tower grows narrower. Step by step your puzzle grew clearer.'),
'wheelcity':('Das Rad kehrt immer wieder zurück. Der Blick von oben darf trotzdem jedes Mal neu sein.','The wheel comes round again and again. The view from the top can still be new every time.'),
'glassgold':('Zwei unterschiedliche Türme teilen sich eine Verbindung. Zusammen sieht die Sache gleich interessanter aus.','Two different towers share a connection. Together, the scene becomes more interesting.'),
'moonroofs':('Die Dächer liegen unter einem kleinen Mond. Heute muss die Nacht nichts weiter erklären.','The rooftops lie beneath a little moon. Tonight needs no further explanation.'),
'colourtown':('Ein buntes Viertel muss sich nicht auf eine Lieblingsfarbe einigen.','A colourful neighbourhood does not have to agree on one favourite colour.'),
'gate':('Das Tor ist offen. Der nächste kleine Aufbruch darf warten, bis du bereit bist.','The gate is open. Your next little departure can wait until you are ready.')}
for i,k,t,en in city_items:add(path('skylines',i),t,en,lambda a,k=k:city(a,k),*thoughts[k])
def main():
 data=json.dumps({'version':1,'entries':RECIPES},ensure_ascii=False,indent=2)
 data=re.sub(r'("cells": )(\[\n.*?\n        \])',lambda match:match[1]+json.dumps(json.loads(match[2]),separators=(',',':')),data,flags=re.S)
 (ROOT/'collections/variety_recipes.json').write_text(data+'\n',encoding='utf-8');print('Prepared',len(RECIPES),'distinct editable scenes')
if __name__=='__main__':main()
