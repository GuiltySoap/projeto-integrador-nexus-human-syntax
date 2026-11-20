# 15.6 Código

> **Atualização (2026-11-09).** A interface agora é montada em cenas `.tscn` editáveis (não mais em código). Onde este documento fala de `UiKit` construindo nós ou de cenas só com a raiz, leia como a etapa anterior; a descrição atual está em [`10_refatoracao_ui.md`](10_refatoracao_ui.md) e [`04_hierarquia_das_cenas.md`](04_hierarquia_das_cenas.md).

## Onde está o código completo

O conteúdo completo de cada arquivo é o próprio arquivo do projeto (sem trechos omitidos nem pseudocódigo). Este documento traz, para cada um: o **caminho**, a **responsabilidade**, os **nós** envolvidos e os **sinais**. A tabela do fim é **gerada** a partir dos scripts por `tools/gerar_indice_codigo.py`; rode o script de novo depois de mudar o código para atualizá-la.

- **Nós que devem existir na cena.** Só a raiz (`Control` com o script) de cada `.tscn`; a cena do desktop também precisa das 9 camadas nomeadas (`CamadaFundo`… `CamadaDebug`), e mesmo elas são criadas pelo script se faltarem. Todo o resto é construído em código (coluna "Nós criados em código").
- **Sinais a conectar.** Nenhum precisa ser conectado no editor: tudo é conectado em código e desconectado em `_exit_tree` (`Conexoes.ligar` na interface do sistema, `AppBase.conectar` nos aplicativos). A seção "Quem escuta cada sinal dos autoloads" lista quem usa cada sinal.

## Arquivos criados, alterados e removidos

Comparação com o `Nexus_OS_Build_Oficial_organizado.zip` recebido (84 arquivos fora da `.godot/`):

| | Quantidade | O que são |
|---|---|---|
| Mantidos sem mudança | 36 | `backend/` (protótipo em C), `.gitignore`, `.gitattributes`, `icon.svg`, os 16 `.uid` dos scripts que continuam existindo e os `.gitkeep` de `addons/` e das pastas de assets |
| Alterados | 27 | `project.godot`, `GerenciadorEstado`, `JanelaBase`, `TelaBoot`, `AreaDeTrabalho`, `PopupNotificacao`, `WidgetNexus`, `BalaoChat`, os seis apps que já existiam (`AppConfig`, `AppEmail`, `AppLeitorTexto`, `AppMensageiro`, `AppNavegador`, `AppVisualizador`) com suas cenas, os três scripts do minigame de lógica e o `README.md` |
| Removidos | 21 | Componentes sem uso (`balao_nexus`, `media_viewer_modal`, `icone_ficheiro`, `password_modal`), cenas que passaram a ser montadas em código (`popup_notificacao`, `widget_nexus`, `balao_chat`, `minigame_logica`) e 9 `.gitkeep` de pastas que agora têm conteúdo ou não eram usadas |
| Criados | 69 | Os 8 autoloads novos (o `GerenciadorEstado` já existia), 7 utilitários, 4 componentes de `shared/ui`, 11 scripts do shell, 6 apps novos, puzzles, tela final, 9 JSONs de dados, 9 docs, `tests/` e `tools/` |

A lista exata (por arquivo) está no relatório final de `09_criterios_de_aceitacao.md`.

## Contrato de um aplicativo (`AppBase`)

Todo app herda `AppBase` (`shared/ui/app_base/scripts/app_base.gd`). O `GerenciadorJanelas` instancia a cena do catálogo, injeta as propriedades e chama `iniciar`.

| Membro | Para que serve |
|---|---|
| `app_id`, `info`, `janela` | Preenchidos pelo gerenciador antes de `iniciar` (id e entrada do catálogo; a `JanelaBase`). |
| `iniciar(args)` | Chamado uma vez, com o app já na árvore. Monte a interface aqui (com guarda `_montada`) e leia `args`. |
| `receber_args(args)` | Chamado quando o app é de instância única e já está aberto (padrão: chama `iniciar`). |
| `pode_fechar()` / `confirmar_fechar()` | Impedem ou confirmam o fechamento (o Bloco de Notas usa `await` num diálogo). |
| `ao_focar()` / `ao_fechar()` | Ganchos de foco e fechamento. |
| `definir_titulo(texto)` | Muda o título da janela (sinal `titulo_alterado`). |
| `conectar(sinal, callable)` | Liga um sinal e o desliga sozinho em `_exit_tree`. Subclasses que sobrescrevem `_exit_tree`/`_ready` precisam chamar `super()`. |

## Como criar um novo aplicativo

1. Crie `features/apps/<nome>/scripts/app_<nome>.gd` com `class_name App<Nome>` e `extends AppBase`; implemente `iniciar(args)` montando a interface com `UiKit`.
2. Adicione uma entrada em `core/data/catalogo_apps.json`:

   | Campo | Significado |
   |---|---|
   | `id`, `nome`, `icone` (emoji), `cor` | Identificação e aparência (se existir `res://shared/assets/icons/apps/<id>.svg` ou `.png`, ele substitui o emoji). |
   | `cena` | `res://features/apps/<nome>/scenes/app_<nome>.tscn`. |
   | `processo` | Nome fictício exibido no Monitor do Sistema (`nexus_<algo>.exe`). |
   | `tamanho`, `tamanho_min` | `[largura, altura]` inicial e mínimo da janela. |
   | `multiplas_instancias` | `true` permite várias janelas do mesmo app. |
   | `dia_desbloqueio`, `condicao` | Dia a partir do qual o app existe e condições extras (`"flag:x"`, `"!flag:x"`, `"dia>=N"`, `"dia<=N"`; todas precisam ser verdadeiras). |
   | `area_de_trabalho`, `menu_iniciar`, `fixado` | Onde o app aparece (atalho, menu iniciar, barra de tarefas). |

3. Gere a cena: `python3 -I tools/gerar_cenas.py` (cria o `.tscn` mínimo; preserva UIDs existentes). Também dá para criar à mão: raiz `Control` com o script.
4. Abra o projeto no editor uma vez (gera os `.uid` e atualiza o cache de `class_name`).
5. Teste com `F9` (painel de testes) ou chamando `GerenciadorJanelas.abrir_app("<id>")`. Menu iniciar, barra, atalhos e busca já passam a mostrar o app, pois todos leem o catálogo.

## Convenções do código

- **GDScript 2.0 com tipagem estática**; indentação com tabs. Tipos explícitos quando o valor é `Variant` (`.get()`, indexação sem tipo, `min/max/clamp`).
- **Sem lambdas em `connect`**: métodos nomeados e `Callable.bind`, para poder desconectar. Sinais de autoloads são desfeitos em `_exit_tree`.
- **Sem `eval`, `OS.execute`, `OS.shell_open`, `rm`/`DirAccess.remove` ou acesso à rede.** O validador procura esses usos e falha se achar.
- **`class_name` só onde ajuda** (componentes e utilitários instanciados em código ou referenciados por tipo); nunca igual ao nome de um autoload.
- **Textos de interface em português**; textos narrativos em `core/data/narrativa/*.json`.
- **Recursos opcionais** (fontes, ícones, texturas, áudio) são checados com `ResourceLoader.exists`, com alternativa procedural.

<!-- INICIO_INDICE -->
Total: **106 scripts do jogo**, 20702 linhas de GDScript (sem `tests/`, que traz o teste de fumaça). Tabelas geradas por `tools/gerar_indice_codigo.py`.

### Autoloads (`core/autoload/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `core/autoload/gerenciador_configuracoes.gd` | (autoload) | Node | Preferências do jogador (visual, áudio e acessibilidade). Persistidas em user://. As permissões simuladas e o progresso ficam no GerenciadorEstado (pertencem à narrativa… | — | `configuracao_alterada(chave: String, valor: Variant)` |
| `core/autoload/gerenciador_estado.gd` | (autoload) | Node | Estado global do jogo: somente DADOS e SINAIS. A lógica narrativa fica no GerenciadorNarrativa e o acesso a disco no SistemaPersistencia. Nada aqui grava arquivos nem ab… | — | `dia_mudou(dia: int)`, `flag_alterada(nome: String, valor: Variant)`, `objetivo_concluido(id_objetivo: String)`, `corrupcao_mudou(valor: float)`, `seguranca_mudou(valor: int)`, `ia_estado_mudou(estado: String)`, `app_desbloqueado(app_id: String)`, `permissao_… |
| `core/autoload/gerenciador_janelas.gd` | (autoload) | Node | Gerenciador de janelas e catálogo de aplicativos. - O catálogo (core/data/catalogo_apps.json) é a ÚNICA fonte de apps: menu iniciar, ícones da área de trabalho, barra de… | — | `janela_aberta(janela: JanelaBase)`, `janela_fechada(janela: JanelaBase)`, `janela_focada(janela: JanelaBase)`, `janelas_alteradas()`, `catalogo_alterado()` |
| `core/autoload/gerenciador_narrativa.gd` | (autoload) | Node | Motor da narrativa: dias, objetivos, eventos, mensagens, processo malicioso simulado e finais. Tudo é guiado por dados (core/data/narrativa/*.json). Um único _process av… | — | `dia_iniciado(dia: int)`, `dia_encerrado(dia: int)`, `objetivos_atualizados()`, `evento_disparado(id_evento: String)`, `jogo_finalizado(id_final: String)`, `processo_iniciado(pid: int)`, `processo_finalizado(pid: int, sucesso: bool)`, `abrir_app_solicitado(ap… |
| `core/autoload/gerenciador_nos.gd` | (autoload) | Node | Gerenciador dos Story Nodes (StoryNodeManager): a progressão do jogo por NÓS DE HISTÓRIA, em vez do calendário fixo de 5 dias. Os dados vêm de core/data/narrativa/story_… | — | `no_ativado(id: String)`, `no_concluido(id: String)`, `progresso_atualizado(id: String)`, `falha_de_requisito(id: String, motivo: String)` |
| `core/autoload/relogio_global.gd` | (autoload) | Node | Relógio único do jogo. Evita criar vários Timers: todos os sistemas escutam estes sinais. | — | `segundo_passou(unix: int)`, `minuto_mudou(hora: int, minuto: int)` |
| `core/autoload/sistema_arquivos_virtual.gd` | (autoload) | Node | Sistema de arquivos virtual (VFS). Existe somente em memória: nenhum caminho daqui toca o disco real. Toda entrada de caminho passa por normalizar(); caminhos fora da ár… | — | `arvore_alterada(pasta: String)`, `arquivo_alterado(caminho: String)`, `chave_incorreta(id_puzzle: String)` |
| `core/autoload/sistema_audio.gd` | (autoload) | Node | Áudio do jogo. Se existir res://shared/assets/audio/<nome>.ogg\|wav\|mp3, o arquivo tem prioridade sobre o som procedural (o projeto traz os 9 efeitos principais em .wav… | AudioStreamPlayer, AudioStreamWAV | — |
| `core/autoload/sistema_eventos.gd` | (autoload) | Node | Barramento de eventos do jogo: desacopla os módulos (Mensageiro, Terminal, Arquivos, Permissões, Janelas, Story Nodes...). Quem produz o fato chama `emitir(id, dados)`;… | — | `evento_emitido(id: String, dados: Dictionary, item: Dictionary)`, `evento_rejeitado(id: String, motivo: String)` |
| `core/autoload/sistema_notificacoes.gd` | (autoload) | Node | Fila e histórico de notificações. Só dados e sinais: quem desenha os toasts é a área de trabalho e quem abre aplicativos a partir de um toast é o próprio shell (este aut… | — | `notificacao_emitida(notificacao: Dictionary)`, `historico_alterado()` |
| `core/autoload/sistema_persistencia.gd` | (autoload) | Node | Salvamento, carregamento, autosave e checkpoints. Só escreve dentro de user://nexus_os/. Nunca apaga arquivos: um salvamento ilegível é renomeado para ".corrompido" e o… | — | `salvo(arquivo: String)`, `falha_ao_carregar(motivo: String)` |

### Utilitários (`core/utilities/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `core/utilities/abridor_arquivos.gd` | `AbridorArquivos` | RefCounted | Decide qual aplicativo abre cada arquivo/pasta do VFS (Explorador, busca do menu, terminal e Galeria usam isto). Executáveis são simulados: nada é executado de verdade.… | — | — |
| `core/utilities/ajuda_maya.gd` | `AjudaMaya` | RefCounted | "Pedir ajuda à Maya": o jogador paga um custo de DEPENDÊNCIA para receber ajuda no nó atual. Cada pedido: 1. emite o evento `ajuda_solicitada` (o custo em DEP é aplicado… | — | — |
| `core/utilities/arquivo_virtual.gd` | `ArquivoVirtual` | RefCounted | Modelo dos nós do VFS (§23): normaliza o que vem dos dados (vfs_inicial.json, salvamentos antigos, nós criados em tempo de execução) e descreve o ESTADO de cada arquivo/… | — | — |
| `core/utilities/busca_interna.gd` | `BuscaInterna` | RefCounted | Busca do Navegador SIMULADO (§20): normaliza o que o jogador digitou, valida, consulta o dicionário interno (core/data/narrativa/busca_web.json) e devolve a página inter… | — | — |
| `core/utilities/catalogo_pacotes.gd` | `CatalogoPacotes` | RefCounted | Catálogo de pacotes instaláveis (§21), a partir de core/data/catalogo_apps.json: - cada aplicativo de "apps" é um pacote de BASE (tipo "base", `instalado_por_padrao`): j… | — | — |
| `core/utilities/cenas.gd` | `Cenas` | RefCounted | Caminhos das cenas principais e a ÚNICA camada de troca de cena do jogo (abertura, boot, Menu Principal, jogo, tela final). Nenhuma tela chama `change_scene_to_file` por… | — | — |
| `core/utilities/conexoes.gd` | `Conexoes` | RefCounted | Guarda conexões de sinais e as desfaz de uma vez (chame desligar_tudo() em _exit_tree). Evita sinais pendurados em autoloads quando uma tela/janela é destruída. | — | — |
| `core/utilities/estado_jogo_backend.gd` | `EstadoJogoBackend` | RefCounted | Contrato de arquivo entre o jogo (Godot) e o backend em C (§25/§26): `estado_jogo.json`.  COMO O BACKEND É EXECUTADO: é uma FERRAMENTA AUXILIAR de linha de comando (back… | — | — |
| `core/utilities/falso_boot.gd` | `FalsoBoot` | RefCounted | Falso boot: um "reinício" FALSO do HumaxOS simulado, usado pela narrativa (nó `no_falso_boot` ou efeito `falso_boot_iniciar`). Enquanto dura, os aplicativos listados em… | — | — |
| `core/utilities/imagem_procedural.gd` | `ImagemProcedural` | RefCounted | Gera imagens substitutas (placeholders) quando o arquivo real ainda não existe em res://shared/assets/textures. O puzzle de metadados NÃO depende da imagem: a pista está… | — | — |
| `core/utilities/instalacao_apps.gd` | `InstalacaoApps` | RefCounted | Serviço ÚNICO de instalação de aplicativos (§21): o Terminal (`apt-get install <pacote>`) e a interface gráfica (página Aplicativos das Configurações) chamam as MESMAS f… | — | — |
| `core/utilities/instalacao_humaxos.gd` | `InstalacaoHumaxOS` | RefCounted | Núcleo técnico do boot/instalação do HumaxOS (§13), SEM interface. A cena de boot (TelaBoot: BIOS -> registro -> saudação) só desenha e repassa; os testes chamam estas f… | — | — |
| `core/utilities/marca.gd` | `Marca` | RefCounted | Marca visual do jogo (§22): onde moram os logos oficiais, como achá-los e o que mostrar quando um deles faltar. É o ÚNICO lugar que conhece os caminhos dos logos: as cen… | — | — |
| `core/utilities/mensageria.gd` | `Mensageria` | RefCounted | Núcleo técnico do Mensageiro, sem interface (a UI só desenha o que isto decide, e os testes chamam isto direto): - ESCOLHAS: até 3 fixas vindas dos dados (`origem: "dado… | — | — |
| `core/utilities/metricas.gd` | `Metricas` | RefCounted | Regras das métricas globais AUT (Autonomia), CON (Conformidade) e DEP (Dependência) e a fórmula única do perfil final. Funções PURAS: o valor de cada métrica vive em UM… | — | — |
| `core/utilities/padroes_escuros.gd` | `PadroesEscuros` | RefCounted | Dark patterns FICCIONAIS: efeitos de perda de controle que existem SÓ dentro da interface simulada do HumaxOS (botão de confirmação que se desloca, contagem regressiva f… | — | — |
| `core/utilities/perfil_jogador.gd` | `PerfilJogador` | RefCounted | Perfil do jogador (nome e pronome) e as tags dinâmicas dos textos/diálogos JSON.  TAGS (maiúsculas): {NOME_JOGADOR}, {PRONOME_JOGADOR} (obrigatória), {ARTIGO_JOGADOR}, {… | — | — |
| `core/utilities/permissoes.gd` | `Permissoes` | RefCounted | Permissões do sistema simulado, orientadas a dados (core/data/permissoes.json). O VALOR de cada permissão continua em UM lugar, GerenciadorEstado.permissoes (id -> bool,… | — | — |
| `core/utilities/reacoes_npc.gd` | `ReacoesNpc` | RefCounted | Infraestrutura técnica para os NPCs REAGIREM a uma mensagem que a IA alterou (sem escrita narrativa definitiva). Ao receber o evento `mensagem_alterada_pela_ia` o Sistem… | — | — |
| `core/utilities/regras.gd` | `Regras` | RefCounted | Leitor das regras técnicas do jogo (core/data/regras.json): limites das métricas AUT/CON/DEP, fórmula do perfil final, pronomes, custo da ajuda da Maya, parâmetros dos e… | — | — |
| `core/utilities/sessao.gd` | `Sessao` | RefCounted | Fluxos de sessão compartilhados pelo Menu Principal, pela Pausa e pela Tela de Fim de Jogo: novo jogo, recomeçar, carregar o salvamento anterior e voltar ao Menu Princip… | — | — |
| `core/utilities/tema_nexus.gd` | `TemaNexus` | RefCounted | Paletas por dia narrativo e construção do Theme em código. Em execução, o Theme é aplicado na janela raiz (get_tree().root.theme), então vale para toda a interface (dia… | — | — |
| `core/utilities/tema_variacoes.gd` | `TemaVariacoes` | RefCounted | Type variations do Theme geradas por tabela, para que as cenas (.tscn) escolham estilo e tamanho de texto sem código. Rótulos: cada combinação (estilo x tamanho x mono)… | — | — |
| `core/utilities/ui_kit.gd` | `UiKit` | RefCounted | Utilitários de interface. NÃO constroem Controls: toda a estrutura visual vive em cenas (.tscn) e as aparências vêm de "type variations" do Theme criado em TemaNexus. Aq… | — | — |
| `core/utilities/util_texto.gd` | `UtilTexto` | RefCounted | Funções puras de texto (sem dependência de autoloads). | — | — |

### Componentes compartilhados (`shared/ui/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `shared/ui/app_base/scripts/app_base.gd` | `AppBase` | Control | Contrato de todo aplicativo que roda dentro de uma JanelaBase. O GerenciadorJanelas instancia a cena do app, adiciona à janela e então chama iniciar(args). Conexões feit… | — | `titulo_alterado(novo_titulo: String)` |
| `shared/ui/dialogo_arquivo/scripts/dialogo_arquivo.gd` | `DialogoArquivo` | Control | Seletor de arquivos do sistema simulado (abrir/salvar). Trabalha somente com o VFS. Resultado pelo sinal `resolvido`: caminho escolhido ou "" quando cancelado.  A estrut… | cena: `dialogo_arquivo.tscn`; nada criado em código | `resolvido(caminho: String)` |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | `DialogoNexus` | Control | Diálogo modal do sistema: alerta, confirmação, entrada de texto ou escolha entre 2+ opções. Sempre dá para cancelar com Esc ou com o botão de cancelar (nenhum diálogo pr… | cena: `dialogo_nexus.tscn`; Button | `resolvido(resultado: Variant)` |
| `shared/ui/icone_app/scripts/icone_app.gd` | `IconeApp` | Control | Ícone de um aplicativo do catálogo. Usa res://shared/assets/icons/apps/<id>.svg\|png quando existir; senão mostra um bloco colorido (cor do catálogo) com o emoji do app.… | cena: `icone_app.tscn`; nada criado em código | — |
| `shared/ui/indicador_carregamento/scripts/indicador_carregamento.gd` | `IndicadorCarregamento` | Control | Camada de "Carregando…" para as trocas de cena. Cobre a tela inteira, BLOQUEIA o mouse e leva o foco do teclado/controle para si (nada por trás recebe clique, Enter ou E… | cena: `indicador_carregamento.tscn`; nada criado em código | — |
| `shared/ui/janela_base/components/icone_botao/scripts/icone_botao.gd` | `IconeBotao` | Control | Ícone vetorial dos botões da barra de título (minimizar, maximizar, restaurar e fechar). É desenhado em _draw(): não depende de fontes de símbolos nem de imagens e acomp… | cena: `janela_base.tscn`; nada criado em código | — |
| `shared/ui/janela_base/scripts/janela_base.gd` | `JanelaBase` | Control | Janela do sistema operacional simulado: barra de título, minimizar/maximizar/fechar, arrastar, redimensionar pelas bordas, limites de tela, tamanho mínimo e restauração… | cena: `janela_base.tscn`; nada criado em código | `pedido_fechar(janela: JanelaBase)`, `pedido_minimizar(janela: JanelaBase)`, `maximizada_alterada(janela: JanelaBase, esta_maximizada: bool)`, `movida(janela: JanelaBase)`, `redimensionada(janela: JanelaBase)` |
| `shared/ui/logo_marca/scripts/logo_marca.gd` | `LogoMarca` | HBoxContainer | Logo da marca (Maya ou HumaxOS) como componente de cena: escolhe o arquivo pelo id em `Marca`, mantém a PROPORÇÃO do arquivo em qualquer altura, cai para o fallback quan… | cena: `logo_marca.tscn`; nada criado em código | — |
| `shared/ui/orbe_nexus/scripts/orbe_nexus.gd` | `OrbeNexus` | Control | Orbe animado da Maya. Reage ao estado da IA (cor) e a eventos (pulso). Desenhado em código (animação procedural); o nó e o tamanho mínimo estão em orbe_nexus.tscn (as te… | cena: `orbe_nexus.tscn`; nada criado em código | — |
| `shared/ui/painel_confirmacao/scripts/painel_confirmacao.gd` | `PainelConfirmacao` | Control | Painel de confirmação reutilizável (Menu Principal, Pausa e Fim de Jogo): título + texto + [Cancelar] [Confirmar]. Fica oculto até `perguntar()`. A resposta vem pelos si… | cena: `painel_confirmacao.tscn`; nada criado em código | `confirmado()`, `cancelado()` |
| `shared/ui/painel_opcoes/scripts/painel_opcoes.gd` | `PainelOpcoes` | Control | Painel de Opções do Menu Principal e da Pausa. NÃO é um sistema novo de configurações: cada linha é uma instância dos mesmos componentes das Configurações do HumaxOS (Li… | cena: `painel_opcoes.tscn`; nada criado em código | `fechado()` |

### Shell: boot, área de trabalho, barra, menu, toasts, widgets, efeitos (`features/shell/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | `AreaDeTrabalho` | Control | Cena principal do "sistema operacional". As camadas (fundo, ícones, widgets, janelas, barra/menus, toasts, efeitos, modais e depuração) e todas as peças do shell são nós… | cena: `area_de_trabalho.tscn`; nada criado em código | — |
| `features/shell/area_de_trabalho/scripts/cartao_dia.gd` | `CartaoDia` | Control | Cartão de título do dia ("DIA 3 — O Despertar da Máquina"). Não bloqueia o mouse nem o jogo e não pisca: uma faixa escura central com fade suave (sem fade em "reduzir an… | cena: `cartao_dia.tscn`; nada criado em código | — |
| `features/shell/area_de_trabalho/scripts/icone_area_de_trabalho.gd` | `IconeAreaDeTrabalho` | Button | Atalho de aplicativo na área de trabalho. Mouse: duplo clique. Teclado: Enter/Espaço com o ícone focado. A estrutura (ícone + legenda) está em icone_area_de_trabalho.tsc… | cena: `icone_area_de_trabalho.tscn`; nada criado em código | `abrir_pedido(app_id: String)` |
| `features/shell/area_de_trabalho/scripts/painel_debug.gd` | `PainelDebug` | PanelContainer | Painel de testes (F9) para validar a história sem repetir tudo: pular objetivos/dias, disparar glitch, criar notificações, iniciar o processo malicioso e ver as flags. S… | cena: `painel_debug.tscn`; nada criado em código | — |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | `PapelDeParede` | Control | Papel de parede que acompanha o dia. No modo "dia" usa res://shared/assets/textures/wallpaper_<dia>.png (ou wallpaper.png) quando o arquivo existe; sem ele, ou com "Alto… | cena: `papel_de_parede.tscn`; nada criado em código | — |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | `BarraTarefas` | PanelContainer | Barra de tarefas: botão Iniciar, apps fixados (lidos do catálogo), janelas abertas, bandeja (segurança, corrupção, microfone, notificações) e relógio em tempo real. Tudo… | cena: `barra_de_tarefas.tscn`; nada criado em código | `menu_pedido()`, `notificacoes_pedido()` |
| `features/shell/barra_de_tarefas/scripts/botao_tarefa.gd` | `BotaoTarefaApp` | Button | Botão da barra de tarefas: ícone do app e, nas janelas abertas, o título. Item reutilizável (botao_tarefa.tscn): a barra instancia um por app fixado e um por janela aber… | cena: `botao_tarefa.tscn`; nada criado em código | — |
| `features/shell/centro_notificacoes/scripts/cartao_notificacao.gd` | `CartaoNotificacao` | PanelContainer | Uma notificação no histórico da central. Item reutilizável (cartao_notificacao.tscn): a central instancia um por notificação. Aqui entram só o texto, a cor do nível e o… | cena: `cartao_notificacao.tscn`; nada criado em código | `abrir_app_pedido(app_id: String)` |
| `features/shell/centro_notificacoes/scripts/centro_notificacoes.gd` | `CentroNotificacoes` | Control | Central de notificações: histórico (até 60), opção de silenciar pop-ups e atalhos para os apps. Abre acima da barra de tarefas, no canto direito. Esc ou clicar fora fech… | cena: `centro_notificacoes.tscn`; nada criado em código | `aberto_alterado(aberto: bool)` |
| `features/shell/data_e_hora/scripts/widget_relogio.gd` | `WidgetRelogio` | PanelContainer | Relógio grande da área de trabalho: hora real do sistema + data fictícia do dia do jogo (a mesma da Agenda). Atualiza só quando o minuto muda (sinal do RelogioGlobal): s… | cena: `widget_relogio.tscn`; nada criado em código | — |
| `features/shell/efeito_glitch/scripts/efeito_glitch.gd` | `EfeitoGlitch` | Control | Camada de efeitos de glitch e "corrupção" visual. Acessibilidade: - "Reduzir glitch" desliga o efeito visual por completo; - "Sem flashes" deixa o efeito estático e frac… | cena: `efeito_glitch.tscn`; nada criado em código | — |
| `features/shell/falso_boot/scripts/sobreposicao_falso_boot.gd` | `SobreposicaoFalsoBoot` | Control | Sobreposição do FALSO BOOT (reinício falso do HumaxOS simulado). Só DESENHA o estado que mora em GerenciadorEstado.falso_boot e que a lógica (FalsoBoot) controla; nada a… | cena: `sobreposicao_falso_boot.tscn`; nada criado em código | — |
| `features/shell/janela_inicial/scripts/ajuda_dica.gd` | `AjudaDica` | RefCounted | "Pedir ajuda à Maya": fluxo compartilhado pelo Menu Iniciar, pelo widget da Maya e pelo atalho Ctrl+Shift+H. Pedir ajuda TEM CUSTO (a dependência do jogador em relação à… | — | — |
| `features/shell/janela_inicial/scripts/botao_app_menu.gd` | `BotaoAppMenu` | Button | Botão de um aplicativo na grade do Menu Iniciar. Item reutilizável (botao_app_menu.tscn): o menu instancia um por app. | cena: `botao_app_menu.tscn`; nada criado em código | — |
| `features/shell/janela_inicial/scripts/menu_iniciar.gd` | `MenuIniciar` | Control | Menu Iniciar: lista os aplicativos liberados (lidos do catálogo), busca aplicativos e arquivos do VFS e reúne Pedir ajuda, Encerrar dia, Salvar e Sair. Abre acima da bar… | cena: `menu_iniciar.tscn`; nada criado em código | `aberto_alterado(aberto: bool)`, `sair_pedido()` |
| `features/shell/janela_inicial/scripts/resultado_busca.gd` | `ResultadoBusca` | Button | Um resultado da busca do Menu Iniciar (aplicativo ou arquivo). Item reutilizável (resultado_busca.tscn). | cena: `resultado_busca.tscn`; nada criado em código | — |
| `features/shell/monitor_virtual/scripts/monitor_virtual.gd` | `MonitorVirtual` | Control | Monitor virtual do HumaxOS (§12): renderiza a área de trabalho DENTRO de um SubViewport, mostrado numa "tela de monitor" sobre um fundo físico levemente desfocado (place… | cena: `monitor_virtual.tscn`; nada criado em código | `foco_alterado(foco: int)`, `resolucao_alterada(resolucao: Vector2i)` |
| `features/shell/popup_notificacao/scripts/pilha_toasts.gd` | `PilhaToasts` | Control | Pilha de toasts no canto superior direito. No máximo 3 ao mesmo tempo (os demais esperam numa fila curta); avisos críticos furam a fila. Este nó é do shell, então é ele… | cena: `pilha_toasts.tscn`; nada criado em código | — |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | `PopupNotificacao` | PanelContainer | Toast no canto superior direito. Um único _process conta o tempo (sem Timer); passar o mouse pausa a contagem. Clicar abre o app associado (se houver) e dispensa. O níve… | cena: `popup_notificacao.tscn`; nada criado em código | `fechado(popup: PopupNotificacao)`, `abrir_pedido(app_id: String, id_notificacao: int)` |
| `features/shell/tela_boot/scripts/tela_boot.gd` | `TelaBoot` | Control | Boot diegético do HumaxOS. É a segunda etapa do "Novo Jogo" (a primeira é o Menu Principal, que vem depois da Splash Screen): Executável -> Splash Screen -> Menu Princip… | cena: `tela_boot.tscn`; Label | — |
| `features/shell/widget_nexus/scripts/item_objetivo.gd` | `ItemObjetivo` | Label | Uma linha da lista de objetivos do dia (item_objetivo.tscn): "☐ texto" ou "☑ texto" (esmaecido quando concluído). | cena: `item_objetivo.tscn`; nada criado em código | — |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | `WidgetNexus` | PanelContainer | Widget da Maya na área de trabalho: orbe reativo, estado da IA, fala do dia, pendências do ciclo com progresso, indicadores de segurança/corrupção (barras + texto) e ata… | cena: `widget_nexus.tscn`; nada criado em código | — |

### Aplicativos (`features/apps/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `features/apps/bloco_de_notas/scripts/app_bloco_de_notas.gd` | `AppBlocoDeNotas` | AppBase | Bloco de Notas: edita arquivos de texto do VFS (nada fora do jogo é lido ou gravado). Novo / Abrir / Salvar / Salvar como, atalhos Ctrl+N/O/S e aviso de alterações não s… | cena: `app_bloco_de_notas.tscn`; nada criado em código | — |
| `features/apps/calculadora/scripts/app_calculadora.gd` | `AppCalculadora` | AppBase | Calculadora com máquina de estados própria: nenhuma expressão digitada é interpretada ou avaliada (sem Expression, sem eval). Aceita mouse e teclado (dígitos, + - * /, v… | cena: `app_calculadora.tscn`; nada criado em código | — |
| `features/apps/calendario/scripts/app_calendario.gd` | `AppCalendario` | AppBase | Agenda: calendário mensal com a data fictícia do jogo (o Dia N da história cai N-1 dias depois do início da sessão) e o relógio ao vivo (usa o relógio único do jogo, sem… | cena: `app_calendario.tscn`; ButtonGroup, Control | — |
| `features/apps/calendario/scripts/cartao_compromisso.gd` | `CartaoCompromisso` | PanelContainer | Cartão de um compromisso da agenda (item reutilizável de cartao_compromisso.tscn). | cena: `cartao_compromisso.tscn`; nada criado em código | — |
| `features/apps/calendario/scripts/item_dia_calendario.gd` | `ItemDiaCalendario` | Button | Célula de um dia na grade do calendário (item reutilizável de item_dia_calendario.tscn). “★ hoje” e “● Dia N” aparecem como texto (e não só como cor). | cena: `item_dia_calendario.tscn`; nada criado em código | `selecionado(dia: int)` |
| `features/apps/config/components/cabecalho_pagina/scripts/cabecalho_pagina.gd` | `CabecalhoPagina` | VBoxContainer | Cabeçalho de uma página das Configurações: título grande, subtítulo explicativo e uma linha separadora. Edite `titulo` e `subtitulo` no Inspector; o texto aparece também… | cena: `cabecalho_pagina.tscn`; nada criado em código | — |
| `features/apps/config/components/dialogo_revogacao/scripts/dialogo_revogacao.gd` | `DialogoRevogacao` | Control | Confirmação final ao REVOGAR uma permissão-chave quando a Maya "resiste" (dependência no limite). É um dark pattern FICCIONAL: o botão "Desativar mesmo assim" salta de l… | cena: `dialogo_revogacao.tscn`; nada criado em código | `resolvido(confirmou: bool)` |
| `features/apps/config/components/linha_check/scripts/linha_check.gd` | `LinhaCheck` | VBoxContainer | Opção liga/desliga das Configurações: caixa de seleção com título e uma descrição recuada logo abaixo. No Inspector: `chave` (nome da configuração ou da permissão), `tit… | cena: `linha_check.tscn`; nada criado em código | `alternada(chave: String, ativa: bool)` |
| `features/apps/config/components/linha_opcao/scripts/linha_opcao.gd` | `LinhaOpcao` | HBoxContainer | Linha das Configurações: título à esquerda e lista suspensa (OptionButton) à direita. No Inspector: `chave` (nome da configuração), `titulo`, `rotulos` (texto de cada op… | cena: `linha_opcao.tscn`; nada criado em código | `valor_escolhido(chave: String, valor: Variant)` |
| `features/apps/config/components/linha_slider/scripts/linha_slider.gd` | `LinhaSlider` | VBoxContainer | Controle deslizante (0 a 100%) das Configurações, com título e o valor em porcentagem ao lado. No Inspector: `chave` (nome da configuração) e `titulo`. | cena: `linha_slider.tscn`; nada criado em código | `valor_alterado(chave: String, valor: float)`, `valor_confirmado(chave: String)` |
| `features/apps/config/scripts/app_config.gd` | `AppConfig` | AppBase | Configurações do HumaxOS: Personalização, Áudio, Acessibilidade, Privacidade e Sistema. A página de Privacidade usa "dark patterns" como TEMA narrativo (texto culpabiliz… | cena: `app_config.tscn`; Button, HBoxContainer, Label, MarginContainer, PanelContainer, VBoxContainer | — |
| `features/apps/email/scripts/app_email.gd` | `AppEmail` | AppBase | Caixa de entrada somente leitura. Os e-mails vêm de emails.json e aparecem conforme o dia da história (GerenciadorNarrativa.emails_disponiveis). Ler um e-mail define a f… | cena: `app_email.tscn`; ButtonGroup | — |
| `features/apps/email/scripts/item_email.gd` | `ItemEmail` | Button | Linha da lista de e-mails (item reutilizável de item_email.tscn). O app instancia um por e-mail disponível. “● NOVO” no texto (e não só cor) marca os não lidos. | cena: `item_email.tscn`; nada criado em código | `selecionado(id_email: String)` |
| `features/apps/explorador/scripts/app_explorador.gd` | `AppExplorador` | AppBase | Explorador de Arquivos do sistema simulado. Só enxerga o VFS (nunca o disco real). Navegação com histórico, busca na pasta, "Mostrar ocultos" (liberado pela narrativa no… | cena: `app_explorador.tscn`; nada criado em código | — |
| `features/apps/leitor_texto/scripts/app_leitor_texto.gd` | `AppLeitorTexto` | AppBase | Leitor de texto SOMENTE LEITURA: logs do sistema, arquivos protegidos e arquivos já decifrados. O conteúdo é mostrado como texto puro (nenhum BBCode é interpretado). Par… | cena: `app_leitor_texto.tscn`; nada criado em código | — |
| `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd` | `BalaoChat` | HBoxContainer | Balão de mensagem do Mensageiro (balao_chat.tscn). A estrutura (bolha, etiqueta, texto, hora, botão "Ver original") vive na cena; este script só escolhe o estilo conform… | cena: `balao_chat.tscn`; Button | `original_visto(id_msg: String)`, `reenvio_solicitado(id_msg: String)`, `anexo_solicitado(anexo: Dictionary)` |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | `AppMensageiro` | AppBase | Mensageiro dirigido por dados (conversas.json + GerenciadorEstado.chat). Os contatos e as mensagens mudam com o dia: Maya gentil (Dia 1), sugestões que viram controle (D… | cena: `app_mensageiro.tscn`; ButtonGroup | — |
| `features/apps/mensageiro/scripts/item_contato.gd` | `ItemContato` | Button | Linha da lista de contatos do Mensageiro (item reutilizável de item_contato.tscn). O app instancia um por contato disponível. O texto traz ícone, nome, 🚫 (contato bloque… | cena: `item_contato.tscn`; nada criado em código | `selecionado(id_contato: String)` |
| `features/apps/mensageiro/scripts/item_escolha.gd` | `ItemEscolha` | Button | Botão de resposta do Mensageiro (item reutilizável de item_escolha.tscn): uma opção de resposta de uma mensagem que espera uma escolha do jogador. O app instancia um por… | cena: `item_escolha.tscn`; nada criado em código | `escolhida(id_msg: String, id_escolha: String, flag: String)` |
| `features/apps/monitor_sistema/scripts/app_monitor_sistema.gd` | `AppMonitorSistema` | AppBase | Monitor do Sistema SIMULADO: lista apenas processos fictícios do jogo (TabelaProcessos). Nada aqui lê ou encerra processos reais. O processo malicioso `maya_override_dae… | cena: `app_monitor_sistema.tscn`; ButtonGroup | — |
| `features/apps/monitor_sistema/scripts/linha_processo.gd` | `LinhaProcesso` | Button | Linha da tabela do Monitor do Sistema (item reutilizável de linha_processo.tscn): um por processo fictício. Processos suspeitos usam outra variação de rótulo (vermelho).… | cena: `linha_processo.tscn`; nada criado em código | `selecionada(pid: int)` |
| `features/apps/navegador/scripts/app_navegador.gd` | `AppNavegador` | AppBase | Navegador SIMULADO: só abre páginas internas `humax://` (as de paginas_web.json e as da busca em busca_web.json). Nenhuma requisição de rede é feita e nenhum endereço ex… | cena: `app_navegador.tscn`; Button, HBoxContainer, Timer | — |
| `features/apps/terminal/scripts/app_terminal.gd` | `AppTerminal` | AppBase | Terminal SIMULADO do sistema. Nenhum comando toca o computador real: tudo opera sobre o VFS e os dados do jogo. Comandos comuns (ls, cd, cat, tree, ps, kill...) e, no Di… | cena: `app_terminal.tscn`; nada criado em código | — |
| `features/apps/visualizador/scripts/app_visualizador.gd` | `AppVisualizador` | AppBase | Galeria / Visualizador de mídia: imagens e áudios do VFS, com navegação entre irmãos da pasta e painel de METADADOS. A pista do Dia 3 (banda + ano do show) está nos meta… | cena: `app_visualizador.tscn`; nada criado em código | — |

### Minigame de lógica (`features/minigames/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `features/minigames/logica/components/porta_logica_item/scripts/porta_logica_item.gd` | `PortaLogicaItem` | Button | Porta lógica do minigame (porta_logica_item.tscn). Duas formas de usar (acessibilidade): clicar/Enter (emite `escolhida`) ou arrastar até o encaixe. O tipo da porta é co… | cena: `porta_logica_item.tscn`; Label, PanelContainer | `escolhida(tipo: String)` |
| `features/minigames/logica/components/slot_circuito/scripts/slot_circuito.gd` | `SlotCircuito` | PanelContainer | Encaixe do circuito (slot_circuito.tscn): recebe uma porta arrastada (ou definida por clique, pelo minigame). O rótulo interno ignora o mouse para que o arraste alcance… | cena: `slot_circuito.tscn`; nada criado em código | `porta_alterada(slot_id: String, tipo_porta: String)` |
| `features/minigames/logica/scripts/minigame_logica.gd` | `MinigameLogica` | Control | Cofre lógico da pasta PROJECT_Icarus (modal). O jogador encaixa uma porta lógica no circuito de forma que a saída reproduza a tabela-alvo para TODAS as combinações de A… | cena: `minigame_logica.tscn`; nada criado em código | `resolvido(ok: bool)` |

### Puzzles (`features/puzzles/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `features/puzzles/arquivos_criptografados/scripts/dialogo_chave.gd` | `DialogoChave` | Control | Puzzle dos arquivos criptografados (Lixeira e memorias_backup.zip). A chave nunca aparece em texto no jogo: o VFS só guarda o SHA-256 da forma normalizada. Acessibilidad… | cena: `dialogo_chave.tscn`; nada criado em código | `resolvido(ok: bool)` |
| `features/puzzles/evento_processo/scripts/tabela_processos.gd` | `TabelaProcessos` | RefCounted | Tabela de processos SIMULADA. Nada aqui lê, lista ou encerra processos reais do computador. Junta (1) as janelas de aplicativos abertas, (2) processos "de sistema" fictí… | — | — |

### Narrativa: finais (`features/narrative/`)

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `features/narrative/finais/components/item_evidencia/scripts/item_evidencia.gd` | `ItemEvidencia` | Label | Linha de uma prova no resumo da jornada (tela final): "☑ nome" quando a prova foi reunida e "☐ nome", em tom mais fraco, quando ainda falta. A cena (item_evidencia.tscn)… | cena: `item_evidencia.tscn`; nada criado em código | — |
| `features/narrative/finais/scripts/tela_final.gd` | `TelaFinal` | Control | Tela de final. Lê o final alcançado (GerenciadorEstado.final_id) e os textos de finais.json. Mostra o texto, o resumo da jornada (evidências, corrupção, segurança) e as… | cena: `tela_final.tscn`; nada criado em código | — |

### Outros

| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |
|---|---|---|---|---|---|
| `features/menu_principal/scripts/menu_principal.gd` | `MenuPrincipal` | Control | Menu Principal: vem depois da Splash Screen (Executável -> Splash -> Menu) e é o destino de "Retornar ao Menu Inicial" (Pausa, Fim de Jogo e Tela Final). Não inicia o jo… | cena: `menu_principal.tscn`; nada criado em código | — |
| `features/menu_principal/scripts/painel_creditos.gd` | `PainelCreditos` | Control | Painel de Créditos do Menu Principal. Só mostra o que está confirmado no projeto: nome do jogo, tecnologias, origem das imagens e dos áudios e a licença do motor. As seç… | cena: `painel_creditos.tscn`; nada criado em código | `fechado()` |
| `features/pause/scripts/camada_sobreposta.gd` | `CamadaSobreposta` | Control | Base do Menu de Pausa e da Tela de Fim de Jogo: uma camada por cima do jogo que PAUSA a árvore, prende o foco nela mesma e oferece as ações de sessão (carregar o salvame… | — | — |
| `features/pause/scripts/menu_pausa.gd` | `MenuPausa` | CamadaSobreposta | Menu de Pausa do jogo (a área de trabalho). Abre com Esc (ação `ui_cancel`, a mesma do resto do jogo) e PAUSA de verdade (`get_tree().paused`): relógio da narrativa, aut… | cena: `menu_pausa.tscn`; nada criado em código | `aberto_alterado(aberto: bool)` |
| `features/pause/scripts/tela_fim_de_jogo.gd` | `TelaFimDeJogo` | CamadaSobreposta | Tela de Fim de Jogo: aparece sozinha quando a história termina e oferece as três saídas (Recomeçar Jogo, Carregar Salvamento Anterior, Retornar ao Menu Inicial), sempre… | cena: `tela_fim_de_jogo.tscn`; nada criado em código | `rever_pedido()` |
| `features/splash_screen/scripts/splash_screen.gd` | `SplashScreen` | Control | Splash Screen: a abertura da marca ("Maya Human Syntax"). É a PRIMEIRA cena do jogo (`run/main_scene`) e fica fora da narrativa: só mostra a logo animada e entrega o jog… | cena: `splash_screen.tscn`; nada criado em código | — |

### Quem escuta cada sinal dos autoloads

| Sinal | Escutado em |
|---|---|
| `RelogioGlobal.segundo_passou(unix: int)` | `app_calendario` |
| `RelogioGlobal.minuto_mudou(hora: int, minuto: int)` | `barra_de_tarefas`, `widget_relogio` |
| `GerenciadorConfiguracoes.configuracao_alterada(chave: String, valor: Variant)` | `app_config`, `area_de_trabalho`, `logo_marca`, `menu_principal`, `monitor_virtual`, `painel_opcoes`, `sistema_audio`, `splash_screen` |
| `GerenciadorEstado.dia_mudou(dia: int)` | `app_explorador`, `barra_de_tarefas`, `gerenciador_janelas`, `painel_debug`, `widget_relogio` |
| `GerenciadorEstado.flag_alterada(nome: String, valor: Variant)` | `app_calendario`, `app_explorador`, `app_mensageiro`, `gerenciador_narrativa`, `gerenciador_nos`, `painel_debug`, `sistema_persistencia` |
| `GerenciadorEstado.objetivo_concluido(id_objetivo: String)` | `area_de_trabalho`, `sistema_persistencia` |
| `GerenciadorEstado.corrupcao_mudou(valor: float)` | `app_config`, `area_de_trabalho`, `barra_de_tarefas`, `widget_nexus` |
| `GerenciadorEstado.seguranca_mudou(valor: int)` | `app_config`, `barra_de_tarefas`, `widget_nexus` |
| `GerenciadorEstado.ia_estado_mudou(estado: String)` | `widget_nexus` |
| `GerenciadorEstado.app_desbloqueado(app_id: String)` | `area_de_trabalho`, `gerenciador_janelas` |
| `GerenciadorEstado.permissao_alterada(nome: String, ativa: bool)` | `app_config`, `barra_de_tarefas`, `sistema_eventos`, `sistema_persistencia` |
| `GerenciadorEstado.processos_alterados()` | `app_monitor_sistema` |
| `GerenciadorEstado.processo_encerrado_pelo_jogador(pid: int)` | — (emitido para quem quiser escutar) |
| `GerenciadorEstado.mensagem_recebida(contato: String, entrada: Dictionary)` | `app_mensageiro`, `sistema_persistencia`, `widget_nexus` |
| `GerenciadorEstado.contato_bloqueado(contato: String)` | `app_mensageiro`, `sistema_persistencia` |
| `GerenciadorEstado.final_alcancado(id_final: String)` | `sistema_eventos` |
| `GerenciadorEstado.jogador_alterado(nome: String)` | — (emitido para quem quiser escutar) |
| `GerenciadorEstado.glitch_solicitado(intensidade: float, duracao: float)` | `area_de_trabalho` |
| `GerenciadorEstado.gaslighting_solicitado(id_alvo: String, novo_texto: String)` | `app_mensageiro` |
| `GerenciadorEstado.metrica_mudou(nome: String, valor: float, delta: float)` | `gerenciador_nos`, `sistema_persistencia` |
| `GerenciadorEstado.mensagem_alterada(contato: String, id_msg: String, texto_original: String, texto_novo: String)` | `sistema_eventos` |
| `GerenciadorEstado.mensagem_atualizada(contato: String, id_msg: String)` | `app_mensageiro` |
| `GerenciadorEstado.perfil_alterado(nome: String, pronome: String)` | `sistema_persistencia` |
| `GerenciadorEstado.apps_instalados_mudou(app_id: String, instalado: bool)` | `app_config`, `sistema_arquivos_virtual`, `sistema_persistencia` |
| `GerenciadorEstado.falso_boot_mudou(ativo: bool)` | `gerenciador_janelas`, `sistema_persistencia`, `sobreposicao_falso_boot` |
| `SistemaNotificacoes.notificacao_emitida(notificacao: Dictionary)` | `pilha_toasts` |
| `SistemaNotificacoes.historico_alterado()` | `barra_de_tarefas`, `centro_notificacoes` |
| `SistemaArquivosVirtual.arvore_alterada(pasta: String)` | `app_explorador`, `sistema_persistencia` |
| `SistemaArquivosVirtual.arquivo_alterado(caminho: String)` | `app_bloco_de_notas`, `app_explorador`, `app_leitor_texto`, `sistema_persistencia` |
| `SistemaArquivosVirtual.chave_incorreta(id_puzzle: String)` | — (emitido para quem quiser escutar) |
| `GerenciadorJanelas.janela_aberta(janela: JanelaBase)` | — (emitido para quem quiser escutar) |
| `GerenciadorJanelas.janela_fechada(janela: JanelaBase)` | — (emitido para quem quiser escutar) |
| `GerenciadorJanelas.janela_focada(janela: JanelaBase)` | — (emitido para quem quiser escutar) |
| `GerenciadorJanelas.janelas_alteradas()` | `app_monitor_sistema`, `barra_de_tarefas` |
| `GerenciadorJanelas.catalogo_alterado()` | `area_de_trabalho`, `barra_de_tarefas`, `menu_iniciar` |
| `SistemaEventos.evento_emitido(id: String, dados: Dictionary, item: Dictionary)` | `gerenciador_nos` |
| `SistemaEventos.evento_rejeitado(id: String, motivo: String)` | — (emitido para quem quiser escutar) |
| `GerenciadorNos.no_ativado(id: String)` | — (emitido para quem quiser escutar) |
| `GerenciadorNos.no_concluido(id: String)` | — (emitido para quem quiser escutar) |
| `GerenciadorNos.progresso_atualizado(id: String)` | `sistema_persistencia` |
| `GerenciadorNos.falha_de_requisito(id: String, motivo: String)` | — (emitido para quem quiser escutar) |
| `GerenciadorNarrativa.dia_iniciado(dia: int)` | `app_calendario`, `app_email`, `app_leitor_texto`, `app_mensageiro`, `area_de_trabalho`, `sistema_persistencia`, `widget_nexus` |
| `GerenciadorNarrativa.dia_encerrado(dia: int)` | — (emitido para quem quiser escutar) |
| `GerenciadorNarrativa.objetivos_atualizados()` | `widget_nexus` |
| `GerenciadorNarrativa.evento_disparado(id_evento: String)` | — (emitido para quem quiser escutar) |
| `GerenciadorNarrativa.jogo_finalizado(id_final: String)` | `area_de_trabalho`, `sistema_persistencia` |
| `GerenciadorNarrativa.processo_iniciado(pid: int)` | — (emitido para quem quiser escutar) |
| `GerenciadorNarrativa.processo_finalizado(pid: int, sucesso: bool)` | — (emitido para quem quiser escutar) |
| `GerenciadorNarrativa.abrir_app_solicitado(app_id: String)` | `area_de_trabalho` |
| `SistemaPersistencia.salvo(arquivo: String)` | — (emitido para quem quiser escutar) |
| `SistemaPersistencia.falha_ao_carregar(motivo: String)` | — (emitido para quem quiser escutar) |

### Dados (JSON em `res://core/data/`)

| Arquivo | Conteúdo |
|---|---|
| `core/data/catalogo_apps.json` | Catálogo dos aplicativos (id, nome, ícone, cena, tamanhos, dia de desbloqueio, condição). Lido por menu, barra de tarefas, atalhos e gerenciador de janelas. (válido) |
| `core/data/eventos.json` | — (válido) |
| `core/data/permissoes.json` | — (válido) |
| `core/data/regras.json` | — (válido) |
| `core/data/vfs_inicial.json` | Árvore inicial do sistema de arquivos virtual (pastas, arquivos, metadados, ocultos, criptografados, puzzles). (válido) |
| `core/data/narrativa/busca_web.json` | — (válido) |
| `core/data/narrativa/calendario.json` | Compromissos da agenda e como a Maya os altera/oculta/cancela. (válido) |
| `core/data/narrativa/conversas.json` | Contatos, mensagens (com dia, tipo e escolhas), respostas genéricas e respostas automáticas do Dia 4. (válido) |
| `core/data/narrativa/dias.json` | Dias 1–5: título, paleta, estado da IA, corrupção/segurança, apps liberados, objetivos, eventos e segredos. (válido) |
| `core/data/narrativa/emails.json` | E-mails por dia. (válido) |
| `core/data/narrativa/finais.json` | Os 4 finais e as 4 evidências usadas para a negociação. (válido) |
| `core/data/narrativa/instalacao_humaxos.json` | — (válido) |
| `core/data/narrativa/paginas_web.json` | Páginas `humax://` do navegador simulado por dia. (válido) |
| `core/data/narrativa/processos.json` | Processos maliciosos (duração, penalidades), processos do sistema simulados e multiplicadores de dificuldade. (válido) |
| `core/data/narrativa/reacoes_npc.json` | — (válido) |
| `core/data/narrativa/story_nodes.json` | — (válido) |
<!-- FIM_INDICE -->
