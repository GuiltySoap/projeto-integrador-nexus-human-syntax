extends Control

# Caminhos relativos dentro do projeto
const BACKEND_PATH = "res://backend_nexus.exe"
const JSON_PATH = "res://estado_jogo.json"

@onready var lbl_mensagem: Label = $LblMensagem
@onready var lbl_metricas: Label = $LblMetricas
@onready var btn_nex: Button = $BtnEscolhaNex
@onready var btn_recusar: Button = $BtnEscolhaRecusar

func _ready() -> void:
	# Conecta os sinais de clique dos botões
	btn_nex.pressed.connect(func(): enviar_escolha_ao_backend(3))
	btn_recusar.pressed.connect(func(): enviar_escolha_ao_backend(1))
	
	# Leitura inicial caso o JSON já exista
	ler_e_atualizar_interface()

func enviar_escolha_ao_backend(id_escolha: int) -> void:
	# Transforma o caminho res:// para o caminho absoluto do sistema operacional
	var caminho_exe_abs = ProjectSettings.globalize_path(BACKEND_PATH)
	var argumentos = [str(id_escolha)]
	var saida_terminal = []
	
	# Executa o backend em C silenciosamente
	# OS.execute(caminho, args, array_saida, ler_stderr, ocultar_janela)
	var resultado = OS.execute(caminho_exe_abs, argumentos, saida_terminal, true, true)
	
	if resultado == 0:
		print("Backend C executado com sucesso.")
		ler_e_atualizar_interface()
	else:
		print("Erro ao executar backend. Código de saída: ", resultado)

func ler_e_atualizar_interface() -> void:
	var caminho_json_abs = ProjectSettings.globalize_path(JSON_PATH)
	
	if not FileAccess.file_exists(caminho_json_abs):
		lbl_mensagem.text = "Aguardando inicialização do sistema..."
		return

	# 1. Abre e lê o texto do arquivo JSON
	var arquivo = FileAccess.open(caminho_json_abs, FileAccess.READ)
	var conteudo_texto = arquivo.get_as_text()
	arquivo.close()

	# 2. Converte a String em Dicionário GDScript
	var json = JSON.new()
	var erro_parse = json.parse(conteudo_texto)
	
	if erro_parse == OK:
		var estado = json.get_data()
		aplicar_estado_na_ui(estado)
	else:
		print("Erro ao ler JSON na linha: ", json.get_error_line())

func aplicar_estado_na_ui(estado: Dictionary) -> void:
	# Extrai os dados salvos pelo C
	var fase_os = estado.get("fase_os", 1)
	var msg_nex = estado.get("mensagem_nex", "")
	var bloquear_cancelar = estado.get("bloquear_botao_cancelar", false)
	
	var metricas = estado.get("metricas", {})
	var aut = metricas.get("autonomia", 0)
	var con = metricas.get("conveniencia", 0)
	var dep = metricas.get("dependencia", 0)

	# Atualiza os componentes da tela
	lbl_mensagem.text = "Fase OS: %d\nStatus: %s" % [fase_os, msg_nex]
	lbl_metricas.text = "AUT: %d | CON: %d | DEP: %d" % [aut, con, dep]

	# Exemplo de regra visual: Bloqueia o botão de recusa se a dependência for alta
	btn_recusar.disabled = bloquear_cancelar
