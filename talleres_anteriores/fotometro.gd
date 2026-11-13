extends Node

@export var sistema: SistemaSol
@export var camara: Camera3D
@export var superficie: MeshInstance3D    # la superficie que se mide
@export var punto := Vector3(-3.2, 0, 2.0)
@export var horas: Array[float] = [7.0, 8.0, 9.0]

var i := 0
var espera := 0


func _ready() -> void:
	var env := sistema.entorno.environment       # modo laboratorio
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var mate := StandardMaterial3D.new()
	mate.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	mate.roughness = 1.0
	mate.metallic_specular = 0.0
	superficie.material_override = mate
	sistema.ciclo.pausado = true
	sistema.ciclo.hora = horas[0]


func _process(_delta: float) -> void:
	espera += 1
	if espera < 10:             # unos frames para que el render se ponga al día
		return
	espera = 0
	var px := camara.unproject_position(punto)
	var imagen := get_viewport().get_texture().get_image()
	var color := imagen.get_pixel(int(px.x), int(px.y))
	print("hora %.1f   medido %.3f   predicho %.3f" % [sistema.ciclo.hora,
		color.srgb_to_linear().r, sistema.prediccion_piso()])
	i += 1
	if i < horas.size():
		sistema.ciclo.hora = horas[i]
	else:
		set_process(false)
