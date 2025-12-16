extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Força com que o jogador empurra as caixas (Ajusta se necessário)
const PUSH_FORCE = 1.0 

# ---------------------
# EXPORTS
# ---------------------
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var MOUSE_SENSITIVITY : float = 0.5

# ---------------------
# INTERNAL STATE
# ---------------------
var _mouse_rotation : Vector3 = Vector3.ZERO
var _rotation_input : float = 0.0
var _tilt_input : float = 0.0

# ---------------------
# READY
# ---------------------
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if CAMERA_CONTROLLER == null:
		push_error("ERRO: A Camera3D não está atribuída ao export CAMERA_CONTROLLER.")
		return

# ---------------------
# INPUT EVENT (mouse)
# ---------------------
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

# ---------------------
# ESC SAIR
# ---------------------
func _input(event):
	if event.is_action_pressed("exit"): # Garante que tens esta ação no Input Map ou usa ui_cancel
		get_tree().quit()

# ---------------------
# CAMERA UPDATE
# ---------------------
func _update_camera():
	# atualizar valores do rato
	_mouse_rotation.x += _tilt_input
	_mouse_rotation.y += _rotation_input

	# limitar vertical (cima/baixo)
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)

	# ROTACIONAR O PLAYER (esquerda/direita) - Roda o corpo todo
	global_rotation.y = _mouse_rotation.y

	# ROTACIONAR O PIVOT DA CAMERA (cima/baixo)
	# Nota: Certifica-te que a Camera3D é filha de um Node3D (ex: CameraPivot)
	if CAMERA_CONTROLLER and CAMERA_CONTROLLER.get_parent():
		var pivot = CAMERA_CONTROLLER.get_parent()
		pivot.rotation.x = _mouse_rotation.x

	# reset dos inputs
	_rotation_input = 0.0
	_tilt_input = 0.0

# ---------------------
# PHYSICS PROCESS
# ---------------------
func _physics_process(delta: float) -> void:
	
	# Atualiza a câmara antes de mover
	_update_camera()

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movimentação
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# -----------------------------------------------
	# NOVA PARTE: CÓDIGO PARA EMPURRAR CAIXAS (RigidBody3D)
	# -----------------------------------------------
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		
		# Verifica se batemos num RigidBody (a caixa)
		if collider is RigidBody3D:
			# Calcula a direção do empurrão (contrária à normal da colisão)
			var push_dir = -c.get_normal()
			
			# Opcional: Aumentar a força se estivermos no chão para empurrar melhor
			var push_strength = PUSH_FORCE
			
			# Truque: Ignorar a força vertical (Y) para não empurrar a caixa para dentro do chão
			# e garantir que só empurramos na horizontal
			push_dir.y = 0 
			push_dir = push_dir.normalized()
			
			# Aplica o impulso no centro da caixa
			collider.apply_central_impulse(push_dir * push_strength)
