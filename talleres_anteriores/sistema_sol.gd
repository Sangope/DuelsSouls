class_name SistemaSol
extends Node

signal cambio_noche(es_noche: bool)

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol := 1.2
@export var azimut := -65.0        # grados en Y: hacia dónde caen las sombras
@export var ambiente_dia := 0.15
@export var ambiente_noche := 0.03
@export var luz_reacciona: Light3D

var era_noche := false

@onready var ciclo: CicloDia = $CicloDia


func _ready() -> void:
	aplicar_hora()
	era_noche = CicloDia.factor_sol(ciclo.hora) <= 0.0
	if luz_reacciona != null:
		luz_reacciona.visible = era_noche
		cambio_noche.connect(func(n: bool) -> void: luz_reacciona.visible = n)


func _process(delta: float) -> void:
	ciclo.avanzar(delta)
	aplicar_hora()
	var es_noche := CicloDia.factor_sol(ciclo.hora) <= 0.0
	if es_noche != era_noche:
		era_noche = es_noche
		cambio_noche.emit(es_noche)


func aplicar_hora() -> void:
	var h := ciclo.hora
	var f := CicloDia.factor_sol(h)
	sol.rotation_degrees = Vector3(-CicloDia.elevacion(h), azimut, 0.0)
	sol.light_energy = energia_sol * f
	sol.light_color = CicloDia.color_sol(h)
	entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)


static func lambert(normal: Vector3, hacia_luz: Vector3) -> float:
	var n := Vectores.normalizar(normal)
	var l := Vectores.normalizar(hacia_luz)
	return maxf(0.0, n.dot(l))


func prediccion_piso() -> float:
	var hacia_luz := sol.global_transform.basis.z
	var difusa := lambert(Vector3.UP, hacia_luz)
	return sol.light_energy * sol.light_color.r * difusa
