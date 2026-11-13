extends Node

signal cambio(vida)
signal sin_vida

@export var vida = 100
@export var invulnerable = 0.5
@export var reapariciones = 0
@export var espera_reaparecer = 2.0

var reloj = 0.0
var vida_inicial = 0
var punto = Vector3.ZERO
@onready var pj = get_parent()


func _ready():
	sin_vida.connect(_al_quedar_sin_vida)
	vida_inicial = vida
	punto = pj.global_position


func _physics_process(delta):
	reloj = maxf(reloj - delta, 0.0)


func puede_recibir_golpe() -> bool:
	return reloj <= 0.001 and vida > 0


func recibir_golpe(danio):
	if not puede_recibir_golpe():
		return
	vida = maxi(vida - danio, 0)
	reloj = invulnerable
	cambio.emit(vida)
	if vida == 0:
		sin_vida.emit()


func curar(cuanto):
	if vida == 0:
		return
	vida = mini(vida + cuanto, vida_inicial)
	cambio.emit(vida)


# Se busca aquí y no en _ready(): la Partida quizá todavía no existía.
func _al_quedar_sin_vida():
	var jid: Variant = pj.get("jugador_id") if pj else 1
	var etiqueta := "Jugador %d" % jid if typeof(jid) == TYPE_INT else str(pj.name)
	if reapariciones > 0:
		reapariciones -= 1
		vida = vida_inicial
		pj.global_position = punto
		reloj = espera_reaparecer
		cambio.emit(vida)
		print("%s reaparece" % etiqueta)
		return
	print("%s quedó sin vida (KO)" % etiqueta)
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		var ganador_id: int = 1 if (pj != null and pj.is_in_group("rival")) else 2
		if partida.has_method("declarar_ganador"):
			partida.declarar_ganador(ganador_id, "por KO")
		elif ganador_id == 1:
			partida.ganar()
		else:
			partida.perder("GANÓ EL JUGADOR 2 (por KO)")
