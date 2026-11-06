#!/usr/bin/env python3
"""Author MysticRun's stone guardian; Blender 4.3.2, no additional downloads."""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import math
from mathutils import Vector
from character_mesh import CharacterMesh

m=CharacterMesh('gargoyle',outward_tubes=True)
STONE=m.material('Stone_jade','58a99e',0,.92)
LIGHT=m.material('Stone_edges','76b5a6',0,.88)
DEEP=m.material('Stone_recesses','315e65',0,.96)
PLUM=m.material('Wing_membrane','9566af',0,.87)
PURPLE=m.material('Membrane_underside','674879',0,.94)
CLOTH=m.material('Sash_plum','6c4d88',0,.96)
GOLD=m.material('Ornaments_warm_gold','d8b36b',.45,.48)
IVORY=m.material('Claws_ivory','dfdab9',0,.65)
WHITE=m.material('Eyes_ivory','f4f4dd',0,.38)
IRIS=m.material('Eyes_amber','d8a84e',.03,.42)
DARK=m.material('Eyes_mouth','153543',0,.8)
MINT=m.material('Mineral_marks','9bcbb9',0,.85)

wing_definitions=[]
for suffix,side in [('l',1),('r',-1)]:
    wing_definitions += [(f'wing_root_{suffix}','spine_03',(side*.20,1.42,-.12)),(f'wing_tip_{suffix}',f'wing_root_{suffix}',(side*.64,1.65,-.24))]
m.add_bones(wing_definitions)

def torso_weights(p):
    if p.y<1.05:return {'pelvis':1}
    if p.y<1.22:
        t=(p.y-1.05)/.17;return {'spine_01':1-t,'spine_02':t}
    t=min(1,(p.y-1.22)/.18);return {'spine_02':1-t,'spine_03':t}

# Designed barrel chest, broad shoulder line and muscular stone abdomen.
torso_start=len(m.vertices)
m.loft([(0,.85,.0,.19,.14),(0,1.0,.0,.235,.17),(0,1.15,.0,.25,.18),(0,1.31,-.005,.325,.21),(0,1.43,-.02,.335,.20),(0,1.49,-.02,.245,.14),(0,1.53,-.015,.115,.10)],STONE,torso_weights,sides=32)
for point in m.vertices[torso_start:]:
    if point.z>0:
        chest=math.exp(-((abs(point.x)-.14)/.13)**2-((point.y-1.36)/.10)**2)
        abdomen=math.exp(-(point.x/.15)**2-((point.y-1.14)/.12)**2)
        point.z+=.029*chest+.014*abdomen
for side in (-1,1):
    m.tube([(side*.02,1.26,.204),(side*.11,1.23,.20),(side*.20,1.26,.18)],[.004,.005,.003],DEEP,'spine_02',8)
    m.tube([(side*.025,1.42,.174),(side*.15,1.45,.158),(side*.255,1.42,.108)],[.009,.012,.006],MINT,'spine_03',8)

# Short, substantial legs with broad three-toed feet.
for suffix in ('l','r'):
    side=1 if suffix=='l' else -1
    hip,knee,ankle=(m.rest[n+'_'+suffix] for n in ('thigh','calf','foot'))
    m.limb(hip,knee,[.085,.115,.12,.10,.085,.078],STONE,'thigh_'+suffix)
    m.limb(knee,ankle,[.078,.092,.10,.082,.064,.062],STONE,'calf_'+suffix)
    x=hip.x
    m.ellipsoid((x,.55,.079),(.104,.081,.062),LIGHT,'calf_'+suffix,8,18)
    m.tube([(x-.065,.43,.075),(x-.048,.32,.085),(x,.18,.08)],[.01,.008,.005],MINT,'calf_'+suffix,8)
    m.ellipsoid((x,.083,.07),(.14,.075,.18),STONE,'foot_'+suffix,8,20)
    for toe in range(3):
        tx=x+(toe-1)*.077
        m.ellipsoid((tx,.065,.19),(.052,.05,.10),LIGHT,'foot_'+suffix,6,12)
        m.tube([(tx,.067,.24),(tx,.054,.29),(tx,.028,.325)],[.026,.023,.003],IVORY,'foot_'+suffix,8,3)

# Broad forearms and closed gripping fingers carry the existing punch animation.
for suffix in ('l','r'):
    side=1 if suffix=='l' else -1
    shoulder,elbow,hand=(m.rest[n+'_'+suffix] for n in ('upperarm','lowerarm','hand'))
    m.limb(shoulder,elbow,[.10,.13,.125,.105,.085,.082],STONE,'upperarm_'+suffix)
    m.limb(elbow,hand,[.084,.12,.14,.13,.094,.075],STONE,'lowerarm_'+suffix)
    m.ellipsoid(shoulder+Vector((side*.025,.01,0)),(.15,.125,.14),STONE,'upperarm_'+suffix,9,20)
    for i in range(2):
        p=elbow.lerp(hand,.35+i*.18)
        m.tube([p+Vector((side*.07,-.05,.065)),p+Vector((side*.08,.005,.10)),p+Vector((side*.06,.055,.07))],[.006,.009,.005],MINT,'lowerarm_'+suffix,8)
    m.ellipsoid(hand+Vector((side*.035,-.015,.035)),(.10,.08,.085),STONE,'hand_'+suffix,8,18)
    for i in range(3):
        x=hand.x+side*(.012+i*.036)
        m.tube([(x,hand.y+.018,.085),(x,hand.y-.045,.105),(x,hand.y-.075,.055)],[.029,.03,.019],LIGHT,'hand_'+suffix,8,3)
        m.tube([(x,hand.y-.07,.07),(x,hand.y-.078,.11),(x,hand.y-.10,.12)],[.018,.015,.002],IVORY,'hand_'+suffix,8,3)
    m.tube([hand+Vector((side*.016,.065,.0)),hand+Vector((side*.085,.045,-.025)),hand+Vector((side*.106,-.015,.025))],[.035,.034,.019],LIGHT,'hand_'+suffix,10,3)

# Thick plum sash, clasp and layered hanging ends.
m.loft([(0,.92,.0,.232,.168),(0,.98,0,.245,.18),(0,1.035,0,.242,.177)],CLOTH,'pelvis',sides=28,steps=2)
m.loft([(0,1.018,0,.244,.18),(0,1.04,0,.244,.18)],GOLD,'pelvis',sides=28,steps=1)
m.plate([(-.065,.946),(-.078,.988),(0,1.031),(.078,.988),(.065,.946),(0,.923)],.185,.019,GOLD,'pelvis')
m.plate([(-.034,.965),(0,1.008),(.034,.965),(0,.944)],.208,.01,MINT,'pelvis')
for side in (-1,1):
    m.plate([(side*.07,.947),(side*.195,.946),(side*.19,.69),(side*.135,.61),(side*.08,.72)],.139,.025,CLOTH,'pelvis')
    m.tube([(side*.09,.935,.168),(side*.112,.78,.168),(side*.136,.642,.168)],[.005,.007,.004],GOLD,'pelvis',8)

# Nonhuman head with a broad muzzle, swept ears and paired stone horns.
m.loft([(0,1.46,-.025,.10,.095),(0,1.59,-.02,.12,.11)],STONE,'neck_01',sides=24)
m.loft([(0,1.535,.02,.105,.10),(0,1.58,.045,.16,.125),(0,1.66,.025,.195,.14),(0,1.75,-.015,.215,.15),(0,1.85,-.035,.195,.15),(0,1.93,-.04,.13,.12),(0,1.96,-.04,.035,.045)],STONE,'Head',sides=32,tag='face')
m.ellipsoid((0,1.675,.157),(.149,.069,.10),LIGHT,'Head',9,24,'muzzle')
m.ellipsoid((0,1.734,.217),(.062,.026,.034),STONE,'Head',7,16)
for side in (-1,1):
    m.ellipsoid((side*.032,1.727,.244),(.016,.008,.004),DEEP,'Head',6,12)
    m.ellipsoid((side*.165,1.697,.078),(.063,.079,.061),LIGHT,'Head',8,16,'cheek')
    m.tube([(side*.177,1.79,-.015),(side*.245,1.81,-.04),(side*.288,1.876,-.06)],[.052,.039,.002],STONE,'Head',12,4)
    m.tube([(side*.132,1.88,-.075),(side*.175,2.005,-.10),(side*.153,2.13,-.075),(side*.10,2.18,-.03)],[.052,.045,.026,.002],DEEP,'Head',12,4)
    m.tube([(side*.128,1.89,-.07),(side*.145,1.94,-.078)],[.055,.05],GOLD,'Head',12,3)
    m.ellipsoid((side*.09,1.795,.137),(.055,.042,.025),WHITE,'Head',8,20,'eye')
    m.ellipsoid((side*.084,1.794,.16),(.026,.031,.007),IRIS,'Head',8,18,'eye')
    m.ellipsoid((side*.083,1.794,.167),(.011,.022,.003),DARK,'Head',7,14,'eye')
    m.ellipsoid((side*.074,1.806,.170),(.006,.006,.0015),WHITE,'Head',6,10,'eye')
    m.tube([(side*.038,1.795,.154),(side*.064,1.831,.161),(side*.11,1.834,.15),(side*.147,1.801,.124)],[.006,.008,.009,.004],STONE,'Head',8,3,'upper_lid')
    m.tube([(side*.042,1.778,.153),(side*.094,1.756,.159),(side*.141,1.777,.13)],[.004,.006,.003],DEEP,'Head',8,3,'lower_lid')
    m.tube([(side*.037,1.86,.139),(side*.087,1.881,.143),(side*.152,1.856,.104)],[.014,.02,.009],DEEP,'Head',10,4,'brow')
    m.tube([(side*.17,1.75,.09),(side*.185,1.70,.102),(side*.15,1.66,.12)],[.005,.006,.003],MINT,'Head',8)
    m.tube([(side*.077,1.641,.224),(side*.075,1.675,.242),(side*.067,1.694,.247)],[.015,.012,.0015],IVORY,'Head',8,3)
m.tube([(-.105,1.657,.222),(-.05,1.645,.25),(.025,1.648,.256),(.106,1.669,.223)],[.004,.005,.005,.003],DARK,'Head',8,4,'mouth')
m.tube([(-.065,1.63,.232),(0,1.625,.247),(.068,1.639,.232)],[.005,.008,.004],STONE,'Head',8,3,'lower_lip')
m.ellipsoid((0,1.65,.251),(.055,.0015,.004),DARK,'Head',6,16,'mouth_inner')
m.ellipsoid((0,1.655,.257),(.047,.001,.002),IVORY,'Head',6,16,'teeth')

# Solid, curved membranes with scalloped outlines and deforming finger spars.
for suffix,side in [('l',1),('r',-1)]:
    origin=Vector((side*.20,1.42,-.13))
    # Tuck the outer flight feathers into a readable chase-camera silhouette.
    # Keep the membrane's six scallops, the four control bones and rig weights.
    tips=[Vector((side*.42,1.85,-.20)),Vector((side*.70,1.98,-.22)),Vector((side*.94,1.76,-.26)),Vector((side*.93,1.36,-.34)),Vector((side*.68,1.11,-.37)),Vector((side*.33,1.075,-.23))]
    def weights(p,suffix=suffix):
        t=min(.72,max(0,(abs(p.x)-.41)/.82))
        return {'wing_root_'+suffix:1-t,'wing_tip_'+suffix:t}
    boundary=[]
    for segment in range(len(tips)-1):
        for i in range(7):
            t=i/7;point=tips[segment].lerp(tips[segment+1],t)
            boundary.append(origin+(point-origin)*(1-.19*math.sin(math.pi*t)))
    boundary.append(tips[-1]);columns=len(boundary);radial=5
    surfaces=[]
    for layer in (-1,1):
        pts=[];uv=[];faces=[]
        for r in range(radial+1):
            f=r/radial
            for c,end in enumerate(boundary):
                p=origin.lerp(end,f)
                p.z-=.075*math.sin(math.pi*f)*math.sin(math.pi*c/(columns-1))
                p.z+=layer*.005
                pts.append(p);uv.append((c/(columns-1),f))
        for r in range(radial):
            for c in range(columns-1):
                a=r*columns+c;face=(a,a+1,a+columns+1,a+columns)
                faces.append(face if layer*side>0 else tuple(reversed(face)))
        surfaces.append(pts)
        m.mesh(pts,faces,PLUM if layer>0 else PURPLE,weights,uv,'wing')
    edge_points=[];edge_faces=[]
    for c in range(columns):edge_points.extend([surfaces[0][radial*columns+c],surfaces[1][radial*columns+c]])
    for c in range(columns-1):edge_faces.append((2*c,2*c+1,2*c+3,2*c+2))
    m.mesh(edge_points,edge_faces,PLUM,weights,tag='wing')
    for tip in tips:
        midpoint=origin.lerp(tip,.58);midpoint.z-=.03
        m.tube([origin,midpoint,tip],[.032,.023,.006],STONE,weights,8,3,'wing')
    m.tube([tips[0],tips[1],tips[2]],[.025,.024,.004],LIGHT,weights,8,3,'wing')

def deform(name,p,tag):
    eye=tag in ('eye','upper_lid','lower_lid');corner=min(1,abs(p.x)/.11)
    if name=='Blink' and eye:p.y=1.793+(p.y-1.793)*.025
    if name=='Smile':
        if tag in ('mouth','lower_lip'):p.y+=.003+.016*corner**1.5
        elif tag=='mouth_inner':p.y=1.654+(p.y-1.65)*6
        elif tag=='teeth':p.y=1.66+(p.y-1.655)*4
        elif eye:p.y=1.796+(p.y-1.795)*.86
    if name=='Focus':
        if tag=='brow':p.y+=-.018+.025*min(1,abs(p.x)/.15)
        elif eye:p.y=1.793+(p.y-1.795)*.77
        elif tag in ('mouth','lower_lip'):p.y-=.004*corner
    if name=='Surprised':
        if tag=='brow':p.y+=.018
        elif eye:p.y=1.797+(p.y-1.795)*1.14
        elif tag=='mouth_inner':p.y=1.65+(p.y-1.65)*15;p.x*=.8
        elif tag=='mouth':p.y-=.011*(1-corner)
        elif tag in ('lower_lip','teeth'):p.y-=.013
    if name=='Hurt':
        if tag=='brow':p.y+=.015-.025*corner
        elif eye:p.y=1.791+(p.y-1.795)*.45
        elif tag in ('mouth','lower_lip'):p.y-=.012*corner
        elif tag=='mouth_inner':p.y=1.645+(p.y-1.65)*6
    return p

m.export({name:lambda p,tag,n=name:deform(n,p,tag) for name in ['Blink','Smile','Focus','Surprised','Hurt']},{
    'revision':'authored-gargoyle-3','source_generator':'tools/build_gargoyle_asset.py',
    'geometry':'Original Lamont Labs stone body, muzzle, horns, hands, feet, sash, wing membranes and spars.',
    'rig_source':'Previously admitted Quaternius CC0 humanoid skeleton, plus four original wing control bones.',
    'motion_source':'Existing admitted CC0 authored motion; original cosmetic wing control in game/hero.gd.',
    'blink_closure_y':1.793,
    'tube_side_faces_outward':True,
    'modifications':['Original nonhuman visible geometry and five facial morph targets.','Four added wing bones and weighted curved membranes, retained humanoid motion rig.','Outward-facing curved detail surfaces for solid brows, horns, claws, piping and wing spars.','Compact outer wing contour for improved chase-camera readability without changing rig or wing controls.'],
})
