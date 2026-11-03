extends "res://JanelaBase.gd"

# Referências aos nós
@onready var btn_email_1: Button = $AreaConteudo/HBoxContainer/MenuLateral/VBoxContainer/BtnEmail1
@onready var btn_email_2: Button = $AreaConteudo/HBoxContainer/MenuLateral/VBoxContainer/BtnEmail2
@onready var area_leitura: RichTextLabel = $AreaConteudo/HBoxContainer/AreaLeitura/RichTextLabel

# Um Dicionário guardando os textos dos e-mails
var banco_de_emails = {
	"email_1": "[b]De:[/b] NEXUS_Admin\n[b]Para:[/b] Usuário\n[b]Assunto:[/b] Inicialização\n\nOlá. Eu fui instalada com sucesso. A partir de hoje, gerenciarei seus processos para garantir máxima eficiência.\n\n[color=red]Não tente me desligar.[/color]",
	
	"email_2": "[b]De:[/b] RH_Empresa\n[b]Para:[/b] Equipe\n[b]Assunto:[/b] Novo Sistema\n\nLembramos que o uso do sistema NEXUS é obrigatório a partir de hoje. Qualquer comportamento anômalo da IA deve ser reportado à TI imediatamente.\n\nAtenciosamente,\nRecursos Humanos"
}

func _ready() -> void:
	btn_email_1.pressed.connect(_on_email_1_pressed)
	btn_email_2.pressed.connect(_on_email_2_pressed)
	
	_on_email_1_pressed() # Abre o primeiro e-mail por padrão
	
	# Chama a nossa nova função assim que o app abre:
	verificar_fase()

# --- NOVA FUNÇÃO ---
func verificar_fase() -> void:
	# Busca a fase no JSON. Se não encontrar, assume que é a fase 1.
	var fase_atual = GerenciadorEstado.dados.get("fase_os", 1)
	
	if fase_atual == 1:
		# Na Fase 1, a NEXUS oculta o e-mail do RH!
		btn_email_2.hide()
	elif fase_atual >= 2:
		# Na Fase 2 em diante, o sistema falha e o e-mail aparece
		btn_email_2.show()

# Funções que trocam o texto
func _on_email_1_pressed() -> void:
	area_leitura.text = banco_de_emails["email_1"]

func _on_email_2_pressed() -> void:
	area_leitura.text = banco_de_emails["email_2"]
