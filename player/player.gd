extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Força com que o jogador empurra as caixas
const PUSH_FORCE = 1.0 

# ---------------------
# EXPORTS
# ---------------------
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var MOUSE_SENSITIVITY : float = 0.5

# Arrastar o AnimationPlayer para aqui no Inspector
@export var anim : AnimationPlayer 

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
	
	if anim == null:
		push_warning("AVISO: O AnimationPlayer não está atribuído.")

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
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" é o ESC por defeito no Godot
		get_tree().quit()

# ---------------------
# CAMERA UPDATE
# ---------------------
func _update_camera():
	_mouse_rotation.x += _tilt_input
	_mouse_rotation.y += _rotation_input
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)

	global_rotation.y = _mouse_rotation.y

	if CAMERA_CONTROLLER and CAMERA_CONTROLLER.get_parent():
		var pivot = CAMERA_CONTROLLER.get_parent()
		pivot.rotation.x = _mouse_rotation.x

	_rotation_input = 0.0
	_tilt_input = 0.0

# ---------------------
# PHYSICS PROCESS
# ---------------------
func _physics_process(delta):
	_update_camera()

	# 1. Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Movimento
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# -----------------------------------------------
	# 4. GESTÃO DE ANIMAÇÕES
	# -----------------------------------------------
	if anim:
		# Se estiver no ar (a saltar ou a cair)
		if not is_on_floor():
			anim.play("jump") # Verifica se o nome é "Jump" ou "mixamo_com" (salto)
		
		# Se estiver no chão e a mover-se
		elif direction != Vector3.ZERO:
			anim.play("walking") # Verifica se é "Run", "Walk" ou o nome que deste
		
		# Se estiver no chão e parado
		else:
			anim.play("idle") # Verifica se é "Idle"

	move_and_slide()

	# -----------------------------------------------
	# 5. EMPURRAR CAIXAS (RigidBody3D)
	# -----------------------------------------------
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		
		if collider is RigidBody3D:
			var push_dir = -c.get_normal()
			var push_strength = PUSH_FORCE
			
			push_dir.y = 0 
			push_dir = push_dir.normalized()
			
			collider.apply_central_impulse(push_dir * push_strength)
