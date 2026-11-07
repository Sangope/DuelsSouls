class_name CicloDia
extends Node

const NARANJA := Color(1.0, 0.12, 0.14)   # el color bajo de su paleta

@export var hora := 7.0              # h, al empezar
@export var duracion_dia := 48.0     # s reales que dura un día de 24 h
@export var pausado := true


func avanzar(dt: float) -> void:
	if not pausado:
		hora = fposmod(hora + 24.0 * dt / duracion_dia, 24.0)   # horas de juego en dt segundos


static func elevacion(h: float) -> float:
	return (h - 6.0) * 15.0             # 6 h -> 0°, 12 h -> 90°, 18 h -> 180°


static func factor_sol(h: float) -> float:
	return maxf(0.0, sin(deg_to_rad(elevacion(h))))   # el seno de la elevación (¡en radianes!)


static func color_sol(h: float) -> Color:
	return NARANJA.lerp(Color.WHITE, factor_sol(h))
