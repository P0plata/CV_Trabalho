extends Node3D

# --- REFERÊNCIAS ---
@export var gato_script : Node3D
@export var cine_camera : Camera3D
@export var cam_pivot : Node3D
@export var shader_rect : ColorRect
@export var world_env : WorldEnvironment
@export var trigger : Area3D

# --- CONTROLO ---
var shader_mat : ShaderMaterial
var player_ref : Node3D = null
var sequencia_ativa : bool = false
var fase_camera_rodar : bool = false
var pode_ativar_trigger : bool = false

# Dados originais
var altura_original_gato : float = 0.0
var cor_fundo_original : Color = Color.BLACK 

func _ready():
	shader_mat = shader_rect.material as ShaderMaterial
	trigger.body_entered.connect(_on_trigger_enter)
	
	shader_mat.set_shader_parameter("intensidade", 0.0)
	
	if gato_script:
		altura_original_gato = gato_script.position.y
	if world_env.environment:
		cor_fundo_original = world_env.environment.background_color

	await get_tree().create_timer(1.0).timeout
	pode_ativar_trigger = true

func _process(delta):
	# FASE 3: ROTAÇÃO CONTÍNUA DA CÂMARA
	# Se isto estiver true, o pivot roda, levando a câmara com ele
	if fase_camera_rodar and cam_pivot:
		cam_pivot.rotate_y(0.8 * delta) 

func _on_trigger_enter(body):
	if not pode_ativar_trigger: return
	if body.is_in_group("player") and not sequencia_ativa:
		sequencia_ativa = true
		player_ref = body
		iniciar_show()

func iniciar_show():
	print("--- 1. BLOQUEIO E IDLE ---")
	
	# Parar player
	player_ref.velocity = Vector3.ZERO
	if "anim" in player_ref and player_ref.anim:
		player_ref.anim.play("idle") 
	
	player_ref.set_physics_process(false)
	player_ref.set_process_input(false)
	player_ref.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Rodar player para o gato
	if cam_pivot:
		var alvo = cam_pivot.global_position
		alvo.y = player_ref.global_position.y
		var t_rot = create_tween()
		var nova_transform = player_ref.global_transform.looking_at(alvo, Vector3.UP)
		t_rot.tween_property(player_ref, "global_transform", nova_transform, 1.0)
	
	await get_tree().create_timer(3.0).timeout
	
	print("--- 2. GATO APARECE ---")
	gato_script.aparecer_magicamente()
	await get_tree().create_timer(3.0).timeout 
	
	# --- FASE 1 ---
	print("--- 3. FASE 1: CORES (15s) ---")
	gato_script.a_rodar = true
	shader_mat.set_shader_parameter("modo", 1)
	
	var t1 = create_tween()
	t1.tween_method(set_shader_val, 0.0, 0.8, 10.0)
	
	await get_tree().create_timer(15.0).timeout 
	
	# Pausa
	gato_script.a_rodar = false
	shader_mat.set_shader_parameter("intensidade", 0.0)
	await get_tree().create_timer(4.0).timeout 
	
	# --- FASE 2 ---
	print("--- 4. FASE 2: CINE CAMERA (15s) ---")
	if cine_camera: 
		cine_camera.make_current()
	
	# ATIVAR A ROTAÇÃO DA CÂMARA AQUI
	fase_camera_rodar = true 
	
	gato_script.a_rodar = true
	shader_mat.set_shader_parameter("modo", 2)
	
	var t2 = create_tween()
	t2.tween_method(set_shader_val, 0.0, 0.6, 5.0)
	
	await get_tree().create_timer(15.0).timeout 
	
	# Pausa
	gato_script.a_rodar = false
	shader_mat.set_shader_parameter("intensidade", 0.0)
	fase_camera_rodar = false # Parar câmara para a pausa
	
	await get_tree().create_timer(4.0).timeout 
	
	# --- FASE 3 ---
	print("--- 5. FASE 3: LEVITAÇÃO (15s) ---")
	
	fase_camera_rodar = true # Voltar a rodar câmara
	gato_script.a_rodar = true
	
	# Levitar Gato E Pivot (para a câmara subir junto mantendo o enquadramento)
	var nova_altura = altura_original_gato + 2.0
	var t_levitar = create_tween().set_parallel(true)
	
	t_levitar.tween_property(gato_script, "position:y", nova_altura, 5.0).set_trans(Tween.TRANS_SINE)
	if cam_pivot:
		t_levitar.tween_property(cam_pivot, "position:y", nova_altura, 5.0).set_trans(Tween.TRANS_SINE)
	
	shader_mat.set_shader_parameter("modo", 2)
	shader_mat.set_shader_parameter("intensidade", 1.0)
	
	if world_env.environment:
		world_env.environment.background_mode = Environment.BG_COLOR
		world_env.environment.background_color = Color(0.8, 0, 0)
	
	await get_tree().create_timer(15.0).timeout 
	
	terminar_sequencia()

func terminar_sequencia():
	print("--- A REPOR NORMALIDADE ---")
	fase_camera_rodar = false
	gato_script.a_rodar = false
	
	# Aterrar
	var t_aterrar = create_tween().set_parallel(true)
	t_aterrar.tween_property(gato_script, "position:y", altura_original_gato, 2.0)
	if cam_pivot:
		t_aterrar.tween_property(cam_pivot, "position:y", altura_original_gato, 2.0)
	
	var t_limpar = create_tween()
	t_limpar.tween_method(set_shader_val, 1.0, 0.0, 2.0)
	
	if world_env.environment:
		world_env.environment.background_color = cor_fundo_original
	
	await get_tree().create_timer(2.0).timeout
	
	var cam_player = player_ref.find_child("Camera3D", true, false)
	if cam_player:
		cam_player.make_current()
	elif player_ref.has_node("CameraPivot/Camera3D"):
		player_ref.get_node("CameraPivot/Camera3D").make_current()
	else:
		cine_camera.current = false
	
	player_ref.set_physics_process(true)
	player_ref.set_process_input(true)
	player_ref.set_process_unhandled_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	trigger.queue_free() 
	print("LIVRE!")

func set_shader_val(v):
	if shader_mat: shader_mat.set_shader_parameter("intensidade", v)
