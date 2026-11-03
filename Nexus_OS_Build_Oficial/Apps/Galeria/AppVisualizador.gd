extends "res://JanelaBase.gd"

@onready var imagem_exibida: TextureRect = $AreaConteudo/ImagemExibida

func _ready() -> void:
	# Opcional: Define um título padrão
	if has_node("BarraSuperior/TituloApp"):
		$BarraSuperior/TituloApp.text = "Nexus Photo Viewer"

# Função para ser chamada pelo Desktop/Arquivos ao abrir uma imagem
func carregar_imagem(caminho_imagem: String, nome_arquivo: String = "data_stream.png") -> void:
	var nova_textura = load(caminho_imagem)
	if nova_textura:
		imagem_exibida.texture = nova_textura
		if has_node("BarraSuperior/TituloApp"):
			$BarraSuperior/TituloApp.text = "Visualizando: " + nome_arquivo
	else:
		print("Erro: Imagem não encontrada no caminho -> ", caminho_imagem)
