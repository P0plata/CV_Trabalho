extends Node3D

@export var next_scene_path : String = ""
@export var open_only_once : bool = false
@export var anim_player : AnimationPlayer
@export var spawn_position : Node3D

# 🔑 NOVO (opcional)
@export var sala_controladora : NodePath

# ================= ESTADO =================
var is_open := false
var player_na_pequena := false
var player_na_grande := false
var a_fechar := false

# ================= ÁREA GRANDE =================
func _seguranca_entrar(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_na_grande = true

func _seguranca_sair(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_na_grande = false

# ================= ÁREA PEQUENA =================
func _ativacao_entrar(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	player_na_pequena = true

	if is_open and not a_fechar:
		return

	a_fechar = false
	print("GATILHO: Player tentou abrir porta")

	# 🔹 CASO 1 — PORTA NORMAL
	if sala_controladora == null or sala_controladora == NodePath(""):
		print("Porta normal → abrir")
		abrir_porta()
		return

	# 🔹 CASO 2 — PORTA DE PUZZLE
	var sala = get_node_or_null(sala_controladora)
	if sala and sala.pode_abrir_porta(self):
		print("Porta de puzzle correta → abrir")
		abrir_porta()
	else:
		print("Porta de puzzle errada → bloqueada")

func _ativacao_sair(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_na_pequena = false

# ================= LÓGICA PRINCIPAL =================
func abrir_porta():
	if is_open and not a_fechar:
		return

	if !Main.door_open:
		Main.door_open = true
	else:
		return

	is_open = true
	print("A iniciar abertura...")

	if anim_player and anim_player.has_animation("Open_door"):
		anim_player.play("Open_door")

	if next_scene_path != "":
		_load_next_scene()

	tentar_fechar_com_atraso()

func _load_next_scene():
	print("A carregar nova sala:", next_scene_path)

	if Main.current_room:
		Main.current_room.queue_free()
		Main.current_room = null

	var packed := load(next_scene_path)
	if not packed:
		push_error("Erro ao carregar cena")
		return

	var sala = packed.instantiate()
	Main.current_room = sala
	get_tree().current_scene.add_child(sala)

	if spawn_position:
		sala.global_transform.origin = spawn_position.global_transform.origin

func tentar_fechar_com_atraso():
	await get_tree().create_timer(2.0).timeout

	while player_na_pequena or player_na_grande:
		await get_tree().create_timer(0.5).timeout

	if not open_only_once:
		fechar_porta()

func fechar_porta():
	if player_na_pequena or player_na_grande:
		tentar_fechar_com_atraso()
		return

	print("A fechar a porta...")
	is_open = false
	a_fechar = true

	if anim_player.has_animation("close"):
		anim_player.play("close")
	elif anim_player.has_animation("Open_door"):
		anim_player.play_backwards("Open_door")

	await anim_player.animation_finished
	Main.door_open = false
	a_fechar = false
