class_name EfectoSangre
extends Node3D

## Efecto visual 3D de impacto de golpe y salpicadura de sangre pixel-art.
## Crea particulas de sangre, un destello de salpicadura en el torso, una mancha
## temporal en el piso de ladrillos y sacudida corta de camara.

var _tiempo: float = 0.0
var _duracion_total: float = 3.2
var _destello: Sprite3D = null
var _charco: Sprite3D = null
var _luz: OmniLight3D = null


static func crear_impacto_sangre(
	escena_padre: Node,
	posicion_impacto: Vector3,
	dir_empuje: float,
	suelo_y: float = 0.0
) -> Node3D:
	if escena_padre == null:
		return null

	var nodo := EfectoSangre.new()
	nodo.name = "EfectoSangreImpacto"
	escena_padre.add_child(nodo)
	nodo.global_position = posicion_impacto

	var tex_gota: Texture2D = load("res://escenario/sangre_gota.png")
	var tex_charco: Texture2D = load("res://escenario/sangre_charco.png")

	# 1. Particulas 3D de gotas de sangre saliendo disparadas por el golpe
	var particulas := CPUParticles3D.new()
	particulas.name = "ParticulasSangre"
	particulas.amount = 28
	particulas.lifetime = 0.52
	particulas.one_shot = true
	particulas.explosiveness = 0.92

	var mat_part := StandardMaterial3D.new()
	mat_part.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_part.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_part.vertex_color_use_as_albedo = true
	mat_part.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_part.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat_part.albedo_texture = tex_gota
	mat_part.albedo_color = Color(0.92, 0.06, 0.10, 0.98)

	var quad := QuadMesh.new()
	quad.material = mat_part
	quad.size = Vector2(0.18, 0.18)
	particulas.mesh = quad

	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = 0.14
	particulas.direction = Vector3(dir_empuje, 0.58, 0.18).normalized()
	particulas.spread = 42.0
	particulas.gravity = Vector3(0.0, -13.5, 0.0)
	particulas.initial_velocity_min = 2.0
	particulas.initial_velocity_max = 4.6
	particulas.scale_amount_min = 0.75
	particulas.scale_amount_max = 1.45
	particulas.color = Color(0.88, 0.05, 0.09, 1.0)
	nodo.add_child(particulas)
	particulas.emitting = true

	# 2. Destello de salpicadura inmediata en el punto del golpe
	var destello := Sprite3D.new()
	destello.name = "DestelloSangre"
	destello.texture = tex_charco
	destello.pixel_size = 0.0115
	destello.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	destello.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	destello.no_depth_test = true
	destello.modulate = Color(0.96, 0.08, 0.12, 0.95)
	destello.position = Vector3(0.0, 0.0, 0.18)
	nodo.add_child(destello)
	nodo._destello = destello

	# 3. Luz roja breve de impacto
	var luz := OmniLight3D.new()
	luz.light_color = Color(0.95, 0.1, 0.14, 1.0)
	luz.light_energy = 1.8
	luz.omni_range = 2.2
	nodo.add_child(luz)
	nodo._luz = luz

	# 4. Mancha de sangre sobre los ladrillos del suelo
	var charco := Sprite3D.new()
	charco.name = "CharcoSuelo"
	charco.texture = tex_charco
	charco.pixel_size = 0.0105
	charco.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	charco.modulate = Color(0.62, 0.03, 0.06, 0.88)
	nodo.add_child(charco)
	charco.global_position = Vector3(
		posicion_impacto.x + dir_empuje * 0.24,
		suelo_y + 0.015,
		0.12
	)
	charco.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	nodo._charco = charco

	# 5. Sacudida breve de camara tipo Mortal Kombat
	var cam := escena_padre.get_node_or_null("Camera3D")
	if cam and cam.has_method("sacudir"):
		cam.call("sacudir", 0.075, 0.13)

	return nodo


static func crear_chispa_bloqueo(
	escena_padre: Node,
	posicion_impacto: Vector3,
	dir_empuje: float
) -> Node3D:
	if escena_padre == null:
		return null

	var nodo := EfectoSangre.new()
	nodo.name = "EfectoBloqueo"
	nodo._duracion_total = 0.45
	escena_padre.add_child(nodo)
	nodo.global_position = posicion_impacto

	var particulas := CPUParticles3D.new()
	particulas.name = "ChispasBloqueo"
	particulas.amount = 16
	particulas.lifetime = 0.26
	particulas.one_shot = true
	particulas.explosiveness = 0.95

	var mat_chispa := StandardMaterial3D.new()
	mat_chispa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_chispa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_chispa.vertex_color_use_as_albedo = true
	mat_chispa.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_chispa.albedo_color = Color(1.0, 0.86, 0.42, 0.95)

	var quad := QuadMesh.new()
	quad.material = mat_chispa
	quad.size = Vector2(0.07, 0.07)
	particulas.mesh = quad
	particulas.direction = Vector3(-dir_empuje, 0.45, 0.25).normalized()
	particulas.spread = 55.0
	particulas.gravity = Vector3(0.0, -9.8, 0.0)
	particulas.initial_velocity_min = 2.2
	particulas.initial_velocity_max = 4.2
	nodo.add_child(particulas)
	particulas.emitting = true

	var cam := escena_padre.get_node_or_null("Camera3D")
	if cam and cam.has_method("sacudir"):
		cam.call("sacudir", 0.035, 0.08)

	return nodo


static func crear_ruptura_escudo(
	escena_padre: Node,
	posicion_impacto: Vector3,
	dir_empuje: float
) -> Node3D:
	if escena_padre == null:
		return null

	var nodo := EfectoSangre.new()
	nodo.name = "EfectoRupturaEscudo"
	nodo._duracion_total = 0.65
	escena_padre.add_child(nodo)
	nodo.global_position = posicion_impacto

	var particulas := CPUParticles3D.new()
	particulas.name = "FragmentosEscudo"
	particulas.amount = 34
	particulas.lifetime = 0.42
	particulas.one_shot = true
	particulas.explosiveness = 0.96

	var mat_frag := StandardMaterial3D.new()
	mat_frag.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_frag.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_frag.vertex_color_use_as_albedo = true
	mat_frag.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_frag.albedo_color = Color(0.35, 0.88, 1.0, 0.98)

	var quad := QuadMesh.new()
	quad.material = mat_frag
	quad.size = Vector2(0.11, 0.11)
	particulas.mesh = quad
	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = 0.18
	particulas.direction = Vector3(dir_empuje, 0.55, 0.25).normalized()
	particulas.spread = 75.0
	particulas.gravity = Vector3(0.0, -11.5, 0.0)
	particulas.initial_velocity_min = 2.8
	particulas.initial_velocity_max = 5.6
	nodo.add_child(particulas)
	particulas.emitting = true

	var luz := OmniLight3D.new()
	luz.light_color = Color(0.35, 0.85, 1.0, 1.0)
	luz.light_energy = 2.6
	luz.omni_range = 2.8
	nodo.add_child(luz)
	nodo._luz = luz

	var cam := escena_padre.get_node_or_null("Camera3D")
	if cam and cam.has_method("sacudir"):
		cam.call("sacudir", 0.12, 0.22)

	return nodo


func _process(delta: float) -> void:
	_tiempo += delta
	if _destello:
		if _tiempo < 0.18:
			var t := _tiempo / 0.18
			var escala := lerpf(0.75, 1.45, t)
			_destello.scale = Vector3(escala, escala, 1.0)
			_destello.modulate.a = lerpf(0.95, 0.0, t)
		else:
			_destello.visible = false
	if _luz:
		if _tiempo < 0.15:
			_luz.light_energy = lerpf(1.8, 0.0, _tiempo / 0.15)
		else:
			_luz.visible = false
	if _charco and _tiempo > 1.8:
		var t_c := clampf((_tiempo - 1.8) / maxf(0.1, _duracion_total - 1.8), 0.0, 1.0)
		_charco.modulate.a = lerpf(0.88, 0.0, t_c)
	if _tiempo >= _duracion_total:
		queue_free()
