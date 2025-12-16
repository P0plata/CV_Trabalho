extends Node3D

var completed_s : bool = false;

# --- REFERÊNCIAS ---
var player : CharacterBody3D = null
@export var puzzle_cam : Camera3D

# --- VARIÁVEIS DE CONTROLO ---
var modo_puzzle = false
var objeto_selecionado : Node3D = null
var spawn_pos : Vector3 = Vector3.ZERO # <--- Onde o jogador vai renascer

# Variáveis para travar a posição
var y_fixo : float = 0.0
var z_fixo : float = 0.0
var distancia_cam : float = 0.0

func _enter_tree() -> void:
	if Main.sala1_done == true:
		completed_s = true

func _is_sala():
	return true

func _is_completed():
	return completed_s
	
func completed():
	Main.sala1_done = true
	completed_s = true

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		print("ERRO CRÍTICO: Não encontrei o Player! Verifica se ele está no grupo 'player'.")
	else:
		# Guarda a posição inicial do jogador como ponto de respawn
		spawn_pos = player.global_position
	

func _input(event):
	if event.is_action_pressed("toggle_projection"):
		_alternar_modo()
	
	if modo_puzzle:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					_tentar_pegar_objeto(event.position)
				else:
					_largar_objeto()
		
		elif event is InputEventMouseMotion and objeto_selecionado:
			_mover_objeto(event.position)

func _alternar_modo():
	modo_puzzle = !modo_puzzle
	
	if modo_puzzle:
		puzzle_cam.make_current()
		# Força o modo ortogonal e define o tamanho (ZOOM)
		puzzle_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		puzzle_cam.size = 12.0 # Ajusta este valor se a sala parecer muito perto ou longe
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.set_process_input(false)
	else:
		_largar_objeto()
		# Tenta encontrar a câmara do player onde quer que ela esteja
		var cam_player = player.find_child("Camera3D", true, false)
		if cam_player:
			cam_player.make_current()
		else:
			# Fallback para o caminho que tinhas antes
			player.get_node("CameraPivot/Camera3D").make_current()
			
		puzzle_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.set_process_input(true)

# --- FUNÇÃO NOVA: QUANDO TOCA NA LAVA ---
func _on_lava_touched(body):
	# Só reseta se for o jogador
	if body.is_in_group("player"):
		print("O jogador caiu na lava! Resetando...")
		
		# Teleporta para o início
		body.completed = spawn_pos
		
		# Para qualquer movimento de queda (zera a velocidade)
		body.velocity = Vector3.ZERO

# --- FÍSICA E MOVIMENTO ---

func _tentar_pegar_objeto(mouse_pos):
	var from = puzzle_cam.project_ray_origin(mouse_pos)
	var dir = puzzle_cam.project_ray_normal(mouse_pos)
	var to = from + dir * 1000.0
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)
	
	if result:
		var corpo = result.collider
		# Debug e Lógica juntos
		print("Cliquei em: ", corpo.name)
		
		if corpo.is_in_group("movel"):
			print("✅ A agarrar objeto móvel...")
			objeto_selecionado = corpo
			
			# GUARDA A POSIÇÃO ORIGINAL Y E Z
			y_fixo = corpo.global_position.y
			z_fixo = corpo.global_position.z
			
			distancia_cam = from.distance_to(corpo.global_position)
		else:
			print("❌ Objeto não está no grupo 'movel'.")

func _largar_objeto():
	objeto_selecionado = null

func _mover_objeto(mouse_pos):
	if !objeto_selecionado: return
	
	var nova_posicao_rato = puzzle_cam.project_position(mouse_pos, distancia_cam)
	
	# Trava nos eixos Y e Z originais, move apenas no X
	var nova_posicao_final = Vector3(nova_posicao_rato.x, y_fixo, z_fixo)
	
	# Snap opcional (remove o 'snapped' se quiseres movimento fluido)
	var posicao_com_snap = Vector3(snapped(nova_posicao_final.x, 1.0), y_fixo, z_fixo)
	
	objeto_selecionado.global_position = posicao_com_snap
