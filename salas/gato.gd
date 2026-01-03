extends Node3D

@export var modelo_high : Node3D
@export var modelo_low : Node3D

var a_rodar : bool = false
var velocidade : float = 0.0

# Ajustes
var velocidade_max : float = 40.0 # Aumentei para rodar mais rápido
var aceleracao : float = 10.0     # Acelera mais depressa
var threshold_lod : float = 10.0  # Troca mais cedo (quando chega a 10)

func _ready():
	# Garante estado inicial
	if modelo_high: modelo_high.visible = false
	if modelo_low: modelo_low.visible = false
	scale = Vector3.ZERO 

func aparecer_magicamente():
	if modelo_high: modelo_high.visible = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BOUNCE)

func _process(delta):
	# 1. Física da velocidade
	if a_rodar:
		velocidade = move_toward(velocidade, velocidade_max, aceleracao * delta)
	else:
		velocidade = move_toward(velocidade, 0.0, 3*aceleracao * delta)
	
	# 2. Rotação (Local)
	rotate_y(velocidade * delta)
	
	# 3. Troca de Modelo (LOD) - Com Debug
	if modelo_high and modelo_low and scale.x > 0.1:
		if velocidade > threshold_lod:
			if modelo_high.visible: # Só troca se ainda não trocou
				print("!!! TROCA PARA LOW POLY (Velocidade: " + str(velocidade) + ")")
				modelo_high.visible = false
				modelo_low.visible = true
		else:
			if modelo_low.visible:
				modelo_high.visible = true
				modelo_low.visible = false
