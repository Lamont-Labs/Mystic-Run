"""Shared, deterministic Blender authoring helpers for MysticRun characters.

Coordinates are X/right, Y/up, Z/front. Geometry and palette are authored by
each character script; only the previously admitted CC0 skeleton is retained.
"""
from __future__ import annotations
import hashlib
import json
import math
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]

def xyz(p):
    return Vector((p[0], -p[2], p[1]))

def game(p):
    return Vector((p[0], p[2], -p[1]))

def smooth_path(points, steps=3):
    points=[Vector(p) for p in points];out=[]
    for i in range(len(points)-1):
        a,b,c,d=points[max(0,i-1)],points[i],points[i+1],points[min(i+2,len(points)-1)]
        for j in range(steps):
            t=j/steps
            out.append(.5*(2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    return out+[points[-1]]

class CharacterMesh:
    def __init__(self, identity, gender='Male', outward_tubes=False):
        self.identity=identity
        # Preserve prior saved derivatives when rebuilding them. New character
        # revisions can opt into outward side faces; tube end caps stay outward.
        self.outward_tubes=outward_tubes
        bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
        bpy.ops.import_scene.gltf(filepath=str(ROOT/f'assets/models/quaternius/base/Superhero_{gender}_FullBody.gltf'))
        self.rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        self.rig.name=identity.title()+'Rig'
        for obj in list(bpy.data.objects):
            if obj!=self.rig:bpy.data.objects.remove(obj,do_unlink=True)
        self.rest={b.name:game(self.rig.matrix_world@b.head_local) for b in self.rig.data.bones}
        self.vertices=[];self.faces=[];self.colors=[];self.parameters=[];self.weights=[];self.tags=[];self.uv=[]
        self.palette={};self.bone_additions=[]

    def material(self,name,hex_color,metal=0.0,rough=.85):
        def linear(v):
            v=int(v,16)/255
            return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
        self.palette[name]=(tuple(linear(hex_color[i:i+2]) for i in (0,2,4)),metal,rough)
        return name

    def mesh(self,points,faces,material,bone,uv=None,tag=''):
        start=len(self.vertices)
        rgb,metal,rough=self.palette[material]
        for i,p in enumerate(points):
            p=Vector(p);coord=uv[i] if uv else (.5,.5)
            self.vertices.append(p);self.uv.append(coord)
            gradient=.88+.12*math.sin(coord[1]*math.pi)
            self.colors.append(tuple(min(1,c*gradient) for c in rgb)+(1,))
            self.parameters.append((metal,rough))
            weights=bone(p) if callable(bone) else {bone:1.0}
            total=sum(weights.values())
            assert total>0 and all(w>=0 for w in weights.values())
            self.weights.append({n:w/total for n,w in weights.items() if w>0})
            self.tags.append(tag)
        self.faces.extend(tuple(start+i for i in f) for f in faces)

    def ellipsoid(self,at,size,material,bone,rings=8,sides=16,tag=''):
        pts=[];faces=[];uv=[]
        for j in range(rings+1):
            theta=math.pi*j/rings
            for i in range(sides+1):
                a=math.tau*i/sides
                pts.append((at[0]+size[0]*math.sin(theta)*math.sin(a),at[1]+size[1]*math.cos(theta),at[2]+size[2]*math.sin(theta)*math.cos(a)))
                uv.append((i/sides,1-j/rings))
        for j in range(rings):
            for i in range(sides):
                a=j*(sides+1)+i;faces.append((a,a+sides+1,a+sides+2,a+1))
        self.mesh(pts,faces,material,bone,uv,tag)

    def loft(self,rows,material,bone,sides=24,steps=3,tag=''):
        profile=[]
        for j in range(len(rows)-1):
            a,b,c,d=rows[max(0,j-1)],rows[j],rows[j+1],rows[min(j+2,len(rows)-1)]
            for s in range(steps):
                t=s/steps
                profile.append([.5*(2*b[k]+(-a[k]+c[k])*t+(2*a[k]-5*b[k]+4*c[k]-d[k])*t*t+(-a[k]+3*b[k]-3*c[k]+d[k])*t*t*t) for k in range(5)])
        profile.append(rows[-1]);pts=[];faces=[];uv=[]
        for j,(x,y,z,w,depth) in enumerate(profile):
            for i in range(sides+1):
                a=math.tau*i/sides
                pts.append((x+math.sin(a)*max(.001,w),y,z+math.cos(a)*max(.001,depth)));uv.append((i/sides,j/(len(profile)-1)))
        for j in range(len(profile)-1):
            for i in range(sides):
                a=j*(sides+1)+i;faces.append((a,a+1,a+sides+2,a+sides+1))
        faces.extend([tuple(range(sides,-1,-1)),tuple((len(profile)-1)*(sides+1)+i for i in range(sides+1))])
        self.mesh(pts,faces,material,bone,uv,tag)

    def tube(self,points,radii,material,bone,sides=10,steps=3,tag='',caps=True):
        path=smooth_path(points,steps)
        radii=[radii[i]+(radii[i+1]-radii[i])*j/steps for i in range(len(radii)-1) for j in range(steps)]+[radii[-1]]
        pts=[];faces=[];uv=[];previous=None
        for j,p in enumerate(path):
            tangent=(path[min(j+1,len(path)-1)]-path[max(0,j-1)]).normalized()
            cross=previous-tangent*previous.dot(tangent) if previous is not None else tangent.cross(Vector((0,0,1)))
            if cross.length<.01:cross=tangent.cross(Vector((0,1,0)))
            cross.normalize();up=tangent.cross(cross).normalized();previous=cross.copy()
            for i in range(sides+1):
                a=math.tau*i/sides;pts.append(p+radii[j]*(cross*math.cos(a)+up*math.sin(a)));uv.append((i/sides,j/(len(path)-1)))
        for j in range(len(path)-1):
            for i in range(sides):
                a=j*(sides+1)+i;faces.append((a,a+1,a+sides+2,a+sides+1) if self.outward_tubes else (a,a+sides+1,a+sides+2,a+1))
        if caps:
            faces.append(tuple(range(sides-1,-1,-1)))
            faces.append(tuple((len(path)-1)*(sides+1)+i for i in range(sides)))
        self.mesh(pts,faces,material,bone,uv,tag)

    def limb(self,a,b,radii,material,bone,sides=18):
        points=[Vector(a).lerp(Vector(b),t) for t in [0,.10,.30,.65,.90,1]]
        self.tube(points,radii,material,bone,sides=sides,steps=2)

    def plate(self,outline,z,depth,material,bone):
        x=sum(p[0] for p in outline)/len(outline);y=sum(p[1] for p in outline)/len(outline)
        pts=[];faces=[];n=len(outline)
        for t in range(3):
            for a,b in outline:
                k=.88 if t==2 else 1
                pts.append((x+(a-x)*k,y+(b-y)*k,z+(0 if t==0 else depth*.65 if t==1 else depth)))
        for j in range(2):
            for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
        faces.append(tuple(range(n-1,-1,-1)));faces.append(tuple(2*n+i for i in range(n)))
        self.mesh(pts,faces,material,bone)

    def add_bones(self,definitions):
        bpy.context.view_layer.objects.active=self.rig
        self.rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
        for name,parent,position in definitions:
            bone=self.rig.data.edit_bones.new(name)
            bone.head=self.rig.matrix_world.inverted()@xyz(position)
            bone.tail=self.rig.matrix_world.inverted()@xyz(Vector(position)+Vector((0,.16,0)))
            bone.parent=self.rig.data.edit_bones[parent]
            self.bone_additions.append(name)
        bpy.ops.object.mode_set(mode='OBJECT')

    def export(self,morphs,metadata):
        data=bpy.data.meshes.new(self.identity.title()+'_AuthoredTopology')
        data.from_pydata([xyz(p) for p in self.vertices],[],self.faces);data.update()
        obj=bpy.data.objects.new(self.identity.title(),data);bpy.context.collection.objects.link(obj)
        mat=bpy.data.materials.new(self.identity.title()+'_VertexPaint');mat.use_nodes=True
        vertex=mat.node_tree.nodes.new('ShaderNodeVertexColor');vertex.layer_name='SculptTint'
        mat.node_tree.links.new(vertex.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
        data.materials.append(mat)
        for face in data.polygons:face.use_smooth=True
        data.update()
        # UV seams duplicate positions. Average their normals without welding
        # topology, paint regions, skin weights or facial shape-key indices.
        normals=[v.normal.copy() for v in data.vertices];groups={}
        for i,p in enumerate(self.vertices):
            key=tuple(round(v,6) for v in p)+tuple(round(v,6) for v in self.colors[i])+tuple(sorted((name,round(w,6)) for name,w in self.weights[i].items()))
            groups.setdefault(key,[]).append(i)
        for group in groups.values():
            if len(group)>1:
                average=sum((normals[i] for i in group),Vector()).normalized()
                for i in group:normals[i]=average
        data.normals_split_custom_set_from_vertices(normals)
        color=data.color_attributes.new(name='SculptTint',type='FLOAT_COLOR',domain='POINT')
        for i,value in enumerate(self.colors):color.data[i].color=value
        uv=data.uv_layers.new(name='UVMap');pbr=data.uv_layers.new(name='MaterialParameters')
        for loop in data.loops:
            uv.data[loop.index].uv=self.uv[loop.vertex_index];pbr.data[loop.index].uv=self.parameters[loop.vertex_index]
        groups={b.name:obj.vertex_groups.new(name=b.name) for b in self.rig.data.bones}
        for i,weights in enumerate(self.weights):
            for name,w in weights.items():groups[name].add([i],w,'REPLACE')
        obj.parent=self.rig;skin=obj.modifiers.new('CharacterSkin','ARMATURE');skin.object=self.rig
        obj.shape_key_add(name='Basis');affected={}
        for name,deform in morphs.items():
            target=obj.shape_key_add(name=name);count=0
            for i,p in enumerate(self.vertices):
                point=Vector(deform(p.copy(),self.tags[i]))
                if (point-p).length>1e-6:target.data[i].co=xyz(point);count+=1
            affected[name]=count
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);self.rig.select_set(True);bpy.context.view_layer.objects.active=obj
        destination=ROOT/'assets/characters'/self.identity;destination.mkdir(parents=True,exist_ok=True)
        editable=ROOT/'art/characters'/self.identity;editable.mkdir(parents=True,exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(editable/(self.identity+'.blend')))
        output=destination/(self.identity+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_morph=True,export_attributes=True,export_yup=True)
        data.calc_loop_triangles()
        report={**metadata,'character':self.identity,'blender_version':bpy.app.version_string,'mesh_vertices':len(self.vertices),'triangles':len(data.loop_triangles),'material_surfaces':1,'painted_material_regions':len(self.palette),'bones':len(self.rig.data.bones),'new_bones':self.bone_additions,'morph_targets':list(morphs),'morph_affected_vertices':affected,'seam_normals_averaged':True,'asset_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'asset_bytes':output.stat().st_size,'base_body_mesh_reused':False,'physical_phone_tested':False}
        (destination/'PROVENANCE.json').write_text(json.dumps(report,indent=2)+'\n')
        registry_path=ROOT/'assets/asset_registry.json';registry=json.loads(registry_path.read_text())
        identifier='mysticrun-authored-'+self.identity
        entry=next((e for e in registry['assets'] if e['id']==identifier),None)
        if entry is None:
            license_path=ROOT/f'assets/licenses/{self.identity}-original.txt'
            license_path.write_text(f'MysticRun original {self.identity.title()} artwork\nCopyright 2026 Lamont Labs. All rights reserved.\n\nThe visible geometry, costume, face, equipment and new control bones are authored by Lamont Labs. The retained Quaternius skeleton remains under its included CC0 1.0 dedication; see quaternius-CC0.txt. This record does not relicense third-party work.\n\nLicenseRef-LamontLabs-Original identifies owner-authored project artwork and is not a license grant to third parties.\n')
            evidence=license_path.read_bytes()
            entry={'id':identifier,'publisher':'Lamont Labs','license':'LicenseRef-LamontLabs-Original','cost_usd':0,'commercial_use':True,'modification':True,'game_distribution':True,'attribution_required':False,'edition':'Original derivative','sources':[metadata['source_generator'],str((destination/'PROVENANCE.json').relative_to(ROOT))],'derived_from':['quaternius-base-characters'],'license_evidence':{'path':license_path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(evidence).hexdigest(),'bytes':len(evidence)}}
            registry['assets'].append(entry)
        assert entry['publisher']=='Lamont Labs' and entry['license']=='LicenseRef-LamontLabs-Original'
        entry['modifications']=metadata['modifications']
        entry['files']=[{'path':output.relative_to(ROOT).as_posix(),'sha256':report['asset_sha256'],'bytes':report['asset_bytes']}]
        registry_path.write_text(json.dumps(registry,indent=2)+'\n')
        print('CHARACTER_ASSET',json.dumps(report))
        return report
