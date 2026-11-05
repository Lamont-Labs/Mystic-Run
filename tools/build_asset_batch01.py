#!/usr/bin/env python3
"""Build MysticRun's first replacement asset review batch in Blender 4.3+.

blender --background --python tools/build_asset_batch01.py

Produces real GLB geometry. Review files live under art/ (excluded from the
game export), so unapproved candidates cannot silently enter the Android build.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import random

import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
BATCH = ROOT / "art/asset_batch_01"
DEST = BATCH / "review/assets/original"
DEST.mkdir(parents=True, exist_ok=True)
TAU = math.tau
records = []
parts = []
palette = {
    "ivory": "e5ddcc", "stone": "969bb4", "shadow": "424d72",
    "blue": "245b91", "teal": "318f9d", "gold": "d3ac68",
    "silver": "b9d1db", "leather": "4b2935", "wood": "513544",
    "violet": "6850a2", "glow": "7be4df", "white": "e4f9ef",
}


def linear(hex_color):
    result = []
    for i in (0, 2, 4):
        c = int(hex_color[i:i + 2], 16) / 255
        result.append(c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4)
    return result


def reset():
    global parts
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    parts = []


def mesh(name, vertices, faces, pigment, surface="matte", smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    color = data.color_attributes.new(name="Paint", type="FLOAT_COLOR", domain="CORNER")
    rgb = linear(palette.get(pigment, pigment))
    low = min(v[2] for v in vertices)
    span = max(1e-5, max(v[2] for v in vertices) - low)
    for p in data.polygons:
        p.use_smooth = smooth
        for loop in p.loop_indices:
            z = data.vertices[data.loops[loop].vertex_index].co.z
            shade = .82 + .18 * ((z - low) / span)
            color.data[loop].color = (*[c * shade for c in rgb], 1)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material(surface))
    parts.append(obj)
    return obj


def material(kind):
    name = "Batch01_" + kind
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = {"matte": .79, "metal": .34, "light": .28}[kind]
    shader.inputs["Metallic"].default_value = .62 if kind == "metal" else 0
    node = mat.node_tree.nodes.new("ShaderNodeVertexColor")
    node.layer_name = "Paint"
    mat.node_tree.links.new(node.outputs["Color"], shader.inputs["Base Color"])
    if kind == "light":
        shader.inputs["Emission Color"].default_value=(*linear(palette['glow']),1)
        shader.inputs["Emission Strength"].default_value = .42
    return mat


def box(name, at, size, pigment, bevel=.025, surface="matte"):
    x, y, z = at
    a, b, c = [s * .5 for s in size]
    v = [(x+i*a, y+j*b, z+k*c) for k in (-1, 1) for j in (-1, 1) for i in (-1, 1)]
    o = mesh(name, v, [(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)], pigment, surface)
    if bevel:
        bpy.context.view_layer.objects.active = o
        mod = o.modifiers.new("Crafted edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o


def lathe(name, profile, pigment, sides=32, surface="matte", at=(0,0,0), smooth=True):
    v, f = [], []
    for z, radius in profile:
        for i in range(sides):
            a = TAU*i/sides
            v.append((at[0]+radius*math.cos(a), at[1]+radius*math.sin(a), at[2]+z))
    for j in range(len(profile)-1):
        for i in range(sides):
            a=j*sides+i;b=j*sides+(i+1)%sides
            f.append((a,b,b+sides,a+sides))
    f.extend([tuple(reversed(range(sides))), tuple((len(profile)-1)*sides+i for i in range(sides))])
    return mesh(name,v,f,pigment,surface,smooth)


def tube(name, path, radius, pigment, sides=8, surface="metal"):
    v, f = [], []
    for j, point in enumerate(path):
        p=Vector(point)
        tangent=Vector(path[min(j+1,len(path)-1)])-Vector(path[max(j-1,0)])
        tangent.normalize()
        right=tangent.cross(Vector((0,1,0)))
        if right.length<.01:right=tangent.cross(Vector((1,0,0)))
        right.normalize();up=tangent.cross(right).normalized()
        for i in range(sides):
            a=TAU*i/sides
            v.append(p+radius*(right*math.cos(a)+up*math.sin(a)))
    for j in range(len(path)-1):
        for i in range(sides):
            a=j*sides+i;b=j*sides+(i+1)%sides;f.append((a,b,b+sides,a+sides))
    f.extend([tuple(reversed(range(sides))),tuple((len(path)-1)*sides+i for i in range(sides))])
    return mesh(name,v,f,pigment,surface,True)


def ring(name, at, radius, thickness, pigment, start=0, end=TAU, surface="metal", steps=48):
    path=[(at[0]+radius*math.sin(start+(end-start)*i/steps),at[1],at[2]+radius*math.cos(start+(end-start)*i/steps)) for i in range(steps+1)]
    return tube(name,path,thickness,pigment,surface=surface)


def crystal(name, at, radius, height, pigment="glow", sides=6):
    profile=[(at[2]-height*.5,0.01),(at[2]-height*.27,radius*.82),(at[2]+height*.19,radius),(at[2]+height*.5,0.002)]
    return lathe(name,profile,pigment,sides,"light",(at[0],at[1],0),False)


def plate(name, outline, y, depth, pigment, surface="metal"):
    n=len(outline)
    v=[(x,y+d,z) for d in (-depth/2,depth/2) for x,z in outline]
    f=[tuple(reversed(range(n))),tuple(n+i for i in range(n))]
    f.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
    return mesh(name,v,f,pigment,surface)


def star(at, radius, pigment="gold", points=4, y=0, depth=.012):
    outline=[]
    for i in range(points*2):
        a=TAU*i/(points*2);r=radius if i%2==0 else radius*.32
        outline.append((at[0]+math.sin(a)*r,at[2]+math.cos(a)*r))
    return plate("Heraldic star",outline,y,depth,pigment)


def finish(identity, purpose, limit):
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    obj=bpy.context.object;obj.name=identity
    # Consolidate duplicate material slots introduced by joining components.
    mats=[];indices={}
    for slot in obj.data.materials:
        if slot.name not in indices:indices[slot.name]=len(mats);mats.append(slot)
    remap=[indices[m.name] for m in obj.data.materials]
    assignments=[remap[polygon.material_index] for polygon in obj.data.polygons]
    obj.data.materials.clear()
    for mat in mats:obj.data.materials.append(mat)
    for polygon,index in zip(obj.data.polygons,assignments):polygon.material_index=index
    obj.data.calc_loop_triangles()
    triangles=len(obj.data.loop_triangles)
    assert 100<triangles<=limit,(identity,triangles,limit)
    assert len(mats)<=3
    path=DEST/(identity+".glb")
    bpy.ops.export_scene.gltf(filepath=str(path),export_format="GLB",use_selection=True,export_yup=True,export_animations=False,export_extras=True)
    data=path.read_bytes()
    coords=[obj.matrix_world@v.co for v in obj.data.vertices]
    minimum=[min(p[i] for p in coords) for i in range(3)];maximum=[max(p[i] for p in coords) for i in range(3)]
    records.append({"id":identity,"path":path.relative_to(BATCH).as_posix(),"purpose":purpose,"publisher":"Lamont Labs","license":"LicenseRef-LamontLabs-Original","triangles":triangles,"materials":len(mats),"textures":0,"rigged":False,"sha256":hashlib.sha256(data).hexdigest(),"bytes":len(data),"dimensions_blender_xyz":[round(b-a,4) for a,b in zip(minimum,maximum)],"status":"REVIEW_ONLY"})
    print("ASSET",identity,triangles,len(mats),len(data),flush=True)


def sword():
    reset()
    # A continuous tapered blade with a raised central fuller and sharpened bevels.
    rows=[(.50,.115),(.61,.145),(1.35,.104),(1.57,.0)]
    v=[]
    for z,w in rows:
        v.extend([(-w,0,z),(-w*.74,-.022,z),(0,-.046,z),(w*.74,-.022,z),(w,0,z),(0,.034,z)])
    f=[]
    for j in range(len(rows)-1):
        for i in range(6):f.append((j*6+i,j*6+(i+1)%6,(j+1)*6+(i+1)%6,(j+1)*6+i))
    f.append(tuple(reversed(range(6))))
    mesh("Forged blade",v,f,"silver","metal")
    plate("Enamel fuller",[(-.022,.66),(-.016,1.24),(0,1.37),(.016,1.24),(.022,.66)],-.047,.004,"blue")
    for side in (-1,1):
        tube("Swept crossguard",[(0,0,.52),(side*.16,0,.53),(side*.26,0,.47),(side*.30,0,.49)],.034,"gold",10)
    lathe("Leather grip",[(.16,.034),(.19,.042),(.43,.042),(.47,.055)],"leather",20)
    for i in range(9):
        z=.20+i*.026
        lathe("Grip binding",[(z,.044),(z+.006,.045),(z+.009,.044)],"gold",20,"metal")
    lathe("Pommel",[(.07,.012),(.1,.055),(.14,.052),(.17,.025)],"gold",24,"metal")
    crystal("Pommel jewel",(0,-.038,.116),.026,.055,"glow")
    star((0,0,.54),.080,y=-.053,depth=.02)
    finish("skyguard_sword","Knight weapon candidate with forged blade, inlaid fuller and wrapped grip",5000)


def staff():
    reset()
    lathe("Carved shaft",[(0,.025),(.08,.034),(.35,.027),(1.15,.029),(1.47,.047),(1.55,.025)],"wood",24)
    for z in [.05,.12,.40,.98,1.16,1.40,1.49]:
        lathe("Turned collar",[(z,.034),(z+.009,.043),(z+.025,.043),(z+.034,.033)],"gold",24,"metal")
    for i in range(11):
        z=.70+i*.025
        lathe("Leather hand wrap",[(z,.033),(z+.012,.036),(z+.020,.033)],"leather",20)
    ring("Crescent outer",(0,0,1.86),.29,.027,"gold",.40,TAU-.40,steps=56)
    ring("Crescent inset",(0,.012,1.86),.24,.012,"silver",.60,TAU-.60,steps=48)
    crystal("Suspended moonstone",(0,0,1.87),.090,.32)
    for side in (-1,1):
        tube("Crystal claw",[(0,0,1.53),(side*.12,0,1.64),(side*.10,0,1.79)],.016,"gold")
        for i in range(3):
            star((side*(.22-i*.015),0,1.67+i*.055),.02,y=-.029,depth=.005)
    lathe("Heel cap",[(0,.019),(.06,.033),(.09,.032)],"gold",24,"metal")
    finish("moonspire_staff","Witch staff candidate with a layered crescent and suspended crystal",6500)


def lantern():
    reset()
    lathe("Plinth",[(0,.20),(.04,.24),(.10,.24),(.14,.18),(.19,.15)],"shadow",8)
    lathe("Lower bezel",[(.17,.17),(.20,.20),(.23,.20),(.25,.17)],"gold",8,"metal")
    lathe("Luminous body",[(.24,.13),(.74,.13)],"glow",8,"light",smooth=False)
    for i in range(8):
        a=TAU*i/8;x=.174*math.cos(a);y=.174*math.sin(a)
        tube("Window mullion",[(x,y,.23),(x,y,.76)],.018,"gold")
        tube("Pointed tracery",[(x*.95,y*.95,.30),(x*.98,y*.98,.57),(x*.50,y*.50,.73)],.009,"blue")
    lathe("Crown bezel",[(.74,.17),(.77,.205),(.80,.205),(.83,.17)],"gold",8,"metal")
    lathe("Enamel roof",[(.82,.22),(.88,.21),(1.02,.095),(1.06,.04)],"blue",8)
    lathe("Finial",[(1.02,.035),(1.10,.05),(1.19,.0)],"gold",16,"metal")
    ring("Handle",(0,0,1.18),.07,.014,"gold",steps=32)
    finish("citadel_lantern","Repeatable castle lantern with framed luminous windows and pointed enamel roof",6500)


def waystone():
    reset()
    lathe("Foundation",[(0,.48),(.07,.53),(.16,.53),(.21,.43),(.27,.42)],"shadow",8)
    lathe("Gold base fillet",[(.20,.45),(.23,.46),(.26,.44)],"gold",8,"metal")
    lathe("Carved shaft",[(.25,.35),(.39,.33),(1.17,.24),(1.36,.29),(1.46,.19)],"stone",8,smooth=False)
    for side in (-1,1):
        for i in range(3):
            z=.46+i*.20
            tube("Inlaid rune",[(side*.11,-.30,z),(0,-.315,z+.08),(side*.07,-.30,z+.13)],.012,"glow",6,"light")
    lathe("Crown setting",[(1.35,.26),(1.40,.33),(1.48,.32),(1.54,.21)],"gold",8,"metal")
    crystal("Relic crystal",(0,0,1.77),.18,.54)
    for i in range(4):
        a=TAU*i/4+math.pi/4
        tube("Crown claw",[(.26*math.cos(a),.26*math.sin(a),1.42),(.26*math.cos(a),.26*math.sin(a),1.60),(.15*math.cos(a),.15*math.sin(a),1.69)],.022,"gold")
    finish("relic_waystone","Landmark or checkpoint art candidate with inset runes and caged crystal",7000)


def gateway():
    reset()
    for side in (-1,1):
        x=side*2.55
        box("Stepped foot",(x,0,.18),(1.10,1.18,.36),"shadow",.055)
        box("Limestone pier",(x,0,1.65),(.68,.82,2.65),"ivory",.045)
        box("Inset pier panel",(x,-.428,1.64),(.34,.05,1.80),"blue",.018)
        for z in [.42,2.65,2.85]:box("Pier belt",(x,0,z),(.84,.98,.10),"gold",.022,"metal")
        for dx in [-.19,.19]:
            tube("Pier fluting",[(x+dx,-.455,.62),(x+dx,-.455,2.50)],.018,"gold")
        lathe("Side crown",[(2.92,.43),(3.10,.43),(3.16,.30),(3.82,.0)],"blue",8,at=(x,0,0),smooth=False)
        star((x,0,2.60),.12,y=-.50,depth=.022)
    # Masonry follows a true pointed arch; each voussoir is a shaped solid wedge.
    for side in (-1,1):
        def p(t,r):
            return Vector((side*(2.55*(1-t)),0,2.88+1.62*(math.sin(t*math.pi/2))))+Vector((side*r*math.cos(t*math.pi/2),0,r*math.sin(t*math.pi/2)))
        for i in range(13):
            t0=(i+.018)/13;t1=(i+.982)/13
            outline=[p(t0,.0),p(t1,.0),p(t1,.26),p(t0,.26)]
            vertices=[(v.x,y,v.z) for y in [-.39,.39] for v in outline]
            mesh("Cut arch stone",vertices,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],"ivory" if i%3 else "stone")
        line=[p(i/40,-.025) for i in range(41)]
        tube("Gold arch reveal",[(v.x,-.42,v.z) for v in line],.027,"gold")
    star((0,0,4.50),.24,y=-.43,depth=.06)
    for side in (-1,1):
        tube("Crown flourish",[(0,-.42,4.48),(side*.35,-.42,4.57),(side*.57,-.42,4.48)],.022,"gold")
    finish("skybridge_gateway","Off-route signature architecture with cut masonry, inset panels and heraldic metalwork",9000)


for build in (sword,staff,lantern,waystone,gateway):
    build()

(BATCH/"original-assets.json").write_text(json.dumps({"schema":1,"generator":"tools/build_asset_batch01.py","blender":bpy.app.version_string,"runtime_integration":False,"assets":records},indent=2)+"\n")
print("BATCH COMPLETE",len(records),flush=True)
