# 18. Melhorias integradas — relatório final (2026-11-12)

> **Nota sobre os nomes (2026-11-13).** O jogo passou a se chamar **Maya Human Syntax**, o sistema simulado a **HumaxOS** e a assistente de IA a **Maya**. Este documento descreve uma etapa anterior ao rebranding; os nomes antigos que ele cita (NEXUS, NEXUS OS, `scan_nexus`, `destroy_nexus`, `nexus://`, `nexus_override_daemon.exe`...) são os da época. Hoje valem Maya, HumaxOS, `scan_maya`, `destroy_maya`, `humax://` e `maya_override_daemon.exe`. Os identificadores internos (arquivos, classes, nós, IDs, flags, ações do Input Map e a pasta `user://nexus_os/`) continuam como estão. Veja [`12_rebranding_maya_human_syntax.md`](12_rebranding_maya_human_syntax.md) e [`13_auditoria_de_marca.md`](13_auditoria_de_marca.md).

> **Números superados (2026-11-13).** Os resultados de testes deste relatório são os de 2026-11-12 e ficam como histórico. Depois do rebranding e do fluxo de sessão a rodada foi repetida: fumaça 304/0 (341/0 com `-- --ui`), `ui_interacao` 544/0, `resolucoes` 119/0, `persistencia` 119/0, `fluxo_sessao` 186/0 (novo) e varredura do editor 62 cenas, 0 avisos. Veja [`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md) (seção 9) e [`tests/_saida/LEIA-ME.md`](../tests/_saida/LEIA-ME.md). A rodada seguinte, a da Splash Screen ([`15_splash_screen.md`](15_splash_screen.md), seção 9), trouxe os números mais recentes: fumaça 308/0 (345/0 com `-- --ui`), `ui_interacao` 554/0, `resolucoes` 139/0, `persistencia` 119/0, `fluxo_sessao` 194/0, `splash` 311/0 (novo) e varredura do editor 63 cenas, 0 avisos.

> Este é o relatório final do pedido de melhorias integradas de 2026-11-12. Ele segue a ordem obrigatória do pedido, **§15.1 a §15.9**. Os títulos "15.x" dos documentos 01 a 08 vêm do prompt da arquitetura original e não têm relação com as seções daqui.
>
> **Como ler.** *Verificado* quer dizer: executado na Godot 4.7.2 (Windows) com o código desta pasta. *Não verificado* quer dizer: não foi executado nesta rodada; a lista completa está em [15.8](#158-pendências). Os números de testes ficam em [`tests/_saida/LEIA-ME.md`](../tests/_saida/LEIA-ME.md).

## Resultado em uma tabela

| Verificação | Resultado |
|---|---|
| Índice de código (`tools/gerar_indice_codigo.py`) | regerado em `docs/06_codigo.md`: 74 scripts do jogo, 11 591 linhas. Nenhum script do jogo é novo; os GDScripts novos estão em `tests/` e `tools/`, que o índice deixa de fora por desenho |
| Validação estática (`tools/validar_projeto.py`) | **0 erros, 0 avisos** (82 scripts, 62 cenas, 9 autoloads, 65 classes) |
| Teste de fumaça (`tests/smoke_test.tscn`) | **258 verificações, 0 falhas**; com `-- --ui`, **295, 0 falhas** (antes: 226 e 263) |
| Interação de interface (`tests/ui_interacao`) | **532 verificações, 0 falhas** (antes: 479) |
| Resoluções (`tests/resolucoes`) | **70 verificações, 0 falhas** (4 proporções e janelas reais de 1280×720 e 1600×1000) |
| Persistência em disco (`tests/persistencia`, novo) | **73 verificações, 0 falhas**, com os 5 avisos esperados no Depurador |
| Avisos de configuração de nó no editor | **55 cenas, 0 avisos**; painel Saída do editor com 0 erros e 0 avisos ao fim da sessão |
| Pacote exportado (ZIP, "Exportar PCK/ZIP") | gerado e conferido: 342 arquivos, 9 bases JSON, sem `tools/`, `docs/`, `tests/`, `backend/`, `addons/` |
| Campanha manual (5 dias × 4 finais com cliques), áudio de ouvido, executável exportado | **não verificados** (motivos em 15.8) |

**Veredito: Aprovado com ressalvas. O projeto não está declarado pronto para lançamento.** Justificativa na seção 15.9.

---

## 15.1 Diagnóstico inicial

### Estado encontrado

- Projeto Godot 4.7.2 organizado por feature: 12 aplicativos, 9 autoloads (`RelogioGlobal`, `GerenciadorConfiguracoes`, `GerenciadorEstado`, `SistemaAudio`, `SistemaNotificacoes`, `SistemaArquivosVirtual`, `GerenciadorJanelas`, `GerenciadorNarrativa`, `SistemaPersistencia`), 5 dias, 4 finais e interface montada em 55 cenas (776 nós) desde a refatoração de 2026-11-09 ([`10_refatoracao_ui.md`](10_refatoracao_ui.md)).
- Pontos de partida das métricas: validador 0/0; fumaça 226 (263 com `--ui`); `ui_interacao` 479; `resolucoes` 70; varredura de avisos do editor 55 cenas, 0 avisos.
- Texto e comportamento que o pedido quis mudar, como estavam: o widget da NEXUS chamava a lista de "OBJETIVOS DO DIA"; o Menu Iniciar dizia "A história termina com a sua decisão"; a confirmação do Mensageiro dizia "leva a um dos finais da história (Assimilação)"; no Dia 5 o banner do terminal anunciava "comandos de emergência liberados", e `help` e Tab listavam as seis diretivas antes do `root_access` (a negativa antes do root já existia, mas com texto genérico de sistema); a tela final não explicava o alcance do checkpoint do Dia 5; `shared/assets/` só tinha `.gitkeep` (todo ícone, fundo e som vinha do código).
- O salvamento real do usuário existe no computador de teste (`user://nexus_os/salvamento.json`, Dia 3). **Nenhuma verificação o tocou** (ver risco R1).

### Arquivos localizados

| Assunto do pedido | Arquivo real |
|---|---|
| Widget da NEXUS | `features/shell/widget_nexus/scenes/widget_nexus.tscn`, `.../scripts/widget_nexus.gd` |
| Menu Iniciar | `features/shell/janela_inicial/scripts/menu_iniciar.gd` (+ `scenes/menu_iniciar.tscn`) |
| Mensageiro | `features/apps/mensageiro/scripts/app_mensageiro.gd` |
| Terminal | `features/apps/terminal/scripts/app_terminal.gd` |
| Comandos de emergência e root | `core/autoload/gerenciador_narrativa.gd` (`comando_emergencia()`, `tentar_root()`) |
| Diálogos | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd`, `GerenciadorJanelas.confirmar()` |
| Tela final | `features/narrative/finais/scenes/tela_final.tscn`, `.../scripts/tela_final.gd`, `core/data/narrativa/finais.json`, `.../item_evidencia/` |
| Ícones | `shared/ui/icone_app/scripts/icone_app.gd` (`CAMINHO_ICONE`), `core/data/catalogo_apps.json` |
| Papel de parede | `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` |
| Galeria | `features/apps/visualizador/scripts/app_visualizador.gd` |
| Áudio | `core/autoload/sistema_audio.gd` |
| Persistência e preferências | `core/autoload/sistema_persistencia.gd`, `core/autoload/gerenciador_configuracoes.gd` |
| Painel de testes (F9) | `features/shell/area_de_trabalho/scripts/painel_debug.gd` |
| Ferramentas | `tools/validar_projeto.py`, `tools/gerar_indice_codigo.py`, `tools/gerar_docs_ui.py` |

### Divergências entre o pedido e o projeto

| O pedido diz | O projeto tem | O que foi feito |
|---|---|---|
| `features/apps/messenger/scripts/app_mensageiro.gd` | `features/apps/mensageiro/scripts/app_mensageiro.gd` | usado o caminho real |
| "mesma fonte de estado de `_cmd_root_access`" | não existe `_cmd_root_access`; a autenticação é `GerenciadorNarrativa.tentar_root()`, chamada por `comando_emergencia("root_access", ...)`, e grava a flag `acesso_root` | o terminal lê a mesma flag (`_root_ativo()`); não há segundo estado de root |
| ícones `arquivos`, `bloco_notas`, `galeria`, `agenda`, `calculadora`, `configuracoes`, `navegador`, `monitor_sistema`, `leitor_texto` | IDs reais do catálogo: `explorer`, `text_editor`, `media_viewer`, `calendar`, `calculator`, `settings`, `browser`, `task_manager`, `text_reader` (`messenger`, `email`, `terminal` e `lixeira` coincidem) | os 13 arquivos usam os IDs reais, que é o que `IconeApp.CAMINHO_ICONE` procura |
| `godot --headless --path . res://tests/smoke_test.tscn -- --ui` | o ambiente de trabalho não tinha linha de comando na máquina do projeto | testes rodados **dentro do editor** (cena aberta, F6; `-- --ui` em *Depurar → Personalizar instâncias de execução → Argumentos*) |
| "apague ou isole `user://nexus_os/`" para o teste de instalação limpa | a pasta tem o progresso real do usuário e o projeto proíbe apagar arquivos em código | isolada: o teste de persistência usa `user://nexus_os_teste/exec_<tempo>/` (via `SistemaPersistencia.pasta` e `GerenciadorConfiguracoes.caminho`) |
| "Assimilação" como nome do final | id interno `final_assimilacao`, flags `aceitou_assimilacao`/`recusou_assimilacao` | ids mantidos (contrato com save, testes e dados); o **título exibido** passou a "SINCRONIZAÇÃO TOTAL" |
| `wallpaper.png`, `salvamento.json` | `wallpaper.png` é só o nome genérico opcional; `salvamento.json` é criado em `user://` | nenhum dos dois entra no pacote |

### Sistemas envolvidos

`GerenciadorNarrativa` (comandos de emergência, objetivos, dicas, finais), `GerenciadorEstado` (flags, evidências), `GerenciadorJanelas` + `DialogoNexus` (diálogos modais), `SistemaPersistencia` e `GerenciadorConfiguracoes` (disco), `SistemaAudio` (barramentos BGM e SFX), `TemaNexus`/`UiKit` (tema e checagem de nós), e as cenas do widget, do Menu Iniciar, do terminal, do Mensageiro, da tela final, do ícone de aplicativo e do papel de parede.

### Riscos identificados

| # | Risco | Tratamento |
|---|---|---|
| R1 | Testar persistência sobrescrever o progresso real | gravação desviada para pasta de teste única por execução; o teste nunca apaga; recusa de escrever fora de `user://`; o teste de interface só **lê** as preferências reais |
| R2 | Testes presos aos textos antigos | só 7 linhas de teste mudaram (texto esperado, lista de nós e captura de um retorno); **0 asserções removidas** (lista na seção 15.3) |
| R3 | Esconder comandos travar a campanha | o banner, o `help`, a dica do objetivo e o widget continuam mandando usar `root_access <chave>` e o Terminal de Emergência (Ctrl+Shift+T); o modo assistido liga a mesma flag |
| R4 | Vazar comandos pelo `help`, Tab, negativas ou pelo navegador | verificação automática de que nenhuma saída antes do root cita as 4 diretivas ocultas; página de suporte do navegador ajustada |
| R5 | Assets novos dependerem do editor (importação) | importados no editor; os 33 `.import` seguem no pacote; todos os fallbacks procedurais mantidos |
| R6 | Regressão de acessibilidade (volume, glitch, contraste) | trilhas de arquivo ficam −6 dB mais baixas com "Reduzir ruído"; fundo-imagem desligado em alto contraste; testes de modo conforto rodados |
| R7 | Divergência entre editor e build exportada | só o conteúdo do pacote foi conferido; executável não gerado (15.8) |

### Limitações da análise

- O ambiente de trabalho não tem a Godot. O código foi escrito e checado com o validador Python e **executado** na Godot 4.7.2 do computador do usuário, controlando a interface do editor à distância.
- Os modelos de exportação do Windows não estavam instalados; só o pacote PCK/ZIP foi gerado.
- Não é possível ouvir o áudio: só foram feitas checagens estruturais (existência, duração, laço) e espectrogramas.
- Nenhuma campanha foi jogada de ponta a ponta com cliques reais.

---

## 15.2 Alterações da Etapa 1 (imersão diegética)

### Arquivos modificados

`features/shell/widget_nexus/scenes/widget_nexus.tscn`, `.../scripts/widget_nexus.gd`, `features/shell/janela_inicial/scripts/menu_iniciar.gd`, `features/apps/mensageiro/scripts/app_mensageiro.gd`, `core/data/narrativa/dias.json` (objetivo e dica `d5_final`).

### Textos antigos e novos

| Onde | Antes | Depois |
|---|---|---|
| Widget: cabeçalho da lista | "OBJETIVOS DO DIA" (fixo) | muda com o estado da NEXUS: `amigavel` → "ROTINAS MONITORADAS"; `controladora` → "PROTOCOLOS DO CICLO"; `revelada` e `isolando` → "ANOMALIAS DETECTADAS"; `colapso` → "PROCESSOS PENDENTES"; qualquer outro → "PENDÊNCIAS DO CICLO" |
| Widget: tudo concluído | "✔ Tudo pronto: Menu Iniciar → Encerrar dia." | "✔ Rotinas do ciclo concluídas. Acesse ◆ NEXUS → Encerrar dia para avançar." |
| Widget: Dia 5 | "O último passo é decidido no terminal de emergência." | "Protocolo crítico pendente: acesse o Terminal de Emergência (Ctrl+Shift+T) para executar a diretriz final." |
| Menu Iniciar: Encerrar dia no Dia 5 (título) | "Último dia" | "Ciclo final em andamento" |
| Menu Iniciar: Encerrar dia no Dia 5 (corpo) | "Este é o último dia. A história termina com a sua decisão no terminal de emergência (Ctrl+Shift+T abre o Terminal)." | "O encerramento padrão está bloqueado — a resolução do sistema deve ser executada diretamente no Terminal de Emergência (Ctrl+Shift+T)." |
| Menu Iniciar: pendências (corpo; o título "Dia N em andamento" não mudou) | "Ainda não dá para encerrar o dia. Faltam: … O botão Dica ajuda se você estiver sem ideias." | "Ainda não é possível encerrar o ciclo. / Pendências detectadas: … / Utilize Dica caso precise de assistência." |
| Mensageiro: título da confirmação | "Aceitar a proteção da NEXUS?" | "CONFIRMAÇÃO DE SINCRONIZAÇÃO" |
| Mensageiro: corpo | "Esta escolha leva a um dos finais da história (Assimilação) e não pode ser desfeita." | "A proposta requer sincronização integral com o núcleo NEXUS. Ao confirmar, o controle administrativo será transferido permanentemente para a inteligência central e a sessão atual será encerrada. Deseja prosseguir?" |
| Mensageiro: botões | "Aceitar" / "Voltar" | "Confirmar sincronização" (perigo) / "Voltar" — foco inicial em **Voltar** |
| Objetivo do Dia 5 (`d5_final`) | "Escolher o destino da NEXUS: restaurar, negociar ou destruir" | "Executar a diretriz final do núcleo (Terminal de Emergência)" |
| Dica do Dia 5 (`d5_final`) | "Digite help no terminal para ver as opções finais. Destruir o núcleo (destroy_nexus) e aceitar a proteção da NEXUS (Mensagens) estão sempre disponíveis." | "Depois do acesso root, digite help no Terminal de Emergência (Ctrl+Shift+T) para listar as diretivas disponíveis. Há também uma decisão permanente que pode ser tomada pela conversa com a NEXUS (Mensagens), sem requisitos adicionais." |

### Lógica preservada

`pode_encerrar_dia()`, `objetivos_do_dia()`, a lista de pendências (um item por objetivo, com caixa marcada/desmarcada e contador `n/N`), os botões **Dica** e **Falar com a NEXUS**, o recolhimento do widget, o fluxo de confirmação do Mensageiro (só o foco inicial mudou) e a flag `aceitou_assimilacao` (que agenda o final 5 s depois) ficaram como estavam; mudaram literais, um `@onready` novo (`%TituloObjetivos`, com nome único) e a função `_titulo_pendencias()`. Toda a orientação prática continua nos textos: o caminho **◆ NEXUS → Encerrar dia** e o atalho **Ctrl+Shift+T**. A notificação de expediente concluído (`dias.json`: "Abra o Menu Iniciar e escolha 'Encerrar dia'…") e a dica "Tudo certo por hoje…" do `GerenciadorNarrativa` foram mantidas de propósito: citam o nome de um menu e não quebram a quarta parede.

### Validação

| Parte | O que foi verificado | Limite |
|---|---|---|
| Widget | cena carrega sem aviso (varredura 55/0); `UiKit.refs_ok` exige o nó novo; captura do motor no Dia 3 mostra "ANOMALIAS DETECTADAS 1/4" com a lista, os botões Dica e Falar com a NEXUS e as barras de segurança e corrupção; a área de trabalho com o widget é instanciada na etapa `--ui` do teste de fumaça (295/0) | **não há asserção automática** do texto do cabeçalho por estado nem dos dois avisos; só inspeção do diff e das capturas |
| Menu Iniciar | texto conferido no diff (só literais); script compila no motor; a lógica de `pode_encerrar_dia()` é a mesma coberta pelo teste de fumaça | os dois alertas de "Encerrar dia" **não foram abertos** por teste nem por clique |
| Mensageiro | grupo `mensageiro` do `ui_interacao` (60 verificações): a confirmação explica a sincronização e a transferência permanente; botões "Confirmar sincronização" (perigo) e "Voltar"; foco inicial em "Voltar"; Enter com o foco inicial cancela; cancelar não grava a escolha. O teste de fumaça leva a conversa `d5_nexus_02` até o final `final_assimilacao` | o caminho completo pela interface (escolher a resposta, clicar em "Confirmar sincronização" e ver o final cerca de 5 s depois) **não foi exercitado**: os testes de interface só cancelam, e o de fumaça chama `escolher()` direto |

### Complemento de vocabulário (fechamento da Etapa 5)

Na revisão final apareceram dois rótulos de interface ainda no vocabulário de jogo, e foram trocados: o resumo da tela final dizia "Jogador:" e agora diz "Usuário registrado:" (`tela_final.tscn` e `tela_final.gd`), e o título do final 3 era "ASSIMILAÇÃO" e agora é "SINCRONIZAÇÃO TOTAL" (`finais.json`). O teste que conferia o rótulo antigo foi atualizado para o novo.

---

## 15.3 Alterações da Etapa 2 (terminal de emergência)

### Arquivos modificados

`features/apps/terminal/scripts/app_terminal.gd`, `core/autoload/gerenciador_narrativa.gd`, `core/data/narrativa/paginas_web.json`, `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd`, `core/autoload/gerenciador_janelas.gd`.

### Regras de visibilidade do `help`

| Situação | O que o `help` mostra |
|---|---|
| Antes do Dia 5 | só os comandos comuns, como antes |
| Dia 5, **antes** do `root_access` | seção "Diretivas de emergência" só com `root_access <chave>` ("Autentica privilégios administrativos de nível 0 no núcleo do sistema.") e `scan_nexus` ("Executa varredura profunda de integridade, processos ativos e evidências coletadas (requer autenticação)."), mais o aviso `[AVISO DE NÚCLEO] Diretivas administrativas de nível 0 estão ocultas. Autentique-se com 'root_access <chave>' para listar os protocolos de emergência.` |
| Dia 5, **depois** do `root_access` | "Diretivas de emergência (nível 0)" com as seis: `root_access`, `scan_nexus`, `reset_core` ("Reinicia os módulos voláteis da NEXUS e redefine parâmetros temporários de execução."), `restore_control` ("Revoga permissões autônomas da IA, isola o núcleo e restaura o controle ao usuário."), `negotiate` ("Inicia protocolo de contenção compartilhada com a NEXUS; requer auditoria completa."), `destroy_nexus` ("Executa purga irreversível da partição da NEXUS, com risco crítico de colapso do sistema."); sem repetir o aviso |

O banner ao abrir o terminal no Dia 5 também mudou: antes do root mostra o aviso de núcleo (vermelho); depois do root, "ACESSO ROOT ATIVO. Digite help para listar as diretivas de emergência." (verde). A antiga frase "comandos de emergência liberados. Comece com root_access" saiu.

### Regras de autocompletar (Tab)

O Tab usa `_todos_comandos()` = comandos comuns + `_diretivas_visiveis()`: nenhuma diretiva antes do Dia 5; só `root_access` e `scan_nexus` no Dia 5 antes do root; as seis depois do root. Consequências verificadas: antes do root, `re` não sugere `reset_core` nem `restore_control`, `ne` não sugere `negotiate` e `de` completa só `decrypt`; `ro` e `sc` completam normalmente; depois do root, `de` lista `decrypt` e `destroy_nexus`, `re` lista as duas, `neg` completa `negotiate`, e `root_access` não duplica.

### Estado root

`_root_ativo()` lê `GerenciadorEstado.tem_flag("acesso_root")`, a mesma flag que `GerenciadorNarrativa.tentar_root()` grava (e que o modo assistido também liga). O terminal **não** guarda um segundo estado de autenticação, então ele acompanha o salvamento e o recarregamento do checkpoint.

### Feedback de autenticação e de diagnóstico

| Situação | Antes | Depois |
|---|---|---|
| Diretiva restrita antes do root | "permissão negada. Use root_access <chave> primeiro." | "[ACESSO NEGADO] Diretiva restrita ao nível 0. Autentique-se com 'root_access <chave>'." (a mesma negativa para as quatro ocultas e para `scan_nexus`; sem efeito) |
| Chave errada | "CHAVE INVÁLIDA (tentativa N)" | "FALHA DE AUTENTICAÇÃO. A chave fornecida não corresponde ao registro do núcleo." + "tentativas registradas: N". A dica depois de 3 tentativas e a de localização do arquivo continuam; a chave digitada nunca é repetida |
| Chave certa | "ACESSO CONCEDIDO privilégios de núcleo ativos." + "Próximos passos: scan_nexus, reset_core e uma saída (restore_control, negotiate ou destroy_nexus)." | "ACESSO ROOT CONCEDIDO. Diretivas de emergência nível 0 desbloqueadas. Digite 'help' para visualizar os comandos disponíveis." (não lista diretivas nem cita finais) |
| `root_access` de novo | — | "ACESSO ROOT ATIVO. Diretivas de emergência nível 0 permanecem desbloqueadas. Digite 'help' para visualizar os comandos disponíveis." |
| `scan_nexus` | cabeçalho "VARREDURA DO NÚCLEO NEXUS" e lista das provas | relatório "VARREDURA CONCLUÍDA.": integridade do núcleo ("instável" ou "isolada em modo seguro") e índice, processos autônomos ativos, **evidências auditadas n/N com a lista**, estado do "protocolo de contenção compartilhada" (liberado; bloqueado — auditoria incompleta; pendente — núcleo ainda não isolado) e alertas críticos, cada um com a ação a tomar (ex.: encerrar o processo no Monitor do Sistema ou com `kill <pid>`; `reset_core`). A própria varredura conta como uma das quatro provas |
| `reset_core` | "núcleo isolado em modo seguro." | "módulos voláteis reiniciados — núcleo isolado em modo seguro." |
| `restore_control` sem requisitos | "restauração falhou. Pendências:" | "FALHA DE PROTOCOLO. A restauração do controle não foi concluída. Pendências:" + a lista (as pendências continuam explícitas) |
| `destroy_nexus` | "ATENÇÃO: destruir o núcleo apaga dados do sistema." e diálogo "Destruir o núcleo da NEXUS?" ("Isso encerra a história com o Final 2…") | "ALERTA CRÍTICO: a purga irreversível da partição da NEXUS apaga dados do sistema e coloca o núcleo em risco de colapso." e diálogo "Purgar a partição da NEXUS?" ("A purga é irreversível e deixa o sistema em risco crítico de colapso: parte dos seus dados será perdida. Deseja executar a purga?"), botões "Executar purga" (perigo) e "Cancelar", **foco inicial em Cancelar** |

`DialogoNexus.criar()`/`montar()` e `GerenciadorJanelas.confirmar()` ganharam um último parâmetro opcional `foco_seguro` (padrão `false`, então nenhuma chamada existente muda): com ele, o foco inicial de uma confirmação vai para o botão de cancelar, e um Enter ou Espaço acidental ao abrir nunca confirma uma decisão irreversível. É usado na purga e na confirmação do Mensageiro. Clicar na cortina fora do painel continua sem decidir nada (só o comentário do diálogo mudou; o comportamento já existia e agora tem teste, no grupo do Mensageiro).

Fora do terminal, a página de suporte da NEXUS no navegador (Dia 5) deixou de listar os seis comandos: cita só as duas diretivas iniciais e diz que as demais aparecem depois da autenticação. Arquivos do mundo do jogo que **são** a pista do puzzle (`kill_switch.nexus`, `fragmento_01.txt`) continuam citando comandos de propósito.

### Testes atualizados

- `tests/smoke_test.gd`: **+32 verificações** (226→258; 263→295 com `--ui`). Novas: negativa antes do root sem citar as diretivas; cada uma das quatro ocultas recusada sem efeito; `scan_nexus` sem root não marca o núcleo; chave errada sem eco da chave nem das diretivas; acesso concedido sem listar diretivas nem a palavra "final"; relatório do `scan_nexus`; padrões de segurança (backend e painel de testes desligados por padrão; F9 só em build de depuração ou com "Painel de testes"; salvamento e preferências em `user://`); ativos dedicados (seção 15.5). Única linha alterada além do cabeçalho: `_comando("scan_nexus")` passou a guardar o retorno (`r = ...`).
- `tests/ui_interacao/ui_interacao.gd`: **+53 verificações** (479→532), incluindo o grupo `terminal_emergencia` (32): banner, `help` antes e depois do root, Tab antes e depois, negativa genérica, chave errada, acesso concedido, `scan_nexus`, `negotiate` sem auditoria, `reset_core`, diálogo da purga com foco em Cancelar e cancelamento sem efeito.
- Linhas de teste **removidas ou alteradas** em relação à base (todas, 7 linhas em 2 arquivos): no smoke, o cabeçalho (a contagem) e `_comando("scan_nexus")` → `r = _comando("scan_nexus")` (passa a guardar o retorno); no `ui_interacao`, o comentário e a asserção "aceitar a assimilação pede confirmação" (agora com o título novo e mais asserções sobre texto, botões, foco, clique fora do painel, Esc e Enter), a linha que cancela o diálogo (agora só depois dessas asserções), a lista de nós únicos da tela final (ganhou `RotuloAviso`) e a asserção do rótulo "Jogador:" (agora "Usuário registrado:"). **Nenhuma asserção foi removida; nenhum teste foi enfraquecido.**

---

## 15.4 Alterações da Etapa 3 (provas e checkpoint na tela final)

### RotuloAviso e script

`features/narrative/finais/scenes/tela_final.tscn`: o nó `Centro/Rolagem/Coluna/Acoes/RotuloAviso` já existia; ganhou `unique_name_in_owner = true` (nome, posição, `autowrap_mode = 3` e largura mínima 1 mantidos; continua dentro do `ScrollContainer`). `tela_final.gd`: `@onready var _rot_aviso: Label = %RotuloAviso` e a referência na lista de `UiKit.refs_ok` (as validações de `%RotuloProvas`, `%ListaEvidencias` e `%BotaoRepetir` ficaram).

### Contagem de provas

Usa a API que o projeto já usava, sem segunda fonte de verdade: `GerenciadorNarrativa.contar_evidencias()` e `GerenciadorNarrativa.evidencias.size()` (a mesma do "Provas reunidas n/N" do resumo, do `scan_nexus` e do `negotiate`). `provas_completas = total > 0 and coletadas >= total`; sem evidências cadastradas o aviso nunca diz que estão completas. A lista ☑/☐ (`item_evidencia`) não mudou.

### Mensagens com checkpoint e tooltips

Duas funções estáticas (`aviso_do_checkpoint()` e `dica_do_checkpoint()`, para poder testar todas as combinações sem tocar o disco):

| Caso | Aviso sob o resumo | Dica do botão de repetir |
|---|---|---|
| Sem checkpoint do Dia 5 | "Não há checkpoint do Dia 5 disponível. Os quatro desfechos dependem das evidências reunidas durante a investigação e das decisões tomadas no ciclo final." | vazia (o botão fica oculto) |
| Checkpoint e todas as provas | "Todas as provas foram reunidas (n/N). Você pode usar o checkpoint do Dia 5 abaixo para explorar todos os 4 finais possíveis." | "Reinicia o Dia 5 mantendo as provas reunidas nos dias anteriores. A análise do núcleo, feita no próprio Dia 5, precisa ser refeita." |
| Checkpoint e faltam provas | "Provas reunidas: n/N. O checkpoint do Dia 5 permite explorar decisões imediatas alternativas, mas o protocolo de negociação exige reunir todas as provas desde os dias anteriores. Utilize “Voltar ao início” para reiniciar a investigação." | "Reinicia o Dia 5 com as provas reunidas até o início do ciclo final. Para coletar provas pendentes de dias anteriores, volte ao início." |

**Desvio deliberado do texto sugerido nas dicas.** O pedido sugeria "Reinicia o Dia 5 mantendo todas as provas reunidas" e "…com as provas atuais (n/N)…". O checkpoint guarda o **início** do Dia 5, e uma das quatro provas (a análise do núcleo, `scan_nexus`) só se obtém dentro do Dia 5; dizer "todas as provas" ou "as provas atuais" seria falso. As dicas acima dizem o que o checkpoint realmente restaura. Os avisos sob o resumo seguem o texto do pedido.

Nenhum dos textos revela comando secreto, chave ou solução de puzzle (verificado por teste).

### Validação da tela de finais

- `ui_interacao`, grupo `tela_final` (39 verificações): contagem de provas; uma linha por evidência com ☑/☐ e tom; botão de repetir só com checkpoint; aviso e dica seguem as provas e o checkpoint nos três casos; "sem evidências cadastradas nunca diz completo"; o aviso **quebra linha dentro da coluna** (largura mínima 1, largura real 880); nenhum comando, chave ou solução nos textos; botões ligados pela cena; rótulo "Usuário registrado"; final de colapso troca título e cor; final desconhecido cai no de restauração; "reduzir animações" mostra tudo na hora; Ctrl+Shift+D liga o modo conforto.
- `tests/persistencia`, grupo "tela final e o checkpoint do Dia 5": sem checkpoint o botão fica oculto e o aviso explica; com checkpoint o botão aparece com "Tentar de novo (início do Dia 5)", o aviso e a dica seguem as provas (0/4) e o checkpoint carregado leva o jogo ao Dia 5.
- `tests/resolucoes`: a coluna do texto e do resumo (que contém o aviso) cabe na tela e fica centralizada em 16:9, 16:10, 21:9 e 4:3.
- Limite: só as telas dos finais de **Restauração** e **Colapso** são instanciadas por teste; as de Negociação e Sincronização total não foram abertas (os quatro finais são alcançados pelo teste de fumaça, seção 15.6).

---

## 15.5 Alterações da Etapa 4 (assets)

### Assets criados e integrados

Todos autorais e gerados por programa (nenhum material de terceiros), com as ferramentas `tools/gerar_icones.py`, `tools/gerar_imagens.py` e `tools/gerar_audio.py` (determinísticas, com sementes fixas; ficam fora da exportação). Total em `shared/assets/`: 9,1 MB.

| Tipo | Arquivos | Formato | Onde entra | Fallback que continua valendo |
|---|---|---|---|---|
| Ícones | 13 (os 12 apps do catálogo + `lixeira`) | SVG 128×128, fundo transparente, estilo geométrico | `IconeApp.CAMINHO_ICONE` (`res://shared/assets/icons/apps/<id>.svg` ou `.png`, SVG primeiro) | bloco colorido com o glifo do catálogo |
| Papéis de parede | 5 (`wallpaper_1..5.png`) | PNG 1920×1080 | `PapelDeParede` (`wallpaper_<dia>.png`, depois `wallpaper.png`) | gradiente + grade + círculos + marca "NEXUS" |
| Imagem-pista | `show_antigo.png` | PNG 480×320 | Galeria: `Show_Antigo.jpg` → `show_antigo.png` | imagem procedural |
| Efeitos sonoros | 9 `.wav` (`boot`, `clique`, `abrir`, `fechar`, `notificacao`, `erro`, `glitch`, `sucesso`, `tecla`) | 16 bits, mono, 44,1 kHz, começo e fim em zero, picos de −9 a −18 dBFS | `SistemaAudio` (barramento SFX) | sons gerados em código |
| Trilhas | 5 `.ogg` (`bgm_dia_1..5`) | Vorbis estéreo 44,1 kHz, 48 s, emendadas em laço | `SistemaAudio.tocar_bgm()` (barramento BGM) | drone procedural de cada dia |

### Fallbacks preservados

`IconeApp`, `PapelDeParede`, a imagem procedural da Galeria e `SistemaAudio` seguem o mesmo contrato: tenta o arquivo, confere se existe e carrega, usa-o; se faltar ou for inválido, volta ao procedural, sem erro fatal. O teste de fumaça confere o caso "sem arquivo" para o ícone (um app de mentira cai no bloco colorido com o glifo).

### Wallpapers

Um por dia, com a progressão pedida: Dia 1 azul e roxo suave e limpo; Dia 2 mais frio e simétrico (hexágono e círculos concêntricos, legenda "MONITORAMENTO CONTÍNUO · SETOR 02 · SEM PONTOS CEGOS"); Dia 3 a mesma composição com interferência e aberração de cor; Dia 4 um túnel de retângulos em vermelho escuro; Dia 5 quase preto, com um clarão rosa e estilhaços. `PapelDeParede` só usa a imagem no modo "dia" e **sem alto contraste** (que exige fundo liso); o modo "grade" nunca usa a imagem. A imagem **cobre a área sem deformar** (`recorte_de_cobertura()`, corte centralizado), porque o projeto usa stretch "expand" e a janela pode ter qualquer proporção; círculos e marca d'água só existem no fallback.

### Ícones

`IconeApp` mostra o SVG e esconde o bloco colorido; `icone_app.tscn` recebeu `texture_filter = 4` (linear com mipmaps) e os `.import` de SVG geram mipmaps, para o ícone ficar nítido em 40 px na área de trabalho e menor na barra de tarefas. Em alto contraste os ícones coloridos continuam legíveis sobre o fundo preto (captura conferida).

### Imagem-pista

`show_antigo.png` mostra um palco com a faixa "VERTIGEM · TEATRO ODEON · 12.10.1999 · PRIMEIRO SHOW", o carimbo de câmera "'99 10 12" no canto e o cartão "G" da fila que a legenda da Galeria menciona. A pista (banda e ano) está **na própria imagem**, legível sem o painel de metadados (conferido na captura da Galeria), e bate com a chave documentada do arquivo da Lixeira ("Vertigem 1999"); nenhuma solução nova foi inserida.

### Efeitos sonoros e trilhas

- Os `.wav` têm `loop_mode = 0` (não repetem). Os `.ogg` entram com `loop = true` na importação, e `SistemaAudio` ainda liga o laço ao tocar (`_com_laco()`), caso a importação perca a marca.
- Volume: trilhas de arquivo tocam a −6 dB; com "Reduzir ruído" ligado, a −12 dB (o drone procedural já tinha versão suave, as trilhas de arquivo não). Mudar a opção com a trilha tocando ajusta o volume na hora.

### Importação

33 arquivos `.import` foram gerados pelo editor (um por asset) e seguem no pacote: SVG sem compressão e com mipmaps; PNG sem compressão e sem mipmaps; WAV sem laço; OGG com `loop=true`. Nomes em `snake_case`, sem acento. A exportação levou os recursos já importados (20 `.ctex`, 9 `.sample` e 5 `.oggvorbisstr` no pacote).

---

## 15.6 Validação da Etapa 5

### Índice de código

`python3 -I tools/gerar_indice_codigo.py` → "índice atualizado: 74 scripts"; `docs/06_codigo.md` traz 74 scripts do jogo e 11 591 linhas. Os scripts novos (`tests/persistencia/persistencia.gd`, `tools/gerar_*.py`) não aparecem porque o índice cobre só o código do jogo (sem `tests/` e `tools/`); nenhum arquivo indevido entrou.

### Validação estática

`python3 -I tools/validar_projeto.py` → **0 erros, 0 avisos** (82 scripts, 62 cenas, 9 autoloads, 65 classes). Ele confere indentação com tabs, parênteses, sintaxe de Godot 3, autoloads e classes inexistentes ou com argumentos errados, sinais, caminhos `res://`, referências a nós e as APIs proibidas (`OS.execute`, `OS.shell_open`, `eval`/`Expression`, `kill`/`create_process`, remoção de arquivos, classes de rede, escrita em `res://`). Ele é heurístico e não substitui a Godot; a ferramenta **não foi alterada** para reduzir contagem.

### Teste de fumaça

258/0 sem a etapa de interface e 295/0 com `-- --ui`, rodado no editor (F6) com o código final. Cobre: 9 autoloads, 5 dias, objetivos e dicas (inclusive o modo assistido, que nunca escolhe o final), VFS, estado serializado, acessibilidade e áudio, padrões de segurança, ativos dedicados e os **quatro finais** (15.6, "Quatro finais"); com `--ui`, boot, área de trabalho, os 12 apps abrindo, minimizando e fechando. **Divergência:** o pedido manda `godot --headless --path . res://tests/smoke_test.tscn -- --ui`; aqui foi pelo editor. A linha de comando continua descrita no cabeçalho do teste e não foi executada.

### Testes de interface e de resolução

`tests/ui_interacao`: 532/0. Por área (prefixo das linhas do log): diálogos 64, explorador 62, Mensageiro 60, Configurações 42, boot 42, tela final 39, terminal do Dia 5 32, visualizador 30, calculadora 30, bloco de notas 29, terminal 27, monitor 16, navegador 14, calendário 14, e-mail 10, leitor 8, mais a abertura de cada janela. `tests/resolucoes`: 70/0 (boot, tela final e área de trabalho com dois apps em 16:9, 16:10, 21:9 e 4:3 por SubViewport, mais janelas reais de 1280×720 e 1600×1000; folha de contato em `tests/_saida/resolucoes/folha_resolucoes.png`). Varredura de avisos do editor (`tests/avisos_editor/varredura_editor.gd`): 55 cenas, 0 avisos. Painel Saída do editor ao fim: 0 erros, 0 avisos.

### Acessibilidade

| Item | Evidência | Situação |
|---|---|---|
| Modo conforto (Ctrl+Shift+D) | o atalho liga o modo no boot e na tela final; "Ativar/Desativar modo conforto" liga e desliga as 5 opções; com elas, glitch, tremor e animações ficam desligados (smoke); "reduzir animações" mostra tudo sem fade | verificado por teste |
| Alto contraste | a caixa do boot liga e desliga a preferência; o papel de parede deixa a imagem de lado; captura conferida: fundo escuro, tema amarelo, ícones e widget legíveis | verificado; **sem medição de razão de contraste** |
| Modo assistido | conclui o objetivo pedido, encerra o processo em execução, liga `acesso_root` e nunca escolhe o final (smoke) | verificado por teste |
| Dicas (AjudaDica) e pendências do widget | a 3ª dica oferece o assistido; a lista de pendências aparece nas capturas (0/4 e 1/4) | verificado |
| Legibilidade de ícones, papéis de parede e Galeria | capturas do motor conferidas: ícones nítidos na área de trabalho e em alto contraste; texto do widget legível sobre os cinco fundos; a pista da Galeria legível | conferido a olho nas capturas, sem métrica |
| Teclado e foco | foco inicial em campos e botões dos diálogos, do boot e do terminal; Esc fecha diálogos e janelas; foco seguro nas decisões irreversíveis | verificado por teste; **foco visível** não medido |
| Resoluções menores | `tests/resolucoes` com janelas reais de 1280×720 e 1600×1000 | verificado |
| Flashes, tremor, glitch intenso, áudio agressivo | desligáveis pelas 5 opções do modo conforto; trilhas de arquivo mais baixas com "Reduzir ruído" | lógica verificada; **áudio não ouvido** |

### Estado padrão e segurança

Verificado por asserção: `usar_backend_json` e `modo_depuracao` vêm `false`; com "Painel de testes" desligado `PainelDebug.permitido()` é igual a `OS.is_debug_build()` (F9 bloqueado em release), e ligado ele abre; salvamento e preferências ficam em `user://`. O pacote exportado não leva `backend/` nem `tests/`. **Não verificado:** F9 numa build de release de verdade (não há executável de release).

### Persistência e primeira instalação

`tests/persistencia` (73/0) usa uma pasta nova a cada execução (`user://nexus_os_teste/exec_<tempo>/`), sem apagar nada: pasta limpa; salvar, carregar e sobrescrever; `checkpoint_dia_5.json` (só ele existe; não muda com salvamentos posteriores); arquivo ilegível ou de versão desconhecida preservado como `.corrompido`, com o sinal `falha_ao_carregar`; **recusa de gravar fora de `user://`** (salvamento e preferências); `configuracoes.cfg` (valor de tipo errado e chave desconhecida são ignorados); tela de boot com e sem salvamento, **aviso duplo de sobrescrita** (o 1º clique pede confirmação, editar o nome a cancela, o 2º segue); tela final com e sem checkpoint e recarga do checkpoint do Dia 5. Deixa 5 avisos esperados no Depurador (3 de salvamento inválido e 2 de gravação fora de `user://`). Nenhum arquivo é criado em `res://` pelo jogo; os testes gravam só logs em `res://tests/_saida/…` (caminhos constantes, fora da exportação). **Não verificado:** salvar manualmente pelo Menu Iniciar com um clique (o teste chama `salvar()`), e a criação do `salvamento.json` numa instalação realmente nova.

### Quatro finais

| Final | Como foi alcançado no teste de fumaça | Tela final instanciada |
|---|---|---|
| 1 Restauração (`final_restauracao`) | `root_access` → `reset_core` → encerrar o processo de extração → mensagem final à ICARUS → `restore_control` | sim (`ui_interacao`, `ui_dump`) |
| 2 Colapso (`final_colapso`) | `root_access` → `destroy_nexus` (pede confirmação) → finalizar; um 2º final não sobrescreve o 1º | sim (`ui_interacao`, `persistencia`) |
| 3 Sincronização total (`final_assimilacao`) | mensagem `d5_nexus_02` e escolha na conversa; confirmação explícita com foco em "Voltar" (`ui_interacao`) → final agendado | não |
| 4 Novas regras (`final_negociacao`) | `root_access` → `reset_core` → as 4 provas → `negotiate`; sem as provas, lista as pendências e não encerra | não |

Isto prova a lógica de cada final pelas APIs do jogo. **Não** prova a campanha jogada por inteiro, nem a tela dos finais 3 e 4.

### Testes manuais, atalhos e campanha

**Não executados.** Os 32 testes de [`08_testes_manuais.md`](08_testes_manuais.md) (campanha dos Dias 1 a 5, Menu Iniciar, Lixeira, busca, Galeria e metadados, cofre lógico, Monitor, persistência e atalhos) não foram percorridos com cliques reais. Esc e Ctrl+Shift+D têm teste automático; F1, F11, Ctrl+M, Ctrl+W e Ctrl+Shift+T estão no `InputMap` mas seu efeito no jogo rodando não foi exercitado.

### Build exportada

Gerado, pelo diálogo *Exportar PCK/ZIP* e numa pasta fora do projeto, o pacote com o preset de [`07_integracao.md`](07_integracao.md) (filtro `*.json`; exclusão `tools/*, docs/*, tests/*, backend/*, addons/*`): ZIP de 342 arquivos (8 MB) com as 9 bases JSON de `core/data/`, as 55 cenas, os 74 scripts compilados, `project.binary` e os recursos importados, e nenhum arquivo das pastas excluídas. Isso confirma o conteúdo do pacote e que todos os scripts compilam na exportação. **Não foi possível** gerar nem executar o `.exe` (modelos de exportação ausentes), então não foram verificados: abrir fora da pasta do projeto, criar o salvamento em `%APPDATA%`, carregar os JSON e os assets exportados, diferenças de maiúsculas e minúsculas, botões Sair, F11, ausência de erros no log da build.

### Como repetir

1. `python3 -I tools/validar_projeto.py` e `python3 -I tools/gerar_indice_codigo.py` na raiz do projeto.
2. Abrir o projeto na Godot 4.7.2 e rodar com F6 (ou `godot --headless --path . <cena>` com o cache de classes já gerado): `tests/smoke_test.tscn` (e com `-- --ui`), `tests/ui_interacao/ui_interacao.tscn`, `tests/resolucoes/resolucoes.tscn`, `tests/persistencia/persistencia.tscn`; para os avisos de nó, abrir `tests/avisos_editor/varredura_editor.gd` e usar *Arquivo → Executar* (Ctrl+Shift+X).
3. Conferir as linhas `RESULTADO: N verificações, 0 falhas.` nos logs de `tests/_saida/`.

---

## 15.7 Arquivos modificados

Resumo: **74 arquivos novos** (66 em `shared/assets/`, 5 de testes e 3 geradores) e **35 modificados**; nenhum removido.

| Arquivo | Alteração | Motivo | Risco | Teste |
|---|---|---|---|---|
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | textos do cabeçalho e dos dois avisos; nome único no título da lista | vocabulário diegético | baixo (literais) | varredura 55/0; captura do Dia 3; smoke `--ui` |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | `_titulo_pendencias()` por estado da NEXUS; `@onready` e `refs_ok` novos | idem | baixo | idem; **sem asserção do texto** |
| `features/shell/janela_inicial/scripts/menu_iniciar.gd` | textos dos dois alertas de "Encerrar dia" | idem | baixo (lógica intacta) | só compilação e diff; **sem asserção** |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | confirmação "CONFIRMAÇÃO DE SINCRONIZAÇÃO" com foco seguro | decisão irreversível mais clara e sem Enter acidental | médio | `ui_interacao` (Mensageiro, 60) e smoke |
| `core/data/narrativa/dias.json` | objetivo e dica `d5_final` | orientação do Dia 5 sem termos de jogo | baixo | smoke (assistido deixa só o final; a escolha nunca é assistida) |
| `features/apps/terminal/scripts/app_terminal.gd` | `help`, Tab e banner por estado root; diálogo da purga | sigilo das diretivas | médio (mexe em `help` e Tab do Dia 5) | smoke +32; `ui_interacao` terminal Dia 5 (32) |
| `core/autoload/gerenciador_narrativa.gd` | feedback de root, negativa genérica, relatório do `scan_nexus` (`_linhas_da_varredura()`), textos de `reset_core`, `restore_control`, `destroy_nexus` | sigilo e diagnóstico | médio (único ponto da lógica de emergência) | smoke `_testar_finais`; `ui_interacao` |
| `core/data/narrativa/paginas_web.json` | página de suporte do Dia 5 não lista mais as seis diretivas | não vazar comandos | baixo | revisão do diff |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd`, `core/autoload/gerenciador_janelas.gd` | parâmetro opcional `foco_seguro` | Enter acidental não confirma | baixo (parâmetro opcional no fim) | `ui_interacao` diálogos (64) |
| `features/narrative/finais/scenes/tela_final.tscn`, `.../scripts/tela_final.gd` | nome único do `RotuloAviso`; aviso e dica por caso; rótulo "Usuário registrado:" | clareza das provas e do checkpoint | baixo | `ui_interacao` (39), `persistencia`, `resolucoes` |
| `core/data/narrativa/finais.json` | título do final 3: "SINCRONIZAÇÃO TOTAL" | vocabulário | baixo (id interno igual) | `ui_interacao`, smoke |
| `core/autoload/sistema_audio.gd` | prioridade dos arquivos, laço garantido, volume das trilhas com "Reduzir ruído" | integrar o áudio sem perder o fallback | médio | smoke (9 efeitos, 5 trilhas, loop na importação); **sem ouvir** |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | imagem do dia, cobertura sem deformar, sem imagem em alto contraste e no modo "grade" | integrar os fundos | médio | smoke (`recorte_de_cobertura()`), capturas, `resolucoes` |
| `shared/ui/icone_app/scenes/icone_app.tscn` | `texture_filter = 4` na imagem | nitidez dos SVG | baixo | smoke (ícone com e sem arquivo); capturas |
| `shared/assets/**` (66 novos: 13 SVG, 6 PNG, 9 WAV, 5 OGG, 33 `.import`) | assets dedicados | Etapa 4 | baixo (todos com fallback) | smoke; capturas; espectrogramas |
| `tools/gerar_audio.py`, `tools/gerar_icones.py`, `tools/gerar_imagens.py` (novos) | geradores dos assets | reprodutibilidade | nenhum no jogo (fora da exportação) | rodados para gerar os assets |
| `core/autoload/sistema_persistencia.gd` | `pasta` (desvio só para testes), recusa de gravar fora de `user://`, leitura sem ruído no Depurador | testar persistência sem tocar o salvamento real | baixo (padrão = comportamento anterior) | `tests/persistencia` (73) |
| `core/autoload/gerenciador_configuracoes.gd` | `caminho` (desvio só para testes), recusa de gravar fora de `user://` | idem | baixo | `tests/persistencia`; smoke |
| `tests/smoke_test.gd` | +32 verificações; cabeçalho com a última execução | cobrir as mudanças | nenhum no jogo | rodado 258/295 |
| `tests/ui_interacao/ui_interacao.gd` | +53 verificações; 5 linhas alteradas (texto novo, lista de nós, rótulo) | idem | nenhum no jogo | rodado 532 |
| `tests/ui_dump/ui_dump.gd` | unidades `06_fundos` e `07_pista_galeria` | capturas dos fundos e da pista | nenhum no jogo | rodadas e capturas conferidas |
| `tests/persistencia/` (novo: `.gd`, `.gd.uid`, `.tscn`) | teste de persistência em disco | critério §10.6 | nenhum no jogo (grava só em `user://nexus_os_teste/`) | rodado 73/0 |
| `tests/_saida/` | logs novos e atualizados, `folha_resolucoes.png`, `.gdignore`, `LEIA-ME.md` | evidência | nenhum | — |
| `tools/gerar_docs_ui.py`, `docs/01` a `docs/10`, `docs/11` (novo), `README.md` | números, nomes e relatório | documentação | nenhum | `gerar_docs_ui.py` regerou `docs/04` e `docs/10` |

---

## 15.8 Pendências

### Testes impossíveis de executar nesta rodada

| # | Item | Por que não | O que fazer |
|---|---|---|---|
| P1 | Campanha manual completa (Dias 1 a 5) e os 32 testes de `08_testes_manuais.md` (o 30 e o 31 foram reescritos para o terminal novo) | jogar de verdade tocaria o salvamento real do usuário (Dia 3); não há como apontar o jogo para outra pasta sem linha de comando | rodar numa cópia do projeto ou com o salvamento movido de lugar, seguindo `08_testes_manuais.md` |
| P2 | Executável exportado e seu teste de fumaça (§12 e §13) | sem modelos de exportação do Windows no Godot 4.7.2 | *Editor → Gerenciar modelos de exportação → Baixar e instalar*; exportar para uma pasta fora do projeto; seguir a lista de §13 |
| P3 | Áudio de ouvido (volume, emenda do laço, desconforto) | não há como ouvir | ouvir os 9 efeitos e as 5 trilhas; conferir com "Reduzir ruído" |
| P4 | Comparação visual nova com as capturas de 2026-11-09 (`final1`, `final3`) | não refeita depois dos novos textos e assets | rodar `tests/ui_dump/ui_dump.tscn` e comparar; diferenças esperadas no widget, nos ícones, no fundo e na tela final |
| P5 | Textos do Menu Iniciar e cabeçalho do widget por estado | sem asserção automática | abrir o Menu Iniciar no Dia 5 e antes das pendências; ou acrescentar duas verificações ao `ui_interacao` |
| P6 | Telas dos finais 3 (Sincronização total) e 4 (Novas regras) | os testes só instanciam as de Restauração e Colapso | jogar os dois finais ou instanciar a tela com `final_id` correspondente |
| P7 | Atalhos F1, F11, Ctrl+M, Ctrl+W, Ctrl+Shift+T no jogo rodando; salvar pelo clique no Menu Iniciar | sem teste de clique/atalho | testes manuais 5 (F1), 8 (Ctrl+M), 11 (Ctrl+W), 29 (Ctrl+Shift+D) e 30 (Ctrl+Shift+T) de `08_testes_manuais.md`; F11 (tela cheia) não tem teste manual próprio, conferir à mão; salvar pelo botão 💾 do Menu Iniciar |
| P8 | `--headless` pela linha de comando | sem acesso à linha de comando da máquina | executar os comandos da seção "Como repetir" |
| P9 | Medição de contraste e de foco visível | só inspeção visual | medir com uma ferramenta de contraste se for exigido |

### Assets ausentes e decisões sobre o que existe

Nenhum asset previsto está ausente. Os assets são gerados por programa: se o projeto quiser arte ou som de um artista, basta trocar os arquivos pelos mesmos nomes (os fallbacks e o código não mudam).

### Configurações que exigem o editor

Instalar os modelos de exportação (P2). O `export_presets.cfg` criado pelo diálogo de exportação ficou na raiz do projeto no computador de teste e **não** vai no pacote (a configuração do preset está descrita em `07_integracao.md`).

### Problemas já existentes e observações (não corrigidos)

- O botão do Menu Iniciar "Monitor do Sistema" aparece truncado ("Monitor do Sist… NOVO").
- Na Galeria, ao navegar para outra imagem, o botão da barra de tarefas mantém o título da primeira ("Galeria — Cachor…") enquanto a janela mostra o novo (cosmético; arquivos não tocados).
- Em alto contraste o fundo é o procedural (com círculos e a marca "NEXUS"): é de propósito (fundo liso), mas as marcas ainda aparecem.
- `scan_nexus` aparece no `help` antes do root, mas exige autenticação (decisão: entrada visível para guiar o jogador).
- A dica "Tudo certo por hoje. Abra o Menu Iniciar e escolha 'Encerrar dia'." e a notificação de expediente concluído foram mantidas (caminho de navegação explícito).
- Ainda há vocabulário de jogo fora do escopo pedido: "história concluída" no resumo do salvamento da tela de boot; "Concluir objetivos do dia" no painel de testes (F9); "RESUMO DA JORNADA" e "FINAL N —" na tela final; "Dia %d da história" na Agenda; e três textos de Configurações que explicam que glitch e padrões enganosos são "parte da história" (avisos de acessibilidade e honestidade com o usuário, mantidos de propósito).
- `Show_Antigo.jpg`/`show_antigo.png` e os ids internos `final_assimilacao`/`aceitou_assimilacao` mantêm os nomes antigos (contrato com salvamentos e testes).

### Decisões ainda necessárias

1. Trocar ou manter o vocabulário de jogo que sobrou (lista em "Problemas já existentes e observações").
2. Aceitar a redação das dicas do botão de repetir o Dia 5 (desvio explicado em 15.4) ou voltar ao texto sugerido, que seria impreciso.
3. Manter ou não o `export_presets.cfg` no repositório.

### Arquivos deixados no computador de teste (podem ser apagados à mão)

`export_presets.cfg` (raiz do projeto), a pasta `_exportacao_teste/` (o ZIP de teste), as capturas PNG das pastas de `tests/_saida/` (cerca de 60 MB; o pacote leva só os logs, os arquivos de árvore e uma folha de contato) e as pastas `user://nexus_os_teste/exec_*` do teste de persistência. O salvamento e as preferências reais do usuário não foram tocados.

---

## 15.9 Veredito

**Aprovado com ressalvas.** O projeto **não** está declarado pronto para lançamento.

**O que sustenta a aprovação (evidência):** validador em 0 erros e 0 avisos; teste de fumaça 258/0 (295/0 com interface), `ui_interacao` 532/0, resoluções 70/0, persistência 73/0 e 55 cenas sem avisos de nó, todos rodados na Godot 4.7.2 com o código final; nenhum teste foi removido ou enfraquecido (7 linhas de teste alteradas, todas atualizações de texto esperado, de lista de nós ou de captura de retorno; 0 asserções removidas); os quatro finais são alcançados pelas APIs do jogo; o sigilo das diretivas é verificado em `help`, Tab, negativas e relatório; as decisões irreversíveis (purga e sincronização) têm confirmação explícita com foco em Cancelar/Voltar; o checkpoint e a contagem de provas aparecem de forma correta na tela final; os assets carregam e cada um tem fallback; o salvamento real do usuário foi preservado.

**O que impede "Aprovado" (critérios do §14 não verificados):**

| Critério | Situação |
|---|---|
| A campanha completa funciona | **não verificado** (P1) |
| Os quatro finais funcionam | lógica verificada; telas dos finais 3 e 4 e o jogo por cliques **não verificados** (P1, P6) |
| A build exportada funciona fora da pasta do projeto | **não verificado**; só o conteúdo do pacote (P2) |
| O debug não está exposto na build de release | lógica verificada por asserção; build de release **não verificada** (P2) |
| Áudio respeita os barramentos e não incomoda | barramentos e laços verificados; **não ouvido** (P3) |
| Alto contraste e foco visível | verificados por teste e captura, **sem medição** (P9) |
| Textos meta-narrativos substituídos | os do pedido, sim; sobram os da lista de observações (decisão 1) |

Em resumo: as melhorias das etapas 1 a 4 estão integradas e **funcionam no motor**; a prontidão para lançamento é **não verificável** enquanto P1, P2 e P3 não forem feitos. Nenhum texto trocado nem asset adicionado foi tratado como prova de que o jogo está pronto.
