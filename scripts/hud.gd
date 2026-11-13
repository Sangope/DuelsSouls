extends CanvasLayer

## HUD de combate 1v1: muestra barras de vida y pociones de J1 (Paladin) y J2 (Vampiro),
## el temporizador/resultado de la partida y una guia compacta de controles.

@export var personaje: Node

@onready var barra_p1: ProgressBar = $PanelSuperior/Contenedor/ColumnaP1/BarraP1
@onready var info_p1: Label = $PanelSuperior/Contenedor/ColumnaP1/InfoP1
@onready var barra_p2: ProgressBar = $PanelSuperior/Contenedor/ColumnaP2/BarraP2
@onready var info_p2: Label = $PanelSuperior/Contenedor/ColumnaP2/InfoP2
@onready var estado_centro: Label = $PanelSuperior/Contenedor/EstadoCentro

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
			_salud_p1.connect("cambio", Callable(self, "_actualizar_p1"))
	if _p2:
		_salud_p2 = _p2.get_node_or_null("Salud")
		if _salud_p2 and _salud_p2.has_signal("cambio"):
			_salud_p2.connect("cambio", Callable(self, "_actualizar_p2"))

	_refrescar_todo()


func _process(_delta: float) -> void:
	_refrescar_todo()


func _refrescar_todo() -> void:
	if _salud_p1:
		_actualizar_p1(int(_salud_p1.get("vida")))
	if _salud_p2:
		_actualizar_p2(int(_salud_p2.get("vida")))
	_actualizar_centro()


func _actualizar_p1(vida: int) -> void:
	if barra_p1:
		barra_p1.value = vida
	if info_p1:
		var poc: Variant = _obtener_pociones(_p1)
		info_p1.text = "J1 Paladín  %d HP · Poc: %d" % [vida, poc]
	_actualizar_centro()


func _actualizar_p2(vida: int) -> void:
	if barra_p2:
		barra_p2.value = vida
	if info_p2:
		var poc: Variant = _obtener_pociones(_p2)
		info_p2.text = "J2 Vampiro  %d HP · Poc: %d" % [vida, poc]
	_actualizar_centro()


func _obtener_pociones(luchador: Node) -> int:
	if luchador == null:
		return 0
	var poc: Node = luchador.get_node_or_null("Pocion")
	return int(poc.get("pociones")) if poc else 0


func _actualizar_centro() -> void:
	if estado_centro == null:
		return
	var v1: int = int(_salud_p1.get("vida")) if _salud_p1 else 100
	var v2: int = int(_salud_p2.get("vida")) if _salud_p2 else 100
	if v1 <= 0 and v2 <= 0:
		estado_centro.text = "EMPATE"
	elif v2 <= 0:
		estado_centro.text = "¡GANÓ PALADÍN!"
	elif v1 <= 0:
		estado_centro.text = "¡GANÓ VAMPIRO!"
	elif _partida and _partida.get("tiempo") != null:
		estado_centro.text = "%d" % maxi(0, ceili(float(_partida.get("tiempo"))))
	else:
		estado_centro.text = "VS"
