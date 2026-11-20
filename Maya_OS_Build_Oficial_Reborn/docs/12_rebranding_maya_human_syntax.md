# 19. Rebranding para Maya Human Syntax (relatório §17, 2026-11-13)

> Relatório do pedido "Rebranding do projeto para Maya Human Syntax". Segue a ordem obrigatória do §17: diagnóstico, alterações aplicadas, identificadores preservados, comandos e URLs alterados, auditoria de strings, validação, pendências e veredito. Duas seções curtas foram acrescentadas porque o pedido pede as duas coisas por outros caminhos: as regras de nomenclatura (seção 2) e a compatibilidade com saves (seção 6). A tabela completa de ocorrências (antes, linha a linha e depois) é gerada por `tools/auditar_marca.py` em [`13_auditoria_de_marca.md`](13_auditoria_de_marca.md). Este documento e o 13 falam do nome antigo por definição, por isso a própria auditoria não os conta.

> **Atualização posterior (2026-11-13).** Depois que este relatório foi escrito, a ponte com o computador do projeto voltou e as suítes que a tabela da seção 8 e o veredito da seção 10 dão como **NÃO VERIFICÁVEL** foram executadas no editor da Godot 4.7.2 (Windows), com o código do rebranding mais o fluxo de sessão (Menu Principal, Pausa e Fim de Jogo): fumaça 304/0 sem interface e 341/0 com `-- --ui`; `tests/ui_interacao` 544/0; `tests/resolucoes` 119/0; `tests/persistencia` 119/0 (inclui o salvamento da versão 1 e a migração de marca); varredura do editor 62 cenas, 0 avisos; e o novo `tests/fluxo_sessao` 186/0. A auditoria de marca foi reexecutada e `13_auditoria_de_marca.md` regenerado: continua com **0 texto visível, 0 não resolvida e 0 problema de grafia**; o total passou de 547 para 568 ocorrências (as 21 a mais são identificadores preservados nos arquivos novos do fluxo de sessão, como `TemaNexus` e as ações `nexus_*`, mais documentação nova), e os números da seção "Auditoria" do resumo abaixo são os da época. Números, arquivos e logs em [`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md) (seções 9 e 11) e em `tests/_saida/`. **Continuam sem verificação:** o roteiro manual R1–R6, uma campanha manual completa (5 dias × 4 finais, com cliques reais), a instalação limpa e o salvamento antigo reais na máquina do jogador (a pasta limpa e o salvamento da versão 1 foram simulados pelos testes) e o jogo exportado. O restante deste documento é o relatório original, mantido como foi escrito (por isso ainda fala em "não verificável"). Os números mais recentes, depois da Splash Screen, estão em [`15_splash_screen.md`](15_splash_screen.md) (seção 9).

## Resumo

- **Nomes.** O jogo é **Maya Human Syntax**. A IA, que era a NEXUS, é a **Maya** ("a Maya"; **MAYA** só em etiquetas e cabeçalhos em caixa alta). O sistema simulado, que era o NEXUS OS, é o **HumaxOS** (sempre com essa grafia e no masculino: "o HumaxOS").
- **O que o jogador vê.** Boot, barra de tarefas, Menu Iniciar, widget, avisos, papel de parede, os 12 aplicativos, as conversas, os e-mails, a agenda, os 5 dias, os 4 finais, as páginas da rede interna, os arquivos e processos simulados, o terminal e o navegador usam a identidade nova. 213 linhas do jogo e 74 linhas de teste foram trocadas; nos dados JSON mudaram 124 valores e 7 chaves de página, e nenhuma estrutura.
- **O que não mudou.** Nenhum arquivo, pasta, classe, nó, ID, flag, sinal, ação do InputMap nem a pasta `user://nexus_os/` foi renomeado (seção 4).
- **Comandos e URLs.** `scan_nexus` virou `scan_maya`, `destroy_nexus` virou `destroy_maya` e `nexus://` virou `humax://`, cada um com parser, help, Tab, dicas, dados e testes atualizados juntos. Não há aliases: os nomes antigos caem em "comando não encontrado" e em "Endereço bloqueado" (seção 5).
- **Saves.** A pasta dos salvamentos foi fixada no `project.godot` para não mudar com o nome do projeto. O formato passou da versão 1 para a 2 (mesma estrutura); ao carregar um salvamento da versão 1, os textos antigos são migrados e os caminhos antigos do log de arquivos virtuais são traduzidos (seção 6).
- **Auditoria.** 841 ocorrências da marca antiga antes, 547 depois; todas as que sobram são identificadores preservados, compatibilidade deliberada, testes, ferramentas, documentos de histórico ou o protótipo em C. **Texto visível: 269 → 0. Não resolvidas: 0.**
- **Validação.** Validador do projeto, auditoria de marca, leitura dos JSON, comparação dos dados e checagem estática dos scripts passaram. **Os testes que precisam da Godot (fumaça, interface, resoluções, persistência, instalação limpa, save antigo, quatro finais, interface manual) não puderam rodar nesta rodada** e estão marcados como não verificáveis (seção 8).
- **Veredito.** **APROVADO COM RESSALVAS** (seção 10).

## 1. Diagnóstico

### 1.1 Estrutura encontrada e versão da Godot

- Projeto Godot **4.7** (`config/features` = `4.7`, renderer Forward Plus), GDScript 2.0 com tipagem estática. O editor usado nas rodadas anteriores é a 4.7.2. Nesta rodada não havia Godot no ambiente de trabalho e a ponte com o computador do projeto falhou (erro 503), então nada foi executado no motor.
- Pasta `Nexus_OS_Build_Oficial_organizado`: 82 scripts, 62 cenas `.tscn`, 9 autoloads e 65 classes (contagem do validador), 12 aplicativos, dados narrativos em `core/data/**` (JSON), interface em cenas editáveis (`features/**/scenes` e `shared/ui/**`), testes em `tests/`, ferramentas Python em `tools/` e um protótipo em C em `backend/` que não faz parte do jogo.

### 1.2 Arquivos analisados

- 233 arquivos de texto (`.gd`, `.tscn`, `.tres`, `.json`, `.cfg`, `.svg`, `.import`, `.godot`, `.py`, `.md`, `.c`, `.h`). Ficaram de fora a pasta `.godot/` (cache do editor), os logs de rodadas anteriores em `tests/_saida/` e os binários (imagens e áudio). Nomes de arquivos e pastas também foram conferidos.
- Ocorrências de `nexus`, `NEXUS`, `Nexus`, `NEXUS OS` e do apelido `Nex` **antes**: 841, em 84 arquivos (jogo 397, testes 133, ferramentas 25, documentos 250, protótipo em C 36).

### 1.3 Sistemas afetados

| Sistema | O que continha a marca | Observação |
|---|---|---|
| Shell: boot, barra de tarefas, Menu Iniciar, widget, avisos, papel de parede | títulos, botões, prefixo da fala da IA, etiqueta do aviso, marca-d'água | textos em `.tscn` e `.gd` |
| Mensageiro | nome do contato, falas, tooltips | o ID do contato e os IDs das mensagens continuam |
| E-mail e Calendário | remetentes (`@nexus.os`), compromissos | dados JSON |
| Navegador | esquema `nexus://`, 7 páginas, placeholder e rodapé | interativo: parser, dados, dicas e testes citavam o mesmo nome |
| Terminal | comandos `scan_nexus` e `destroy_nexus`, banner, prompt, help, Tab | interativo |
| Explorador e arquivos virtuais | pasta `/sistema/nexus`, `core.nexus`, `NEXUSCore.exe`, `nexus_audit.log`, zip com `.nexus` | caminhos visíveis que também entram no log de operações dos saves |
| Monitor do Sistema | `nexus_*.exe` (12 aplicativos, processos do sistema e processos suspeitos) | nomes visíveis; o processo suspeito é gravado nos saves |
| Configurações e tela final | descrições, rótulos e textos dos finais | |
| Persistência | o nome do projeto determina a pasta de `user://`; os saves guardam textos de jogo | risco de perder saves |
| Testes, ferramentas e documentos | expectativas de texto e prosa | |

### 1.4 Divergências encontradas

1. O nome do projeto (`config/name`) define a pasta de `user://`. Mudar só o nome faria o jogo "perder" os salvamentos e as preferências.
2. Comandos e URLs com a marca (`scan_nexus`, `destroy_nexus`, `nexus://`) são interativos: o parser, o help, o Tab, as dicas dos objetivos, as páginas internas, o arquivo de protocolo do Dia 5 e os testes citavam os mesmos nomes.
3. Nomes de processos, arquivos e pastas simulados aparecem para o jogador e também ficam nos saves (log do sistema de arquivos virtual e processo suspeito).
4. Os salvamentos guardam texto de jogo (conversas e ações pendentes) com a marca antiga.
5. O apelido "Nex" (mensagem editada da mãe: "você, Nex.") e o rótulo "NEXUS AI" das respostas automáticas.
6. A extensão `.nexus` dos arquivos do núcleo.
7. O protótipo em C (`backend/`) e os logs de `tests/_saida/` citam a marca antiga, mas não fazem parte do jogo.
8. A pasta e o zip do projeto se chamam `Nexus_OS_Build_Oficial_organizado`: é o nome do pacote, não do jogo.

## 2. Regras de nomenclatura adotadas

| Marca | Forma | Quando | Exemplos |
|---|---|---|---|
| **Maya Human Syntax** | nome do jogo | `config/name`, README, documentos | título da janela do jogo |
| **Maya** | a IA; feminina ("a Maya", "da Maya", "à Maya") | prosa, nome do contato, rótulos, prefixos | "Falar com a Maya", "Maya: …", "Maya Admin <admin@humax.os>" |
| **MAYA** | só caixa alta de etiquetas, cabeçalhos e rótulos técnicos | etiqueta do aviso da IA, rótulo da saudação, BIOS, rótulos de resposta automática | `MAYA`, `MAYA SYSTEMS BIOS v1.0`, `MAYA Corp.`, `MAYA AI`, `MAYA CORE`, `NÚCLEO MAYA` |
| **HumaxOS** | o sistema; masculino ("o HumaxOS", "no HumaxOS"); grafia exata | barra de tarefas, boot, terminal, configurações, marca-d'água | `◆  HumaxOS`, `HumaxOS Terminal 1.0`, `HumaxOS 1.0 pronto.` |
| `maya_*` | tokens técnicos ligados à IA | processos, pastas e arquivos do núcleo | `maya_override_daemon.exe`, `maya_telemetry.exe`, `/sistema/maya`, `core.maya`, `diretrizes.maya`, `maya_audit.log`, `MayaCore.exe`, `scan_maya`, `destroy_maya` |
| `humax_*` | tokens técnicos ligados ao sistema | processos dos aplicativos e do sistema, rede interna, e-mail, nome do computador | `humax_explorer.exe`, `humax_core.exe`, `humax://home`, `admin@humax.os`, `<nome>@humax` |

"MAYA SYSTEMS BIOS v1.0" e "MAYA Corp." já eram assim antes do rebranding e foram mantidos. `tools/auditar_marca.py` confere automaticamente a grafia de HumaxOS (nunca "Humax OS", "HUMAX OS" nem "Humaxos"), o gênero dos artigos e o uso de Maya/MAYA nos textos do jogo; o resultado é "nenhum problema".

## 3. Alterações aplicadas

### 3.1 Por área

- **Configuração.** `project.godot`: `config/name="Maya Human Syntax"` e pasta de dados fixada (seção 6).
- **Shell.** Boot (título do registro "HumaxOS", rótulo da saudação "MAYA", fim do log "HumaxOS 1.0 pronto…", saudação "Eu sou a Maya…"), barra de tarefas ("◆  HumaxOS"), Menu Iniciar (prefixo "Maya: "), widget (título "Maya", "💬 Falar com a Maya", "Acesse ◆ HumaxOS → Encerrar dia"), etiqueta do aviso da IA ("MAYA"), título "Maya" nas notificações, marca-d'água "HumaxOS" no papel de parede.
- **Aplicativos.** Mensageiro (contato "Maya", balões, tooltips), E-mail (`@humax.os`), Calendário, Navegador (`humax://`), Terminal (comandos, help, banner e prompt), Monitor do Sistema (processos `humax_*` e `maya_*`), Explorador (pasta `/sistema/maya` e arquivos `.maya`), Configurações ("HumaxOS 1.0 — simulação").
- **Narrativa e dados.** Conversas, e-mails, calendário, objetivos e dicas dos 5 dias, 4 finais, 7 páginas da rede interna, catálogo de aplicativos, processos e árvore de arquivos virtuais.
- **Código novo de compatibilidade.** Migração dos textos de saves da versão 1 (`GerenciadorEstado`), versão do formato 2 (`SistemaPersistencia`), tradução de caminhos antigos do log de arquivos (`SistemaArquivosVirtual`) e extensão legada `.nexus` no `AbridorArquivos`.
- **Testes, ferramentas e documentos.** Seções 7 e 8 e a tabela abaixo.

### 3.2 Por arquivo

Cada linha mostra um exemplo do texto antigo e do novo, quantas linhas daquele arquivo foram trocadas e para que servem. O texto antigo → novo de **todas** as linhas está em [`13_auditoria_de_marca.md`](13_auditoria_de_marca.md) ("Alterações aplicadas (linha a linha)").

| Arquivo | Texto antigo → texto novo (amostra) | Linhas | Tipo | Motivo | Impacto funcional | Testes associados |
|---|---|---|---|---|---|---|
| `core/autoload/gerenciador_estado.gd` | (nada) → `SUBSTITUICOES_DE_MARCA`, `migrar_marca_antiga()`, `_migrar_textos()` (código novo) | 1 + 43 novas | Compatibilidade (código novo); comentário | converter os textos (chat, processo suspeito, ações pendentes) de salvamentos anteriores ao rebranding | só atua em salvamentos da versão 1; nunca toca em chaves, IDs, flags nem no nome do jogador | smoke `_testar_migracao_de_marca`; persistência `_testar_salvamento_antes_do_rebranding` |
| `core/autoload/gerenciador_janelas.gd` | `SistemaNotificacoes.notificar("NEXUS", "Esta…` → `SistemaNotificacoes.notificar("Maya", "Esta…` | 2 | Texto visível | título dos avisos em que a IA segura ou reorganiza a janela | nenhum | auditoria (`auditar_marca.py`) |
| `core/autoload/gerenciador_narrativa.gd` | `"scan_nexus":` e `"destroy_nexus":` → `"scan_maya":` e `"destroy_maya":` | 11 | Comando interativo; texto visível; comentário | parser dos comandos de emergência, mensagens do terminal e rótulos de fala passam a usar Maya, `scan_maya` e `destroy_maya` | os comandos novos substituem os antigos (sem alias); IDs, flags e finais não mudam | smoke `_testar_finais` (parser); ui_interacao `terminal_emergencia` |
| `core/autoload/sistema_arquivos_virtual.gd` | (nada) → `CAMINHOS_ANTIGOS`, `_operacao_atual()`, `_caminho_atual()` (código novo) | 0 + 29 novas | Compatibilidade (código novo) | traduzir os caminhos citados por salvamentos antigos ao reaplicar o log de operações do VFS | só atua no carregamento; operações novas passam intactas | smoke `_testar_migracao_de_marca`; persistência `_testar_salvamento_antes_do_rebranding` |
| `core/autoload/sistema_persistencia.gd` | `const VERSAO := 1` → `const VERSAO := 2` + migração em `_carregar_de` | 0 + 5 novas | Persistência (versão do formato) | `VERSAO` 1 → 2 separa os salvamentos já na marca nova; `_carregar_de` migra os da versão 1 | salvamentos da versão 1 carregam e são regravados como versão 2; versões acima de 2 continuam sendo preservadas como `.corrompido` | persistência `_testar_salvamento_antes_do_rebranding` |
| `core/data/catalogo_apps.json` | `…"processo": "nexus_explorer.exe",` → `…"processo": "humax_explorer.exe",` | 12 | Nome de processo interativo | o Monitor do Sistema lista o processo de cada app: `nexus_*.exe` → `humax_*.exe` | nenhum: IDs, nomes e ícones dos apps iguais | smoke `_testar_marca` (processos `humax_*`) |
| `core/data/narrativa/calendario.json` | `…(definida pela NEXUS)",` → `…(definida pela Maya)",` | 12 | Narrativa | textos da agenda que citavam a IA | nenhum | smoke `_testar_apps_simples` (Dia 4) |
| `core/data/narrativa/conversas.json` | `…"nome": "NEXUS",` → `…"nome": "Maya",` | 13 | Narrativa | nome do contato (`NEXUS` → `Maya`) e falas | o ID do contato (`nexus`), os IDs das mensagens e as flags não mudaram | smoke `_testar_marca`; ui_interacao `mensageiro` |
| `core/data/narrativa/dias.json` | `…": "A NEXUS quer ajudar."…` → `…": "A Maya quer ajudar."…` | 30 | Narrativa; comandos e URL nas dicas | objetivos, dicas, mensagens e ações dos 5 dias; as dicas citam `scan_maya` e `humax://news` | nenhum fluxo muda; as dicas apontam para os comandos novos | smoke `_testar_dados`, `_testar_finais`; ui_interacao `terminal_emergencia` |
| `core/data/narrativa/emails.json` | `…"de": "NEXUS Admin <admin@nexus.os>",` → `…"de": "Maya Admin <admin@humax.os>",` | 8 | Narrativa; endereço | domínio `@nexus.os` → `@humax.os` e textos | nenhum | smoke `_testar_marca` (varredura dos JSON) |
| `core/data/narrativa/finais.json` | `…Você interrompeu a NEXUS e restaurou o… …quem escreveu a NEXUS, e por…` → `…Você interrompeu a Maya e restaurou o… …quem escreveu a Maya, e por…` | 5 | Narrativa | textos dos 4 finais e nomes das provas | os 4 finais continuam com os mesmos IDs e condições | smoke `_testar_finais`; ui_interacao `tela_final` |
| `core/data/narrativa/paginas_web.json` | chaves `"nexus://home"` … `"nexus://root"` e links `[url=nexus://…]` → chaves `"humax://home"` … `"humax://root"` e links `[url=humax://…]` | 27 | URL; narrativa | 7 chaves `nexus://…` → `humax://…`, links e textos das páginas | as páginas só abrem pelo esquema novo (sem alias) | smoke `_testar_dados`, `_testar_marca`, `_testar_apps_simples`; ui_interacao `navegador` |
| `core/data/narrativa/processos.json` | `…"nome": "nexus_override_daemon.exe",` → `…"nome": "maya_override_daemon.exe",` | 6 | Nome de processo interativo | processos do sistema e processos suspeitos do Monitor do Sistema | nenhum: IDs e comportamento iguais | smoke `_testar_marca` (varredura dos JSON), `_testar_processo_malicioso` |
| `core/data/vfs_inicial.json` | `…:00:01] NEXUS OS v9.4.1…` → `…:00:01] HumaxOS v9.4.1…` | 18 | Nome de arquivo e pasta; narrativa | `/sistema/nexus` → `/sistema/maya`, `core.nexus` → `core.maya`, `NEXUSCore.exe` → `MayaCore.exe`, log, zip e textos | os salvamentos antigos que citam os caminhos antigos são traduzidos (`CAMINHOS_ANTIGOS`) | smoke `_testar_marca`, `_testar_migracao_de_marca`; persistência |
| `core/utilities/abridor_arquivos.gd` | extensão `nexus` → extensão `maya` (e `nexus` mantida como legado) | 2 + 2 novas | Texto visível (extensão); compatibilidade | arquivos `.maya` abrem no leitor de texto com o ícone de núcleo; `.nexus` continua aceito para arquivos de antes | nenhum para quem já tinha arquivos `.nexus` | sem asserção específica; roteiro manual (Explorador) |
| `features/apps/calendario/scripts/app_calendario.gd` | `…"reorganizados" pela NEXUS conforme a história…` → `…"reorganizados" pela Maya conforme a história…` | 2 | Texto visível; comentário | textos do app que citavam a IA | nenhum | smoke `_testar_apps_simples` (Dia 4); auditoria (`auditar_marca.py`) |
| `features/apps/calendario/scripts/cartao_compromisso.gd` | `…"alterado pela NEXUS",` → `…"alterado pela Maya",` | 3 | Texto visível; comentário | etiquetas dos compromissos alterados pela IA | nenhum | smoke `_testar_apps_simples` (Dia 4); auditoria (`auditar_marca.py`) |
| `features/apps/config/scenes/app_config.tscn` | `…balançar quando a NEXUS reage."` → `…balançar quando a Maya reage."` | 3 | Texto visível | descrições e tooltips que citavam a IA | nenhum | ui_interacao `config`; auditoria (`auditar_marca.py`) |
| `features/apps/config/scripts/app_config.gd` | `…ativa. A NEXUS não está monitorando…` → `…ativa. A Maya não está monitorando…` | 3 | Texto visível | painel de sessão: `HumaxOS 1.0 — simulação` e demais textos | nenhum | ui_interacao `config` |
| `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn` | `…antes de a NEXUS editar a mensagem…` → `…antes de a Maya editar a mensagem…` | 1 | Texto visível | tooltip da mensagem editada pela IA | nenhum | ui_interacao `mensageiro` |
| `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd` | `…💡 sugestão da NEXUS",` → `…💡 sugestão da Maya",` | 4 | Texto visível; comentário | rótulos de autor e de mensagem editada | nenhum | ui_interacao `mensageiro` |
| `features/apps/mensageiro/scenes/app_mensageiro.tscn` | `…= "A NEXUS bloqueou este contato…` → `…= "A Maya bloqueou este contato…` | 1 | Texto visível | aviso de contato bloqueado pela IA | nenhum | ui_interacao `mensageiro` |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | `…Contato bloqueado pela NEXUS" if bloqueado…` → `…Contato bloqueado pela Maya" if bloqueado…` | 4 | Texto visível; comentário | textos da conversa e da lista de contatos | nenhum (IDs de contato e de mensagem intactos) | ui_interacao `mensageiro` |
| `features/apps/mensageiro/scripts/item_contato.gd` | `…contato bloqueado pela NEXUS; ativo: conversa…` → `…contato bloqueado pela Maya; ativo: conversa…` | 1 | Texto visível | rótulo da IA na lista de contatos | nenhum | ui_interacao `mensageiro` |
| `features/apps/monitor_sistema/scripts/app_monitor_sistema.gd` | `…processo malicioso 'nexus_override_daemon.exe' tem…` → `…processo malicioso 'maya_override_daemon.exe' tem…` | 1 | Comentário | comentário que citava a IA | nenhum | auditoria (`auditar_marca.py`) |
| `features/apps/navegador/scenes/app_navegador.tscn` | `placeholder_text = "nexus://home"` → `placeholder_text = "humax://home"` | 2 | URL; texto visível | placeholder da barra de endereço e rodapé da rede interna | nenhum | ui_interacao `navegador` |
| `features/apps/navegador/scripts/app_navegador.gd` | `const ESQUEMA := "nexus://"` → `const ESQUEMA := "humax://"` | 7 | URL (esquema); texto visível | `ESQUEMA`, `PAGINA_INICIAL`, normalização do endereço digitado e página de bloqueio | `nexus://…` digitado agora cai na página de bloqueio (sem alias) | smoke `_testar_apps_simples`; ui_interacao `navegador` |
| `features/apps/terminal/scripts/app_terminal.gd` | `COMANDOS_ENTRADA := ["root_access", "scan_nexus"]` → `COMANDOS_ENTRADA := ["root_access", "scan_maya"]` | 14 | Comando interativo; texto visível | listas de comandos (autocompletar), help, confirmações, banner e prompt | `scan_nexus`/`destroy_nexus` deixam de existir (sem alias); os demais comandos não mudam | ui_interacao `terminal`, `terminal_emergencia` |
| `features/puzzles/evento_processo/scripts/tabela_processos.gd` | `…NOME_ISCA := "nexus_update_helper.exe"` → `…NOME_ISCA := "humax_update_helper.exe"` | 1 | Nome de processo interativo | `NOME_ISCA` acompanha o nome em `processos.json` | nenhum: continua sendo o processo-isca | smoke `_testar_processo_malicioso` |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | `….58), "NEXUS", HORIZONTAL_ALIGNMENT_CENTER,…` → `….58), "HumaxOS", HORIZONTAL_ALIGNMENT_CENTER,…` | 2 | Texto visível (marca-d'água); comentário | marca-d'água do papel de parede procedural | nenhum | ui_dump (visual); auditoria (`auditar_marca.py`) |
| `features/shell/barra_de_tarefas/scenes/barra_de_tarefas.tscn` | `…= "◆  NEXUS"` → `…= "◆  HumaxOS"` | 1 | Texto visível | botão Iniciar da barra de tarefas | nenhum | ui_interacao `marca` |
| `features/shell/janela_inicial/scripts/ajuda_dica.gd` | `…pelo widget da NEXUS.` → `…pelo widget da Maya.` | 1 | Comentário | comentário que citava a IA | nenhum | auditoria (`auditar_marca.py`) |
| `features/shell/janela_inicial/scripts/menu_iniciar.gd` | `….text = "NEXUS: " +…` → `….text = "Maya: " +…` | 1 | Texto visível | prefixo da fala da IA no cabeçalho do Menu Iniciar | nenhum | ui_interacao `marca` |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | `return "NEXUS"` → `return "MAYA"` | 1 | Texto visível (etiqueta) | etiqueta do nível `ia`; a chave `"ia"` continua | nenhum | ui_interacao `marca` |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | `text = "NEXUS OS"` → `text = "HumaxOS"` | 2 | Texto visível | título do registro e rótulo da saudação | nenhum | ui_interacao `tela_boot` |
| `features/shell/tela_boot/scripts/tela_boot.gd` | `"NEXUS OS 1.0 pronto…` → `"HumaxOS 1.0 pronto…` | 4 | Texto visível; comentário | log de boot e saudação da Maya (`MAYA SYSTEMS BIOS v1.0` e `MAYA Corp.` já eram assim e foram mantidos) | nenhum | ui_interacao `tela_boot` |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | `text = "NEXUS"` → `text = "Maya"` | 3 | Texto visível | título, botão e aviso de rotinas concluídas do widget | nenhum | ui_interacao `marca` |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | `…# Widget da NEXUS na área de…` → `…# Widget da Maya na área de…` | 2 | Texto visível; comentário | textos do widget | nenhum | ui_interacao `marca` |
| `project.godot` | `config/name="Nexus_OS_Build_Oficial"` → `config/name="Maya Human Syntax"` + pasta de dados fixada | 1 + 3 novas | Configuração; compatibilidade | o nome do projeto aparece na janela, no editor e no executável; como a pasta de `user://` deriva desse nome, ela foi fixada (`use_custom_user_dir`, com a sobrescrita `.linuxbsd`) | nenhum nos saves: a pasta continua a mesma | smoke `_testar_marca`; manual R5 |
| `shared/ui/orbe_nexus/scripts/orbe_nexus.gd` | `…Orbe animado da NEXUS. Reage ao…` → `…Orbe animado da Maya. Reage ao…` | 1 | Comentário | comentário que citava a IA | nenhum | auditoria (`auditar_marca.py`) |
| `tests/exportar_tema/exportar_tema.gd` | `…Theme base do Nexus (dia 1,…` → `…Theme base do HumaxOS (dia 1,…` | 1 | Comentário | prosa | nenhum | auditoria (`auditar_marca.py`) |
| `tests/persistencia/persistencia.gd` | a saudação da NEXUS → a saudação da Maya (+ função nova `_testar_salvamento_antes_do_rebranding`) | 1 + 55 novas | Teste (função nova) | salvamento da versão 1 carrega, é migrado e volta como versão 2 | nenhum no jogo | — |
| `tests/smoke_test.gd` | `…"negotiate", "destroy_nexus"]` → `…"negotiate", "destroy_maya"]` | 24 + 93 novas | Teste (expectativas atualizadas; funções novas) | atualizar os textos e comandos esperados e cobrir a marca e a migração | as asserções continuam as mesmas, só mudam os textos esperados; 2 funções novas | — |
| `tests/ui_dump/ui_dump.gd` | `…os estilos do Nexus.` → `…os estilos do HumaxOS.` | 2 | Comentário | prosa | nenhum | auditoria (`auditar_marca.py`) |
| `tests/ui_interacao/ui_interacao.gd` | `…"negotiate", "destroy_nexus"]` → `…"negotiate", "destroy_maya"]` | 45 + 40 novas | Teste (expectativas atualizadas; grupo novo) | textos esperados com a marca nova e o grupo `marca` | as asserções continuam as mesmas, só mudam os textos esperados | — |
| `tools/comparar_rodadas.py` | `…e o brilho do NEXUS mudam sozinhos entre…` → `…e o brilho da Maya mudam sozinhos entre…` | 1 | Ferramenta (prosa) | descrição | nenhum | auditoria (`auditar_marca.py`) |
| `tools/gerar_audio.py` | `…áudio autoral do Nexus OS: 9 efeitos…` → `…áudio autoral do HumaxOS: 9 efeitos…` | 1 | Ferramenta (prosa) | descrição | nenhum | auditoria (`auditar_marca.py`) |
| `tools/gerar_docs_ui.py` | `…Conversas com a NEXUS e os contatos…` → `…Conversas com a Maya e os contatos…` | 3 + 1 novas | Ferramenta (prosa e texto gerado) | frases geradas em docs/04 e docs/10 e nota de rebranding | nenhum no jogo | regenerado e conferido |
| `tools/gerar_icones.py` | `…dos aplicativos do Nexus OS (SVG, 128x128…` → `…dos aplicativos do HumaxOS (SVG, 128x128…` | 1 | Ferramenta (prosa) | descrição | nenhum | auditoria (`auditar_marca.py`) |
| `tools/gerar_imagens.py` | `…imagens autorais do Nexus OS: papéis de…` → `…imagens autorais do HumaxOS: papéis de…` | 2 | Ferramenta (prosa) | descrição | nenhum | auditoria (`auditar_marca.py`) |
| `tools/gerar_indice_codigo.py` | `…e como a NEXUS os altera/oculta…` → `…e como a Maya os altera/oculta…` | 2 | Ferramenta (prosa) | descrição | nenhum | auditoria (`auditar_marca.py`) |
| `tools/validar_projeto.py` | `…) do projeto Nexus OS. Não substitui…` → `…) do projeto HumaxOS (Maya Human Syntax). Não substitui…` | 1 | Ferramenta (prosa) | descrição | nenhum | auditoria (`auditar_marca.py`) |
| `README.md`, `docs/01` a `docs/11` (12 arquivos) | prosa, exemplos e tabelas com a marca antiga → marca nova | 80 + 52 novas | Documentação | os documentos descrevem o jogo que o jogador vê; os de etapas anteriores ganharam uma nota de nomes e mantêm o histórico | nenhum | `auditar_marca.py` (documentos vivos sem texto visível antigo) |
| `tools/auditar_marca.py` (novo), `docs/12_…` e `docs/13_…` (novos) | — | — | Ferramenta e documentação | classificar toda ocorrência da marca antiga e provar que não sobra texto visível | nenhum no jogo | o próprio `auditar_marca.py` (código de saída 1 se houver pendência) |

## 4. Identificadores preservados

Regra seguida: só o que o jogador lê foi renomeado. Tudo o que é nome de arquivo, caminho de recurso, classe, nó, ID, chave, flag, sinal, ação de entrada ou pasta de dados foi mantido, porque renomear essas coisas quebra referências (`res://`, `uid://`, `class_name`, `%Nome`), os testes, os salvamentos e os atalhos que o jogador personalizou, e o jogador não os vê.

| Grupo | Exemplos mantidos | Por que foram preservados |
|---|---|---|
| Arquivos e pastas | `features/shell/widget_nexus/` (`widget_nexus.tscn`, `widget_nexus.gd` e o `.uid`), `shared/ui/orbe_nexus/`, `shared/ui/dialogo_nexus/`, `core/utilities/tema_nexus.gd`, `shared/theme/tema_nexus_base.tres` | os caminhos `res://` e os `uid://` estão referenciados por cenas, scripts, testes e pelo validador |
| Classes | `TemaNexus`, `OrbeNexus`, `DialogoNexus`, `WidgetNexus` | `class_name` usado como tipo em muitos scripts |
| Nós e nomes únicos | `WidgetNexus`, `%WidgetNexus`, `RotuloNexus` (saudação do boot), `OrbeNexus` | `@onready var x: T = %Nome` e `find_child` dos testes dependem do nome |
| Estado | `ia_estado` | variável de estado gravada nos saves |
| IDs e chaves de dados | contato `nexus`, mensagens `d1_nexus_01` etc., chave de conversa `nexus`, flags como `conversa_lida:nexus`, nível de notificação `"ia"` | os saves e a narrativa se referem a eles; mudar um ID repetiria ou perderia mensagens |
| Ações do InputMap | `nexus_menu_iniciar`, `nexus_tela_cheia`, `nexus_painel_debug`, `nexus_proxima_janela`, `nexus_fechar_janela`, `nexus_minimizar_janela`, `nexus_abrir_terminal`, `nexus_forcar_desativar` | gravadas em `project.godot` e nas preferências; renomear faria o jogador perder os atalhos que personalizou |
| Persistência | `user://nexus_os/`, `salvamento.json`, `checkpoint_dia_N.json`, `configuracoes.cfg`, `user://nexus_os_teste/` (testes) | os saves e as preferências que já existem estão aí |
| Pasta do usuário | `custom_user_dir_name` com `Nexus_OS_Build_Oficial` | mantém a pasta onde os saves antigos estão (seção 6) |
| Tema do projeto | `theme/custom="res://shared/theme/tema_nexus_base.tres"` | caminho de recurso |
| Protótipo e logs | `backend/**`, `tests/_saida/**` | fora do escopo (seção 10) |
| Pacote | pasta e zip `Nexus_OS_Build_Oficial_organizado` | nome do pacote, não do jogo; renomear fica a critério de quem distribui |

## 5. Comandos, URLs e nomes técnicos alterados

| Nome antigo → novo | Parser | help | Autocompletar (Tab) | Pistas e dados | Testes | Saves | Alias |
|---|---|---|---|---|---|---|---|
| `scan_nexus` → `scan_maya` | `match` do comando de emergência em `GerenciadorNarrativa` | linha do help em `app_terminal.gd` ("requer autenticação" antes do root) | `COMANDOS_ENTRADA` e `COMANDOS_EMERGENCIA` | objetivo e dica do Dia 5 (`dias.json`), protocolo em `registro_icarus.txt` (`vfs_inicial.json`), página `humax://support`, mensagem de provas insuficientes, final "Núcleo da Maya analisado (scan_maya)" | smoke `_testar_finais` (parser) e `_testar_dados`, ui_interacao `terminal` e `terminal_emergencia` | textos de ações pendentes de saves antigos são migrados | **nenhum**: `scan_nexus` responde "comando não encontrado" (teste em `terminal`) |
| `destroy_nexus` → `destroy_maya` | `match` do comando de emergência | linha do help, só depois do root | só depois do `root_access` | texto da purga | smoke `_testar_finais` (pede confirmação), ui_interacao `terminal_emergencia` (continua oculto antes do root) | idem | **nenhum** |
| `nexus://…` → `humax://…` (7 páginas) | `AppNavegador.ESQUEMA`, `PAGINA_INICIAL` e `normalizar_url` | placeholder da barra de endereço e rodapé da rede interna | — (não há Tab no navegador) | chaves e links de `paginas_web.json`, objetivo e dica do Dia 2 (`humax://news`), links da página inicial | smoke `_testar_dados`, `_testar_marca` e `_testar_apps_simples` (7 páginas e normalização), ui_interacao `navegador` | textos de ações pendentes migrados; a flag `visitou_pagina_interna` não mudou | **nenhum**: `nexus://home` mostra "Endereço bloqueado" (testes em smoke e `navegador`) |
| `nexus_*.exe` → `humax_*.exe` (12 aplicativos e `core`, `render`, `update_helper`) e `nexus_telemetry.exe` / `nexus_override_daemon.exe` → `maya_telemetry.exe` / `maya_override_daemon.exe` | — (o `kill` do terminal usa o PID, não o nome) | `ps` lista os nomes novos | — | `catalogo_apps.json`, `processos.json`, `NOME_ISCA` em `tabela_processos.gd`, dicas dos Dias 4 e 5 e mensagem do terminal | smoke `_testar_marca` (`humax_*` no catálogo) e `_testar_processo_malicioso` (processo-isca) | o nome do processo suspeito gravado no save é migrado | **nenhum** |
| `/sistema/nexus`, `core.nexus`, `diretrizes.nexus`, `nexus_audit.log`, `NEXUSCore.exe`, `kill_switch.nexus` → `/sistema/maya`, `core.maya`, `diretrizes.maya`, `maya_audit.log`, `MayaCore.exe`, `kill_switch.maya` | `cd`, `ls`, `cat` e o Explorador usam o nome atual | — | Tab de arquivos usa o nome atual | `vfs_inicial.json`, ação `revelar` do Dia 5 | smoke `_testar_marca` e `_testar_migracao_de_marca`, persistência | log de operações de saves antigos: `CAMINHOS_ANTIGOS` traduz os caminhos | só para saves (um caminho digitado à mão não é traduzido) |
| `@nexus.os` → `@humax.os`; prompt `<nome>@nexus:…$` → `<nome>@humax:…$` | — | — | — | `emails.json`, prompt do terminal | smoke `_testar_marca` (varredura dos JSON), ui_interacao `terminal` (prompt) | — | **nenhum** |
| extensão `.nexus` → `.maya` | `AbridorArquivos` abre `.maya` como texto | — | — | arquivos do núcleo | sem asserção específica; roteiro manual | arquivos antigos continuam abrindo: `.nexus` segue aceito (linha marcada `# marca-legada`) | sim, deliberado e só para leitura |

Comandos que não citavam a marca e portanto não mudaram: `root_access`, `reset_core`, `restore_control`, `negotiate`, `help`, `ls`, `cd`, `cat`, `ps`, `kill` e os demais.

## 6. Compatibilidade com saves

### 6.1 Pasta de dados

`user://` vem do nome do projeto. Para o nome novo não "esconder" os saves, `project.godot` fixa a pasta que sempre foi usada:

```ini
config/name="Maya Human Syntax"
config/use_custom_user_dir=true
config/custom_user_dir_name="Godot/app_userdata/Nexus_OS_Build_Oficial"
config/custom_user_dir_name.linuxbsd="godot/app_userdata/Nexus_OS_Build_Oficial"
```

No Windows e no macOS o caminho resultante é idêntico ao de antes (`%APPDATA%\Godot\app_userdata\Nexus_OS_Build_Oficial\` e `~/Library/Application Support/Godot/app_userdata/Nexus_OS_Build_Oficial/`). No Linux a Godot usa `godot` em minúsculas por padrão, e a sobrescrita `.linuxbsd` mantém essa grafia. A pasta `nexus_os/` e os nomes dos arquivos dentro dela não mudaram.

### 6.2 Versão do formato: 1 → 2

- `SistemaPersistencia.VERSAO` passou de 1 para 2. **O formato é o mesmo** (`versao`, `salvo_em`, `estado`, `vfs`); a versão só separa os salvamentos que já nasceram com a marca nova dos que ainda trazem a antiga.
- `_carregar_de()` (usado por `carregar()` e por `carregar_checkpoint()`) migra o estado quando `versao < 2` e depois segue o caminho normal. Salvamentos da versão 2 não passam pela migração. Versões acima de 2 continuam sendo recusadas e preservadas como `.corrompido` (nada é apagado).
- `GerenciadorEstado.migrar_marca_antiga()` devolve uma cópia e troca **só valores de texto** dos campos `chat`, `processos_maliciosos` e `acoes_pendentes`, na ordem `NEXUS AI` → `MAYA AI`, `NEXUS OS` → `HumaxOS`, `NEXUS` → `Maya`, `você, Nex.` → `você, Maya.`, `nexus_override_daemon.exe` → `maya_override_daemon.exe`, `scan_nexus` → `scan_maya`, `destroy_nexus` → `destroy_maya`, `nexus://` → `humax://`.
- **Nunca** são tocados: chaves de dicionário, IDs de mensagem e de contato, o campo `autor`, as flags, o nome do jogador e o resto do estado. Migrar duas vezes dá o mesmo resultado.
- Efeito colateral aceito: uma mensagem que o próprio jogador digitou com a palavra "NEXUS" também vira "Maya" ao migrar.

### 6.3 Arquivos virtuais

O log de operações do VFS (`criar`, `texto`, `mover`, `decifrar`, `revelar`) cita caminhos. `SistemaArquivosVirtual.CAMINHOS_ANTIGOS` mapeia os 6 caminhos antigos para os novos e `desserializar()` traduz os campos `c`, `de`, `para`, `origem_lixeira` e `no.caminho` de cada operação ao reaplicá-lo. Operações novas passam intactas. Os arquivos extraídos de um zip são gerados a partir dos dados atuais, então já saem com os nomes novos.

### 6.4 Preferências e downgrade

- `configuracoes.cfg` guarda só preferências e atalhos (sem texto de marca): não precisa de migração.
- Um salvamento da versão 2 **não** abre numa build anterior ao rebranding (que só conhece a versão 1); ela o preserva como `.corrompido`. Voltar atrás exige restaurar uma cópia do salvamento antigo, e por isso o roteiro manual R4 manda copiar a pasta `nexus_os/` antes de testar.

## 7. Auditoria de strings

`python3 -I tools/auditar_marca.py` procura `nexus`, `NEXUS`, `Nexus`, `NEXUS OS` e `Nex` em todo o projeto, classifica cada ocorrência por token (um mesmo literal pode ter ocorrências de classes diferentes) e termina com código 1 se sobrar texto visível ou ocorrência não classificada. As classes são as do pedido:

| Classe | Antes | Depois |
|---|---|---|
| Texto visível | 269 | 0 |
| Não resolvida | 0 | 0 |
| Interna | 206 | 181 |
| Compatibilidade | 0 | 18 |
| Persistência | 4 | 4 |
| Teste | 51 | 105 |
| Ferramenta (fora do jogo) | 25 | 14 |
| Documentação (fora do jogo) | 250 | 189 |
| Protótipo C (fora do jogo) | 36 | 36 |
| **Total** | **841** | **547** |

O que sobra no jogo (**181 internas, 18 de compatibilidade, 4 de persistência**):

- **Interna:** nomes de arquivos e caminhos de recurso, `class_name`, nós, `%WidgetNexus`, `ia_estado`, IDs e flags, as 8 ações `nexus_*` do InputMap e comentários que citam esses identificadores.
- **Compatibilidade:** a tabela de migração de saves, os caminhos antigos do VFS, a extensão `.nexus` legada e a pasta de dados fixada no `project.godot`. Toda linha de compatibilidade termina com o marcador `# marca-legada`.
- **Persistência:** `user://nexus_os` e `user://nexus_os/configuracoes.cfg`.

Fora do jogo: **105 em testes** (fixtures de salvamentos antigos, verificações de que a marca antiga não aparece e os identificadores preservados), **14 em ferramentas** (identificadores citados), **189 em documentos** (identificadores, caminhos, o nome do zip, a pasta fixada e o histórico das etapas anteriores) e **36 no protótipo em C**. As ocorrências de documentos que **não** são identificadores estão em citações deliberadas de nomes antigos (o roteiro R2, a seção de saves em `docs/07` e as notas de nomes dos documentos 01, 02 e 11).

**Texto visível: 0. Não resolvida: 0.** Nenhuma ocorrência ficou sem classe: o resumo de [`13_auditoria_de_marca.md`](13_auditoria_de_marca.md) soma exatamente as ocorrências encontradas.

## 8. Validação

| Verificação | Resultado | Evidência |
|---|---|---|
| `python3 -I tools/validar_projeto.py` | **0 erros, 0 avisos** (82 scripts, 62 cenas, 9 autoloads, 65 classes) | rodado na pasta final e numa cópia extraída do zip |
| `python3 -I tools/auditar_marca.py` | **0 pendências, 0 problemas de uso das marcas novas**, código de saída 0. Controle: na cópia anterior ao rebranding a mesma ferramenta acusa 269 pendências e sai com código 1 | idem |
| Dados JSON (9 arquivos) | todos leem; a estrutura é idêntica à anterior (124 valores e 7 chaves de página mudaram, 0 mudanças estruturais) | comparação campo a campo com a cópia anterior ao rebranding |
| Checagem estática dos 28 scripts alterados | 0 problemas novos (parênteses, colchetes, chaves e aspas balanceados; só tabs; sem CRLF) | script de apoio, fora do projeto |
| Pistas e referências cruzadas | os 36 tokens técnicos com a marca nova que aparecem nos textos, dados e código (comandos, URLs, caminhos, processos, arquivos) resolvem para algo que existe; as únicas exceções esperadas são o domínio `humax.os`, o valor de metadado `maya_core` e o link decorativo `humax://social/curtir`, que já não tinha página antes | script de apoio que cruza os textos com `vfs_inicial.json`, `catalogo_apps.json`, `processos.json`, `paginas_web.json` e a lista de comandos do terminal |
| Assets (PNG, SVG, áudio) | nenhum traz a marca antiga: varredura de bytes por `nexus` sem achados, SVG sem `<text>` e um papel de parede conferido visualmente (sem texto) | `shared/assets/**` |
| Índice de código e documentos de UI | regenerados (`gerar_indice_codigo.py`: 74 scripts; `gerar_docs_ui.py`) | `docs/04`, `docs/06`, `docs/10` |
| `godot --headless --path . res://tests/smoke_test.tscn -- --ui` | **NÃO VERIFICÁVEL nesta rodada** | sem Godot no ambiente; ponte com o computador do projeto indisponível (503) |
| Testes de interface (`tests/ui_interacao`) | **NÃO VERIFICÁVEL** | idem |
| Testes de resolução (`tests/resolucoes`) | **NÃO VERIFICÁVEL** | idem |
| Testes de persistência (`tests/persistencia`) | **NÃO VERIFICÁVEL** | idem (inclui o salvamento da versão 1) |
| Varredura de avisos do editor (`tests/avisos_editor`) | **NÃO VERIFICÁVEL** | idem |
| Instalação limpa | **NÃO VERIFICÁVEL** | idem |
| Save antigo | **NÃO VERIFICÁVEL no motor**; lógica e testes escritos e revisados | `_testar_salvamento_antes_do_rebranding`, `_testar_migracao_de_marca` |
| Save novo | **NÃO VERIFICÁVEL** | coberto pelo teste de persistência |
| Quatro finais | **NÃO VERIFICÁVEL**; os dados dos 4 finais mudaram só em texto (IDs e condições iguais) | smoke `_testar_finais` |
| Teste manual da interface | **NÃO VERIFICÁVEL** | roteiro R1–R6 em `docs/08_testes_manuais.md` |

Para fechar a validação na máquina do projeto (Godot 4.7.2), a partir da pasta do projeto:

```
python3 -I tools/validar_projeto.py
python3 -I tools/auditar_marca.py
godot --headless --path . res://tests/smoke_test.tscn -- --ui
godot --headless --path . res://tests/ui_interacao/ui_interacao.tscn
godot --headless --path . res://tests/resolucoes/resolucoes.tscn
godot --headless --path . res://tests/persistencia/persistencia.tscn
godot --headless --path . res://tests/avisos_editor/avisos_editor.tscn
```

(ou abrir cada cena no editor e apertar F6, como nas rodadas anteriores). A rodada anterior, antes do rebranding, fechou assim no motor: validador 0/0, fumaça 258/0 (295/0 com `-- --ui`), interface 532, resoluções 70, persistência 73, varredura do editor 55/0. Com os testes novos os totais sobem; o que importa é **nenhuma falha**.

### 8.1 Testes atualizados e acrescentados

- **Atualizados, sem enfraquecer nenhuma asserção:** só mudaram os textos, comandos e URLs esperados (`smoke_test.gd`, `ui_interacao.gd`, `persistencia.gd`), por exemplo `"nexus://home"` → `"humax://home"`, `"◆  NEXUS"` → `"◆  HumaxOS"` e `destroy_nexus` → `destroy_maya`. Nenhum teste, validação ou fallback foi removido.
- **Novos no teste de fumaça (`_testar_marca`, `_testar_migracao_de_marca`):** nome do projeto; pasta de `user://` fixada; nenhum JSON nem cena do jogo com a marca antiga; contato da IA "Maya" com ID `nexus`; todas as páginas em `humax://`; processos `humax_*`; o esquema antigo não abre página; migração dos textos (cópia sem alterar o original, IDs/flags/nome do jogador intactos, migrar de novo não muda nada); tradução do caminho `/sistema/nexus` ao reaplicar um log antigo.
- **Novo no teste de persistência (`_testar_salvamento_antes_do_rebranding`):** um salvamento da versão 1 carrega, mantém nome/dia/flags/IDs, troca os textos, renomeia o processo suspeito, traduz o log do VFS, é regravado como versão 2 sem a marca antiga; um salvamento da versão 2 não é reescrito; um checkpoint da versão 1 também é migrado.
- **No teste de interface:** grupo novo `marca` (barra de tarefas, widget, Menu Iniciar aberto e fechado, etiqueta `MAYA`, contato "Maya") e asserções de marca nos grupos `tela_boot`, `navegador`, `config` e `terminal` (título e rótulo do boot, placeholder e rodapé do navegador, painel de sessão, banner e prompt do terminal), além do comando `scan_nexus` sem alias e do endereço `nexus://home` bloqueado.

## 9. Pendências

| Categoria do pedido | Item |
|---|---|
| Não pôde ser alterado | `backend/` (protótipo em C, só é alcançado pela ponte opcional `usar_backend_json`, desligada por padrão e sem opção nas Configurações) cita a marca antiga em `dialogues.json`, `mock_estado_jogo.json` e no código C; `tests/_saida/**` são logs de rodadas anteriores e ficam como evidência (há uma nota em `tests/_saida/LEIA-ME.md`); a pasta e o zip `Nexus_OS_Build_Oficial_organizado` |
| Exige migração futura | renomear arquivos, classes, nós, ações do InputMap ou a pasta `user://nexus_os/` precisa de plano próprio (UIDs, `class_name`, remapeamento de atalhos, migração de pasta). A migração de textos da versão 1 pode ser removida quando não existirem mais saves dessa versão |
| Depende do editor Godot | ao abrir o projeto, o editor reescreve `project.godot` (descarta os comentários e reordena chaves) e atualiza caches; `export_presets.cfg` só existe na máquina do projeto e pode manter o nome do aplicativo, o ícone ou a descrição antigos: conferir ao exportar; todos os testes da seção 8 |
| Depende de asset ausente | nenhum asset novo foi necessário: os assets não trazem a marca antiga (seção 8). Só uma conferência visual de todas as imagens, que fica para quem abrir o jogo |
| Risco de compatibilidade | a pasta de dados no Linux depende da sobrescrita `.linuxbsd` (não testada); um salvamento da versão 2 não abre em build anterior; quem decorou `scan_nexus` ou `nexus://` recebe erro; mensagens digitadas pelo jogador com "NEXUS" viram "Maya" ao migrar um save antigo |
| Precisa de decisão de design | aliases temporários para `scan_nexus` e `nexus://` (decidido que **não**, para a narrativa não citar um nome que o jogo abandonou); manter ou remover a extensão legada `.nexus` no `AbridorArquivos`; renomear os arquivos e classes internos num refatoramento futuro |
| Não pôde ser testado | tudo o que depende do motor (seção 8) |

## 10. Veredito

**APROVADO COM RESSALVAS.**

Evidências a favor:

- A identidade nova está completa e coerente na experiência visível: a auditoria foi de 841 para 547 ocorrências, com **0 texto visível, 0 não resolvida e 0 problema de grafia ou gênero** de HumaxOS e Maya (`auditar_marca.py`, código de saída 0).
- A arquitetura interna foi preservada: nenhum arquivo, pasta, classe, nó, ID, flag, ação do InputMap ou caminho de salvamento foi renomeado; os dados JSON mudaram só em valores (124) e em 7 chaves de página, sem estrutura nova.
- Comandos e URLs foram atualizados em conjunto (parser, help, Tab, dicas, dados e testes), e os nomes antigos têm comportamento definido e testado (sem alias).
- Os saves antigos têm caminho de migração desenhado, documentado e coberto por testes escritos (pasta fixada, versão 1 → 2, textos, caminhos do VFS, checkpoints), sem mudar o diretório nem apagar nada.
- O validador do projeto fecha em 0 erros e 0 avisos e os scripts alterados passam na checagem estática.

Por que não é "APROVADO" pleno: o pedido exige o teste de fumaça, os testes de interface, resolução e persistência e as verificações de instalação limpa, save antigo, save novo, quatro finais e interface manual, e **nada disso pôde rodar nesta rodada** (sem Godot no ambiente e com a ponte do computador do projeto fora do ar). As mudanças de comportamento são pequenas e localizadas (texto, valores de dados e três blocos novos de código de compatibilidade), mas só o motor confirma que as cenas carregam, os autoloads iniciam, a migração roda e os quatro finais continuam acessíveis.

Próximo passo recomendado: rodar os comandos da seção 8 na máquina do projeto e os roteiros R1–R6 de `docs/08_testes_manuais.md`, nessa ordem; se algum teste falhar, o relatório do teste aponta o arquivo e a linha, e quase certamente é uma expectativa de texto a ajustar.
