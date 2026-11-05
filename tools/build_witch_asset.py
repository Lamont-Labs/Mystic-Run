#!/usr/bin/env python3
"""Author MysticRun's silver-braided spellcaster using the admitted CC0 rig."""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import math
from mathutils import Vector
from character_mesh import CharacterMesh, smooth_path

m=CharacterMesh('witch',gender='Female',outward_tubes=True)
PLUM=m.material('Coat_plum','4a315f',0,.9)
VIOLET=m.material('Coat_lining','9566b6',0,.86)
INK=m.material('Tailored_bodice','292c49',0,.83)
GOLD=m.material('Antique_gold','d9b570',.5,.44)
SKIN=m.material('Warm_skin','e5b9a4',0,.82)
SHADE=m.material('Skin_shadow','be857d',0,.88)
LIPS=m.material('Lips_rose','994f63',0,.68)
SILVER=m.material('Hair_silver','d4dbe5',.06,.66)
HAIR_SHADE=m.material('Hair_recess','7c869f',.02,.78)
WHITE=m.material('Eye_ivory','f6eee5',0,.35)
CYAN=m.material('Crystal_cyan','7ad7df',.10,.3)
TEAL=m.material('Crystal_facets','327f9d',.18,.34)
DARK=m.material('Lashes_leather','252438',0,.86)

hand=m.rest['hand_r']
m.add_bones([
    ('braid_root','Head',(.14,1.65,-.13)),
    ('braid_tip','braid_root',(.235,1.21,-.225)),
    ('staff_control','hand_r',tuple(hand)),
])

def torso_weights(p):
    if p.y<1.03:return {'pelvis':1}
    if p.y<1.19:
        t=(p.y-1.03)/.16;return {'spine_01':1-t,'spine_02':t}
    t=min(1,(p.y-1.19)/.19);return {'spine_02':1-t,'spine_03':t}

# Continuous fitted torso and a high, open collar. The silhouette is tailored,
# with painted regions and piping rather than separate spherical chest pieces.
m.loft([(0,.88,-.025,.17,.116),(0,1.02,-.012,.16,.12),(0,1.12,-.015,.128,.103),(0,1.25,-.012,.157,.118),(0,1.34,-.02,.188,.119),(0,1.405,-.024,.186,.104),(0,1.45,-.032,.105,.08)],INK,torso_weights,sides=32,steps=3)
m.loft([(0,1.405,-.035,.085,.076),(0,1.515,-.035,.064,.064)],SKIN,'neck_01',sides=20,steps=2)
for side in (-1,1):
    m.plate([(side*.035,1.14),(side*.14,1.17),(side*.195,1.38),(side*.09,1.43),(side*.075,1.35)],.105,.016,PLUM,'spine_03')
    m.tube([(side*.035,1.15,.13),(side*.09,1.30,.145),(side*.095,1.425,.10)],[.005,.006,.004],GOLD,'spine_03',8,3)
    m.plate([(side*.075,1.425),(side*.16,1.42),(side*.17,1.54),(side*.11,1.57)],-.015,.046,PLUM,'neck_01')
    m.tube([(side*.08,1.435,.035),(side*.112,1.548,.035),(side*.163,1.526,.026)],[.005,.006,.004],GOLD,'neck_01',8,3)
    for j in range(3):
        m.tube([(side*.035,1.20+j*.044,.131),(0,1.18+j*.044,.144),(side*.035,1.17+j*.044,.13)],[.0035,.004,.0025],GOLD,'spine_02',6,2)
m.plate([(-.027,1.385),(0,1.422),(.027,1.385),(0,1.348)],.128,.017,GOLD,'spine_03')
m.plate([(-.015,1.385),(0,1.406),(.015,1.385),(0,1.365)],.148,.009,CYAN,'spine_03')

# Fitted leggings, high boots, kneecaps, straps and pointed toe silhouettes.
for suffix in ('l','r'):
    side=1 if suffix=='l' else -1
    hip,knee,ankle=(m.rest[n+'_'+suffix] for n in ('thigh','calf','foot'))
    m.limb(hip,knee,[.068,.087,.087,.072,.064,.061],INK,'thigh_'+suffix,sides=18)
    m.limb(knee,ankle,[.065,.078,.075,.058,.047,.046],DARK,'calf_'+suffix,sides=18)
    x=hip.x
    m.loft([(x,.37,-.03,.069,.065),(x,.48,-.035,.083,.071),(x,.56,-.035,.079,.067)],PLUM,'calf_'+suffix,sides=20,steps=2)
    m.loft([(x,.535,-.034,.081,.069),(x,.56,-.034,.083,.071)],GOLD,'calf_'+suffix,sides=20,steps=1)
    m.plate([(x-.055,.51),(x,.575),(x+.055,.51),(x,.445)],.037,.024,GOLD,'calf_'+suffix)
    m.plate([(x-.031,.509),(x,.549),(x+.031,.509),(x,.474)],.064,.008,INK,'calf_'+suffix)
    m.ellipsoid((x,.067,.014),(.066,.056,.139),DARK,'foot_'+suffix,8,18)
    m.tube([(x,.071,.06),(x,.063,.13),(x+side*.013,.042,.205)],[.062,.045,.005],INK,'foot_'+suffix,12,3)
    for j in range(2):
        y=.17+j*.125
        m.tube([(x-.047,y,.006),(x,y+.024,.031),(x+.047,y+.04,.004)],[.005,.007,.005],GOLD,'calf_'+suffix,8,3)
    m.tube([(x,.43,.045),(x,.30,.043),(x,.13,.018)],[.0045,.005,.003],GOLD,'calf_'+suffix,8,3)

# Sleeves follow the existing cast and sprint joints. Small glove fingers close
# around the staff grip on the right; the left remains a compact casting hand.
for suffix in ('l','r'):
    side=1 if suffix=='l' else -1
    shoulder,elbow,wrist=(m.rest[n+'_'+suffix] for n in ('upperarm','lowerarm','hand'))
    m.limb(shoulder,elbow,[.066,.09,.083,.067,.057,.055],PLUM,'upperarm_'+suffix,18)
    m.limb(elbow,wrist,[.056,.068,.069,.058,.048,.043],PLUM,'lowerarm_'+suffix,18)
    m.ellipsoid(elbow,(.066,.062,.061),PLUM,'lowerarm_'+suffix,7,16)
    m.ellipsoid(shoulder+Vector((side*.024,.022,0)),(.112,.077,.099),INK,'upperarm_'+suffix,7,18)
    m.tube([shoulder+Vector((side*.02,.08,-.07)),shoulder+Vector((side*.10,.075,0)),shoulder+Vector((side*.03,.065,.08))],[.008,.012,.007],GOLD,'upperarm_'+suffix,8,3)
    for t in (.60,.83):
        p=elbow.lerp(wrist,t)
        m.tube([p+Vector((0,-.055,-.035)),p+Vector((0,-.055,.035)),p+Vector((0,0,.062)),p+Vector((0,.055,.03))],[.005,.005,.006,.004],GOLD,'lowerarm_'+suffix,8,2)
    m.ellipsoid(wrist+Vector((side*.025,-.005,.018)),(.066,.052,.057),DARK,'hand_'+suffix,7,16)
    for j in range(4):
        x=wrist.x+side*(.01+j*.022)
        m.tube([(x,wrist.y+.015,.055),(x,wrist.y-.028,.075),(x,wrist.y-.051,.04)],[.015,.016,.011],DARK,'hand_'+suffix,8,2)
    m.tube([wrist+Vector((side*.008,.035,.01)),wrist+Vector((side*.067,.018,-.003)),wrist+Vector((side*.068,-.023,.035))],[.019,.018,.011],DARK,'hand_'+suffix,8,2)

# Four thick coat tails: each has a violet lining, smooth panel curvature and
# gold edge. Leg weighting preserves a clear gap for running rather than a tube.
def tail_weights(p):
    suffix='l' if p.x>=0 else 'r'
    # Below the hip transition, travel with the leg rather than allowing a
    # sprinting thigh to pass through a pelvis-dominated front panel.
    t=min(1,max(0,(.99-p.y)/.24))
    return {'pelvis':1-t,'thigh_'+suffix:t}
for side in (-1,1):
    for rear in (False,True):
        pts=[];uv=[];faces=[]
        for j in range(11):
            t=j/10;y=.99-.61*t
            center=side*(.12+.12*t);width=.063+.045*t
            for i in range(7):
                u=i/6;z=(-.14-.08*t if rear else .102-.018*t)-.025*math.sin(u*math.pi)*t
                pts.append((center+(u-.5)*2*width,y+.055*math.cos(u*math.pi)*t,z))
                uv.append((u,t))
        for j in range(10):
            for i in range(6):
                a=j*7+i;faces.append((a+7,a+8,a+1,a) if not rear else (a,a+1,a+8,a+7))
        m.mesh(pts,faces,PLUM,tail_weights,uv,'coat')
        lining=[(p[0],p[1],p[2]+(-.012 if not rear else .012)) for p in pts]
        m.mesh(lining,[tuple(reversed(f)) for f in faces],VIOLET,tail_weights,uv,'coat')
        border=list(range(7))+[j*7+6 for j in range(1,11)]+[70+i for i in range(5,-1,-1)]+[j*7 for j in range(9,0,-1)]
        edge_points=[];edge_faces=[]
        for at in border:edge_points.extend([pts[at],lining[at]])
        for i in range(len(border)):
            a=2*i;b=2*((i+1)%len(border));edge_faces.append((a,b,b+1,a+1))
        m.mesh(edge_points,edge_faces,PLUM,tail_weights,tag='coat')
        for column in (0,6):
            path=[pts[j*7+column] for j in (0,3,6,10)]
            m.tube(path,[.004,.005,.005,.003],GOLD,tail_weights,6,2,'coat')
        # Small embroidered crescent on the broad panel, still one surface.
        center=Vector(pts[6*7+3]);center.z+=-.004 if rear else .004
        crescent=[center+Vector((side*.020*math.cos(a),.025*math.sin(a),0)) for a in [math.pi*.35+i*math.pi*1.3/8 for i in range(9)]]
        m.tube(crescent,[.003]*9,GOLD,tail_weights,6,1,'coat')
m.loft([(0,.965,-.02,.181,.132),(0,1.025,-.02,.172,.129)],DARK,'pelvis',28,2)
for y in (.975,1.018):m.loft([(0,y-.004,-.02,.184,.135),(0,y+.004,-.02,.184,.135)],GOLD,'pelvis',28,1)
m.plate([(-.043,.969),(-.053,.996),(0,1.033),(.053,.996),(.043,.969),(0,.955)],.124,.022,GOLD,'pelvis')
m.plate([(-.023,.99),(0,1.012),(.023,.99),(0,.968)],.149,.009,VIOLET,'pelvis')
for side in (-1,1):
    m.ellipsoid((side*.169,.935,.04),(.052,.068,.037),DARK,'pelvis',7,14)
    m.tube([(side*.12,.99,.11),(side*.19,.94,.12),(side*.21,.86,.07)],[.004,.005,.004],GOLD,'pelvis',6,3)

# Adult stylized face: shaped jaw, full cheek plane, defined nose, eyelids and
# separate tiny lash/iris regions. All face parts share the same skinned surface.
m.loft([(0,1.515,.015,.055,.057),(0,1.56,.032,.085,.071),(0,1.625,.025,.115,.091),(0,1.715,.002,.148,.118),(0,1.80,-.025,.15,.133),(0,1.875,-.035,.127,.119),(0,1.928,-.04,.074,.078),(0,1.945,-.04,.01,.012)],SKIN,'Head',sides=32,steps=3,tag='face')
for side in (-1,1):
    m.ellipsoid((side*.147,1.733,-.012),(.032,.055,.023),SKIN,'Head',7,14)
    m.tube([(side*.162,1.751,.003),(side*.174,1.726,.012),(side*.160,1.707,.008)],[.005,.006,.004],SHADE,'Head',8,2)
    m.tube([(side*.165,1.706,.004),(side*.18,1.676,.008),(side*.162,1.657,.014)],[.005,.006,.004],GOLD,'Head',8,3)
    m.ellipsoid((side*.070,1.786,.100),(.047,.027,.023),WHITE,'Head',8,20,'eye')
    m.ellipsoid((side*.067,1.786,.122),(.019,.023,.0055),CYAN,'Head',8,16,'eye')
    m.ellipsoid((side*.066,1.786,.128),(.009,.018,.0025),DARK,'Head',7,14,'eye')
    m.ellipsoid((side*.060,1.793,.131),(.0045,.0055,.0015),WHITE,'Head',5,10,'eye')
    m.tube([(side*.026,1.786,.12),(side*.05,1.813,.125),(side*.084,1.813,.113),(side*.113,1.793,.095)],[.004,.006,.006,.003],DARK,'Head',8,3,'upper_lid')
    m.tube([(side*.03,1.779,.12),(side*.068,1.761,.124),(side*.109,1.783,.099)],[.003,.004,.002],SHADE,'Head',8,3,'lower_lid')
    m.tube([(side*.03,1.844,.108),(side*.063,1.855,.115),(side*.111,1.838,.091)],[.006,.009,.004],HAIR_SHADE,'Head',8,4,'brow')
    m.tube([(side*.107,1.798,.106),(side*.13,1.804,.096)],[.004,.0008],DARK,'Head',6,2,'upper_lid')
m.loft([(0,1.715,.130,.012,.015),(0,1.734,.145,.025,.029),(0,1.758,.13,.018,.023),(0,1.795,.108,.010,.013)],SKIN,'Head',sides=16,steps=2)
for side in (-1,1):m.ellipsoid((side*.018,1.724,.165),(.007,.003,.0035),SHADE,'Head',5,10)
m.tube([(-.041,1.675,.123),(-.015,1.68,.142),(0,1.677,.146),(.016,1.681,.142),(.041,1.678,.123)],[.003,.005,.004,.005,.002],LIPS,'Head',8,3,'mouth')
m.tube([(-.033,1.673,.131),(0,1.663,.145),(.033,1.676,.131)],[.003,.006,.002],LIPS,'Head',8,3,'lower_lip')
m.ellipsoid((0,1.673,.144),(.027,.0018,.003),DARK,'Head',5,16,'mouth_inner')
m.ellipsoid((0,1.676,.147),(.023,.001,.0018),WHITE,'Head',5,16,'teeth')

# Hair shell leaves the face open; sweeping locks and a three-strand silver braid.
pts=[];uv=[];faces=[];sides=32;rings=10
for j in range(rings+1):
    for i in range(sides+1):
        a=math.tau*i/sides;front=max(0,math.cos(a));theta=(2.7-1.75*front)*j/rings
        pts.append((.168*math.sin(theta)*math.sin(a),1.79+.194*math.cos(theta),-.035+.161*math.sin(theta)*math.cos(a)))
        uv.append((i/sides,j/rings))
for j in range(rings):
    for i in range(sides):
        a=j*(sides+1)+i;faces.append((a,a+sides+1,a+sides+2,a+1))
m.mesh(pts,faces,SILVER,'Head',uv,'hair')
for j in range(9):
    a=math.pi*.58+j*math.pi*.84/8
    path=[]
    for theta in (.32,.72,1.18,1.68,2.20):
        path.append((.171*math.sin(theta)*math.sin(a),1.79+.195*math.cos(theta),-.035+.164*math.sin(theta)*math.cos(a)))
    m.tube(path,[.009,.015,.016,.015,.004],SILVER,'Head',8,2,'hair')
for side in (-1,1):
    for j in range(3):
        start=Vector((side*(.015+j*.025),1.95-j*.006,.015))
        path=[start,(side*.10,1.925,.076),(side*.151,1.83,.071),(side*(.16+j*.006),1.69,-.018)]
        m.tube(path,[.022,.028,.026,.005],SILVER,'Head',10,4,'hair')
    m.tube([(side*.075,1.927,.085),(side*.13,1.89,.12),(side*.155,1.804,.097)],[.018,.025,.002],SILVER,'Head',10,4,'hair')
def braid_weights(p):
    t=min(1,max(0,(1.57-p.y)/.52));return {'braid_root':1-t,'braid_tip':t}
path=smooth_path([(.13,1.74,-.13),(.18,1.56,-.18),(.255,1.31,-.24),(.28,1.07,-.22),(.23,.87,-.18)],6)
for strand in range(3):
    points=[];radii=[]
    for j,p in enumerate(path):
        t=j/(len(path)-1);a=t*math.tau*4.8+strand*math.tau/3
        radius=.028*(1-.65*t)
        points.append(p+Vector((math.cos(a)*radius,0,math.sin(a)*radius)))
        radii.append(.025*(1-.6*t))
    m.tube(points,radii,SILVER,braid_weights,8,1,'braid')
for y,x,z in [(1.58,.179,-.178),(.94,.25,-.198)]:
    m.loft([(x,y-.018,z,.041,.035),(x,y+.018,z,.041,.035)],GOLD,braid_weights,16,1,'braid')
m.tube([(.23,.89,-.18),(.20,.825,-.15),(.195,.79,-.12)],[.021,.024,.002],SILVER,braid_weights,10,3,'braid')

# Compact crooked hat with a sculpted brim, ribbon and crescent clasp.
pts=[];uv=[];faces=[];sides=32
for j in range(5):
    radius=.13+j*.042
    for i in range(sides+1):
        a=math.tau*i/sides
        pts.append((math.sin(a)*radius,1.964+.018*math.cos(a*2)*(j/4)+.012*math.sin(a),-.036+math.cos(a)*radius*.79))
        uv.append((i/sides,j/4))
for j in range(4):
    for i in range(sides):
        a=j*(sides+1)+i;faces.append((a,a+sides+1,a+sides+2,a+1))
m.mesh(pts,faces,PLUM,'Head',uv,'hat')
m.mesh([(x,y-.014,z) for x,y,z in pts],[tuple(reversed(f)) for f in faces],VIOLET,'Head',uv,'hat')
rim=[pts[4*(sides+1)+i] for i in range(sides+1)]
rim_points=[];rim_faces=[]
for x,y,z in rim:rim_points.extend([(x,y,z),(x,y-.014,z)])
for i in range(sides):rim_faces.append((2*i,2*i+1,2*i+3,2*i+2))
m.mesh(rim_points,rim_faces,PLUM,'Head',tag='hat')
m.loft([(0,1.965,-.036,.157,.13),(-.006,2.035,-.037,.14,.115),(-.032,2.13,-.035,.104,.087),(-.078,2.21,-.026,.060,.053),(-.137,2.247,-.005,.033,.027),(-.183,2.22,.012,.003,.004)],PLUM,'Head',sides=28,steps=3,tag='hat')
m.loft([(0,1.976,-.036,.16,.133),(-.006,2.020,-.037,.148,.123)],VIOLET,'Head',sides=28,steps=2,tag='hat')
m.loft([(-.006,2.014,-.037,.150,.125),(-.007,2.024,-.037,.147,.122)],GOLD,'Head',sides=28,steps=1,tag='hat')
crescent=[(.058+.026*math.cos(a),2.001+.031*math.sin(a),.094) for a in [math.pi*.35+j*math.pi*1.35/12 for j in range(13)]]
m.tube(crescent,[.005]*13,GOLD,'Head',8,1,'hat')

# Staff geometry is weighted to its own control under the actual grip joint.
# A crescent cage frames an asymmetric, deliberately faceted cyan crystal.
sx,sy,sz=hand
staff='staff_control'
m.tube([(sx,.64,sz),(sx,1.0,sz),(sx,1.45,sz),(sx,1.94,sz)],[.012,.017,.016,.014],DARK,staff,12,3,'staff')
for y in (.69,1.17,1.32,1.52,1.88):
    m.loft([(sx,y-.014,sz,.022,.022),(sx,y+.014,sz,.022,.022)],GOLD,staff,sides=12,steps=1,tag='staff')
for side in (-1,1):
    points=[(sx+side*.02,1.88,sz),(sx+side*.14,1.99,sz),(sx+side*.174,2.13,sz),(sx+side*.13,2.26,sz),(sx+side*.055,2.31,sz)]
    m.tube(points,[.019,.023,.020,.013,.001],GOLD,staff,10,4,'staff')
m.loft([(sx,1.99,sz,.004,.004),(sx-.016,2.09,sz,.072,.05),(sx+.008,2.20,sz,.048,.043),(sx-.02,2.29,sz,.002,.002)],CYAN,staff,sides=6,steps=1,tag='staff')
m.plate([(sx-.04,2.10),(sx-.015,2.24),(sx+.015,2.18),(sx+.05,2.10),(sx,2.02)],sz+.048,.001,TEAL,staff)

def deform(name,p,tag):
    eye=tag in ('eye','upper_lid','lower_lid');corner=min(1,abs(p.x)/.045)
    if name=='Blink' and eye:p.y=1.785+(p.y-1.785)*.025
    if name=='Smile':
        if tag in ('mouth','lower_lip'):p.y+=.012*corner**1.6
        elif tag=='mouth_inner':p.y=1.675+(p.y-1.673)*4
        elif tag=='teeth':p.y=1.68+(p.y-1.676)*4
        elif eye:p.y=1.788+(p.y-1.786)*.86
    if name=='Focus':
        if tag=='brow':p.y+=-.014+.022*min(1,abs(p.x)/.12)
        elif eye:p.y=1.785+(p.y-1.786)*.75
        elif tag in ('mouth','lower_lip'):p.y-=.003*corner
    if name=='Surprised':
        if tag=='brow':p.y+=.018
        elif eye:p.y=1.788+(p.y-1.786)*1.18
        elif tag=='mouth_inner':p.y=1.673+(p.y-1.673)*8;p.x*=.7
        elif tag=='mouth':p.y-=.008*(1-corner)
        elif tag in ('lower_lip','teeth'):p.y-=.010
    if name=='Hurt':
        if tag=='brow':p.y+=.014-.025*min(1,abs(p.x)/.12)
        elif eye:p.y=1.783+(p.y-1.786)*.43
        elif tag in ('mouth','lower_lip'):p.y-=.012*corner
        elif tag=='mouth_inner':p.y=1.67+(p.y-1.673)*4
    return p

m.export({name:lambda p,tag,n=name:deform(n,p,tag) for name in ['Blink','Smile','Focus','Surprised','Hurt']},{
    'revision':'authored-witch-1','source_generator':'tools/build_witch_asset.py',
    'geometry':'Original Lamont Labs face, tailored costume, gloves, boots, silver braid, crooked hat and crescent crystal staff.',
    'rig_source':'Previously admitted Quaternius CC0 female humanoid skeleton, plus two braid controls and one staff control.',
    'motion_source':'Existing admitted CC0 motion; original cosmetic braid and staff control in game/hero.gd.',
    'blink_closure_y':1.785,
    'tube_side_faces_outward':True,
    'modifications':['Original visible body, costume, equipment and five facial morph targets.','Three added control bones retain the original humanoid motion and hand grip.'],
})
