extends Node3D

# --- DADOS DO JOGO ---
#var sala1_done: bool = false
#var sala2_done: bool = false
#var sala3_done: bool = false
#var sala4_done: bool = false

var sala1_done: bool = true
var sala2_done: bool = true
var sala3_done: bool = true
var sala4_done: bool = true

var door_open: bool = false
var current_room : Node = null
	
	# 3. Guardar a referência na variável (útil se precisares de aceder ao script do corredor)

# Função utilitária para verificar progresso
func all_salas_completas() -> bool:
	if not sala1_done: return false
	if not sala2_done: return false
	if not sala3_done: return false
	if not sala4_done: return false
	return true
