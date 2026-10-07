"""Curated material colors; preserve every baked arrow and its solution order."""
import json, hashlib, colorsys
from collections import Counter
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,v): (ROOT/p).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
GREEN='55ec91'; WOOD='db975d'; WHITE='e4f5ff'; METAL='90cce8'; GOLD='ffd35e'; RED='ff637d'; BLUE='66cfff'; PURPLE='b592ff'; DARK='7893b2'; ORANGE='ffa35d'
def box(name,color,x0=0,y0=0,x1=1,y1=1):return dict(name=name,color=color,shape='box',bounds=[x0,y0,x1,y1])
def ellipse(name,color,x=.5,y=.5,rx=.25,ry=.25):return dict(name=name,color=color,shape='ellipse',bounds=[x,y,rx,ry])
def base(name,color,*regions):return dict(base=dict(name=name,color=color),regions=list(regions),mode=3,strength=.48)
PROFILES={}
def setp(keys,profile):
 for key in keys.split():PROFILES['new_'+key]=profile
# Anatomical colors, demonstration dyes and medical materials.
setp('heart_organ',base('Herzmuskel','ff557d',box('Große Gefäße',BLUE,0,0,1,.26)))
setp('lungs',base('Lungengewebe','ff92af',box('Luftröhre',WHITE,.38,0,.62,.44)))
setp('brain',base('Gehirnwindungen','ffa4c9',box('Hirnstamm',PURPLE,.4,.70,.7,1)))
setp('pelvis_bone forearm',base('Knochen',WHITE,box('Gelenkflächen',METAL,0,.78,1,1)))
setp('anatomy',base('Körperkontur','ffc291',box('Kopf und Hals','ffe0b5',0,0,1,.28),box('Innere Organe','ff7c99',.30,.35,.70,.69)))
setp('human_ear nose_front finger_print',base('Haut','ffc49b',ellipse('Sanfte Vertiefung','ef9e92',.5,.5,.3,.3)))
setp('tongue',base('Zunge','ff6688',box('Ansatz','ffc0cb',0,0,1,.26)))
setp('eyeball',base('Augapfel',WHITE,ellipse('Iris','51d9d1',.5,.5,.28,.32),ellipse('Pupille',DARK,.5,.5,.13,.17)))
setp('stethoscope',base('Schlauch','a78bfb',box('Ohrbügel',METAL,0,0,1,.35),box('Bruststück',METAL,0,.76,1,1)))
setp('syringe',base('Spritzenkörper',BLUE,box('Kolben und Skala',WHITE,0,0,1,.30),box('Kanüle',METAL,0,.74,1,1)))
setp('medical_thermometer thermometer_scale',base('Glas und Skala',WHITE,box('Messflüssigkeit',RED,.38,.35,.67,1)))
setp('medical_drip',base('Schlauch und Halterung',METAL,box('Infusionsbeutel',BLUE,0,0,1,.40),box('Flüssigkeit','4ee9cb',.25,.28,.78,.58)))
setp('bandage_roll arm_bandage',base('Verband',WHITE,box('Gewebe im Schatten','a1cadb',0,.65,1,1)))
setp('hospital',base('Fassade',BLUE,box('Sockel',DARK,0,.77,1,1),box('Zeichen der Hilfe',RED,.32,0,.68,.36)))
setp('hospital_cross',base('Hilfssymbol','ff657e',box('Lichtseite','ffb08b',0,0,.44,1)))
setp('medical_pack',base('Tasche',BLUE,box('Griff',METAL,0,0,1,.22),ellipse('Hilfezeichen',RED,.5,.55,.25,.25)))
setp('crutches',base('Stützen',METAL,box('Polster',PURPLE,0,0,1,.18),box('Gummifüße',DARK,0,.82,1,1)))
setp('tooth',base('Zahnschmelz',WHITE,box('Wurzellicht','a4d9e9',0,.57,1,1)))
setp('toothbrush',base('Griff',BLUE,box('Borsten',WHITE,0,0,1,.30)))
setp('mouth_watering',base('Zähne',WHITE,box('Lippen',RED,0,0,1,.28),box('Lippen',RED,0,.76,1,1)))
setp('rod_of_asclepius',base('Stab',WOOD,box('Schlange',GREEN,0,.18,.43,.87),box('Schlange',GREEN,.57,.18,1,.87)))
setp('herbs_bundle',base('Blätter',GREEN,box('Stiele',WOOD,0,.70,1,1),box('Bindeband',GOLD,0,.61,1,.73)))
setp('mortar',base('Steinmörser',METAL,box('Stößel',WOOD,0,0,1,.43)))
# Scientific illustrations use meaningful component colors, not random confetti.
setp('abacus',base('Holzrahmen',WOOD,box('Obere Kugeln',RED,.13,.16,.86,.43),box('Mittlere Kugeln',BLUE,.13,.44,.86,.66),box('Untere Kugeln',GOLD,.13,.67,.86,.85)))
setp('triangle_target pentacle',base('Geometrische Linien',PURPLE,box('Vordere Linien',BLUE,0,.45,1,1)))
setp('cube',base('Linke Fläche',BLUE,box('Rechte Fläche',PURPLE,.5,.25,1,1),box('Oberseite',WHITE,0,0,1,.28)))
setp('infinity',base('Linke Schleife',BLUE,box('Rechte Schleife','ff85be',.5,0,1,1)))
setp('prism',base('Glaskörper',BLUE,box('Lichtstrahlen',GOLD,.64,0,1,1),box('Spektralfarbe','ff76b9',.64,.52,1,1)))
setp('pendulum_swing',base('Aufhängung',METAL,box('Pendelkörper',GOLD,0,.63,1,1)))
setp('gyroscope',base('Außenring',METAL,ellipse('Innerer Kreisel',GOLD,.5,.5,.29,.33)))
setp('weight',base('Metallgewicht',METAL,box('Griff',GOLD,0,0,1,.26)))
setp('chemical_drop',base('Reagenz',GREEN,box('Glanzseite',BLUE,0,0,.38,1)))
setp('test_tubes',base('Glas',WHITE,box('Rotes Reagenz',RED,0,.44,.34,1),box('Blaues Reagenz',BLUE,.34,.44,.67,1),box('Grünes Reagenz',GREEN,.67,.44,1,1)))
setp('molecule',base('Bindungen',METAL,ellipse('Atom links',RED,.2,.5,.22,.26),ellipse('Atom rechts',BLUE,.78,.5,.22,.26),ellipse('Atom oben',GOLD,.5,.17,.23,.23)))
setp('crystal_growth',base('Kristallflächen','56dfc8',box('Facetten',PURPLE,.53,0,1,1),box('Gestein',WOOD,0,.80,1,1)))
setp('microscope',base('Gehäuse',METAL,box('Optik',BLUE,0,0,1,.37),box('Standfuß',DARK,0,.78,1,1)))
setp('dna1',base('Linker Strang',BLUE,box('Rechter Strang','ff87bc',.55,0,1,1),box('Basenpaare',GOLD,.35,0,.55,1)))
setp('cell',base('Zellmembran','62e8ca',ellipse('Zellkern',PURPLE,.55,.48,.26,.27),box('Zellbestandteile',GOLD,0,.75,1,1)))
setp('antibody',base('Antikörper',BLUE,box('Bindungsstellen','ff85c0',0,0,1,.30)))
setp('bacteria',base('Zellhülle','6be7ab',box('Zellinneres',PURPLE,.29,.25,.72,.78),box('Geißeln',GOLD,0,.80,1,1)))
setp('ammonite_fossil trilobite archaeopteryx_fossil fossil',base('Fossil','eac38a',box('Mineralisierte Schatten','c79af0',0,.61,1,1)))
setp('geode',base('Gestein',WOOD,ellipse('Kristalle',PURPLE,.53,.53,.29,.39),ellipse('Kristalllicht',BLUE,.5,.5,.16,.24)))
setp('scales balance_scale',base('Gestell',METAL,box('Waagschalen',GOLD,0,.39,.38,.77),box('Waagschalen',GOLD,.62,.39,1,.77),box('Sockel',WOOD,0,.82,1,1)))
setp('measure_tape',base('Gehäuse',ORANGE,box('Maßband',GOLD,.45,.58,1,1)))
setp('stopwatch alarm_clock',base('Gehäuse',BLUE,ellipse('Zifferblatt',WHITE,.5,.54,.29,.30),box('Bedienelemente',GOLD,0,0,1,.18)))
setp('archive_research',base('Papier',WHITE,box('Einband',WOOD,0,.72,1,1),box('Markierung',GOLD,.65,0,1,.4)))
# Animals: body, wings, shell, feet and beaks.
setp('praying_mantis',base('Körper',GREEN,box('Fangbeine','b6f46e',0,.38,.43,1)))
setp('dragonfly',base('Flügel',BLUE,box('Körper','70e6ab',.41,0,.61,1)))
setp('ant earwig long_antennae_bug',base('Panzer','d99561',box('Beine und Fühler',GOLD,0,0,1,.24),box('Hinterleib','e78373',0,.65,1,1)))
setp('ladybug',base('Flügeldecken',RED,box('Kopf und Fühler',DARK,0,0,1,.24),box('Trennlinie',DARK,.44,.24,.57,.83),ellipse('Punkte',DARK,.23,.48,.13,.15),ellipse('Punkte',DARK,.78,.48,.13,.15)))
setp('scarab_beetle',base('Panzer','4fdfbc',box('Kopf',GOLD,0,0,1,.26),box('Beine',METAL,0,.75,1,1)))
setp('flying_beetle',base('Flügeldecken',GREEN,box('Kopf',WOOD,0,0,1,.3),box('Unterflügel',BLUE,0,.55,.27,1),box('Unterflügel',BLUE,.73,.55,1,1)))
setp('bee',base('Körper',GOLD,box('Kopf',WOOD,.60,0,1,.5),box('Flügel',WHITE,0,0,.55,.37),box('Hinterleibzeichnung',WOOD,0,.54,.5,.71)))
setp('spider_web',base('Spinnfäden',WHITE,ellipse('Morgenlicht',BLUE,.5,.5,.26,.26)))
setp('hanging_spider',base('Spinne',PURPLE,box('Faden',WHITE,0,0,1,.33)))
setp('scorpion',base('Panzer',ORANGE,box('Scheren',GOLD,0,0,1,.40),box('Schwanz',RED,.67,.3,1,1)))
setp('tick',base('Körper',WOOD,box('Beine',DARK,0,0,1,.34)))
setp('gecko chameleon_glyph',base('Körper',GREEN,box('Bauch und Füße','c7ee79',0,.6,1,1),box('Schwanz','59d9ce',.75,0,1,1)))
setp('snake_spiral',base('Schuppen',GREEN,box('Bauch',GOLD,0,.67,1,1)))
setp('sea_turtle',base('Flossen',GREEN,ellipse('Panzer','c49a67',.51,.50,.28,.33)))
setp('snake_egg',base('Schlange',GREEN,box('Eierschale',WHITE,0,.58,1,1)))
setp('axolotl',base('Körper','ffa8c5',box('Federkiemen','ff658f',0,0,.29,.45),box('Federkiemen','ff658f',.71,0,1,.45),box('Schwanz','c5a6ff',0,.73,1,1)))
setp('salamander',base('Körper',DARK,box('Rückenzeichnung',GOLD,.32,0,.68,.85)))
setp('frog',base('Körper',GREEN,box('Bauch','d7ed83',.24,.42,.75,1)))
setp('frog_prince',base('Frosch',GREEN,box('Krone',GOLD,0,0,1,.25),box('Bauch','b9eda1',.3,.55,.75,1)))
setp('anteater',base('Fell',WOOD,box('Schnauze','eac8a0',.63,0,1,.58),box('Vorderbeine',DARK,.25,.63,.60,1)))
setp('armadillo',base('Panzer','d5ad76',box('Kopf und Beine',WOOD,0,.63,1,1)))
setp('bat',base('Flügel',PURPLE,box('Körper',WOOD,.36,0,.65,1)))
setp('hedgehog',base('Stacheln',WOOD,box('Schnauze und Bauch','f4c78e',.65,.3,1,1),box('Schnauze und Bauch','f4c78e',0,.78,1,1)))
setp('kangaroo',base('Fell',WOOD,box('Brust und Bauch','ffd6a0',.4,.33,.73,.79)))
setp('pelican',base('Gefieder',WHITE,box('Schnabel',GOLD,.65,.06,1,.5),box('Füße',ORANGE,0,.82,1,1)))
setp('flamingo',base('Gefieder','ff8bb6',box('Schnabel',GOLD,.78,0,1,.20),box('Beine',ORANGE,0,.64,1,1)))
setp('woodpecker',base('Gefieder',DARK,box('Rote Haube',RED,0,0,1,.22),box('Bauch',WHITE,.44,.4,.78,.8),box('Schnabel',GOLD,.60,.18,.83,.38),box('Baumstamm',WOOD,.79,0,1,1)))
setp('kiwi_bird',base('Gefieder',WOOD,box('Schnabel',GOLD,.57,0,1,.65),box('Beine',ORANGE,0,.76,1,1)))
setp('stork_delivery',base('Gefieder',WHITE,box('Schnabel',ORANGE,.6,0,1,.3),box('Bündel',BLUE,0,.64,1,1)))
setp('nautilus_shell',base('Schale','ffd6a1',box('Schalenzeichnung',ORANGE,.48,0,1,1)))
setp('seahorse',base('Körper',GOLD,box('Bauch',ORANGE,.46,.25,.78,.73)))
setp('manta_ray',base('Flügel',BLUE,box('Körper',WHITE,.38,0,.64,.70),box('Schwanz',PURPLE,0,.79,1,1)))
setp('coral',base('Korallenäste','ff83a6',box('Ansatz',ORANGE,0,.77,1,1)))
# Plant materials and seasonally intentional leaf palettes.
setp('willow_tree beech treehouse',base('Laub',GREEN,box('Stamm',WOOD,.41,.42,.61,1)))
setp('birch_trees',base('Laub',GREEN,box('Birkenstämme',WHITE,.06,.27,.28,1),box('Birkenstämme',WHITE,.74,.27,1,1)))
setp('tree_roots plant_roots',base('Wurzeln',WOOD,box('Pflanzengrün',GREEN,0,0,1,.43)))
setp('ginkgo_leaf oak_leaf monstera_leaf fern agave',base('Blattgrün',GREEN,box('Blattrippe','c0f183',.43,.45,.59,1)))
setp('carnivorous_plant',base('Blätter',GREEN,box('Fangblatt innen','ff8797',.25,0,.85,.48)))
setp('banana_bunch',base('Frucht',GOLD,box('Stiel',GREEN,0,0,1,.22)))
setp('chanterelles',base('Pilzhüte',GOLD,box('Stiele','f4c393',0,.55,1,1)))
setp('mushroom_gills mushrooms_cluster',base('Pilzhüte','ff857f',box('Lamellen und Stiele','ffe1b4',0,.53,1,1)))
setp('gardening_shears scissors',base('Klingen',METAL,box('Griffe','ff86bc',0,.53,1,1)))
setp('plant_watering',base('Pflanzengrün',GREEN,box('Wasser',BLUE,0,0,.45,.57),box('Topf',ORANGE,0,.76,1,1)))
setp('cotton_flower',base('Blüte',WHITE,box('Stängel und Blätter',GREEN,0,.47,1,1)))
setp('dandelion_flower',base('Blüte',GOLD,box('Stängel und Blätter',GREEN,0,.50,1,1)))
setp('flower_pot',base('Blätter',GREEN,box('Blüten','ff88b2',.32,0,.67,.24),box('Blüten','ff88b2',.80,.2,1,.40),box('Terrakottatopf',ORANGE,0,.66,1,1)))
# Homes and recognizable material contrasts.
setp('house_keys',base('Schlüssel',GOLD,box('Schlüsselring',METAL,0,0,1,.3)))
setp('dog_house',base('Holzwände',WOOD,box('Dach',RED,0,0,1,.35)))
setp('igloo',base('Schneeblöcke',WHITE,box('Eislicht',BLUE,0,.66,1,1)))
setp('gas_stove fridge kitchen_tap pressure_cooker washing_machine sewing_machine',base('Gehäuse',WHITE,box('Bedienelemente',BLUE,0,0,1,.28),box('Metallteile',METAL,0,.72,1,1)))
setp('armchair sofa',base('Polster','ff9cb6',box('Füße und Gestell',WOOD,0,.80,1,1)))
setp('rocking_chair garden_bench desk wardrobe',base('Holz',WOOD,box('Beschläge',METAL,0,.81,1,1)))
setp('fireplace',base('Mauerwerk','e9ad83',ellipse('Feuer',ORANGE,.5,.63,.3,.32),ellipse('Flammenkern',GOLD,.5,.54,.16,.22)))
setp('bookshelf',base('Regal',WOOD,box('Bücher links',BLUE,.08,.12,.35,.77),box('Bücher Mitte','ff85b3',.36,.12,.62,.77),box('Bücher rechts',GREEN,.65,.12,.9,.77)))
setp('bed bunk_beds',base('Bettgestell',WOOD,box('Bettwäsche',BLUE,.13,.25,.85,.66),box('Kissen',WHITE,.12,.25,.40,.52)))
setp('bed_lamp desk_lamp',base('Gestell',METAL,box('Lampenschirm',GOLD,0,0,1,.40),box('Sockel',BLUE,0,.80,1,1)))
setp('bathtub shower sink toilet',base('Keramik',WHITE,box('Wasser und Armatur',BLUE,0,0,1,.31),box('Keramikschatten','a6d0ed',0,.77,1,1)))
setp('plunger',base('Stiel',WOOD,box('Saugglocke',RED,0,.67,1,1)))
setp('toy_mallet',base('Holzgriff',WOOD,box('Spielzeugkopf',BLUE,0,0,1,.42),box('Farbdetail',RED,.65,0,1,.42)))
setp('rocking_horse',base('Holzpferd',WOOD,box('Schaukelkufen',RED,0,.83,1,1),box('Sattel',BLUE,.27,.4,.68,.62)))
setp('office_chair',base('Polster',BLUE,box('Gestell',METAL,0,.58,1,1)))
setp('vacuum_cleaner',base('Gehäuse',RED,box('Schlauch und Rohr',METAL,0,0,1,.46)))
setp('broom',base('Stiel',WOOD,box('Borsten',GOLD,0,.65,1,1)))
setp('pearl_necklace',base('Perlen',WHITE,box('Verschluss',GOLD,0,0,1,.19)))
setp('bow_tie',base('Stoff',RED,box('Knoten',GOLD,.4,.25,.61,.77)))
setp('umbrella',base('Schirmstoff',BLUE,box('Zweites Stofffeld',PURPLE,.53,0,1,.61),box('Griff',WOOD,0,.62,1,1)))
setp('high_heel',base('Schuh',RED,box('Sohle und Absatz',GOLD,0,.72,1,1)))
# Food and craft.
setp('asparagus broccoli',base('Gemüsegrün',GREEN,box('Stängel','b8ed8b',0,.62,1,1)))
setp('beet',base('Knolle','ff679c',box('Blätter',GREEN,0,0,1,.37)))
setp('garlic',base('Knolle','ffebcb',box('Stängel',GREEN,0,0,1,.23)))
setp('corn',base('Maiskörner',GOLD,box('Hüllblätter',GREEN,0,.59,.30,1),box('Hüllblätter',GREEN,.7,.50,1,1)))
setp('pretzel baguette croissant',base('Kruste','f5b66f',box('Backlicht','ffe4a0',0,0,1,.38)))
setp('chocolate_bar',base('Schokolade','d1916b',box('Verpackung',RED,0,.65,1,1)))
setp('honeycomb',base('Wachs',GOLD,box('Honig',ORANGE,0,.6,1,1)))
setp('coffee_beans',base('Kaffeebohnen',WOOD,box('Röstlicht','f2bc81',0,0,.44,1)))
setp('coffee_pot',base('Metall',METAL,box('Griff',DARK,.69,.17,1,.73),box('Deckel',GOLD,0,0,1,.22)))
setp('corked_tube',base('Glas',BLUE,box('Korken',WOOD,0,0,1,.22),box('Inhalt','ff8db5',0,.6,1,1)))
setp('kitchen_scale',base('Gehäuse',BLUE,box('Waagschale',METAL,0,0,1,.35)))
setp('whisk corkscrew',base('Metall',METAL,box('Griff',WOOD,0,.67,1,1)))
setp('rolling_pin',base('Holzrolle','f2c18d',box('Griffe',WOOD,0,0,.20,1),box('Griffe',WOOD,.80,0,1,1)))
setp('sushis',base('Reis',WHITE,box('Fisch und Füllung','ff908e',0,0,1,.38),box('Algenblatt',GREEN,0,.68,1,1)))
setp('tacos',base('Teig',GOLD,box('Salat',GREEN,0,0,1,.35),box('Tomaten',RED,.25,.25,.67,.43)))
setp('noodles',base('Schale',BLUE,box('Nudeln',GOLD,0,0,1,.53),box('Stäbchen',WOOD,0,0,1,.17)))
setp('dumpling',base('Teig','ffe0a0',box('Falten','efb986',0,0,1,.42)))
setp('hand_saw chisel',base('Metall',METAL,box('Holzgriff',WOOD,0,0,.40,.62)))
setp('wood_pile wooden_crate spinning_wheel',base('Holz',WOOD,box('Schnittflächen','f6ce98',0,0,1,.35)))
setp('anvil metal_bar horseshoe',base('Metall',METAL,box('Materialschatten',DARK,0,.65,1,1)))
setp('blacksmith',base('Werkstatt',METAL,box('Feuer und Glut',ORANGE,0,.65,1,1),box('Schürze',WOOD,.30,.25,.65,.72)))
setp('electrical_resistance',base('Anschlussdrähte',METAL,box('Widerstandskörper',GOLD,.3,.2,.70,.8)))
setp('electrical_socket plug',base('Isolierung',WHITE,box('Kontakte',GOLD,0,.58,1,1)))
setp('brick_pile',base('Ziegel',ORANGE,box('Gebrannte Kanten','dc7c77',0,.65,1,1)))
setp('paint_roller',base('Griff',WOOD,box('Farbwalze','ff8fb9',0,0,1,.38),box('Metallbügel',METAL,0,.39,1,.62)))
setp('paint_bucket',base('Eimer',METAL,box('Farbe','ff8fb9',0,0,1,.33)))
setp('wheelbarrow',base('Wanne',GREEN,box('Gestell und Rad',METAL,0,.58,1,1)))
setp('sewing_needle',base('Nadel',METAL,box('Faden',RED,.55,0,1,1)))
setp('yarn',base('Wolle','ff86b2',box('Abrollender Faden',PURPLE,0,.72,1,1)))
setp('amphora painted_pottery broken_pottery water_jug',base('Terrakotta',ORANGE,box('Glasurband',BLUE,0,.44,1,.62),box('Rand',GOLD,0,0,1,.17)))
setp('watering_can',base('Gießkanne',GREEN,box('Brause',METAL,.72,.1,1,.66)))
setp('chef_toque',base('Stoff',WHITE,box('Mützenband',RED,0,.78,1,1)))
setp('diving_helmet',base('Kupferhelm',ORANGE,ellipse('Sichtfenster',BLUE,.5,.46,.28,.29),box('Halsring',METAL,0,.76,1,1)))
# Historical technology and contemporary mechanisms.
setp('typewriter',base('Gehäuse',METAL,box('Papier',WHITE,.12,0,.89,.33),box('Tasten',GOLD,0,.60,1,1)))
setp('quill_ink feather',base('Feder',WHITE,box('Tintenfass',BLUE,0,.67,1,1)))
setp('wax_tablet',base('Holzrahmen',WOOD,box('Wachs',GOLD,.14,.14,.85,.80)))
setp('printing_press',base('Holzgestell',WOOD,box('Pressmechanik',METAL,.31,.12,.67,.6),box('Papier',WHITE,0,.62,1,.8)))
setp('newspaper scroll_unfurled',base('Papier','fff0d0',box('Schrift',BLUE,.14,.25,.86,.8)))
setp('gramophone',base('Holzkasten',WOOD,box('Messingtrichter',GOLD,0,0,1,.55),box('Tonarm',METAL,0,.55,1,.7)))
setp('vintage_robot robot_golem mechanical_arm delivery_drone',base('Metall',METAL,box('Anzeigen und Sensoren',BLUE,0,0,1,.30),box('Gelenke und Antrieb',GOLD,0,.65,1,1)))
setp('pocket_radio',base('Gehäuse',WOOD,box('Antenne',METAL,0,0,1,.21),box('Skala',BLUE,.52,.22,1,.53)))
setp('cuckoo_clock',base('Holzgehäuse',WOOD,ellipse('Zifferblatt',WHITE,.5,.40,.24,.21),box('Gewichte',GOLD,0,.7,1,1)))
setp('gears',base('Zahnräder',METAL,box('Messingräder',GOLD,.54,0,1,1)))
setp('spring',base('Federstahl',METAL,box('Reflexlicht',BLUE,0,0,.38,1)))
setp('hourglass',base('Glas',BLUE,box('Holzrahmen',WOOD,0,0,1,.18),box('Holzrahmen',WOOD,0,.82,1,1),box('Sand',GOLD,.3,.61,.72,.81)))
setp('wind_turbine',base('Rotor und Turm',WHITE,box('Antrieb',BLUE,.40,.25,.65,.49)))
setp('water_mill',base('Mühlenhaus',WOOD,box('Wasserrad',GOLD,.55,.4,1,1),box('Wasser',BLUE,0,.83,1,1)))
setp('nuclear_plant',base('Beton',METAL,box('Dampf',WHITE,0,0,1,.30),box('Sockellicht',BLUE,0,.79,1,1)))
# Space and travel: believable materials with vivid exhaust, fabric and water.
setp('comet_spark',base('Schweif',BLUE,ellipse('Kern',WHITE,.72,.72,.23,.23),box('Schweifsaum',PURPLE,0,0,.35,1)))
setp('asteroid',base('Gestein',WOOD,box('Minerale',PURPLE,.5,0,1,1)))
setp('eclipse',base('Sonnenkorona',GOLD,ellipse('Mondrand',PURPLE,.5,.5,.32,.32)))
setp('space_shuttle',base('Rumpf',WHITE,box('Flügel',BLUE,0,.44,.3,1),box('Flügel',BLUE,.7,.44,1,1),box('Triebwerke',ORANGE,0,.80,1,1)))
setp('space_suit',base('Raumanzug',WHITE,box('Helmvisier',GOLD,.24,0,.78,.26),box('Bedienfeld',BLUE,.32,.35,.70,.59)))
setp('observatory',base('Gebäude',WOOD,box('Kuppel',BLUE,0,0,1,.54)))
setp('satellite_communication',base('Metallkörper',WHITE,box('Solarpaneele',BLUE,0,.25,.32,.82),box('Solarpaneele',BLUE,.68,.25,1,.82),box('Antenne',GOLD,0,0,1,.24)))
setp('orbital',base('Umlaufbahnen',BLUE,ellipse('Himmelskörper',GOLD,.5,.5,.24,.24)))
setp('biplane glider hang_glider',base('Flügel',GOLD,box('Rumpf',BLUE,.4,0,.63,1),box('Leitwerk',RED,0,.76,1,1)))
setp('parachute',base('Schirm',RED,box('Stoffbahn',GOLD,.35,0,.65,.54),box('Leinen und Last',METAL,0,.55,1,1)))
setp('jetpack',base('Gehäuse',METAL,box('Flammen',ORANGE,0,.7,1,1),box('Energieanzeige',BLUE,.33,.28,.65,.52)))
setp('chariot',base('Wagen',WOOD,box('Metallbeschläge',GOLD,0,.65,1,1)))
setp('steam_locomotive',base('Lokomotive',DARK,box('Räder',RED,0,.70,1,1),box('Dampf',WHITE,0,0,1,.30),box('Kessel',GOLD,.25,.4,.7,.68)))
setp('egyptian_sphinx',base('Sandstein','f7c781',box('Kopfschmuck',BLUE,0,0,1,.32)))
setp('pagoda',base('Wände',GOLD,box('Oberes Dach',RED,0,0,1,.30),box('Dachbänder',RED,0,.43,1,.55),box('Dachbänder',RED,0,.74,1,.85)))
setp('pisa_tower',base('Marmor','ffe3b4',box('Arkadenlicht',BLUE,0,.65,1,1)))
setp('rialto_bridge',base('Stein',WHITE,box('Dach',ORANGE,0,0,1,.28),box('Sockellicht',BLUE,0,.77,1,1)))
setp('campfire',base('Holzscheite',WOOD,box('Flammen',ORANGE,0,0,1,.68),ellipse('Flammenkern',GOLD,.5,.36,.22,.28)))
setp('sleeping_bag',base('Stoff',BLUE,box('Futter',GOLD,0,0,1,.25)))
setp('rope_coil',base('Seil','f2c58b',box('Seilschatten',WOOD,0,.65,1,1)))
# History, literature and cultural art.
setp('ancient_columns greek_temple castle_ruins drawbridge tower_flag mayan_pyramid',base('Stein','e4c698',box('Sockel',WOOD,0,.78,1,1),box('Dach und Fahne',RED,0,0,1,.22)))
setp('roman_toga',base('Stoff','fff0d0',box('Saumband',PURPLE,0,.75,1,1)))
setp('laurels shamrock',base('Blätter',GREEN,box('Band und Stiele',GOLD,0,.78,1,1)))
setp('closed_barbute crossed_swords',base('Stahl',METAL,box('Griffe und Zier',GOLD,0,.66,1,1)))
setp('medieval_pavilion',base('Zeltstoff',RED,box('Zweite Stoffbahn',WHITE,.35,0,.63,.82),box('Fahne',GOLD,0,0,1,.18)))
setp('dinosaur_bones',base('Fossile Knochen','ffe3b8',box('Sockel',WOOD,0,.88,1,1)))
setp('stone_tablet',base('Stein','e5c499',box('Schriftspuren',BLUE,.2,.25,.82,.8)))
setp('oil_lamp',base('Lampenkörper',GOLD,box('Flamme',ORANGE,0,0,1,.42),box('Standfuß',WOOD,0,.78,1,1)))
setp('egyptian_profile',base('Haut',WOOD,box('Kopfschmuck',BLUE,0,0,1,.30),box('Schmuck',GOLD,0,.66,1,1)))
setp('hieroglyph_y',base('Zeichen',GOLD,box('Farbakzent',BLUE,0,.65,1,1)))
setp('byzantin_temple',base('Mauerwerk','ffdab0',box('Kuppel',GOLD,0,0,1,.44),box('Sockel',BLUE,0,.8,1,1)))
setp('torii_gate',base('Holzpfosten',RED,box('Dachbalken',DARK,0,0,1,.22),box('Querbalken',GOLD,0,.27,1,.39)))
setp('philosopher_bust stone_bust venus_of_willendorf',base('Skulptur','f2d8be',box('Materialschatten','b8badb',0,.7,1,1)))
setp('open_book',base('Papier','fff0d0',box('Einband',RED,0,.79,1,1)))
setp('book_pile',base('Buch oben',BLUE,box('Buch Mitte',RED,0,.34,1,.67),box('Buch unten',GOLD,0,.68,1,1)))
setp('windmill',base('Mühlenhaus',WOOD,box('Flügel',WHITE,0,0,1,.51),box('Dach',RED,.35,.2,.7,.38)))
setp('submarine',base('Nautilus',GOLD,box('Bullaugen',BLUE,.22,.35,.76,.62),box('Schraube',METAL,.79,0,1,1)))
setp('drink_me',base('Fläschchen',BLUE,box('Etikett',WHITE,.16,.41,.84,.67),box('Trank',PURPLE,0,.70,1,1),box('Verschluss',GOLD,0,0,1,.20)))
setp('insect_jaws',base('Panzer',PURPLE,box('Mundwerkzeuge',ORANGE,0,.54,1,1)))
setp('bookmark',base('Leseband',RED,box('Zierkante',GOLD,0,.75,1,1)))
setp('scroll_quill',base('Pergament','ffe7b5',box('Feder',WHITE,.55,0,1,1)))
setp('book_cover',base('Einband',BLUE,box('Buchrücken',WOOD,0,0,.22,1),box('Zierprägung',GOLD,.30,.25,.8,.6)))
# Sports, stage, tabletop games and fantastic creatures.
setp('surf_board',base('Brett',BLUE,box('Dekorstreifen',GOLD,.32,0,.58,1)))
setp('water_polo beach_ball',base('Ball',WHITE,box('Blaues Segment',BLUE,0,0,.35,1),box('Rotes Segment',RED,.68,0,1,1)))
setp('boxing_ring',base('Ringseile',RED,box('Matte',BLUE,.13,.32,.86,.78),box('Pfosten',METAL,0,.79,1,1)))
setp('fencer',base('Schutzkleidung',WHITE,box('Maske',DARK,0,0,1,.20),box('Waffe',METAL,.60,.23,1,.65)))
setp('high_kick',base('Sportkleidung',BLUE,box('Haut','ffd0a2',0,0,1,.23),box('Haut','ffd0a2',.70,.30,1,.60)))
setp('chess_knight chess_rook meeple',base('Spielfigur',GOLD,box('Sockellicht',WOOD,0,.79,1,1)))
setp('backgammon',base('Brett',WOOD,box('Linkes Spielfeld',RED,0,.16,.46,.83),box('Rechtes Spielfeld',WHITE,.54,.16,1,.83)))
setp('domino_tiles',base('Spielsteine',WHITE,box('Augenzeichnung',BLUE,.32,.2,.74,.79)))
setp('juggler',base('Kleidung',PURPLE,box('Jonglierbälle',GOLD,0,0,1,.3),box('Kopf','ffd0a2',.3,.3,.67,.48)))
setp('unicycle',base('Metallrahmen',METAL,box('Sattel',RED,0,0,1,.24),box('Rad',BLUE,0,.52,1,1)))
setp('tightrope',base('Seil',GOLD,box('Artist',PURPLE,0,0,1,.70),box('Kopf','ffd0a2',.3,0,.7,.20)))
setp('drama_masks',base('Heitere Maske',GOLD,box('Tragische Maske',PURPLE,.50,0,1,1)))
setp('theater_curtains',base('Vorhang',RED,box('Saum',GOLD,0,0,1,.23),box('Bühne',WOOD,0,.89,1,1)))
setp('film_projector',base('Gehäuse',BLUE,box('Filmspulen',METAL,0,0,1,.43),box('Lichtstrahl',GOLD,.74,.35,1,.82)))
setp('film_spool',base('Filmspule',METAL,box('Filmstreifen',GOLD,0,.67,1,1)))
setp('director_chair',base('Holzgestell',WOOD,box('Stoff',RED,0,0,1,.55)))
setp('carousel',base('Karussell',GOLD,box('Dach',RED,0,0,1,.34),box('Pferde',WHITE,0,.42,1,.73),box('Sockel',BLUE,0,.80,1,1)))
setp('griffin_symbol',base('Löwenkörper',GOLD,box('Adlerflügel',WHITE,0,0,1,.51),box('Schnabel',ORANGE,.76,0,1,.34)))
setp('unicorn pegasus',base('Fell',WHITE,box('Mähne',PURPLE,0,0,1,.38),box('Horn',GOLD,.40,0,.69,.15)))
setp('dragon_head',base('Schuppen',GREEN,box('Hörner',GOLD,0,0,1,.30),box('Maul',ORANGE,.5,.60,1,1)))
setp('mermaid',base('Haut','ffcfa6',box('Haare',RED,0,0,1,.25),box('Fischschwanz','55dfc8',0,.53,1,1)))
setp('minotaur',base('Fell',WOOD,box('Hörner',WHITE,0,0,1,.25),box('Rüstung',GOLD,0,.6,1,1)))
setp('sea_serpent',base('Schuppen',BLUE,box('Bauch',GOLD,0,.65,1,1)))
setp('portal',base('Portalrahmen',PURPLE,box('Energiesaum',BLUE,.3,0,.75,1),box('Sockel',GOLD,0,.88,1,1)))
setp('cloud_ring',base('Wolken',WHITE,box('Traumlicht',PURPLE,0,.54,1,1)))
# Seasonal colors.
setp('butterfly_flower',base('Blüte','ff83b2',box('Schmetterling',GOLD,0,0,1,.44),box('Stängel',GREEN,0,.73,1,1)))
setp('plant_seed',base('Keimling',GREEN,box('Samen',WOOD,0,.57,1,1)))
setp('ice_pop',base('Fruchteis','ff829f',box('Zweite Eisschicht',GOLD,0,.38,1,.68),box('Holzstiel',WOOD,0,.80,1,1)))
setp('chestnut_leaf maple_leaf',base('Herbstlaub',ORANGE,box('Blattspitzen',GOLD,0,0,1,.32),box('Blattadern','f36f85',0,.65,1,1)))
setp('acorn',base('Eichel',WOOD,box('Fruchtbecher',GOLD,0,0,1,.45)))
setp('carnival_mask',base('Maske',PURPLE,box('Linke Verzierung',GOLD,0,0,.35,1),box('Rechte Verzierung','ff8fba',.7,0,1,1)))
setp('jester_hat',base('Kappe',PURPLE,box('Linke Zacke',RED,0,0,.35,.7),box('Rechte Zacke',GREEN,.65,0,1,.7),box('Schellen',GOLD,0,.8,1,1)))
setp('grain_bundle',base('Ähren',GOLD,box('Stängel',WOOD,0,.67,1,1),box('Bindeband',RED,0,.55,1,.68)))
setp('fruit_bowl',base('Schale',BLUE,box('Apfel',RED,0,0,.40,.63),box('Zitrusfrucht',ORANGE,.4,0,.7,.63),box('Trauben',PURPLE,.7,0,1,.63)))
setp('cornucopia',base('Horn',GOLD,box('Blätter',GREEN,0,0,.6,.28),box('Früchte',RED,0,.3,.37,.69)))
setp('firework_rocket',base('Rakete',RED,box('Spitze',GOLD,0,0,1,.23),box('Stab',WOOD,0,.70,1,1)))
setp('party_popper',base('Hülle',PURPLE,box('Konfetti',GOLD,0,0,.5,.52),box('Konfetti',RED,.5,0,1,.52)))
setp('balloons',base('Ballon',RED,box('Ballon links',BLUE,0,0,.34,.78),box('Ballon rechts',GOLD,.68,0,1,.78),box('Schnüre',WHITE,0,.78,1,1)))
setp('asian_lantern',base('Laterne',RED,box('Rahmen',GOLD,0,0,1,.18),box('Fransen',GOLD,0,.82,1,1)))
setp('diablo_skull',base('Schädel',WHITE,box('Stirndekor',GOLD,0,0,1,.26),box('Dekor links',BLUE,0,.26,.34,.72),box('Dekor rechts','ff86b8',.67,.26,1,.72),box('Kieferdekor',PURPLE,0,.74,1,1)))
setp('feather',base('Feder',WHITE,box('Federkiel',WOOD,0,.73,1,1)))
def inside(region,x,y):
 a,b,c,d=region['bounds']
 return a<=x<=c and b<=y<=d if region['shape']=='box' else ((x-a)/c)**2+((y-b)/d)**2<=1

def geometry_hash(paths):
 return hashlib.sha256('|'.join(';'.join(f"{int(x)},{int(y)}" for x,y in a['points']) for a in paths).encode()).hexdigest()
def shades(hexcolor):
 r,g,b=[int(hexcolor[i:i+2],16)/255 for i in (0,2,4)];h,s,v=colorsys.rgb_to_hsv(r,g,b)
 def color(h,s,v):return ''.join(f'{round(q*255):02x}' for q in colorsys.hsv_to_rgb(h%1,max(0,min(s,1)),max(0,min(v,1))))
 return [color(h+.006,s*.80,min(1,v+.05)),hexcolor,color(h-.006,min(1,s+.05),max(.62,v*.84))]
def main():
 recipes=read('collections/expansion_recipes.json')['entries']; masks=read('collections/expansion_masks.json'); lookup={e['key']:e for e in masks}
 missing=[e['key'] for e in recipes if e['key'] not in PROFILES]
 assert not missing,missing
 profiles={'version':1,'notice':'Materialfarben und benannte, an vorhandenen Pfeilwegen ausgerichtete Farbflächen. Keine Neugenerierung der Geometrie.','entries':PROFILES}
 write('collections/expansion_color_designs.json',profiles)
 protected=read("collections/editor_overrides.json")["entries"] if (ROOT/"collections/editor_overrides.json").exists() else {}
 counts=[]
 for recipe in recipes:
  key=recipe['key'];mask=lookup[key];profile=PROFILES[key]
  path=f"collections/levels/{mask['collection']['id']}_{int(mask['collection']['order']):02d}_{key}.json"
  if path in protected:
   doc=read(path);counts.append((doc["title"],len(doc["motif"]["parts"])));continue
  file=ROOT/path; before=file.read_bytes();doc=json.loads(before.decode('utf-8-sig')); oldpaint=json.dumps([doc['motif'],doc['paths']],sort_keys=True);oldpoints=[a['points'] for a in doc['paths']];oldcells={(x,y) for x,y,_ in doc['motif']['cells']}
  xs=[x for x,y in oldcells];ys=[y for x,y in oldcells];lo=(min(xs),min(ys));span=(max(1,max(xs)-lo[0]),max(1,max(ys)-lo[1]))
  roles=[profile['base']]+profile['regions']; regioncells={}
  for x,y in oldcells:
   u=(x-lo[0])/span[0];v=(y-lo[1])/span[1];owner=0
   for i,region in enumerate(profile['regions'],1):
    if inside(region,u,v):owner=i
   regioncells[x,y]=owner
  # An arrow is one editable region member. Align paint boundaries with complete
  # existing arrows so the original paths, ordering and solution remain intact.
  owners=[]; arrowcells=[]
  for arrow in doc['paths']:
   cells=[(round((x-74)/14),round((y-183)/14)) for x,y in arrow['points']];arrowcells.append(cells)
   owners.append(Counter(regioncells[c] for c in cells).most_common(1)[0][0])
  # Keep significant, small details if an existing arrow follows that detail.
  for role in range(1,len(roles)):
   if role in owners:continue
   candidates=[(sum(regioncells[c]==role for c in cells)/len(cells),i) for i,cells in enumerate(arrowcells)]
   coverage,index=max(candidates)
   if coverage>=.38 and owners.count(owners[index])>1:owners[index]=role
  used=sorted(set(owners)); remap={role:i for i,role in enumerate(used)}; cells={};parts=[];styles={}
  for role in used:
   rolecells=[c for i,cs in enumerate(arrowcells) if owners[i]==role for c in cs]
   px=[74+14*x for x,y in rolecells];py=[183+14*y for x,y in rolecells]
   style=dict(mode=profile['mode'],strength=profile['strength'],colors=shades(roles[role]['color']),bounds=[min(px),min(py),max(1,max(px)-min(px)),max(1,max(py)-min(py))])
   styles[role]=style;parts.append(dict(id=remap[role],name=roles[role]['name'],colors=style['colors'],style=style))
  for i,arrow in enumerate(doc['paths']):
   role=owners[i]
   for c in arrowcells[i]:cells[c]=remap[role]
   arrow['color']=roles[role]['color']+'ff';arrow['color_style']=styles[role]
   arrow.pop('manual_color',None)
  doc['motif']['cells']=[[x,y,cells[x,y]] for x,y,_ in doc['motif']['cells']];doc['motif']['parts']=parts
  assert [a['points'] for a in doc['paths']]==oldpoints and set(cells)==oldcells
  history=doc.setdefault('compatible_color_checkpoints',[])
  prior=dict(fingerprint=hashlib.sha256(before).hexdigest(),geometry=geometry_hash(doc['paths']))
  if oldpaint!=json.dumps([doc['motif'],doc['paths']],sort_keys=True) and prior not in history:history.append(prior)
  doc['color_design']=dict(version=1,recipe=key,regions=len(parts),strategy='Material colors aligned to original complete arrow paths')
  write(path,doc);counts.append((recipe['title'],len(parts)))
 report={'version':1,'motifs':len(counts),'multicolor':sum(n>1 for _,n in counts),'single_region':[t for t,n in counts if n==1],'geometry':'All arrow points, path order and occupied cells unchanged.'}
 write('collections/expansion_color_report.json',report)
 print(report)
if __name__=='__main__':main()
