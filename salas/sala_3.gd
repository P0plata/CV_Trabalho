extends Node3D

# =========================
# CONFIGURAÇÕES
# =========================
const CODIGO_CORRETO = "509"

# =========================
# VARIÁVEIS DE CONTROLO
# =========================
var completed_s : bool = false
var jogador_perto_keypad : bool = false
var ui_esta_aberta : bool = false

# =========================
# REFERÊNCIAS (ARRASTAR NO INSPECTOR)
# =========================
@export_group("Referências 3D")
@export var quadro_mesh : MeshInstance3D
@export var placa1_area : Area3D
@export var placa2_area : Area3D
@export var placa3_area : Area3D
@export var area_keypad : Area3D              
@export var parede_colisao : CollisionShape3D 
@export var parede_visual : Node3D            
@export var coin : Node3D                     

@export_group("Referências UI")
@export var ui_painel : Control               
@export var input_texto : LineEdit            
@export var botao_confirmar : Button          
@export var label_feedback : Label            

var material_quadro: BaseMaterial3D

func _enter_tree() -> void:
	if "sala3_done" in Main and Main.sala3_done == true:
		completed_s = true

func _ready():
	print("--- SALA 3 INICIADA ---")
	
	# Verificar se as coisas importantes foram arrastadas
	if not ui_painel or not area_keypad or not botao_confirmar:
		print("ERRO CRÍTICO: Faltam referências no Inspector da Sala 3!")
		return

	if ui_painel: ui_painel.visible = false
	
	if coin:
		coin.visible = true 
		if coin.has_node("CollisionShape3D"):
			coin.get_node("CollisionShape3D").set_deferred("disabled", false)

	if completed_s:
		_desativar_parede()
		return

	# Conexões
	placa1_area.body_entered.connect(_on_mudar_filtro_pisado.bind(0))
	placa2_area.body_entered.connect(_on_mudar_filtro_pisado.bind(1))
	placa3_area.body_entered.connect(_on_mudar_filtro_pisado.bind(2))
	
	area_keypad.body_entered.connect(_on_keypad_enter)
	area_keypad.body_exited.connect(_on_keypad_exit)
	
	if botao_confirmar:
		botao_confirmar.pressed.connect(_verificar_codigo)

	material_quadro = quadro_mesh.get_active_material(0)
	if material_quadro:
		_aplicar_filtro(BaseMaterial3D.TEXTURE_FILTER_NEAREST)

# =========================
# INPUT (ABRIR O KEYPAD)
# =========================
func _input(event):
	# Só processa se o jogador estiver na área e a sala não estiver acabada
	if jogador_perto_keypad and not completed_s:
		# Aceita "interagir" (Tecla E) OU "ui_accept" (Espaço/Enter)
		if event.is_action_pressed("interagir") or event.is_action_pressed("ui_accept"):
			print("Tecla pressionada! A tentar abrir UI...")
			_alternar_ui()

# =========================
# DETEÇÃO DO JOGADOR
# =========================
func _on_keypad_enter(body):
	# Verifica se é o player pelo GRUPO ou pelo NOME
	if body.is_in_group("player") or body.name == "Player":
		jogador_perto_keypad = true
		print("Jogador entrou na zona do Keypad. Pressiona E.")

func _on_keypad_exit(body):
	if body.is_in_group("player") or body.name == "Player":
		jogador_perto_keypad = false
		print("Jogador saiu da zona do Keypad.")
		if ui_esta_aberta: _alternar_ui()

# =========================
# LÓGICA UI
# =========================
func _alternar_ui():
	ui_esta_aberta = !ui_esta_aberta
	ui_painel.visible = ui_esta_aberta
	
	print("UI Aberta:", ui_esta_aberta)
	
	if ui_esta_aberta:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		input_texto.clear()
		input_texto.grab_focus()
		label_feedback.text = "Insere o Código..."
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _verificar_codigo():
	print("A verificar código: ", input_texto.text)
	
	if input_texto.text == CODIGO_CORRETO:
		label_feedback.text = "ACESSO PERMITIDO!"
		label_feedback.modulate = Color.GREEN
		print("Código correto!")
		await get_tree().create_timer(1.0).timeout
		_alternar_ui()
		_completar_sala()
	else:
		label_feedback.text = "CÓDIGO ERRADO!"
		label_feedback.modulate = Color.RED
		print("Código errado!")
		input_texto.clear()

# =========================
# PLACAS (MUDANÇA VISUAL)
# =========================
func _on_mudar_filtro_pisado(body, indice_placa):
	if not body.is_in_group("player") and body.name != "Player": return 
	
	match indice_placa:
		0: _aplicar_filtro(BaseMaterial3D.TEXTURE_FILTER_NEAREST)
		1: _aplicar_filtro(BaseMaterial3D.TEXTURE_FILTER_LINEAR)
		2: _aplicar_filtro(BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)

func _aplicar_filtro(tipo):
	if material_quadro:
		material_quadro.texture_filter = tipo

# =========================
# CONCLUSÃO
# =========================
func _completar_sala():
	print("SALA 3 COMPLETA!")
	completed_s = true
	if "sala3_done" in Main: Main.sala3_done = true
	_desativar_parede()

func _desativar_parede():
	if parede_colisao: parede_colisao.set_deferred("disabled", true)
	if parede_visual: parede_visual.visible = false

# =========================
# SISTEMA DE SALAS
# =========================
func _is_sala(): return true
func _is_completed(): return completed_s
func completed():
	completed_s = true
	if "sala3_done" in Main: Main.sala3_done = true
