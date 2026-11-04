extends Node

# Sinal emitido quando o backend em C exigir uma alteração no histórico
signal gaslighting_solicitado(id_alvo: String, novo_texto: String)

var dados: Dictionary = {}

func _ready() -> void:
	carregar_json()

func carregar_json() -> void:
	var arquivo = FileAccess.open("res://_Backend/mock_estado_jogo.json", FileAccess.READ)
	
	if arquivo:
		var texto = arquivo.get_as_text()
		var json = JSON.new()
		var erro = json.parse(texto)
		
		if erro == OK:
			dados = json.data
			print("JSON carregado com sucesso! Fase atual: ", dados["fase_os"])
			verificar_gatilhos_historia()
		else:
			print("Erro ao ler o JSON.")

# --- SUB-01 e SUB-04: Ligação com a Árvore de Diálogo ---
func verificar_gatilhos_historia() -> void:
	# Verifica se a flag "gaslighting_pendente" vem como verdadeira a partir do backend C
	if dados.has("gaslighting_pendente") and dados["gaslighting_pendente"] == true:
		var id = dados.get("id_alvo_manipulacao", "")
		var texto = dados.get("texto_manipulado", "")
		
		if id != "" and texto != "":
			print("Gatilho de Gaslighting detetado! Emitindo sinal...")
			
			# Dá um pequeno delay para garantir que as janelas já estão carregadas
			get_tree().create_timer(1.0).timeout.connect(func():
				gaslighting_solicitado.emit(id, texto)
				
				# Após emitir, podemos "limpar" o estado localmente (ou enviar um ACK para o C)
				dados["gaslighting_pendente"] = false
			)
