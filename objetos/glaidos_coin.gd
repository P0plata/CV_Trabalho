extends Node3D # <--- Lembra-te que mudamos para Area3D para a colisão funcionar!

# MUDANÇA 1: Usamos 'Node' em vez de 'Node3D' para evitar o erro de tipo 'Window'
var sala : Node = null

func _ready():
	# Começa a procurar no pai
	var candidato = get_parent()
	
	while candidato != null:
		# Se encontrarmos a função, guardamos e paramos o loop
		if candidato.has_method("_is_sala"):
			sala = candidato
			break
		
		# Se chegarmos ao topo do jogo (Window/Root), paramos para não dar erro
		if candidato.get_parent() == null or candidato is Window:
			break
			
		# Continua a subir
		candidato = candidato.get_parent()
		
	# MUDANÇA 2: Verificamos se encontrámos mesmo uma sala antes de continuar
	if sala:
		if sala.has_method("_is_completed"):
			if sala._is_completed():
				queue_free()
				return 

func _on_body_entered(body):
	if body.is_in_group("player"):
		_marcar_concluida()
		queue_free()
		
func _marcar_concluida():
	if sala:
		sala.completed()
		print("Sala marcada como concluída.")
