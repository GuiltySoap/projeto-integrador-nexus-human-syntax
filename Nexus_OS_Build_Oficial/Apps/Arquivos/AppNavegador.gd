extends "res://JanelaBase.gd"

# Carrega o molde do ícone que criamos
const ICONE_FICHEIRO = preload("res://Apps/IconeFicheiro.tscn")

# Substitua pelo caminho correto do seu GridContainer!
@onready var grid_arquivos: GridContainer = $AreaConteudo/HSplitContainer/PanelDireito/ScrollContainer/GridContainer

# Nosso "banco de dados" de arquivos locais
var sistema_de_arquivos = [
	{"nome": "System_Logs", "tipo": "pasta"},
	{"nome": "Personal_Data", "tipo": "pasta"},
	{"nome": "PROJECT_Icarus", "tipo": "pasta"},
	{"nome": "read_me.txt", "tipo": "texto"},
	{"nome": "NEXUSCore.exe", "tipo": "executavel"},
	{"nome": "data_stream.png", "tipo": "imagem_corrompida"}
]

func _ready() -> void:
	gerar_arquivos()

func gerar_arquivos() -> void:
	for arquivo in sistema_de_arquivos:
		# 1. Cria uma cópia do molde
		var novo_icone = ICONE_FICHEIRO.instantiate()
		
		# 2. Adiciona à grelha (o Godot organiza a posição automaticamente)
		grid_arquivos.add_child(novo_icone)
		
		# 3. Puxa as referências de dentro do componente instanciado
		var label_nome = novo_icone.get_node("VBoxContainer/NomeFicheiro")
		var botao = novo_icone.get_node("BotaoClique")
		
		# 4. Define o texto para o nome do arquivo atual
		label_nome.text = arquivo["nome"]
		
		# 5. Conecta o clique usando uma função Lambda (anônima) para passar o nome adiante
		botao.pressed.connect(func(): abrir_arquivo(arquivo["nome"], arquivo["tipo"]))

func abrir_arquivo(nome: String, tipo: String) -> void:
	# Subimos dois degraus de uma vez só e guardamos a referência
	var desktop = get_parent().get_parent()
	
	if nome == "PROJECT_Icarus":
		if desktop.has_method("disparar_notificacao"):
			desktop.disparar_notificacao(
				"🔒 ACESSO NEGADO", 
				"Nível de autorização insuficiente para acessar 'PROJECT_Icarus'. Esta violação de conduta foi registrada."
			)
			
	elif nome == "read_me.txt":
		var texto_corporativo = "Bem-vindo ao NEXUS OS.\n\nLembre-se: Produtividade é Obediência. Pausas não autorizadas serão descontadas dos seus créditos sociais.\n\nSua estação está sendo monitorada."
		
		# Agora usamos a mesma variável 'desktop' que o Icarus usou!
		if desktop.has_method("abrir_leitor_texto"):
			desktop.abrir_leitor_texto(nome, texto_corporativo)		
		
	elif tipo == "texto" or tipo == "imagem_corrompida":
		print("NEXUS: Abrindo visualizador para " + nome + "...")
	else:
		print("NEXUS: Acessando pasta " + nome)
