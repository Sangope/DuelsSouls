extends Node

enum Estado { LISTA, ACTIVA, RECARGA }

@export var tecla = "pocion"
@export var duracion = 0.8
@export var recarga = 1.2
@export var curacion = 30
@onready var pj = get_parent()

var estado = Estado.LISTA
var tiempo = 0.0
var pociones = 2


func _physics_process(delta):
	tiempo -= delta
	match estado:
		Estado.LISTA:
			if Input.is_action_just_pressed(tecla) and puede():
				empezar()
		Estado.ACTIVA:
			if tiempo <= 0.001:   # 0.001 y no 0: restar 1/60 no da exacto
				terminar()
		Estado.RECARGA:
			if tiempo <= 0.001:
				estado = Estado.LISTA


func puede():
	return pociones > 0


func empezar():
	estado = Estado.ACTIVA
	tiempo = duracion
	pociones -= 1
	pj.empuje = Vector3.ZERO
	pj.multiplicador = 0.0
	pj.accion = "pick-up"
	var salud = pj.get_node_or_null("Salud")
	if salud != null and salud.has_method("curar"):
		salud.curar(curacion)
	print("empieza: ", tecla)
	print("+", curacion, " de vida, quedan ", pociones)


func terminar():
	estado = Estado.RECARGA
	tiempo = recarga
	pj.empuje = Vector3.ZERO
	pj.multiplicador = 1.0
	pj.accion = ""
	print("termina: ", tecla)
