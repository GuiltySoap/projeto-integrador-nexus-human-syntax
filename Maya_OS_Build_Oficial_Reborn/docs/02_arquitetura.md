# 15.2 Arquitetura

> **Nota sobre os nomes (2026-11-13).** O jogo passou a se chamar **Maya Human Syntax**, o sistema simulado a **HumaxOS** e a assistente de IA a **Maya**. Este documento descreve uma etapa anterior ao rebranding; os nomes antigos que ele cita (NEXUS, NEXUS OS, `scan_nexus`, `destroy_nexus`, `nexus://`, `nexus_override_daemon.exe`...) são os da época. Hoje valem Maya, HumaxOS, `scan_maya`, `destroy_maya`, `humax://` e `maya_override_daemon.exe`. Os identificadores internos (arquivos, classes, nós, IDs, flags, ações do Input Map e a pasta `user://nexus_os/`) continuam como estão. Veja [`12_rebranding_maya_human_syntax.md`](12_rebranding_maya_human_syntax.md) e [`13_auditoria_de_marca.md`](13_auditoria_de_marca.md).

> **Atualização (2026-11-09).** A interface agora é montada em cenas `.tscn` editáveis (não mais em código). Onde este documento fala de `UiKit` construindo nós ou de cenas só com a raiz, leia como a etapa anterior; a descrição atual está em [`10_refatoracao_ui.md`](10_refatoracao_ui.md) e [`04_hierarquia_das_cenas.md`](04_hierarquia_das_cenas.md).

> **Atualização (2026-11-13, Splash Screen).** A cena principal agora é `features/splash_screen/scenes/splash_screen.tscn`, que só mostra a marca e entrega ao Menu Principal pela camada `Cenas`; a `tela_boot` deixou de ser a cena principal e passou a ser o boot do Novo Jogo (BIOS, registro, saudação da Maya). A árvore abaixo é a da etapa original e não lista `splash_screen/`, `menu_principal/` nem `pause/`; veja [`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md) e [`15_splash_screen.md`](15_splash_screen.md).

## Árvore de pastas

A organização é **por funcionalidade**: tudo que pertence a um recurso (cenas, scripts, assets e resources exclusivos) fica junto dele. O que mais de uma funcionalidade usa sobe para `shared/` (interface e assets) ou `core/` (serviços, dados e utilitários).

```text
res://
├── project.godot
├── README.md
├── .gitignore                       # ignora .godot/ e temporários do editor
├── .gitattributes
├── addons/                          # plugins de terceiros (vazio)
├── backend/                         # protótipo em C e JSONs antigos; fora do jogo Godot
├── core/
│   ├── autoload/                    # 9 serviços globais (ordem de registro abaixo)
│   │   ├── relogio_global.gd
│   │   ├── gerenciador_configuracoes.gd
│   │   ├── gerenciador_estado.gd
│   │   ├── sistema_audio.gd
│   │   ├── sistema_notificacoes.gd
│   │   ├── sistema_arquivos_virtual.gd
│   │   ├── gerenciador_janelas.gd
│   │   ├── gerenciador_narrativa.gd
│   │   └── sistema_persistencia.gd
│   ├── data/                        # dados da história e do sistema (JSON)
│   │   ├── catalogo_apps.json
│   │   ├── vfs_inicial.json
│   │   └── narrativa/               # dias, conversas, emails, calendario, paginas_web, processos, finais
│   └── utilities/                   # funções estáticas e classes auxiliares (sem estado global)
│       ├── abridor_arquivos.gd  cenas.gd  conexoes.gd  imagem_procedural.gd
│       └── tema_nexus.gd  ui_kit.gd  util_texto.gd
├── shared/
│   ├── assets/                      # audio/ fonts/ icons/ textures/ (todos opcionais)
│   ├── themes/                      # reservado para .tres de tema (o tema padrão é feito em código)
│   └── ui/                          # componentes usados por várias funcionalidades
│       ├── app_base/                # contrato de todo aplicativo
│       ├── janela_base/             # janela do sistema (+ janela_base.tscn)
│       ├── dialogo_nexus/           # alerta, confirmar, texto, escolha
│       ├── dialogo_arquivo/         # abrir/salvar sobre o VFS
│       └── orbe_nexus/              # orbe reativo da IA
├── features/
│   ├── splash_screen/               # splash_screen.tscn (cena principal: logo animada → Menu Principal) + vídeo .ogv e logo
│   ├── shell/                       # a "interface do sistema"
│   │   ├── tela_boot/               # tela_boot.tscn (boot do HumaxOS, aberto pelo Novo Jogo)
│   │   ├── area_de_trabalho/        # area_de_trabalho.tscn + camadas, ícones, debug, papel de parede
│   │   ├── barra_de_tarefas/        # iniciar, fixados, janelas, bandeja
│   │   ├── janela_inicial/          # menu iniciar e fluxo de dicas
│   │   ├── popup_notificacao/       # toast e pilha de toasts
│   │   ├── centro_notificacoes/     # histórico de notificações
│   │   ├── widget_nexus/            # widget da IA (orbe, fala do dia, objetivos)
│   │   ├── data_e_hora/             # widget de relógio
│   │   └── efeito_glitch/           # glitch/corrupção visual com opções de acessibilidade
│   ├── apps/
│   │   ├── explorador/  terminal/  bloco_de_notas/  calculadora/  config/
│   │   ├── navegador/  monitor_sistema/  mensageiro/ (+ components/balao_chat)
│   │   └── visualizador/  calendario/  email/  leitor_texto/
│   ├── minigames/logica/            # cofre lógico (+ components/porta_logica_item, slot_circuito)
│   ├── puzzles/
│   │   ├── arquivos_criptografados/ # diálogo de chave (Lixeira e memorias_backup.zip)
│   │   └── evento_processo/         # tabela de processos simulada (Terminal + Monitor)
│   └── narrative/finais/            # tela_final.tscn
├── docs/                            # esta documentação
├── tests/                           # smoke_test.gd (headless)
└── tools/                           # scripts Python de apoio (não entram no jogo)
    ├── gerar_cenas.py  gerar_indice_codigo.py  validar_projeto.py
    ├── gerar_icones.py  gerar_imagens.py  gerar_audio.py      # mídia autoral de shared/assets/ (opcional)
```

Fora do projeto, em tempo de execução:

```text
user://nexus_os/
├── salvamento.json              # progresso, VFS, mensagens, flags (autosave a cada 12 s com alteração + ao sair)
├── checkpoint_dia_<N>.json      # início de cada dia (permite refazer um dia)
└── configuracoes.cfg            # preferências e acessibilidade
```

`.godot/` é cache do editor e **não** é versionada.

### Como isto se relaciona com a estrutura sugerida no prompt

| Sugestão do prompt | No projeto |
|---|---|
| `assets/shared/...` | `shared/assets/...` (áudio, fontes, ícones, texturas) |
| `src/core/...` | `core/...` (sem o nível `src/`) |
| `src/features/...` | `features/...` |
| `src/shared/...` | `shared/...` |
| `src/tests/` | `tests/` |
| `user_data/README.md` | não existe: dados do jogador ficam em `user://nexus_os/` |
| pastas de apps em inglês e `app_*` duplicadas | uma pasta por app, em português (`explorador`, `navegador`...). Os **ids** do catálogo seguem os nomes do prompt (`explorer`, `browser`, `task_manager`...) |

O nível `src/` não foi criado porque o projeto já estava organizado em `core/`, `shared/` e `features/`, e mover tudo exigiria reescrever UIDs e referências sem ganho real.

### Aplicativos: id, pasta, classe

| id (catálogo) | Pasta | Classe | Libera no dia |
|---|---|---|---|
| `explorer` | `features/apps/explorador` | `AppExplorador` | 1 |
| `text_editor` | `features/apps/bloco_de_notas` | `AppBlocoDeNotas` | 1 |
| `messenger` | `features/apps/mensageiro` | `AppMensageiro` | 1 |
| `email` | `features/apps/email` | `AppEmail` | 1 |
| `media_viewer` | `features/apps/visualizador` | `AppVisualizador` | 1 |
| `calendar` | `features/apps/calendario` | `AppCalendario` | 1 |
| `calculator` | `features/apps/calculadora` | `AppCalculadora` | 1 |
| `settings` | `features/apps/config` | `AppConfig` | 1 |
| `browser` | `features/apps/navegador` | `AppNavegador` | 2 |
| `terminal` | `features/apps/terminal` | `AppTerminal` | 2 |
| `task_manager` | `features/apps/monitor_sistema` | `AppMonitorSistema` | 3 |
| `text_reader` | `features/apps/leitor_texto` | `AppLeitorTexto` | 1 (sem atalho; abre pelo Explorador) |

O **Relógio** pedido no prompt existe como widget da área de trabalho (`WidgetRelogio`), como relógio da barra de tarefas e dentro da Agenda, todos alimentados pelo mesmo `RelogioGlobal`.

## Responsabilidade de cada pasta

| Pasta | Responsabilidade | Pode depender de |
|---|---|---|
| `core/autoload` | Serviços globais, cada um com uma responsabilidade (tabela a seguir). | outros autoloads **anteriores** na ordem de registro, `core/utilities` |
| `core/data` | Dados da história e do sistema em JSON. Alterar história = editar JSON. | — |
| `core/utilities` | Código sem estado global: tema, construtores de interface, texto, troca de cena, conexões de sinais. | autoloads (somente `TemaNexus`/`UiKit` para configurações e tema) |
| `shared/ui` | Componentes reutilizáveis: janela, base de aplicativo, diálogos, orbe. | `core` |
| `shared/assets` | Fontes, ícones, texturas e áudio compartilhados. Todos opcionais. | — |
| `features/shell` | A interface do sistema: boot, área de trabalho, barra, menu, toasts, widgets, efeitos. Só reage a sinais. | `core`, `shared` |
| `features/apps` | Um aplicativo por pasta. Cada um herda `AppBase` e roda dentro de uma `JanelaBase`. | `core`, `shared` |
| `features/minigames`, `features/puzzles` | Puzzles. Recebem dados e emitem `resolvido`; quem decide as consequências é a narrativa. | `core`, `shared` |
| `features/narrative` | Tela de final. A lógica dos finais fica em `GerenciadorNarrativa` e `finais.json`. | `core`, `shared` |
| `tests`, `tools`, `docs` | Teste de fumaça, scripts de apoio e documentação. Não entram na exportação. | — |

## Autoloads

Ordem de registro em `project.godot` (cada autoload só depende dos que vêm antes, o que evita dependência circular):

| # | Autoload | Responsabilidade | Depende de | Sinais principais |
|---|---|---|---|---|
| 1 | `RelogioGlobal` | Relógio único do jogo (hora real, data fictícia por dia). Evita Timers espalhados: todos escutam `segundo_passou` e `minuto_mudou`. | — | `segundo_passou`, `minuto_mudou` |
| 2 | `GerenciadorConfiguracoes` | Preferências e acessibilidade em `user://nexus_os/configuracoes.cfg`; registra o Input Map em código; modo conforto; tela cheia. | — | `configuracao_alterada` |
| 3 | `GerenciadorEstado` | **Somente dados e sinais**: dia, jogador, flags, objetivos, corrupção e segurança, estado da IA, permissões simuladas, processos, mensagens, contatos bloqueados, final. Serializa/restaura o estado. | Configurações | `dia_mudou`, `flag_alterada`, `objetivo_concluido`, `corrupcao_mudou`, `seguranca_mudou`, `mensagem_recebida`, `contato_bloqueado`, `final_alcancado`, `glitch_solicitado`, `gaslighting_solicitado` e outros |
| 4 | `SistemaAudio` | Usa o arquivo em `shared/assets/audio` quando existe (9 efeitos `.wav` e `bgm_dia_1..5.ogg` já inclusos; a trilha de arquivo tem o laço garantido em código) e, quando falta, gera o som em código (`AudioStreamWAV`); cria os barramentos `BGM` e `SFX` se não existirem. | Configurações, Estado | — |
| 5 | `SistemaNotificacoes` | Fila e histórico (até 60) de notificações. Só dados: quem desenha os toasts é a área de trabalho. | Estado, Relógio | `notificacao_emitida`, `historico_alterado` |
| 6 | `SistemaArquivosVirtual` | VFS **somente em memória**: normaliza e valida caminhos, ocultos, somente leitura, criptografia, lixeira, busca. Nunca toca o disco. | Estado | `arvore_alterada`, `arquivo_alterado`, `chave_incorreta` |
| 7 | `GerenciadorJanelas` | Catálogo de aplicativos, abertura/fechamento/foco/minimização, z-order, diálogos modais. Todos os módulos que listam apps leem o catálogo daqui. | Estado, Áudio, Notificações | `janela_aberta`, `janela_fechada`, `janela_focada`, `janelas_alteradas`, `catalogo_alterado` |
| 8 | `GerenciadorNarrativa` | Motor da história: dias, objetivos, eventos, mensagens, processo malicioso simulado, terminal de emergência, finais. **Não conhece janelas nem interface**: pede coisas por sinal (`abrir_app_solicitado`). | Configurações, Estado, Relógio, VFS, Áudio, Notificações | `dia_iniciado`, `dia_encerrado`, `objetivos_atualizados`, `evento_disparado`, `jogo_finalizado`, `processo_iniciado`, `processo_finalizado`, `abrir_app_solicitado` |
| 9 | `SistemaPersistencia` | Salvar/carregar, autosave, checkpoints. Só escreve em `user://nexus_os/`. Um save ilegível é renomeado para `.corrompido` e o jogo segue com um novo. | Estado, Narrativa, VFS | `salvo`, `falha_ao_carregar` |

## Relação entre os módulos

```text
          ┌────────────────────────────── features/ (interface e conteúdo) ──────────────────────────────┐
          │  shell (boot, área de trabalho, barra, menu, toasts, widgets, efeitos)                        │
          │  apps (12)      puzzles/minigames      narrative/finais                                       │
          └───────▲───────────────────▲────────────────────────▲──────────────────────────────────────────┘
                  │ usam              │ usam                   │ escutam sinais
          ┌───────┴────────┐  ┌───────┴────────┐
          │   shared/ui    │  │ core/utilities │  UiKit · TemaNexus · UtilTexto · Conexoes · Cenas
          │ JanelaBase     │  └───────▲────────┘
          │ AppBase        │          │
          │ Diálogos, Orbe │          │
          └───────▲────────┘          │
                  │                   │
   ┌──────────────┴───────────────────┴───────────────────────────────────────────────────────┐
   │ core/autoload — "A ─► B" significa "A usa B" (B sempre vem antes de A na ordem)          │
   │                                                                                          │
   │ 9 Persistência ─► 8 Narrativa, 6 VFS, 3 Estado                                           │
   │ 8 Narrativa ────► 1 Relógio, 2 Configurações, 3 Estado, 4 Áudio, 5 Notificações, 6 VFS   │
   │ 7 Janelas ──────► 3 Estado, 4 Áudio, 5 Notificações                                      │
   │ 6 VFS ──────────► 3 Estado                                                               │
   │ 5 Notificações ─► 1 Relógio, 3 Estado                                                    │
   │ 4 Áudio ────────► 2 Configurações, 3 Estado                                              │
   │ 3 Estado ───────► 2 Configurações                                                        │
   └──────────────────────────────────────────────────────────────────────────────────────────┘
                  ▲
                  │ lê
          core/data/*.json  (catálogo, VFS inicial, dias, conversas, e-mails, agenda, páginas, processos, finais)
```

O gerenciador de janelas e a narrativa **não** dependem um do outro: a narrativa pede por sinal e a área de trabalho faz a ponte.

Regras que mantêm o acoplamento baixo:

1. **Estado é só dado.** Quem muda algo chama `GerenciadorEstado.set_flag(...)`, `ajustar_corrupcao(...)` etc.; quem se interessa escuta o sinal.
2. **A narrativa não conhece a interface.** Para abrir um app ela emite `abrir_app_solicitado`; a área de trabalho escuta e chama `GerenciadorJanelas.abrir_app`.
3. **O catálogo é a fonte da verdade dos apps.** Menu iniciar, barra de tarefas (fixados), atalhos da área de trabalho, busca e gerenciador de janelas leem `GerenciadorJanelas.apps_do_menu()`, `apps_da_area_de_trabalho()` e `apps_fixados()`.
4. **Um aplicativo = `AppBase`.** O gerenciador instancia a cena do catálogo (`PackedScene.instantiate()`), injeta `app_id`, `info` e `janela`, e chama `iniciar(args)`. Os sinais assinados com `conectar(...)` são desligados sozinhos ao sair da árvore.
5. **Um único relógio.** `RelogioGlobal` entrega os ticks; a narrativa (eventos e processo malicioso) e o autosave avançam por um `_process` cada, e os toasts contam o tempo no próprio `_process`. Os únicos nós `Timer` do projeto são o de 0,5 s do Monitor do Sistema (só enquanto a janela existe) e o de 0,1 s do player de áudio da Galeria. Há ainda um atraso único (`create_timer`) na ponte opcional com o backend em C, desligada por padrão.
6. **O VFS é compartilhado.** Explorador, Bloco de Notas, Leitor de Texto, Galeria, Terminal e busca do menu iniciar usam o mesmo `SistemaArquivosVirtual`. Mudanças chegam por `arquivo_alterado` e `arvore_alterada`.
7. **Nada toca o computador real.** Terminal, Monitor e Navegador são simulações. Não há `OS.execute`, `eval`, acesso à rede nem remoção de arquivos reais (verificado pelo validador).

## Dados e tema

- **Tema em código.** `TemaNexus` define as paletas dos 5 dias e monta o `Theme` com variações de tipo (`BotaoPrimario`, `PainelVidro`, `RotuloMono`...). É aplicado em `get_tree().root.theme`, então muda de uma vez em todas as janelas.
- **Paletas por dia** (fundo / acento / acento 2): Dia 1 roxo `#8b5cf6` e azul `#38bdf8` sobre `#0b0a1a`; Dia 2 azul `#38bdf8` e índigo `#6366f1` sobre `#080d1a`; Dia 3 carmim `#e11d48` e roxo `#a855f7` sobre `#12091a`; Dia 4 vermelho `#ef4444` e laranja `#f97316` sobre `#0a0506`; Dia 5 vermelho `#ef4444` e verde de terminal `#22c55e` sobre `#050505`. A cor de acento manual (roxo/azul/verde) e o modo "alto contraste" (fundo preto, acentos amarelo e ciano, bordas opacas) são aplicados por cima da paleta do dia; o tamanho do texto tem quatro níveis (0,9 / 1,0 / 1,2 / 1,4).
- **Dados.** `core/data/*.json` descrevem a história. O código nunca embute texto narrativo além de mensagens de interface.
