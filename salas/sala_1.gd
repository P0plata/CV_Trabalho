extends Node3D

var completed_s : bool = false

# --- REFERÊNCIAS ---
var player : CharacterBody3D = null
@export var puzzle_cam : Camera3D
@export var area_lava : Area3D 
@export var ponto_spawn : Node3D # Guardamos a REFERÊNCIA ao objeto, não a posição

# --- VARIÁVEIS DE CONTROLO ---
var modo_puzzle = false
var objeto_selecionado : Node3D = null
# (Removemos a variável pos_respawn_segura, não precisamos dela fixa)

var y_fixo : float = 0.0
var z_fixo : float = 0.0
var distancia_cam : float = 0.0

func _enter_tree() -> void:
	if Main.sala1_done == true:
		completed_s = true

func _is_sala(): return true
func _is_completed(): return completed_s
func completed():
	Main.sala1_done = true
	completed_s = true

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player = get_tree().get_first_node_in_group("player")
	
	# Verificação de segurança apenas
	if not ponto_spawn:
		# Tenta encontrar sozinho se esqueceste de arrastar
		ponto_spawn = find_child("Spawnpoint", true, false)
		if ponto_spawn:
			print("Spawnpoint encontrado pelo nome.")
		else:
			print("⚠️ AVISO: Sem Spawnpoint definido! O respawn pode falhar.")

	if area_lava:
		if not area_lava.body_entered.is_connected(_on_lava_touched):
			area_lava.body_entered.connect(_on_lava_touched)

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
		puzzle_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		puzzle_cam.size = 12.0 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if player:
			player.set_process_input(false)
			player.velocity = Vector3.ZERO
	else:
		_largar_objeto()
		var cam_player = player.find_child("Camera3D", true, false)
		if cam_player: cam_player.make_current()
		else:
			var cam_backup = player.get_node_or_null("CameraPivot/Camera3D")
			if cam_backup: cam_backup.make_current()
			
		puzzle_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if player: player.set_process_input(true)

# --- CORREÇÃO AQUI NA LÓGICA DE MORTE ---
func _on_lava_touched(body):
	if body.is_in_group("player"):
		print("🔥 LAVA!")
		
		# 1. Pergunta a posição ATUAL do marker (Global)
		var destino = Vector3.ZERO
		
		if ponto_spawn:
			# Pega a posição global AGORA (que já inclui o movimento da sala)
			destino = ponto_spawn.global_position
			print(" -> Teleportando para Marker: ", destino)
		else:
			# Fallback de emergência (sobe 2 metros de onde caiu)
			destino = body.global_position + Vector3(0, 2, 0)
			print(" -> Marker não existe! Teleporte de emergência.")

		# 2. Aplica
		body.global_position = destino
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
		if corpo.is_in_group("movel"):
			objeto_selecionado = corpo
			y_fixo = corpo.global_position.y
			z_fixo = corpo.global_position.z
			distancia_cam = from.distance_to(corpo.global_position)

func _largar_objeto():
	objeto_selecionado = null

func _mover_objeto(mouse_pos):
	if !objeto_selecionado: return
	var nova_posicao_rato = puzzle_cam.project_position(mouse_pos, distancia_cam)
	var nova_posicao_final = Vector3(nova_posicao_rato.x, y_fixo, z_fixo)
	var posicao_com_snap = Vector3(snapped(nova_posicao_final.x, 1.0), y_fixo, z_fixo)
	objeto_selecionado.global_position = posicao_com_snap
