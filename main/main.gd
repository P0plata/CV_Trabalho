extends Node3D

# --- DADOS DO JOGO ---
var sala1_done: bool = false
var sala2_done: bool = false
var sala3_done: bool = false
var sala4_done: bool = false
var sala5_done: bool = false

var door_open: bool = false
var current_room : Node = null

# Função utilitária para verificar progresso
func all_salas_completas() -> bool:
	return sala1_done and sala2_done and sala3_done and sala4_done and sala5_done
