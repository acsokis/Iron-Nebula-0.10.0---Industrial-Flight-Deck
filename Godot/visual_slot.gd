class_name NebulaVisualSlot
extends Node3D

const INDUSTRIAL_HULL_SHADER = preload("res://Godot/industrial_hull.gdshader")
var metallic_frame: MeshInstance3D
var frame_material: ShaderMaterial

## Replace artwork with an imported .glb/.gltf scene without changing the body,
## collision, flight plane or weapon mounts owned by its parent.
func configure(art: Texture2D, dimensions: Vector2, model: PackedScene = null, mirror: bool = false, metallic_frame: bool = false) -> void:
	for child in get_children():
		child.queue_free()
	self.metallic_frame = null
	if model != null:
		add_child(model.instantiate())
		return
	if metallic_frame:
		self.metallic_frame = MeshInstance3D.new()
		self.metallic_frame.name = "MetallicFrame"
		var frame_mesh := QuadMesh.new()
		frame_mesh.size = dimensions * 1.2
		self.metallic_frame.mesh = frame_mesh
		self.metallic_frame.position.z = -0.09
		self.frame_material = ShaderMaterial.new()
		self.frame_material.shader = INDUSTRIAL_HULL_SHADER
		self.frame_material.set_shader_parameter("hull_mask", art)
		self.frame_material.set_shader_parameter("alloy_color", Color("9fb2bb"))
		self.frame_material.set_shader_parameter("signal_color", Color("45dfff"))
		self.frame_material.set_shader_parameter("damage", 0.0)
		if mirror:
			self.frame_material.set_shader_parameter("mirror_u", true)
		self.metallic_frame.material_override = self.frame_material
		self.metallic_frame.visible = false
		add_child(self.metallic_frame)
	var quad := MeshInstance3D.new()
	quad.name = "HullSprite"
	var mesh := QuadMesh.new()
	mesh.size = dimensions
	quad.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_texture = art
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_texture = art
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.025
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	if mirror:
		material.uv1_scale.x = -1
		material.uv1_offset.x = 1
	quad.material_override = material
	add_child(quad)

func set_damage_fraction(fraction: float) -> void:
	if metallic_frame != null:
		var damage := clampf(1.0 - fraction, 0.0, 1.0)
		metallic_frame.visible = damage > 0.0
		frame_material.set_shader_parameter("damage", damage)
