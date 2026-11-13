extends CanvasLayer

## HUD minimalista: muestra solo el temporizador en pantalla
## y reporta la vida de ambos luchadores por la consola.

@export var personaje: Node

@onready var estado_centro: Label = $PanelSuperior/EstadoCentro

var _p1: Node = null
var _p2: Node = null
var _salud_p1: Node = null
var _salud_p2: Node = null
var _partida: Node = null


func _ready() -> void:
	call_deferred("_conectar_luchadores")


func _conectar_luchadores() -> void:
	_p1 = personaje if is_instance_valid(personaje) else get_tree().get_first_node_in_group("jugador")
	_p2 = get_tree().get_first_node_in_group("rival")
	_partida = get_parent().get_node_or_null("Partida") if get_parent() else null

	if _p1:
		_salud_p1 = _p1.get_node_or_null("Salud")
		if _salud_p1 and _salud_p1.has_signal("cambio"):
			_salud_p1.connect("cambio", Callable(self, "_al_cambiar_vida"))
	if _p2:
		_salud_p2 = _p2.get_node_or_null("Salud")
		if _salud_p2 and _salud_p2.has_signal("cambio"):
			_salud_p2.connect("cambio", Callable(self, "_al_cambiar_vida"))

	_imprimir_vidas_consola()
	_actualizar_tiempo()


func _process(_delta: float) -> void:
	_actualizar_tiempo()


func _al_cambiar_vida(_nueva_vida: int) -> void:
	_imprimir_vidas_consola()


func _imprimir_vidas_consola() -> void:
	var v1: int = int(_salud_p1.get("vida")) if _salud_p1 else 0
	var v2: int = int(_salud_p2.get("vida")) if _salud_p2 else 0
	print("Vida -> Jugador 1: %d | Jugador 2: %d" % [v1, v2])


func _actualizar_tiempo() -> void:
	if estado_centro == null:
		return
	if _partida and _partida.get("tiempo") != null:
		estado_centro.text = "%d" % maxi(0, ceili(float(_partida.get("tiempo"))))
