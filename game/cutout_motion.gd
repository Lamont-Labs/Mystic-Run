extends MeshInstance3D
## Continuously skinned concept-art cutout, not duplicate/generated run frames.
const SHADER=preload("res://assets/shaders/cutout_motion.gdshader")
var paint:ShaderMaterial
var current:Texture2D
var blend:float=1.0
var gait:float=0.0
var stride_weight:float=0.0
var joint_samples:PackedFloat32Array=PackedFloat32Array()

func configure(kind:String) -> void:
	paint=ShaderMaterial.new()
	paint.shader=SHADER
	paint.set_shader_parameter("character_kind",float(["knight","gargoyle","witch"].find(kind)))
	material_override=paint
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var vertices:=PackedVector3Array()
	var uv:=PackedVector2Array()
	var indices:=PackedInt32Array()
	const COLUMNS=28
	const ROWS=32
	for y in range(ROWS+1):
		for x in range(COLUMNS+1):
			var t:=Vector2(float(x)/COLUMNS,float(y)/ROWS)
			vertices.append(Vector3(t.x-.5,.5-t.y,0))
			uv.append(t)
	for y in range(ROWS):
		for x in range(COLUMNS):
			var a:int=y*(COLUMNS+1)+x
			indices.append_array(PackedInt32Array([a,a+COLUMNS+1,a+1,a+1,a+COLUMNS+1,a+COLUMNS+2]))
	var arrays:Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var surface:=ArrayMesh.new()
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh=surface
	extra_cull_margin=1.0

func _set_texture(texture:Texture2D,previous:bool=false) -> void:
	var source:Texture2D=texture
	var rect:=Vector4(0,0,1,1)
	if texture is AtlasTexture:
		source=texture.atlas
		var size:=Vector2(source.get_width(),source.get_height())
		rect=Vector4(texture.region.position.x/size.x,texture.region.position.y/size.y,texture.region.size.x/size.x,texture.region.size.y/size.y)
	paint.set_shader_parameter("previous_art" if previous else "art",source)
	paint.set_shader_parameter("previous_region" if previous else "region",rect)

func advance(delta:float,actor:Node3D) -> void:
	var texture:Texture2D=actor.concept_sprite.texture
	if current!=texture:
		_set_texture(current if current!=null else texture,true)
		_set_texture(texture)
		blend=0.0 if current!=null and not actor.reduced_motion else 1.0
		current=texture
	blend=minf(1.0,blend+delta/0.10)
	var running:bool=actor.moving and not actor.airborne and not actor.sliding and actor.hurt_left<=0 and actor.attack_time<=0 and actor.power_time<=0 and not actor.defeated and actor.celebration_left<=0
	var target:float=1.0 if running and actor.concept_view=="rear" and not actor.reduced_motion else 0.0
	stride_weight=lerpf(stride_weight,target,1-exp(-delta*18.0))
	gait+=delta*TAU*2.15*clampf(actor.motion.locomotion_rate,.6,1.65)
	paint.set_shader_parameter("phase",gait)
	paint.set_shader_parameter("locomotion",stride_weight)
	paint.set_shader_parameter("action_energy",0.0 if actor.reduced_motion else .35)
	paint.set_shader_parameter("transition",smoothstep(0.0,1.0,blend))
	paint.set_shader_parameter("tint",actor.concept_sprite.modulate)
	position=actor.concept_sprite.position
	scale=Vector3(actor.concept_sprite_height*float(texture.get_width())/texture.get_height(),actor.concept_sprite_height,1.0)*actor.concept_sprite.scale
	rotation.z=actor.concept_sprite.rotation.z
	joint_samples=PackedFloat32Array([sin(gait)*.24*stride_weight,sin(gait+PI)*.24*stride_weight,maxf(0,-sin(gait))*.32*stride_weight])
