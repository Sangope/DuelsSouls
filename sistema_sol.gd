class_name SistemaSol
extends Node

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol := 1.2
@export var azimut := -65.0        # grados en Y: hacia dónde caen las sombras
@export var ambiente_dia := 0.15
@export var ambiente_noche := 0.03

@onready var ciclo: CicloDia = $CicloDia


func _ready() -> void:
	aplicar_hora()


func _process(delta: float) -> void:
	ciclo.avanzar(delta)
	aplicar_hora()


func aplicar_hora() -> void:
	var h := ciclo.hora
	var f := CicloDia.factor_sol(h)
	sol.rotation_degrees = Vector3(-CicloDia.elevacion(h), azimut, 0.0)
	sol.light_energy = energia_sol * f
	sol.light_color = CicloDia.color_sol(h)
	entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)
