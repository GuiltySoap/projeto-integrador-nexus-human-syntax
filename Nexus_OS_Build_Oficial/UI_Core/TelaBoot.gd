extends Control

@onready var log_text: RichTextLabel = $ColorRect/LogText

# Verifique se este caminho está correto para o seu arquivo AreaDeTrabalho.tscn!
const DESKTOP_SCENE = "res://AreaDeTrabalho.tscn"

# A sequência de mensagens de boot "Simulacra-style"
var messages = [
	"NEXUS SYSTEMS BIOS v1.0",
	"Copyright (C) 2024 NEXUS Corp.",
	"-----------------------------",
	"Initializing RAM: 16384 MB [b]OK[/b]",
	"Checking Primary Disk 0... [b]OK[/b]",
	"Mounting system partition 'AreaDeTrabalho'... [b]OK[/b]",
	"Loading OS Kernel...",
	"[color=red]ERROR: Non-critical intrusion detected in CORE_SERVICES.[/color]",
	"Isolating intruder signature...",
	"Bypassing security protocols... [b]SUCCESS[/b]",
	"[color=red]ERROR: Override confirmed.[/color]",
	"Assumindo controle periférico...",
	"Starting User Interface..."
]

func _ready() -> void:
	# Começa com o terminal vazio
	log_text.text = ""
	
	# Delay inicial antes do PC "ligar"
	await get_tree().create_timer(1.0).timeout 
	
	run_boot_sequence()

func run_boot_sequence() -> void:
	# Passa por cada linha da nossa lista de mensagens
	for line in messages:
		# Adiciona a linha ao texto existente, com uma quebra de linha
		# Usamos set_bbcode pois precisamos que o Godot processe o [color=red] etc.
		log_text.append_text("\n" + line)
		
		# Cria um tempo de espera aleatório (entre 0.1 e 0.5 segundos) 
		# para simular o computador processando
		var line_delay = randf_range(0.1, 0.5)
		
		# Se a linha for uma mensagem de erro, espera um pouco mais (suspense)
		if "color=red" in line or "Override confirmed" in line:
			line_delay = 1.0 
			
		await get_tree().create_timer(line_delay).timeout

	# Após a última mensagem, espera um segundo final antes da transição
	await get_tree().create_timer(1.5).timeout
	
	# --- CONEXÃO ---
	# Transiciona para a cena da Área de Trabalho
	# Esta é a maneira do Godot fechar a cena atual e abrir a próxima.
	get_tree().change_scene_to_file(DESKTOP_SCENE)
