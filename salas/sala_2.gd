extends Node3D

# --- VARIÁVEIS DE CONTROLO ---
var completed_s : bool = false
var nivel_visual_atual : int = -1 # Para controlar a mudança de gráficos

# --- REFERÊNCIAS ---
@export var spotlight : SpotLight3D
@export var world_env : WorldEnvironment      # <--- ARRASTAR O WORLD ENVIRONMENT AQUI
@export var sensores_luz : Array[Node3D]
@export var sensores_sombra : Array[Node3D]
@export var coin : Node3D
@export var objeto_para_ignorar : CollisionObject3D 

# --- MATERIAIS ---
var mat_verde : StandardMaterial3D
var mat_vermelho : StandardMaterial3D

func _enter_tree() -> void:
	# Verifica se a sala 2 já foi completada
	if Main.sala2_done == true:
		completed_s = true

func _ready():
	# Configura materiais
	mat_verde = StandardMaterial3D.new()
	mat_verde.albedo_color = Color.GREEN
	mat_verde.emission_enabled = true
	mat_verde.emission = Color.GREEN
	
	mat_vermelho = StandardMaterial3D.new()
	mat_vermelho.albedo_color = Color.RED
	mat_vermelho.emission_enabled = true
	mat_vermelho.emission = Color.RED
	
	# Estado inicial da moeda
	if coin:
		coin.visible = false
		if completed_s and coin.has_node("CollisionShape3D"):
			coin.get_node("CollisionShape3D").set_deferred("disabled", true)
			
	# Inicializa gráficos no nível 0 (Básico)
	atualizar_qualidade_visual(0)

func _physics_process(_delta):
	if !spotlight: return
	
	# Se já completou, mantém o nível máximo de gráficos e pára a lógica
	if completed_s: 
		atualizar_qualidade_visual(2)
		return 
	
	var puzzle_completo = true
	var sensores_corretos = 0 # Contador para definir a qualidade gráfica
	
	# 1. VERIFICAR SENSORES DE LUZ
	for sensor in sensores_luz:
		var esta_iluminado = verificar_raio(sensor)
		atualizar_cor(sensor, esta_iluminado)
		
		if esta_iluminado == false:
			puzzle_completo = false
		else:
			sensores_corretos += 1
			
	# 2. VERIFICAR SENSORES DE SOMBRA
	for sensor in sensores_sombra:
		var esta_iluminado = verificar_raio(sensor)
		# Nota: Para sombra, "bom" é quando NÃO está iluminado (!esta_iluminado)
		atualizar_cor(sensor, !esta_iluminado)
		
		if esta_iluminado == true:
			puzzle_completo = false
		else:
			sensores_corretos += 1
	
	# --- LÓGICA DE PROGRESSÃO GRÁFICA ---
	# Define o nível visual baseado no progresso
	var total_sensores = sensores_luz.size() + sensores_sombra.size()
	
	if puzzle_completo:
		_mostrar_moeda()
		atualizar_qualidade_visual(2) # Nível Máximo (God Rays)
	elif sensores_corretos > 0:
		atualizar_qualidade_visual(1) # Nível Médio (Reflexos/Soft Shadows)
	else:
		atualizar_qualidade_visual(0) # Nível Básico (Hard Shadows)

# --- SISTEMA DE PROGRESSÃO VISUAL (EDUCATIVO) ---
func atualizar_qualidade_visual(nivel: int):
	# Só atualiza se o nível mudou (para poupar performance)
	if nivel == nivel_visual_atual: return
	nivel_visual_atual = nivel
	
	if !spotlight or !world_env: return
	var env = world_env.environment
	
	# Garante que as sombras estão ligadas (necessário para o puzzle)
	spotlight.shadow_enabled = true 
	
	match nivel:
		0: # --- NÍVEL BÁSICO (O jogo começa aqui) ---
			print("Gráficos: Nível 0 (Básico)")
			# Sombras duras e definidas
			var tween = get_tree().create_tween()
			tween.tween_property(spotlight, "shadow_blur", 0.0, 0.5)
			
			# Desliga efeitos avançados
			env.ssr_enabled = false             # Sem reflexos
			env.ssao_enabled = false            # Sem oclusão ambiental
			env.volumetric_fog_enabled = false  # Sem "God Rays"
			env.glow_enabled = false            # Sem brilho
			
		1: # --- NÍVEL MÉDIO (Algum progresso) ---
			print("Gráficos: Nível 1 (Reflexos e Suavidade)")
			# Sombras ficam suaves (Blur)
			var tween = get_tree().create_tween()
			tween.tween_property(spotlight, "shadow_blur", 5.0, 1.0)
			
			# Liga Reflexos no chão (SSR) e Oclusão
			env.ssr_enabled = true
			env.ssao_enabled = true 
			env.volumetric_fog_enabled = false
			
		2: # --- NÍVEL ULTRA (Puzzle Resolvido) ---
			print("Gráficos: Nível 2 (Volumetrics/Next-Gen)")
			# Liga o Nevoeiro Volumétrico (O feixe de luz torna-se visível no ar)
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.02 # Ajusta a densidade se ficar muito branco
			
			# Liga o Glow para as luzes parecerem mágicas
			env.glow_enabled = true
			env.glow_intensity = 0.5

# --- A FUNÇÃO DE RAIO (CORRIGIDA) ---
func verificar_raio(alvo : Node3D) -> bool:
	var space = get_world_3d().direct_space_state
	
	# 1. Direção
	var direcao_tiro = spotlight.global_position.direction_to(alvo.global_position)
	
	# 2. Ponto de Partida (Avança 0.5m para sair da lanterna)
	var origem_ajustada = spotlight.global_position + (direcao_tiro * 0.5)
	
	# 3. Ponto de Chegada (Recua 0.2m para não bater na parede)
	var destino_ajustado = alvo.global_position - (direcao_tiro * 0.2) 
	
	var query = PhysicsRayQueryParameters3D.create(origem_ajustada, destino_ajustado)
	
	# --- LISTA DE EXCLUSÃO ---
	var lista_exclusao = []
	
	# Ignora a própria sala
	var eu_mesmo = get_node(".")
	if eu_mesmo is CollisionObject3D:
		lista_exclusao.append(eu_mesmo.get_rid())
		
	# Ignora a lanterna fixa
	if objeto_para_ignorar: 
		lista_exclusao.append(objeto_para_ignorar.get_rid())
		
	# Ignora o player
	var player = get_tree().get_first_node_in_group("player")
	if player: lista_exclusao.append(player.get_rid())
	
	query.exclude = lista_exclusao
	# -------------------------
	
	var result = space.intersect_ray(query)
	
	if result:
		var colidiu_com = result.collider
		#var ponto_impacto = result.position
		
		# Verifica acerto
		var temp_node = colidiu_com
		for i in range(4): 
			if temp_node == alvo:
				# desenhar_linha(origem_ajustada, ponto_impacto, Color.GREEN) # Debug Opcional
				return true
			temp_node = temp_node.get_parent()
			if temp_node == null: break
			
		# Se bateu em algo errado:
		# desenhar_linha(origem_ajustada, ponto_impacto, Color.RED) # Debug Opcional
			
	else:
		# Caminho livre
		# desenhar_linha(origem_ajustada, destino_ajustado, Color.GREEN) # Debug Opcional
		return true 

	return false 

# --- DESENHO DE DEBUG (Desativado nos comentários acima) ---
func desenhar_linha(inicio: Vector3, fim: Vector3, cor: Color):
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = cor
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(inicio)
	immediate_mesh.surface_add_vertex(fim)
	immediate_mesh.surface_end()
	
	get_tree().root.add_child(mesh_instance)
	await get_tree().process_frame
	if is_instance_valid(mesh_instance):
		mesh_instance.queue_free()

func atualizar_cor(sensor_node, is_active):
	var mesh = sensor_node.find_child("MeshInstance3D", true, false)
	if mesh:
		mesh.material_override = mat_verde if is_active else mat_vermelho

func _mostrar_moeda():
	if coin and not completed_s:
		if coin.visible == false:
			print("PUZZLE RESOLVIDO! Nível Gráfico: MÁXIMO")
			coin.visible = true
			if coin.has_node("CollisionShape3D"):
				coin.get_node("CollisionShape3D").set_deferred("disabled", false)

func _is_sala(): return true
func _is_completed(): return completed_s
func completed():
	Main.sala2_done = true
	completed_s = true
