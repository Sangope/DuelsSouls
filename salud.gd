extends Node

signal cambio(vida)
signal sin_vida

@export var vida = 100
@export var invulnerable = 0.5
var reloj = 0.0


func _ready():
	sin_vida.connect(_al_quedar_sin_vida)


func _physics_process(delta):
	reloj = maxf(reloj - delta, 0.0)


func recibir_golpe(danio):
	if reloj > 0.001 or vida == 0:
		return
	vida = maxi(vida - danio, 0)
	reloj = invulnerable
	cambio.emit(vida)
	if vida == 0:
		sin_vida.emit()


# Se busca aquí y no en _ready(): la Partida quizá todavía no existía.
func _al_quedar_sin_vida():
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.perder("sin vida")
