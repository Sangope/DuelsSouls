class_name EfectoSangre
extends Node3D

## Efectos visuales 3D de combate:
## - Impacto de sangre con degradado suave y mancha en el piso.
## - Bloqueo de escudo con chispas metalicas suaves (aditivas) y onda de choque.
## - Ruptura de Guardia (Guard Break) con onda expansiva natural y brasas luminosas.

static var _tex_chispa_suave: ImageTexture = null
static var _tex_onda_suave: ImageTexture = null
static var _curva_escala: Curve = null

var _tiempo: float = 0.0
var _duracion_total: float = 3.2
var _destello: Sprite3D = null
var _onda: Sprite3D = null
var _charco: Sprite3D = null
var _luz: OmniLight3D = null
var _energia_luz_inicial: float = 1.8
var _duracion_onda: float = 0.22
var _escala_onda_fin: float = 1.65


static func _obtener_textura_chispa_suave() -> ImageTexture:
	if _tex_chispa_suave != null:
		return _tex_chispa_suave
	var tam := 64
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	var centro := Vector2(tam * 0.5, tam * 0.5)
	var radio := tam * 0.5
	for y in range(tam):
		for x in range(tam):
			var d: float = Vector2(x, y).distance_to(centro) / radio
			if d >= 1.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
			else:
				# Caida radial gaussiana suave sin bordes cuadrados
				var nucleo: float = exp(-d * d * 5.2)
				var halo: float = pow(1.0 - d, 2.4) * 0.65
				var alpha: float = clampf(nucleo + halo, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_tex_chispa_suave = ImageTexture.create_from_image(img)
	return _tex_chispa_suave


static func _obtener_textura_onda_suave() -> ImageTexture:
	if _tex_onda_suave != null:
		return _tex_onda_suave
	var tam := 96
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	var centro := Vector2(tam * 0.5, tam * 0.5)
	var radio := tam * 0.5
	for y in range(tam):
		for x in range(tam):
			var d: float = Vector2(x, y).distance_to(centro) / radio
			if d >= 1.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
			else:
				# Anillo suave luminoso con centro tenue
				var anillo: float = exp(-pow((d - 0.68) / 0.14, 2.0))
				var centro_suave: float = exp(-d * d * 4.0) * 0.35
				var borde: float = clampf((1.0 - d) * 3.0, 0.0, 1.0)
				var alpha: float = clampf((anillo + centro_suave) * borde, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_tex_onda_suave = ImageTexture.create_from_image(img)
	return _tex_onda_suave


static func _obtener_curva_escala() -> Curve:
	if _curva_escala != null:
		return _curva_escala
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(0.55, 0.72))
	c.add_point(Vector2(1.0, 0.0))
	_curva_escala = c
	return _curva_escala


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

	# 1. Particulas 3D de gotas de sangre que se encogen suavemente al caer
	var particulas := CPUParticles3D.new()
	particulas.name = "ParticulasSangre"
	particulas.amount = 26
	particulas.lifetime = 0.48
	particulas.one_shot = true
	particulas.explosiveness = 0.92

	var mat_part := StandardMaterial3D.new()
	mat_part.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_part.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_part.vertex_color_use_as_albedo = true
	mat_part.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_part.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat_part.albedo_texture = tex_gota
	mat_part.albedo_color = Color(0.88, 0.05, 0.09, 0.95)

	var quad := QuadMesh.new()
	quad.material = mat_part
	quad.size = Vector2(0.14, 0.14)
	particulas.mesh = quad

	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = 0.12
	particulas.direction = Vector3(dir_empuje, 0.55, 0.16).normalized()
	particulas.spread = 38.0
	particulas.gravity = Vector3(0.0, -13.5, 0.0)
	particulas.initial_velocity_min = 1.9
	particulas.initial_velocity_max = 4.3
	particulas.scale_amount_min = 0.65
	particulas.scale_amount_max = 1.25
	particulas.scale_amount_curve = _obtener_curva_escala()
	particulas.color = Color(0.86, 0.04, 0.08, 1.0)
	nodo.add_child(particulas)
	particulas.emitting = true

	# 2. Destello de salpicadura en el punto del golpe
	var destello := Sprite3D.new()
	destello.name = "DestelloSangre"
	destello.texture = tex_charco
	destello.pixel_size = 0.0105
	destello.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	destello.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	destello.no_depth_test = true
	destello.modulate = Color(0.92, 0.06, 0.10, 0.9)
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
	nodo._energia_luz_inicial = 1.8

	# 4. Mancha de sangre sobre los ladrillos del suelo
	var charco := Sprite3D.new()
	charco.name = "CharcoSuelo"
	charco.texture = tex_charco
	charco.pixel_size = 0.010
	charco.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	charco.modulate = Color(0.58, 0.03, 0.05, 0.85)
	nodo.add_child(charco)
	charco.global_position = Vector3(
		posicion_impacto.x + dir_empuje * 0.24,
		suelo_y + 0.015,
		0.12
	)
	charco.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	nodo._charco = charco

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
	nodo._duracion_total = 0.42
	nodo._duracion_onda = 0.18
	nodo._escala_onda_fin = 1.25
	escena_padre.add_child(nodo)
	nodo.global_position = posicion_impacto

	# 1. Chispas metalicas suaves con brillo aditivo y textura radial difuminada
	var particulas := CPUParticles3D.new()
	particulas.name = "ChispasBloqueo"
	particulas.amount = 18
	particulas.lifetime = 0.25
	particulas.one_shot = true
	particulas.explosiveness = 0.94

	var mat_chispa := StandardMaterial3D.new()
	mat_chispa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_chispa.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat_chispa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_chispa.vertex_color_use_as_albedo = true
	mat_chispa.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_chispa.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat_chispa.albedo_texture = _obtener_textura_chispa_suave()
	mat_chispa.albedo_color = Color(1.0, 0.88, 0.55, 0.92)

	var quad := QuadMesh.new()
	quad.material = mat_chispa
	quad.size = Vector2(0.055, 0.055)
	particulas.mesh = quad
	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = 0.06
	particulas.direction = Vector3(-dir_empuje, 0.42, 0.22).normalized()
	particulas.spread = 48.0
	particulas.gravity = Vector3(0.0, -8.5, 0.0)
	particulas.initial_velocity_min = 1.8
	particulas.initial_velocity_max = 3.6
	particulas.scale_amount_min = 0.6
	particulas.scale_amount_max = 1.25
	particulas.scale_amount_curve = _obtener_curva_escala()

	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.96, 0.78, 1.0))
	grad.set_color(1, Color(1.0, 0.55, 0.15, 0.0))
	particulas.color_ramp = grad
	nodo.add_child(particulas)
	particulas.emitting = true

	# 2. Onda suave de impacto en el escudo
	var onda := Sprite3D.new()
	onda.name = "OndaEscudo"
	onda.texture = _obtener_textura_onda_suave()
	onda.pixel_size = 0.0065
	onda.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	onda.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	onda.no_depth_test = true
	onda.modulate = Color(1.0, 0.88, 0.58, 0.75)
	onda.position = Vector3(0.0, 0.0, 0.15)
	nodo.add_child(onda)
	nodo._onda = onda

	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.85, 0.5, 1.0)
	luz.light_energy = 1.35
	luz.omni_range = 1.8
	nodo.add_child(luz)
	nodo._luz = luz
	nodo._energia_luz_inicial = 1.35

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
	nodo._duracion_onda = 0.28
	nodo._escala_onda_fin = 2.1
	escena_padre.add_child(nodo)
	nodo.global_position = posicion_impacto

	# 1. Brasas luminosas suaves que se desvanecen naturalmente (sin cuadrados pixelados)
	var particulas := CPUParticles3D.new()
	particulas.name = "FragmentosEscudo"
	particulas.amount = 28
	particulas.lifetime = 0.42
	particulas.one_shot = true
	particulas.explosiveness = 0.95

	var mat_frag := StandardMaterial3D.new()
	mat_frag.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_frag.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat_frag.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_frag.vertex_color_use_as_albedo = true
	mat_frag.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_frag.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat_frag.albedo_texture = _obtener_textura_chispa_suave()
	mat_frag.albedo_color = Color(1.0, 0.78, 0.42, 0.95)

	var quad := QuadMesh.new()
	quad.material = mat_frag
	quad.size = Vector2(0.075, 0.075)
	particulas.mesh = quad
	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = 0.14
	particulas.direction = Vector3(dir_empuje, 0.48, 0.22).normalized()
	particulas.spread = 68.0
	particulas.gravity = Vector3(0.0, -7.5, 0.0)
	particulas.initial_velocity_min = 2.0
	particulas.initial_velocity_max = 4.4
	particulas.scale_amount_min = 0.65
	particulas.scale_amount_max = 1.4
	particulas.scale_amount_curve = _obtener_curva_escala()

	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.94, 0.72, 1.0))
	grad.set_color(1, Color(0.95, 0.32, 0.14, 0.0))
	particulas.color_ramp = grad
	nodo.add_child(particulas)
	particulas.emitting = true

	# 2. Onda de choque circular suave al romperse la guardia
	var onda := Sprite3D.new()
	onda.name = "OndaRuptura"
	onda.texture = _obtener_textura_onda_suave()
	onda.pixel_size = 0.0085
	onda.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	onda.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	onda.no_depth_test = true
	onda.modulate = Color(1.0, 0.72, 0.36, 0.85)
	onda.position = Vector3(0.0, 0.0, 0.16)
	nodo.add_child(onda)
	nodo._onda = onda

	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.68, 0.32, 1.0)
	luz.light_energy = 2.2
	luz.omni_range = 2.6
	nodo.add_child(luz)
	nodo._luz = luz
	nodo._energia_luz_inicial = 2.2

	var cam := escena_padre.get_node_or_null("Camera3D")
	if cam and cam.has_method("sacudir"):
		cam.call("sacudir", 0.11, 0.20)

	return nodo


func _process(delta: float) -> void:
	_tiempo += delta
	if _destello:
		if _tiempo < 0.18:
			var t := _tiempo / 0.18
			var escala := lerpf(0.75, 1.45, t)
			_destello.scale = Vector3(escala, escala, 1.0)
			_destello.modulate.a = lerpf(0.9, 0.0, t)
		else:
			_destello.visible = false
	if _onda:
		if _tiempo < _duracion_onda:
			var t_o := _tiempo / _duracion_onda
			var esc_o := lerpf(0.45, _escala_onda_fin, 1.0 - pow(1.0 - t_o, 2.0))
			_onda.scale = Vector3(esc_o, esc_o, 1.0)
			_onda.modulate.a = lerpf(0.85, 0.0, t_o)
		else:
			_onda.visible = false
	if _luz:
		if _tiempo < 0.18:
			_luz.light_energy = lerpf(_energia_luz_inicial, 0.0, _tiempo / 0.18)
		else:
			_luz.visible = false
	if _charco and _tiempo > 1.8:
		var t_c := clampf((_tiempo - 1.8) / maxf(0.1, _duracion_total - 1.8), 0.0, 1.0)
		_charco.modulate.a = lerpf(0.85, 0.0, t_c)
	if _tiempo >= _duracion_total:
		queue_free()
