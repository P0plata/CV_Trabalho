extends Node3D

var completed_s : bool = false

# --- REFERÊNCIAS ---
var player : CharacterBody3D = null

@export var puzzle_cam : Camera3D
@export var spawn_point : Node3D   # 👈 SpawnPoint da sala

# --- VARIÁVEIS DE CONTROLO ---
var modo_puzzle : bool = false
var objeto_selecionado : Node3D = null

# Variáveis para travar a posição do objeto
var y_fixo : float = 0.0
var z_fixo : float = 0.0
var distancia_cam : float = 0.0


# ------------------------------------------------------------------
# CICLO DE VIDA
# ------------------------------------------------------------------

func _enter_tree() -> void:
	if Main.sala1_done:
		completed_s = true


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_error("ERRO CRÍTICO: Não encontrei o Player! Verifica se está no grupo 'player'.")
	

# ------------------------------------------------------------------
# INTERFACE COM O SISTEMA DE SALAS
# ------------------------------------------------------------------

func _is_sala() -> bool:
	return true


func _is_completed() -> bool:
	return completed_s


func completed() -> void:
	Main.sala1_done = true
	completed_s = true


# ------------------------------------------------------------------
# INPUT
# ------------------------------------------------------------------

func _input(event) -> void:
	if event.is_action_pressed("toggle_projection"):
		_alternar_modo()
	
	if not modo_puzzle:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_tentar_pegar_objeto(event.position)
			else:
				_largar_objeto()
	
	elif event is InputEventMouseMotion and objeto_selecionado:
		_mover_objeto(event.position)


# ------------------------------------------------------------------
# MODO PUZZLE / CÂMARAS
# ------------------------------------------------------------------

func _alternar_modo() -> void:
	modo_puzzle = !modo_puzzle
	
	if modo_puzzle:
		puzzle_cam.make_current()
		puzzle_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		puzzle_cam.size = 12.0
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.set_process_input(false)
	else:
		_largar_objeto()
		
		var cam_player = player.find_child("Camera3D", true, false)
		if cam_player:
			cam_player.make_current()
		else:
			player.get_node("CameraPivot/Camera3D").make_current()
		
		puzzle_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.set_process_input(true)


# ------------------------------------------------------------------
# RESPAWN / LAVA
# ------------------------------------------------------------------

func _on_lava_touched(body) -> void:
	if body.is_in_group("player"):
		print("🔥 Jogador caiu na lava! Respawn...")
		
		body.global_position = spawn_point.global_position
		body.velocity = Vector3.ZERO
		body.move_and_slide()


# ------------------------------------------------------------------
# INTERAÇÃO COM OBJETOS
# ------------------------------------------------------------------

func _tentar_pegar_objeto(mouse_pos: Vector2) -> void:
	var from = puzzle_cam.project_ray_origin(mouse_pos)
	var dir = puzzle_cam.project_ray_normal(mouse_pos)
	var to = from + dir * 1000.0
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)
	
	if result:
		var corpo = result.collider
		print("Cliquei em:", corpo.name)
		
		if corpo.is_in_group("movel"):
			print("✅ A agarrar objeto móvel")
			objeto_selecionado = corpo
			
			y_fixo = corpo.global_position.y
			z_fixo = corpo.global_position.z
			distancia_cam = from.distance_to(corpo.global_position)
		else:
			print("❌ Objeto não pertence ao grupo 'movel'")


func _largar_objeto() -> void:
	objeto_selecionado = null


func _mover_objeto(mouse_pos: Vector2) -> void:
	if not objeto_selecionado:
		return
	
	var nova_pos_rato = puzzle_cam.project_position(mouse_pos, distancia_cam)
	var nova_pos_final = Vector3(nova_pos_rato.x, y_fixo, z_fixo)
	
	# Snap opcional (remove se quiseres fluidez total)
	nova_pos_final.x = snapped(nova_pos_final.x, 1.0)
	
	objeto_selecionado.global_position = nova_pos_final
