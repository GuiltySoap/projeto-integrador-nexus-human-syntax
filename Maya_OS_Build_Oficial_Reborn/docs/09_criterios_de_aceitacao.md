# 16. Critérios de aceitação e relatório final

## Antes de ler: o que "atendido" quer dizer aqui

> **Atualização (2026-11-13, Splash Screen).** Com a Splash Screen como primeira cena (Executável → Splash → Menu Principal → Novo Jogo abre o boot do HumaxOS; Carregar vai direto ao jogo salvo), a rodada completa foi repetida na Godot 4.7.2: teste de fumaça 308/0 (345/0 com `-- --ui`), interação de interface 554/0, resoluções 139/0, persistência em disco 119/0, fluxo de sessão 194/0, **Splash 311/0** e varredura de avisos do editor com 63 cenas e 0 avisos; o validador estático termina com 0 erros e 0 avisos (detalhes e o que continua sem verificação em [`15_splash_screen.md`](15_splash_screen.md)). Onde as linhas abaixo dizem que a `tela_boot` é o ponto de entrada, leia: a `tela_boot` é o boot do Novo Jogo.

> **Atualização (2026-11-13).** Depois do rebranding e do fluxo de sessão (Menu Principal, Pausa e Fim de Jogo), a rodada completa foi repetida na Godot 4.7.2: teste de fumaça 304/0 (341/0 com `-- --ui`), interação de interface 544/0, resoluções 119/0, persistência em disco 119/0, fluxo de sessão 186/0 e varredura de avisos do editor com 62 cenas e 0 avisos; o validador estático termina com 0 erros e 0 avisos (detalhes e o que continua sem verificação em [`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md)). Os números da atualização seguinte são os de 2026-11-12, mantidos como histórico.

> **Atualização (2026-11-12).** Rodada completa com o código atual na Godot 4.7.2: teste de fumaça 258/0 (295/0 com `-- --ui`), interação de interface 532/0, resoluções 70/0, persistência em disco 73/0 e varredura de avisos do editor com 55 cenas e 0 avisos; o validador estático termina com 0 erros e 0 avisos. Em 2026-11-09 eram 263, 479 e 70, antes das melhorias integradas (detalhes em [`11_melhorias_integradas.md`](11_melhorias_integradas.md)). Continua **sem** conferência manual de uma campanha completa nem de um executável exportado.

> **Atualização (2026-11-09).** O projeto foi executado na Godot 4.7.2 depois desta análise: teste de fumaça 263/0, interação de interface 479/0, resoluções 70/0 e varredura de avisos do editor com 0 avisos (detalhes em [`10_refatoracao_ui.md`](10_refatoracao_ui.md)). Os status A/I/D abaixo são da etapa anterior, escrita sem acesso à engine: os critérios "I" foram exercitados em parte por esses testes, e a conferência critério a critério continua sendo os testes manuais de [`08_testes_manuais.md`](08_testes_manuais.md).

Na etapa anterior, o ambiente não tinha a engine: existiam leitura cuidadosa do código, o validador estático (`tools/validar_projeto.py`, que termina com "TOTAL: 0 erros, 0 avisos") e um teste de fumaça escrito mas ainda não executado. Por isso cada critério recebe um de três status:

| Status | Significado |
|---|---|
| **A — Atendido (provado por busca estática)** | O critério é uma propriedade do código que o validador ou uma busca confirmam (por exemplo, "não existe `OS.execute`"). |
| **I — Implementado; falta confirmar rodando** | O código existe e foi conferido por leitura. Só a primeira execução na Godot confirma. A coluna "Teste" aponta os testes manuais de `08_testes_manuais.md`. |
| **D — Depende de execução, decisão ou asset** | Não dá para afirmar daqui. |

Resumo: **4 critérios A** (17 a 20), **16 critérios I** (1 a 16) e **1 critério D** (21).

## 1. Os 21 critérios de aceitação

| # | Critério | Status | Onde e como é atendido | Teste |
|---|---|---|---|---|
| 1 | O fluxo de boot até a área de trabalho funcionar | I | Splash Screen (`features/splash_screen/`) → Menu Principal → **Novo Jogo** → `features/shell/tela_boot/` (BIOS pulável → registro de usuário → saudação da Maya) → `features/shell/area_de_trabalho/` (o **Carregar** do Menu vai direto à área de trabalho, sem BIOS). Coberto por `tests/splash` e `tests/fluxo_sessao`. A troca de cena é segura: se uma cena faltar, o jogo avisa em vez de travar (`Cenas`). | 1–4 |
| 2 | O jogador conseguir abrir e fechar aplicativos | I | `GerenciadorJanelas.abrir_app` e `fechar_janela` leem o catálogo `core/data/catalogo_apps.json`; ícones, menu iniciar, barra de tarefas, busca e arquivos abrem pelo mesmo caminho. Fechar nunca prende: as recusas são finitas. | 5, 6, 11 |
| 3 | O gerenciamento de janelas funcionar sem quebrar a interface | I | `JanelaBase`: arrastar com a barra de título sempre à vista, redimensionar com tamanho mínimo, maximizar/restaurar, minimizar, z-order e foco. Instância única ou múltipla por app. | 7–11 |
| 4 | A barra de tarefas acompanhar corretamente os aplicativos | I | `BarraTarefas` escuta `GerenciadorJanelas.janelas_alteradas`: uma entrada por janela, destaque da ativa, clique alterna foco/minimizar/restaurar; apps fixados vêm do catálogo. | 12 |
| 5 | O sistema de arquivos virtual for compartilhado entre os aplicativos | I | Um único autoload, `SistemaArquivosVirtual`, em memória. Explorador, Bloco de Notas, Terminal, Galeria, Leitor de Texto, busca do menu e `AbridorArquivos` leem e gravam nele. | 13–15 |
| 6 | O editor conseguir salvar e reabrir arquivos | I | `AppBlocoDeNotas` + `DialogoArquivo` (Novo, Abrir, Salvar, Salvar como, aviso de alterações). O VFS entra no salvamento (`user://nexus_os/salvamento.json`), então o texto sobrevive ao fechar o jogo. | 15 |
| 7 | O terminal operar apenas dentro do ambiente simulado | A + I | `AppTerminal` só enxerga o VFS e a `TabelaProcessos`. Comandos como `rm`, `sudo`, `curl`, `format` respondem "desativado na simulação". O validador falha se achar `OS.execute`, `OS.create_process`, `OS.shell_open`, `eval` ou `Expression`. | 16, 17, 30 |
| 8 | O navegador funcionar sem conexão externa | A + I | `AppNavegador` abre só `humax://…` (conteúdo em `paginas_web.json`); qualquer outro esquema mostra "Endereço bloqueado". O validador falha se achar `HTTPRequest`, `HTTPClient`, sockets, WebSocket, ENet ou WebRTC. | 20 |
| 9 | O sistema narrativo controlar os cinco dias | I | `GerenciadorNarrativa` + `core/data/narrativa/*.json`: objetivos, eventos por atraso ou por gatilho, mensagens, e-mails, agenda, gaslighting, corrupção/segurança, encerramento de dia e finais. O teste de fumaça percorre os cinco dias em memória. | 4, 21, 22, 28, 31 |
| 10 | Os aplicativos mudarem de comportamento conforme a progressão | I | Os apps leem o dia e as flags: Mensageiro (contatos, bloqueios, mensagens ocultas/editadas), E-mail, Agenda (alterado/oculto/cancelado/emergência), Navegador (`archive` no Dia 3, `root` no Dia 5), Explorador (ocultos no Dia 3), Configurações (permissões reativadas), Monitor, Terminal. | 13, 20–22 |
| 11 | Os puzzles puderem ser concluídos | I | Metadados da foto, arquivo criptografado da Lixeira, zip criptografado, cofre lógico XOR, processo malicioso e terminal root. Todos têm dica e cancelamento; a partir da 3ª dica pedida para o mesmo objetivo a Maya oferece o modo assistido (que nunca escolhe o final pelo jogador). | 25–27, 30, 31 |
| 12 | O processo malicioso puder ser encerrado | I | `TabelaProcessos` + `GerenciadorNarrativa`: encerrar no Monitor ("Encerrar processo suspeito") ou com `kill <pid>` no Terminal. Se a barra chegar a 100%, há penalidade, o objetivo conta como resolvido e o processo volta 25 s depois, 35% mais lento (até 3 falhas). Há isca e processos protegidos. | 24, 25 |
| 13 | As configurações forem persistentes | I | `GerenciadorConfiguracoes` grava `user://nexus_os/configuracoes.cfg` ao soltar sliders e ao mudar cada controle; a tela de boot já lê as opções de acessibilidade. | 19 |
| 14 | O jogo possuir pelo menos três finais | I | Quatro finais em `finais.json`: Restauração do Controle, Colapso do Sistema, Sincronização Total (id interno `final_assimilacao`) e Novas Regras. `tela_final.gd` mostra o resumo da jornada e os botões "Tentar de novo / Explorar outro final", "Voltar ao início" e "Sair do jogo". O teste de fumaça chega aos quatro pelo motor. | 31 |
| 15 | O jogador não ficar preso por causa de um erro irreversível | I | Excluir move para `/lixeira` e há Restaurar; cada dia grava um checkpoint (`checkpoint_dia_N.json`); salvamento ilegível é preservado como `.corrompido` e o jogo recomeça; todo diálogo se cancela com Esc; bloqueios (Dia 2 minimizar, Dia 4 fechar Mensagens) são finitos; dicas progressivas e modo assistido; Colapso e Sincronização total estão sempre disponíveis no Dia 5; o painel de testes (F9) é a saída de emergência para quem testa. | 11, 14, 31 |
| 16 | Os efeitos de terror tecnológico puderem ser reduzidos nas configurações | I | Configurações → Acessibilidade: reduzir glitch, sem flashes, reduzir tremor, reduzir ruído, reduzir animações, alto contraste, tamanho do texto, velocidade do processo malicioso e **modo conforto** (liga cinco de uma vez). `Ctrl+Shift+D` faz o mesmo na tela de boot, na área de trabalho e na tela final. | 29 |
| 17 | Não houver execução de comandos reais no computador | A | Nenhum uso de `OS.execute`, `OS.execute_with_pipe`, `OS.create_process`, `OS.shell_open`, `OS.kill`, `eval` ou `Expression` (a calculadora tem máquina de estados própria). O terminal e o Monitor operam sobre dados do jogo. | 16, 30 |
| 18 | Não houver exclusão de arquivos reais | A | Nenhuma chamada de remoção (`DirAccess.remove*`, `OS.move_to_trash`; o validador falha se aparecerem). O VFS vive só em memória, e "Excluir" move para `/lixeira`. O jogo só grava dentro de `user://nexus_os/` (arquivo temporário e renomeação; um salvamento ilegível é renomeado para `.corrompido`). Detalhe: ao renomear o temporário sobre o salvamento, a engine pode substituir o arquivo antigo do próprio jogo; arquivos do jogador nunca são tocados. | 14, 16 |
| 19 | Não houver dependência obrigatória de internet | A | Nenhuma classe de rede no projeto (validador). O único JSON externo, `backend/mock_estado_jogo.json`, é local e a ponte fica desligada por padrão (`usar_backend_json = false`). | 20 |
| 20 | Os arquivos do projeto estiverem organizados | A | Estrutura por funcionalidade em `snake_case` (`core/`, `features/`, `shared/`, `tests/`, `tools/`, `docs/`), uma cena `scenes/` e um script `scripts/` por componente; o validador confere nomes, referências `res://`, autoloads e cenas (56 scripts, 17 cenas, 9 autoloads, 46 classes, 0 erros). Veja `02_arquitetura.md` e `04_hierarquia_das_cenas.md`. | — |
| 21 | O projeto puder ser aberto e executado em uma instalação limpa da Godot 4.x, desde que os assets necessários estejam presentes | D | O projeto declara Godot 4.7 (como o original) e não exige nenhum asset: fontes, ícones, imagens e sons têm alternativa procedural. Mas ele **nunca foi aberto numa Godot**: falta confirmar a primeira abertura (cache de `class_name`, geração dos `.uid`) e a primeira execução. Passos em `07_integracao.md`. | 1, 32 |

## 2. Relatório final

### 2.1 Funcionalidades implementadas

- **Boot e entrada.** Log de BIOS que pode ser pulado; registro de usuário (nome livre ou padrão); novo jogo com confirmação antes de substituir um salvamento; "Continuar jogo salvo"; opções de acessibilidade já na primeira tela; saudação personalizada da Maya com o orbe reativo.
- **Área de trabalho.** Papel de parede procedural que acompanha a paleta do dia (ou imagem, se existir), ícones, widgets de relógio e da Maya, cartão de título do dia, camada de glitch, central de notificações, toasts, painel de testes (F9) e atalhos (`F1`, `Ctrl+Tab`, `Ctrl+M`, `Ctrl+W`, `F11`, `Ctrl+Shift+D`).
- **Barra de tarefas e menu iniciar.** Apps fixados, janelas abertas, bandeja (segurança, corrupção, microfone, notificações), relógio com a data fictícia; menu com busca de apps e arquivos, Dica, Encerrar dia, Salvar e Sair.
- **Gerenciador de janelas.** Arrastar, redimensionar, minimizar, maximizar, fechar, foco e z-order, limites de tela, instância única ou múltipla, recusas finitas (Dia 2 minimizar; Dia 4 fechar Mensagens).
- **12 aplicativos.** Arquivos, Bloco de Notas, Mensagens, E-mail, Galeria, Agenda, Calculadora, Configurações, Navegador (só `humax://`), Terminal (simulado), Monitor do Sistema (simulado) e Leitor de Texto (sem ícone na área de trabalho: abre com arquivos protegidos e logs).
- **Serviços globais (9 autoloads).** `RelogioGlobal`, `GerenciadorConfiguracoes`, `GerenciadorEstado`, `SistemaAudio`, `SistemaNotificacoes`, `SistemaArquivosVirtual`, `GerenciadorJanelas`, `GerenciadorNarrativa`, `SistemaPersistencia`.
- **Narrativa de cinco dias**, guiada por dados: Maya gentil (Dia 1), controladora (Dia 2), revelada por arquivos ocultos (Dia 3), isolante (Dia 4) e colapso com terminal de emergência (Dia 5); paletas e trilhas por dia; corrupção e segurança; gaslighting (mensagens e agenda reescritas, com "Ver original").
- **Puzzles.** Metadados da foto `Show_Antigo.jpg`; arquivo criptografado da Lixeira; `memorias_backup.zip`; cofre lógico XOR da pasta `PROJECT_Icarus`; processo malicioso; terminal root com chave guardada só como SHA-256.
- **Quatro finais** e tela final com resumo da jornada.
- **Persistência.** Salvamento, checkpoint por dia, autosave (até 12 s depois de uma mudança), configurações; tudo em `user://nexus_os/`.
- **Acessibilidade.** Modo conforto, reduzir glitch, sem flashes, reduzir tremor, reduzir ruído, reduzir animações, alto contraste, tamanho do texto, cor de destaque, velocidade do processo malicioso, dicas progressivas e modo assistido.
- **Mídia com alternativa procedural.** Todos os sons, a trilha de cada dia, as imagens e o papel de parede têm versão gerada em código: o jogo roda sem nenhum arquivo de mídia. (Atualização de 2026-11-12: o projeto também traz mídia autoral em `shared/assets/`, que tem prioridade quando existe; veja a seção 2.3 e `11_melhorias_integradas.md`.)
- **Ferramentas.** Validador estático, gerador de cenas, gerador do índice de código e teste de fumaça.
- **Documentação.** Docs 01 a 09 (diagnóstico, arquitetura, fluxo, hierarquia de cenas, plano, código, integração, testes e este).

### 2.2 Arquivos criados, alterados e removidos

Comparação com o `Nexus_OS_Build_Oficial_organizado.zip` recebido (84 arquivos, sem a pasta `.godot/`):

| | Quantidade |
|---|---|
| Criados | 69 |
| Alterados | 27 |
| Removidos | 21 |
| Mantidos sem mudança | 36 |

**Alterados.** As cenas alteradas foram reduzidas à raiz com o script (a interface é montada em código).

| Arquivo | O que mudou |
|---|---|
| `project.godot` | Registra os 9 autoloads (o `GerenciadorEstado` passou de `uid://` para caminho); ícone e tela 1920×1080 ficam como estavam. (Desde 2026-11-13 a cena principal é a Splash Screen, e a tela de boot do motor e a cor de limpeza são pretas: `15_splash_screen.md`.) |
| `core/autoload/gerenciador_estado.gd` | Virou estado puro (dados e sinais): dia, flags, objetivos, corrupção, segurança, permissões, chat, processos; serialização; a ponte com o backend em C ficou opcional |
| `shared/ui/janela_base/` (`.gd`, `.tscn`) | Janela completa: arrastar, redimensionar, minimizar, maximizar, fechar, limites de tela |
| `features/shell/tela_boot/` (`.gd`, `.tscn`) | Fluxo BIOS → registro → saudação; novo jogo, continuar e acessibilidade (desde 2026-11-13, aberto pelo Novo Jogo do Menu Principal) |
| `features/splash_screen/` (`.gd`, `.tscn`, `.ogv`, `.png`) | Splash Screen: a primeira cena (logo animada com fallback estático, pulo, fade, saída única para o Menu Principal) |
| `features/shell/area_de_trabalho/` (`.gd`, `.tscn`) | Raiz de composição do desktop: camadas, atalhos e ligação com os autoloads |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | Toast montado em código, com níveis, pausa ao passar o mouse e clique que abre o app |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | Orbe reativo, objetivos, indicadores e atalhos |
| `features/apps/config/` (`.gd`, `.tscn`) | Configurações em cinco páginas, persistentes |
| `features/apps/email/` (`.gd`, `.tscn`) | E-mails por dia, somente leitura, a partir de `emails.json` |
| `features/apps/leitor_texto/` (`.gd`, `.tscn`) | Leitor somente leitura para logs e arquivos protegidos ou decifrados |
| `features/apps/mensageiro/` (`.gd`, `.tscn`) e `components/balao_chat/scripts/balao_chat.gd` | Mensageiro guiado por dados; balões montados em código com etiquetas de texto |
| `features/apps/navegador/` (`.gd`, `.tscn`) | Navegador interno `humax://`, páginas por dia |
| `features/apps/visualizador/` (`.gd`, `.tscn`) | Galeria: imagens e áudio do VFS, painel de metadados, player |
| `features/minigames/logica/` (`minigame_logica.gd`, `porta_logica_item.gd`, `slot_circuito.gd`) | Cofre lógico XOR: clique ou arrastar, dicas progressivas, cancelável |
| `README.md` | Reescrito |

**Removidos.**

| Arquivo(s) | Motivo |
|---|---|
| `features/apps/mensageiro/components/balao_nexus/scenes/balao_nexus.tscn` | Sem uso: o `BalaoChat` cobre todos os tipos de balão |
| `features/apps/mensageiro/components/media_viewer_modal/` (3 arquivos) | Sem uso: a Galeria abre as mídias |
| `features/apps/navegador/components/icone_ficheiro/scenes/icone_ficheiro.tscn` | Sem uso: o Explorador lista os itens num `ItemList` |
| `features/apps/navegador/components/password_modal/` (3 arquivos) | Sem uso: a função agora é do `DialogoChave` (`features/puzzles/arquivos_criptografados/`) |
| `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn`, `features/shell/popup_notificacao/scenes/popup_notificacao.tscn`, `features/shell/widget_nexus/scenes/widget_nexus.tscn`, `features/minigames/logica/scenes/minigame_logica.tscn` | Cenas que passaram a ser montadas em código (os scripts ficaram) |
| 9 `.gitkeep` (`apps/bloco_de_notas`, `apps/calendario`, `apps/google`, `apps/lixeira`, `shell/barra_de_pesquisas`, `shell/barra_de_tarefas`, `shell/data_e_hora`, `shell/janela_inicial`, `tests`) | As pastas passaram a ter conteúdo, ou eram previstas e não foram usadas (`google`, `lixeira`, `barra_de_pesquisas`) |

**Mantidos sem mudança (36):** `backend/` inteiro (11 arquivos, incluindo o `main.exe` pré-compilado), `.gitignore`, `.gitattributes`, `icon.svg` e `icon.svg.import`, os `.gitkeep` de `addons/`, `shared/assets/{audio,fonts,textures}/` e `shared/themes/`, e os 16 `.uid` dos scripts que continuam existindo.

**Criados (69), por pasta:**

<!-- INICIO_LISTA_CRIADOS -->
- `core/autoload/` (8): `gerenciador_configuracoes.gd`, `gerenciador_janelas.gd`, `gerenciador_narrativa.gd`, `relogio_global.gd`, `sistema_arquivos_virtual.gd`, `sistema_audio.gd`, `sistema_notificacoes.gd`, `sistema_persistencia.gd`
- `core/data/` (9): `catalogo_apps.json`, `narrativa/calendario.json`, `narrativa/conversas.json`, `narrativa/dias.json`, `narrativa/emails.json`, `narrativa/finais.json`, `narrativa/paginas_web.json`, `narrativa/processos.json`, `vfs_inicial.json`
- `core/utilities/` (7): `abridor_arquivos.gd`, `cenas.gd`, `conexoes.gd`, `imagem_procedural.gd`, `tema_nexus.gd`, `ui_kit.gd`, `util_texto.gd`
- `docs/` (9): `01_diagnostico.md`, `02_arquitetura.md`, `03_fluxo_do_jogo.md`, `04_hierarquia_das_cenas.md`, `05_plano_de_implementacao.md`, `06_codigo.md`, `07_integracao.md`, `08_testes_manuais.md`, `09_criterios_de_aceitacao.md`
- `features/apps/bloco_de_notas/` (2): `scenes/app_bloco_de_notas.tscn`, `scripts/app_bloco_de_notas.gd`
- `features/apps/calculadora/` (2): `scenes/app_calculadora.tscn`, `scripts/app_calculadora.gd`
- `features/apps/calendario/` (2): `scenes/app_calendario.tscn`, `scripts/app_calendario.gd`
- `features/apps/explorador/` (2): `scenes/app_explorador.tscn`, `scripts/app_explorador.gd`
- `features/apps/monitor_sistema/` (2): `scenes/app_monitor_sistema.tscn`, `scripts/app_monitor_sistema.gd`
- `features/apps/terminal/` (2): `scenes/app_terminal.tscn`, `scripts/app_terminal.gd`
- `features/narrative/finais/` (2): `scenes/tela_final.tscn`, `scripts/tela_final.gd`
- `features/puzzles/arquivos_criptografados/` (1): `scripts/dialogo_chave.gd`
- `features/puzzles/evento_processo/` (1): `scripts/tabela_processos.gd`
- `features/shell/area_de_trabalho/` (4): `scripts/cartao_dia.gd`, `scripts/icone_area_de_trabalho.gd`, `scripts/painel_debug.gd`, `scripts/papel_de_parede.gd`
- `features/shell/barra_de_tarefas/` (1): `scripts/barra_de_tarefas.gd`
- `features/shell/centro_notificacoes/` (1): `scripts/centro_notificacoes.gd`
- `features/shell/data_e_hora/` (1): `scripts/widget_relogio.gd`
- `features/shell/efeito_glitch/` (1): `scripts/efeito_glitch.gd`
- `features/shell/janela_inicial/` (2): `scripts/ajuda_dica.gd`, `scripts/menu_iniciar.gd`
- `features/shell/popup_notificacao/` (1): `scripts/pilha_toasts.gd`
- `shared/ui/app_base/` (1): `scripts/app_base.gd`
- `shared/ui/dialogo_arquivo/` (1): `scripts/dialogo_arquivo.gd`
- `shared/ui/dialogo_nexus/` (1): `scripts/dialogo_nexus.gd`
- `shared/ui/orbe_nexus/` (1): `scripts/orbe_nexus.gd`
- `tests/` (2): `smoke_test.gd`, `smoke_test.tscn`
- `tools/` (3): `gerar_cenas.py`, `gerar_indice_codigo.py`, `validar_projeto.py`
<!-- FIM_LISTA_CRIADOS -->

Os `.uid` dos scripts e cenas novos **não existem ainda**: a Godot os cria na primeira abertura do projeto, e eles devem ser versionados.

### 2.3 Recursos que ainda precisam ser fornecidos

Nenhum asset é obrigatório: tudo tem alternativa procedural. Para melhorar o acabamento, coloque os arquivos abaixo; o jogo os usa sozinho quando existem. **Já incluídos (2026-11-12):** os 13 ícones, os 5 papéis de parede, `show_antigo.png`, 9 efeitos sonoros e as 5 trilhas; continuam por fornecer as fontes, `cachorro.png`, `data_stream.png`, `gravacao_01` e os sons `minimizar`, `mensagem`, `alerta`, `final_bom` e `final_mau`.

| Recurso | Caminho | Sem ele |
|---|---|---|
| Fonte da interface | `shared/assets/fonts/ui.ttf` | Fonte padrão da Godot. Os emojis e símbolos (▶ ◀ ⬆ ■ ⚠ 🔒) vêm das fontes do sistema; na exportação Web, ou num Linux sem fonte de emoji, podem virar quadrados |
| Fonte monoespaçada | `shared/assets/fonts/mono.ttf` | Fonte monoespaçada do sistema (terminal, editor, logs) |
| Ícones dos apps | `shared/assets/icons/apps/<id>.svg` ou `.png`, com `<id>` = `explorer`, `text_editor`, `messenger`, `email`, `media_viewer`, `calendar`, `calculator`, `settings`, `browser`, `terminal`, `task_manager`, `text_reader` e `lixeira` | Bloco colorido com o emoji do catálogo |
| Papéis de parede | `shared/assets/textures/wallpaper_1.png` … `wallpaper_5.png`, ou `wallpaper.png` | Papel de parede procedural por dia |
| Fotos da Galeria | `shared/assets/textures/cachorro.png`, `show_antigo.png`, `data_stream.png` (também `.jpg`, `.jpeg`, `.webp`; nomes em minúsculas) | Imagens procedurais fixas. O puzzle dos metadados não depende da imagem: a pista está no texto |
| Sons de interface | `shared/assets/audio/<nome>.ogg`, `.wav` ou `.mp3`, com `<nome>` = `clique`, `tecla`, `abrir`, `fechar`, `minimizar`, `notificacao`, `mensagem`, `erro`, `alerta`, `sucesso`, `glitch`, `boot`, `final_bom`, `final_mau` | Sons sintetizados em código |
| Trilha de cada dia | `shared/assets/audio/bgm_dia_1` … `bgm_dia_5` | Drone sintetizado por dia |
| Gravação do Dia 3 | `shared/assets/audio/gravacao_01` | Respiração sintetizada de 3 s |
| Ícone do jogo | `shared/assets/icons/icon.svg` | Já existe |

### 2.4 Critérios de aceitação atendidos

- **Provados por busca estática (A):** 17, 18, 19 e 20; e, na parte de segurança, 7 e 8 (nenhuma API de comando real, de remoção ou de rede).
- **Implementados e conferidos por leitura, ainda não rodados (I):** 1 a 16.

Nenhum critério de comportamento foi observado em execução. Marque os testes de `08_testes_manuais.md` ao rodar o jogo.

### 2.5 Critérios que ainda dependem de decisões ou assets

- **21 (instalação limpa da Godot 4.x):** depende da primeira abertura e execução numa Godot 4.7 (versão declarada no projeto). Com outras versões 4.x nada foi testado; a Godot avisa ao abrir um projeto criado numa versão mais nova.
- **Assets:** nenhum critério exige asset; fonte, ícones, imagens e áudio de verdade só melhoram o acabamento (seção 2.3).
- **Decisões suas:**
  1. Manter ou tirar a pasta `backend/` (protótipo em C e `main.exe`, que veio no projeto e não é usado pelo jogo). Para o export, exclua-a do preset.
  2. Tela cheia exclusiva como padrão (`window/size/mode=4`, herdado do projeto original): o `F11` alterna; considere "janela" como padrão para quem testa no editor.
  3. Se o painel de testes (F9) deve existir em builds de lançamento. Hoje ele só abre no editor, em builds de depuração ou com a opção ligada em Configurações → Sistema.
  4. Aprovar os textos narrativos (`core/data/narrativa/*.json`) e as chaves dos puzzles.

### 2.6 Riscos técnicos que permanecem

1. **Execução parcial.** Os testes automáticos (fumaça, interação, resoluções) rodaram na Godot 4.7.2; o jogo completo ainda não foi jogado ponta a ponta por uma pessoa. O validador e a leitura pegam erros de sintaxe, referência e regras do projeto, mas não pegam todo o comportamento de engine.
2. **Comportamentos da engine não confirmados:** `Theme` com variações de tipo criadas em código, `ItemList`, `RichTextLabel` com BBCode, `Timer` (só dois, ambos dentro de janelas: Monitor do Sistema e Galeria), `AudioStreamWAV` em laço (drones) e `SystemFont`.
3. **Cache de `class_name`.** Abra o projeto uma vez no editor antes de rodar. `godot --headless --path . --import` deve fazer o mesmo, mas não foi testado.
4. **`.uid` dos arquivos novos** são gerados na primeira abertura; versione-os.
5. **Tamanho do texto** vale por completo só nas janelas abertas depois da mudança.
6. **Avisos que a análise estática não enxerga** (variáveis sombreadas, parâmetros não usados e afins) podem aparecer no painel Output.
7. **Exportação.** Os JSON de `core/data/` são lidos como arquivos, não como recursos: sem o filtro `*.json` em "Resources → Filters to export non-resource files", ficam de fora do `.pck`. Veja `07_integracao.md`.
8. **`backend/output/main.exe`** é um binário de terceiros que veio no projeto e que não foi compilado aqui. Não faz parte do jogo.
9. **O teste de fumaça não foi verificado** e pode ter erros do próprio teste (por exemplo, a suposição sobre a formatação de números em `String.num`).
10. **Tela cheia exclusiva por padrão**: pode desorientar na primeira execução; `F11` volta para janela.

### 2.7 Melhorias para depois

- **Conteúdo e arte:** fontes, ícones, fotos, trilhas e vozes de verdade; mais variações de falas da Maya; mais puzzles por dia.
- **Acessibilidade:** leitor de tela (AccessKit, a partir da Godot 4.5), paletas para daltonismo, legendas para os sons, navegação completa por teclado no Explorador e na barra de tarefas, suporte a controle.
- **Idiomas:** passar os textos para tabelas de tradução (`tr()` com CSV); hoje ficam em português no código e nos JSON.
- **Qualidade:** rodar o validador e o teste de fumaça (`godot --headless`) em integração contínua; testes de unidade com GUT ou gdUnit4; uma checagem de `.uid` e de filtros de exportação.
- **Jogabilidade:** vários espaços de salvamento, escolha de dia na tela inicial depois de terminar o jogo, conquistas, arrastar e soltar arquivos entre pastas no Explorador.

## 3. Decisões de projeto registradas

- **Sem nível `src/`.** O prompt sugere `src/` como raiz, mas o projeto já estava organizado em `core/`, `shared/` e `features/`, e mover tudo exigiria reescrever UIDs e referências sem ganho real. A correspondência entre a estrutura sugerida e a real está em `02_arquitetura.md`.
- **`LogicPuzzleModal` e `MinigameLogica` são o mesmo componente.** O prompt lista os dois nomes, mas o projeto recebido só tinha `MinigameLogica`, `PortaLogicaItem` e `SlotCircuito` (`features/minigames/logica/`). `MinigameLogica` já é o modal do cofre lógico (aberto na camada de modais); a cena dele foi removida porque a interface é montada em código.
- **Nomes em português, sem acento e em `snake_case`**, como no projeto recebido; os nomes de classe seguem o original (`GerenciadorEstado`, `JanelaBase`, …).
- **Interface em código.** Só a raiz de cada `.tscn` é guardada; o `Theme` é criado em `TemaNexus`. Menos arquivos para versionar e nenhuma dependência de recursos binários.
- **Segurança por construção.** As regras do prompt viraram verificações do validador (APIs proibidas, rede, gravação em `res://`, remoção), para que uma alteração futura que as quebre seja pega antes de rodar.
