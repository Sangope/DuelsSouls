extends CanvasLayer

## HUD de combate 1v1 estilo Mortal Kombat / Blasphemous:
## muestra barras de vida, barras de escudo/guardia (con alerta de Guardia Rota),
## pociones, temporizador/ganador en pantalla y reporta la vida por consola.

@export var personaje: Node

@onready var barra_p1: ProgressBar = $PanelSuperior/Contenedor/ColumnaP1/BarraP1
@onready var barra_escudo_p1: ProgressBar = $PanelSuperior/Contenedor/ColumnaP1/BarraEscudoP1
@onready var info_p1: Label = $PanelSuperior/Contenedor/ColumnaP1/InfoP1
@onready var barra_p2: ProgressBar = $PanelSuperior/Contenedor/ColumnaP2/BarraP2
@onready var barra_escudo_p2: ProgressBar = $PanelSuperior/Contenedor/ColumnaP2/BarraEscudoP2
@onready var info_p2: Label = $PanelSuperior/Contenedor/ColumnaP2/InfoP2
@onready var estado_centro: Label = $PanelSuperior/Contenedor/EstadoCentro

var _p1: Node = null
var _p2: Node = null
var _salud_p1: Node = null
var _salud_p2: Node = null
var _combate_p1: Node = null
var _combate_p2: Node = null
var _partida: Node = null
var _vida_prev_p1: int = 100
var _vida_prev_p2: int = 100
var _flash_p1: float = 0.0
var _flash_p2: float = 0.0


func _ready() -> void:
	call_deferred("_conectar_luchadores")


func _conectar_luchadores() -> void:
	_p1 = personaje if is_instance_valid(personaje) else get_tree().get_first_node_in_group("jugador")
	_p2 = get_tree().get_first_node_in_group("rival")
	_partida = get_parent().get_node_or_null("Partida") if get_parent() else null

	if _p1:
		_salud_p1 = _p1.get_node_or_null("Salud")
		_combate_p1 = _p1.get_node_or_null("Combate")
		if _salud_p1:
			_vida_prev_p1 = int(_salud_p1.get("vida"))
			if _salud_p1.has_signal("cambio"):
				_salud_p1.connect("cambio", Callable(self, "_al_cambiar_vida_p1"))
	if _p2:
		_salud_p2 = _p2.get_node_or_null("Salud")
		_combate_p2 = _p2.get_node_or_null("Combate")
		if _salud_p2:
			_vida_prev_p2 = int(_salud_p2.get("vida"))
			if _salud_p2.has_signal("cambio"):
				_salud_p2.connect("cambio", Callable(self, "_al_cambiar_vida_p2"))

	_imprimir_vidas_consola()
	_refrescar_hud()


func _process(delta: float) -> void:
	if _flash_p1 > 0.0:
		_flash_p1 = maxf(0.0, _flash_p1 - delta)
		if barra_p1:
			barra_p1.modulate = Color(1.0, 0.35, 0.35, 1.0) if _flash_p1 > 0.0 else Color.WHITE
	if _flash_p2 > 0.0:
		_flash_p2 = maxf(0.0, _flash_p2 - delta)
		if barra_p2:
			barra_p2.modulate = Color(1.3, 0.45, 0.45, 1.0) if _flash_p2 > 0.0 else Color.WHITE
	_refrescar_hud()


func _al_cambiar_vida_p1(nueva_vida: int) -> void:
	if nueva_vida < _vida_prev_p1:
		_flash_p1 = 0.22
	_vida_prev_p1 = nueva_vida
	_imprimir_vidas_consola()
	_refrescar_hud()


func _al_cambiar_vida_p2(nueva_vida: int) -> void:
	if nueva_vida < _vida_prev_p2:
		_flash_p2 = 0.22
	_vida_prev_p2 = nueva_vida
	_imprimir_vidas_consola()
	_refrescar_hud()


func _imprimir_vidas_consola() -> void:
	var v1: int = int(_salud_p1.get("vida")) if _salud_p1 else 0
	var v2: int = int(_salud_p2.get("vida")) if _salud_p2 else 0
	print("Vida -> Jugador 1: %d | Jugador 2: %d" % [v1, v2])


func _obtener_pociones(luchador: Node) -> int:
	if luchador == null:
		return 0
	var poc: Node = luchador.get_node_or_null("Pocion")
	return int(poc.get("pociones")) if poc else 0


func _obtener_escudo(combate: Node) -> float:
	if combate == null:
		return 100.0
	var val: Variant = combate.get("escudo")
	return float(val) if val != null else 100.0


func _tiene_guardia_rota(combate: Node) -> bool:
	if combate == null or not combate.has_method("tiene_guardia_rota"):
		return false
	return bool(combate.call("tiene_guardia_rota"))


func _actualizar_color_barra_escudo(barra: ProgressBar, valor: float, rota: bool) -> void:
	if barra == null:
		return
	barra.value = valor
	if rota:
		barra.modulate = Color(1.0, 0.22, 0.22, 1.0)
	elif valor < 35.0:
		barra.modulate = Color(1.0, 0.62, 0.2, 1.0)
	else:
		barra.modulate = Color.WHITE


func _refrescar_hud() -> void:
	var v1: int = int(_salud_p1.get("vida")) if _salud_p1 else 100
	var v2: int = int(_salud_p2.get("vida")) if _salud_p2 else 100
	var e1: float = _obtener_escudo(_combate_p1)
	var e2: float = _obtener_escudo(_combate_p2)
	var rota1: bool = _tiene_guardia_rota(_combate_p1)
	var rota2: bool = _tiene_guardia_rota(_combate_p2)

	if barra_p1:
		barra_p1.value = v1
	_actualizar_color_barra_escudo(barra_escudo_p1, e1, rota1)
	if info_p1:
		var txt_esc1 := "¡GUARDIA ROTA!" if rota1 else ("Escudo: %d%%" % ceili(e1))
		info_p1.text = "J1 PALADÍN  %d HP · %s · Poc: %d" % [v1, txt_esc1, _obtener_pociones(_p1)]

	if barra_p2:
		barra_p2.value = v2
	_actualizar_color_barra_escudo(barra_escudo_p2, e2, rota2)
	if info_p2:
		var txt_esc2 := "¡GUARDIA ROTA!" if rota2 else ("Escudo: %d%%" % ceili(e2))
		info_p2.text = "J2 VAMPIRO  %d HP · %s · Poc: %d" % [v2, txt_esc2, _obtener_pociones(_p2)]

	if estado_centro:
		if v1 <= 0 and v2 <= 0:
			estado_centro.text = "EMPATE"
		elif v2 <= 0:
			estado_centro.text = "¡GANÓ J1!"
		elif v1 <= 0:
			estado_centro.text = "¡GANÓ J2!"
		elif _partida and _partida.get("tiempo") != null:
			estado_centro.text = "%d" % maxi(0, ceili(float(_partida.get("tiempo"))))
		else:
			estado_centro.text = "90"
