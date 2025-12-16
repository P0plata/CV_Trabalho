extends Node3D

# ==========================================
# EXPORTS
# ==========================================
@export_group("Referências da Sala")
@export var subsalas: Array[Node3D]
@export var pistas: Array[MeshInstance3D]
@export var spawn: Node3D
@export var coin: Node3D

@export_group("Ambiente")
@export var world_env: WorldEnvironment

# ==========================================
# VARIÁVEIS INTERNAS
# ==========================================
var porta_correta: Array[int] = []
var sala_atual := 0
var env: Environment
var rodar_ambiente := false # Variável para controlar a rotação na Sala 3

func _ready():
	randomize()
	if coin: coin.visible = false
	
	if world_env:
		env = world_env.environment
		env.adjustment_enabled = true 
		# Reseta rotação inicial
		env.sky_rotation = Vector3.ZERO
	
	_inicializar_puzzle()
	_atualizar_atmosfera()

# ==========================================
# LÓGICA DE ROTAÇÃO (SALA 3)
# ==========================================
func _process(delta):
	# Se a variável estiver ativa, roda o céu
	if rodar_ambiente and env:
		# Roda no eixo Y. O valor 0.2 é a velocidade (aumenta se quiseres mais rápido)
		env.sky_rotation.y += 0.2 * delta

# ==========================================
# LÓGICA DO PUZZLE
# ==========================================
func _inicializar_puzzle():
	porta_correta.clear()
	for i in subsalas.size():
		var portas := _get_portas_da_sala(subsalas[i])
		if portas.is_empty():
			porta_correta.append(-1)
			continue
		var correta = randi() % portas.size()
		porta_correta.append(correta)
		if i < pistas.size():
			_aplicar_shader_pista(i, correta)
		print("Puzzle Sala", i, "→ Porta Correta Index:", correta)

func pode_abrir_porta(porta: Node) -> bool:
	var subsala := porta.get_parent()
	var sala_idx := subsalas.find(subsala)

	if sala_idx == -1: return true 

	var portas := _get_portas_da_sala(subsala)
	var porta_idx := portas.find(porta)

	if sala_idx < sala_atual: return true
	if sala_idx > sala_atual: return false

	if porta_idx == porta_correta[sala_atual]:
		print("✔ SUCESSO")
		sala_atual += 1
		_atualizar_atmosfera() # Muda as luzes/cor
		if sala_atual >= subsalas.size():
			_puzzle_completo()
		return true 
	else:
		print("❌ FALHA")
		_castigo_erro()
		return true 

# ==========================================
# RESETS E FEEDBACK
# ==========================================
func _castigo_erro():
	if env:
		var tween = get_tree().create_tween()
		tween.tween_property(env, "adjustment_saturation", 0.1, 0.1)
		tween.parallel().tween_property(env, "adjustment_brightness", 0.5, 0.1)
		tween.tween_callback(_resetar_player)
		tween.tween_callback(_atualizar_atmosfera)

func _resetar_player():
	var player = get_tree().get_first_node_in_group("player")
	if player and spawn:
		player.global_transform.origin = spawn.global_transform.origin
		player.rotation.y = spawn.rotation.y
	sala_atual = 0 

func _puzzle_completo():
	print("🎉 PUZZLE COMPLETO")
	if coin: 
		coin.visible = true
		if coin.has_node("CollisionShape3D"):
			coin.get_node("CollisionShape3D").set_deferred("disabled", false)

func _aplicar_shader_pista(sala_idx: int, porta_idx: int):
	var mesh_pista = pistas[sala_idx]
	var mat = mesh_pista.get_active_material(0) 
	if mat:
		mat.set_shader_parameter("zona_correta", porta_idx)
		mat.set_shader_parameter("modo", sala_idx)

# ==========================================
# CONTROLO VISUAL (CORRIGIDO)
# ==========================================
func _atualizar_atmosfera():
	if not env: return
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	match sala_atual:
		0: 
			# --- INÍCIO (Limpo) ---
			rodar_ambiente = false
			tween.tween_property(env, "adjustment_brightness", 1.0, 1.0)
			tween.tween_property(env, "adjustment_contrast", 1.1, 1.0) # Ligeiro contraste extra
			tween.tween_property(env, "adjustment_saturation", 1.0, 1.0)
			tween.tween_property(env, "glow_intensity", 0.2, 1.0)
			
		1: 
			# --- SALA 2 (Tensão) ---
			rodar_ambiente = false
			
			# Aumenta ligeiramente o brilho para compensar o contraste
			tween.tween_property(env, "adjustment_brightness", 0.9, 1.0) # <--- Tenta 0.9 ou 1.0 aqui
			
			# Mantém o contraste alto para o look de filme
			tween.tween_property(env, "adjustment_contrast", 1.2, 1.0)   # <--- Baixa um pouco de 1.4/1.5 para 1.3
			
			tween.tween_property(env, "adjustment_saturation", 0.8, 1.0)
			tween.tween_property(env, "glow_intensity", 0.5, 1.0)
		2: 
			# --- SALA 3 (Maluco/Psicadélico + Rotação) ---
			rodar_ambiente = true 
			
			# Visual agressivo mas legível
			tween.tween_property(env, "adjustment_brightness", 1.0, 2.0)
			tween.tween_property(env, "adjustment_contrast", 1.5, 2.0)
			tween.tween_property(env, "adjustment_saturation", 2.0, 2.0) # Cores muito fortes
			tween.tween_property(env, "glow_intensity", 1.5, 2.0)
			
		_: 
			# --- FINAL (Vitória Celestial) ---
			rodar_ambiente = false
			tween.tween_property(env, "adjustment_brightness", 1.3, 3.0)
			tween.tween_property(env, "adjustment_contrast", 1.0, 3.0)
			tween.tween_property(env, "adjustment_saturation", 1.2, 3.0)
# ==========================================
# UTILITÁRIOS
# ==========================================
func _get_portas_da_sala(sala: Node) -> Array:
	var portas_encontradas := []
	for child in sala.get_children():
		if child.is_in_group("porta_puzzle"):
			portas_encontradas.append(child)
	return portas_encontradas
