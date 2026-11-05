#!/usr/bin/env python3
"""Reproducible authored Knight mesh. Run with Blender 4.3+ --background --python.

All design coordinates use Godot's X/right, Y/up, Z/front convention. The
Quaternius CC0 skeleton is retained for the existing motion adapter; every
visible surface below is newly modeled. No runtime primitive assembly.
"""
import hashlib
import json
import math
import pathlib

import bpy
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/characters/knight'
DEST.mkdir(parents=True, exist_ok=True)
EDITABLE = ROOT / 'art/characters/knight'
EDITABLE.mkdir(parents=True, exist_ok=True)
(ROOT / 'art/.gdignore').write_text('')
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(ROOT / 'assets/models/quaternius/base/Superhero_Male_FullBody.gltf'))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
rig.name = 'KnightRig'
for obj in list(bpy.data.objects):
    if obj != rig:
        bpy.data.objects.remove(obj, do_unlink=True)


def xyz(p):
    return (p[0], -p[2], p[1])


def game(p):
    return Vector((p[0], p[2], -p[1]))


REST = {b.name: game(rig.matrix_world @ b.head_local) for b in rig.data.bones}
V, F, MI, UV, COL, PBR, WEIGHTS, TAGS = [], [], [], [], [], [], [], []
MATS = []


def material(name, color, metal=0.0, rough=.65):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    def linear(c):
        c=int(c,16)/255
        return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
    p.inputs['Base Color'].default_value = tuple(linear(color[i:i+2]) for i in (0, 2, 4))+(1,)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    p.inputs['Specular IOR Level'].default_value = .32
    tint = m.node_tree.nodes.new('ShaderNodeVertexColor')
    tint.layer_name = 'SculptTint'
    m.node_tree.links.new(tint.outputs['Color'], p.inputs['Base Color'])
    MATS.append(m)
    return len(MATS)-1


SKIN = material('Skin_warm_peach', 'dfa984', 0, .82)
BLUE = material('Enamel_sapphire', '4c8cad', .28, .48)
GOLD = material('Metal_warm_gold', 'd7b271', .55, .44)
SILVER = material('Blade_satin_steel', 'b8d6e6', .50, .28)
NAVY = material('Cloth_indigo', '263755', 0, .93)
LEATHER = material('Leather_chestnut', '624437', 0, .90)
HAIR = material('Hair_chestnut', '50362c', 0, .87)
WHITE = material('Eyes_ivory', 'f5f5ed', 0, .25)
IRIS = material('Eyes_ocean_blue', '2f789c', 0, .31)
DARK = material('Eyes_and_seams', '142334', 0, .77)
RED = material('Plume_coral', 'b94249', 0, .80)
GEM = material('Gem_turquoise', '57d7db', .24, .23)
LIP = material('Face_warm_detail', 'b57565', 0, .84)


def color_for(mat, p, uv):
    base = MATS[mat].node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value
    # Broad painted gradients survive the chase camera. No random surface noise.
    h = .93+.07*math.sin(uv[1]*math.pi)
    if mat == BLUE:
        h = .80+.23*uv[1]+.05*math.cos(uv[0]*math.tau)
    elif mat in (GOLD, SILVER):
        h = .90+.11*math.sin(uv[0]*math.pi)+.04*uv[1]
    elif mat == SKIN:
        h = .94+.06*uv[1]
    return tuple(min(1, max(0, c*h)) for c in base[:3])+(1,)


def mesh(points, faces, mat, bone, uvs=None, tag=''):
    offset = len(V)
    for i, p in enumerate(points):
        uv = uvs[i] if uvs else (0.5, 0.5)
        V.append(xyz(p)); UV.append(uv); COL.append(color_for(mat, p, uv))
        params=MATS[mat].node_tree.nodes.get('Principled BSDF').inputs
        PBR.append((params['Metallic'].default_value,params['Roughness'].default_value))
        WEIGHTS.append(bone(p) if callable(bone) else {bone: 1.0})
        TAGS.append(tag)
    F.extend(tuple(offset+i for i in f) for f in faces)
    MI.extend([mat]*len(faces))


def catmull(points, steps=4):
    pts = [Vector(p) for p in points]
    out = []
    for i in range(len(pts)-1):
        a,b,c,d = pts[max(0,i-1)],pts[i],pts[i+1],pts[min(len(pts)-1,i+2)]
        for j in range(steps):
            t = j/steps
            out.append((b*2+(-a+c)*t+(a*2-b*5+c*4-d)*t*t+(-a+b*3-c*3+d)*t*t*t)*.5)
    return out+[pts[-1]]


def ellipsoid(center, scale, mat, bone, rings=12, sides=24, tag=''):
    rings=max(6,int(rings*.75));sides=max(8,int(sides*.75))
    pts, uv, faces = [], [], []
    for j in range(rings+1):
        t = math.pi*j/rings
        for i in range(sides+1):
            a = math.tau*i/sides
            pts.append((center[0]+scale[0]*math.sin(t)*math.sin(a),
                        center[1]+scale[1]*math.cos(t),
                        center[2]+scale[2]*math.sin(t)*math.cos(a)))
            uv.append((i/sides, 1-j/rings))
    for j in range(rings):
        for i in range(sides):
            a = j*(sides+1)+i
            faces.append((a, a+sides+1, a+sides+2, a+1))
    mesh(pts, faces, mat, bone, uv, tag)


def loft(rows, mat, bone, sides=24, steps=2, tag=''):
    # rows: center-x, height, center-z, half-width, half-depth.
    # Interpolate five-dimensional profiles without the 4D Vector limit.
    profile=[]
    for j in range(len(rows)-1):
        a,b,c,d=rows[max(0,j-1)],rows[j],rows[j+1],rows[min(len(rows)-1,j+2)]
        for s in range(steps):
            t=s/steps
            profile.append([.5*(2*b[k]+(-a[k]+c[k])*t+(2*a[k]-5*b[k]+4*c[k]-d[k])*t*t+(-a[k]+3*b[k]-3*c[k]+d[k])*t*t*t) for k in range(5)])
    profile.append(rows[-1])
    pts,uv,faces=[],[],[]
    for j,row in enumerate(profile):
        x,y,z,w,depth=row
        for i in range(sides+1):
            a=math.tau*i/sides
            pts.append((x+math.sin(a)*max(.001,w), y, z+math.cos(a)*max(.001,depth)))
            uv.append((i/sides,j/(len(profile)-1)))
    for j in range(len(profile)-1):
        for i in range(sides):
            a=j*(sides+1)+i
            faces.append((a,a+1,a+sides+2,a+sides+1))
    faces.extend([tuple(range(sides,-1,-1)),tuple((len(profile)-1)*(sides+1)+i for i in range(sides+1))])
    mesh(pts,faces,mat,bone,uv,tag)


def tube(points, radii, mat, bone, sides=8, steps=2, tag=''):
    path=catmull(points,steps)
    rs=[]
    for i in range(len(radii)-1):
        rs.extend(radii[i]+(radii[i+1]-radii[i])*j/steps for j in range(steps))
    rs.append(radii[-1])
    pts,uv,faces=[],[],[]
    previous_cross=None
    for j,p in enumerate(path):
        direction=(path[min(j+1,len(path)-1)]-path[max(0,j-1)]).normalized()
        # Transport the previous cross-section instead of flipping a fixed-axis
        # frame at the apex of a bent plume, hair clump or armor trim.
        cross=previous_cross-direction*previous_cross.dot(direction) if previous_cross is not None else direction.cross(Vector((0,0,1)))
        if cross.length<.01:cross=direction.cross(Vector((0,1,0)))
        cross.normalize();up=direction.cross(cross).normalized()
        previous_cross=cross.copy()
        for i in range(sides+1):
            a=math.tau*i/sides
            pts.append(p+rs[j]*(cross*math.cos(a)+up*math.sin(a)))
            uv.append((i/sides,j/(len(path)-1)))
    for j in range(len(path)-1):
        for i in range(sides):
            a=j*(sides+1)+i
            faces.append((a,a+sides+1,a+sides+2,a+1))
    if tag=='plume':
        faces.append(tuple(range(sides-1,-1,-1)))
        faces.append(tuple((len(path)-1)*(sides+1)+i for i in range(sides)))
    mesh(pts,faces,mat,bone,uv,tag)


def limb(a,b,radii,mat,bone):
    direction=(Vector(b)-Vector(a)).normalized()
    lengths=[0,.08,.28,.65,.9,1]
    pts=[Vector(a).lerp(Vector(b),t) for t in lengths]
    tube(pts,radii,mat,bone,sides=20,steps=2)


def plate(outline, z, depth, mat, bone, bevel=.012):
    # A beveled convex plate with a raised central ridge and real edge thickness.
    cx=sum(p[0] for p in outline)/len(outline); cy=sum(p[1] for p in outline)/len(outline)
    pts=[]
    for ring in range(3):
        for x,y in outline:
            shrink=1 if ring<2 else .89
            pts.append((cx+(x-cx)*shrink,cy+(y-cy)*shrink,z+(0 if ring==0 else depth-bevel if ring==1 else depth)))
    n=len(outline);faces=[]
    for j in range(2):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    pts.append((cx,cy,z+depth+.012)); center=len(pts)-1
    for i in range(n):faces.append((2*n+i,2*n+(i+1)%n,center))
    faces.append(tuple(range(n-1,-1,-1)))
    mesh(pts,faces,mat,bone)


def star(x,y,z,r,mat,bone,depth=.008):
    outline=[]
    for i in range(10):
        a=math.pi*.5+i*math.pi/5;radius=r if i%2==0 else r*.44
        outline.append((x+math.cos(a)*radius,y+math.sin(a)*radius))
    plate(outline,z,depth,mat,bone,.002)


# The suit is a continuous weighted torso, with deliberate cloth and armor layers.
def torso_weights(p):
    y=p[1]
    if y<1.03:return {'pelvis':1}
    if y<1.17:
        t=(y-1.03)/.14;return {'spine_01':1-t,'spine_02':t}
    t=min(1,(y-1.17)/.14);return {'spine_02':1-t,'spine_03':t}


loft([(0,.85,.02,.16,.12),(0,.99,.01,.18,.135),(0,1.12,.00,.16,.125),(0,1.30,0,.24,.16),(0,1.43,0,.245,.14),(0,1.48,.01,.11,.09)],NAVY,torso_weights)
loft([(0,1.045,0,.17,.137),(0,1.09,.01,.19,.15),(0,1.22,.015,.235,.176),(0,1.36,.00,.265,.182),(0,1.435,0,.23,.135)],BLUE,'spine_03')
loft([(0,1.045,0,.175,.142),(0,1.065,0,.184,.15),(0,1.08,0,.19,.15)],GOLD,'spine_03',steps=2)
for side in (-1,1):
    tube([(side*.215,1.418,.082),(side*.19,1.40,.139),(side*.12,1.355,.177),(0,1.305,.199)],[.012]*4,GOLD,'spine_03')
    tube([(side*.205,1.17,.115),(side*.15,1.13,.157),(0,1.10,.17)],[.009]*3,GOLD,'spine_03')
star(0,1.31,.196,.081,GOLD,'spine_03')
plate([(-.025,1.31),(0,1.35),(.025,1.31),(0,1.268)],.218,.012,GEM,'spine_03')

# Belt, shaped buckle, hanging tassets, straps and visible rivets.
loft([(0,.96,.015,.19,.15),(0,1.005,.015,.19,.15)],LEATHER,'pelvis',steps=1)
plate([(-.055,.963),(-.055,1.013),(.055,1.013),(.055,.963)],.167,.022,GOLD,'pelvis')
plate([(-.031,.976),(-.031,1.001),(.031,1.001),(.031,.976)],.191,.003,LEATHER,'pelvis')
for side in (-1,1):
    plate([(side*.035,.956),(side*.175,.972),(side*.23,.81),(side*.12,.775)],.126,.028,GOLD,'pelvis')
    plate([(side*.05,.945),(side*.164,.956),(side*.207,.825),(side*.12,.80)],.159,.012,BLUE,'pelvis')
    for y in (.978,.996):ellipsoid((side*.09,y,.176),(.007,.007,.005),GOLD,'pelvis',6,10)
    for i in range(2):
        x=side*(.17+i*.035)
        tube([(x,.985,.145),(x,.976,.157),(x,.962,.146)],[.008]*3,GOLD,'pelvis',6,2)

# Legs retain the rig's original joint positions and clearance envelope.
for suffix in ('l','r'):
    side=1 if suffix=='l' else -1
    hip,knee,ankle=(REST[n+'_'+suffix] for n in ('thigh','calf','foot'))
    limb(hip,knee,[.07,.09,.085,.075,.062,.06],NAVY,'thigh_'+suffix)
    limb(knee,ankle,[.062,.07,.072,.056,.048,.045],NAVY,'calf_'+suffix)
    x=hip.x
    plate([(x-.07,.91),(x+.07,.91),(x+.086,.70),(x,.63),(x-.08,.70)],.092,.038,GOLD,'thigh_'+suffix)
    plate([(x-.057,.891),(x+.057,.891),(x+.068,.708),(x,.656),(x-.065,.708)],.131,.013,BLUE,'thigh_'+suffix)
    ellipsoid((x,.547,.095),(.095,.063,.038),GOLD,'calf_'+suffix,10,20)
    ellipsoid((x,.551,.114),(.077,.047,.026),BLUE,'calf_'+suffix,10,20)
    loft([(x,.13,-.015,.069,.073),(x,.22,-.014,.077,.077),(x,.39,-.008,.091,.080),(x,.485,.003,.077,.073)],BLUE,'calf_'+suffix,sides=24)
    tube([(x-.075,.46,.035),(x-.058,.475,.066),(x,.48,.081),(x+.058,.475,.066),(x+.075,.46,.035)],[.009]*5,GOLD,'calf_'+suffix)
    tube([(x,.17,.063),(x,.29,.079),(x,.43,.083)],[.007]*3,SILVER,'calf_'+suffix,8)
    # A rounded toe and stacked sabaton plates instead of a chamfered box.
    ellipsoid((x,.087,.075),(.092,.071,.19),BLUE,'foot_'+suffix,12,24)
    ellipsoid((x,.038,.083),(.097,.025,.193),LEATHER,'foot_'+suffix,8,24)
    for i in range(3):
        z=.09+i*.045
        tube([(x-.08,.094,z),(x-.057,.143,z+.008),(x,.156,z+.012),(x+.057,.143,z+.008),(x+.08,.094,z)],[.007]*5,GOLD if i==2 else SILVER,'foot_'+suffix,8,2)

# Arms: fabric joints, curved pauldrons, cuffs and fingers folded around real grips.
for suffix in ('l','r'):
    side=1 if suffix=='l' else -1
    shoulder,elbow,hand=(REST[n+'_'+suffix] for n in ('upperarm','lowerarm','hand'))
    limb(shoulder,elbow,[.075,.087,.085,.068,.059,.055],NAVY,'upperarm_'+suffix)
    limb(elbow,hand,[.055,.066,.075,.062,.045,.04],NAVY,'lowerarm_'+suffix)
    center=shoulder+Vector((side*.035,.012,0))
    cx,cy,cz=center
    loft([(cx,cy-.070,cz,.13,.115),(cx,cy-.03,cz,.147,.14),(cx,cy+.055,cz,.115,.113),(cx,cy+.10,cz,.065,.066),(cx,cy+.115,cz,.008,.008)],BLUE,'upperarm_'+suffix,sides=24)
    loft([(cx,cy-.075,cz,.133,.118),(cx,cy-.055,cz,.143,.132)],GOLD,'upperarm_'+suffix,sides=24,steps=1)
    for zsign in (-1,1):ellipsoid(center+Vector((side*.09,.00,zsign*.11)),(.014,.014,.01),GOLD,'upperarm_'+suffix,8,12)
    mid=elbow.lerp(hand,.58)
    ellipsoid(mid+Vector((0,0,.025)),(.12,.083,.091),BLUE,'lowerarm_'+suffix,12,24)
    for t in (.12,.90):
        p=elbow.lerp(hand,t)
        tube([p+Vector((0,-.06,-.035)),p+Vector((0,-.065,.025)),p+Vector((0,0,.082)),p+Vector((0,.065,.025)),p+Vector((0,.06,-.035))],[.012]*5,GOLD,'lowerarm_'+suffix,8)
    ellipsoid(hand+Vector((side*.035,-.005,.01)),(.075,.055,.056),LEATHER,'hand_'+suffix,10,20)
    for i in range(4):
        x=hand.x+side*(.012+i*.024)
        tube([(x,.005+hand.y,.045),(x,-.038+hand.y,.064),(x,-.05+hand.y,.015)],[.018,.018,.013],LEATHER,'hand_'+suffix,8,2)
        ellipsoid((x,hand.y+.018,.043),(.013,.015,.018),BLUE,'hand_'+suffix,6,10)
    tube([hand+Vector((side*.02,.036,-.012)),hand+Vector((side*.075,.025,-.038)),hand+Vector((side*.082,-.012,-.013))],[.022,.019,.014],LEATHER,'hand_'+suffix,8)

# A designed head: chin, jaw, cheek, temple and forehead rings with an open face.
loft([(0,1.46,.018,.073,.071),(0,1.57,.017,.078,.075)],SKIN,'neck_01',sides=24)
loft([(0,1.525,.025,.075,.072),(0,1.55,.025,.116,.10),(0,1.59,.015,.147,.112),(0,1.665,.002,.171,.132),(0,1.755,-.01,.168,.143),(0,1.825,-.02,.136,.128),(0,1.865,-.024,.06,.069),(0,1.874,-.024,.004,.004)],SKIN,'Head',sides=36,tag='face')
for side in (-1,1):
    ellipsoid((side*.169,1.675,-.006),(.039,.061,.031),SKIN,'Head',10,18)
    ellipsoid((side*.184,1.678,.015),(.016,.034,.011),LIP,'Head',8,14)
    # Eye sockets and curved lids, with opaque whites and separate irises.
    ellipsoid((side*.070,1.706,.134),(.041,.027,.019),WHITE,'Head',10,24,'eye')
    ellipsoid((side*.065,1.706,.152),(.022,.023,.005),IRIS,'Head',10,20,'eye')
    ellipsoid((side*.064,1.706,.157),(.009,.016,.003),DARK,'Head',8,16,'eye')
    ellipsoid((side*.059,1.714,.160),(.004,.004,.0015),WHITE,'Head',6,10,'eye')
    tube([(side*.029,1.705,.146),(side*.046,1.727,.153),(side*.079,1.731,.147),(side*.108,1.711,.134)],[.003,.004,.004,.0025],HAIR,'Head',8,3,'upper_lid')
    tube([(side*.031,1.697,.146),(side*.071,1.682,.151),(side*.106,1.695,.137)],[.0025,.003,.0025],LIP,'Head',8,3,'lower_lid')
    tube([(side*.025,1.754,.141),(side*.061,1.763,.145),(side*.106,1.754,.129)],[.006,.008,.004],HAIR,'Head',10,4,'brow')
ellipsoid((0,1.683,.124),(.022,.038,.023),SKIN,'Head',10,20)
ellipsoid((0,1.657,.15),(.027,.018,.019),SKIN,'Head',10,20)
for side in (-1,1):ellipsoid((side*.016,1.650,.159),(.005,.003,.003),LIP,'Head',6,10)
tube([(-.054,1.603,.122),(-.024,1.595,.139),(.015,1.595,.142),(.054,1.607,.129)],[.003,.0035,.0035,.003],HAIR,'Head',8,4,'mouth')
tube([(-.036,1.589,.135),(0,1.585,.144),(.039,1.593,.139)],[.003,.004,.0025],LIP,'Head',8,3,'lower_lip')
# The inner mouth and teeth start almost closed; facial morphs open real volume.
ellipsoid((0,1.597,.143),(.029,.0015,.004),DARK,'Head',8,16,'mouth_inner')
ellipsoid((0,1.601,.148),(.023,.001,.0025),WHITE,'Head',8,16,'teeth')

# Hair is swept in coherent clumps under the helmet, with broad sculpted grooves.
for side in (-1,1):
    tube([(side*.122,1.802,.08),(side*.145,1.746,.096),(side*.147,1.689,.052)],[.026,.024,.010],HAIR,'Head',12,4)
tube([(-.105,1.789,.151),(-.025,1.789,.160),(.058,1.780,.159),(.09,1.773,.150)],[.016,.020,.015,.003],HAIR,'Head',12,4)

# Helmet shell is a curved open visor, with deliberately smooth outer normals.
pts,uv,faces=[],[],[]
nr,ns=12,40
def helmet_bottom(a):
    return 1.615+.215*max(0,math.cos(a))**.70

for j in range(nr):
    t=j/nr
    for i in range(ns+1):
        a=math.tau*i/ns
        bottom=helmet_bottom(a)
        y=bottom+(1.94-bottom)*t
        radius=math.sqrt(max(.001,1-((y-1.74)/.20)**2))
        pts.append((math.sin(a)*(.184*radius+.008),y,-.021+math.cos(a)*(.161*radius+.012)))
        uv.append((i/ns,t))
for j in range(nr-1):
    for i in range(ns):
        a=j*(ns+1)+i;faces.append((a,a+1,a+ns+2,a+ns+1))
# Close the crown with a true apex; the previous shell left an open top ring.
apex=len(pts);pts.append((0,1.94,-.021));uv.append((.5,1))
for i in range(ns):
    faces.append(((nr-1)*(ns+1)+i,(nr-1)*(ns+1)+i+1,apex))
mesh(pts,faces,BLUE,'Head',uv)
brim=[]
for i in range(41):
    a=math.tau*i/40;y=helmet_bottom(a)
    radius=math.sqrt(max(.001,1-((y-1.74)/.20)**2))
    brim.append((math.sin(a)*(.184*radius+.009),y,-.021+math.cos(a)*(.161*radius+.014)))
tube(brim,[.011]*len(brim),GOLD,'Head',8,1)
for side in (-1,1):
    ellipsoid((side*.176,1.686,-.018),(.025,.061,.061),GOLD,'Head',10,24)
    ellipsoid((side*.195,1.686,-.018),(.014,.039,.039),GEM,'Head',10,24)
    tube([(side*.151,1.77,.036),(side*.164,1.69,.04),(side*.139,1.585,.071)],[.009,.012,.01],SILVER,'Head')
# Raised crown ridge and a swept horsehair plume; rear silhouette matches the cape.
tube([(0,1.806,.143),(0,1.884,.091),(0,1.927,-.015),(0,1.875,-.146),(0,1.74,-.194)],[.012,.015,.017,.013,.008],SILVER,'Head',10,4)
# A long, tapered, rear-swept crest replaces the compact upright curl.
# Keep the same Head weighting and 'plume' tag for PlumeSway.
tube([(0,1.91,-.043),(0,2.045,-.105),(0,2.095,-.245),(.012,2.073,-.39),(.025,2.01,-.52),(.035,1.945,-.61)],[.025,.049,.060,.046,.026,.003],RED,'Head',12,5,'plume')

# Sword: enclosed steel volume with a swept tip and a clean central ridge.
hand=REST['hand_r'];hx,hy,hz=hand
tube([(hx,hy,hz-.05),(hx,hy,hz+.10)],[.026,.026],LEATHER,'hand_r',12,6)
for i in range(5):
    z=hz-.04+i*.03
    tube([(hx-.023,hy,z),(hx,hy+.026,z),(hx+.023,hy,z),(hx,hy-.026,z),(hx-.023,hy,z)],[.003]*5,GOLD,'hand_r',6,1)
ellipsoid((hx,hy,hz-.075),(.038,.038,.038),GOLD,'hand_r',10,16)
tube([(hx-.145,hy-.013,hz+.123),(hx-.08,hy+.012,hz+.13),(hx,hy+.006,hz+.15),(hx+.08,hy+.012,hz+.13),(hx+.145,hy-.013,hz+.123)],[.016,.021,.026,.021,.016],GOLD,'hand_r',10)
pts=[(hx-.055,hy,hz+.16),(hx+.055,hy,hz+.16),(hx+.046,hy,hz+.74),(hx-.017,hy,hz+.99),(hx-.035,hy,hz+.73),(hx,hy+.022,hz+.18),(hx+.005,hy+.019,hz+.72),(hx,hy-.022,hz+.18),(hx+.005,hy-.019,hz+.72)]
faces=[(0,5,6,4),(5,1,2,6),(4,6,3),(6,2,3),(0,4,8,7),(7,8,2,1),(4,3,8),(8,3,2),(0,7,1,5)]
mesh(pts,faces,SILVER,'hand_r')
ellipsoid((hx,hy+.029,hz+.145),(.026,.009,.031),GEM,'hand_r',8,16)

# Shield follows the front plane of the forearm in the source rest pose.
left=REST['lowerarm_l'].lerp(REST['hand_l'],.50);x,y,z=left
outline=[(x-.15,y+.22),(x+.12,y+.22),(x+.19,y+.10),(x+.14,y-.15),(x,y-.32),(x-.15,y-.15),(x-.19,y+.10)]
plate(outline,z+.075,.035,GOLD,'lowerarm_l')
inner=[(x+(u-x)*.84,y+(v-y)*.84) for u,v in outline]
plate(inner,z+.113,.008,BLUE,'lowerarm_l')
star(x,y-.018,z+.135,.096,GOLD,'lowerarm_l')

# Keep source-space coordinates so expressions use the identical head transform.
SOURCE_POSITIONS=[game(Vector(v)) for v in V]
def head_point(p):
    pivot=REST['Head'];d=Vector(p)-pivot
    return pivot+Vector((d.x*1.12,d.y*1.05,d.z*1.06))

# Create a single skinned mesh, named surfaces, UVs and facial/secondary morphs.
for i,weights in enumerate(WEIGHTS):
    if weights.get('Head',0)>.99:
        V[i]=xyz(head_point(SOURCE_POSITIONS[i]))
data=bpy.data.meshes.new('Knight_AuthoredTopology')
data.from_pydata(V,[],F);data.update()
obj=bpy.data.objects.new('Knight',data);bpy.context.collection.objects.link(obj)
data.materials.append(MATS[0])
for polygon,material_index in zip(data.polygons,MI):
    polygon.material_index=0;polygon.use_smooth=True
uv_layer=data.uv_layers.new(name='UVMap')
pbr_layer=data.uv_layers.new(name='MaterialParameters')
colors=data.color_attributes.new(name='SculptTint',type='FLOAT_COLOR',domain='POINT')
for i,c in enumerate(COL):colors.data[i].color=c
for polygon in data.polygons:
    for loop in polygon.loop_indices:
        vertex=data.loops[loop].vertex_index
        uv_layer.data[loop].uv=UV[vertex]
        pbr_layer.data[loop].uv=PBR[vertex]
groups={b.name:obj.vertex_groups.new(name=b.name) for b in rig.data.bones}
for i,weights in enumerate(WEIGHTS):
    for bone,w in weights.items():
        if w>0:groups[bone].add([i],w,'REPLACE')
modifier=obj.modifiers.new('KnightSkin','ARMATURE');modifier.object=rig
obj.parent=rig
obj.shape_key_add(name='Basis')
MORPHS=['Blink','PlumeSway','Smile','Focus','Surprised','Hurt']
affected={}
for name in MORPHS:
    shape=obj.shape_key_add(name=name)
    changed=0
    for i,tag in enumerate(TAGS):
        p=SOURCE_POSITIONS[i].copy();original=p.copy()
        corner=min(1,abs(p.x)/.055)
        if name=='Blink' and tag in ('eye','upper_lid','lower_lid'):
            p.y=1.704+(p.y-1.704)*.025
        elif name=='PlumeSway' and tag=='plume':
            p.x+=.07*max(0,(p.y-1.91)/.17)
        elif name=='Smile':
            if tag in ('mouth','lower_lip'):
                p.y+=.004+.016*corner**1.5
            elif tag=='mouth_inner':
                p.y=1.599+(p.y-1.597)*5.5;p.x*=1.1
            elif tag=='teeth':
                p.y=1.604+(p.y-1.601)*3.5
            elif tag in ('eye','upper_lid','lower_lid'):
                p.y=1.707+(p.y-1.706)*.87
            elif tag=='brow':p.y+=.003
        elif name=='Focus':
            if tag=='brow':p.y+=-.016+.023*min(1,abs(p.x)/.11)
            elif tag in ('eye','upper_lid','lower_lid'):p.y=1.704+(p.y-1.706)*.77
            elif tag in ('mouth','lower_lip'):p.y-=.004*corner
        elif name=='Surprised':
            if tag=='brow':p.y+=.017
            elif tag in ('eye','upper_lid','lower_lid'):p.y=1.708+(p.y-1.706)*1.18
            elif tag=='mouth_inner':p.y=1.596+(p.y-1.597)*15;p.x*=.8
            elif tag=='mouth':p.y-=.012*(1-corner);p.x*=.82
            elif tag in ('lower_lip','teeth'):p.y-=.014
        elif name=='Hurt':
            if tag=='brow':p.y+=.014-.022*corner
            elif tag in ('eye','upper_lid','lower_lid'):p.y=1.702+(p.y-1.706)*.45
            elif tag in ('mouth','lower_lip'):p.y-=.011*corner
            elif tag=='mouth_inner':p.y=1.593+(p.y-1.597)*6
            elif tag=='teeth':p.y-=.005
        if (p-original).length>.000001:
            shape.data[i].co=xyz(head_point(p) if WEIGHTS[i].get('Head',0)>.99 else p)
            changed+=1
    affected[name]=changed

bpy.context.view_layer.objects.active=obj
obj.select_set(True);rig.select_set(True)
data.calc_loop_triangles()
triangle_count=len(data.loop_triangles)
blend=EDITABLE/'knight.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
bpy.ops.export_scene.gltf(filepath=str(DEST/'knight.glb'),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_morph=True,export_attributes=True,export_yup=True)
binary=DEST/'knight.glb'
manifest={
 'character':'knight','revision':'authored-knight-2-expressions','source_generator':'tools/build_knight_asset.py',
 'blender_version':bpy.app.version_string,'mesh_vertices':len(V),'triangles':triangle_count,
 'material_surfaces':1,'painted_material_regions':len(MATS),'bones':len(rig.data.bones),'morph_targets':MORPHS,
 'morph_affected_vertices':affected,
 'blink_closure_y':head_point(Vector((0,1.704,0))).y,
 'asset_sha256':hashlib.sha256(binary.read_bytes()).hexdigest(),'asset_bytes':binary.stat().st_size,
 'rig_source':'Quaternius Universal Base Characters, CC0 1.0; original skeleton retained',
 'geometry':'New Lamont Labs mesh, costume, face, helmet, plume, weapon and shield, authored by the source generator',
 'base_body_mesh_reused':False,'motion_source':'Existing Quaternius CC0 authored-motion library, sampled by game/rig_motion.gd',
 'concept_reference':'MysticRun fantasy heroes concept sheet, November 3, 2026',
 'texture_method':'UV-mapped mesh with linear per-vertex authored color gradients; secondary UV stores metallic/roughness values for one runtime material; no bitmap texture atlas in this revision',
 'physical_phone_tested':False,
}
(DEST/'PROVENANCE.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Rebuilding owned geometry must update its exact byte record, never its rights.
registry_path=ROOT/'assets/asset_registry.json'
if registry_path.is_file():
    registry=json.loads(registry_path.read_text())
    entry=next(e for e in registry['assets'] if e['id']=='mysticrun-authored-knight')
    assert entry['publisher']=='Lamont Labs' and entry['license']=='LicenseRef-LamontLabs-Original'
    entry['files']=[{'path':binary.relative_to(ROOT).as_posix(),'sha256':manifest['asset_sha256'],'bytes':manifest['asset_bytes']}]
    entry['modifications']=['Original weighted face, costume and equipment; refined open helmet and six facial/secondary morph targets.','Retained previously admitted CC0 humanoid skeleton; original body mesh not reused.']
    registry_path.write_text(json.dumps(registry,indent=2)+'\n')
print('KNIGHT_ASSET',json.dumps(manifest))
