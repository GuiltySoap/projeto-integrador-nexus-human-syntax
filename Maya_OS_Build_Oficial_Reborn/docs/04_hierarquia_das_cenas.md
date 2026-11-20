# 15.4 Hierarquia das cenas

> Gerado por `tools/gerar_docs_ui.py` a partir dos `.tscn` (rode de novo depois de mudar uma cena).

## Como as cenas são construídas

A interface do HumaxOS é montada **no editor**: cada tela, janela, aplicativo, diálogo e componente é uma cena `.tscn` com a hierarquia de nós, os containers nativos e o layout salvos no arquivo. Os scripts guardam só comportamento (estado, regras, ligação com os autoloads). Conteúdo que só existe em tempo de execução (linhas de lista, balões de chat, botões por opção) é criado a partir de **cenas de item** reutilizáveis, instanciadas dentro de um container que já existe na cena pai.

Convenções:

- Nós que o script usa têm **nome único** (`%Nome`, `unique_name_in_owner`) e são lidos com `@onready var x: Tipo = %Nome`. Nenhum caminho `$A/B/C` frágil.
- Propriedades que o designer ajusta no editor são `@export` (por exemplo `cena_item: PackedScene`); as referências essenciais são conferidas em `_ready` (`UiKit.refs_ok`).
- Sinais de nós fixos são conexões da própria cena (`[connection …]`, aba *Nó → Sinais*); só os itens criados em tempo de execução são conectados no código, uma vez, na criação.
- Aparência: `shared/theme/tema_nexus_base.tres` (definido em `gui/theme/custom`) faz o editor mostrar as cenas estilizadas; em jogo `TemaNexus.aplicar()` aplica o tema completo em `root.theme`. Para regerar o `.tres` depois de mudar `tema_nexus.gd`/`tema_variacoes.gd`, rode `tests/exportar_tema/exportar_tema.tscn`.
- Os autoloads **não** constroem interface.

## Índice das cenas (63)

| Cena | Raiz | Script | Nós | `%Nome` | Conexões |
|---|---|---|---:|---:|---:|
| `features/apps/bloco_de_notas/scenes/app_bloco_de_notas.tscn` | Control | `app_bloco_de_notas.gd` | 13 | 5 | 7 |
| `features/apps/calculadora/scenes/app_calculadora.tscn` | Control | `app_calculadora.gd` | 29 | 3 | 20 |
| `features/apps/calendario/scenes/app_calendario.tscn` | Control | `app_calendario.gd` | 24 | 6 | 3 |
| `features/apps/calendario/scenes/cartao_compromisso.tscn` | PanelContainer | `cartao_compromisso.gd` | 8 | 4 | 0 |
| `features/apps/calendario/scenes/item_dia_calendario.tscn` | Button | `item_dia_calendario.gd` | 1 | 0 | 1 |
| `features/apps/config/components/cabecalho_pagina/scenes/cabecalho_pagina.tscn` | VBoxContainer | `cabecalho_pagina.gd` | 4 | 2 | 0 |
| `features/apps/config/components/linha_check/scenes/linha_check.tscn` | VBoxContainer | `linha_check.gd` | 4 | 3 | 1 |
| `features/apps/config/components/linha_opcao/scenes/linha_opcao.tscn` | HBoxContainer | `linha_opcao.gd` | 3 | 2 | 1 |
| `features/apps/config/components/linha_slider/scenes/linha_slider.tscn` | VBoxContainer | `linha_slider.gd` | 5 | 3 | 2 |
| `features/apps/config/scenes/app_config.tscn` | Control | `app_config.gd` | 100 | 13 | 34 |
| `features/apps/email/scenes/app_email.tscn` | Control | `app_email.gd` | 18 | 6 | 0 |
| `features/apps/email/scenes/item_email.tscn` | Button | `item_email.gd` | 1 | 0 | 1 |
| `features/apps/explorador/scenes/app_explorador.tscn` | Control | `app_explorador.gd` | 32 | 14 | 24 |
| `features/apps/leitor_texto/scenes/app_leitor_texto.tscn` | Control | `app_leitor_texto.gd` | 10 | 4 | 1 |
| `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn` | HBoxContainer | `balao_chat.gd` | 8 | 5 | 1 |
| `features/apps/mensageiro/scenes/app_mensageiro.tscn` | Control | `app_mensageiro.gd` | 23 | 11 | 2 |
| `features/apps/mensageiro/scenes/item_contato.tscn` | Button | `item_contato.gd` | 1 | 0 | 1 |
| `features/apps/mensageiro/scenes/item_escolha.tscn` | Button | `item_escolha.gd` | 1 | 0 | 1 |
| `features/apps/monitor_sistema/scenes/app_monitor_sistema.tscn` | Control | `app_monitor_sistema.gd` | 39 | 13 | 2 |
| `features/apps/monitor_sistema/scenes/linha_processo.tscn` | Button | `linha_processo.gd` | 7 | 5 | 1 |
| `features/apps/navegador/scenes/app_navegador.tscn` | Control | `app_navegador.gd` | 17 | 7 | 12 |
| `features/apps/terminal/scenes/app_terminal.tscn` | Control | `app_terminal.gd` | 8 | 3 | 2 |
| `features/apps/visualizador/scenes/app_visualizador.tscn` | Control | `app_visualizador.gd` | 21 | 14 | 6 |
| `features/apps/visualizador/scenes/rotulo_meta_chave.tscn` | Label | — | 1 | 0 | 0 |
| `features/apps/visualizador/scenes/rotulo_meta_valor.tscn` | Label | — | 1 | 0 | 0 |
| `features/menu_principal/scenes/menu_principal.tscn` | Control | `menu_principal.gd` | 27 | 20 | 9 |
| `features/menu_principal/scenes/painel_creditos.tscn` | Control | `painel_creditos.gd` | 39 | 5 | 1 |
| `features/minigames/logica/components/porta_logica_item/scenes/porta_logica_item.tscn` | Button | `porta_logica_item.gd` | 1 | 0 | 1 |
| `features/minigames/logica/components/slot_circuito/scenes/slot_circuito.tscn` | PanelContainer | `slot_circuito.gd` | 2 | 1 | 0 |
| `features/minigames/logica/scenes/minigame_logica.tscn` | Control | `minigame_logica.gd` | 55 | 19 | 13 |
| `features/narrative/finais/components/item_evidencia/scenes/item_evidencia.tscn` | Label | `item_evidencia.gd` | 1 | 0 | 0 |
| `features/narrative/finais/scenes/tela_final.tscn` | Control | `tela_final.gd` | 27 | 16 | 5 |
| `features/pause/scenes/menu_pausa.tscn` | Control | `menu_pausa.gd` | 22 | 16 | 9 |
| `features/pause/scenes/tela_fim_de_jogo.tscn` | Control | `tela_fim_de_jogo.gd` | 20 | 14 | 6 |
| `features/puzzles/arquivos_criptografados/scenes/dialogo_chave.tscn` | Control | `dialogo_chave.gd` | 17 | 9 | 5 |
| `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn` | Control | `area_de_trabalho.gd` | 24 | 15 | 0 |
| `features/shell/area_de_trabalho/scenes/cartao_dia.tscn` | Control | `cartao_dia.gd` | 8 | 4 | 0 |
| `features/shell/area_de_trabalho/scenes/icone_area_de_trabalho.tscn` | Button | `icone_area_de_trabalho.gd` | 4 | 2 | 2 |
| `features/shell/area_de_trabalho/scenes/painel_debug.tscn` | PanelContainer | `painel_debug.gd` | 25 | 3 | 12 |
| `features/shell/area_de_trabalho/scenes/papel_de_parede.tscn` | Control | `papel_de_parede.gd` | 1 | 0 | 0 |
| `features/shell/barra_de_tarefas/scenes/barra_de_tarefas.tscn` | PanelContainer | `barra_de_tarefas.gd` | 15 | 9 | 2 |
| `features/shell/barra_de_tarefas/scenes/botao_tarefa.tscn` | Button | `botao_tarefa.gd` | 4 | 2 | 0 |
| `features/shell/centro_notificacoes/scenes/cartao_notificacao.tscn` | PanelContainer | `cartao_notificacao.gd` | 10 | 6 | 1 |
| `features/shell/centro_notificacoes/scenes/centro_notificacoes.tscn` | Control | `centro_notificacoes.gd` | 14 | 6 | 3 |
| `features/shell/data_e_hora/scenes/widget_relogio.tscn` | PanelContainer | `widget_relogio.gd` | 6 | 3 | 0 |
| `features/shell/efeito_glitch/scenes/efeito_glitch.tscn` | Control | `efeito_glitch.gd` | 2 | 1 | 0 |
| `features/shell/janela_inicial/scenes/botao_app_menu.tscn` | Button | `botao_app_menu.gd` | 5 | 3 | 0 |
| `features/shell/janela_inicial/scenes/menu_iniciar.tscn` | Control | `menu_iniciar.gd` | 29 | 14 | 7 |
| `features/shell/janela_inicial/scenes/resultado_busca.tscn` | Button | `resultado_busca.gd` | 7 | 4 | 0 |
| `features/shell/popup_notificacao/scenes/pilha_toasts.tscn` | Control | `pilha_toasts.gd` | 2 | 1 | 0 |
| `features/shell/popup_notificacao/scenes/popup_notificacao.tscn` | PanelContainer | `popup_notificacao.gd` | 14 | 8 | 2 |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | Control | `tela_boot.gd` | 40 | 15 | 11 |
| `features/shell/widget_nexus/scenes/item_objetivo.tscn` | Label | `item_objetivo.gd` | 1 | 0 | 0 |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | PanelContainer | `widget_nexus.gd` | 27 | 14 | 3 |
| `features/splash_screen/scenes/splash_screen.tscn` | Control | `splash_screen.gd` | 16 | 11 | 2 |
| `shared/ui/dialogo_arquivo/scenes/dialogo_arquivo.tscn` | Control | `dialogo_arquivo.gd` | 16 | 9 | 6 |
| `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn` | Control | `dialogo_nexus.gd` | 13 | 8 | 3 |
| `shared/ui/icone_app/scenes/icone_app.tscn` | Control | `icone_app.gd` | 4 | 3 | 0 |
| `shared/ui/indicador_carregamento/scenes/indicador_carregamento.tscn` | Control | `indicador_carregamento.gd` | 8 | 2 | 0 |
| `shared/ui/janela_base/scenes/janela_base.tscn` | Control | `janela_base.gd` | 26 | 9 | 13 |
| `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn` | Control | `orbe_nexus.gd` | 1 | 0 | 0 |
| `shared/ui/painel_confirmacao/scenes/painel_confirmacao.tscn` | Control | `painel_confirmacao.gd` | 11 | 4 | 2 |
| `shared/ui/painel_opcoes/scenes/painel_opcoes.tscn` | Control | `painel_opcoes.gd` | 32 | 4 | 2 |

Total: **63 cenas, 955 nós**.

---

## `features/apps/`

### `features/apps/bloco_de_notas/scenes/app_bloco_de_notas.tscn`

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

Sinais conectados na cena: `caret_changed` de `Raiz/Editor` → `_atualizar_posicao`; `gui_input` de `Raiz/Editor` → `_ao_entrada_editor`; `pressed` de `Raiz/Barra/BotaoAbrir` → `_ao_abrir`; `pressed` de `Raiz/Barra/BotaoNovo` → `_ao_novo`; `pressed` de `Raiz/Barra/BotaoSalvar` → `_ao_salvar`; `pressed` de `Raiz/Barra/BotaoSalvarComo` → `_ao_salvar_como`; `text_changed` de `Raiz/Editor` → `_ao_texto_alterado`.

### `features/apps/calculadora/scenes/app_calculadora.tscn`

```text
AppCalculadora (Control + app_calculadora.gd)
  Raiz (VBoxContainer)
    Visor (PanelContainer)
      Margem (MarginContainer)
        Coluna (VBoxContainer)
          %RotuloHistorico (Label)
          %RotuloExpressao (Label)
          %RotuloResultado (Label)
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

Sinais conectados na cena: `pressed` → `_ao_tecla` (20).

### `features/apps/calendario/scenes/app_calendario.tscn`

```text
AppCalendario (Control + app_calendario.gd)
  Raiz (VBoxContainer)
    PainelAgora (PanelContainer)
      Margem (MarginContainer)
        %RotuloAgora (Label)
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
        Margem (MarginContainer)
          %Lista (VBoxContainer)
            %RotuloVazio (Label, oculto)
```

Sinais conectados na cena: `pressed` de `Raiz/Navegacao/BotaoMesAnterior` → `_ao_mes_anterior`; `pressed` de `Raiz/Navegacao/BotaoMesSeguinte` → `_ao_mes_seguinte`; `pressed` de `Raiz/Navegacao/BotaoHoje` → `_ir_para_hoje`.

### `features/apps/calendario/scenes/cartao_compromisso.tscn`

```text
CartaoCompromisso (PanelContainer + cartao_compromisso.gd)
  Margem (MarginContainer)
    Linha (HBoxContainer)
      %Hora (Label)
      Corpo (VBoxContainer)
        %Texto (Label)
        %Estado (Label, oculto)
        %Original (Label, oculto)
```

### `features/apps/calendario/scenes/item_dia_calendario.tscn`

```text
ItemDiaCalendario (Button + item_dia_calendario.gd)
```

Sinais conectados na cena: `pressed` de `.` → `_ao_pressionado`.

### `features/apps/config/components/cabecalho_pagina/scenes/cabecalho_pagina.tscn`

```text
CabecalhoPagina (VBoxContainer + cabecalho_pagina.gd)
  %RotuloTitulo (Label)
  %RotuloSubtitulo (Label)
  Separador (HSeparator)
```

### `features/apps/config/components/linha_check/scenes/linha_check.tscn`

```text
LinhaCheck (VBoxContainer + linha_check.gd)
  %Caixa (CheckBox)
  %RecuoDescricao (MarginContainer)
    %RotuloDescricao (Label)
```

Sinais conectados na cena: `toggled` de `Caixa` → `_ao_alternar`.

### `features/apps/config/components/linha_opcao/scenes/linha_opcao.tscn`

```text
LinhaOpcao (HBoxContainer + linha_opcao.gd)
  %RotuloTitulo (Label)
  %Seletor (OptionButton)
```

Sinais conectados na cena: `item_selected` de `Seletor` → `_ao_item_selecionado`.

### `features/apps/config/components/linha_slider/scenes/linha_slider.tscn`

```text
LinhaSlider (VBoxContainer + linha_slider.gd)
  Topo (HBoxContainer)
    %RotuloTitulo (Label)
    %RotuloValor (Label)
  %Slider (HSlider)
```

Sinais conectados na cena: `drag_ended` de `Slider` → `_ao_arraste_terminado`; `value_changed` de `Slider` → `_ao_valor_alterado`.

### `features/apps/config/scenes/app_config.tscn`

```text
AppConfig (Control + app_config.gd)
  Raiz (HBoxContainer)
    PainelMenu (PanelContainer)
      Margem (MarginContainer)
        Menu (VBoxContainer)
          %BotaoPersonalizacao (Button)
          %BotaoAudio (Button)
          %BotaoAcessibilidade (Button)
          %BotaoPrivacidade (Button)
          %BotaoSistema (Button)
    Conteudo (Control)
      %PaginaPersonalizacao (ScrollContainer)
        Margem (MarginContainer)
          Caixa (VBoxContainer)
            Cabecalho (instância de cabecalho_pagina.tscn)
            OpcaoPapelDeParede (instância de linha_opcao.tscn)
            OpcaoTema (instância de linha_opcao.tscn)
            OpcaoTamanhoTexto (instância de linha_opcao.tscn)
            NotaTamanhoTexto (Label)
      %PaginaAudio (ScrollContainer, oculto)
        Margem (MarginContainer)
          Caixa (VBoxContainer)
            Cabecalho (instância de cabecalho_pagina.tscn)
            VolumeGeral (instância de linha_slider.tscn)
            VolumeMusica (instância de linha_slider.tscn)
            VolumeEfeitos (instância de linha_slider.tscn)
            BarraSom (HBoxContainer)
              BotaoTestarSom (Button)
      %PaginaAcessibilidade (ScrollContainer, oculto)
        Margem (MarginContainer)
          Caixa (VBoxContainer)
            Cabecalho (instância de cabecalho_pagina.tscn)
            BarraConforto (HBoxContainer)
              BotaoAtivarConforto (Button)
              BotaoDesativarConforto (Button)
              BotaoRestaurarPadroes (Button)
            NotaAtalhoConforto (Label)
            OpcaoReduzirGlitch (instância de linha_check.tscn)
            OpcaoReduzirTremor (instância de linha_check.tscn)
            OpcaoSemFlashes (instância de linha_check.tscn)
            OpcaoReduzirRuido (instância de linha_check.tscn)
            OpcaoReduzirAnimacoes (instância de linha_check.tscn)
            OpcaoAltoContraste (instância de linha_check.tscn)
            Separador (HSeparator)
            TituloRitmo (Label)
            OpcaoDificuldade (instância de linha_opcao.tscn)
            NotaDificuldade (Label)
      %PaginaPrivacidade (ScrollContainer, oculto)
        Margem (MarginContainer)
          Caixa (VBoxContainer)
            Cabecalho (instância de cabecalho_pagina.tscn)
            %RotuloMonitoramento (Label)
            %ListaPermissoes (VBoxContainer)
              CartaoMicrofone (PanelContainer)
              CartaoAnalise (PanelContainer)
              CartaoLocalizacao (PanelContainer)
              CartaoCamera (PanelContainer)
            BarraPermissoes (HBoxContainer)
              BotaoDesativarTodas (Button)
              BotaoReativarTodas (Button)
            Separador (HSeparator)
            NotaPadroesEnganosos (Label)
      %PaginaSistema (ScrollContainer, oculto)
        Margem (MarginContainer)
          Caixa (VBoxContainer)
            Cabecalho (instância de cabecalho_pagina.tscn)
            PainelSessao (PanelContainer)
              Margem (MarginContainer)
            BarraSistema (HBoxContainer)
              BotaoTelaCheia (Button)
              BotaoSalvarJogo (Button)
            OpcaoDepuracao (instância de linha_check.tscn)
            Separador (HSeparator)
            TituloAtalhos (Label)
            ListaAtalhos (GridContainer)
              Tecla1 (Label)
              Descricao1 (Label)
              Tecla2 (Label)
              Descricao2 (Label)
              Tecla3 (Label)
              Descricao3 (Label)
              Tecla4 (Label)
              Descricao4 (Label)
              Tecla5 (Label)
              Descricao5 (Label)
              Tecla6 (Label)
              Descricao6 (Label)
              Tecla7 (Label)
              Descricao7 (Label)
              Tecla8 (Label)
              Descricao8 (Label)
```

Sinais conectados na cena: `alternada` → `_ao_alternar` (7); `alternada` → `_ao_permissao_alternada` (4); `pressed` de `Raiz/Conteudo/PaginaAcessibilidade/Margem/Caixa/BarraConforto/BotaoAtivarConforto` → `_ao_ativar_conforto`; `pressed` de `Raiz/Conteudo/PaginaAcessibilidade/Margem/Caixa/BarraConforto/BotaoDesativarConforto` → `_ao_desativar_conforto`; `pressed` de `Raiz/Conteudo/PaginaPrivacidade/Margem/Caixa/BarraPermissoes/BotaoDesativarTodas` → `_ao_desativar_todas`; `pressed` de `Raiz/Conteudo/PaginaPrivacidade/Margem/Caixa/BarraPermissoes/BotaoReativarTodas` → `_ao_reativar_todas`; `pressed` de `Raiz/Conteudo/PaginaAcessibilidade/Margem/Caixa/BarraConforto/BotaoRestaurarPadroes` → `_ao_restaurar_acessibilidade`; `pressed` de `Raiz/Conteudo/PaginaSistema/Margem/Caixa/BarraSistema/BotaoSalvarJogo` → `_ao_salvar_jogo`; `pressed` de `Raiz/Conteudo/PaginaSistema/Margem/Caixa/BarraSistema/BotaoTelaCheia` → `_ao_tela_cheia`; `pressed` de `Raiz/Conteudo/PaginaAudio/Margem/Caixa/BarraSom/BotaoTestarSom` → `_ao_testar_som`; `pressed` → `_mostrar_pagina` (5); `valor_alterado` → `_ao_slider` (3); `valor_confirmado` → `_ao_slider_solto` (3); `valor_escolhido` → `_ao_opcao` (4).

### `features/apps/email/scenes/app_email.tscn`

```text
AppEmail (Control + app_email.gd)
  Raiz (HBoxContainer)
    PainelLista (PanelContainer)
      Margem (MarginContainer)
        Rolagem (ScrollContainer)
          %Lista (VBoxContainer)
            %RotuloVazio (Label, oculto)
    Leitura (VBoxContainer)
      Cabecalho (PanelContainer)
        Margem (MarginContainer)
          Coluna (VBoxContainer)
            %RotuloAssunto (Label)
            %RotuloDe (Label)
            %RotuloDia (Label)
      PainelCorpo (PanelContainer)
        Margem (MarginContainer)
          %Corpo (RichTextLabel)
      RotuloAviso (Label)
```

### `features/apps/email/scenes/item_email.tscn`

```text
ItemEmail (Button + item_email.gd)
```

Sinais conectados na cena: `pressed` de `.` → `_ao_pressionado`.

### `features/apps/explorador/scenes/app_explorador.tscn`

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
        Margem (MarginContainer)
          ListaLocais (VBoxContainer)
            RotuloLocais (Label)
            LocalInicio (Button)
            LocalDocumentos (Button)
            LocalImagens (Button)
            LocalMusicas (Button)
            LocalDownloads (Button)
            LocalDadosPessoais (Button)
            LocalLixeira (Button)
            LocalSistema (Button)
      %Lista (ItemList)
    %RotuloStatus (Label)
```

Sinais conectados na cena: `empty_clicked` de `Raiz/Corpo/Lista` → `_ao_clique_vazio`; `gui_input` de `Raiz/Corpo/Lista` → `_ao_entrada_lista`; `item_activated` de `Raiz/Corpo/Lista` → `_ao_item_ativado`; `item_selected` de `Raiz/Corpo/Lista` → `_ao_item_selecionado`; `pressed` de `Raiz/BarraAcoes/BotaoAbrir` → `_ao_abrir_selecionado`; `pressed` de `Raiz/BarraNavegacao/BotaoAcima` → `_ao_acima`; `pressed` de `Raiz/BarraNavegacao/BotaoAvancar` → `_ao_avancar`; `pressed` de `Raiz/BarraAcoes/BotaoExcluir` → `_ao_excluir`; `pressed` → `_ao_local` (8); `pressed` de `Raiz/BarraAcoes/BotaoNovaPasta` → `_ao_nova_pasta`; `pressed` de `Raiz/BarraAcoes/BotaoNovoArquivo` → `_ao_novo_arquivo`; `pressed` de `Raiz/BarraAcoes/BotaoRenomear` → `_ao_renomear`; `pressed` de `Raiz/BarraAcoes/BotaoRestaurar` → `_ao_restaurar`; `pressed` de `Raiz/BarraNavegacao/BotaoVoltar` → `_ao_voltar`; `text_changed` de `Raiz/BarraNavegacao/CampoFiltro` → `_ao_filtro`; `text_submitted` de `Raiz/BarraNavegacao/CampoCaminho` → `_ao_caminho_enviado`; `toggled` de `Raiz/BarraAcoes/CaixaOcultos` → `_ao_ocultos`.

### `features/apps/leitor_texto/scenes/app_leitor_texto.tscn`

```text
AppLeitorTexto (Control + app_leitor_texto.gd)
  Raiz (VBoxContainer)
    Topo (HBoxContainer)
      %RotuloCaminho (Label)
      RotuloSomenteLeitura (Label)
      %BotaoEditor (Button)
    PainelCorpo (PanelContainer)
      Margem (MarginContainer)
        %Corpo (RichTextLabel)
    %RotuloEstado (Label)
```

Sinais conectados na cena: `pressed` de `Raiz/Topo/BotaoEditor` → `_ao_abrir_no_editor`.

### `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn`

```text
BalaoChat (HBoxContainer + balao_chat.gd)
  %Bolha (PanelContainer)
    Coluna (VBoxContainer)
      %RotuloEtiqueta (Label, oculto)
      %RotuloTexto (Label)
      Rodape (HBoxContainer)
        %RotuloHora (Label, oculto)
        %BotaoOriginal (Button, oculto)
```

Sinais conectados na cena: `pressed` de `Bolha/Coluna/Rodape/BotaoOriginal` → `_ao_alternar_original`.

### `features/apps/mensageiro/scenes/app_mensageiro.tscn`

```text
AppMensageiro (Control + app_mensageiro.gd)
  Raiz (HBoxContainer)
    BarraContatos (PanelContainer)
      Margem (MarginContainer)
        RolagemContatos (ScrollContainer)
          %ListaContatos (VBoxContainer)
    %PainelConversa (VBoxContainer)
      Cabecalho (PanelContainer)
        Margem (MarginContainer)
          Coluna (VBoxContainer)
            %RotuloNome (Label)
            %RotuloStatus (Label)
      AreaMensagens (PanelContainer)
        %Rolagem (ScrollContainer)
          Margem (MarginContainer)
            %ListaMensagens (VBoxContainer)
              %RotuloVazio (Label, oculto)
      %AreaEscolhas (VBoxContainer, oculto)
        RotuloEscolher (Label)
      %RotuloDica (Label, oculto)
      Compositor (HBoxContainer)
        %Campo (LineEdit)
        %BotaoEnviar (Button)
```

Sinais conectados na cena: `pressed` de `Raiz/PainelConversa/Compositor/BotaoEnviar` → `_ao_enviar`; `text_submitted` de `Raiz/PainelConversa/Compositor/Campo` → `_ao_texto_enviado`.

### `features/apps/mensageiro/scenes/item_contato.tscn`

```text
ItemContato (Button + item_contato.gd)
```

Sinais conectados na cena: `pressed` de `.` → `_ao_pressionado`.

### `features/apps/mensageiro/scenes/item_escolha.tscn`

```text
ItemEscolha (Button + item_escolha.gd)
```

Sinais conectados na cena: `pressed` de `.` → `_ao_pressionado`.

### `features/apps/monitor_sistema/scenes/app_monitor_sistema.tscn`

```text
AppMonitorSistema (Control + app_monitor_sistema.gd)
  Raiz (VBoxContainer)
    Resumo (HBoxContainer)
      PainelCpu (PanelContainer)
        Margem (MarginContainer)
          %RotuloCpu (Label)
      PainelMemoria (PanelContainer)
        Margem (MarginContainer)
          %RotuloMemoria (Label)
      PainelProcessos (PanelContainer)
        Margem (MarginContainer)
          %RotuloProcessos (Label)
    Barras (HBoxContainer)
      Seguranca (VBoxContainer)
        Titulo (Label)
        %BarraSeguranca (ProgressBar)
      Integridade (VBoxContainer)
        Titulo (Label)
        %BarraIntegridade (ProgressBar)
    %Alerta (PanelContainer, oculto)
      Margem (MarginContainer)
        Coluna (VBoxContainer)
          %RotuloAlerta (Label)
          %BarraProcesso (ProgressBar)
          Dica (Label)
    Cabecalho (HBoxContainer)
      CabNome (Label)
      CabPid (Label)
      CabCpu (Label)
      CabMemoria (Label)
      CabTipo (Label)
    PainelLista (PanelContainer)
      Rolagem (ScrollContainer)
        %Lista (VBoxContainer)
    Rodape (HBoxContainer)
      %RotuloDetalhe (Label)
      %BotaoEncerrar (Button)
    %RotuloEstado (Label)
  %Temporizador (Timer)
```

Sinais conectados na cena: `pressed` de `Raiz/Rodape/BotaoEncerrar` → `_ao_encerrar`; `timeout` de `Temporizador` → `_ao_timer`.

### `features/apps/monitor_sistema/scenes/linha_processo.tscn`

```text
LinhaProcesso (Button + linha_processo.gd)
  Colunas (HBoxContainer)
    %Nome (Label)
    %Pid (Label)
    %Cpu (Label)
    %Memoria (Label)
    %Tipo (Label)
```

Sinais conectados na cena: `pressed` de `.` → `_ao_pressionado`.

### `features/apps/navegador/scenes/app_navegador.tscn`

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
        %Links (RichTextLabel)
    %RotuloTitulo (Label)
    PainelCorpo (PanelContainer)
      Margem (MarginContainer)
        %Corpo (RichTextLabel)
    %RotuloEstado (Label)
```

Sinais conectados na cena: `meta_clicked` → `_ao_link` (2); `meta_hover_ended` → `_ao_link_fim` (2); `meta_hover_started` → `_ao_link_hover` (2); `pressed` de `Raiz/Barra/BotaoAvancar` → `_ao_avancar`; `pressed` de `Raiz/Barra/BotaoInicio` → `_ao_inicio`; `pressed` de `Raiz/Barra/BotaoIr` → `_ao_ir`; `pressed` de `Raiz/Barra/BotaoRecarregar` → `_ao_recarregar`; `pressed` de `Raiz/Barra/BotaoVoltar` → `_ao_voltar`; `text_submitted` de `Raiz/Barra/CampoEndereco` → `_ao_endereco_enviado`.

### `features/apps/terminal/scenes/app_terminal.tscn`

```text
AppTerminal (Control + app_terminal.gd)
  Raiz (VBoxContainer)
    PainelSaida (PanelContainer)
      Margem (MarginContainer)
        %Saida (RichTextLabel)
    LinhaComando (HBoxContainer)
      %RotuloPrompt (Label)
      %Campo (LineEdit)
```

Sinais conectados na cena: `gui_input` de `Raiz/LinhaComando/Campo` → `_ao_entrada_campo`; `text_submitted` de `Raiz/LinhaComando/Campo` → `_ao_enviar`.

### `features/apps/visualizador/scenes/app_visualizador.tscn`

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
        %BotaoTocar (Button)
        %BarraAudio (ProgressBar)
        %RotuloAudio (Label)
    %RotuloLegenda (Label)
    %PainelMeta (PanelContainer, oculto)
      Margem (MarginContainer)
        %GradeMeta (GridContainer)
  %Tocador (AudioStreamPlayer)
  %Temporizador (Timer)
```

Sinais conectados na cena: `finished` de `Tocador` → `_ao_audio_terminou`; `pressed` de `Raiz/CaixaAudio/LinhaAudio/BotaoTocar` → `_ao_alternar_audio`; `pressed` de `Raiz/Topo/BotaoMeta` → `_ao_alternar_meta`; `pressed` de `Raiz/Topo/BotaoAnterior` → `_ao_anterior`; `pressed` de `Raiz/Topo/BotaoProximo` → `_ao_proximo`; `timeout` de `Temporizador` → `_atualizar_progresso`.

### `features/apps/visualizador/scenes/rotulo_meta_chave.tscn`

```text
RotuloMetaChave (Label)
```

### `features/apps/visualizador/scenes/rotulo_meta_valor.tscn`

```text
RotuloMetaValor (Label)
```

---

## `features/menu_principal/`

### `features/menu_principal/scenes/menu_principal.tscn`

```text
MenuPrincipal (Control + menu_principal.gd)
  %Fundo (ColorRect)
  CamadaAtmosferica (Control)
    OrbeAtmosfera (instância de orbe_nexus.tscn)
    Vinheta (TextureRect)
  %MargemPrincipal (MarginContainer)
    Conteudo (VBoxContainer)
      %Logo (TextureRect)
      %Titulo (Label)
      %Subtitulo (Label)
      Separador (HSeparator)
      %Botoes (VBoxContainer)
        %BotaoNovoJogo (Button)
        %BotaoCarregar (Button)
        %BotaoOpcoes (Button)
        %BotaoCreditos (Button)
        %BotaoSair (Button)
      %LinhaStatus (HBoxContainer, oculto)
        %IconeStatus (Label)
        %MensagemStatus (Label)
      %RotuloSalvamento (Label, oculto)
      RotuloDica (Label)
      %Versao (Label)
  %PainelOpcoes (instância de painel_opcoes.tscn)
  %PainelCreditos (instância de painel_creditos.tscn)
  %DialogoConfirmacao (instância de painel_confirmacao.tscn)
  %IndicadorCarregamento (instância de indicador_carregamento.tscn)
```

Sinais conectados na cena: `cancelado` de `DialogoConfirmacao` → `_ao_cancelado`; `confirmado` de `DialogoConfirmacao` → `_ao_confirmado`; `fechado` → `_ao_painel_fechado` (2); `pressed` de `MargemPrincipal/Conteudo/Botoes/BotaoCarregar` → `_ao_carregar`; `pressed` de `MargemPrincipal/Conteudo/Botoes/BotaoCreditos` → `_ao_creditos`; `pressed` de `MargemPrincipal/Conteudo/Botoes/BotaoNovoJogo` → `_ao_novo_jogo`; `pressed` de `MargemPrincipal/Conteudo/Botoes/BotaoOpcoes` → `_ao_opcoes`; `pressed` de `MargemPrincipal/Conteudo/Botoes/BotaoSair` → `_ao_sair`.

### `features/menu_principal/scenes/painel_creditos.tscn`

```text
PainelCreditos (Control + painel_creditos.gd, oculto)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        Caixa (VBoxContainer)
          RotuloTitulo (Label)
          %Rolagem (ScrollContainer)
            %Conteudo (VBoxContainer)
              SecaoJogo (VBoxContainer)
              SecaoEquipe (VBoxContainer)
              SecaoFuncoes (VBoxContainer)
              SecaoTecnologias (VBoxContainer)
              SecaoAssets (VBoxContainer)
              SecaoAudios (VBoxContainer)
              SecaoLicencas (VBoxContainer)
              SecaoAgradecimentos (VBoxContainer)
              SecaoVersao (VBoxContainer)
          Rodape (HBoxContainer)
            %BotaoVoltar (Button)
```

Sinais conectados na cena: `pressed` de `Centro/Painel/Margem/Caixa/Rodape/BotaoVoltar` → `_ao_voltar`.

---

## `features/minigames/`

### `features/minigames/logica/components/porta_logica_item/scenes/porta_logica_item.tscn`

```text
PortaLogicaItem (Button + porta_logica_item.gd)
```

Sinais conectados na cena: `pressed` de `.` → `_ao_pressionar`.

### `features/minigames/logica/components/slot_circuito/scenes/slot_circuito.tscn`

```text
SlotCircuito (PanelContainer + slot_circuito.gd)
  %Rotulo (Label)
```

### `features/minigames/logica/scenes/minigame_logica.tscn`

```text
MinigameLogica (Control + minigame_logica.gd)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        %Caixa (VBoxContainer)
          RotuloTitulo (Label)
          RotuloIntro (Label)
          Separador (HSeparator)
          Meio (HBoxContainer)
            ColunaTabela (VBoxContainer)
              RotuloTabela (Label)
              %GradeTabela (GridContainer)
            ColunaCircuito (VBoxContainer)
              RotuloCircuito (Label)
              LinhaCircuito (HBoxContainer)
          RotuloPortas (Label)
          ListaPortas (HBoxContainer)
            %PortaAND (instância de porta_logica_item.tscn)
            %PortaOR (instância de porta_logica_item.tscn)
            %PortaXOR (instância de porta_logica_item.tscn)
            %PortaNAND (instância de porta_logica_item.tscn)
            %PortaNOR (instância de porta_logica_item.tscn)
          %RotuloStatus (Label)
          %RotuloDica (Label, oculto)
          Botoes (HBoxContainer)
            %BotaoDica (Button)
            %BotaoSolucao (Button, oculto)
            %BotaoLimpar (Button)
            %BotaoCancelar (Button)
            %BotaoTestar (Button)
```

Sinais conectados na cena: `escolhida` → `_ao_escolher_porta` (5); `porta_alterada` de `Centro/Painel/Margem/Caixa/Meio/ColunaCircuito/LinhaCircuito/Encaixe` → `_ao_porta_alterada`; `pressed` de `Centro/Painel/Margem/Caixa/Meio/ColunaCircuito/LinhaCircuito/Entradas/BotaoA` → `_ao_alternar_a`; `pressed` de `Centro/Painel/Margem/Caixa/Meio/ColunaCircuito/LinhaCircuito/Entradas/BotaoB` → `_ao_alternar_b`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoCancelar` → `_ao_cancelar`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoDica` → `_ao_dica`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoLimpar` → `_ao_limpar`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoSolucao` → `_ao_solucao`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoTestar` → `_ao_testar`.

---

## `features/narrative/`

### `features/narrative/finais/components/item_evidencia/scenes/item_evidencia.tscn`

```text
ItemEvidencia (Label + item_evidencia.gd)
```

### `features/narrative/finais/scenes/tela_final.tscn`

```text
TelaFinal (Control + tela_final.gd)
  %Fundo (ColorRect)
  Centro (CenterContainer)
    Rolagem (ScrollContainer)
      Coluna (VBoxContainer)
        %Orbe (instância de orbe_nexus.tscn)
        %RotuloTitulo (Label)
        %RotuloTexto (Label)
        %BotaoPular (Button)
        %Acoes (VBoxContainer, oculto)
          Separador (HSeparator)
          PainelResumo (PanelContainer)
            Margem (MarginContainer)
              Resumo (VBoxContainer)
          %RotuloAviso (Label)
          Botoes (HBoxContainer)
            %BotaoRepetir (Button, oculto)
            %BotaoInicio (Button)
            BotaoSair (Button)
  %TelaFimDeJogo (instância de tela_fim_de_jogo.tscn)
```

Sinais conectados na cena: `pressed` de `Centro/Rolagem/Coluna/Acoes/Botoes/BotaoRepetir` → `_ao_repetir_dia5`; `pressed` de `Centro/Rolagem/Coluna/Acoes/Botoes/BotaoSair` → `_ao_sair`; `pressed` de `Centro/Rolagem/Coluna/Acoes/Botoes/BotaoInicio` → `_ao_voltar_ao_inicio`; `pressed` de `Centro/Rolagem/Coluna/BotaoPular` → `_concluir_texto`; `rever_pedido` de `TelaFimDeJogo` → `_ao_fim_de_jogo_revisto`.

---

## `features/pause/`

### `features/pause/scenes/menu_pausa.tscn`

```text
MenuPausa (Control + menu_pausa.gd, oculto)
  FundoEscurecido (ColorRect)
  Centro (CenterContainer)
    Moldura (PanelContainer)
      %PainelPrincipal (MarginContainer)
        %Conteudo (VBoxContainer)
          %Titulo (Label)
          %RotuloContexto (Label)
          Separador (HSeparator)
          %BotaoContinuar (Button)
          %BotaoSalvar (Button)
          %BotaoCarregar (Button)
          %BotaoRecomecar (Button)
          %BotaoOpcoes (Button)
          %BotaoMenuInicial (Button)
          %LinhaStatus (HBoxContainer, oculto)
            %IconeStatus (Label)
            %MensagemStatus (Label)
          RotuloDica (Label)
  %PainelOpcoes (instância de painel_opcoes.tscn)
  %PainelConfirmacao (instância de painel_confirmacao.tscn)
  %IndicadorCarregamento (instância de indicador_carregamento.tscn)
```

Sinais conectados na cena: `cancelado` de `PainelConfirmacao` → `_ao_cancelado`; `confirmado` de `PainelConfirmacao` → `_ao_confirmado`; `fechado` de `PainelOpcoes` → `_ao_painel_fechado`; `pressed` de `Centro/Moldura/PainelPrincipal/Conteudo/BotaoCarregar` → `_ao_carregar`; `pressed` de `Centro/Moldura/PainelPrincipal/Conteudo/BotaoContinuar` → `_ao_continuar`; `pressed` de `Centro/Moldura/PainelPrincipal/Conteudo/BotaoMenuInicial` → `_ao_menu_inicial`; `pressed` de `Centro/Moldura/PainelPrincipal/Conteudo/BotaoOpcoes` → `_ao_opcoes`; `pressed` de `Centro/Moldura/PainelPrincipal/Conteudo/BotaoRecomecar` → `_ao_recomecar`; `pressed` de `Centro/Moldura/PainelPrincipal/Conteudo/BotaoSalvar` → `_ao_salvar`.

### `features/pause/scenes/tela_fim_de_jogo.tscn`

```text
TelaFimDeJogo (Control + tela_fim_de_jogo.gd, oculto)
  Fundo (ColorRect)
  Centro (CenterContainer)
    Moldura (PanelContainer)
      %Painel (MarginContainer)
        %Conteudo (VBoxContainer)
          %Titulo (Label)
          %MensagemMotivo (Label)
          %Resumo (Label)
          Separador (HSeparator)
          %BotaoRecomecar (Button)
          %BotaoCarregar (Button)
          %BotaoMenuInicial (Button)
          %BotaoRever (Button)
          %LinhaStatus (HBoxContainer, oculto)
            %IconeStatus (Label)
            %MensagemStatus (Label)
          RotuloDica (Label)
  %PainelConfirmacao (instância de painel_confirmacao.tscn)
  %IndicadorCarregamento (instância de indicador_carregamento.tscn)
```

Sinais conectados na cena: `cancelado` de `PainelConfirmacao` → `_ao_cancelado`; `confirmado` de `PainelConfirmacao` → `_ao_confirmado`; `pressed` de `Centro/Moldura/Painel/Conteudo/BotaoCarregar` → `_ao_carregar`; `pressed` de `Centro/Moldura/Painel/Conteudo/BotaoMenuInicial` → `_ao_menu_inicial`; `pressed` de `Centro/Moldura/Painel/Conteudo/BotaoRecomecar` → `_ao_recomecar`; `pressed` de `Centro/Moldura/Painel/Conteudo/BotaoRever` → `_ao_rever`.

---

## `features/puzzles/`

### `features/puzzles/arquivos_criptografados/scenes/dialogo_chave.tscn`

```text
DialogoChave (Control + dialogo_chave.gd)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        %Caixa (VBoxContainer)
          RotuloTitulo (Label)
          %RotuloNome (Label)
          RotuloInstrucao (Label)
          %Campo (LineEdit)
          %CaixaMostrar (CheckBox)
          %RotuloErro (Label, oculto)
          %RotuloDica (Label, oculto)
          Botoes (HBoxContainer)
            %BotaoDica (Button)
            %BotaoCancelar (Button)
            %BotaoDecifrar (Button)
```

Sinais conectados na cena: `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoCancelar` → `_ao_cancelar`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoDecifrar` → `_ao_decifrar`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoDica` → `_ao_mostrar_dica`; `text_submitted` de `Centro/Painel/Margem/Caixa/Campo` → `_ao_enviar_texto`; `toggled` de `Centro/Painel/Margem/Caixa/CaixaMostrar` → `_ao_mostrar_chave`.

---

## `features/shell/`

### `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn`

```text
AreaDeTrabalho (Control + area_de_trabalho.gd)
  CamadaFundo (Control)
    %PapelDeParede (instância de papel_de_parede.tscn)
  CamadaIcones (Control)
    %GradeIcones (VFlowContainer)
  CamadaWidgets (Control)
    ColunaWidgets (VBoxContainer)
      %WidgetRelogio (instância de widget_relogio.tscn)
      %WidgetNexus (instância de widget_nexus.tscn)
  %CamadaJanelas (Control)
  CamadaShell (Control)
    %BarraTarefas (instância de barra_de_tarefas.tscn)
    %MenuIniciar (instância de menu_iniciar.tscn)
    %CentroNotificacoes (instância de centro_notificacoes.tscn)
  CamadaToasts (Control)
    %PilhaToasts (instância de pilha_toasts.tscn)
  CamadaEfeitos (Control)
    %EfeitoGlitch (instância de efeito_glitch.tscn)
    %CartaoDia (instância de cartao_dia.tscn)
  %CamadaModais (Control)
  CamadaDebug (Control)
    %PainelDebug (instância de painel_debug.tscn)
  %MenuPausa (instância de menu_pausa.tscn)
  %TelaFimDeJogo (instância de tela_fim_de_jogo.tscn)
```

### `features/shell/area_de_trabalho/scenes/cartao_dia.tscn`

```text
CartaoDia (Control + cartao_dia.gd)
  Centro (CenterContainer)
    %Painel (PanelContainer, oculto)
      Margem (MarginContainer)
        Caixa (VBoxContainer)
          %RotuloDia (Label)
          %RotuloTitulo (Label)
          %RotuloSub (Label)
```

### `features/shell/area_de_trabalho/scenes/icone_area_de_trabalho.tscn`

```text
IconeAreaDeTrabalho (Button + icone_area_de_trabalho.gd)
  Caixa (VBoxContainer)
    %Icone (instância de icone_app.tscn)
    %Rotulo (Label)
```

Sinais conectados na cena: `gui_input` de `.` → `_ao_entrada`; `pressed` de `.` → `_ao_pressionado`.

### `features/shell/area_de_trabalho/scenes/painel_debug.tscn`

```text
PainelDebug (PanelContainer + painel_debug.gd, oculto)
  Margem (MarginContainer)
    Raiz (VBoxContainer)
      Cabecalho (HBoxContainer)
        Titulo (Label)
        Espaco (Control)
        BotaoFechar (Button)
      %RotuloEstado (Label)
      Grade (GridContainer)
        BotaoConcluir (Button)
        BotaoEncerrar (Button)
        BotaoGlitch (Button)
        BotaoCorrupcao (Button)
        BotaoSeguranca (Button)
        BotaoToastInfo (Button)
        BotaoToastCritico (Button)
        BotaoLiberarApps (Button)
        BotaoProcesso (Button)
        BotaoSalvar (Button)
      LinhaDia (HBoxContainer)
        TituloDia (Label)
        %SpinDia (SpinBox)
        BotaoIr (Button)
      TituloFlags (Label)
      %ListaFlags (RichTextLabel)
```

Sinais conectados na cena: `pressed` de `Margem/Raiz/Grade/BotaoConcluir` → `_ao_concluir`; `pressed` de `Margem/Raiz/Grade/BotaoCorrupcao` → `_ao_corrupcao`; `pressed` de `Margem/Raiz/Grade/BotaoEncerrar` → `_ao_encerrar`; `pressed` de `Margem/Raiz/Grade/BotaoGlitch` → `_ao_glitch`; `pressed` de `Margem/Raiz/LinhaDia/BotaoIr` → `_ao_ir_para_dia`; `pressed` de `Margem/Raiz/Grade/BotaoLiberarApps` → `_ao_liberar_apps`; `pressed` de `Margem/Raiz/Grade/BotaoProcesso` → `_ao_processo`; `pressed` de `Margem/Raiz/Grade/BotaoSalvar` → `_ao_salvar`; `pressed` de `Margem/Raiz/Grade/BotaoSeguranca` → `_ao_seguranca`; `pressed` de `Margem/Raiz/Grade/BotaoToastCritico` → `_ao_toast_critico`; `pressed` de `Margem/Raiz/Grade/BotaoToastInfo` → `_ao_toast_info`; `pressed` de `Margem/Raiz/Cabecalho/BotaoFechar` → `alternar`.

### `features/shell/area_de_trabalho/scenes/papel_de_parede.tscn`

```text
PapelDeParede (Control + papel_de_parede.gd)
```

### `features/shell/barra_de_tarefas/scenes/barra_de_tarefas.tscn`

```text
BarraTarefas (PanelContainer + barra_de_tarefas.gd)
  Raiz (HBoxContainer)
    %BotaoIniciar (Button)
    Separador1 (VSeparator)
    %CaixaFixados (HBoxContainer)
    Separador2 (VSeparator)
    %CaixaJanelas (HBoxContainer)
    %RotuloSeg (Label)
    %RotuloCor (Label)
    %RotuloMic (Label)
    Separador3 (VSeparator)
    %BotaoNotificacoes (Button)
    Relogio (VBoxContainer)
      %RotuloHora (Label)
      %RotuloData (Label)
```

Sinais conectados na cena: `pressed` de `Raiz/BotaoIniciar` → `_ao_iniciar`; `pressed` de `Raiz/BotaoNotificacoes` → `_ao_notificacoes`.

### `features/shell/barra_de_tarefas/scenes/botao_tarefa.tscn`

```text
BotaoTarefaApp (Button + botao_tarefa.gd)
  Linha (HBoxContainer)
    %Icone (instância de icone_app.tscn)
    %Rotulo (Label, oculto)
```

### `features/shell/centro_notificacoes/scenes/cartao_notificacao.tscn`

```text
CartaoNotificacao (PanelContainer + cartao_notificacao.gd)
  Margem (MarginContainer)
    Coluna (VBoxContainer)
      Cabecalho (HBoxContainer)
        %Tag (Label)
        %Nova (Label, oculto)
        %Hora (Label)
      %Titulo (Label)
      %Corpo (Label)
      %BotaoAbrir (Button, oculto)
```

Sinais conectados na cena: `pressed` de `Margem/Coluna/BotaoAbrir` → `_ao_abrir`.

### `features/shell/centro_notificacoes/scenes/centro_notificacoes.tscn`

```text
CentroNotificacoes (Control + centro_notificacoes.gd, oculto)
  %Fora (ColorRect)
  %Painel (PanelContainer)
    Margem (MarginContainer)
      Raiz (VBoxContainer)
        Cabecalho (HBoxContainer)
          Titulo (Label)
          %RotuloResumo (Label)
          BotaoLimpar (Button)
        %Silenciar (CheckBox)
        Separador (HSeparator)
        Rolagem (ScrollContainer)
          %Lista (VBoxContainer)
            %RotuloVazio (Label, oculto)
```

Sinais conectados na cena: `gui_input` de `Fora` → `_ao_clique_fora`; `pressed` de `Painel/Margem/Raiz/Cabecalho/BotaoLimpar` → `_ao_limpar`; `toggled` de `Painel/Margem/Raiz/Silenciar` → `_ao_silenciar`.

### `features/shell/data_e_hora/scenes/widget_relogio.tscn`

```text
WidgetRelogio (PanelContainer + widget_relogio.gd)
  Margem (MarginContainer)
    Caixa (VBoxContainer)
      %RotuloHora (Label)
      %RotuloData (Label)
      %RotuloDia (Label)
```

### `features/shell/efeito_glitch/scenes/efeito_glitch.tscn`

```text
EfeitoGlitch (Control + efeito_glitch.gd)
  %Retangulo (ColorRect, oculto)
```

### `features/shell/janela_inicial/scenes/botao_app_menu.tscn`

```text
BotaoAppMenu (Button + botao_app_menu.gd)
  Linha (HBoxContainer)
    %Icone (instância de icone_app.tscn)
    %Nome (Label)
    %Etiqueta (Label, oculto)
```

### `features/shell/janela_inicial/scenes/menu_iniciar.tscn`

```text
MenuIniciar (Control + menu_iniciar.gd, oculto)
  %Fora (ColorRect)
  %Painel (PanelContainer)
    Margem (MarginContainer)
      Raiz (VBoxContainer)
        Cabecalho (HBoxContainer)
          %Orbe (instância de orbe_nexus.tscn)
          Textos (VBoxContainer)
            %RotuloDia (Label)
            %RotuloIa (Label)
        %Campo (LineEdit)
        %RolagemApps (ScrollContainer)
          %Grade (GridContainer)
        %RolagemBusca (ScrollContainer, oculto)
          CaixaBusca (VBoxContainer)
            %SemResultado (Label, oculto)
            %SecaoApps (VBoxContainer, oculto)
              TituloApps (Label)
              %ListaApps (VBoxContainer)
            %SecaoArquivos (VBoxContainer, oculto)
              TituloArquivos (Label)
              %ListaArquivos (VBoxContainer)
        Separador (HSeparator)
        Rodape (HBoxContainer)
          BotaoDica (Button)
          BotaoEncerrarDia (Button)
          BotaoSalvar (Button)
          Espacador (Control)
          BotaoSair (Button)
```

Sinais conectados na cena: `gui_input` de `Fora` → `_ao_clique_fora`; `pressed` de `Painel/Margem/Raiz/Rodape/BotaoDica` → `_ao_dica`; `pressed` de `Painel/Margem/Raiz/Rodape/BotaoEncerrarDia` → `_ao_encerrar_dia`; `pressed` de `Painel/Margem/Raiz/Rodape/BotaoSair` → `_ao_sair`; `pressed` de `Painel/Margem/Raiz/Rodape/BotaoSalvar` → `_ao_salvar`; `text_changed` de `Painel/Margem/Raiz/Campo` → `_ao_busca`; `text_submitted` de `Painel/Margem/Raiz/Campo` → `_ao_busca_enviada`.

### `features/shell/janela_inicial/scenes/resultado_busca.tscn`

```text
ResultadoBusca (Button + resultado_busca.gd)
  Linha (HBoxContainer)
    %Icone (instância de icone_app.tscn)
    %Emoji (Label, oculto)
    Textos (VBoxContainer)
      %Titulo (Label)
      %Detalhe (Label)
```

### `features/shell/popup_notificacao/scenes/pilha_toasts.tscn`

```text
PilhaToasts (Control + pilha_toasts.gd)
  %Pilha (VBoxContainer)
```

### `features/shell/popup_notificacao/scenes/popup_notificacao.tscn`

```text
PopupNotificacao (PanelContainer + popup_notificacao.gd)
  Externo (VBoxContainer)
    Linha (HBoxContainer)
      %Icone (Label)
      Textos (VBoxContainer)
        Cabecalho (HBoxContainer)
          %Tag (Label)
          %Hora (Label)
        %Titulo (Label)
        %Corpo (Label)
        %Dica (Label, oculto)
      %BotaoFechar (Button)
    Trilho (Control)
      %Barra (ColorRect)
```

Sinais conectados na cena: `gui_input` de `.` → `_ao_entrada`; `pressed` de `Externo/Linha/BotaoFechar` → `_ao_fechar_botao`.

### `features/shell/tela_boot/scenes/tela_boot.tscn`

```text
TelaBoot (Control + tela_boot.gd)
  %Fundo (ColorRect)
  Margem (MarginContainer)
    Coluna (VBoxContainer)
      %Log (RichTextLabel)
      RotuloAviso (Label)
  %Menu (Control, oculto)
    Cortina (ColorRect)
    Centro (CenterContainer)
      Painel (PanelContainer)
        Margem (MarginContainer)
          Caixa (VBoxContainer)
            RotuloTitulo (Label)
            RotuloSubtitulo (Label)
            Separador1 (HSeparator)
            %RotuloSalvo (Label)
            %BotaoContinuar (Button)
            RotuloNovo (Label)
            %CampoNome (LineEdit)
            %RotuloErro (Label, oculto)
            LinhaEntrar (HBoxContainer)
              %BotaoEntrar (Button)
              BotaoNomePadrao (Button)
            Separador2 (HSeparator)
            RotuloAcessibilidade (Label)
            %CaixaConforto (CheckBox)
            %CaixaContraste (CheckBox)
            Rodape (HBoxContainer)
              %BotaoVoltar (Button, oculto)
              BotaoTelaCheia (Button)
              Espacador (Control)
              BotaoSair (Button)
  %Saudacao (Control, oculto)
    Cortina (ColorRect)
    Centro (CenterContainer)
      Coluna (VBoxContainer)
        %Orbe (instância de orbe_nexus.tscn)
        RotuloNexus (Label)
        %RotuloFala (Label)
        %BotaoSaudacao (Button)
```

Sinais conectados na cena: `pressed` de `Menu/Centro/Painel/Margem/Caixa/BotaoContinuar` → `_ao_continuar`; `pressed` de `Menu/Centro/Painel/Margem/Caixa/LinhaEntrar/BotaoEntrar` → `_ao_entrar`; `pressed` de `Menu/Centro/Painel/Margem/Caixa/LinhaEntrar/BotaoNomePadrao` → `_ao_nome_padrao`; `pressed` de `Menu/Centro/Painel/Margem/Caixa/Rodape/BotaoSair` → `_ao_sair`; `pressed` de `Saudacao/Centro/Coluna/BotaoSaudacao` → `_ao_saudacao_continuar`; `pressed` de `Menu/Centro/Painel/Margem/Caixa/Rodape/BotaoTelaCheia` → `_ao_tela_cheia`; `pressed` de `Menu/Centro/Painel/Margem/Caixa/Rodape/BotaoVoltar` → `_ao_voltar`; `text_changed` de `Menu/Centro/Painel/Margem/Caixa/CampoNome` → `_ao_nome_alterado`; `text_submitted` de `Menu/Centro/Painel/Margem/Caixa/CampoNome` → `_ao_nome_enviado`; `toggled` de `Menu/Centro/Painel/Margem/Caixa/CaixaConforto` → `_ao_conforto`; `toggled` de `Menu/Centro/Painel/Margem/Caixa/CaixaContraste` → `_ao_contraste`.

### `features/shell/widget_nexus/scenes/item_objetivo.tscn`

```text
ItemObjetivo (Label + item_objetivo.gd)
```

### `features/shell/widget_nexus/scenes/widget_nexus.tscn`

```text
WidgetNexus (PanelContainer + widget_nexus.gd)
  Margem (MarginContainer)
    Raiz (VBoxContainer)
      Cabecalho (HBoxContainer)
        %Orbe (instância de orbe_nexus.tscn)
        Textos (VBoxContainer)
          Titulo (Label)
          %RotuloEstado (Label)
        %BotaoRecolher (Button)
      %Corpo (VBoxContainer)
        %RotuloFala (Label)
        Separador1 (HSeparator)
        LinhaObjetivos (HBoxContainer)
          %TituloObjetivos (Label)
          %RotuloProgresso (Label)
        CaixaObjetivos (VBoxContainer)
          %ListaObjetivos (VBoxContainer)
          %RotuloPronto (Label, oculto)
          %RotuloUltimo (Label, oculto)
        Separador2 (HSeparator)
        %RotuloSeg (Label)
        %BarraSeg (ProgressBar)
        %RotuloCor (Label)
        %BarraCor (ProgressBar)
        Botoes (HBoxContainer)
          BotaoDica (Button)
          BotaoFalar (Button)
```

Sinais conectados na cena: `pressed` de `Margem/Raiz/Corpo/Botoes/BotaoDica` → `_ao_dica`; `pressed` de `Margem/Raiz/Corpo/Botoes/BotaoFalar` → `_ao_falar`; `pressed` de `Margem/Raiz/Cabecalho/BotaoRecolher` → `_ao_recolher`.

---

## `features/splash_screen/`

### `features/splash_screen/scenes/splash_screen.tscn`

```text
SplashScreen (Control + splash_screen.gd)
  %FundoPreto (ColorRect)
  %ContainerVideo (AspectRatioContainer)
    %VideoLogo (VideoStreamPlayer)
  %LogoFallback (TextureRect)
  %CamadaInteracao (Control)
    %IndicadorPular (Label)
  %PainelFalha (CenterContainer, oculto)
    Moldura (PanelContainer)
      Margem (MarginContainer)
        Conteudo (VBoxContainer)
          TituloFalha (Label)
          %MensagemFalha (Label)
          %BotaoTentarNovamente (Button)
          %BotaoSair (Button)
  %FadeOverlay (ColorRect)
```

Sinais conectados na cena: `pressed` de `PainelFalha/Moldura/Margem/Conteudo/BotaoSair` → `_ao_sair`; `pressed` de `PainelFalha/Moldura/Margem/Conteudo/BotaoTentarNovamente` → `_ao_tentar_novamente`.

---

## `shared/ui/`

### `shared/ui/dialogo_arquivo/scenes/dialogo_arquivo.tscn`

```text
DialogoArquivo (Control + dialogo_arquivo.gd)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        %Caixa (VBoxContainer)
          %RotuloTitulo (Label)
          Topo (HBoxContainer)
            %BotaoSubir (Button)
            %RotuloPasta (Label)
          %Lista (ItemList)
          %Campo (LineEdit, oculto)
          %RotuloErro (Label, oculto)
          Botoes (HBoxContainer)
            %BotaoCancelar (Button)
            %BotaoConfirmar (Button)
```

Sinais conectados na cena: `item_activated` de `Centro/Painel/Margem/Caixa/Lista` → `_ao_item_ativado`; `item_selected` de `Centro/Painel/Margem/Caixa/Lista` → `_ao_item_selecionado`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoCancelar` → `_ao_cancelar`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoConfirmar` → `_ao_confirmar`; `pressed` de `Centro/Painel/Margem/Caixa/Topo/BotaoSubir` → `_ao_subir`; `text_submitted` de `Centro/Painel/Margem/Caixa/Campo` → `_ao_nome_enviado`.

### `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn`

```text
DialogoNexus (Control + dialogo_nexus.gd)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        %Caixa (VBoxContainer)
          %RotuloTitulo (Label)
          %RotuloCorpo (Label)
          %Campo (LineEdit, oculto)
          %RotuloErro (Label, oculto)
          %Botoes (HBoxContainer)
            %BotaoCancelar (Button)
            %BotaoOk (Button)
```

Sinais conectados na cena: `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoCancelar` → `_ao_cancelar`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoOk` → `_ao_confirmar`; `text_submitted` de `Centro/Painel/Margem/Caixa/Campo` → `_ao_texto_enviado`.

### `shared/ui/icone_app/scenes/icone_app.tscn`

```text
IconeApp (Control + icone_app.gd)
  %Imagem (TextureRect, oculto)
  %Bloco (PanelContainer)
    %Glifo (Label)
```

### `shared/ui/indicador_carregamento/scenes/indicador_carregamento.tscn`

```text
IndicadorCarregamento (Control + indicador_carregamento.gd, oculto)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        Caixa (VBoxContainer)
          %Rotulo (Label)
          %Barra (ProgressBar)
```

### `shared/ui/janela_base/scenes/janela_base.tscn`

```text
JanelaBase (Control + janela_base.gd)
  %Fundo (Panel)
  Layout (VBoxContainer)
    %Barra (Panel)
      MargemBarra (MarginContainer)
        Linha (HBoxContainer)
          %IconeTitulo (Control)
            %IconeApp (instância de icone_app.tscn)
          %RotuloTitulo (Label)
          BotaoMinimizar (Button)
            Icone (Control)
          %BotaoMaximizar (Button)
            %IconeMaximizar (Control)
          BotaoFechar (Button)
            Icone (Control)
    MargemArea (MarginContainer)
      %Area (Control)
  %Alcas (Control)
    AlcaNoroeste (Control)
    AlcaNorte (Control)
    AlcaNordeste (Control)
    AlcaOeste (Control)
    AlcaLeste (Control)
    AlcaSudoeste (Control)
    AlcaSul (Control)
    AlcaSudeste (Control)
```

Sinais conectados na cena: `gui_input` → `_ao_alca_input` (8); `gui_input` de `Layout/Barra` → `_ao_barra_input`; `pressed` de `Layout/Barra/MargemBarra/Linha/BotaoFechar` → `_ao_fechar_pressionado`; `pressed` de `Layout/Barra/MargemBarra/Linha/BotaoMaximizar` → `_ao_maximizar_pressionado`; `pressed` de `Layout/Barra/MargemBarra/Linha/BotaoMinimizar` → `_ao_minimizar_pressionado`; `resized` de `.` → `_ao_redimensionar`.

### `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn`

```text
OrbeNexus (Control + orbe_nexus.gd)
```

### `shared/ui/painel_confirmacao/scenes/painel_confirmacao.tscn`

```text
PainelConfirmacao (Control + painel_confirmacao.gd, oculto)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        Caixa (VBoxContainer)
          %RotuloTitulo (Label)
          %RotuloTexto (Label)
          Botoes (HBoxContainer)
            %BotaoCancelar (Button)
            %BotaoConfirmar (Button)
```

Sinais conectados na cena: `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoCancelar` → `_ao_cancelar`; `pressed` de `Centro/Painel/Margem/Caixa/Botoes/BotaoConfirmar` → `_ao_confirmar`.

### `shared/ui/painel_opcoes/scenes/painel_opcoes.tscn`

```text
PainelOpcoes (Control + painel_opcoes.gd, oculto)
  Cortina (ColorRect)
  Centro (CenterContainer)
    Painel (PanelContainer)
      Margem (MarginContainer)
        Caixa (VBoxContainer)
          RotuloTitulo (Label)
          RotuloAjuda (Label)
          %Rolagem (ScrollContainer)
            %Linhas (VBoxContainer)
              TituloAudio (Label)
              VolumeGeral (instância de linha_slider.tscn)
              VolumeMusica (instância de linha_slider.tscn)
              VolumeEfeitos (instância de linha_slider.tscn)
              Separador1 (HSeparator)
              TituloTela (Label)
              %BotaoTelaCheia (Button)
              OpcaoTamanhoTexto (instância de linha_opcao.tscn)
              OpcaoAltoContraste (instância de linha_check.tscn)
              Separador2 (HSeparator)
              TituloAcessibilidade (Label)
              OpcaoConforto (instância de linha_check.tscn)
              OpcaoReduzirAnimacoes (instância de linha_check.tscn)
              OpcaoReduzirGlitch (instância de linha_check.tscn)
              OpcaoReduzirTremor (instância de linha_check.tscn)
              OpcaoSemFlashes (instância de linha_check.tscn)
              OpcaoReduzirRuido (instância de linha_check.tscn)
              Separador3 (HSeparator)
              TituloJogo (Label)
              OpcaoDificuldade (instância de linha_opcao.tscn)
          Rodape (HBoxContainer)
            %BotaoVoltar (Button)
```

Sinais conectados na cena: `pressed` de `Centro/Painel/Margem/Caixa/Rolagem/Linhas/BotaoTelaCheia` → `_ao_tela_cheia`; `pressed` de `Centro/Painel/Margem/Caixa/Rodape/BotaoVoltar` → `_ao_voltar`.
