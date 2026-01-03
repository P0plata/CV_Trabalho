extends Node3D

# ================= CONFIGURAÇÃO =================
@export var final_scene_path : String = ""
@export var anim_player : AnimationPlayer
@export var spawn_position : Node3D   # opcional (posição na cena final)

# ================= ESTADO =================
var is_open : bool = false
var player_na_pequena : bool = false
var player_na_grande : bool = false


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

	if is_open:
		return

	print("🚪 Porta FINAL: tentativa de abertura")

	if not Main.all_salas_completas():
		print("❌ Porta final bloqueada — salas incompletas")
		return

	abrir_porta()


func _ativacao_sair(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_na_pequena = false


# ================= LÓGICA DA PORTA FINAL =================
func abrir_porta() -> void:
	if is_open:
		return

	is_open = true
	Main.door_open = true

	print("🏁 Porta FINAL aberta")
	if final_scene_path != "":
		_carregar_cena_final()
		
	if anim_player and anim_player.has_animation("Open_door"):
		anim_player.play("Open_door")

	



func _carregar_cena_final() -> void:
	print("🎬 A carregar cena final:", final_scene_path)


	var packed := load(final_scene_path)
	if not packed:
		push_error("Erro ao carregar a cena final")
		return

	var cena_final = packed.instantiate()
	Main.current_room = cena_final
	get_tree().current_scene.add_child(cena_final)

	if spawn_position:
		cena_final.global_transform.origin = spawn_position.global_transform.origin
