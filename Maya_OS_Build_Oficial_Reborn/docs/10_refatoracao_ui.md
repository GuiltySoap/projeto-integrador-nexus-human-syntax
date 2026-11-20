# 17. Refatoração da interface para cenas editáveis (relatório §18 e §20)

> Gerado em parte por `tools/gerar_docs_ui.py` (tabelas, árvores, contagens e a lista de critérios por aplicativo). O texto corrido é mantido à mão.

> **Atualização (2026-11-13).** O texto corrido desta página descreve a refatoração de 2026-11-09. As contagens, as árvores e os resultados dos testes foram refeitos com o código atual, que inclui as melhorias integradas de 2026-11-12 ([`11_melhorias_integradas.md`](11_melhorias_integradas.md)), o rebranding ([`12_rebranding_maya_human_syntax.md`](12_rebranding_maya_human_syntax.md)) e o fluxo Menu Principal / Pausa / Fim de Jogo ([`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md)). Todas as suítes foram reexecutadas na Godot 4.7.2 em 2026-11-13; a contagem de cenas e de nós já inclui as cenas novas.
## 1. Resultado

**Classificação: Refatoração concluída com ressalvas** (ressalvas na seção 12). O projeto roda na Godot 4.7.2 com a interface montada em cenas, os 9 autoloads e os contratos públicos preservados e as evidências abaixo.

| Critério | Evidência |
|---|---|
| Arquitetura preservada | 9 autoloads intactos; 0 scripts removidos; diferença de API pública na seção 6; `tools/validar_projeto.py`: 0 erros, 0 avisos |
| Interface no editor | 63 cenas de jogo com 955 nós (antes: 16 cenas com 25 nós). Chamadas `UiKit.*` de montagem: 455 → 0; `Classe.new()` de interface: 92 → 4 (justificados na seção 12); `add_child`: 530 → 26 |
| Scripts só com comportamento | 347 `@onready` e 64 `@export` em 84 scripts (antes: 0 e 0 em 55 scripts) |
| Funcionalidade | `tests/ui_interacao` no estado final: **554 verificações, 0 falhas.** |
| Editor sem avisos | varredura dos avisos de configuração de nó em todas as cenas (`tests/avisos_editor/varredura_editor.gd`): **58 avisos → 0** em 2026-11-09 e **63 cenas, 0 avisos** na rodada de 2026-11-13 (62 antes da Splash Screen: as 7 cenas novas do fluxo de sessão entram na conta, e a 63ª é a Splash) |
| Aparência preservada | árvore de nós de todas as cenas capturadas (retângulo, variação de tema, flags, fonte, texto) idêntica antes/depois da última correção. Em relação ao projeto original (capturas da janela em 2560×1440; área do jogo 1920×1080): rodada `final1`, 31 capturas com no máximo 0,50% de pixels diferentes (relógio, data e elementos animados), boot e tela final com 0,000%; rodada `depois3` (5 páginas de Configurações e Terminal): no máximo 0,24%. Depois da virada do dia do jogo (21h, UTC−3) a Agenda e o Terminal passam de 1% por causa da data (`final2`). Logs em `tests/_saida/` (ver `LEIA-ME.md` ali) |
| Resoluções | `tests/resolucoes`: 119 verificações, 0 falhas (4 proporções por SubViewport, com Menu Principal, Menu de Pausa e Tela de Fim de Jogo, + janelas reais 1280×720 e 1600×1000) — rodada de 2026-11-13, com o código atual (seção 11) |

## 2. Diagnóstico (§18.1)

Antes desta etapa, o projeto tinha a arquitetura por feature e o jogo completos, mas **toda a interface nascia em código**: 16 cenas com 25 nós (quase só a raiz com script), 455 chamadas `UiKit.*` e 92 `Classe.new()` de nós de interface, 530 `add_child`, 67 `add_theme_*_override` e nenhum `@onready`/`@export`. Consequências: o editor mostrava cenas vazias; nenhum layout podia ser ajustado visualmente; o estilo ficava espalhado em scripts; `UiKit` era um construtor global escondido; testes e revisões dependiam de ler código para saber o que existia.

## 3. Plano de migração (§18.2)

| Fase | Conteúdo | Situação |
|---|---|---|
| 1 | Baseline: capturas e árvores do projeto original (`antes`), convenções de nome/`@onready`/`@export` | concluída |
| 2 | Tema: `TemaNexus` + variações de rótulo geradas (`TemaVariacoes`), tema base exportado em `.tres` e ligado em `gui/theme/custom` | concluída |
| 3 | Componentes e shell (barra de tarefas, menu iniciar, notificações, widget, janela base, ícones, glitch, papel de parede) | concluída |
| 4 | Os 12 aplicativos | concluída |
| 5 | Diálogos modais, minigame lógico e puzzle da chave | concluída |
| 6 | Telas de boot e final (com cena de item das evidências) | concluída |
| 7 | Limpeza (`UiKit` reduzido a utilitários), testes automáticos, varredura de avisos do editor, documentação | concluída (ressalvas na seção 12) |

## 4. Estrutura de pastas (§18.3)

```text
features/
  apps/
    bloco_de_notas/   (1 cena)
    calculadora/   (1 cena)
    calendario/   (3 cenas)
    config/   (1 cena)
      components/
        cabecalho_pagina/   (1 cena)
        linha_check/   (1 cena)
        linha_opcao/   (1 cena)
        linha_slider/   (1 cena)
    email/   (2 cenas)
    explorador/   (1 cena)
    leitor_texto/   (1 cena)
    mensageiro/   (3 cenas)
      components/
        balao_chat/   (1 cena)
    monitor_sistema/   (2 cenas)
    navegador/   (1 cena)
    terminal/   (1 cena)
    visualizador/   (3 cenas)
  menu_principal/   (2 cenas)
  minigames/
    logica/   (1 cena)
      components/
        porta_logica_item/   (1 cena)
        slot_circuito/   (1 cena)
  narrative/
    finais/   (1 cena)
      components/
        item_evidencia/   (1 cena)
  pause/   (2 cenas)
  puzzles/
    arquivos_criptografados/   (1 cena)
    evento_processo/
  shell/
    area_de_trabalho/   (5 cenas)
    barra_de_tarefas/   (2 cenas)
    centro_notificacoes/   (2 cenas)
    data_e_hora/   (1 cena)
    efeito_glitch/   (1 cena)
    janela_inicial/   (3 cenas)
    popup_notificacao/   (2 cenas)
    tela_boot/   (1 cena)
    widget_nexus/   (2 cenas)
  splash_screen/   (1 cena)
    assets/
shared/ui/…   componentes compartilhados (janela_base, app_base, dialogo_nexus, icone_app, …)
shared/theme/tema_nexus_base.tres
core/autoload/   9 autoloads (sem interface)
core/utilities/  UiKit (utilitários), TemaNexus, TemaVariacoes, …
tests/, tools/
```

## 5. Contratos preservados

- **Autoloads (9), sem alteração de nome, ordem ou papel:** `RelogioGlobal`, `GerenciadorConfiguracoes`, `GerenciadorEstado`, `SistemaAudio`, `SistemaNotificacoes`, `SistemaArquivosVirtual`, `GerenciadorJanelas`, `GerenciadorNarrativa`, `SistemaPersistencia`. Nenhum cria nós de interface; as telas reagem aos sinais deles.
- **`AppBase`:** `iniciar(args)`, `receber_args(args)`, `pode_fechar()`, `confirmar_fechar()`, `ao_focar()`, `ao_fechar()`, `definir_titulo()`, `conectar()` e o sinal `titulo_alterado` continuam iguais.
- **`GerenciadorJanelas`:** `abrir_app`, `fechar_janela` etc. e o catálogo `core/data/catalogo_apps.json` (campo `cena`) inalterados; cada app continua sendo instanciado pelo gerenciador.
- **Dados, narrativa, salvamento e flags:** nenhum arquivo de `core/data/` foi alterado.

## 6. Relatório de mudanças de API

Comparação automática entre o projeto antes desta etapa e o atual: **0 scripts removidos, 0 sinais removidos ou renomeados, 19 scripts novos** (componentes e itens). Mudanças que afetam código que use esses nomes:

| # | Antigo → novo | Arquivos afetados | Motivo | Compatibilidade / migração | Risco |
|---|---|---|---|---|---|
| 1 | `UiKit.botao/rotulo/painel/linha/margem/rolagem/separador/rico/rotulo_quebra/caixa_h/caixa_v/cheio/espacador/expandir/icone_app/texto_alvo` removidos; novos `UiKit.refs_ok` e `UiKit.remover_itens` (ficam `escalar` e `limpar_filhos`) | `core/utilities/ui_kit.gd` e todas as telas | A interface passou a existir na cena | Quebra para quem chamava os construtores; dentro do projeto não resta nenhuma chamada (validador estático). Migração: criar o nó na cena ou instanciar uma cena de item | baixo (validador + testes) |
| 2 | `DialogoNexus.new()` + `montar(...)` / `montar_escolha(...)` → `DialogoNexus.criar(...)` / `criar_escolha(...)`; `DialogoArquivo.criar(modo, pasta, nome, extensões)`; `DialogoChave.criar(caminho)` (fábricas estáticas que instanciam a cena do diálogo); novo `DialogoNexus.mostrar_erro()` | `shared/ui/dialogo_nexus`, `shared/ui/dialogo_arquivo`, `dialogo_chave`; os chamadores públicos (`GerenciadorJanelas.alerta/confirmar/escolher_arquivo/...`) não mudaram | O diálogo é uma cena | `montar*` continuam públicos, mas `.new()` sozinho não cria os nós; usar `criar*`. Chamadores internos migrados | médio (grupo `dialogos` dos testes) |
| 3 | `MinigameLogica.new()` + `montar()` → `MinigameLogica.criar()` | `features/minigames/logica`, `dialogo_chave`/pasta protegida | Idem | `avaliar()` estático inalterado | baixo |
| 4 | `BalaoChat`, `SlotCircuito`, `PortaLogicaItem` deixam de ser construídos com `.new()`; `SlotCircuito.slot_id` passa a `@export` | mensageiro, minigame | Itens agora são cenas | `BalaoChat.configurar(entrada, largura_max)` mantido; instanciar a cena (`cena_balao` etc.) | baixo |
| 5 | Constantes públicas de layout/dados removidas dos scripts: `LOCAIS` (Explorador), `TECLAS` (Calculadora), `PAGINAS`/`ATALHOS`/`PERMISSOES`/`TAMANHOS_TEXTO` (Configurações), `ETIQUETAS_ESTADO`/`NOMES_SEMANA` (Agenda), `LARGURA_BARRA`/`LIMITE_TEXTO` (Mensageiro), `INTERVALO`, `INTERVALO_AUDIO`, `MARGEM`/`LARGURA`/`ALTURA`/`BORDA` (shell), `CODIGO_SHADER` (glitch) | scripts correspondentes | Os valores agora estão nas cenas (posições, textos dos botões) ou em `@export` | Nenhuma referência externa no projeto | baixo |
| 6 | `AppNavegador.ao_focar()` deixou de sobrescrever `AppBase.ao_focar()` | `app_navegador.gd` | O foco inicial é do campo na cena | Comportamento do hook herdado (vazio) | baixo |
| 7 | **Novo** `GerenciadorConfiguracoes.persistencia_habilitada` (padrão `true`) | autoload | Testes não podem gravar as preferências reais | Aditivo; padrão mantém o comportamento | baixo |
| 8 | Tamanhos mínimos de painéis e janelas deixam de ser multiplicados por `UiKit.escalar(tamanho do texto)` e viram `custom_minimum_size` fixo na cena | cenas de app/diálogo | Valor editável no inspetor | A fonte continua escalando pelo tema; só o tamanho mínimo da caixa não acompanha mais a escala do texto | médio-baixo (visual) |
| 9 | Novo `gui/theme/custom` em `project.godot` apontando para `shared/theme/tema_nexus_base.tres` | `project.godot` | O editor mostra as cenas estilizadas | Em jogo o tema de `TemaNexus.aplicar()` continua prevalecendo | baixo |
| 10 | Novos testes e ferramentas: `tests/avisos_editor`, `tests/exportar_tema`, `tests/resolucoes`; `tools/gerar_docs_ui.py` | — | Evidência de aceitação | Aditivo | nenhum |

## 7. Componentes reutilizáveis

| Cena | Raiz | API (exports / sinais / métodos públicos) |
|---|---|---|
| `features/apps/config/components/cabecalho_pagina/scenes/cabecalho_pagina.tscn` | VBoxContainer | exports: `titulo`, `subtitulo` |
| `features/apps/config/components/linha_check/scenes/linha_check.tscn` | VBoxContainer | exports: `chave`, `titulo`, `descricao`; sinais: `alternada`; métodos: `definir_ativa()`, `esta_ativa()` |
| `features/apps/config/components/linha_opcao/scenes/linha_opcao.tscn` | HBoxContainer | exports: `chave`, `titulo`, `rotulos`, `valores`; sinais: `valor_escolhido`; métodos: `definir_valor()` |
| `features/apps/config/components/linha_slider/scenes/linha_slider.tscn` | VBoxContainer | exports: `chave`, `titulo`; sinais: `valor_alterado`, `valor_confirmado`; métodos: `definir_valor()` |
| `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn` | HBoxContainer | exports: `variacao_bolha_propria`, `variacao_bolha_sistema`, `variacao_bolha_corrompida`, `variacao_bolha_padrao`, `variacao_texto`, `variacao_texto_sistema`, `variacao_etiqueta`, `variacao_etiqueta_perigo`; sinais: `original_visto`; métodos: `configurar()` |
| `features/minigames/logica/components/porta_logica_item/scenes/porta_logica_item.tscn` | Button | exports: `tipo_porta`; sinais: `escolhida`; métodos: `configurar()` |
| `features/minigames/logica/components/slot_circuito/scenes/slot_circuito.tscn` | PanelContainer | exports: `slot_id`; sinais: `porta_alterada`; métodos: `definir_porta()`, `limpar()` |
| `features/narrative/finais/components/item_evidencia/scenes/item_evidencia.tscn` | Label | métodos: `configurar()` |
| `shared/ui/dialogo_arquivo/scenes/dialogo_arquivo.tscn` | Control | sinais: `resolvido`; métodos: `criar()`, `montar()` |
| `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn` | Control | sinais: `resolvido`; métodos: `criar()`, `criar_escolha()`, `montar()`, `montar_escolha()`, `mostrar_erro()` |
| `shared/ui/icone_app/scenes/icone_app.tscn` | Control | exports: `lado`; métodos: `configurar()` |
| `shared/ui/indicador_carregamento/scenes/indicador_carregamento.tscn` | Control | métodos: `esta_aberto()`, `mostrar()`, `ocultar()` |
| `shared/ui/janela_base/scenes/janela_base.tscn` | Control | exports: `titulo`, `tamanho_min`, `pode_maximizar`; sinais: `pedido_fechar`, `pedido_minimizar`, `maximizada_alterada`, `movida`, `redimensionada`; métodos: `configurar()`, `definir_titulo()`, `definir_ativa()`, `definir_minimizada()`, `alternar_maximizar()`, `reajustar()` |
| `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn` | Control | métodos: `definir_estado()`, `reagir()` |
| `shared/ui/painel_confirmacao/scenes/painel_confirmacao.tscn` | Control | sinais: `confirmado`, `cancelado`; métodos: `esta_aberto()`, `perguntar()`, `fechar()` |
| `shared/ui/painel_opcoes/scenes/painel_opcoes.tscn` | Control | sinais: `fechado`; métodos: `esta_aberto()`, `abrir()`, `fechar()` |

## 8. Os 12 aplicativos (um por seção)

### Arquivos (`explorer`)

- **Função:** Navega pelo sistema de arquivos virtual (lugares, pastas, arquivos); abre, cria, renomeia e exclui itens.
- **Cena e script:** `features/apps/explorador/scenes/app_explorador.tscn` (32 nós, 14 com nome único); `features/apps/explorador/scripts/app_explorador.gd` (419 linhas, `AppExplorador` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppExplorador (Control + app_explorador.gd)
    Raiz (VBoxContainer)
      BarraNavegacao (HBoxContainer)
        %BotaoVoltar (Button)
        %BotaoAvancar (Button)
        %BotaoAcima (Button)
        %CampoCaminho (LineEdit)
        %CampoFiltro (LineEdit)
      BarraAcoes (HBoxContainer)
        %BotaoAbrir (Button)
        %BotaoNovoArquivo (Button)
        %BotaoNovaPasta (Button)
        %BotaoRenomear (Button)
        %BotaoExcluir (Button)
        %BotaoRestaurar (Button)
        Espacador (Control)
        %CaixaOcultos (CheckBox)
      Corpo (HBoxContainer)
        PainelLocais (PanelContainer)
        %Lista (ItemList)
      %RotuloStatus (Label)
  ```
- **Nós importantes (nome único):** `%BotaoVoltar` (Button), `%BotaoAvancar` (Button), `%BotaoAcima` (Button), `%CampoCaminho` (LineEdit), `%CampoFiltro` (LineEdit), `%BotaoAbrir` (Button), `%BotaoNovoArquivo` (Button), `%BotaoNovaPasta` (Button), `%BotaoRenomear` (Button), `%BotaoExcluir` (Button), `%BotaoRestaurar` (Button), `%CaixaOcultos` (CheckBox), `%Lista` (ItemList), `%RotuloStatus` (Label)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `caminho`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (24):** `empty_clicked` de `Raiz/Corpo/Lista` → `_ao_clique_vazio`; `gui_input` de `Raiz/Corpo/Lista` → `_ao_entrada_lista`; `item_activated` de `Raiz/Corpo/Lista` → `_ao_item_ativado`; `item_selected` de `Raiz/Corpo/Lista` → `_ao_item_selecionado`; `pressed` de `Raiz/BarraAcoes/BotaoAbrir` → `_ao_abrir_selecionado`; `pressed` de `Raiz/BarraNavegacao/BotaoAcima` → `_ao_acima`; `pressed` de `Raiz/BarraNavegacao/BotaoAvancar` → `_ao_avancar`; `pressed` de `Raiz/BarraAcoes/BotaoExcluir` → `_ao_excluir`; `pressed` → `_ao_local` (8); `pressed` de `Raiz/BarraAcoes/BotaoNovaPasta` → `_ao_nova_pasta` … +7 grupos
- **Sinais conectados em código:** 4 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** nenhum
- **Conteúdo dinâmico mantido:** nenhum: toda a interface é estática na cena.
- **Lógica removida do script:** antes, 21 chamadas `UiKit.*`, 2 `Classe.new()` de interface e 17 `add_child`; depois, 0 `.new()` de interface. O script passou de 489 para 419 linhas.
- **Dependências:** autoloads `GerenciadorEstado`, `SistemaNotificacoes`, `SistemaArquivosVirtual`, `GerenciadorJanelas`; cenas de componente/item: nenhuma.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `explorador`, 63 verificações, todas OK no último log):
  - o app explorer abre em uma janela
  - explorador: os nós da cena existem
  - explorador: abre na pasta do usuário (/home/usuario | Arquivos — usuario)
  - explorador: a lista mostra os itens visíveis da pasta (6)
  - explorador: sem histórico, Voltar e Avançar ficam desabilitados e Pasta acima habilitado
  - explorador: sem seleção, Abrir, Renomear e Excluir ficam desabilitados e Restaurar escondido
  - explorador: o rodapé conta os itens (6 item(ns) em /home/usuario)
  - explorador: 'Mostrar ocultos' começa bloqueado pelo administrador
  - explorador: dicas e botão de limpar definidos na cena
  - explorador: o atalho Documentos navega (/home/usuario/Documentos)
  - explorador: Documentos lista tarefas.txt e os demais itens
  - explorador: visitar a pasta registra o objetivo pasta_visitada
  - explorador: depois de navegar, Voltar habilita e Avançar continua desabilitado
  - explorador: Voltar retorna à pasta anterior e habilita Avançar
  - explorador: Avançar volta para Documentos
  - explorador: Pasta acima sobe um nível
  - explorador: caminho digitado + Enter abre a pasta
  - explorador: caminho inexistente avisa e restaura o campo (Pasta não encontrada: /nao/existe)
  - explorador: item protegido não pode ser renomeado nem excluído, mas pode ser aberto
  - explorador: item comum habilita Renomear e Excluir e mostra os detalhes no rodapé
  - explorador: clicar no vazio limpa a seleção
  - explorador: o filtro mostra só o que combina com o termo
  - explorador: filtro sem resultado deixa a lista vazia
  - explorador: limpar o filtro devolve todos os itens
  - explorador: trocar de pasta zera o filtro
  - explorador: duplo clique em um arquivo abre o Bloco de Notas
  - explorador: duplo clique em uma pasta entra nela
  - explorador: seleciona read_me.txt
  - explorador: o botão Abrir abre o item selecionado
  - explorador: '＋ Arquivo' abre o diálogo de nome
  - explorador: cancelar o diálogo não cria nada
  - explorador: nome com caractere proibido mostra o alerta 'Nome inválido'
  - explorador: o arquivo foi criado no VFS
  - explorador: o arquivo novo aparece na lista já selecionado
  - explorador: '＋ Pasta' abre o diálogo de nome
  - explorador: a pasta foi criada e aparece na lista
  - explorador: nome repetido mostra o alerta 'Não foi possível criar'
  - explorador: Renomear abre o diálogo com o nome atual
  - explorador: o item foi renomeado no VFS
  - explorador: o item renomeado fica selecionado na lista
  - explorador: renomear para um nome existente mostra o alerta
  - explorador: F2 na lista abre Renomear
  - explorador: cancelar o Renomear mantém o nome
  - explorador: Backspace na lista sobe uma pasta
  - explorador: Alt+← volta no histórico
  - explorador: Alt+→ avança no histórico
  - explorador: Del na lista pede confirmação
  - explorador: cancelar a exclusão mantém o arquivo
  - explorador: confirmar move o arquivo para a Lixeira
  - explorador: a lista atualiza sozinha (sinal arvore_alterada do VFS)
  - explorador: na Lixeira aparece Restaurar, some Excluir e criar fica desabilitado
  - explorador: item protegido da Lixeira não pode ser restaurado
  - explorador: item da Lixeira pode ser restaurado
  - explorador: Restaurar devolve o arquivo à pasta de origem e atualiza a lista
  - explorador: a flag da narrativa libera 'Mostrar ocultos'
  - explorador: ocultos aparecem marcados com '(oculto)'
  - explorador: exibir um item oculto registra o objetivo ocultos_revelados
  - explorador: desmarcar esconde os ocultos de novo
  - explorador: a pasta PROJECT_Icarus bloqueada abre o minigame de lógica
  - explorador: sem resolver o minigame, a janela continua na pasta anterior (Arquivos — sistema)
  - explorador: com o puzzle resolvido a pasta abre
  - explorador: nenhum diálogo ficou aberto
  - explorador: ao fechar, a janela some e as ligações com os autoloads são desfeitas

### Bloco de Notas (`text_editor`)

- **Função:** Edita arquivos de texto do sistema virtual (novo, abrir, salvar, salvar como, aviso de alterações não salvas).
- **Cena e script:** `features/apps/bloco_de_notas/scenes/app_bloco_de_notas.tscn` (13 nós, 5 com nome único); `features/apps/bloco_de_notas/scripts/app_bloco_de_notas.gd` (303 linhas, `AppBlocoDeNotas` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppBlocoDeNotas (Control + app_bloco_de_notas.gd)
    Raiz (VBoxContainer)
      Barra (HBoxContainer)
        BotaoNovo (Button)
        BotaoAbrir (Button)
        BotaoSalvar (Button)
        BotaoSalvarComo (Button)
        %RotuloArquivo (Label)
      %RotuloAviso (Label, oculto)
      %Editor (TextEdit)
      Rodape (HBoxContainer)
        %RotuloEstado (Label)
        %RotuloPosicao (Label)
  ```
- **Nós importantes (nome único):** `%RotuloArquivo` (Label), `%RotuloAviso` (Label), `%Editor` (TextEdit), `%RotuloEstado` (Label), `%RotuloPosicao` (Label)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `caminho`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (7):** `caret_changed` de `Raiz/Editor` → `_atualizar_posicao`; `gui_input` de `Raiz/Editor` → `_ao_entrada_editor`; `pressed` de `Raiz/Barra/BotaoAbrir` → `_ao_abrir`; `pressed` de `Raiz/Barra/BotaoNovo` → `_ao_novo`; `pressed` de `Raiz/Barra/BotaoSalvar` → `_ao_salvar`; `pressed` de `Raiz/Barra/BotaoSalvarComo` → `_ao_salvar_como`; `text_changed` de `Raiz/Editor` → `_ao_texto_alterado`
- **Sinais conectados em código:** 1 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** nenhum
- **Conteúdo dinâmico mantido:** nenhum: toda a interface é estática na cena.
- **Lógica removida do script:** antes, 11 chamadas `UiKit.*`, 1 `Classe.new()` de interface e 12 `add_child`; depois, 0 `.new()` de interface. O script passou de 336 para 303 linhas.
- **Dependências:** autoloads `RelogioGlobal`, `SistemaAudio`, `SistemaArquivosVirtual`, `GerenciadorJanelas`; cenas de componente/item: nenhuma.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `bloco_de_notas`, 30 verificações, todas OK no último log):
  - o app text_editor abre em uma janela
  - bloco de notas: os nós da cena existem
  - bloco de notas: abre com um documento novo, editável e sem aviso
  - bloco de notas: o rodapé mostra a posição e o documento vazio pode ser fechado
  - bloco de notas: o título da janela mostra o arquivo (Bloco de Notas — sem_titulo.txt)
  - bloco de notas: o editor tem o texto de dica definido na cena
  - bloco de notas: digitar marca o documento como alterado (● e *)
  - bloco de notas: com alterações não salvas, pode_fechar() é falso
  - bloco de notas: o rodapé acompanha o cursor (Ln 1, Col 4 · 3 caracteres)
  - bloco de notas: Salvar como… abre o diálogo de arquivos
  - bloco de notas: o arquivo foi criado no VFS com o texto digitado
  - bloco de notas: depois de salvar, a marca de alteração some
  - bloco de notas: o rodapé confirma o salvamento (Salvo às 21:10:48.)
  - bloco de notas: o título passa a mostrar o novo nome
  - bloco de notas: editar um arquivo salvo volta a marcar alteração
  - bloco de notas: Ctrl+S (sinal gui_input do editor) grava o arquivo
  - bloco de notas: o botão Salvar regrava o arquivo existente
  - bloco de notas: Abrir… mostra o diálogo de arquivos
  - bloco de notas: o arquivo escolhido é carregado no editor
  - bloco de notas: cancelar o diálogo de Abrir não muda nada
  - bloco de notas: Novo cria um documento vazio
  - bloco de notas: arquivo protegido abre em somente leitura, com o aviso visível
  - bloco de notas: Salvar em arquivo protegido mostra o alerta de somente leitura
  - bloco de notas: o alerta fecha ao responder
  - bloco de notas: abrir um arquivo comum esconde o aviso e libera a edição
  - bloco de notas: fechar com alterações pergunta se deseja salvar
  - bloco de notas: o diálogo oferece Salvar, Descartar e Continuar editando
  - bloco de notas: 'Continuar editando' mantém a janela aberta com o texto
  - bloco de notas: fechar de novo repete a pergunta
  - bloco de notas: 'Descartar' fecha a janela

### Mensagens (`messenger`)

- **Função:** Conversas com a Maya e os contatos: lista de contatos, balões de mensagem, opções de resposta, bloqueio e mensagens editadas/ocultas conforme o dia.
- **Cena e script:** `features/apps/mensageiro/scenes/app_mensageiro.tscn` (23 nós, 11 com nome único); `features/apps/mensageiro/scripts/app_mensageiro.gd` (288 linhas, `AppMensageiro` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppMensageiro (Control + app_mensageiro.gd)
    Raiz (HBoxContainer)
      BarraContatos (PanelContainer)
        Margem (MarginContainer)
      %PainelConversa (VBoxContainer)
        Cabecalho (PanelContainer)
        AreaMensagens (PanelContainer)
        %AreaEscolhas (VBoxContainer, oculto)
        %RotuloDica (Label, oculto)
        Compositor (HBoxContainer)
  ```
- **Nós importantes (nome único):** `%ListaContatos` (VBoxContainer), `%PainelConversa` (VBoxContainer), `%RotuloNome` (Label), `%RotuloStatus` (Label), `%Rolagem` (ScrollContainer), `%ListaMensagens` (VBoxContainer), `%RotuloVazio` (Label), `%AreaEscolhas` (VBoxContainer), `%RotuloDica` (Label), `%Campo` (LineEdit), `%BotaoEnviar` (Button)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `contato`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (2):** `pressed` de `Raiz/PainelConversa/Compositor/BotaoEnviar` → `_ao_enviar`; `text_submitted` de `Raiz/PainelConversa/Compositor/Campo` → `_ao_texto_enviado`
- **Sinais conectados em código:** 7 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** `cena_contato: PackedScene`, `cena_balao: PackedScene`, `cena_escolha: PackedScene`
- **Conteúdo dinâmico mantido:** instancia, a partir de `PackedScene` exportada, `cena_balao`, `cena_contato`, `cena_escolha` dentro de containers que já existem na cena.
- **Lógica removida do script:** antes, 22 chamadas `UiKit.*`, 0 `Classe.new()` de interface e 17 `add_child`; depois, 0 `.new()` de interface. O script passou de 326 para 288 linhas.
- **Dependências:** autoloads `GerenciadorEstado`, `GerenciadorJanelas`, `GerenciadorNarrativa`; cenas de componente/item: `balao_chat.tscn`, `item_contato.tscn`, `item_escolha.tscn`.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `mensageiro`, 61 verificações, todas OK no último log):
  - o app messenger abre em uma janela
  - mensageiro: os nós essenciais existem com nome único
  - mensageiro: uma linha da lista por contato disponível (4)
  - mensageiro: o campo de texto vem configurado pela cena (limite 500, dica)
  - mensageiro: o aviso de bloqueio e as escolhas começam ocultos
  - mensageiro: existe a linha do contato nexus
  - mensageiro: abrir nexus mostra o nome e o status
  - mensageiro: nexus mostra um balão por mensagem (0) e o aviso de conversa vazia só sem mensagens
  - mensageiro: nexus fica como conversa ativa e é marcada como lida
  - mensageiro: a linha de nexus fica marcada na lista
  - mensageiro: existe a linha do contato lucas
  - mensageiro: abrir lucas mostra o nome e o status
  - mensageiro: lucas mostra um balão por mensagem (0) e o aviso de conversa vazia só sem mensagens
  - mensageiro: lucas fica como conversa ativa e é marcada como lida
  - mensageiro: a linha de lucas fica marcada na lista
  - mensageiro: existe a linha do contato bia
  - mensageiro: abrir bia mostra o nome e o status
  - mensageiro: bia mostra um balão por mensagem (0) e o aviso de conversa vazia só sem mensagens
  - mensageiro: bia fica como conversa ativa e é marcada como lida
  - mensageiro: a linha de bia fica marcada na lista
  - mensageiro: existe a linha do contato mae
  - mensageiro: abrir mae mostra o nome e o status
  - mensageiro: mae mostra um balão por mensagem (0) e o aviso de conversa vazia só sem mensagens
  - mensageiro: mae fica como conversa ativa e é marcada como lida
  - mensageiro: a linha de mae fica marcada na lista
  - mensageiro: mensagem só com espaços não é enviada
  - mensageiro: Enviar põe um balão novo na conversa e limpa o campo
  - mensageiro: o último balão existe
  - mensageiro: a mensagem do jogador fica alinhada à direita com o texto digitado
  - mensageiro: o balão do jogador usa a variação BolhaPropria do tema
  - mensageiro: o balão mostra a hora e esconde a etiqueta e o botão 'Ver original'
  - mensageiro: Enter no campo também envia a mensagem
  - mensageiro: contato bloqueado mostra o aviso e o status de bloqueio
  - mensageiro: a lista marca o contato bloqueado com 🚫 e a flag da pista é gravada
  - mensageiro: o aviso de bloqueio some em outra conversa
  - mensageiro: uma mensagem com escolhas pendentes mostra um botão por opção (2)
  - mensageiro: os botões trazem o texto das opções
  - mensageiro: escolher grava a flag e some com os botões de resposta
  - mensageiro: a fala escolhida aparece como balão do jogador
  - mensageiro: a mensagem do Dia 5 chegou à conversa aberta
  - mensageiro: mensagem corrompida mostra a etiqueta em vermelho
  - mensageiro: o balão corrompido usa a variação BolhaCorrompida
  - mensageiro: a escolha final mostra os dois botões
  - mensageiro: aceitar a transferência de controle pede confirmação explícita
  - mensageiro: a confirmação explica a sincronização e a transferência permanente de controle
  - mensageiro: a confirmação não usa o rótulo de roteiro 'Assimilação'
  - mensageiro: a confirmação tem 'Confirmar sincronização' (perigo) e 'Voltar'
  - mensageiro: o foco inicial fica em 'Voltar' (um Enter acidental não confirma)
  - mensageiro: clicar fora do painel não decide a confirmação
  - mensageiro: Esc cancela a confirmação sem gravar a escolha
  - mensageiro: os botões de resposta continuam depois de cancelar
  - mensageiro: a confirmação abre de novo ao repetir a escolha
  - mensageiro: Enter com o foco inicial ('Voltar') cancela em vez de confirmar
  - mensageiro: cancelar a confirmação não grava a escolha e mantém os botões
  - mensageiro: a Maya consegue editar a última mensagem do jogador
  - mensageiro: a conversa é refeita com o balão editado
  - mensageiro: o balão mostra o texto novo e a etiqueta ✎ editada
  - mensageiro: o botão 'Ver original' aparece só em mensagem editada
  - mensageiro: 'Ver original' revela o texto anterior e grava a flag da pista
  - mensageiro: apertar de novo volta ao texto editado
  - mensageiro: fechar o app limpa a conversa ativa

### E-mail (`email`)

- **Função:** Caixa de entrada: lista de e-mails, leitura, marcação de lido e conteúdo condicionado ao dia e às flags da história.
- **Cena e script:** `features/apps/email/scenes/app_email.tscn` (18 nós, 6 com nome único); `features/apps/email/scripts/app_email.gd` (111 linhas, `AppEmail` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppEmail (Control + app_email.gd)
    Raiz (HBoxContainer)
      PainelLista (PanelContainer)
        Margem (MarginContainer)
      Leitura (VBoxContainer)
        Cabecalho (PanelContainer)
        PainelCorpo (PanelContainer)
        RotuloAviso (Label)
  ```
- **Nós importantes (nome único):** `%Lista` (VBoxContainer), `%RotuloVazio` (Label), `%RotuloAssunto` (Label), `%RotuloDe` (Label), `%RotuloDia` (Label), `%Corpo` (RichTextLabel)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `id`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (0):** nenhum
- **Sinais conectados em código:** 2 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** `cena_item: PackedScene`
- **Conteúdo dinâmico mantido:** instancia, a partir de `PackedScene` exportada, `cena_item` dentro de containers que já existem na cena.
- **Lógica removida do script:** antes, 16 chamadas `UiKit.*`, 0 `Classe.new()` de interface e 11 `add_child`; depois, 0 `.new()` de interface. O script passou de 135 para 111 linhas.
- **Dependências:** autoloads `GerenciadorEstado`, `GerenciadorNarrativa`; cenas de componente/item: `item_email.tscn`.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `email`, 11 verificações, todas OK no último log):
  - o app email abre em uma janela
  - e-mail: os nós essenciais existem com nome único
  - e-mail: há pelo menos 2 e-mails no dia de teste (3)
  - e-mail: um item da lista por e-mail disponível
  - e-mail: o aviso 'Nenhum e-mail' fica oculto quando há e-mails
  - e-mail: clicar num item mostra o assunto dele
  - e-mail: clicar num item mostra o remetente
  - e-mail: ler o e-mail grava a flag email_lido
  - e-mail: o item do e-mail aberto fica marcado na lista
  - e-mail: depois de lido, o item perde a marca NOVO
  - e-mail: receber_args({id}) abre o e-mail pedido

### Galeria (`media_viewer`)

- **Função:** Galeria de imagens e áudio com painel de metadados (puzzle da foto) e player de áudio simulado.
- **Cena e script:** `features/apps/visualizador/scenes/app_visualizador.tscn` (21 nós, 14 com nome único); `features/apps/visualizador/scripts/app_visualizador.gd` (290 linhas, `AppVisualizador` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppVisualizador (Control + app_visualizador.gd)
    Raiz (VBoxContainer)
      Topo (HBoxContainer)
        %BotaoAnterior (Button)
        %BotaoProximo (Button)
        %RotuloNome (Label)
        %BotaoMeta (Button)
      PainelImagem (PanelContainer)
        %Imagem (TextureRect)
      %CaixaAudio (VBoxContainer, oculto)
        TituloAudio (Label)
        LinhaAudio (HBoxContainer)
      %RotuloLegenda (Label)
      %PainelMeta (PanelContainer, oculto)
        Margem (MarginContainer)
    %Tocador (AudioStreamPlayer)
    %Temporizador (Timer)
  ```
- **Nós importantes (nome único):** `%BotaoAnterior` (Button), `%BotaoProximo` (Button), `%RotuloNome` (Label), `%BotaoMeta` (Button), `%Imagem` (TextureRect), `%CaixaAudio` (VBoxContainer), `%BotaoTocar` (Button), `%BarraAudio` (ProgressBar), `%RotuloAudio` (Label), `%RotuloLegenda` (Label), `%PainelMeta` (PanelContainer), `%GradeMeta` (GridContainer), `%Tocador` (AudioStreamPlayer), `%Temporizador` (Timer)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `caminho`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (6):** `finished` de `Tocador` → `_ao_audio_terminou`; `pressed` de `Raiz/CaixaAudio/LinhaAudio/BotaoTocar` → `_ao_alternar_audio`; `pressed` de `Raiz/Topo/BotaoMeta` → `_ao_alternar_meta`; `pressed` de `Raiz/Topo/BotaoAnterior` → `_ao_anterior`; `pressed` de `Raiz/Topo/BotaoProximo` → `_ao_proximo`; `timeout` de `Temporizador` → `_atualizar_progresso`
- **Sinais conectados em código:** 0 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** `cena_meta_chave: PackedScene`, `cena_meta_valor: PackedScene`
- **Conteúdo dinâmico mantido:** instancia, a partir de `PackedScene` exportada, `cena_meta_chave`, `cena_meta_valor` dentro de containers que já existem na cena.
- **Lógica removida do script:** antes, 17 chamadas `UiKit.*`, 3 `Classe.new()` de interface e 20 `add_child`; depois, 0 `.new()` de interface. O script passou de 339 para 290 linhas.
- **Dependências:** autoloads `GerenciadorConfiguracoes`, `GerenciadorEstado`, `SistemaAudio`, `SistemaArquivosVirtual`; cenas de componente/item: `rotulo_meta_chave.tscn`, `rotulo_meta_valor.tscn`.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `visualizador`, 31 verificações, todas OK no último log):
  - visualizador: a pasta Imagens tem pelo menos 2 mídias no VFS (3)
  - o app media_viewer abre em uma janela
  - visualizador: os nós essenciais existem com nome único
  - visualizador: sem argumentos, abre a primeira mídia da pasta Imagens (Cachorro.jpg)
  - visualizador: uma imagem aparece e os controles de áudio ficam ocultos
  - visualizador: o painel de metadados começa fechado e o botão fica habilitado
  - visualizador: ◀ e ▶ ficam habilitados quando há várias mídias na pasta
  - visualizador: o Tocador da cena usa o barramento SFX, que existe
  - visualizador: o Temporizador da cena (0,1 s) só roda durante o áudio
  - visualizador: ▶ percorre todas as mídias da pasta sem repetir (Cachorro.jpg, data_stream.png, Show_Antigo.jpg)
  - visualizador: ▶ na última volta para a primeira
  - visualizador: ◀ na primeira vai para a última
  - visualizador: receber_args({caminho}) abre o arquivo pedido
  - visualizador: a legenda mostra a descrição do metadado
  - visualizador: antes de abrir o painel, a pista dos metadados ainda não foi vista
  - visualizador: o botão de metadados abre o painel
  - visualizador: o painel tem uma linha (2 células) por campo (16 células)
  - visualizador: a primeira linha do painel é Nome / Show_Antigo.jpg
  - visualizador: as células usam as cenas de rótulo (chave destacada, valor normal)
  - visualizador: abrir os metadados grava a flag da pista do Dia 3
  - visualizador: o mesmo botão fecha o painel
  - visualizador: reabrir o painel não duplica as células
  - visualizador: um áudio mostra os controles de reprodução no lugar da imagem
  - visualizador: trocar de arquivo fecha o painel de metadados
  - visualizador: a gravação procedural gravacao_01 existe
  - visualizador: o botão tocar fica habilitado e o contador mostra a duração (0:00 / 0:03)
  - visualizador: ▶ Reproduzir toca o áudio e liga o Temporizador da cena
  - visualizador: ■ Parar interrompe o áudio e zera a barra
  - visualizador: trocar de arquivo com o áudio tocando para a reprodução
  - visualizador: arquivo inexistente mostra o aviso e desabilita os botões
  - visualizador: arquivo de texto mostra o aviso de formato não suportado

### Agenda (`calendar`)

- **Função:** Agenda: grade mensal, compromissos (alterados, ocultos, cancelados, de emergência) e lista do dia.
- **Cena e script:** `features/apps/calendario/scenes/app_calendario.tscn` (24 nós, 6 com nome único); `features/apps/calendario/scripts/app_calendario.gd` (188 linhas, `AppCalendario` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppCalendario (Control + app_calendario.gd)
    Raiz (VBoxContainer)
      PainelAgora (PanelContainer)
        Margem (MarginContainer)
      Navegacao (HBoxContainer)
        BotaoMesAnterior (Button)
        %RotuloMes (Label)
        BotaoMesSeguinte (Button)
        BotaoHoje (Button)
      %Grade (GridContainer)
        CabDom (Label)
        CabSeg (Label)
        CabTer (Label)
        CabQua (Label)
        CabQui (Label)
        CabSex (Label)
        CabSab (Label)
      %RotuloTituloLista (Label)
      PainelCompromissos (PanelContainer)
        Rolagem (ScrollContainer)
  ```
- **Nós importantes (nome único):** `%RotuloAgora` (Label), `%RotuloMes` (Label), `%Grade` (GridContainer), `%RotuloTituloLista` (Label), `%Lista` (VBoxContainer), `%RotuloVazio` (Label)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); este app não lê chaves específicas.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (3):** `pressed` de `Raiz/Navegacao/BotaoMesAnterior` → `_ao_mes_anterior`; `pressed` de `Raiz/Navegacao/BotaoMesSeguinte` → `_ao_mes_seguinte`; `pressed` de `Raiz/Navegacao/BotaoHoje` → `_ir_para_hoje`
- **Sinais conectados em código:** 4 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** `cena_dia: PackedScene`, `cena_compromisso: PackedScene`
- **Conteúdo dinâmico mantido:** instancia, a partir de `PackedScene` exportada, `cena_compromisso`, `cena_dia` dentro de containers que já existem na cena; ainda cria 1 nó(s) de interface por código (ver ressalvas).
- **Lógica removida do script:** antes, 24 chamadas `UiKit.*`, 1 `Classe.new()` de interface e 20 `add_child`; depois, 1 `.new()` de interface. O script passou de 239 para 188 linhas.
- **Dependências:** autoloads `RelogioGlobal`, `GerenciadorEstado`, `GerenciadorNarrativa`; cenas de componente/item: `cartao_compromisso.tscn`, `item_dia_calendario.tscn`.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `calendario`, 15 verificações, todas OK no último log):
  - o app calendar abre em uma janela
  - calendário: os nós essenciais existem
  - calendário: o mês mostra de 28 a 31 dias (30)
  - calendário: o cabeçalho dom..sáb existe na cena (7 rótulos)
  - calendário: o cartão mostra a data fictícia de hoje
  - calendário: o dia de hoje fica marcado e selecionado
  - calendário: um cartão por compromisso do dia (1)
  - calendário: o aviso 'Sem compromissos' fica oculto quando há compromissos
  - calendário: o botão ▶ muda o mês (Dezembro de 2026)
  - calendário: o botão ◀ volta ao mês anterior
  - calendário: o botão Hoje volta ao mês de hoje
  - calendário: clicar num dia atualiza o título da lista
  - calendário: um dia sem compromissos mostra o aviso
  - calendário: o dia 1 da história aparece como '● Dia 1'
  - calendário: clicar num dia da história mostra o número do dia

### Calculadora (`calculator`)

- **Função:** Calculadora com visor e teclado; não avalia expressões arbitrárias.
- **Cena e script:** `features/apps/calculadora/scenes/app_calculadora.tscn` (29 nós, 3 com nome único); `features/apps/calculadora/scripts/app_calculadora.gd` (290 linhas, `AppCalculadora` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppCalculadora (Control + app_calculadora.gd)
    Raiz (VBoxContainer)
      Visor (PanelContainer)
        Margem (MarginContainer)
      Teclado (GridContainer)
        TeclaLimpar (Button)
        TeclaApagar (Button)
        TeclaPercentual (Button)
        TeclaDividir (Button)
        Tecla7 (Button)
        Tecla8 (Button)
        Tecla9 (Button)
        TeclaMultiplicar (Button)
        Tecla4 (Button)
        Tecla5 (Button)
        Tecla6 (Button)
        TeclaSubtrair (Button)
        Tecla1 (Button)
        Tecla2 (Button)
        Tecla3 (Button)
        TeclaSomar (Button)
        TeclaSinal (Button)
        Tecla0 (Button)
        TeclaDecimal (Button)
        TeclaIgual (Button)
  ```
- **Nós importantes (nome único):** `%RotuloHistorico` (Label), `%RotuloExpressao` (Label), `%RotuloResultado` (Label)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); este app não lê chaves específicas.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (20):** `pressed` → `_ao_tecla` (20)
- **Sinais conectados em código:** 0 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** nenhum
- **Conteúdo dinâmico mantido:** nenhum: toda a interface é estática na cena.
- **Lógica removida do script:** antes, 8 chamadas `UiKit.*`, 1 `Classe.new()` de interface e 7 `add_child`; depois, 0 `.new()` de interface. O script passou de 321 para 290 linhas.
- **Dependências:** autoloads `SistemaAudio`, `GerenciadorJanelas`; cenas de componente/item: nenhuma.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `calculadora`, 31 verificações, todas OK no último log):
  - o app calculator abre em uma janela
  - calculadora: o visor e o teclado existem na cena
  - calculadora: o teclado tem 20 teclas em 4 colunas (20)
  - calculadora: todas as teclas têm o sinal pressed ligado na cena
  - calculadora: as teclas de operação têm dica (tooltip)
  - calculadora: o visor começa em 0, com o texto grande
  - calculadora: 7 + 5 = 12 (visor mostra 12)
  - calculadora: a expressão e o histórico registram a conta
  - calculadora: continuar a conta a partir do resultado (12 + 3 = 15)
  - calculadora: dividir por zero mostra o erro em vermelho
  - calculadora: o erro limpa a expressão
  - calculadora: digitar depois do erro recomeça e volta ao texto normal
  - calculadora: C zera o visor e a expressão
  - calculadora: a vírgula decimal funciona
  - calculadora: ± troca o sinal
  - calculadora: ⌫ apaga o último dígito (-1,)
  - calculadora: ⌫ até esvaziar volta a 0
  - calculadora: 50% sozinho vale 0,5
  - calculadora: 200 + 10% = 220 (percentual sobre o acumulado)
  - calculadora: o histórico usa o símbolo × (2 × 4 = 8)
  - calculadora: o histórico guarda só as 4 últimas contas
  - calculadora: com 12 dígitos o visor reduz o texto (médio)
  - calculadora: com 17 caracteres o visor reduz mais (pequeno)
  - calculadora: o 17º dígito é ignorado (limite de 16 dígitos)
  - calculadora: C devolve o texto ao tamanho grande
  - calculadora: o teclado físico digita 8 * 3 Enter = 24 (visor 24)
  - calculadora: Esc limpa o visor
  - calculadora: o teclado físico digita 7 depois de limpar
  - calculadora: Delete limpa o visor
  - calculadora: a API estática AppCalculadora.calcular continua igual
  - calculadora: a API estática AppCalculadora.formatar continua igual

### Configurações (`settings`)

- **Função:** Configurações: personalização, áudio, acessibilidade, privacidade/permissões e sistema.
- **Cena e script:** `features/apps/config/scenes/app_config.tscn` (100 nós, 13 com nome único); `features/apps/config/scripts/app_config.gd` (324 linhas, `AppConfig` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppConfig (Control + app_config.gd)
    Raiz (HBoxContainer)
      PainelMenu (PanelContainer)
        Margem (MarginContainer)
      Conteudo (Control)
        %PaginaPersonalizacao (ScrollContainer)
        %PaginaAudio (ScrollContainer, oculto)
        %PaginaAcessibilidade (ScrollContainer, oculto)
        %PaginaPrivacidade (ScrollContainer, oculto)
        %PaginaSistema (ScrollContainer, oculto)
  ```
- **Nós importantes (nome único):** `%BotaoPersonalizacao` (Button), `%BotaoAudio` (Button), `%BotaoAcessibilidade` (Button), `%BotaoPrivacidade` (Button), `%BotaoSistema` (Button), `%PaginaPersonalizacao` (ScrollContainer), `%PaginaAudio` (ScrollContainer), `%PaginaAcessibilidade` (ScrollContainer), `%PaginaPrivacidade` (ScrollContainer), `%RotuloMonitoramento` (Label), `%ListaPermissoes` (VBoxContainer), `%PaginaSistema` (ScrollContainer), `%RotuloSistema` (Label)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `pagina`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (34):** `alternada` → `_ao_alternar` (7); `alternada` → `_ao_permissao_alternada` (4); `pressed` de `Raiz/Conteudo/PaginaAcessibilidade/Margem/Caixa/BarraConforto/BotaoAtivarConforto` → `_ao_ativar_conforto`; `pressed` de `Raiz/Conteudo/PaginaAcessibilidade/Margem/Caixa/BarraConforto/BotaoDesativarConforto` → `_ao_desativar_conforto`; `pressed` de `Raiz/Conteudo/PaginaPrivacidade/Margem/Caixa/BarraPermissoes/BotaoDesativarTodas` → `_ao_desativar_todas`; `pressed` de `Raiz/Conteudo/PaginaPrivacidade/Margem/Caixa/BarraPermissoes/BotaoReativarTodas` → `_ao_reativar_todas`; `pressed` de `Raiz/Conteudo/PaginaAcessibilidade/Margem/Caixa/BarraConforto/BotaoRestaurarPadroes` → `_ao_restaurar_acessibilidade`; `pressed` de `Raiz/Conteudo/PaginaSistema/Margem/Caixa/BarraSistema/BotaoSalvarJogo` → `_ao_salvar_jogo`; `pressed` de `Raiz/Conteudo/PaginaSistema/Margem/Caixa/BarraSistema/BotaoTelaCheia` → `_ao_tela_cheia`; `pressed` de `Raiz/Conteudo/PaginaAudio/Margem/Caixa/BarraSom/BotaoTestarSom` → `_ao_testar_som` … +4 grupos
- **Sinais conectados em código:** 4 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** nenhum
- **Conteúdo dinâmico mantido:** nenhum: toda a interface é estática na cena.
- **Lógica removida do script:** antes, 49 chamadas `UiKit.*`, 8 `Classe.new()` de interface e 50 `add_child`; depois, 0 `.new()` de interface. O script passou de 526 para 324 linhas.
- **Dependências:** autoloads `GerenciadorConfiguracoes`, `GerenciadorEstado`, `SistemaAudio`, `SistemaNotificacoes`, `GerenciadorJanelas`, `GerenciadorNarrativa`, `SistemaPersistencia`; cenas de componente/item: `cabecalho_pagina.tscn`, `linha_check.tscn`, `linha_opcao.tscn`, `linha_slider.tscn`.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `config`, 43 verificações, todas OK no último log):
  - o app settings abre em uma janela
  - configurações: os nós essenciais da cena existem
  - configurações: abre na página Personalização (a única visível)
  - configurações: os botões do menu compartilham o ButtonGroup da cena
  - configurações: texto e alinhamento do menu vêm da cena
  - configurações: o botão Personalizacao mostra só a sua página
  - configurações: o botão Audio mostra só a sua página
  - configurações: o botão Acessibilidade mostra só a sua página
  - configurações: o botão Privacidade mostra só a sua página
  - configurações: o botão Sistema mostra só a sua página
  - configurações: o cabeçalho da página vem do componente CabecalhoPagina (Áudio)
  - configurações: receber_args abre a página pedida e marca privacidade_visitada
  - configurações: página desconhecida mantém a atual
  - configurações: a grade de atalhos tem as 8 linhas na cena
  - configurações: mudar tema e papel de parede move as listas suspensas
  - configurações: valor numérico (1,2) e texto ('intenso') escolhem a opção certa
  - configurações: o controle deslizante e o rótulo seguem a configuração
  - configurações: caixas de seleção seguem a configuração
  - configurações: escolher 'Roxo' grava tema=roxo e o componente emite valor_escolhido
  - configurações: escolher 'Normal' grava o número 1,0
  - configurações: mexer no controle deslizante grava o volume e atualiza o rótulo (50%)
  - configurações: soltar o controle emite valor_confirmado
  - configurações: marcar uma caixa grava a configuração
  - configurações: desmarcar grava o valor falso
  - configurações: 'Ativar modo conforto' liga as 5 opções e marca as caixas
  - configurações: 'Desativar modo conforto' desliga as 5 opções
  - configurações: 'Restaurar padrões' devolve contraste e tamanho do texto
  - configurações: todas as permissões começam ativas (Monitoramento completo: 4 de 4 permissões ativas.)
  - configurações: desmarcar uma permissão abre a pergunta com os dois botões de sempre
  - configurações: enquanto decide, a caixa continua marcada e a permissão ativa
  - configurações: 'Manter ativado' mantém a permissão
  - configurações: a partir do Dia 2 há uma segunda etapa de confirmação
  - configurações: confirmando as duas etapas a permissão é desativada
  - configurações: o resumo mostra monitoramento parcial (Monitoramento parcial: 3 de 4 permissões ativas.)
  - configurações: reativar uma permissão é imediato, sem perguntas
  - configurações: apertar duas vezes 'Desativar todas' abre uma só pergunta
  - configurações: a pergunta fala de todas as permissões
  - configurações: confirmando, todas as permissões ficam desativadas e a flag da narrativa é gravada
  - configurações: o resumo muda para 'nenhuma permissão' com o estilo fraco
  - configurações: 'Reativar todas' liga tudo sem perguntas
  - configurações: o painel de sessão mostra usuário e dia
  - configurações: o painel de sessão acompanha a segurança (sinal do GerenciadorEstado)
  - configurações: ao fechar, a janela some e as ligações com os autoloads são desfeitas

### Navegador (`browser`)

- **Função:** Navegador do universo do jogo: abre só `humax://…` (páginas de `paginas_web.json`) e bloqueia qualquer outro esquema.
- **Cena e script:** `features/apps/navegador/scenes/app_navegador.tscn` (17 nós, 7 com nome único); `features/apps/navegador/scripts/app_navegador.gd` (146 linhas, `AppNavegador` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppNavegador (Control + app_navegador.gd)
    Raiz (VBoxContainer)
      Barra (HBoxContainer)
        %BotaoVoltar (Button)
        %BotaoAvancar (Button)
        BotaoRecarregar (Button)
        BotaoInicio (Button)
        %CampoEndereco (LineEdit)
        BotaoIr (Button)
      PainelLinks (PanelContainer)
        Margem (MarginContainer)
      %RotuloTitulo (Label)
      PainelCorpo (PanelContainer)
        Margem (MarginContainer)
      %RotuloEstado (Label)
  ```
- **Nós importantes (nome único):** `%BotaoVoltar` (Button), `%BotaoAvancar` (Button), `%CampoEndereco` (LineEdit), `%Links` (RichTextLabel), `%RotuloTitulo` (Label), `%Corpo` (RichTextLabel), `%RotuloEstado` (Label)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `url`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (12):** `meta_clicked` → `_ao_link` (2); `meta_hover_ended` → `_ao_link_fim` (2); `meta_hover_started` → `_ao_link_hover` (2); `pressed` de `Raiz/Barra/BotaoAvancar` → `_ao_avancar`; `pressed` de `Raiz/Barra/BotaoInicio` → `_ao_inicio`; `pressed` de `Raiz/Barra/BotaoIr` → `_ao_ir`; `pressed` de `Raiz/Barra/BotaoRecarregar` → `_ao_recarregar`; `pressed` de `Raiz/Barra/BotaoVoltar` → `_ao_voltar`; `text_submitted` de `Raiz/Barra/CampoEndereco` → `_ao_endereco_enviado`
- **Sinais conectados em código:** 0 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** nenhum
- **Conteúdo dinâmico mantido:** nenhum: toda a interface é estática na cena.
- **Lógica removida do script:** antes, 14 chamadas `UiKit.*`, 0 `Classe.new()` de interface e 12 `add_child`; depois, 0 `.new()` de interface. O script passou de 181 para 146 linhas.
- **Dependências:** autoloads `GerenciadorEstado`, `SistemaAudio`, `GerenciadorNarrativa`; cenas de componente/item: nenhuma.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `navegador`, 17 verificações, todas OK no último log):
  - o app browser abre em uma janela
  - navegador: os nós essenciais existem
  - navegador: abre na página inicial
  - navegador: o campo e o rodapé falam da rede interna humax:// do HumaxOS
  - navegador: a faixa de links mostra os links do dia
  - navegador: sem histórico, voltar e avançar ficam desabilitados
  - navegador: Enter no campo normaliza o endereço (humax://status)
  - navegador: a página interna mostra o título dela
  - navegador: navegar pelo jogador grava visitou_pagina_interna
  - navegador: depois de navegar, só voltar fica habilitado
  - navegador: voltar retorna à página anterior e habilita avançar
  - navegador: avançar volta para a página seguinte
  - navegador: um endereço externo mostra a página de bloqueio
  - navegador: o esquema antigo nexus:// também mostra a página de bloqueio (sem alias)
  - navegador: clicar num link da faixa navega até o destino
  - navegador: passar o mouse num link mostra o destino no rodapé
  - navegador: ao sair do link o rodapé volta ao texto padrão

### Terminal (`terminal`)

- **Função:** Terminal simulado: comandos sobre o sistema de arquivos virtual e a tabela de processos; nenhum shell real.
- **Cena e script:** `features/apps/terminal/scenes/app_terminal.tscn` (8 nós, 3 com nome único); `features/apps/terminal/scripts/app_terminal.gd` (530 linhas, `AppTerminal` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppTerminal (Control + app_terminal.gd)
    Raiz (VBoxContainer)
      PainelSaida (PanelContainer)
        Margem (MarginContainer)
      LinhaComando (HBoxContainer)
        %RotuloPrompt (Label)
        %Campo (LineEdit)
  ```
- **Nós importantes (nome único):** `%Saida` (RichTextLabel), `%RotuloPrompt` (Label), `%Campo` (LineEdit)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); este app não lê chaves específicas.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (2):** `gui_input` de `Raiz/LinhaComando/Campo` → `_ao_entrada_campo`; `text_submitted` de `Raiz/LinhaComando/Campo` → `_ao_enviar`
- **Sinais conectados em código:** 0 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** nenhum
- **Conteúdo dinâmico mantido:** nenhum: toda a interface é estática na cena.
- **Lógica removida do script:** antes, 6 chamadas `UiKit.*`, 0 `Classe.new()` de interface e 5 `add_child`; depois, 0 `.new()` de interface. O script passou de 511 para 530 linhas.
- **Dependências:** autoloads `RelogioGlobal`, `GerenciadorEstado`, `SistemaAudio`, `SistemaArquivosVirtual`, `GerenciadorJanelas`, `GerenciadorNarrativa`; cenas de componente/item: nenhuma.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `terminal`, 29 verificações, todas OK no último log):
  - o app terminal abre em uma janela
  - terminal: os nós da cena existem
  - terminal: o banner aparece uma vez ao abrir
  - terminal: o [b] do banner usa a fonte em negrito do tema (RichoMono repete bold_font do tema padrão)
  - terminal: o prompt mostra usuário e pasta (teste@humax:~$)
  - terminal: o campo tem a dica da cena e o foco
  - terminal: chamar iniciar() de novo não repete o banner
  - terminal: 'help' ecoa o comando, limpa o campo e lista os comandos
  - terminal: 'pwd' mostra a pasta atual
  - terminal: 'cd' atualiza o prompt (teste@humax:~/Documentos$)
  - terminal: 'ls' lista os arquivos da pasta
  - terminal: 'cat' mostra o conteúdo do arquivo
  - terminal: 'echo' escapa o BBCode (aparece literalmente)
  - terminal: comando bloqueado avisa e não mexe no VFS
  - terminal: comando desconhecido mostra o erro
  - terminal: 'mkdir' (com aspas) e 'touch' criam no VFS
  - terminal: 'history' numera os comandos
  - terminal: linha em branco não entra no histórico
  - terminal: seta ↑ traz o último comando (history)
  - terminal: seta ↑ repetida volta no histórico (touch feito_no_terminal.txt)
  - terminal: seta ↓ até o fim limpa o campo
  - terminal: Tab completa o nome do comando
  - terminal: Tab completa nomes de arquivos da pasta atual (cat read_me.txt)
  - terminal: Ctrl+L limpa a tela
  - terminal: depois de limpar a saída continua funcionando
  - terminal: o comando 'clear' também limpa
  - terminal: o comando antigo scan_nexus não existe mais (sem alias)
  - terminal: a saída guarda no máximo ~400 linhas (398) e mantém as mais recentes
  - terminal: 'exit' fecha a janela

### Monitor do Sistema (`task_manager`)

- **Função:** Monitor do sistema: processos simulados, uso de CPU/RAM e encerramento do processo suspeito.
- **Cena e script:** `features/apps/monitor_sistema/scenes/app_monitor_sistema.tscn` (39 nós, 13 com nome único); `features/apps/monitor_sistema/scripts/app_monitor_sistema.gd` (197 linhas, `AppMonitorSistema` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppMonitorSistema (Control + app_monitor_sistema.gd)
    Raiz (VBoxContainer)
      Resumo (HBoxContainer)
        PainelCpu (PanelContainer)
        PainelMemoria (PanelContainer)
        PainelProcessos (PanelContainer)
      Barras (HBoxContainer)
        Seguranca (VBoxContainer)
        Integridade (VBoxContainer)
      %Alerta (PanelContainer, oculto)
        Margem (MarginContainer)
      Cabecalho (HBoxContainer)
        CabNome (Label)
        CabPid (Label)
        CabCpu (Label)
        CabMemoria (Label)
        CabTipo (Label)
      PainelLista (PanelContainer)
        Rolagem (ScrollContainer)
      Rodape (HBoxContainer)
        %RotuloDetalhe (Label)
        %BotaoEncerrar (Button)
      %RotuloEstado (Label)
    %Temporizador (Timer)
  ```
- **Nós importantes (nome único):** `%RotuloCpu` (Label), `%RotuloMemoria` (Label), `%RotuloProcessos` (Label), `%BarraSeguranca` (ProgressBar), `%BarraIntegridade` (ProgressBar), `%Alerta` (PanelContainer), `%RotuloAlerta` (Label), `%BarraProcesso` (ProgressBar), `%Lista` (VBoxContainer), `%RotuloDetalhe` (Label), `%BotaoEncerrar` (Button), `%RotuloEstado` (Label), `%Temporizador` (Timer)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); este app não lê chaves específicas.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (2):** `pressed` de `Raiz/Rodape/BotaoEncerrar` → `_ao_encerrar`; `timeout` de `Temporizador` → `_ao_timer`
- **Sinais conectados em código:** 3 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** `cena_linha: PackedScene`
- **Conteúdo dinâmico mantido:** instancia, a partir de `PackedScene` exportada, `cena_linha` dentro de containers que já existem na cena.
- **Lógica removida do script:** antes, 27 chamadas `UiKit.*`, 3 `Classe.new()` de interface e 31 `add_child`; depois, 0 `.new()` de interface. O script passou de 314 para 197 linhas.
- **Dependências:** autoloads `GerenciadorEstado`, `GerenciadorJanelas`; cenas de componente/item: `linha_processo.tscn`.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `monitor_sistema`, 17 verificações, todas OK no último log):
  - o app task_manager abre em uma janela
  - monitor: os nós essenciais existem com nome único
  - monitor: o Timer da cena está rodando (intervalo 0,5 s)
  - monitor: uma linha da tabela por processo (5)
  - monitor: o resumo conta os processos
  - monitor: sem seleção, o botão Encerrar fica desabilitado
  - monitor: sem processo suspeito, o alerta fica oculto
  - monitor: existe um processo protegido na tabela
  - monitor: selecionar uma linha habilita Encerrar e mostra o detalhe
  - monitor: encerrar um processo protegido recusa, em vermelho
  - monitor: o processo suspeito do Dia 5 foi criado
  - monitor: o alerta aparece com um processo suspeito
  - monitor: o suspeito vai para o topo da tabela
  - monitor: a linha suspeita usa o texto vermelho
  - monitor: selecionar o suspeito muda o texto do botão
  - monitor: encerrar o suspeito o remove do estado do jogo
  - monitor: o alerta some e a mensagem de sucesso aparece

### Leitor de Texto (`text_reader`)

- **Função:** Leitor de texto somente leitura para arquivos do sistema virtual.
- **Cena e script:** `features/apps/leitor_texto/scenes/app_leitor_texto.tscn` (10 nós, 4 com nome único); `features/apps/leitor_texto/scripts/app_leitor_texto.gd` (89 linhas, `AppLeitorTexto` herda `AppBase`).
- **Árvore (3 níveis):**

  ```text
  AppLeitorTexto (Control + app_leitor_texto.gd)
    Raiz (VBoxContainer)
      Topo (HBoxContainer)
        %RotuloCaminho (Label)
        RotuloSomenteLeitura (Label)
        %BotaoEditor (Button)
      PainelCorpo (PanelContainer)
        Margem (MarginContainer)
      %RotuloEstado (Label)
  ```
- **Nós importantes (nome único):** `%RotuloCaminho` (Label), `%BotaoEditor` (Button), `%Corpo` (RichTextLabel), `%RotuloEstado` (Label)
- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`); chaves lidas: `caminho`.
- **Sinais emitidos:** nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)
- **Sinais conectados na cena (1):** `pressed` de `Raiz/Topo/BotaoEditor` → `_ao_abrir_no_editor`
- **Sinais conectados em código:** 2 chamada(s) `connect`/`conectar` (itens criados em tempo de execução).
- **Exports:** nenhum
- **Conteúdo dinâmico mantido:** nenhum: toda a interface é estática na cena.
- **Lógica removida do script:** antes, 8 chamadas `UiKit.*`, 0 `Classe.new()` de interface e 7 `add_child`; depois, 0 `.new()` de interface. O script passou de 107 para 89 linhas.
- **Dependências:** autoloads `SistemaArquivosVirtual`, `GerenciadorJanelas`, `GerenciadorNarrativa`; cenas de componente/item: nenhuma.
- **Critérios de aceitação** (`tests/ui_interacao`, grupo `leitor_texto`, 9 verificações, todas OK no último log):
  - o app text_reader abre em uma janela
  - leitor: os nós essenciais existem com nome único
  - leitor: o caminho do arquivo aparece no topo
  - leitor: o corpo mostra o texto do arquivo (154 caracteres)
  - leitor: o rodapé resume linhas e caracteres
  - leitor: o botão 'Abrir no Bloco de Notas' fica habilitado com um arquivo aberto
  - leitor: o botão abre o Bloco de Notas com o arquivo
  - leitor: caminho inexistente mostra aviso e desabilita o botão
  - leitor: receber_args volta a mostrar um arquivo válido

## 9. Demais cenas: telas, shell, itens de lista, diálogos e minigame

| Cena | Raiz | Nós | `%Nome` | Exports | Conexões na cena | Grupo de teste |
|---|---|---:|---:|---|---:|---|
| `features/apps/calendario/scenes/cartao_compromisso.tscn` | PanelContainer | 8 | 4 | `variacao_texto_emergencia`, `variacao_estado_alterado`, `variacao_estado_alerta` | 0 | — |
| `features/apps/calendario/scenes/item_dia_calendario.tscn` | Button | 1 | 0 | `variacao_hoje`, `variacao_normal` | 1 | — |
| `features/apps/email/scenes/item_email.tscn` | Button | 1 | 0 | — | 1 | — |
| `features/apps/mensageiro/scenes/item_contato.tscn` | Button | 1 | 0 | — | 1 | — |
| `features/apps/mensageiro/scenes/item_escolha.tscn` | Button | 1 | 0 | — | 1 | — |
| `features/apps/monitor_sistema/scenes/linha_processo.tscn` | Button | 7 | 5 | `variacao_normal`, `variacao_suspeito` | 1 | — |
| `features/apps/visualizador/scenes/rotulo_meta_chave.tscn` | Label | 1 | 0 | — | 0 | — |
| `features/apps/visualizador/scenes/rotulo_meta_valor.tscn` | Label | 1 | 0 | — | 0 | — |
| `features/menu_principal/scenes/menu_principal.tscn` | Control | 27 | 20 | — | 9 | — |
| `features/menu_principal/scenes/painel_creditos.tscn` | Control | 39 | 5 | — | 1 | — |
| `features/minigames/logica/scenes/minigame_logica.tscn` | Control | 55 | 19 | — | 13 | `dialogos` (64) |
| `features/narrative/finais/scenes/tela_final.tscn` | Control | 27 | 16 | `cena_item_evidencia` | 5 | `tela_final` (39) |
| `features/pause/scenes/menu_pausa.tscn` | Control | 22 | 16 | — | 9 | — |
| `features/pause/scenes/tela_fim_de_jogo.tscn` | Control | 20 | 14 | — | 6 | — |
| `features/puzzles/arquivos_criptografados/scenes/dialogo_chave.tscn` | Control | 17 | 9 | — | 5 | `dialogos` (64) |
| `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn` | Control | 24 | 15 | `cena_icone` | 0 | — |
| `features/shell/area_de_trabalho/scenes/cartao_dia.tscn` | Control | 8 | 4 | — | 0 | — |
| `features/shell/area_de_trabalho/scenes/icone_area_de_trabalho.tscn` | Button | 4 | 2 | — | 2 | — |
| `features/shell/area_de_trabalho/scenes/painel_debug.tscn` | PanelContainer | 25 | 3 | — | 12 | — |
| `features/shell/area_de_trabalho/scenes/papel_de_parede.tscn` | Control | 1 | 0 | `passo_grade` | 0 | — |
| `features/shell/barra_de_tarefas/scenes/barra_de_tarefas.tscn` | PanelContainer | 15 | 9 | `cena_botao` | 2 | — |
| `features/shell/barra_de_tarefas/scenes/botao_tarefa.tscn` | Button | 4 | 2 | — | 0 | — |
| `features/shell/centro_notificacoes/scenes/cartao_notificacao.tscn` | PanelContainer | 10 | 6 | — | 1 | — |
| `features/shell/centro_notificacoes/scenes/centro_notificacoes.tscn` | Control | 14 | 6 | `cena_cartao` | 3 | — |
| `features/shell/data_e_hora/scenes/widget_relogio.tscn` | PanelContainer | 6 | 3 | — | 0 | — |
| `features/shell/efeito_glitch/scenes/efeito_glitch.tscn` | Control | 2 | 1 | — | 0 | — |
| `features/shell/janela_inicial/scenes/botao_app_menu.tscn` | Button | 5 | 3 | — | 0 | — |
| `features/shell/janela_inicial/scenes/menu_iniciar.tscn` | Control | 29 | 14 | `cena_botao_app`, `cena_resultado` | 7 | — |
| `features/shell/janela_inicial/scenes/resultado_busca.tscn` | Button | 7 | 4 | — | 0 | — |
| `features/shell/popup_notificacao/scenes/pilha_toasts.tscn` | Control | 2 | 1 | `cena_popup` | 0 | — |
| `features/shell/popup_notificacao/scenes/popup_notificacao.tscn` | PanelContainer | 14 | 8 | — | 2 | — |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | Control | 40 | 15 | — | 11 | `tela_boot` (53) |
| `features/shell/widget_nexus/scenes/item_objetivo.tscn` | Label | 1 | 0 | — | 0 | — |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | PanelContainer | 27 | 14 | `cena_item_objetivo` | 3 | — |
| `features/splash_screen/scenes/splash_screen.tscn` | Control | 16 | 11 | `caminho_video`, `caminho_destino`, `exibir_somente_uma_vez`, `tempo_maximo_carga_s`, `tempo_primeiro_quadro_s`, `tempo_maximo_reproducao_s`, `duracao_estatica_s`, `duracao_dissolver_s`, `duracao_fade_saida_s`, `atraso_dica_s`, `ganho_audio_db` | 2 | — |
| `shared/ui/dialogo_arquivo/scenes/dialogo_arquivo.tscn` | Control | 16 | 9 | — | 6 | `dialogos` (64) |
| `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn` | Control | 13 | 8 | — | 3 | `dialogos` (64) |
| `shared/ui/icone_app/scenes/icone_app.tscn` | Control | 4 | 3 | `lado` | 0 | — |
| `shared/ui/indicador_carregamento/scenes/indicador_carregamento.tscn` | Control | 8 | 2 | — | 0 | — |
| `shared/ui/janela_base/scenes/janela_base.tscn` | Control | 26 | 9 | `titulo`, `tamanho_min`, `pode_maximizar` | 13 | — |
| `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn` | Control | 1 | 0 | — | 0 | — |
| `shared/ui/painel_confirmacao/scenes/painel_confirmacao.tscn` | Control | 11 | 4 | — | 2 | — |
| `shared/ui/painel_opcoes/scenes/painel_opcoes.tscn` | Control | 32 | 4 | — | 2 | — |

## 10. Input Map e `project.godot` (§18.7)

As ações abaixo são registradas **em código** por `GerenciadorConfiguracoes._registrar_acoes()` (não aparecem em `project.godot`, por decisão da arquitetura original); não há mapa de entrada a editar no editor.

| Ação | Tecla |
|---|---|
| `nexus_menu_iniciar` | F1 |
| `nexus_tela_cheia` | F11 |
| `nexus_painel_debug` | F9 |
| `nexus_proxima_janela` | Ctrl+TAB |
| `nexus_fechar_janela` | Ctrl+W |
| `nexus_minimizar_janela` | Ctrl+M |
| `nexus_abrir_terminal` | Ctrl+Shift+T |
| `nexus_forcar_desativar` | Ctrl+Shift+D |

Mudança em `project.godot` nesta etapa: secção `[gui]` com `theme/custom="res://shared/theme/tema_nexus_base.tres"`; autoloads, resolução-base 1920×1080, `canvas_items` + `expand` e o modo de janela ficaram como estavam. Mudanças posteriores, da rodada da Splash Screen de 2026-11-13 ([`docs/15`](15_splash_screen.md)): a cena principal deixou de ser a `tela_boot.tscn` e passou a ser `res://features/splash_screen/scenes/splash_screen.tscn`; a tela de boot do motor ficou preta e sem imagem (`boot_splash/bg_color` e `boot_splash/show_image`) e a cor de limpeza padrão ficou preta (`default_clear_color`).

## 11. Testes de aceitação (§18.8)

| Teste | Como rodar | Resultado |
|---|---|---|
| Validador estático | `python3 -I tools/validar_projeto.py` | 0 erros, 0 avisos |
| Avisos do editor | abrir `tests/avisos_editor/varredura_editor.gd` e *Arquivo → Executar* (Ctrl+Shift+X) | 63 cenas, **0 avisos** — rodada de 2026-11-13, `tests/_saida/avisos_editor/log_editor.txt` (em 2026-11-09: 58 → 0 com 55 cenas; a 63ª é a Splash) |
| Interação (cliques, teclado, diálogos, boot, final) | abrir `tests/ui_interacao/ui_interacao.tscn` e F6 | **554 verificações, 0 falhas.** |
| Capturas e árvores | `tests/ui_dump/ui_dump.tscn` e F6 (3ª linha de `rodada.txt` = rodada de referência) | árvore de nós idêntica antes/depois da última correção; diferenças só de relógio/data |
| Fumaça | `tests/smoke_test.tscn` (com `-- --ui` nos argumentos de execução, inclui a camada de interface) | **308 verificações sem a etapa de interface e 345 com `-- --ui`**, 0 falhas, Depurador limpo — rodada de 2026-11-13; a saída fica só no painel Saída do editor (não há arquivo de log) |
| Resoluções | `tests/resolucoes/resolucoes.tscn` e F6 | 139 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/resolucoes/log.txt`; inclui a Splash nas quatro proporções) |
| Persistência em disco | `tests/persistencia/persistencia.tscn` e F6 (grava só em `user://nexus_os_teste/`) | 119 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/persistencia/log.txt`); deixa 6 avisos esperados no Depurador |
| Fluxo de sessão (Menu, Pausa, Fim de Jogo) | `tests/fluxo_sessao/fluxo_sessao.tscn` e F6 (grava só em `user://nexus_os_teste_fluxo/`) | 194 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/fluxo_sessao/log.txt`, com capturas de tela); deixa 6 mensagens esperadas no Depurador. Descrito em `docs/14` e `docs/15` |
| Splash Screen (abertura, pulo, falhas, acessibilidade) | `tests/splash/splash.tscn` e F6 (grava só em `user://nexus_os_teste_splash/`) | 311 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/splash/log.txt`, com capturas de tela); deixa mensagens esperadas no Depurador (as falhas provocadas de propósito). Descrito em `docs/15` |

## 12. Ressalvas e limitações

1. **Nós de interface ainda criados em código (4, em 3 scripts):** botões por opção do diálogo de escolha (`dialogo_nexus.gd`), a prévia de arrastar da porta lógica (`porta_logica_item.gd`) e o espaçador de células vazias da grade da Agenda (`app_calendario.gd`). São dinâmicos ou transitórios; poderiam virar cenas de item, o que não foi feito.
2. **Overrides de tema em código (7):** cores/estados ligados a dados (severidade do toast, cor do ícone do app etc.), não layout.
3. **Tamanhos mínimos fixos** (seção 6, item 8): a escala do texto continua valendo para as fontes, não para o tamanho mínimo das caixas.
4. **Rodada de 2026-11-13:** fumaça (com e sem interface), interação, resoluções, persistência, fluxo de sessão e a varredura dos avisos do editor foram executadas na Godot 4.7.2 com os arquivos finais deste pacote; o validador estático e a auditoria de marca foram reexecutados depois da última alteração de código.
5. **Rodada de 2026-11-09 às 21h (UTC−3):** o dia do jogo e o relógio dependem da hora real; capturas de dias diferentes diferem em texto/relógio e no destaque "hoje" da Agenda.
6. **Efeito colateral nas preferências do jogador:** execuções de teste anteriores à correção do isolamento gravaram em `user://nexus_os/configuracoes.cfg` (reduzir glitch/tremor/flashes/ruído = ativado). Para voltar ao padrão: *Configurações → Acessibilidade → restaurar padrões* ou apagar esse arquivo.
7. **Documentos 01, 02, 03, 05, 07, 08 e 09** descrevem a etapa anterior (interface em código, "nunca executado"); a verdade atual está neste documento e em `docs/04`.
8. **O editor mostra o jogo em exclusivo fullscreen** nas execuções de teste (configuração do projeto); a varredura de avisos não sofre com isso porque é um `EditorScript` (`tests/avisos_editor/varredura_editor.gd`) e roda dentro do editor.
9. **`tests/avisos_editor/avisos_editor.tscn` é obsoleto:** a primeira versão da varredura rodava o jogo e chamava `Node.get_configuration_warnings()`, que o GDScript da Godot 4.7 não expõe. A cena foi reduzida a um aviso que encerra na hora; nada a referencia e ela pode ser apagada (a ferramenta que fez a migração não consegue apagar arquivos da sua pasta).
10. **Rebranding, fluxo de sessão e Splash Screen (2026-11-13):** o rebranding para Maya Human Syntax ([`docs/12`](12_rebranding_maya_human_syntax.md)), o Menu Principal, a Pausa e a Tela de Fim de Jogo ([`docs/14`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md)) e a Splash Screen, nova cena principal ([`docs/15`](15_splash_screen.md)), foram verificados no motor no mesmo dia; os números da tabela de testes acima são da última rodada. O salvamento de versão 1 é coberto por `tests/persistencia`. A conferência manual R1–R6 de `docs/08_testes_manuais.md` e uma campanha manual completa continuam não verificadas.
