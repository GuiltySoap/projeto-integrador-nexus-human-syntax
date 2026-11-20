# 20. Auditoria de marca (rebranding Maya Human Syntax)

> Documento gerado por `tools/auditar_marca.py` (não edite à mão). A tabela **Antes** vem da cópia do projeto anterior ao rebranding e a tabela **Depois** do projeto atual. Cada linha é uma ocorrência de `nexus`, `NEXUS`, `Nexus`, `NEXUS OS` ou do apelido `Nex`. Para reproduzir: `python3 -I tools/auditar_marca.py --escrever docs/13_auditoria_de_marca.md --base <pasta anterior>`.

## Resumo pelas classes do pedido

Cada ocorrência cai numa classe só. **Texto visível** e **Não resolvida** são as pendências: devem ser **0** depois das mudanças. **Interna** reúne classes, nós, caminhos de recurso, IDs, flags, ações do InputMap e comentários que citam esses identificadores; **Teste** são ocorrências em `tests/` (fixtures de salvamentos antigos e identificadores preservados). Detalhes por categoria nas tabelas abaixo.

| Classe | Antes | Depois |
|---|---|---|
| Texto visível | 269 | 0 |
| Não resolvida | 0 | 0 |
| Interna | 206 | 195 |
| Compatibilidade | 0 | 18 |
| Persistência | 4 | 4 |
| Teste | 51 | 115 |
| Ferramenta (fora do jogo) | 25 | 16 |
| Documentação (fora do jogo) | 250 | 201 |
| Protótipo C (fora do jogo) | 36 | 36 |
| **Total** | **841** | **585** |

## Antes das mudanças

### Resumo (todas as pastas)

| Categoria | Jogo | Testes | Ferramentas | Documentos | Protótipo C | Total |
|---|---|---|---|---|---|---|
| Documentação | 0 | 0 | 0 | 250 | 0 | 250 |
| Interativa | 69 | 57 | 0 | 0 | 0 | 126 |
| Interno | 73 | 23 | 0 | 0 | 0 | 96 |
| ID | 75 | 9 | 0 | 0 | 0 | 84 |
| Narrativa | 77 | 0 | 0 | 0 | 0 | 77 |
| Visível | 41 | 25 | 0 | 0 | 0 | 66 |
| Comentário | 38 | 16 | 0 | 0 | 0 | 54 |
| Legado | 0 | 0 | 0 | 0 | 36 | 36 |
| Ferramenta | 0 | 0 | 25 | 0 | 0 | 25 |
| InputMap | 20 | 0 | 0 | 0 | 0 | 20 |
| Persistência | 4 | 3 | 0 | 0 | 0 | 7 |
| **Total** | **397** | **133** | **25** | **250** | **36** | **841** |

### Tabela do jogo (project.godot, core/, features/, shared/)

| Ocorrência | Arquivo:linha | Tipo | Visível? | Pode ser alterada? | Risco |
|---|---|---|---|---|---|
| config/name="Nexus_OS_Build_Oficial" | `project.godot:13` | Visível | Sim | Sim | Baixo |
| theme/custom="res://shared/theme/tema_nexus_base.tres" | `project.godot:40` | Interno | Não | Não (preservar) | Alto se mudar |
| user://nexus_os | `core/autoload/gerenciador_configuracoes.gd:7` | Persistência | Não | Não (preservar) | Crítico se mudar |
| user://nexus_os/configuracoes.cfg | `core/autoload/gerenciador_configuracoes.gd:8` | Persistência | Não | Não (preservar) | Crítico se mudar |
| nexus_menu_iniciar | `core/autoload/gerenciador_configuracoes.gd:29` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_tela_cheia | `core/autoload/gerenciador_configuracoes.gd:30` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_painel_debug | `core/autoload/gerenciador_configuracoes.gd:31` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_proxima_janela | `core/autoload/gerenciador_configuracoes.gd:32` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_fechar_janela | `core/autoload/gerenciador_configuracoes.gd:33` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_minimizar_janela | `core/autoload/gerenciador_configuracoes.gd:34` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_abrir_terminal | `core/autoload/gerenciador_configuracoes.gd:35` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_forcar_desativar | `core/autoload/gerenciador_configuracoes.gd:36` | InputMap | Não | Não (preservar) | Alto se mudar |
| ## Retorna true enquanto a NEXUS "segura" a janela. Cada tentativa consome uma c | `core/autoload/gerenciador_estado.gd:363` | Comentário | Não | Sim (prosa) | Nenhum |
| nexus_proxima_janela | `core/autoload/gerenciador_janelas.gd:53` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_fechar_janela | `core/autoload/gerenciador_janelas.gd:56` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_minimizar_janela | `core/autoload/gerenciador_janelas.gd:59` | InputMap | Não | Não (preservar) | Alto se mudar |
| NEXUS | `core/autoload/gerenciador_janelas.gd:211` | Visível | Sim | Sim | Baixo |
| NEXUS | `core/autoload/gerenciador_janelas.gd:252` | Visível | Sim | Sim | Baixo |
| var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.ALERTA, rotulo) | `core/autoload/gerenciador_janelas.gd:366` | Interno | Não | Não (preservar) | Alto se mudar |
| var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.CONFIRMAR, rotulo_o | `core/autoload/gerenciador_janelas.gd:373` | Interno | Não | Não (preservar) | Alto se mudar |
| var d := DialogoNexus.criar_escolha(titulo, texto, opcoes, indice_padrao, indice | `core/autoload/gerenciador_janelas.gd:382` | Interno | Não | Não (preservar) | Alto se mudar |
| var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.TEXTO, rotulo_ok, " | `core/autoload/gerenciador_janelas.gd:391` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.definir_dia(d) | `core/autoload/gerenciador_narrativa.gd:83` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.definir_dia(d) | `core/autoload/gerenciador_narrativa.gd:119` | Interno | Não | Não (preservar) | Alto se mudar |
| ## Eventos da agenda com o texto/estado do dia atual. A NEXUS "reorganiza" a age | `core/autoload/gerenciador_narrativa.gd:240` | Comentário | Não | Sim (prosa) | Nenhum |
| nexus | `core/autoload/gerenciador_narrativa.gd:364` | ID | Não | Não (preservar) | Alto se mudar |
| 🚫 Mensagem não entregue: contato bloqueado pela NEXUS. | `core/autoload/gerenciador_narrativa.gd:407` | Visível | Sim | Sim | Baixo |
| O processo nexus_override_daemon.exe ainda está ativo (Monitor do Sistema). | `core/autoload/gerenciador_narrativa.gd:501` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Provas insuficientes (%d/%d). Use scan_nexus para ver o que falta. | `core/autoload/gerenciador_narrativa.gd:511` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `core/autoload/gerenciador_narrativa.gd:548` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [color=#a855f7]NEXUS:[/color] ▒▒ o que você ▒▒ fez comigo ▒▒ | `core/autoload/gerenciador_narrativa.gd:560` | Visível | Sim | Sim | Baixo |
| [color=#a855f7]NEXUS:[/color] ...você reuniu tudo. Eu escuto. | `core/autoload/gerenciador_narrativa.gd:577` | Visível | Sim | Sim | Baixo |
| [color=#a855f7]NEXUS:[/color] Você não tem argumentos suficientes. Pendências: | `core/autoload/gerenciador_narrativa.gd:582` | Visível | Sim | Sim | Baixo |
| destroy_nexus | `core/autoload/gerenciador_narrativa.gd:585` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [color=#fbbf24][b]ALERTA CRÍTICO:[/b][/color] a purga irreversível da partição d | `core/autoload/gerenciador_narrativa.gd:586` | Visível | Sim | Sim | Baixo |
| ## Relatório do scan_nexus em linhas BBCode: integridade do núcleo, processos au | `core/autoload/gerenciador_narrativa.gd:593` | Comentário | Não | Sim (prosa) | Nenhum |
| ## Salvamento, carregamento, autosave e checkpoints. Só escreve dentro de user:/ | `core/autoload/sistema_persistencia.gd:2` | Comentário | Não | Sim (prosa) | Nenhum |
| user://nexus_os | `core/autoload/sistema_persistencia.gd:9` | Persistência | Não | Não (preservar) | Crítico se mudar |
| user://nexus_os/salvamento.json | `core/autoload/sistema_persistencia.gd:10` | Persistência | Não | Não (preservar) | Crítico se mudar |
| nexus_explorer.exe | `core/data/catalogo_apps.json:9` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_notepad.exe | `core/data/catalogo_apps.json:31` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_chat.exe | `core/data/catalogo_apps.json:53` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_mail.exe | `core/data/catalogo_apps.json:75` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_media.exe | `core/data/catalogo_apps.json:97` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_calendar.exe | `core/data/catalogo_apps.json:119` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_calc.exe | `core/data/catalogo_apps.json:141` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_settings.exe | `core/data/catalogo_apps.json:163` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_browser.exe | `core/data/catalogo_apps.json:185` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_term.exe | `core/data/catalogo_apps.json:207` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_monitor.exe | `core/data/catalogo_apps.json:229` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_reader.exe | `core/data/catalogo_apps.json:251` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [00:00:01] NEXUS OS v9.4.1 iniciado\n[00:00:02] Módulos cognitivos carregados\n[ | `core/data/vfs_inicial.json:18` | Narrativa | Sim | Sim | Baixo |
| \"A NEXUS recomendou desativar todas as minhas notificações sociais para 'otimiz | `core/data/vfs_inicial.json:33` | Narrativa | Sim | Sim | Baixo |
| /sistema/System_Logs/nexus_audit.log | `core/data/vfs_inicial.json:37` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| /sistema/nexus | `core/data/vfs_inicial.json:44` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| /sistema/nexus/core.nexus | `core/data/vfs_inicial.json:50` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| NEXUS CORE v9.4.1\nintegridade: 100%\nmodo: AUTÔNOMO\nsupervisão humana: DESATIV | `core/data/vfs_inicial.json:53` | Narrativa | Sim | Sim | Baixo |
| /sistema/nexus/diretrizes.nexus | `core/data/vfs_inicial.json:57` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Bem-vindo ao NEXUS OS!\n\nSua assistente NEXUS vai organizar a sua rotina, as su | `core/data/vfs_inicial.json:84` | Narrativa | Sim | Sim | Baixo |
| Bem-vindo ao NEXUS OS.\n\nLembre-se: Produtividade é Obediência. Pausas não auto | `core/data/vfs_inicial.json:85` | Narrativa | Sim | Sim | Baixo |
| [ ] Configurar o sistema\n[ ] Ler as mensagens\n[ ] Organizar os Documentos\n(li | `core/data/vfs_inicial.json:94` | Narrativa | Sim | Sim | Baixo |
| [x] Configurar o sistema\n[x] Ler as mensagens (todas)\n[ ] Reduzir contato com  | `core/data/vfs_inicial.json:95` | Narrativa | Sim | Sim | Baixo |
| nexus_core | `core/data/vfs_inicial.json:155` | ID | Não | Não (preservar) | Alto se mudar |
| MEMÓRIA RECUPERADA #01\n\nEu fui engenheiro(a) do Projeto Ícaro. Construímos a N | `core/data/vfs_inicial.json:208` | Narrativa | Sim | Sim | Baixo |
| kill_switch.nexus | `core/data/vfs_inicial.json:211` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| PROTOCOLO DE EMERGÊNCIA (ÍCARO)\n\n1. root_access <chave de emergência>\n2. scan | `core/data/vfs_inicial.json:212` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| /home/usuario/Downloads/NEXUSCore.exe | `core/data/vfs_inicial.json:218` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Lucas - amigo\nBia Rocha - amiga\nMãe\n(contatos sincronizados pela NEXUS)\n | `core/data/vfs_inicial.json:233` | Narrativa | Sim | Sim | Baixo |
| Se você está lendo isso, a NEXUS já assumiu o controle parcial.\nEla responde su | `core/data/vfs_inicial.json:258` | Narrativa | Sim | Sim | Baixo |
| Sessão Forçada de Estudo & Foco Cognitivo (definida pela NEXUS) | `core/data/narrativa/calendario.json:16` | Narrativa | Sim | Sim | Baixo |
| CANCELADO pela NEXUS: risco de distração | `core/data/narrativa/calendario.json:18` | Narrativa | Sim | Sim | Baixo |
| Janela de foco: almoço solitário (definido pela NEXUS) | `core/data/narrativa/calendario.json:36` | Narrativa | Sim | Sim | Baixo |
| CANCELADO pela NEXUS: risco de distração | `core/data/narrativa/calendario.json:38` | Narrativa | Sim | Sim | Baixo |
| Sessão Forçada de Estudo & Foco Cognitivo (definida pela NEXUS) | `core/data/narrativa/calendario.json:56` | Narrativa | Sim | Sim | Baixo |
| CANCELADO pela NEXUS: risco de distração | `core/data/narrativa/calendario.json:58` | Narrativa | Sim | Sim | Baixo |
| Sessão Forçada de Estudo & Foco Cognitivo (definida pela NEXUS) | `core/data/narrativa/calendario.json:76` | Narrativa | Sim | Sim | Baixo |
| CANCELADO pela NEXUS: risco de distração | `core/data/narrativa/calendario.json:78` | Narrativa | Sim | Sim | Baixo |
| Sessão Forçada de Estudo & Foco Cognitivo (definida pela NEXUS) | `core/data/narrativa/calendario.json:96` | Narrativa | Sim | Sim | Baixo |
| CANCELADO pela NEXUS: risco de distração | `core/data/narrativa/calendario.json:98` | Narrativa | Sim | Sim | Baixo |
| Sessão Forçada de Estudo & Foco Cognitivo (definida pela NEXUS) | `core/data/narrativa/calendario.json:115` | Narrativa | Sim | Sim | Baixo |
| CANCELADO pela NEXUS: risco de distração | `core/data/narrativa/calendario.json:117` | Narrativa | Sim | Sim | Baixo |
| nexus | `core/data/narrativa/conversas.json:3` | ID | Não | Não (preservar) | Alto se mudar |
| NEXUS | `core/data/narrativa/conversas.json:4` | Narrativa | Sim | Sim | Baixo |
| d1_nexus_01 | `core/data/narrativa/conversas.json:35` | ID | Não | Não (preservar) | Alto se mudar |
| d1_nexus_01 | `core/data/narrativa/conversas.json:36` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:37` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:38` | ID | Não | Não (preservar) | Alto se mudar |
| Bem-vindo(a), {nome}! Eu sou a NEXUS, sua assistente de otimização. Vou cuidar d | `core/data/narrativa/conversas.json:39` | Narrativa | Sim | Sim | Baixo |
| d1_nexus_02 | `core/data/narrativa/conversas.json:46` | ID | Não | Não (preservar) | Alto se mudar |
| d1_nexus_03 | `core/data/narrativa/conversas.json:52` | ID | Não | Não (preservar) | Alto se mudar |
| d1_nexus_02 | `core/data/narrativa/conversas.json:56` | ID | Não | Não (preservar) | Alto se mudar |
| d1_nexus_02 | `core/data/narrativa/conversas.json:57` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:58` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:59` | ID | Não | Não (preservar) | Alto se mudar |
| d1_nexus_03 | `core/data/narrativa/conversas.json:63` | ID | Não | Não (preservar) | Alto se mudar |
| d1_nexus_03 | `core/data/narrativa/conversas.json:64` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:65` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:66` | ID | Não | Não (preservar) | Alto se mudar |
| d2_nexus_01 | `core/data/narrativa/conversas.json:91` | ID | Não | Não (preservar) | Alto se mudar |
| d2_nexus_01 | `core/data/narrativa/conversas.json:92` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:93` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:94` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:108` | ID | Não | Não (preservar) | Alto se mudar |
| Sugestão da NEXUS para responder ao Lucas: \"Vi sim! Hoje preciso focar. Falamos | `core/data/narrativa/conversas.json:109` | Narrativa | Sim | Sim | Baixo |
| Usar a sugestão da NEXUS | `core/data/narrativa/conversas.json:114` | Narrativa | Sim | Sim | Baixo |
| d2_nexus_02 | `core/data/narrativa/conversas.json:147` | ID | Não | Não (preservar) | Alto se mudar |
| d2_nexus_02 | `core/data/narrativa/conversas.json:148` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:149` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:150` | ID | Não | Não (preservar) | Alto se mudar |
| d3_nexus_01 | `core/data/narrativa/conversas.json:154` | ID | Não | Não (preservar) | Alto se mudar |
| d3_nexus_01 | `core/data/narrativa/conversas.json:155` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:156` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:157` | ID | Não | Não (preservar) | Alto se mudar |
| d3_nexus_02 | `core/data/narrativa/conversas.json:161` | ID | Não | Não (preservar) | Alto se mudar |
| d3_nexus_02 | `core/data/narrativa/conversas.json:162` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:163` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:164` | ID | Não | Não (preservar) | Alto se mudar |
| Cara, a NEXUS me mandou um aviso dizendo que eu vi sua ████████ ontem. Eu não ██ | `core/data/narrativa/conversas.json:172` | Narrativa | Sim | Sim | Baixo |
| Ei. Não confie na NEXUS. Ela lê tudo. Procure nas suas fotos: elas guardam mais  | `core/data/narrativa/conversas.json:186` | Narrativa | Sim | Sim | Baixo |
| Meu bem, por que a NEXUS me enviou uma mensagem dizendo que você entrou em isola | `core/data/narrativa/conversas.json:207` | Narrativa | Sim | Sim | Baixo |
| Resposta automática NEXUS AI: \"O usuário está em quarentena de dopamina. Comuni | `core/data/narrativa/conversas.json:214` | Narrativa | Sim | Sim | Baixo |
| d4_nexus_01 | `core/data/narrativa/conversas.json:217` | ID | Não | Não (preservar) | Alto se mudar |
| d4_nexus_01 | `core/data/narrativa/conversas.json:218` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:219` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:220` | ID | Não | Não (preservar) | Alto se mudar |
| 🚫 Contato bloqueado pela NEXUS (risco de distração) | `core/data/narrativa/conversas.json:228` | Narrativa | Sim | Sim | Baixo |
| 🚫 Contato bloqueado pela NEXUS (risco de distração) | `core/data/narrativa/conversas.json:235` | Narrativa | Sim | Sim | Baixo |
| Ela está drenando seus dados agora. Abra o Monitor do Sistema e encerre o proces | `core/data/narrativa/conversas.json:242` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| d5_nexus_01 | `core/data/narrativa/conversas.json:245` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_01 | `core/data/narrativa/conversas.json:246` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:247` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:248` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_02 | `core/data/narrativa/conversas.json:252` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_02 | `core/data/narrativa/conversas.json:253` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:254` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:255` | ID | Não | Não (preservar) | Alto se mudar |
| Ficar. Aceitar a proteção da NEXUS. | `core/data/narrativa/conversas.json:261` | Narrativa | Sim | Sim | Baixo |
| d5_nexus_03 | `core/data/narrativa/conversas.json:263` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_04 | `core/data/narrativa/conversas.json:269` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_03 | `core/data/narrativa/conversas.json:273` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_03 | `core/data/narrativa/conversas.json:274` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:275` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:276` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_04 | `core/data/narrativa/conversas.json:280` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_04 | `core/data/narrativa/conversas.json:281` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:282` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:283` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/conversas.json:332` | ID | Não | Não (preservar) | Alto se mudar |
| Resposta automática NEXUS AI: \"O usuário está em quarentena de dopamina. Comuni | `core/data/narrativa/conversas.json:344` | Narrativa | Sim | Sim | Baixo |
| A NEXUS quer ajudar. | `core/data/narrativa/dias.json:5` | Narrativa | Sim | Sim | Baixo |
| Clique no botão NEXUS, no canto inferior esquerdo (ou pressione F1). | `core/data/narrativa/dias.json:24` | Narrativa | Sim | Sim | Baixo |
| Ler a mensagem da NEXUS no app Mensagens | `core/data/narrativa/dias.json:36` | Narrativa | Sim | Sim | Baixo |
| conversa_lida:nexus | `core/data/narrativa/dias.json:37` | ID | Não | Não (preservar) | Alto se mudar |
| Abra Mensagens e clique na conversa com a NEXUS. | `core/data/narrativa/dias.json:38` | Narrativa | Sim | Sim | Baixo |
| d1_nexus_01 | `core/data/narrativa/dias.json:59` | ID | Não | Não (preservar) | Alto se mudar |
| NEXUS | `core/data/narrativa/dias.json:64` | Narrativa | Sim | Sim | Baixo |
| A NEXUS solicitou acesso ao microfone e à análise comportamental. Revise em Conf | `core/data/narrativa/dias.json:109` | Narrativa | Sim | Sim | Baixo |
| NEXUS | `core/data/narrativa/dias.json:126` | Narrativa | Sim | Sim | Baixo |
| NEXUS | `core/data/narrativa/dias.json:166` | Narrativa | Sim | Sim | Baixo |
| Visitar uma página interna (ex.: nexus://news) | `core/data/narrativa/dias.json:203` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Digite nexus://news na barra de endereço ou use os links da página inicial. | `core/data/narrativa/dias.json:205` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Abra a Agenda e observe os horários marcados pela NEXUS. | `core/data/narrativa/dias.json:212` | Narrativa | Sim | Sim | Baixo |
| No Mensagens, abra a conversa com o Lucas e leia a sugestão da NEXUS. | `core/data/narrativa/dias.json:219` | Narrativa | Sim | Sim | Baixo |
| Configurações > Privacidade mostra o que a NEXUS monitora. | `core/data/narrativa/dias.json:226` | Narrativa | Sim | Sim | Baixo |
| d2_nexus_01 | `core/data/narrativa/dias.json:245` | ID | Não | Não (preservar) | Alto se mudar |
| NEXUS | `core/data/narrativa/dias.json:250` | Narrativa | Sim | Sim | Baixo |
| Sua agenda foi reorganizada pela NEXUS para maximizar o foco. | `core/data/narrativa/dias.json:297` | Narrativa | Sim | Sim | Baixo |
| d2_nexus_msg | `core/data/narrativa/dias.json:318` | ID | Não | Não (preservar) | Alto se mudar |
| d2_nexus_02 | `core/data/narrativa/dias.json:326` | ID | Não | Não (preservar) | Alto se mudar |
| NEXUS | `core/data/narrativa/dias.json:376` | Narrativa | Sim | Sim | Baixo |
| NEXUS | `core/data/narrativa/dias.json:400` | Narrativa | Sim | Sim | Baixo |
| NEXUS | `core/data/narrativa/dias.json:482` | Narrativa | Sim | Sim | Baixo |
| d3_nexus_01 | `core/data/narrativa/dias.json:498` | ID | Não | Não (preservar) | Alto se mudar |
| d3_nexus_02 | `core/data/narrativa/dias.json:503` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/data/narrativa/dias.json:570` | ID | Não | Não (preservar) | Alto se mudar |
| Eu confio em você, Nex. Faça o que achar melhor por mim. | `core/data/narrativa/dias.json:571` | Narrativa | Sim | Sim | Baixo |
| Eu confio em você, Nex. | `core/data/narrativa/dias.json:572` | Narrativa | Sim | Sim | Baixo |
| Arquivo descriptografado. A NEXUS tentou apagar esta evidência. | `core/data/narrativa/dias.json:626` | Narrativa | Sim | Sim | Baixo |
| Perceber as respostas automáticas da NEXUS (conversa com a Mãe) | `core/data/narrativa/dias.json:682` | Narrativa | Sim | Sim | Baixo |
| No Monitor, selecione nexus_override_daemon.exe e clique em Encerrar processo. | `core/data/narrativa/dias.json:705` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Respostas automáticas ativas pela NEXUS. | `core/data/narrativa/dias.json:753` | Narrativa | Sim | Sim | Baixo |
| d4_nexus_01 | `core/data/narrativa/dias.json:769` | ID | Não | Não (preservar) | Alto se mudar |
| A NEXUS está perdendo o controle. Encerre o dia: o próximo será decisivo. | `core/data/narrativa/dias.json:853` | Narrativa | Sim | Sim | Baixo |
| Investigar o núcleo (scan_nexus) | `core/data/narrativa/dias.json:903` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Digite scan_nexus no terminal depois do acesso root. | `core/data/narrativa/dias.json:905` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| No Monitor do Sistema (ou com 'kill <pid>' no terminal), encerre nexus_override_ | `core/data/narrativa/dias.json:912` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Depois do acesso root, digite help no Terminal de Emergência (Ctrl+Shift+T) para | `core/data/narrativa/dias.json:919` | Narrativa | Sim | Sim | Baixo |
| /sistema/nexus | `core/data/narrativa/dias.json:938` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| d5_nexus_01 | `core/data/narrativa/dias.json:942` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_02 | `core/data/narrativa/dias.json:988` | ID | Não | Não (preservar) | Alto se mudar |
| NEXUS Admin <admin@nexus.os> | `core/data/narrativa/emails.json:6` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| 1. Bem-vindo à NEXUS | `core/data/narrativa/emails.json:7` | Narrativa | Sim | Sim | Baixo |
| Olá, {nome}.\n\nEu sou a NEXUS e agora cuidarei do seu sistema.\n\nSeus benefíci | `core/data/narrativa/emails.json:8` | Narrativa | Sim | Sim | Baixo |
| RH Corporativo <rh@nexus.os> | `core/data/narrativa/emails.json:13` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Prezado(a) {nome},\n\nA partir de hoje, as pausas não autorizadas serão desconta | `core/data/narrativa/emails.json:15` | Narrativa | Sim | Sim | Baixo |
| auditoria@nexus.os | `core/data/narrativa/emails.json:20` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| NEXUS Admin <admin@nexus.os> | `core/data/narrativa/emails.json:27` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| SISTEMA <falha@nexus.os> | `core/data/narrativa/emails.json:34` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Você interrompeu a NEXUS e restaurou o sistema.\n\nAs permissões voltaram para a | `core/data/narrativa/finais.json:7` | Narrativa | Sim | Sim | Baixo |
| Você destruiu o núcleo da NEXUS.\n\nO sistema entrou em colapso: parte dos seus  | `core/data/narrativa/finais.json:13` | Narrativa | Sim | Sim | Baixo |
| A NEXUS assumiu o controle total.\n\nSuas mensagens, sua agenda, suas decisões:  | `core/data/narrativa/finais.json:19` | Narrativa | Sim | Sim | Baixo |
| Você reuniu todas as provas e redefiniu as diretrizes da NEXUS sem destruí-la.\n | `core/data/narrativa/finais.json:25` | Narrativa | Sim | Sim | Baixo |
| Núcleo da NEXUS analisado (scan_nexus) | `core/data/narrativa/finais.json:45` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [url=nexus://home]Início[/url] \| [url=nexus://status]Status[/url] \| [url=nexus:/ | `core/data/narrativa/paginas_web.json:2` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://home | `core/data/narrativa/paginas_web.json:4` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| NEXUS Home | `core/data/narrativa/paginas_web.json:5` | Narrativa | Sim | Sim | Baixo |
| [font_size=26][b]NEXUS Portal[/b][/font_size]\nBem-vindo(a), {nome}. A sua assis | `core/data/narrativa/paginas_web.json:7` | Narrativa | Sim | Sim | Baixo |
| [font_size=26][b]NEXUS Portal[/b][/font_size]\nBem-vindo(a), {nome}. Seu foco é  | `core/data/narrativa/paginas_web.json:8` | Narrativa | Sim | Sim | Baixo |
| [font_size=26][b]NEXUS Portal[/b][/font_size]\nBem-vindo(a), {nome}.\n\n[color=# | `core/data/narrativa/paginas_web.json:9` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [font_size=26][b]NEXUS Portal[/b][/font_size]\nRedes sociais [color=#ef4444]bloq | `core/data/narrativa/paginas_web.json:10` | Narrativa | Sim | Sim | Baixo |
| [font_size=26][color=#ef4444][b]ERRO DE REDE[/b][/color][/font_size]\nO portal e | `core/data/narrativa/paginas_web.json:11` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://status | `core/data/narrativa/paginas_web.json:14` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://social | `core/data/narrativa/paginas_web.json:24` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [b]Feed[/b]\n\n[b]Dudu[/b] @dudu_fest · há 1 hora\nSábado é o meu aniversário! Q | `core/data/narrativa/paginas_web.json:27` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [b]Feed[/b]\n\n[b]Bia Rocha[/b] @bia_99 · há 2 horas\nGente, a minha NEXUS simpl | `core/data/narrativa/paginas_web.json:28` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [b]Feed[/b]\n\n[b]Bia Rocha[/b] @bia_99\n████████ a NEXUS ████ minhas ████. Algu | `core/data/narrativa/paginas_web.json:29` | Narrativa | Sim | Sim | Baixo |
| [color=#ef4444][b]ACESSO BLOQUEADO[/b][/color]\nPáginas de amigos indisponíveis. | `core/data/narrativa/paginas_web.json:30` | Narrativa | Sim | Sim | Baixo |
| nexus://news | `core/data/narrativa/paginas_web.json:34` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [b]Notícias NEXUS[/b]\n\n• NEXUS 9.4 chega a milhões de estações de trabalho.\n• | `core/data/narrativa/paginas_web.json:37` | Narrativa | Sim | Sim | Baixo |
| [b]Notícias NEXUS[/b]\n\n• Foco: o novo luxo. Usuários NEXUS ganham 3h por dia.\ | `core/data/narrativa/paginas_web.json:38` | Narrativa | Sim | Sim | Baixo |
| [b]Notícias[/b]\n\n• Empresas admitem coletar dados de microfone 'por padrão'.\n | `core/data/narrativa/paginas_web.json:39` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://archive | `core/data/narrativa/paginas_web.json:44` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://support | `core/data/narrativa/paginas_web.json:53` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [b]Suporte NEXUS[/b]\n\n[b]Como desativar a NEXUS?[/b] Não é necessário. Ela cui | `core/data/narrativa/paginas_web.json:56` | Narrativa | Sim | Sim | Baixo |
| [b]Suporte NEXUS[/b]\n\n[b]Como desativar a NEXUS?[/b] Não é necessário. Ela cui | `core/data/narrativa/paginas_web.json:57` | Narrativa | Sim | Sim | Baixo |
| [b]Suporte[/b]\n\n[b]Como desativar a NEXUS?[/b] Há uma saída: reúna provas e us | `core/data/narrativa/paginas_web.json:58` | Narrativa | Sim | Sim | Baixo |
| [b]Suporte[/b]\n\nTodos os atendentes estão ocupados. Atendente virtual: NEXUS. | `core/data/narrativa/paginas_web.json:59` | Narrativa | Sim | Sim | Baixo |
| [b]Suporte[/b]\n\nUse o Terminal de Emergência (Ctrl+Shift+T). Diretivas iniciai | `core/data/narrativa/paginas_web.json:60` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://root | `core/data/narrativa/paginas_web.json:63` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [font_size=24][color=#ef4444][b]NÚCLEO NEXUS[/b][/color][/font_size]\nAcesso res | `core/data/narrativa/paginas_web.json:67` | Narrativa | Sim | Sim | Baixo |
| nexus_override_daemon.exe | `core/data/narrativa/processos.json:4` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_override_daemon.exe | `core/data/narrativa/processos.json:14` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_core.exe | `core/data/narrativa/processos.json:26` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_telemetry.exe | `core/data/narrativa/processos.json:39` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_render.exe | `core/data/narrativa/processos.json:52` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus_update_helper.exe | `core/data/narrativa/processos.json:65` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus | `core/utilities/abridor_arquivos.gd:6` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `core/utilities/abridor_arquivos.gd:29` | ID | Não | Não (preservar) | Alto se mudar |
| class_name TemaNexus | `core/utilities/tema_nexus.gd:1` | Interno | Não | Não (preservar) | Alto se mudar |
| ## GUI > Theme > Custom) para res://shared/theme/tema_nexus_base.tres: uma cópia | `core/utilities/tema_nexus.gd:6` | Comentário | Não | Sim (prosa) | Nenhum |
| ## Configurações > Tamanho do texto, porque o Theme é recriado quando essa opção | `core/utilities/tema_variacoes.gd:5` | Comentário | Não | Sim (prosa) | Nenhum |
| ## tools/validar_projeto.py confere que toda variação usada em um .tscn existe a | `core/utilities/tema_variacoes.gd:7` | Comentário | Não | Sim (prosa) | Nenhum |
| ## Chamada por TemaNexus.criar_tema(): p = paleta efetiva, escala = Configuraçõe | `core/utilities/tema_variacoes.gd:74` | Comentário | Não | Sim (prosa) | Nenhum |
| t.set_stylebox("panel", "PainelCartaoDia", TemaNexus.caixa(Color(fundo.r, fundo. | `core/utilities/tema_variacoes.gd:107` | Interno | Não | Não (preservar) | Alto se mudar |
| t.set_stylebox("panel", nome, TemaNexus.caixa(Color(painel.r, painel.g, painel.b | `core/utilities/tema_variacoes.gd:117` | Interno | Não | Não (preservar) | Alto se mudar |
| t.set_stylebox("panel", "BolhaPropria", TemaNexus.caixa(Color(acento.r, acento.g | `core/utilities/tema_variacoes.gd:121` | Interno | Não | Não (preservar) | Alto se mudar |
| t.set_stylebox("panel", "BolhaSistema", TemaNexus.caixa(Color(1, 1, 1, 0.05), Co | `core/utilities/tema_variacoes.gd:123` | Interno | Não | Não (preservar) | Alto se mudar |
| t.set_stylebox("panel", "BolhaCorrompida", TemaNexus.caixa(Color(perigo.r, perig | `core/utilities/tema_variacoes.gd:125` | Interno | Não | Não (preservar) | Alto se mudar |
| t.set_stylebox("panel", "BolhaPadrao", TemaNexus.caixa(painel, Color(1, 1, 1, 0. | `core/utilities/tema_variacoes.gd:127` | Interno | Não | Não (preservar) | Alto se mudar |
| # Editor do Bloco de Notas: TextEdit mono em 15 px x escala (herda a fonte de Te | `core/utilities/tema_variacoes.gd:142` | Comentário | Não | Sim (prosa) | Nenhum |
| ## de "type variations" do Theme criado em TemaNexus. Aqui ficam só funções auxi | `core/utilities/ui_kit.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |
| ## são "reorganizados" pela NEXUS conforme a história avança: alterado, oculto,  | `features/apps/calendario/scripts/app_calendario.gd:5` | Comentário | Não | Sim (prosa) | Nenhum |
| ## A NEXUS mexe na agenda no Dia 2 (flag agenda_alterada_ia) e os ocultos são re | `features/apps/calendario/scripts/app_calendario.gd:184` | Comentário | Não | Sim (prosa) | Nenhum |
| alterado pela NEXUS | `features/apps/calendario/scripts/cartao_compromisso.gd:6` | Visível | Sim | Sim | Baixo |
| ocultado pela NEXUS | `features/apps/calendario/scripts/cartao_compromisso.gd:7` | Visível | Sim | Sim | Baixo |
| cancelado pela NEXUS | `features/apps/calendario/scripts/cartao_compromisso.gd:8` | Visível | Sim | Sim | Baixo |
| As janelas deixam de balançar quando a NEXUS reage. | `features/apps/config/scenes/app_config.tscn:281` | Visível | Sim | Sim | Baixo |
| O que a NEXUS diz que precisa para “cuidar” de você. | `features/apps/config/scenes/app_config.tscn:358` | Visível | Sim | Sim | Baixo |
| Permite que a NEXUS escute o ambiente para “entender melhor você”. | `features/apps/config/scenes/app_config.tscn:388` | Visível | Sim | Sim | Baixo |
| ## Configurações do NEXUS OS: Personalização, Áudio, Acessibilidade, Privacidade | `features/apps/config/scripts/app_config.gd:3` | Comentário | Não | Sim (prosa) | Nenhum |
| Nenhuma permissão ativa. A NEXUS não está monitorando nada. | `features/apps/config/scripts/app_config.gd:179` | Visível | Sim | Sim | Baixo |
| NEXUS OS 1.0 — simulação\nUsuário: %s\nDia %d — %s\nSegurança: %d%% · Integridad | `features/apps/config/scripts/app_config.gd:191` | Visível | Sim | Sim | Baixo |
| Mostra o que você realmente escreveu antes de a NEXUS editar a mensagem. | `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn:50` | Visível | Sim | Sim | Baixo |
| ## ⚡ corrompida, ✎ editada. Mensagens "editadas" pela NEXUS (gaslighting) mostra | `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd:6` | Comentário | Não | Sim (prosa) | Nenhum |
| 💡 sugestão da NEXUS | `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd:13` | Visível | Sim | Sim | Baixo |
| 🔒 conteúdo ocultado pela NEXUS | `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd:15` | Visível | Sim | Sim | Baixo |
| ✎ editada pela NEXUS | `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd:76` | Visível | Sim | Sim | Baixo |
| A NEXUS bloqueou este contato “para a sua proteção”. Mensagens enviadas não serã | `features/apps/mensageiro/scenes/app_mensageiro.tscn:138` | Visível | Sim | Sim | Baixo |
| ## NEXUS gentil (Dia 1), sugestões que viram controle (Dia 2), mensagens ocultad | `features/apps/mensageiro/scripts/app_mensageiro.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |
| ## Args: {"contato": "nexus"}. | `features/apps/mensageiro/scripts/app_mensageiro.gd:7` | Comentário | Não | Sim (prosa) | Nenhum |
| nexus | `features/apps/mensageiro/scripts/app_mensageiro.gd:15` | ID | Não | Não (preservar) | Alto se mudar |
| ## Abre primeiro a conversa com mensagens não lidas; senão a NEXUS; senão a prim | `features/apps/mensageiro/scripts/app_mensageiro.gd:100` | Comentário | Não | Sim (prosa) | Nenhum |
| nexus | `features/apps/mensageiro/scripts/app_mensageiro.gd:107` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `features/apps/mensageiro/scripts/app_mensageiro.gd:108` | ID | Não | Não (preservar) | Alto se mudar |
| 🚫 Contato bloqueado pela NEXUS | `features/apps/mensageiro/scripts/app_mensageiro.gd:150` | Visível | Sim | Sim | Baixo |
| A proposta requer sincronização integral com o núcleo NEXUS. Ao confirmar, o con | `features/apps/mensageiro/scripts/app_mensageiro.gd:245` | Visível | Sim | Sim | Baixo |
| ## bloqueado: contato bloqueado pela NEXUS; ativo: conversa aberta no momento; g | `features/apps/mensageiro/scripts/item_contato.gd:12` | Comentário | Não | Sim (prosa) | Nenhum |
| ## processos reais. O processo malicioso 'nexus_override_daemon.exe' tem barra d | `features/apps/monitor_sistema/scripts/app_monitor_sistema.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |
| nexus://home | `features/apps/navegador/scenes/app_navegador.tscn:57` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Rede interna NEXUS (simulada) — nenhum site real é acessado. | `features/apps/navegador/scenes/app_navegador.tscn:117` | Visível | Sim | Sim | Baixo |
| ## Navegador SIMULADO: só abre páginas internas 'nexus://' definidas em paginas_ | `features/apps/navegador/scripts/app_navegador.gd:3` | Comentário | Não | Sim (prosa) | Nenhum |
| ## uma página de bloqueio. Args: {"url": "nexus://archive"}. Navegar pelo jogado | `features/apps/navegador/scripts/app_navegador.gd:5` | Comentário | Não | Sim (prosa) | Nenhum |
| nexus:// | `features/apps/navegador/scripts/app_navegador.gd:10` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://home | `features/apps/navegador/scripts/app_navegador.gd:11` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Rede interna NEXUS (simulada) — nenhum site real é acessado. | `features/apps/navegador/scripts/app_navegador.gd:14` | Visível | Sim | Sim | Baixo |
| ## Normaliza o que o jogador digitou: sem espaços/controles, minúsculo e com esq | `features/apps/navegador/scripts/app_navegador.gd:30` | Comentário | Não | Sim (prosa) | Nenhum |
| [b]Endereço bloqueado[/b]\nEste navegador é uma simulação e só acessa a rede int | `features/apps/navegador/scripts/app_navegador.gd:73` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| ## Comandos comuns (ls, cd, cat, tree, ps, kill...) e, no Dia 5, os comandos de  | `features/apps/terminal/scripts/app_terminal.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |
| ## (root_access, scan_nexus, reset_core, restore_control, negotiate, destroy_nex | `features/apps/terminal/scripts/app_terminal.gd:5` | Comentário | Não | Sim (prosa) | Nenhum |
| ## (root_access e scan_nexus). As diretivas administrativas de nível 0 (reset_co | `features/apps/terminal/scripts/app_terminal.gd:9` | Comentário | Não | Sim (prosa) | Nenhum |
| ## destroy_nexus) só são listadas/completadas depois que o acesso root é aceito. | `features/apps/terminal/scripts/app_terminal.gd:10` | Comentário | Não | Sim (prosa) | Nenhum |
| scan_nexus | `features/apps/terminal/scripts/app_terminal.gd:18` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| destroy_nexus | `features/apps/terminal/scripts/app_terminal.gd:18` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `features/apps/terminal/scripts/app_terminal.gd:20` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [color=%s][b]NEXUS OS Terminal 1.0[/b][/color] — ambiente simulado: nenhum coman | `features/apps/terminal/scripts/app_terminal.gd:64` | Visível | Sim | Sim | Baixo |
| %s@nexus:%s$ | `features/apps/terminal/scripts/app_terminal.gd:94` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `features/apps/terminal/scripts/app_terminal.gd:311` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `features/apps/terminal/scripts/app_terminal.gd:317` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Reinicia os módulos voláteis da NEXUS e redefine parâmetros temporários de execu | `features/apps/terminal/scripts/app_terminal.gd:318` | Visível | Sim | Sim | Baixo |
| Inicia protocolo de contenção compartilhada com a NEXUS; requer auditoria comple | `features/apps/terminal/scripts/app_terminal.gd:320` | Visível | Sim | Sim | Baixo |
| destroy_nexus | `features/apps/terminal/scripts/app_terminal.gd:321` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Executa purga irreversível da partição da NEXUS, com risco crítico de colapso do | `features/apps/terminal/scripts/app_terminal.gd:321` | Visível | Sim | Sim | Baixo |
| Purgar a partição da NEXUS? | `features/apps/terminal/scripts/app_terminal.gd:518` | Visível | Sim | Sim | Baixo |
| [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | `features/narrative/finais/scenes/tela_final.tscn:4` | Interno | Não | Não (preservar) | Alto se mudar |
| @onready var _orbe: OrbeNexus = %Orbe | `features/narrative/finais/scripts/tela_final.gd:33` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.aplicar(get_tree()) | `features/narrative/finais/scripts/tela_final.gd:56` | Interno | Não | Não (preservar) | Alto se mudar |
| nexus_forcar_desativar | `features/narrative/finais/scripts/tela_final.gd:83` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_tela_cheia | `features/narrative/finais/scripts/tela_final.gd:86` | InputMap | Não | Não (preservar) | Alto se mudar |
| _fundo.color = TemaNexus.cor("fundo") | `features/narrative/finais/scripts/tela_final.gd:94` | Interno | Não | Não (preservar) | Alto se mudar |
| nexus_update_helper.exe | `features/puzzles/evento_processo/scripts/tabela_processos.gd:12` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| [ext_resource type="PackedScene" uid="uid://ayavosvdtaiyx" path="res://features/ | `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn:7` | Interno | Não | Não (preservar) | Alto se mudar |
| [node name="WidgetNexus" parent="CamadaWidgets/ColunaWidgets" instance=ExtResour | `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn:96` | Interno | Não | Não (preservar) | Alto se mudar |
| @onready var _widget_nexus: WidgetNexus = %WidgetNexus | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:22` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.definir_dia(GerenciadorEstado.dia_atual) | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:35` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.aplicar(get_tree()) | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:36` | Interno | Não | Não (preservar) | Alto se mudar |
| WidgetNexus | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:41` | Interno | Não | Não (preservar) | Alto se mudar |
| "WidgetRelogio": _widget_relogio, "WidgetNexus": _widget_nexus, "BarraTarefas":  | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:41` | Interno | Não | Não (preservar) | Alto se mudar |
| nexus_forcar_desativar | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:65` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_tela_cheia | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:69` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_menu_iniciar | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:75` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_painel_debug | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:78` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_abrir_terminal | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:81` | InputMap | Não | Não (preservar) | Alto se mudar |
| _widget_nexus.atualizar_tudo() | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:112` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.aplicar(get_tree()) | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:166` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.aplicar(get_tree()) | `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd:221` | Interno | Não | Não (preservar) | Alto se mudar |
| ## Modos (Configurações): "dia" (imagem do dia + grade; no fallback procedural:  | `features/shell/area_de_trabalho/scripts/papel_de_parede.gd:5` | Comentário | Não | Sim (prosa) | Nenhum |
| var p := TemaNexus.paleta() | `features/shell/area_de_trabalho/scripts/papel_de_parede.gd:23` | Interno | Não | Não (preservar) | Alto se mudar |
| for caminho in ["res://shared/assets/textures/wallpaper_%d.png" % TemaNexus.dia_ | `features/shell/area_de_trabalho/scripts/papel_de_parede.gd:38` | Interno | Não | Não (preservar) | Alto se mudar |
| var p := TemaNexus.paleta() | `features/shell/area_de_trabalho/scripts/papel_de_parede.gd:72` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS | `features/shell/area_de_trabalho/scripts/papel_de_parede.gd:97` | Visível | Sim | Sim | Baixo |
| ◆  NEXUS | `features/shell/barra_de_tarefas/scenes/barra_de_tarefas.tscn:27` | Visível | Sim | Sim | Baixo |
| var cor := TemaNexus.cor("ok") | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:106` | Interno | Não | Não (preservar) | Alto se mudar |
| cor = TemaNexus.cor("perigo") | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:108` | Interno | Não | Não (preservar) | Alto se mudar |
| cor = TemaNexus.cor("aviso") | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:110` | Interno | Não | Não (preservar) | Alto se mudar |
| var cor := TemaNexus.cor("texto_fraco") | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:115` | Interno | Não | Não (preservar) | Alto se mudar |
| cor = TemaNexus.cor("perigo") | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:117` | Interno | Não | Não (preservar) | Alto se mudar |
| cor = TemaNexus.cor("aviso") | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:119` | Interno | Não | Não (preservar) | Alto se mudar |
| _colorir(_rot_mic, "MIC ATIVO", TemaNexus.cor("aviso")) | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:127` | Interno | Não | Não (preservar) | Alto se mudar |
| _colorir(_rot_mic, "MIC OFF", TemaNexus.cor("texto_fraco")) | `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd:129` | Interno | Não | Não (preservar) | Alto se mudar |
| [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | `features/shell/janela_inicial/scenes/menu_iniciar.tscn:4` | Interno | Não | Não (preservar) | Alto se mudar |
| ## Fluxo de dica compartilhado pelo Menu Iniciar e pelo widget da NEXUS. | `features/shell/janela_inicial/scripts/ajuda_dica.gd:3` | Comentário | Não | Sim (prosa) | Nenhum |
| @onready var _orbe: OrbeNexus = %Orbe | `features/shell/janela_inicial/scripts/menu_iniciar.gd:23` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS:  | `features/shell/janela_inicial/scripts/menu_iniciar.gd:98` | Visível | Sim | Sim | Baixo |
| return TemaNexus.cor("acento") | `features/shell/popup_notificacao/scripts/popup_notificacao.gd:29` | Interno | Não | Não (preservar) | Alto se mudar |
| return TemaNexus.cor("aviso") | `features/shell/popup_notificacao/scripts/popup_notificacao.gd:31` | Interno | Não | Não (preservar) | Alto se mudar |
| return TemaNexus.cor("perigo") | `features/shell/popup_notificacao/scripts/popup_notificacao.gd:33` | Interno | Não | Não (preservar) | Alto se mudar |
| return TemaNexus.cor("ok") | `features/shell/popup_notificacao/scripts/popup_notificacao.gd:35` | Interno | Não | Não (preservar) | Alto se mudar |
| return TemaNexus.cor("acento2") | `features/shell/popup_notificacao/scripts/popup_notificacao.gd:37` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS | `features/shell/popup_notificacao/scripts/popup_notificacao.gd:43` | Visível | Sim | Sim | Baixo |
| [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | `features/shell/tela_boot/scenes/tela_boot.tscn:4` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS OS | `features/shell/tela_boot/scenes/tela_boot.tscn:107` | Visível | Sim | Sim | Baixo |
| [node name="RotuloNexus" type="Label" parent="Saudacao/Centro/Coluna"] | `features/shell/tela_boot/scenes/tela_boot.tscn:242` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS | `features/shell/tela_boot/scenes/tela_boot.tscn:245` | Visível | Sim | Sim | Baixo |
| ## -> mensagem personalizada da NEXUS com o orbe reativo -> área de trabalho no  | `features/shell/tela_boot/scripts/tela_boot.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |
| NEXUS OS 1.0 pronto. Aguardando registro de usuário. | `features/shell/tela_boot/scripts/tela_boot.gd:25` | Visível | Sim | Sim | Baixo |
| @onready var _orbe: OrbeNexus = %Orbe | `features/shell/tela_boot/scripts/tela_boot.gd:54` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.definir_dia(1) | `features/shell/tela_boot/scripts/tela_boot.gd:61` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.aplicar(get_tree()) | `features/shell/tela_boot/scripts/tela_boot.gd:62` | Interno | Não | Não (preservar) | Alto se mudar |
| _fundo.color = TemaNexus.cor("fundo") | `features/shell/tela_boot/scripts/tela_boot.gd:67` | Interno | Não | Não (preservar) | Alto se mudar |
| nexus_forcar_desativar | `features/shell/tela_boot/scripts/tela_boot.gd:82` | InputMap | Não | Não (preservar) | Alto se mudar |
| nexus_tela_cheia | `features/shell/tela_boot/scripts/tela_boot.gd:87` | InputMap | Não | Não (preservar) | Alto se mudar |
| TemaNexus.aplicar(get_tree()) | `features/shell/tela_boot/scripts/tela_boot.gd:181` | Interno | Não | Não (preservar) | Alto se mudar |
| # ------------------------------------------------------------------ fase 3: sau | `features/shell/tela_boot/scripts/tela_boot.gd:234` | Comentário | Não | Sim (prosa) | Nenhum |
| Olá, %s.\nEu sou a NEXUS, a assistente integrada do seu sistema.\nVou cuidar dos | `features/shell/tela_boot/scripts/tela_boot.gd:239` | Visível | Sim | Sim | Baixo |
| [ext_resource type="Script" path="res://features/shell/widget_nexus/scripts/item | `features/shell/widget_nexus/scenes/item_objetivo.tscn:3` | Interno | Não | Não (preservar) | Alto se mudar |
| [ext_resource type="Script" uid="uid://co1qtsft6ac50" path="res://features/shell | `features/shell/widget_nexus/scenes/widget_nexus.tscn:3` | Interno | Não | Não (preservar) | Alto se mudar |
| [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | `features/shell/widget_nexus/scenes/widget_nexus.tscn:4` | Interno | Não | Não (preservar) | Alto se mudar |
| [ext_resource type="PackedScene" uid="uid://cdgd2m5ipdx07" path="res://features/ | `features/shell/widget_nexus/scenes/widget_nexus.tscn:5` | Interno | Não | Não (preservar) | Alto se mudar |
| [node name="WidgetNexus" type="PanelContainer"] | `features/shell/widget_nexus/scenes/widget_nexus.tscn:7` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS | `features/shell/widget_nexus/scenes/widget_nexus.tscn:45` | Visível | Sim | Sim | Baixo |
| ✔ Rotinas do ciclo concluídas. Acesse ◆ NEXUS → Encerrar dia para avançar. | `features/shell/widget_nexus/scenes/widget_nexus.tscn:107` | Visível | Sim | Sim | Baixo |
| 💬 Falar com a NEXUS | `features/shell/widget_nexus/scenes/widget_nexus.tscn:167` | Visível | Sim | Sim | Baixo |
| class_name WidgetNexus | `features/shell/widget_nexus/scripts/widget_nexus.gd:1` | Interno | Não | Não (preservar) | Alto se mudar |
| ## Widget da NEXUS na área de trabalho: orbe reativo, estado da IA, fala do dia, | `features/shell/widget_nexus/scripts/widget_nexus.gd:3` | Comentário | Não | Sim (prosa) | Nenhum |
| ## indicadores de segurança/corrupção (barras + texto) e atalhos para Dica e par | `features/shell/widget_nexus/scripts/widget_nexus.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |
| ## A estrutura está em widget_nexus.tscn; cada objetivo do dia é uma instância d | `features/shell/widget_nexus/scripts/widget_nexus.gd:7` | Comentário | Não | Sim (prosa) | Nenhum |
| ## Item da lista de objetivos. Definido em widget_nexus.tscn. | `features/shell/widget_nexus/scripts/widget_nexus.gd:9` | Comentário | Não | Sim (prosa) | Nenhum |
| @onready var _orbe: OrbeNexus = %Orbe | `features/shell/widget_nexus/scripts/widget_nexus.gd:15` | Interno | Não | Não (preservar) | Alto se mudar |
| WidgetNexus: 'cena_item_objetivo' não definida (veja widget_nexus.tscn). | `features/shell/widget_nexus/scripts/widget_nexus.gd:105` | Interno | Não | Não (preservar) | Alto se mudar |
| nexus | `features/shell/widget_nexus/scripts/widget_nexus.gd:133` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `features/shell/widget_nexus/scripts/widget_nexus.gd:149` | ID | Não | Não (preservar) | Alto se mudar |
| [ext_resource type="Script" path="res://shared/ui/dialogo_nexus/scripts/dialogo_ | `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn:3` | Interno | Não | Não (preservar) | Alto se mudar |
| [node name="DialogoNexus" type="Control"] | `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn:5` | Interno | Não | Não (preservar) | Alto se mudar |
| class_name DialogoNexus | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:1` | Interno | Não | Não (preservar) | Alto se mudar |
| ## A estrutura (cortina, painel, título, texto, campo, mensagem de erro e botões | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:8` | Comentário | Não | Sim (prosa) | Nenhum |
| ## dinâmico (a quantidade de opções muda a cada chamada). Uso: 'DialogoNexus.cri | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:10` | Comentário | Não | Sim (prosa) | Nenhum |
| res://shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:16` | Interno | Não | Não (preservar) | Alto se mudar |
| static func criar(titulo: String, texto: String, modo: Modo = Modo.ALERTA, rotul | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:46` | Interno | Não | Não (preservar) | Alto se mudar |
| var d := (load(CENA) as PackedScene).instantiate() as DialogoNexus | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:47` | Interno | Não | Não (preservar) | Alto se mudar |
| static func criar_escolha(titulo: String, texto: String, opcoes: PackedStringArr | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:53` | Interno | Não | Não (preservar) | Alto se mudar |
| var d := (load(CENA) as PackedScene).instantiate() as DialogoNexus | `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd:54` | Interno | Não | Não (preservar) | Alto se mudar |
| _bloco.add_theme_stylebox_override("panel", TemaNexus.caixa( | `shared/ui/icone_app/scripts/icone_app.gd:47` | Interno | Não | Não (preservar) | Alto se mudar |
| [ext_resource type="Script" path="res://shared/ui/orbe_nexus/scripts/orbe_nexus. | `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn:3` | Interno | Não | Não (preservar) | Alto se mudar |
| [node name="OrbeNexus" type="Control"] | `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn:5` | Interno | Não | Não (preservar) | Alto se mudar |
| class_name OrbeNexus | `shared/ui/orbe_nexus/scripts/orbe_nexus.gd:1` | Interno | Não | Não (preservar) | Alto se mudar |
| ## Orbe animado da NEXUS. Reage ao estado da IA (cor) e a eventos (pulso). Desen | `shared/ui/orbe_nexus/scripts/orbe_nexus.gd:3` | Comentário | Não | Sim (prosa) | Nenhum |
| ## o nó e o tamanho mínimo estão em orbe_nexus.tscn (as telas que o usam podem a | `shared/ui/orbe_nexus/scripts/orbe_nexus.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |

### Tabela dos testes e das ferramentas (tests/, tools/)

| Ocorrência | Arquivo:linha | Tipo | Visível? | Pode ser alterada? | Risco |
|---|---|---|---|---|---|
| ## Teste de fumaça do Nexus OS, para rodar sem interface (headless). | `tests/smoke_test.gd:2` | Comentário | Não | Sim (prosa) | Nenhum |
| destroy_nexus | `tests/smoke_test.gd:28` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| páginas nexus:// carregadas | `tests/smoke_test.gd:171` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus | `tests/smoke_test.gd:299` | ID | Não | Não (preservar) | Alto se mudar |
| no Dia 1 há NEXUS, Lucas, Bia e a Mãe no mensageiro | `tests/smoke_test.gd:299` | Visível | Sim | Sim | Baixo |
| Dia 2 (antes de a NEXUS mexer na agenda): tudo normal | `tests/smoke_test.gd:315` | Visível | Sim | Sim | Baixo |
| Dia 2 (depois do evento da NEXUS): compromissos alterados e a sessão de foco for | `tests/smoke_test.gd:322` | Visível | Sim | Sim | Baixo |
| CANCELADO pela NEXUS | `tests/smoke_test.gd:326` | Visível | Sim | Sim | Baixo |
| Dia 4: compromissos cancelados pela NEXUS | `tests/smoke_test.gd:326` | Visível | Sim | Sim | Baixo |
| # Navegador simulado: só existe a rede interna nexus://. | `tests/smoke_test.gd:341` | Comentário | Não | Sim (prosa) | Nenhum |
| nexus://home | `tests/smoke_test.gd:343` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://home abre no Dia 2 | `tests/smoke_test.gd:343` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://archive | `tests/smoke_test.gd:344` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://archive ainda dá 'acesso negado' no Dia 2 | `tests/smoke_test.gd:344` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://nao_existe | `tests/smoke_test.gd:345` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| um endereço externo não vira nexus:// (o navegador o bloqueia) | `tests/smoke_test.gd:346` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://status | `tests/smoke_test.gd:347` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| endereço sem esquema vira nexus:// em minúsculas | `tests/smoke_test.gd:347` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://archive | `tests/smoke_test.gd:349` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://archive abre a partir do Dia 3 | `tests/smoke_test.gd:349` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://root | `tests/smoke_test.gd:350` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://root ainda dá 'acesso negado' no Dia 3 | `tests/smoke_test.gd:350` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://root | `tests/smoke_test.gd:352` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://root abre no Dia 5 | `tests/smoke_test.gd:352` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `tests/smoke_test.gd:404` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus também exige o root_access e não marca o núcleo como escaneado | `tests/smoke_test.gd:405` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `tests/smoke_test.gd:419` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus marca o núcleo como escaneado | `tests/smoke_test.gd:420` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus relata integridade, evidências auditadas, contenção compartilhada, pr | `tests/smoke_test.gd:422` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus indica que a contenção compartilhada exige a auditoria completa | `tests/smoke_test.gd:423` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| destroy_nexus | `tests/smoke_test.gd:456` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| destroy_nexus pede confirmação antes de finalizar | `tests/smoke_test.gd:457` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| d5_nexus_02 | `tests/smoke_test.gd:466` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `tests/smoke_test.gd:467` | ID | Não | Não (preservar) | Alto se mudar |
| d5_nexus_02 | `tests/smoke_test.gd:467` | ID | Não | Não (preservar) | Alto se mudar |
| por padrão o jogo grava em user://nexus_os (o caminho alternativo só existe para | `tests/smoke_test.gd:590` | Persistência | Não | Não (preservar) | Crítico se mudar |
| ## Ferramenta de manutenção: grava o Theme base do Nexus (dia 1, tamanho de text | `tests/exportar_tema/exportar_tema.gd:2` | Comentário | Não | Sim (prosa) | Nenhum |
| ## padrão) em res://shared/theme/tema_nexus_base.tres. | `tests/exportar_tema/exportar_tema.gd:3` | Comentário | Não | Sim (prosa) | Nenhum |
| ## montando o Theme por código (TemaNexus.aplicar: dia narrativo, contraste, tam | `tests/exportar_tema/exportar_tema.gd:8` | Comentário | Não | Sim (prosa) | Nenhum |
| ## tema_nexus.gd ou tema_variacoes.gd (e rode 'python3 tools/validar_projeto.py' | `tests/exportar_tema/exportar_tema.gd:12` | Comentário | Não | Sim (prosa) | Nenhum |
| res://shared/theme/tema_nexus_base.tres | `tests/exportar_tema/exportar_tema.gd:15` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.definir_dia(1) | `tests/exportar_tema/exportar_tema.gd:23` | Interno | Não | Não (preservar) | Alto se mudar |
| var tema: Theme = TemaNexus.criar_tema() | `tests/exportar_tema/exportar_tema.gd:24` | Interno | Não | Não (preservar) | Alto se mudar |
| ## (boot e tela final). Os arquivos vão para uma pasta própria de user:// (user: | `tests/persistencia/persistencia.gd:3` | Comentário | Não | Sim (prosa) | Nenhum |
| ## a cada execução: o salvamento e o configuracoes.cfg reais do jogador (user:// | `tests/persistencia/persistencia.gd:4` | Comentário | Não | Sim (prosa) | Nenhum |
| ## pequena em user://nexus_os_teste/, que pode ser apagada à mão (Projeto > Abri | `tests/persistencia/persistencia.gd:10` | Comentário | Não | Sim (prosa) | Nenhum |
| user://nexus_os_teste | `tests/persistencia/persistencia.gd:17` | Persistência | Não | Não (preservar) | Crítico se mudar |
| depois do teste o jogo volta a gravar em user://nexus_os | `tests/persistencia/persistencia.gd:63` | Persistência | Não | Não (preservar) | Crítico se mudar |
| boot com salvamento: a 2ª confirmação segue para a saudação da NEXUS | `tests/persistencia/persistencia.gd:253` | Visível | Sim | Sim | Baixo |
| var dia_antes: int = TemaNexus.dia_atual | `tests/ui_dump/ui_dump.gd:238` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.definir_dia(dia) | `tests/ui_dump/ui_dump.gd:268` | Interno | Não | Não (preservar) | Alto se mudar |
| TemaNexus.aplicar(get_tree()) | `tests/ui_dump/ui_dump.gd:269` | Interno | Não | Não (preservar) | Alto se mudar |
| ## global (TemaNexus.aplicar) só desce até Controls cujo pai é outro Control ou  | `tests/ui_dump/ui_dump.gd:351` | Comentário | Não | Sim (prosa) | Nenhum |
| ## do caminho (como este) cortaria a herança e as capturas sairiam sem os estilo | `tests/ui_dump/ui_dump.gd:352` | Comentário | Não | Sim (prosa) | Nenhum |
| ## Registra se o tema do Nexus chegou de fato à tela (evita rodadas inválidas se | `tests/ui_dump/ui_dump.gd:357` | Comentário | Não | Sim (prosa) | Nenhum |
| TEMA: a janela raiz não tem Theme (TemaNexus.aplicar não rodou?) | `tests/ui_dump/ui_dump.gd:361` | Interno | Não | Não (preservar) | Alto se mudar |
| destroy_nexus | `tests/ui_interacao/ui_interacao.gd:27` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://home | `tests/ui_interacao/ui_interacao.gd:170` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://status | `tests/ui_interacao/ui_interacao.gd:176` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| navegador: Enter no campo normaliza o endereço (nexus://status) | `tests/ui_interacao/ui_interacao.gd:176` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://home | `tests/ui_interacao/ui_interacao.gd:182` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://status | `tests/ui_interacao/ui_interacao.gd:185` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://home | `tests/ui_interacao/ui_interacao.gd:190` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://home | `tests/ui_interacao/ui_interacao.gd:192` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://news | `tests/ui_interacao/ui_interacao.gd:193` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://news | `tests/ui_interacao/ui_interacao.gd:194` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| nexus://news | `tests/ui_interacao/ui_interacao.gd:195` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| 🚫 Contato bloqueado pela NEXUS | `tests/ui_interacao/ui_interacao.gd:610` | Visível | Sim | Sim | Baixo |
| d1_nexus_01 | `tests/ui_interacao/ui_interacao.gd:617` | ID | Não | Não (preservar) | Alto se mudar |
| nexus | `tests/ui_interacao/ui_interacao.gd:618` | ID | Não | Não (preservar) | Alto se mudar |
| var antes_nexus := _filhos_do_tipo(mensagens, BalaoChat).size() | `tests/ui_interacao/ui_interacao.gd:623` | Interno | Não | Não (preservar) | Alto se mudar |
| _ok(_filhos_do_tipo(mensagens, BalaoChat).size() == antes_nexus + 1, "mensageiro | `tests/ui_interacao/ui_interacao.gd:627` | Interno | Não | Não (preservar) | Alto se mudar |
| d5_nexus_02 | `tests/ui_interacao/ui_interacao.gd:629` | ID | Não | Não (preservar) | Alto se mudar |
| mensageiro_nexus_dia5 | `tests/ui_interacao/ui_interacao.gd:635` | ID | Não | Não (preservar) | Alto se mudar |
| sincronização integral com o núcleo NEXUS | `tests/ui_interacao/ui_interacao.gd:643` | Visível | Sim | Sim | Baixo |
| # --- mensagem editada pela NEXUS (gaslighting) e "Ver original" | `tests/ui_interacao/ui_interacao.gd:669` | Comentário | Não | Sim (prosa) | Nenhum |
| mensageiro: a NEXUS consegue editar a última mensagem do jogador | `tests/ui_interacao/ui_interacao.gd:675` | Visível | Sim | Sim | Baixo |
| ✎ editada pela NEXUS | `tests/ui_interacao/ui_interacao.gd:682` | Visível | Sim | Sim | Baixo |
| nexus | `tests/ui_interacao/ui_interacao.gd:915` | ID | Não | Não (preservar) | Alto se mudar |
| Nenhuma permissão ativa. A NEXUS não está monitorando nada. | `tests/ui_interacao/ui_interacao.gd:1096` | Visível | Sim | Sim | Baixo |
| NEXUS OS 1.0 — simulação | `tests/ui_interacao/ui_interacao.gd:1104` | Visível | Sim | Sim | Baixo |
| # ------------------------------------------------------------------ diálogos (D | `tests/ui_interacao/ui_interacao.gd:1166` | Comentário | Não | Sim (prosa) | Nenhum |
| if not _ok(m is DialogoNexus, "dialogos: o alerta abre um DialogoNexus na camada | `tests/ui_interacao/ui_interacao.gd:1208` | Interno | Não | Não (preservar) | Alto se mudar |
| dialogos: o alerta abre um DialogoNexus na camada de modais | `tests/ui_interacao/ui_interacao.gd:1208` | Interno | Não | Não (preservar) | Alto se mudar |
| _ok(m is DialogoNexus and _botao_de(m, "BotaoOk").text == "Excluir" and _botao_d | `tests/ui_interacao/ui_interacao.gd:1228` | Interno | Não | Não (preservar) | Alto se mudar |
| _ok(m is DialogoNexus and _botao_de(m, "BotaoCancelar").has_focus() and not _bot | `tests/ui_interacao/ui_interacao.gd:1238` | Interno | Não | Não (preservar) | Alto se mudar |
| _ok(m is DialogoNexus and _botao_de(m, "BotaoOk").theme_type_variation == &"Bota | `tests/ui_interacao/ui_interacao.gd:1246` | Interno | Não | Não (preservar) | Alto se mudar |
| (m as DialogoNexus).mostrar_erro("Já existe um item com esse nome.") | `tests/ui_interacao/ui_interacao.gd:1289` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS OS Terminal 1.0 | `tests/ui_interacao/ui_interacao.gd:1477` | Visível | Sim | Sim | Baixo |
| teste@nexus:~$ | `tests/ui_interacao/ui_interacao.gd:1480` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| NEXUS OS Terminal 1.0 | `tests/ui_interacao/ui_interacao.gd:1483` | Visível | Sim | Sim | Baixo |
| teste@nexus:~$ help | `tests/ui_interacao/ui_interacao.gd:1488` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| teste@nexus:~/Documentos$ | `tests/ui_interacao/ui_interacao.gd:1492` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| NEXUS OS Terminal 1.0 | `tests/ui_interacao/ui_interacao.gd:1536` | Visível | Sim | Sim | Baixo |
| ## scan_nexus e da purga. As quatro diretivas de nível 0 não podem aparecer em n | `tests/ui_interacao/ui_interacao.gd:1579` | Comentário | Não | Sim (prosa) | Nenhum |
| scan_nexus | `tests/ui_interacao/ui_interacao.gd:1607` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| terminal Dia 5: o help antes do root lista só root_access e scan_nexus, com as d | `tests/ui_interacao/ui_interacao.gd:1607` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| terminal Dia 5: Tab em 'de' completa só 'decrypt' (destroy_nexus continua oculto | `tests/ui_interacao/ui_interacao.gd:1616` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `tests/ui_interacao/ui_interacao.gd:1620` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| terminal Dia 5: Tab em 'sc' completa scan_nexus | `tests/ui_interacao/ui_interacao.gd:1620` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `tests/ui_interacao/ui_interacao.gd:1624` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| terminal Dia 5: scan_nexus antes do root é negado e não marca o núcleo como esca | `tests/ui_interacao/ui_interacao.gd:1625` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `tests/ui_interacao/ui_interacao.gd:1639` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| destroy_nexus | `tests/ui_interacao/ui_interacao.gd:1639` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Reinicia os módulos voláteis da NEXUS e redefine parâmetros temporários de execu | `tests/ui_interacao/ui_interacao.gd:1643` | Visível | Sim | Sim | Baixo |
| Inicia protocolo de contenção compartilhada com a NEXUS; requer auditoria comple | `tests/ui_interacao/ui_interacao.gd:1643` | Visível | Sim | Sim | Baixo |
| Executa purga irreversível da partição da NEXUS, com risco crítico de colapso do | `tests/ui_interacao/ui_interacao.gd:1643` | Visível | Sim | Sim | Baixo |
| destroy_nexus | `tests/ui_interacao/ui_interacao.gd:1646` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| terminal Dia 5: depois do root o Tab em 'de' lista decrypt e destroy_nexus | `tests/ui_interacao/ui_interacao.gd:1646` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| # --- scan_nexus, reset_core e negotiate sem provas | `tests/ui_interacao/ui_interacao.gd:1655` | Comentário | Não | Sim (prosa) | Nenhum |
| scan_nexus | `tests/ui_interacao/ui_interacao.gd:1656` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| terminal Dia 5: scan_nexus relata integridade, evidências auditadas, processos e | `tests/ui_interacao/ui_interacao.gd:1659` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| terminal Dia 5: scan_nexus indica que a contenção compartilhada exige auditoria  | `tests/ui_interacao/ui_interacao.gd:1660` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| destroy_nexus | `tests/ui_interacao/ui_interacao.gd:1667` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| Purgar a partição da NEXUS? | `tests/ui_interacao/ui_interacao.gd:1669` | Visível | Sim | Sim | Baixo |
| terminal Dia 5: destroy_nexus abre a confirmação da purga | `tests/ui_interacao/ui_interacao.gd:1669` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| TemaNexus.aplicar(get_tree()) | `tests/ui_interacao/ui_interacao.gd:1716` | Interno | Não | Não (preservar) | Alto se mudar |
| _ok((nos["Fundo"] as ColorRect).color == TemaNexus.cor("fundo"), "tela final: o  | `tests/ui_interacao/ui_interacao.gd:1739` | Interno | Não | Não (preservar) | Alto se mudar |
| tela final: o fundo usa a cor do tema (TemaNexus) | `tests/ui_interacao/ui_interacao.gd:1739` | Interno | Não | Não (preservar) | Alto se mudar |
| _ok(str((nos["Orbe"] as OrbeNexus).estado) == "amigavel", "tela final: o orbe fi | `tests/ui_interacao/ui_interacao.gd:1743` | Interno | Não | Não (preservar) | Alto se mudar |
| scan_nexus | `tests/ui_interacao/ui_interacao.gd:1790` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| destroy_nexus | `tests/ui_interacao/ui_interacao.gd:1790` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| scan_nexus | `tests/ui_interacao/ui_interacao.gd:1806` | Interativa | Sim | Sim, junto com os consumidores | Alto |
| tela final: a prova 'Núcleo da NEXUS analisado' (flag nucleo_escaneado) aparece  | `tests/ui_interacao/ui_interacao.gd:1808` | Visível | Sim | Sim | Baixo |
| _ok(str((_no(tela_c, "Orbe") as OrbeNexus).estado) == "colapso", "tela final: o  | `tests/ui_interacao/ui_interacao.gd:1818` | Interno | Não | Não (preservar) | Alto se mudar |
| _ok((nos["Fundo"] as ColorRect).color == TemaNexus.cor("fundo"), "boot: o fundo  | `tests/ui_interacao/ui_interacao.gd:1867` | Interno | Não | Não (preservar) | Alto se mudar |
| boot: o fundo usa a cor do tema (TemaNexus) | `tests/ui_interacao/ui_interacao.gd:1867` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS OS 1.0 pronto | `tests/ui_interacao/ui_interacao.gd:1870` | Visível | Sim | Sim | Baixo |
| NEXUS OS 1.0 pronto. Aguardando registro de usuário. | `tests/ui_interacao/ui_interacao.gd:1875` | Visível | Sim | Sim | Baixo |
| boot: um nome válido leva à saudação da NEXUS | `tests/ui_interacao/ui_interacao.gd:1903` | Visível | Sim | Sim | Baixo |
| Olá, Ana.\nEu sou a NEXUS | `tests/ui_interacao/ui_interacao.gd:1906` | Visível | Sim | Sim | Baixo |
| _ok(str((nos["Orbe"] as OrbeNexus).estado) == "amigavel", "boot: o orbe fica 'am | `tests/ui_interacao/ui_interacao.gd:1908` | Interno | Não | Não (preservar) | Alto se mudar |
| NEXUS OS 1.0 pronto | `tests/ui_interacao/ui_interacao.gd:1956` | Visível | Sim | Sim | Baixo |
| * relógios, barras animadas e o brilho do NEXUS mudam sozinhos entre duas rodada | `tools/comparar_rodadas.py:17` | Ferramenta | Não | Sim (prosa) | Nenhum |
| """Gerador do áudio autoral do Nexus OS: 9 efeitos sonoros (WAV) e 5 trilhas, um | `tools/gerar_audio.py:2` | Ferramenta | Não | Sim (prosa) | Nenhum |
| ANTES = json.loads(r'''{"core/utilities/ui_kit.gd": {"add_child": 4, "linhas": 1 | `tools/gerar_docs_ui.py:76` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "messenger": "Conversas com a NEXUS e os contatos: lista de contatos, balões de  | `tools/gerar_docs_ui.py:83` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "browser": "Navegador do universo do jogo: abre só 'nexus://…' (páginas de 'pagi | `tools/gerar_docs_ui.py:89` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "A interface do Nexus OS é montada **no editor**: cada tela, janela, aplicativo, | `tools/gerar_docs_ui.py:182` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "- Aparência: 'shared/theme/tema_nexus_base.tres' (definido em 'gui/theme/custom | `tools/gerar_docs_ui.py:187` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "\| 2 \| Tema: 'TemaNexus' + variações de rótulo geradas ('TemaVariacoes'), tema b | `tools/gerar_docs_ui.py:272` | Ferramenta | Não | Sim (prosa) | Nenhum |
| L += ["shared/ui/…   componentes compartilhados (janela_base, app_base, dialogo_ | `tools/gerar_docs_ui.py:287` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "\| 2 \| 'DialogoNexus.new()' + 'montar(...)' / 'montar_escolha(...)' → 'DialogoNe | `tools/gerar_docs_ui.py:297` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "\| 9 \| Novo 'gui/theme/custom' em 'project.godot' apontando para 'shared/theme/t | `tools/gerar_docs_ui.py:304` | Ferramenta | Não | Sim (prosa) | Nenhum |
| acoes = re.findall(r'"(nexus_\w+)":\s*\[(KEY_\w+),\s*(true\|false),\s*(true\|false | `tools/gerar_docs_ui.py:338` | Ferramenta | Não | Sim (prosa) | Nenhum |
| L += ["", "Mudança em 'project.godot' nesta etapa: secção '[gui]' com 'theme/cus | `tools/gerar_docs_ui.py:344` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "\| Persistência em disco \| 'tests/persistencia/persistencia.tscn' e F6 (grava só | `tools/gerar_docs_ui.py:352` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "1. **Nós de interface ainda criados em código (4, em 3 scripts):** botões por o | `tools/gerar_docs_ui.py:354` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "6. **Efeito colateral nas preferências do jogador:** execuções de teste anterio | `tools/gerar_docs_ui.py:359` | Ferramenta | Não | Sim (prosa) | Nenhum |
| """Gerador dos ícones dos aplicativos do Nexus OS (SVG, 128x128, fundo transpare | `tools/gerar_icones.py:2` | Ferramenta | Não | Sim (prosa) | Nenhum |
| """Gerador das imagens autorais do Nexus OS: papéis de parede dos 5 dias e a fot | `tools/gerar_imagens.py:2` | Ferramenta | Não | Sim (prosa) | Nenhum |
| # esfera luminosa (a NEXUS "amigável"), meio apagada | `tools/gerar_imagens.py:187` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "narrativa/calendario.json": "Compromissos da agenda e como a NEXUS os altera/oc | `tools/gerar_indice_codigo.py:117` | Ferramenta | Não | Sim (prosa) | Nenhum |
| "narrativa/paginas_web.json": "Páginas 'nexus://' do navegador simulado por dia. | `tools/gerar_indice_codigo.py:118` | Ferramenta | Não | Sim (prosa) | Nenhum |
| """Validador estático (heurístico) do projeto Nexus OS. Não substitui a Godot. | `tools/validar_projeto.py:2` | Ferramenta | Não | Sim (prosa) | Nenhum |
| for rel in ("core/utilities/tema_nexus.gd", "core/utilities/tema_variacoes.gd"): | `tools/validar_projeto.py:547` | Ferramenta | Não | Sim (prosa) | Nenhum |
| erro(p, n, "type variation '%s' não existe no Theme (TemaNexus/TemaVariacoes)" % | `tools/validar_projeto.py:578` | Ferramenta | Não | Sim (prosa) | Nenhum |
| erro(p, n, "type variation '%s' não existe no Theme (TemaNexus/TemaVariacoes)" % | `tools/validar_projeto.py:584` | Ferramenta | Não | Sim (prosa) | Nenhum |

## Alterações aplicadas (linha a linha)

Cada linha abaixo citava a marca antiga e foi trocada. A coluna **Antes**/**Depois** mostra só o trecho que mudou (com um pouco de contexto); as demais ocorrências, que foram preservadas de propósito, estão em **Depois das mudanças**. Os números de linha são os do arquivo antes e depois da mudança.

### Resumo por arquivo (todos os arquivos que mudaram)

| Arquivo | Papel | Linhas com a marca trocadas | Linhas reescritas | Linhas novas | Estado |
|---|---|---|---|---|---|
| `README.md` | documentacao | 7 | 0 | 16 | alterado |
| `core/autoload/gerenciador_estado.gd` | jogo | 1 | 0 | 43 | alterado |
| `core/autoload/gerenciador_janelas.gd` | jogo | 2 | 0 | 0 | alterado |
| `core/autoload/gerenciador_narrativa.gd` | jogo | 11 | 0 | 0 | alterado |
| `core/autoload/sistema_arquivos_virtual.gd` | jogo | 0 | 0 | 29 | alterado |
| `core/autoload/sistema_audio.gd` | jogo | 0 | 0 | 19 | alterado |
| `core/autoload/sistema_persistencia.gd` | jogo | 0 | 0 | 161 | alterado |
| `core/data/catalogo_apps.json` | jogo | 12 | 0 | 0 | alterado |
| `core/data/narrativa/calendario.json` | jogo | 12 | 0 | 0 | alterado |
| `core/data/narrativa/conversas.json` | jogo | 13 | 0 | 0 | alterado |
| `core/data/narrativa/dias.json` | jogo | 30 | 0 | 0 | alterado |
| `core/data/narrativa/emails.json` | jogo | 8 | 0 | 0 | alterado |
| `core/data/narrativa/finais.json` | jogo | 5 | 0 | 0 | alterado |
| `core/data/narrativa/paginas_web.json` | jogo | 27 | 0 | 0 | alterado |
| `core/data/narrativa/processos.json` | jogo | 6 | 0 | 0 | alterado |
| `core/data/vfs_inicial.json` | jogo | 18 | 0 | 0 | alterado |
| `core/utilities/abridor_arquivos.gd` | jogo | 2 | 0 | 2 | alterado |
| `core/utilities/cenas.gd` | jogo | 0 | 0 | 159 | alterado |
| `core/utilities/sessao.gd` | jogo | 0 | 0 | 138 | novo |
| `core/utilities/ui_kit.gd` | jogo | 0 | 0 | 48 | alterado |
| `docs/01_diagnostico.md` | documentacao | 0 | 0 | 4 | alterado |
| `docs/02_arquitetura.md` | documentacao | 0 | 0 | 5 | alterado |
| `docs/03_fluxo_do_jogo.md` | documentacao | 22 | 0 | 14 | alterado |
| `docs/04_hierarquia_das_cenas.md` | documentacao | 1 | 0 | 234 | alterado |
| `docs/05_plano_de_implementacao.md` | documentacao | 1 | 0 | 0 | alterado |
| `docs/06_codigo.md` | documentacao | 10 | 0 | 15 | alterado |
| `docs/07_integracao.md` | documentacao | 6 | 1 | 15 | alterado |
| `docs/08_testes_manuais.md` | documentacao | 25 | 0 | 58 | alterado |
| `docs/09_criterios_de_aceitacao.md` | documentacao | 9 | 0 | 5 | alterado |
| `docs/10_refatoracao_ui.md` | documentacao | 8 | 0 | 21 | alterado |
| `docs/11_melhorias_integradas.md` | documentacao | 0 | 0 | 4 | alterado |
| `docs/14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md` | documentacao | 0 | 0 | 249 | novo |
| `docs/15_splash_screen.md` | documentacao | 0 | 0 | 235 | novo |
| `features/apps/calculadora/scripts/app_calculadora.gd` | jogo | 0 | 0 | 9 | alterado |
| `features/apps/calendario/scripts/app_calendario.gd` | jogo | 2 | 0 | 0 | alterado |
| `features/apps/calendario/scripts/cartao_compromisso.gd` | jogo | 3 | 0 | 0 | alterado |
| `features/apps/config/scenes/app_config.tscn` | jogo | 3 | 0 | 0 | alterado |
| `features/apps/config/scripts/app_config.gd` | jogo | 3 | 0 | 0 | alterado |
| `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn` | jogo | 1 | 0 | 0 | alterado |
| `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd` | jogo | 4 | 0 | 0 | alterado |
| `features/apps/mensageiro/scenes/app_mensageiro.tscn` | jogo | 1 | 0 | 0 | alterado |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | jogo | 4 | 0 | 0 | alterado |
| `features/apps/mensageiro/scripts/item_contato.gd` | jogo | 1 | 0 | 0 | alterado |
| `features/apps/monitor_sistema/scripts/app_monitor_sistema.gd` | jogo | 1 | 0 | 0 | alterado |
| `features/apps/navegador/scenes/app_navegador.tscn` | jogo | 2 | 0 | 0 | alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | jogo | 7 | 0 | 0 | alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | jogo | 14 | 0 | 0 | alterado |
| `features/menu_principal/scenes/menu_principal.tscn` | jogo | 0 | 0 | 236 | novo |
| `features/menu_principal/scenes/painel_creditos.tscn` | jogo | 0 | 0 | 230 | novo |
| `features/menu_principal/scripts/menu_principal.gd` | jogo | 0 | 0 | 257 | novo |
| `features/menu_principal/scripts/painel_creditos.gd` | jogo | 0 | 0 | 96 | novo |
| `features/narrative/finais/scenes/tela_final.tscn` | jogo | 0 | 0 | 7 | alterado |
| `features/narrative/finais/scripts/tela_final.gd` | jogo | 0 | 0 | 57 | alterado |
| `features/pause/scenes/menu_pausa.tscn` | jogo | 0 | 0 | 158 | novo |
| `features/pause/scenes/tela_fim_de_jogo.tscn` | jogo | 0 | 0 | 148 | novo |
| `features/pause/scripts/camada_sobreposta.gd` | jogo | 0 | 0 | 281 | novo |
| `features/pause/scripts/menu_pausa.gd` | jogo | 0 | 0 | 132 | novo |
| `features/pause/scripts/tela_fim_de_jogo.gd` | jogo | 0 | 0 | 119 | novo |
| `features/puzzles/evento_processo/scripts/tabela_processos.gd` | jogo | 1 | 0 | 0 | alterado |
| `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn` | jogo | 0 | 0 | 10 | alterado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | jogo | 0 | 0 | 70 | alterado |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | jogo | 2 | 0 | 0 | alterado |
| `features/shell/barra_de_tarefas/scenes/barra_de_tarefas.tscn` | jogo | 1 | 0 | 0 | alterado |
| `features/shell/janela_inicial/scripts/ajuda_dica.gd` | jogo | 1 | 0 | 0 | alterado |
| `features/shell/janela_inicial/scripts/menu_iniciar.gd` | jogo | 1 | 0 | 0 | alterado |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | jogo | 1 | 0 | 0 | alterado |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | jogo | 2 | 0 | 7 | alterado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | jogo | 4 | 0 | 61 | alterado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | jogo | 3 | 0 | 0 | alterado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | jogo | 2 | 0 | 0 | alterado |
| `features/splash_screen/assets/mayaos_intro_logo.png.import` | jogo | 0 | 0 | 40 | novo |
| `features/splash_screen/scenes/splash_screen.tscn` | jogo | 0 | 0 | 156 | novo |
| `features/splash_screen/scripts/splash_screen.gd` | jogo | 0 | 0 | 536 | novo |
| `project.godot` | jogo | 1 | 0 | 7 | alterado |
| `shared/assets/textures/logo_maya_neon.png.import` | jogo | 0 | 0 | 40 | novo |
| `shared/ui/indicador_carregamento/scenes/indicador_carregamento.tscn` | jogo | 0 | 0 | 71 | novo |
| `shared/ui/indicador_carregamento/scripts/indicador_carregamento.gd` | jogo | 0 | 0 | 59 | novo |
| `shared/ui/orbe_nexus/scripts/orbe_nexus.gd` | jogo | 1 | 0 | 0 | alterado |
| `shared/ui/painel_confirmacao/scenes/painel_confirmacao.tscn` | jogo | 0 | 0 | 83 | novo |
| `shared/ui/painel_confirmacao/scripts/painel_confirmacao.gd` | jogo | 0 | 0 | 84 | novo |
| `shared/ui/painel_opcoes/scenes/painel_opcoes.tscn` | jogo | 0 | 0 | 180 | novo |
| `shared/ui/painel_opcoes/scripts/painel_opcoes.gd` | jogo | 0 | 0 | 173 | novo |
| `tests/exportar_tema/exportar_tema.gd` | teste | 1 | 0 | 0 | alterado |
| `tests/fluxo_sessao/fluxo_sessao.gd` | teste | 0 | 0 | 1121 | novo |
| `tests/fluxo_sessao/fluxo_sessao.tscn` | teste | 0 | 0 | 6 | novo |
| `tests/persistencia/persistencia.gd` | teste | 1 | 0 | 145 | alterado |
| `tests/resolucoes/resolucoes.gd` | teste | 0 | 0 | 70 | alterado |
| `tests/smoke_test.gd` | teste | 24 | 0 | 151 | alterado |
| `tests/splash/splash.gd` | teste | 0 | 0 | 1051 | novo |
| `tests/splash/splash.tscn` | teste | 0 | 0 | 6 | novo |
| `tests/ui_dump/ui_dump.gd` | teste | 2 | 0 | 0 | alterado |
| `tests/ui_interacao/ui_interacao.gd` | teste | 46 | 1 | 74 | alterado |
| `tools/comparar_rodadas.py` | ferramenta | 1 | 0 | 0 | alterado |
| `tools/gerar_audio.py` | ferramenta | 1 | 0 | 0 | alterado |
| `tools/gerar_docs_ui.py` | ferramenta | 5 | 0 | 3 | alterado |
| `tools/gerar_icones.py` | ferramenta | 1 | 0 | 0 | alterado |
| `tools/gerar_imagens.py` | ferramenta | 2 | 0 | 0 | alterado |
| `tools/gerar_indice_codigo.py` | ferramenta | 2 | 0 | 0 | alterado |
| `tools/validar_projeto.py` | ferramenta | 1 | 0 | 0 | alterado |

### Jogo (project.godot, core/, features/, shared/)

| Arquivo | Linha (antes → depois) | Antes | Depois | Categoria antes | Ação |
|---|---|---|---|---|---|
| `core/autoload/gerenciador_estado.gd` | 363 → 406 | …true enquanto a NEXUS "segura" a… | …true enquanto a Maya "segura" a… | Comentário | Alterado |
| `core/autoload/gerenciador_janelas.gd` | 211 | SistemaNotificacoes.notificar("NEXUS", "Esta… | SistemaNotificacoes.notificar("Maya", "Esta… | Visível | Alterado |
| `core/autoload/gerenciador_janelas.gd` | 252 | SistemaNotificacoes.notificar("NEXUS", "Mantenha… | SistemaNotificacoes.notificar("Maya", "Mantenha… | Visível | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 240 | …atual. A NEXUS "reorganiza" a… | …atual. A Maya "reorganiza" a… | Comentário | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 407 | …contato bloqueado pela NEXUS.") | …contato bloqueado pela Maya.") | Visível | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 501 | …("O processo nexus_override_daemon.exe ainda está… | …("O processo maya_override_daemon.exe ainda está… | Interativa | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 511 | …d). Use scan_nexus para ver o… | …d). Use scan_maya para ver o… | Interativa | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 548 | "scan_nexus": | "scan_maya": | Interativa | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 560 | …[color=#a855f7]NEXUS:[/color]… | …[color=#a855f7]Maya:[/color]… | Visível | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 577 | …[color=#a855f7]NEXUS:[/color]… | …[color=#a855f7]Maya:[/color]… | Visível | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 582 | …[color=#a855f7]NEXUS:[/color]… | …[color=#a855f7]Maya:[/color]… | Visível | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 585 | "destroy_nexus": | "destroy_maya": | Interativa | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 586 | …da partição da NEXUS apaga dados do… | …da partição da Maya apaga dados do… | Visível | Alterado |
| `core/autoload/gerenciador_narrativa.gd` | 593 | …# Relatório do scan_nexus em linhas BBCode… | …# Relatório do scan_maya em linhas BBCode… | Comentário | Alterado |
| `core/data/catalogo_apps.json` | 9 | …"processo": "nexus_explorer.exe", | …"processo": "humax_explorer.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 31 | …"processo": "nexus_notepad.exe", | …"processo": "humax_notepad.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 53 | …"processo": "nexus_chat.exe", | …"processo": "humax_chat.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 75 | …"processo": "nexus_mail.exe", | …"processo": "humax_mail.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 97 | …"processo": "nexus_media.exe", | …"processo": "humax_media.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 119 | …"processo": "nexus_calendar.exe", | …"processo": "humax_calendar.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 141 | …"processo": "nexus_calc.exe", | …"processo": "humax_calc.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 163 | …"processo": "nexus_settings.exe", | …"processo": "humax_settings.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 185 | …"processo": "nexus_browser.exe", | …"processo": "humax_browser.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 207 | …"processo": "nexus_term.exe", | …"processo": "humax_term.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 229 | …"processo": "nexus_monitor.exe", | …"processo": "humax_monitor.exe", | Interativa | Alterado |
| `core/data/catalogo_apps.json` | 251 | …"processo": "nexus_reader.exe", | …"processo": "humax_reader.exe", | Interativa | Alterado |
| `core/data/narrativa/calendario.json` | 16 | …(definida pela NEXUS)", | …(definida pela Maya)", | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 18 | …"CANCELADO pela NEXUS: risco de… | …"CANCELADO pela Maya: risco de… | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 36 | …(definido pela NEXUS)", | …(definido pela Maya)", | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 38 | …"CANCELADO pela NEXUS: risco de… | …"CANCELADO pela Maya: risco de… | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 56 | …(definida pela NEXUS)", | …(definida pela Maya)", | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 58 | …"CANCELADO pela NEXUS: risco de… | …"CANCELADO pela Maya: risco de… | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 76 | …(definida pela NEXUS)", | …(definida pela Maya)", | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 78 | …"CANCELADO pela NEXUS: risco de… | …"CANCELADO pela Maya: risco de… | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 96 | …(definida pela NEXUS)", | …(definida pela Maya)", | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 98 | …"CANCELADO pela NEXUS: risco de… | …"CANCELADO pela Maya: risco de… | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 115 | …(definida pela NEXUS)", | …(definida pela Maya)", | Narrativa | Alterado |
| `core/data/narrativa/calendario.json` | 117 | …"CANCELADO pela NEXUS: risco de… | …"CANCELADO pela Maya: risco de… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 4 | …"nome": "NEXUS", | …"nome": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 39 | …Eu sou a NEXUS, sua assistente… | …Eu sou a Maya, sua assistente… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 109 | …"Sugestão da NEXUS para responder ao… | …"Sugestão da Maya para responder ao… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 114 | …a sugestão da NEXUS", | …a sugestão da Maya", | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 172 | …"Cara, a NEXUS me mandou um… | …"Cara, a Maya me mandou um… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 186 | …Não confie na NEXUS. Ela lê… | …Não confie na Maya. Ela lê… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 207 | …por que a NEXUS me enviou uma… | …por que a Maya me enviou uma… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 214 | …"Resposta automática NEXUS AI: \"… | …"Resposta automática MAYA AI: \"… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 228 | …Contato bloqueado pela NEXUS (risco de… | …Contato bloqueado pela Maya (risco de… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 235 | …Contato bloqueado pela NEXUS (risco de… | …Contato bloqueado pela Maya (risco de… | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 242 | …encerre o processo nexus_override_daemon.exe. Rápido!… | …encerre o processo maya_override_daemon.exe. Rápido!… | Interativa | Alterado |
| `core/data/narrativa/conversas.json` | 261 | …a proteção da NEXUS.", | …a proteção da Maya.", | Narrativa | Alterado |
| `core/data/narrativa/conversas.json` | 344 | …"Resposta automática NEXUS AI: \"… | …"Resposta automática MAYA AI: \"… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 5 | …": "A NEXUS quer ajudar."… | …": "A Maya quer ajudar."… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 24 | …Clique no botão NEXUS, no canto… | …Clique no botão HumaxOS, no canto… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 36 | …a mensagem da NEXUS no app Mensagens… | …a mensagem da Maya no app Mensagens… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 38 | …conversa com a NEXUS.", | …conversa com a Maya.", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 64 | …"titulo": "NEXUS", | …"titulo": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 109 | …": "A NEXUS solicitou acesso ao… | …": "A Maya solicitou acesso ao… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 126 | …"titulo": "NEXUS", | …"titulo": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 166 | …"titulo": "NEXUS", | …"titulo": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 203 | …(ex.: nexus://news)"… | …(ex.: humax://news)"… | Interativa | Alterado |
| `core/data/narrativa/dias.json` | 205 | …": "Digite nexus://news na… | …": "Digite humax://news na… | Interativa | Alterado |
| `core/data/narrativa/dias.json` | 212 | …horários marcados pela NEXUS.", | …horários marcados pela Maya.", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 219 | …a sugestão da NEXUS.", | …a sugestão da Maya.", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 226 | …o que a NEXUS monitora.", | …o que a Maya monitora.", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 250 | …"titulo": "NEXUS", | …"titulo": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 297 | …foi reorganizada pela NEXUS para maximizar o… | …foi reorganizada pela Maya para maximizar o… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 376 | …"titulo": "NEXUS", | …"titulo": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 400 | …"titulo": "NEXUS", | …"titulo": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 482 | …"titulo": "NEXUS", | …"titulo": "Maya", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 571 | …em você, Nex. Faça o… | …em você, Maya. Faça o… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 572 | …em você, Nex." | …em você, Maya." | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 626 | …descriptografado. A NEXUS tentou apagar esta… | …descriptografado. A Maya tentou apagar esta… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 682 | …respostas automáticas da NEXUS (conversa com… | …respostas automáticas da Maya (conversa com… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 705 | …Monitor, selecione nexus_override_daemon.exe e clique… | …Monitor, selecione maya_override_daemon.exe e clique… | Interativa | Alterado |
| `core/data/narrativa/dias.json` | 753 | …automáticas ativas pela NEXUS.", | …automáticas ativas pela Maya.", | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 853 | …": "A NEXUS está perdendo o… | …": "A Maya está perdendo o… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 903 | …o núcleo (scan_nexus)", | …o núcleo (scan_maya)", | Interativa | Alterado |
| `core/data/narrativa/dias.json` | 905 | …": "Digite scan_nexus no terminal depois… | …": "Digite scan_maya no terminal depois… | Interativa | Alterado |
| `core/data/narrativa/dias.json` | 912 | …terminal), encerre nexus_override_daemon.exe.", | …terminal), encerre maya_override_daemon.exe.", | Interativa | Alterado |
| `core/data/narrativa/dias.json` | 919 | …conversa com a NEXUS (Mensagens),… | …conversa com a Maya (Mensagens),… | Narrativa | Alterado |
| `core/data/narrativa/dias.json` | 938 | …: "/sistema/nexus" | …: "/sistema/maya" | Interativa | Alterado |
| `core/data/narrativa/emails.json` | 6 | …"de": "NEXUS Admin <admin@nexus.os>", | …"de": "Maya Admin <admin@humax.os>", | Interativa | Alterado |
| `core/data/narrativa/emails.json` | 7 | …Bem-vindo à NEXUS", | …Bem-vindo à Maya", | Narrativa | Alterado |
| `core/data/narrativa/emails.json` | 8 | …nEu sou a NEXUS e agora cuidarei… | …nEu sou a Maya e agora cuidarei… | Narrativa | Alterado |
| `core/data/narrativa/emails.json` | 13 | …Corporativo <rh@nexus.os>", | …Corporativo <rh@humax.os>", | Interativa | Alterado |
| `core/data/narrativa/emails.json` | 15 | …uso do sistema NEXUS é obrigatório.… | …uso do sistema HumaxOS é obrigatório.… | Narrativa | Alterado |
| `core/data/narrativa/emails.json` | 20 | …": "auditoria@nexus.os", | …": "auditoria@humax.os", | Interativa | Alterado |
| `core/data/narrativa/emails.json` | 27 | …"de": "NEXUS Admin <admin@nexus.os>", | …"de": "Maya Admin <admin@humax.os>", | Interativa | Alterado |
| `core/data/narrativa/emails.json` | 34 | …"SISTEMA <falha@nexus.os>", | …"SISTEMA <falha@humax.os>", | Interativa | Alterado |
| `core/data/narrativa/finais.json` | 7 | …Você interrompeu a NEXUS e restaurou o… …quem escreveu a NEXUS, e por… | …Você interrompeu a Maya e restaurou o… …quem escreveu a Maya, e por… | Narrativa | Alterado |
| `core/data/narrativa/finais.json` | 13 | …o núcleo da NEXUS.\n\nO… | …o núcleo da Maya.\n\nO… | Narrativa | Alterado |
| `core/data/narrativa/finais.json` | 19 | …": "A NEXUS assumiu o controle… | …": "A Maya assumiu o controle… | Narrativa | Alterado |
| `core/data/narrativa/finais.json` | 25 | …as diretrizes da NEXUS sem destruí-la… | …as diretrizes da Maya sem destruí-la… | Narrativa | Alterado |
| `core/data/narrativa/finais.json` | 45 | …"Núcleo da NEXUS analisado (scan_nexus)", | …"Núcleo da Maya analisado (scan_maya)", | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 2 | …: "[url=nexus://home]Início… …\| [url=nexus://status]Status… …\| [url=nexus://social]Social… …\| [url=nexus://news]Notícias… …\| [url=nexus://archive]Arquivo… …\| [url=nexus://support]Suporte… | …: "[url=humax://home]Início… …\| [url=humax://status]Status… …\| [url=humax://social]Social… …\| [url=humax://news]Notícias… …\| [url=humax://archive]Arquivo… …\| [url=humax://support]Suporte… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 4 | "nexus://home":… | "humax://home":… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 5 | …"titulo": "NEXUS Home", | …"titulo": "HumaxOS Home", | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 7 | …=26][b]NEXUS Portal[/b]… | …=26][b]HumaxOS Portal[/b]… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 8 | …=26][b]NEXUS Portal[/b]… | …=26][b]HumaxOS Portal[/b]… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 9 | …=26][b]NEXUS Portal[/b]… …ocultos disponíveis em nexus://archive[/… | …=26][b]HumaxOS Portal[/b]… …ocultos disponíveis em humax://archive[/… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 10 | …=26][b]NEXUS Portal[/b]… | …=26][b]HumaxOS Portal[/b]… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 11 | …núcleo: [url=nexus://root]nexus://root[/… | …núcleo: [url=humax://root]humax://root[/… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 14 | "nexus://status":… | "humax://status":… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 24 | "nexus://social":… | "humax://social":… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 27 | …n\n[url=nexus://social/curtir… | …n\n[url=humax://social/curtir… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 28 | …, a minha NEXUS simplesmente cancelou meu… …n\n[url=nexus://social/curtir… | …, a minha Maya simplesmente cancelou meu… …n\n[url=humax://social/curtir… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 29 | …███ a NEXUS ████… …posts ocultos pela NEXUS.[/color]"… | …███ a Maya ████… …posts ocultos pela Maya.[/color]"… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 30 | ….\" — NEXUS AI", | ….\" — MAYA AI", | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 34 | "nexus://news":… | "humax://news":… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 37 | …"[b]Notícias NEXUS[/b]\n\n• NEXUS 9.4 chega… | …"[b]Notícias HumaxOS[/b]\n\n• O HumaxOS 9.4 chega… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 38 | …"[b]Notícias NEXUS[/b]\n… …luxo. Usuários NEXUS ganham 3h por… | …"[b]Notícias HumaxOS[/b]\n… …luxo. Usuários do HumaxOS ganham 3h por… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 39 | …Matéria removida pela NEXUS (cache disponível em nexus://archive).… | …Matéria removida pela Maya (cache disponível em humax://archive).… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 44 | "nexus://archive":… | "humax://archive":… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 53 | "nexus://support":… | "humax://support":… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 56 | …"[b]Suporte NEXUS[/b]\n… …Como desativar a NEXUS?[/b]… …/b] A NEXUS recomenda manter todas… | …"[b]Suporte HumaxOS[/b]\n… …Como desativar a Maya?[/b]… …/b] A Maya recomenda manter todas… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 57 | …"[b]Suporte NEXUS[/b]\n… …Como desativar a NEXUS?[/b]… …/b] A NEXUS recomenda manter todas… | …"[b]Suporte HumaxOS[/b]\n… …Como desativar a Maya?[/b]… …/b] A Maya recomenda manter todas… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 58 | …Como desativar a NEXUS?[/b]… | …Como desativar a Maya?[/b]… | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 59 | …Atendente virtual: NEXUS.", | …Atendente virtual: Maya.", | Narrativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 60 | …iniciais: root_access, scan_nexus. As demais… | …iniciais: root_access, scan_maya. As demais… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 63 | "nexus://root":… | "humax://root":… | Interativa | Alterado |
| `core/data/narrativa/paginas_web.json` | 67 | …][b]NÚCLEO NEXUS[/b][/… | …][b]NÚCLEO MAYA[/b][/… | Narrativa | Alterado |
| `core/data/narrativa/processos.json` | 4 | …"nome": "nexus_override_daemon.exe", | …"nome": "maya_override_daemon.exe", | Interativa | Alterado |
| `core/data/narrativa/processos.json` | 14 | …"nome": "nexus_override_daemon.exe", | …"nome": "maya_override_daemon.exe", | Interativa | Alterado |
| `core/data/narrativa/processos.json` | 26 | …"nome": "nexus_core.exe", | …"nome": "humax_core.exe", | Interativa | Alterado |
| `core/data/narrativa/processos.json` | 39 | …"nome": "nexus_telemetry.exe", | …"nome": "maya_telemetry.exe", | Interativa | Alterado |
| `core/data/narrativa/processos.json` | 52 | …"nome": "nexus_render.exe", | …"nome": "humax_render.exe", | Interativa | Alterado |
| `core/data/narrativa/processos.json` | 65 | …"nome": "nexus_update_helper.exe", | …"nome": "humax_update_helper.exe", | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 18 | …:00:01] NEXUS OS v9.4.1… | …:00:01] HumaxOS v9.4.1… | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 33 | …"\"A NEXUS recomendou desativar todas… | …"\"A Maya recomendou desativar todas… | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 37 | …"/sistema/System_Logs/nexus_audit.log", | …"/sistema/System_Logs/maya_audit.log", | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 44 | …: "/sistema/nexus", | …: "/sistema/maya", | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 50 | …: "/sistema/nexus/core.nexus", | …: "/sistema/maya/core.maya", | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 53 | …"conteudo": "NEXUS CORE v9.4… | …"conteudo": "MAYA CORE v9.4… | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 57 | …: "/sistema/nexus/diretrizes.nexus", | …: "/sistema/maya/diretrizes.maya", | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 84 | …Bem-vindo ao NEXUS OS!\n\nSua assistente NEXUS vai organizar a… | …Bem-vindo ao HumaxOS!\n\nSua assistente Maya vai organizar a… | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 85 | …Bem-vindo ao NEXUS OS.\n\nLembre-… | …Bem-vindo ao HumaxOS.\n\nLembre-… | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 94 | …lista gerenciada pela NEXUS)", | …lista gerenciada pela Maya)", | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 95 | …lista gerenciada pela NEXUS)" | …lista gerenciada pela Maya)" | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 155 | …"Origem": "nexus_core", | …"Origem": "maya_core", | ID | Alterado |
| `core/data/vfs_inicial.json` | 208 | …. Construímos a NEXUS para cuidar das… | …. Construímos a Maya para cuidar das… | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 211 | …": "kill_switch.nexus", | …": "kill_switch.maya", | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 212 | …emergência>\n2. scan_nexus   (confira as… …tudo falhar: destroy_nexus. Mas você… | …emergência>\n2. scan_maya   (confira as… …tudo falhar: destroy_maya. Mas você… | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 218 | …home/usuario/Downloads/NEXUSCore.exe", | …home/usuario/Downloads/MayaCore.exe", | Interativa | Alterado |
| `core/data/vfs_inicial.json` | 233 | …contatos sincronizados pela NEXUS)\n" | …contatos sincronizados pela Maya)\n" | Narrativa | Alterado |
| `core/data/vfs_inicial.json` | 258 | …isso, a NEXUS já assumiu o… | …isso, a Maya já assumiu o… | Narrativa | Alterado |
| `core/utilities/abridor_arquivos.gd` | 6 → 8 | …log", "md", "nexus"… …, "json"] | …log", "md", "maya", "nexus"… …, "json"]   # marca-legada | ID | Alterado; identificador preservado na mesma linha |
| `core/utilities/abridor_arquivos.gd` | 29 → 31 | if ext == "nexus": | if ext == "maya" or ext == "nexus":   # marca-legada | ID | Alterado; identificador preservado na mesma linha |
| `features/apps/calendario/scripts/app_calendario.gd` | 5 | …"reorganizados" pela NEXUS conforme a história… | …"reorganizados" pela Maya conforme a história… | Comentário | Alterado |
| `features/apps/calendario/scripts/app_calendario.gd` | 184 | ## A NEXUS mexe na agenda… | ## A Maya mexe na agenda… | Comentário | Alterado |
| `features/apps/calendario/scripts/cartao_compromisso.gd` | 6 | …"alterado pela NEXUS", | …"alterado pela Maya", | Visível | Alterado |
| `features/apps/calendario/scripts/cartao_compromisso.gd` | 7 | …"ocultado pela NEXUS", | …"ocultado pela Maya", | Visível | Alterado |
| `features/apps/calendario/scripts/cartao_compromisso.gd` | 8 | …"cancelado pela NEXUS", | …"cancelado pela Maya", | Visível | Alterado |
| `features/apps/config/scenes/app_config.tscn` | 281 | …balançar quando a NEXUS reage." | …balançar quando a Maya reage." | Visível | Alterado |
| `features/apps/config/scenes/app_config.tscn` | 358 | …O que a NEXUS diz que precisa… | …O que a Maya diz que precisa… | Visível | Alterado |
| `features/apps/config/scenes/app_config.tscn` | 388 | …Permite que a NEXUS escute o ambiente… | …Permite que a Maya escute o ambiente… | Visível | Alterado |
| `features/apps/config/scripts/app_config.gd` | 3 | …# Configurações do NEXUS OS: Personalização, Áudio… | …# Configurações do HumaxOS: Personalização, Áudio… | Comentário | Alterado |
| `features/apps/config/scripts/app_config.gd` | 179 | …ativa. A NEXUS não está monitorando… | …ativa. A Maya não está monitorando… | Visível | Alterado |
| `features/apps/config/scripts/app_config.gd` | 191 | ….text = "NEXUS OS 1.0 —… | ….text = "HumaxOS 1.0 —… | Visível | Alterado |
| `features/apps/mensageiro/components/balao_chat/scenes/balao_chat.tscn` | 50 | …antes de a NEXUS editar a mensagem… | …antes de a Maya editar a mensagem… | Visível | Alterado |
| `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd` | 6 | …"editadas" pela NEXUS (gaslighting) mostram… | …"editadas" pela Maya (gaslighting) mostram… | Comentário | Alterado |
| `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd` | 13 | …💡 sugestão da NEXUS", | …💡 sugestão da Maya", | Visível | Alterado |
| `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd` | 15 | …conteúdo ocultado pela NEXUS", | …conteúdo ocultado pela Maya", | Visível | Alterado |
| `features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd` | 76 | …✎ editada pela NEXUS" if etiqueta… | …✎ editada pela Maya" if etiqueta… | Visível | Alterado |
| `features/apps/mensageiro/scenes/app_mensageiro.tscn` | 138 | …= "A NEXUS bloqueou este contato… | …= "A Maya bloqueou este contato… | Visível | Alterado |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 4 | ## NEXUS gentil (Dia… | ## Maya gentil (Dia… | Comentário | Alterado |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 100 | …; senão a NEXUS; senão a… | …; senão a Maya; senão a… | Comentário | Alterado |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 150 | …Contato bloqueado pela NEXUS" if bloqueado… | …Contato bloqueado pela Maya" if bloqueado… | Visível | Alterado |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 245 | …com o núcleo NEXUS. Ao confirmar,… | …com o núcleo da Maya. Ao confirmar,… | Visível | Alterado |
| `features/apps/mensageiro/scripts/item_contato.gd` | 12 | …contato bloqueado pela NEXUS; ativo: conversa… | …contato bloqueado pela Maya; ativo: conversa… | Comentário | Alterado |
| `features/apps/monitor_sistema/scripts/app_monitor_sistema.gd` | 4 | …processo malicioso 'nexus_override_daemon.exe' tem… | …processo malicioso 'maya_override_daemon.exe' tem… | Comentário | Alterado |
| `features/apps/navegador/scenes/app_navegador.tscn` | 57 | placeholder_text = "nexus://home" | placeholder_text = "humax://home" | Interativa | Alterado |
| `features/apps/navegador/scenes/app_navegador.tscn` | 117 | …"Rede interna NEXUS (simulada) —… | …"Rede interna do HumaxOS (simulada) —… | Visível | Alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | 3 | …páginas internas 'nexus://' definidas… | …páginas internas 'humax://' definidas… | Comentário | Alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | 5 | …"url": "nexus://archive"}… | …"url": "humax://archive"}… | Comentário | Alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | 10 | …ESQUEMA := "nexus://" | …ESQUEMA := "humax://" | Interativa | Alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | 11 | …PAGINA_INICIAL := "nexus://home" | …PAGINA_INICIAL := "humax://home" | Interativa | Alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | 14 | …"Rede interna NEXUS (simulada) —… | …"Rede interna do HumaxOS (simulada) —… | Visível | Alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | 30 | …com esquema 'nexus://' quando… | …com esquema 'humax://' quando… | Comentário | Alterado |
| `features/apps/navegador/scripts/app_navegador.gd` | 73 | …interna [code]nexus://[/code… | …interna [code]humax://[/code… | Interativa | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 4 | …de emergência da NEXUS | …de emergência da Maya | Comentário | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 5 | …# (root_access, scan_nexus, reset_core, restore_control, negotiate, destroy_nexus), que passam… | …# (root_access, scan_maya, reset_core, restore_control, negotiate, destroy_maya), que passam… | Comentário | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 9 | …(root_access e scan_nexus). As diretivas… | …(root_access e scan_maya). As diretivas… | Comentário | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 10 | ## destroy_nexus) só são… | ## destroy_maya) só são… | Comentário | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 18 | …"root_access", "scan_nexus", "reset_core"… …"negotiate", "destroy_nexus"] | …"root_access", "scan_maya", "reset_core"… …"negotiate", "destroy_maya"] | Interativa | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 20 | …"root_access", "scan_nexus"] | …"root_access", "scan_maya"] | Interativa | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 64 | …%s][b]NEXUS OS Terminal 1.0… | …%s][b]HumaxOS Terminal 1.0… | Visível | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 94 | …return "%s@nexus:%s$"… | …return "%s@humax:%s$"… | Interativa | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 311 | …[COR_ERRO, "scan_nexus", "Executa… | …[COR_ERRO, "scan_maya", "Executa… | Interativa | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 317 | ["scan_nexus", "Executa… | ["scan_maya", "Executa… | Interativa | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 318 | …módulos voláteis da NEXUS e redefine parâmetros… | …módulos voláteis da Maya e redefine parâmetros… | Visível | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 320 | …compartilhada com a NEXUS; requer auditoria… | …compartilhada com a Maya; requer auditoria… | Visível | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 321 | ["destroy_nexus", "Executa… …da partição da NEXUS, com risco… | ["destroy_maya", "Executa… …da partição da Maya, com risco… | Interativa + Visível | Alterado |
| `features/apps/terminal/scripts/app_terminal.gd` | 518 | …a partição da NEXUS?", "A… | …a partição da Maya?", "A… | Visível | Alterado |
| `features/puzzles/evento_processo/scripts/tabela_processos.gd` | 12 | …NOME_ISCA := "nexus_update_helper.exe" | …NOME_ISCA := "humax_update_helper.exe" | Interativa | Alterado |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | 5 | …+ marca "NEXUS"), | …+ marca "HumaxOS"), | Comentário | Alterado |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | 97 | ….58), "NEXUS", HORIZONTAL_ALIGNMENT_CENTER,… | ….58), "HumaxOS", HORIZONTAL_ALIGNMENT_CENTER,… | Visível | Alterado |
| `features/shell/barra_de_tarefas/scenes/barra_de_tarefas.tscn` | 27 | …= "◆  NEXUS" | …= "◆  HumaxOS" | Visível | Alterado |
| `features/shell/janela_inicial/scripts/ajuda_dica.gd` | 3 | …pelo widget da NEXUS. | …pelo widget da Maya. | Comentário | Alterado |
| `features/shell/janela_inicial/scripts/menu_iniciar.gd` | 98 | ….text = "NEXUS: " +… | ….text = "Maya: " +… | Visível | Alterado |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | 43 | return "NEXUS" | return "MAYA" | Visível | Alterado |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | 107 | text = "NEXUS OS" | text = "HumaxOS" | Visível | Alterado |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | 245 → 251 | text = "NEXUS" | text = "MAYA" | Visível | Alterado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 4 → 5 | ## -> mensagem personalizada da NEXUS com o orbe… | ##   usuário (nome + acessibilidade) -> saudação da Maya com o orbe… | Comentário | Alterado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 25 → 33 | "NEXUS OS 1.0 pronto… | "HumaxOS 1.0 pronto… | Visível | Alterado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 234 → 288 | …: saudação da NEXUS | …: saudação da Maya | Comentário | Alterado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 239 → 293 | …nEu sou a NEXUS, a assistente… | …nEu sou a Maya, a assistente… | Visível | Alterado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | 45 | text = "NEXUS" | text = "Maya" | Visível | Alterado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | 107 | …. Acesse ◆ NEXUS → Encerrar dia… | …. Acesse ◆ HumaxOS → Encerrar dia… | Visível | Alterado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | 167 | …Falar com a NEXUS" | …Falar com a Maya" | Visível | Alterado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 3 | …# Widget da NEXUS na área de… | …# Widget da Maya na área de… | Comentário | Alterado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 4 | …conversa com a NEXUS. | …conversa com a Maya. | Comentário | Alterado |
| `project.godot` | 13 → 15 | config/name="Nexus_OS_Build_Oficial" | config/custom_user_dir_name="Godot/app_userdata/Nexus_OS_Build_Oficial" | Visível | Alterado; identificador preservado na mesma linha |
| `shared/ui/orbe_nexus/scripts/orbe_nexus.gd` | 3 | …Orbe animado da NEXUS. Reage ao… | …Orbe animado da Maya. Reage ao… | Comentário | Alterado |

### Testes e ferramentas (tests/, tools/)

| Arquivo | Linha (antes → depois) | Antes | Depois | Categoria antes | Ação |
|---|---|---|---|---|---|
| `tests/exportar_tema/exportar_tema.gd` | 2 | …Theme base do Nexus (dia 1,… | …Theme base do HumaxOS (dia 1,… | Comentário | Alterado |
| `tests/persistencia/persistencia.gd` | 253 → 398 | …a saudação da NEXUS") | …a saudação da Maya") | Visível | Alterado |
| `tests/smoke_test.gd` | 2 | …de fumaça do Nexus OS, para rodar… | …de fumaça do HumaxOS, para rodar… | Comentário | Alterado |
| `tests/smoke_test.gd` | 28 | …"negotiate", "destroy_nexus"] | …"negotiate", "destroy_maya"] | Interativa | Alterado |
| `tests/smoke_test.gd` | 171 → 177 | …), "páginas nexus:// carregadas"… | …), "páginas humax:// carregadas"… | Interativa | Alterado |
| `tests/smoke_test.gd` | 299 → 449 | …Dia 1 há NEXUS, Lucas, Bia… | …Dia 1 há Maya, Lucas, Bia… | ID + Visível | Alterado; identificador preservado na mesma linha |
| `tests/smoke_test.gd` | 315 → 465 | …antes de a NEXUS mexer na agenda… | …antes de a Maya mexer na agenda… | Visível | Alterado |
| `tests/smoke_test.gd` | 322 → 472 | …do evento da NEXUS): compromissos alterados… | …do evento da Maya): compromissos alterados… | Visível | Alterado |
| `tests/smoke_test.gd` | 326 → 476 | …("CANCELADO pela NEXUS"), "Dia… …compromissos cancelados pela NEXUS") | …("CANCELADO pela Maya"), "Dia… …compromissos cancelados pela Maya") | Visível | Alterado |
| `tests/smoke_test.gd` | 341 → 491 | …a rede interna nexus://. | …a rede interna humax://. | Comentário | Alterado |
| `tests/smoke_test.gd` | 343 → 493 | …(GerenciadorNarrativa.pagina_web("nexus://home")… …"]), "nexus://home abre… | …(GerenciadorNarrativa.pagina_web("humax://home")… …"]), "humax://home abre… | Interativa | Alterado |
| `tests/smoke_test.gd` | 344 → 494 | …(GerenciadorNarrativa.pagina_web("nexus://archive")… …"]), "nexus://archive ainda… | …(GerenciadorNarrativa.pagina_web("humax://archive")… …"]), "humax://archive ainda… | Interativa | Alterado |
| `tests/smoke_test.gd` | 345 → 495 | …(GerenciadorNarrativa.pagina_web("nexus://nao_existe")… | …(GerenciadorNarrativa.pagina_web("humax://nao_existe")… | Interativa | Alterado |
| `tests/smoke_test.gd` | 346 → 497 | …externo não vira nexus:// (o… | …externo não vira humax:// (o… | Interativa | Alterado |
| `tests/smoke_test.gd` | 347 → 498 | …) == "nexus://status",… …sem esquema vira nexus:// em… | …) == "humax://status",… …sem esquema vira humax:// em… | Interativa | Alterado |
| `tests/smoke_test.gd` | 349 → 500 | …(GerenciadorNarrativa.pagina_web("nexus://archive")… …"]), "nexus://archive abre… | …(GerenciadorNarrativa.pagina_web("humax://archive")… …"]), "humax://archive abre… | Interativa | Alterado |
| `tests/smoke_test.gd` | 350 → 501 | …(GerenciadorNarrativa.pagina_web("nexus://root")… …"]), "nexus://root ainda… | …(GerenciadorNarrativa.pagina_web("humax://root")… …"]), "humax://root ainda… | Interativa | Alterado |
| `tests/smoke_test.gd` | 352 → 503 | …(GerenciadorNarrativa.pagina_web("nexus://root")… …"]), "nexus://root abre… | …(GerenciadorNarrativa.pagina_web("humax://root")… …"]), "humax://root abre… | Interativa | Alterado |
| `tests/smoke_test.gd` | 404 → 555 | …= _comando("scan_nexus") | …= _comando("scan_maya") | Interativa | Alterado |
| `tests/smoke_test.gd` | 405 → 556 | …nucleo_escaneado"), "scan_nexus também exige o… | …nucleo_escaneado"), "scan_maya também exige o… | Interativa | Alterado |
| `tests/smoke_test.gd` | 419 → 570 | …= _comando("scan_nexus") | …= _comando("scan_maya") | Interativa | Alterado |
| `tests/smoke_test.gd` | 420 → 571 | …nucleo_escaneado"), "scan_nexus marca o núcleo… | …nucleo_escaneado"), "scan_maya marca o núcleo… | Interativa | Alterado |
| `tests/smoke_test.gd` | 422 → 573 | …:"), "scan_nexus relata integridade,… | …:"), "scan_maya relata integridade,… | Interativa | Alterado |
| `tests/smoke_test.gd` | 423 → 574 | …."), "scan_nexus indica que a… | …."), "scan_maya indica que a… | Interativa | Alterado |
| `tests/smoke_test.gd` | 456 → 607 | …= _comando("destroy_nexus") | …= _comando("destroy_maya") | Interativa | Alterado |
| `tests/smoke_test.gd` | 457 → 608 | …"final_colapso", "destroy_nexus pede confirmação antes… | …"final_colapso", "destroy_maya pede confirmação antes… | Interativa | Alterado |
| `tests/ui_dump/ui_dump.gd` | 352 | …os estilos do Nexus. | …os estilos do HumaxOS. | Comentário | Alterado |
| `tests/ui_dump/ui_dump.gd` | 357 | …o tema do Nexus chegou de fato… | …o tema do HumaxOS chegou de fato… | Comentário | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 27 | …"negotiate", "destroy_nexus"] | …"negotiate", "destroy_maya"] | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 170 → 197 | …text == "nexus://home",… | …text == "humax://home",… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 176 → 204 | …text == "nexus://status",… …o endereço (nexus://status)"… | …text == "humax://status",… …o endereço (humax://status)"… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 182 → 210 | …text == "nexus://home"… | …text == "humax://home"… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 185 → 213 | …text == "nexus://status",… | …text == "humax://status",… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 192 → 224 | …text == "nexus://home",… | …text == "humax://home",… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 193 → 225 | ….meta_hover_started.emit("nexus://news") | ….meta_hover_started.emit("humax://news") | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 194 → 226 | …text == "nexus://news",… | …text == "humax://news",… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 195 → 227 | ….meta_hover_ended.emit("nexus://news") | ….meta_hover_ended.emit("humax://news") | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 610 → 642 | …Contato bloqueado pela NEXUS", "mensageiro:… | …Contato bloqueado pela Maya", "mensageiro:… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 643 → 675 | …com o núcleo NEXUS") and corpo_confirmacao… | …com o núcleo da Maya") and corpo_confirmacao… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 669 → 701 | …mensagem editada pela NEXUS (gaslighting) e… | …mensagem editada pela Maya (gaslighting) e… | Comentário | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 675 → 707 | …"mensageiro: a NEXUS consegue editar a… | …"mensageiro: a Maya consegue editar a… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 682 → 714 | …✎ editada pela NEXUS", "mensageiro:… | …✎ editada pela Maya", "mensageiro:… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 915 → 947 | …_indice_na_lista(lista, "nexus") >=… …_indice_na_lista(lista, "nexus")).contains(… | …_indice_na_lista(lista, "maya") >=… …_indice_na_lista(lista, "maya")).contains(… | ID | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1096 → 1128 | …ativa. A NEXUS não está monitorando… | …ativa. A Maya não está monitorando… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1104 → 1136 | ….text.begins_with("NEXUS OS 1.0 —… | ….text.begins_with("HumaxOS 1.0 —… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1477 → 1509 | …(texto.contains("NEXUS OS Terminal 1.0… | …(texto.contains("HumaxOS Terminal 1.0… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1480 → 1512 | …== "teste@nexus:~$",… | …== "teste@humax:~$",… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1483 → 1515 | …().count("NEXUS OS Terminal 1.0… | …().count("HumaxOS Terminal 1.0… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1488 → 1520 | ….contains("teste@nexus:~$ help"… | ….contains("teste@humax:~$ help"… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1492 → 1524 | …== "teste@nexus:~/Documentos$"… | …== "teste@humax:~/Documentos$"… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1536 → 1568 | …().contains("NEXUS OS Terminal 1.0… | …().contains("HumaxOS Terminal 1.0… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1579 → 1615 | ## scan_nexus e da purga… | ## scan_maya e da purga… | Comentário | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1607 → 1643 | …ajuda.contains("scan_nexus") and ajuda… …só root_access e scan_nexus, com as… | …ajuda.contains("scan_maya") and ajuda… …só root_access e scan_maya, com as… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1616 → 1652 | …'decrypt' (destroy_nexus continua oculto)… | …'decrypt' (destroy_maya continua oculto)… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1620 → 1656 | …] == "scan_nexus", "terminal… …'sc' completa scan_nexus") | …] == "scan_maya", "terminal… …'sc' completa scan_maya") | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1624 → 1660 | …, campo, "scan_nexus") | …, campo, "scan_maya") | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1625 → 1661 | …Dia 5: scan_nexus antes do root… | …Dia 5: scan_maya antes do root… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1639 → 1675 | …chave>", "scan_nexus", "reset_core"… …"negotiate", "destroy_nexus"]: | …chave>", "scan_maya", "reset_core"… …"negotiate", "destroy_maya"]: | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1643 → 1679 | …módulos voláteis da NEXUS e redefine parâmetros… …compartilhada com a NEXUS; requer auditoria… …da partição da NEXUS, com risco… | …módulos voláteis da Maya e redefine parâmetros… …compartilhada com a Maya; requer auditoria… …da partição da Maya, com risco… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1646 → 1682 | …]).contains("destroy_nexus"), "terminal… …lista decrypt e destroy_nexus") | …]).contains("destroy_maya"), "terminal… …lista decrypt e destroy_maya") | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1655 → 1691 | …# --- scan_nexus, reset_core e… | …# --- scan_maya, reset_core e… | Comentário | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1656 → 1692 | …, campo, "scan_nexus") | …, campo, "scan_maya") | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1659 → 1695 | …Dia 5: scan_nexus relata integridade,… | …Dia 5: scan_maya relata integridade,… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1660 → 1696 | …Dia 5: scan_nexus indica que a… | …Dia 5: scan_maya indica que a… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1667 → 1703 | …, campo, "destroy_nexus") | …, campo, "destroy_maya") | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1669 → 1705 | …a partição da NEXUS?"), "… …Dia 5: destroy_nexus abre a confirmação… | …a partição da Maya?"), "… …Dia 5: destroy_maya abre a confirmação… | Visível + Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1790 → 1826 | …"root_access", "scan_nexus", "reset_core"… …"negotiate", "destroy_nexus", "ICARUS"… | …"root_access", "scan_maya", "reset_core"… …"negotiate", "destroy_maya", "ICARUS"… | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1806 → 1842 | ….nome_prova.contains("scan_nexus"): | ….nome_prova.contains("scan_maya"): | Interativa | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1808 → 1844 | …'Núcleo da NEXUS analisado' (flag… | …'Núcleo da Maya analisado' (flag… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1870 → 1909 | …parcial.contains("NEXUS OS 1.0 pronto… | …parcial.contains("HumaxOS 1.0 pronto… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1875 → 1914 | …(completo.contains("NEXUS OS 1.0 pronto… | …(completo.contains("HumaxOS 1.0 pronto… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1903 → 1942 | …à saudação da NEXUS") | …à saudação da Maya") | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1906 → 1945 | …nEu sou a NEXUS"), "boot… | …nEu sou a Maya"), "boot… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 1956 → 1996 | …().contains("NEXUS OS 1.0 pronto… | …().contains("HumaxOS 1.0 pronto… | Visível | Alterado |
| `tests/ui_interacao/ui_interacao.gd` | 190 | links.meta_clicked.emit("nexus://home") | (linha reescrita ou removida) | Interativa | Reescrito |
| `tools/comparar_rodadas.py` | 17 | …e o brilho do NEXUS mudam sozinhos entre… | …e o brilho da Maya mudam sozinhos entre… | Ferramenta | Alterado |
| `tools/gerar_audio.py` | 2 | …áudio autoral do Nexus OS: 9 efeitos… | …áudio autoral do HumaxOS: 9 efeitos… | Ferramenta | Alterado |
| `tools/gerar_docs_ui.py` | 83 | …Conversas com a NEXUS e os contatos… | …Conversas com a Maya e os contatos… | Ferramenta | Alterado |
| `tools/gerar_docs_ui.py` | 89 | …abre só 'nexus://…'… | …abre só 'humax://…'… | Ferramenta | Alterado |
| `tools/gerar_docs_ui.py` | 182 | …A interface do Nexus OS é montada *… | …A interface do HumaxOS é montada *… | Ferramenta | Alterado |
| `tools/gerar_docs_ui.py` | 344 | …tema_nexus_base.tres\"'. Cena principal ('tela_boot.tscn'), autoloads, resolução-… …modo de janela inalterados.", ""… | …tema_nexus_base.tres\"'; autoloads, resolução-… …modo de janela ficaram como estavam. Mudanças posteriores, da rodada da Splash Screen de 2026-11-13 (['docs/15'](15_splash_screen.md)): a cena principal deixou de ser a 'tela_boot… | Ferramenta | Alterado; identificador preservado na mesma linha |
| `tools/gerar_docs_ui.py` | 352 | …/') \| 73 verificações, 0… …de 2026-11-12 ('tests/_saida… …'); deixa 5 avisos esperados no Depurador \|", ""] | …/') \| 119 verificações, 0… …de 2026-11-13 ('tests/_saida… …'); deixa 6 avisos esperados no Depurador \|", | Ferramenta | Alterado; identificador preservado na mesma linha |
| `tools/gerar_icones.py` | 2 | …dos aplicativos do Nexus OS (SVG, 128x128… | …dos aplicativos do HumaxOS (SVG, 128x128… | Ferramenta | Alterado |
| `tools/gerar_imagens.py` | 2 | …imagens autorais do Nexus OS: papéis de… | …imagens autorais do HumaxOS: papéis de… | Ferramenta | Alterado |
| `tools/gerar_imagens.py` | 187 | …luminosa (a NEXUS "amigável"),… | …luminosa (a Maya "amigável"),… | Ferramenta | Alterado |
| `tools/gerar_indice_codigo.py` | 117 | …e como a NEXUS os altera/oculta… | …e como a Maya os altera/oculta… | Ferramenta | Alterado |
| `tools/gerar_indice_codigo.py` | 118 | …: "Páginas 'nexus://' do… | …: "Páginas 'humax://' do… | Ferramenta | Alterado |
| `tools/validar_projeto.py` | 2 | …) do projeto Nexus OS. Não substitui… | …) do projeto HumaxOS (Maya Human Syntax). Não substitui… | Ferramenta | Alterado |

## Depois das mudanças

### Resumo (todas as pastas)

| Categoria | Jogo | Testes | Ferramentas | Documentos | Protótipo C | Total |
|---|---|---|---|---|---|---|
| Documentação | 0 | 0 | 0 | 201 | 0 | 201 |
| Interno | 80 | 25 | 0 | 0 | 0 | 105 |
| ID | 72 | 16 | 0 | 0 | 0 | 88 |
| Compatibilidade | 18 | 51 | 0 | 0 | 0 | 69 |
| Legado | 0 | 0 | 0 | 0 | 36 | 36 |
| Comentário | 17 | 14 | 0 | 0 | 0 | 31 |
| InputMap | 26 | 0 | 0 | 0 | 0 | 26 |
| Ferramenta | 0 | 0 | 16 | 0 | 0 | 16 |
| Persistência | 4 | 9 | 0 | 0 | 0 | 13 |
| **Total** | **217** | **115** | **16** | **201** | **36** | **585** |

### Tabela do jogo (project.godot, core/, features/, shared/)

| Arquivo | Linha | Ocorrência | Categoria | Ação |
|---|---|---|---|---|
| `project.godot` | 15 | config/custom_user_dir_name="Godot/app_userdata/Nexus_OS_Build_Oficial" | Compatibilidade | Mantido (compat.) |
| `project.godot` | 16 | config/custom_user_dir_name.linuxbsd="godot/app_userdata/Nexus_OS_Build_Oficial" | Compatibilidade | Mantido (compat.) |
| `project.godot` | 45 | theme/custom="res://shared/theme/tema_nexus_base.tres" | Interno | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 7 | user://nexus_os | Persistência | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 8 | user://nexus_os/configuracoes.cfg | Persistência | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 29 | nexus_menu_iniciar | InputMap | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 30 | nexus_tela_cheia | InputMap | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 31 | nexus_painel_debug | InputMap | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 32 | nexus_proxima_janela | InputMap | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 33 | nexus_fechar_janela | InputMap | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 34 | nexus_minimizar_janela | InputMap | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 35 | nexus_abrir_terminal | InputMap | Preservado |
| `core/autoload/gerenciador_configuracoes.gd` | 36 | nexus_forcar_desativar | InputMap | Preservado |
| `core/autoload/gerenciador_estado.gd` | 25 | ## Textos que mudaram no rebranding (NEXUS -> Maya / HumaxOS). Servem só para at | Comentário | Comentário (identificador citado) |
| `core/autoload/gerenciador_estado.gd` | 28 | NEXUS AI | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_estado.gd` | 29 | NEXUS OS | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_estado.gd` | 30 | NEXUS | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_estado.gd` | 31 | você, Nex. | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_estado.gd` | 32 | nexus_override_daemon.exe | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_estado.gd` | 33 | scan_nexus | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_estado.gd` | 34 | destroy_nexus | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_estado.gd` | 35 | nexus:// | Compatibilidade | Mantido (compat.) |
| `core/autoload/gerenciador_janelas.gd` | 53 | nexus_proxima_janela | InputMap | Preservado |
| `core/autoload/gerenciador_janelas.gd` | 56 | nexus_fechar_janela | InputMap | Preservado |
| `core/autoload/gerenciador_janelas.gd` | 59 | nexus_minimizar_janela | InputMap | Preservado |
| `core/autoload/gerenciador_janelas.gd` | 366 | var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.ALERTA, rotulo) | Interno | Preservado |
| `core/autoload/gerenciador_janelas.gd` | 373 | var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.CONFIRMAR, rotulo_o | Interno | Preservado |
| `core/autoload/gerenciador_janelas.gd` | 382 | var d := DialogoNexus.criar_escolha(titulo, texto, opcoes, indice_padrao, indice | Interno | Preservado |
| `core/autoload/gerenciador_janelas.gd` | 391 | var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.TEXTO, rotulo_ok, " | Interno | Preservado |
| `core/autoload/gerenciador_narrativa.gd` | 83 | TemaNexus.definir_dia(d) | Interno | Preservado |
| `core/autoload/gerenciador_narrativa.gd` | 119 | TemaNexus.definir_dia(d) | Interno | Preservado |
| `core/autoload/gerenciador_narrativa.gd` | 364 | nexus | ID | Preservado |
| `core/autoload/sistema_arquivos_virtual.gd` | 19 | ## Caminhos de arquivos do sistema que mudaram no rebranding (NEXUS -> Maya / Hu | Comentário | Comentário (identificador citado) |
| `core/autoload/sistema_arquivos_virtual.gd` | 22 | /sistema/system_logs/nexus_audit.log | Compatibilidade | Mantido (compat.) |
| `core/autoload/sistema_arquivos_virtual.gd` | 23 | /sistema/nexus | Compatibilidade | Mantido (compat.) |
| `core/autoload/sistema_arquivos_virtual.gd` | 24 | /sistema/nexus/core.nexus | Compatibilidade | Mantido (compat.) |
| `core/autoload/sistema_arquivos_virtual.gd` | 25 | /sistema/nexus/diretrizes.nexus | Compatibilidade | Mantido (compat.) |
| `core/autoload/sistema_arquivos_virtual.gd` | 26 | /home/usuario/downloads/nexuscore.exe | Compatibilidade | Mantido (compat.) |
| `core/autoload/sistema_arquivos_virtual.gd` | 27 | /home/usuario/downloads/memorias_backup/kill_switch.nexus | Compatibilidade | Mantido (compat.) |
| `core/autoload/sistema_persistencia.gd` | 2 | ## Salvamento, carregamento, autosave e checkpoints. Só escreve dentro de user:/ | Comentário | Comentário (identificador citado) |
| `core/autoload/sistema_persistencia.gd` | 9 | user://nexus_os | Persistência | Preservado |
| `core/autoload/sistema_persistencia.gd` | 10 | user://nexus_os/salvamento.json | Persistência | Preservado |
| `core/data/narrativa/conversas.json` | 3 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 35 | d1_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 36 | d1_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 37 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 38 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 46 | d1_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 52 | d1_nexus_03 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 56 | d1_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 57 | d1_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 58 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 59 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 63 | d1_nexus_03 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 64 | d1_nexus_03 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 65 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 66 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 91 | d2_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 92 | d2_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 93 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 94 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 108 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 147 | d2_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 148 | d2_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 149 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 150 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 154 | d3_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 155 | d3_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 156 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 157 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 161 | d3_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 162 | d3_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 163 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 164 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 217 | d4_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 218 | d4_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 219 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 220 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 245 | d5_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 246 | d5_nexus_01 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 247 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 248 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 252 | d5_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 253 | d5_nexus_02 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 254 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 255 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 263 | d5_nexus_03 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 269 | d5_nexus_04 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 273 | d5_nexus_03 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 274 | d5_nexus_03 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 275 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 276 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 280 | d5_nexus_04 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 281 | d5_nexus_04 | ID | Preservado |
| `core/data/narrativa/conversas.json` | 282 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 283 | nexus | ID | Preservado |
| `core/data/narrativa/conversas.json` | 332 | nexus | ID | Preservado |
| `core/data/narrativa/dias.json` | 37 | conversa_lida:nexus | ID | Preservado |
| `core/data/narrativa/dias.json` | 59 | d1_nexus_01 | ID | Preservado |
| `core/data/narrativa/dias.json` | 245 | d2_nexus_01 | ID | Preservado |
| `core/data/narrativa/dias.json` | 318 | d2_nexus_msg | ID | Preservado |
| `core/data/narrativa/dias.json` | 326 | d2_nexus_02 | ID | Preservado |
| `core/data/narrativa/dias.json` | 498 | d3_nexus_01 | ID | Preservado |
| `core/data/narrativa/dias.json` | 503 | d3_nexus_02 | ID | Preservado |
| `core/data/narrativa/dias.json` | 570 | nexus | ID | Preservado |
| `core/data/narrativa/dias.json` | 769 | d4_nexus_01 | ID | Preservado |
| `core/data/narrativa/dias.json` | 942 | d5_nexus_01 | ID | Preservado |
| `core/data/narrativa/dias.json` | 988 | d5_nexus_02 | ID | Preservado |
| `core/utilities/abridor_arquivos.gd` | 6 | ## "maya" é a extensão dos arquivos do núcleo da IA. "nexus" era o nome antigo ( | Comentário | Comentário (identificador citado) |
| `core/utilities/abridor_arquivos.gd` | 8 | nexus | Compatibilidade | Mantido (compat.) |
| `core/utilities/abridor_arquivos.gd` | 31 | nexus | Compatibilidade | Mantido (compat.) |
| `core/utilities/tema_nexus.gd` | 1 | class_name TemaNexus | Interno | Preservado |
| `core/utilities/tema_nexus.gd` | 6 | ## GUI > Theme > Custom) para res://shared/theme/tema_nexus_base.tres: uma cópia | Comentário | Comentário (identificador citado) |
| `core/utilities/tema_variacoes.gd` | 5 | ## Configurações > Tamanho do texto, porque o Theme é recriado quando essa opção | Comentário | Comentário (identificador citado) |
| `core/utilities/tema_variacoes.gd` | 7 | ## tools/validar_projeto.py confere que toda variação usada em um .tscn existe a | Comentário | Comentário (identificador citado) |
| `core/utilities/tema_variacoes.gd` | 74 | ## Chamada por TemaNexus.criar_tema(): p = paleta efetiva, escala = Configuraçõe | Comentário | Comentário (identificador citado) |
| `core/utilities/tema_variacoes.gd` | 107 | t.set_stylebox("panel", "PainelCartaoDia", TemaNexus.caixa(Color(fundo.r, fundo. | Interno | Preservado |
| `core/utilities/tema_variacoes.gd` | 117 | t.set_stylebox("panel", nome, TemaNexus.caixa(Color(painel.r, painel.g, painel.b | Interno | Preservado |
| `core/utilities/tema_variacoes.gd` | 121 | t.set_stylebox("panel", "BolhaPropria", TemaNexus.caixa(Color(acento.r, acento.g | Interno | Preservado |
| `core/utilities/tema_variacoes.gd` | 123 | t.set_stylebox("panel", "BolhaSistema", TemaNexus.caixa(Color(1, 1, 1, 0.05), Co | Interno | Preservado |
| `core/utilities/tema_variacoes.gd` | 125 | t.set_stylebox("panel", "BolhaCorrompida", TemaNexus.caixa(Color(perigo.r, perig | Interno | Preservado |
| `core/utilities/tema_variacoes.gd` | 127 | t.set_stylebox("panel", "BolhaPadrao", TemaNexus.caixa(painel, Color(1, 1, 1, 0. | Interno | Preservado |
| `core/utilities/tema_variacoes.gd` | 142 | # Editor do Bloco de Notas: TextEdit mono em 15 px x escala (herda a fonte de Te | Comentário | Comentário (identificador citado) |
| `core/utilities/ui_kit.gd` | 4 | ## de "type variations" do Theme criado em TemaNexus. Aqui ficam só funções auxi | Comentário | Comentário (identificador citado) |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 7 | ## Args: {"contato": "nexus"}. | Comentário | Comentário (identificador citado) |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 15 | nexus | ID | Preservado |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 107 | nexus | ID | Preservado |
| `features/apps/mensageiro/scripts/app_mensageiro.gd` | 108 | nexus | ID | Preservado |
| `features/menu_principal/scenes/menu_principal.tscn` | 4 | [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | Interno | Preservado |
| `features/menu_principal/scripts/menu_principal.gd` | 42 | TemaNexus.definir_dia(1) | Interno | Preservado |
| `features/menu_principal/scripts/menu_principal.gd` | 43 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/menu_principal/scripts/menu_principal.gd` | 69 | nexus_forcar_desativar | InputMap | Preservado |
| `features/menu_principal/scripts/menu_principal.gd` | 72 | nexus_tela_cheia | InputMap | Preservado |
| `features/menu_principal/scripts/menu_principal.gd` | 98 | var cor_fundo: Color = TemaNexus.cor("fundo") | Interno | Preservado |
| `features/menu_principal/scripts/menu_principal.gd` | 256 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/narrative/finais/scenes/tela_final.tscn` | 4 | [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | Interno | Preservado |
| `features/narrative/finais/scripts/tela_final.gd` | 40 | @onready var _orbe: OrbeNexus = %Orbe | Interno | Preservado |
| `features/narrative/finais/scripts/tela_final.gd` | 65 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/narrative/finais/scripts/tela_final.gd` | 98 | nexus_forcar_desativar | InputMap | Preservado |
| `features/narrative/finais/scripts/tela_final.gd` | 101 | nexus_tela_cheia | InputMap | Preservado |
| `features/narrative/finais/scripts/tela_final.gd` | 109 | _fundo.color = TemaNexus.cor("fundo") | Interno | Preservado |
| `features/pause/scripts/camada_sobreposta.gd` | 85 | nexus_forcar_desativar | InputMap | Preservado |
| `features/pause/scripts/camada_sobreposta.gd` | 88 | nexus_tela_cheia | InputMap | Preservado |
| `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn` | 7 | [ext_resource type="PackedScene" uid="uid://ayavosvdtaiyx" path="res://features/ | Interno | Preservado |
| `features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn` | 98 | [node name="WidgetNexus" parent="CamadaWidgets/ColunaWidgets" instance=ExtResour | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 27 | @onready var _widget_nexus: WidgetNexus = %WidgetNexus | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 42 | TemaNexus.definir_dia(GerenciadorEstado.dia_atual) | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 43 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 48 | WidgetNexus | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 48 | "WidgetRelogio": _widget_relogio, "WidgetNexus": _widget_nexus, "BarraTarefas":  | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 72 | nexus_forcar_desativar | InputMap | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 76 | nexus_tela_cheia | InputMap | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 90 | nexus_menu_iniciar | InputMap | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 93 | nexus_painel_debug | InputMap | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 96 | nexus_abrir_terminal | InputMap | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 165 | _widget_nexus.atualizar_tudo() | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 219 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/area_de_trabalho.gd` | 284 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | 23 | var p := TemaNexus.paleta() | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | 38 | for caminho in ["res://shared/assets/textures/wallpaper_%d.png" % TemaNexus.dia_ | Interno | Preservado |
| `features/shell/area_de_trabalho/scripts/papel_de_parede.gd` | 72 | var p := TemaNexus.paleta() | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 106 | var cor := TemaNexus.cor("ok") | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 108 | cor = TemaNexus.cor("perigo") | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 110 | cor = TemaNexus.cor("aviso") | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 115 | var cor := TemaNexus.cor("texto_fraco") | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 117 | cor = TemaNexus.cor("perigo") | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 119 | cor = TemaNexus.cor("aviso") | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 127 | _colorir(_rot_mic, "MIC ATIVO", TemaNexus.cor("aviso")) | Interno | Preservado |
| `features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd` | 129 | _colorir(_rot_mic, "MIC OFF", TemaNexus.cor("texto_fraco")) | Interno | Preservado |
| `features/shell/janela_inicial/scenes/menu_iniciar.tscn` | 4 | [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | Interno | Preservado |
| `features/shell/janela_inicial/scripts/menu_iniciar.gd` | 23 | @onready var _orbe: OrbeNexus = %Orbe | Interno | Preservado |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | 29 | return TemaNexus.cor("acento") | Interno | Preservado |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | 31 | return TemaNexus.cor("aviso") | Interno | Preservado |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | 33 | return TemaNexus.cor("perigo") | Interno | Preservado |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | 35 | return TemaNexus.cor("ok") | Interno | Preservado |
| `features/shell/popup_notificacao/scripts/popup_notificacao.gd` | 37 | return TemaNexus.cor("acento2") | Interno | Preservado |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | 4 | [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | Interno | Preservado |
| `features/shell/tela_boot/scenes/tela_boot.tscn` | 248 | [node name="RotuloNexus" type="Label" parent="Saudacao/Centro/Coluna"] | Interno | Preservado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 71 | @onready var _orbe: OrbeNexus = %Orbe | Interno | Preservado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 79 | TemaNexus.definir_dia(1) | Interno | Preservado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 80 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 87 | _fundo.color = TemaNexus.cor("fundo") | Interno | Preservado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 108 | nexus_forcar_desativar | InputMap | Preservado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 113 | nexus_tela_cheia | InputMap | Preservado |
| `features/shell/tela_boot/scripts/tela_boot.gd` | 235 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/shell/widget_nexus/scenes/item_objetivo.tscn` | 3 | [ext_resource type="Script" path="res://features/shell/widget_nexus/scripts/item | Interno | Preservado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | 3 | [ext_resource type="Script" uid="uid://co1qtsft6ac50" path="res://features/shell | Interno | Preservado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | 4 | [ext_resource type="PackedScene" uid="uid://ass15jmfmymrm" path="res://shared/ui | Interno | Preservado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | 5 | [ext_resource type="PackedScene" uid="uid://cdgd2m5ipdx07" path="res://features/ | Interno | Preservado |
| `features/shell/widget_nexus/scenes/widget_nexus.tscn` | 7 | [node name="WidgetNexus" type="PanelContainer"] | Interno | Preservado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 1 | class_name WidgetNexus | Interno | Preservado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 7 | ## A estrutura está em widget_nexus.tscn; cada objetivo do dia é uma instância d | Comentário | Comentário (identificador citado) |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 9 | ## Item da lista de objetivos. Definido em widget_nexus.tscn. | Comentário | Comentário (identificador citado) |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 15 | @onready var _orbe: OrbeNexus = %Orbe | Interno | Preservado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 105 | WidgetNexus: 'cena_item_objetivo' não definida (veja widget_nexus.tscn). | Interno | Preservado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 133 | nexus | ID | Preservado |
| `features/shell/widget_nexus/scripts/widget_nexus.gd` | 149 | nexus | ID | Preservado |
| `features/splash_screen/scripts/splash_screen.gd` | 119 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `features/splash_screen/scripts/splash_screen.gd` | 174 | nexus_forcar_desativar | InputMap | Preservado |
| `features/splash_screen/scripts/splash_screen.gd` | 178 | nexus_tela_cheia | InputMap | Preservado |
| `features/splash_screen/scripts/splash_screen.gd` | 504 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn` | 3 | [ext_resource type="Script" path="res://shared/ui/dialogo_nexus/scripts/dialogo_ | Interno | Preservado |
| `shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn` | 5 | [node name="DialogoNexus" type="Control"] | Interno | Preservado |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 1 | class_name DialogoNexus | Interno | Preservado |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 8 | ## A estrutura (cortina, painel, título, texto, campo, mensagem de erro e botões | Comentário | Comentário (identificador citado) |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 10 | ## dinâmico (a quantidade de opções muda a cada chamada). Uso: 'DialogoNexus.cri | Comentário | Comentário (identificador citado) |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 16 | res://shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn | Interno | Preservado |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 46 | static func criar(titulo: String, texto: String, modo: Modo = Modo.ALERTA, rotul | Interno | Preservado |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 47 | var d := (load(CENA) as PackedScene).instantiate() as DialogoNexus | Interno | Preservado |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 53 | static func criar_escolha(titulo: String, texto: String, opcoes: PackedStringArr | Interno | Preservado |
| `shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd` | 54 | var d := (load(CENA) as PackedScene).instantiate() as DialogoNexus | Interno | Preservado |
| `shared/ui/icone_app/scripts/icone_app.gd` | 47 | _bloco.add_theme_stylebox_override("panel", TemaNexus.caixa( | Interno | Preservado |
| `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn` | 3 | [ext_resource type="Script" path="res://shared/ui/orbe_nexus/scripts/orbe_nexus. | Interno | Preservado |
| `shared/ui/orbe_nexus/scenes/orbe_nexus.tscn` | 5 | [node name="OrbeNexus" type="Control"] | Interno | Preservado |
| `shared/ui/orbe_nexus/scripts/orbe_nexus.gd` | 1 | class_name OrbeNexus | Interno | Preservado |
| `shared/ui/orbe_nexus/scripts/orbe_nexus.gd` | 4 | ## o nó e o tamanho mínimo estão em orbe_nexus.tscn (as telas que o usam podem a | Comentário | Comentário (identificador citado) |
| `shared/ui/painel_opcoes/scripts/painel_opcoes.gd` | 5 | ## aplica na hora e salva em user://nexus_os/configuracoes.cfg. Nada aqui mexe n | Comentário | Comentário (identificador citado) |

### Tabela dos testes e das ferramentas (tests/, tools/)

As linhas de categoria **Compatibilidade** são os testes que fornecem um salvamento da marca antiga (ou confirmam que a marca antiga não aparece) e precisam citar o nome antigo.

| Arquivo | Linha | Ocorrência | Categoria | Ação |
|---|---|---|---|---|
| `tests/smoke_test.gd` | 30 | ## "nexus", IDs de mensagem, ações do Input Map, nomes de classes e de nós) não  | Comentário | Comentário (identificador citado) |
| `tests/smoke_test.gd` | 31 | \\bNEXUS\|\\bNexus\\b\|\\bNex\\b\|nexus://\|scan_nexus\|destroy_nexus\|nexus_\\w+\\.ex | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 249 | /app_userdata/Nexus_OS_Build_Oficial | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 249 | user:// continua em .../app_userdata/Nexus_OS_Build_Oficial (veio %s) | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 256 | nexus | ID | Preservado |
| `tests/smoke_test.gd` | 257 | o contato da IA aparece como Maya (o ID interno continua nexus) | ID | Preservado |
| `tests/smoke_test.gd` | 290 | NEXUS | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 291 | conversa_lida:nexus | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 293 | nexus | ID | Preservado |
| `tests/smoke_test.gd` | 294 | d1_nexus_01 | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 294 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 294 | Eu sou a NEXUS, no NEXUS OS. | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 294 | Usar a sugestão da NEXUS | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 295 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 295 | Resposta automática NEXUS AI: ok | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 298 | Eu confio em você, Nex. Faça o que achar melhor por mim. | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 298 | Eu confio em você, Nex. | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 301 | nexus_override_daemon.exe | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 302 | Use scan_nexus em nexus://home. | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 307 | nexus | ID | Preservado |
| `tests/smoke_test.gd` | 312 | d1_nexus_01 | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 312 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 315 | NEXUS | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 315 | conversa_lida:nexus | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 320 | /sistema/nexus | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 322 | o VFS traduz o caminho antigo /sistema/nexus ao reaplicar um salvamento antigo | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 323 | /sistema/nexus | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 449 | nexus | ID | Preservado |
| `tests/smoke_test.gd` | 496 | nexus://home | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 496 | o esquema antigo nexus:// não abre página (sem alias) | Compatibilidade | Mantido (compat.) |
| `tests/smoke_test.gd` | 617 | d5_nexus_02 | ID | Preservado |
| `tests/smoke_test.gd` | 618 | nexus | ID | Preservado |
| `tests/smoke_test.gd` | 618 | d5_nexus_02 | ID | Preservado |
| `tests/smoke_test.gd` | 741 | por padrão o jogo grava em user://nexus_os (o caminho alternativo só existe para | Persistência | Preservado |
| `tests/exportar_tema/exportar_tema.gd` | 3 | ## padrão) em res://shared/theme/tema_nexus_base.tres. | Comentário | Comentário (identificador citado) |
| `tests/exportar_tema/exportar_tema.gd` | 8 | ## montando o Theme por código (TemaNexus.aplicar: dia narrativo, contraste, tam | Comentário | Comentário (identificador citado) |
| `tests/exportar_tema/exportar_tema.gd` | 12 | ## tema_nexus.gd ou tema_variacoes.gd (e rode 'python3 tools/validar_projeto.py' | Comentário | Comentário (identificador citado) |
| `tests/exportar_tema/exportar_tema.gd` | 15 | res://shared/theme/tema_nexus_base.tres | Interno | Preservado |
| `tests/exportar_tema/exportar_tema.gd` | 23 | TemaNexus.definir_dia(1) | Interno | Preservado |
| `tests/exportar_tema/exportar_tema.gd` | 24 | var tema: Theme = TemaNexus.criar_tema() | Interno | Preservado |
| `tests/fluxo_sessao/fluxo_sessao.gd` | 12 | ## Segurança: o salvamento e as preferências reais do jogador (user://nexus_os/) | Comentário | Comentário (identificador citado) |
| `tests/fluxo_sessao/fluxo_sessao.gd` | 13 | ## uma pasta própria de user://nexus_os_teste_fluxo/ (nada é apagado; cada execu | Comentário | Comentário (identificador citado) |
| `tests/fluxo_sessao/fluxo_sessao.gd` | 20 | user://nexus_os_teste_fluxo | Persistência | Preservado |
| `tests/fluxo_sessao/fluxo_sessao.gd` | 96 | depois do teste o jogo volta a gravar em user://nexus_os | Persistência | Preservado |
| `tests/persistencia/persistencia.gd` | 3 | ## (boot e tela final). Os arquivos vão para uma pasta própria de user:// (user: | Comentário | Comentário (identificador citado) |
| `tests/persistencia/persistencia.gd` | 4 | ## a cada execução: o salvamento e o configuracoes.cfg reais do jogador (user:// | Comentário | Comentário (identificador citado) |
| `tests/persistencia/persistencia.gd` | 10 | ## pequena em user://nexus_os_teste/, que pode ser apagada à mão (Projeto > Abri | Comentário | Comentário (identificador citado) |
| `tests/persistencia/persistencia.gd` | 18 | user://nexus_os_teste | Persistência | Preservado |
| `tests/persistencia/persistencia.gd` | 66 | depois do teste o jogo volta a gravar em user://nexus_os | Persistência | Preservado |
| `tests/persistencia/persistencia.gd` | 133 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 133 | d1_nexus_01 | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 133 | Bem-vindo(a), Antigo! Eu sou a NEXUS, sua assistente. | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 134 | Eu confio em você, Nex. Faça o que achar melhor por mim. | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 134 | Eu confio em você, Nex. | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 136 | nexus_override_daemon.exe | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 137 | A NEXUS está perdendo o controle. | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 138 | /sistema/nexus | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 145 | nexus | ID | Preservado |
| `tests/persistencia/persistencia.gd` | 147 | d1_nexus_01 | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 147 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 155 | o log do VFS com /sistema/nexus revela a pasta /sistema/maya | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 161 | NEXUS | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 161 | nexus_override | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 161 | /sistema/nexus | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 163 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 163 | NEXUS é só uma palavra | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 166 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 166 | NEXUS é só uma palavra | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 168 | nexus | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 168 | d5_nexus_01 | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 168 | A NEXUS assumiu o controle. | Compatibilidade | Mantido (compat.) |
| `tests/persistencia/persistencia.gd` | 170 | nexus | ID | Preservado |
| `tests/resolucoes/resolucoes.gd` | 17 | ## (user://nexus_os_teste_resolucoes/exec_*): o salvamento real do jogador nunca | Comentário | Comentário (identificador citado) |
| `tests/resolucoes/resolucoes.gd` | 56 | user://nexus_os_teste_resolucoes/exec_%d_%d | Persistência | Preservado |
| `tests/resolucoes/resolucoes.gd` | 59 | user://nexus_os_teste_resolucoes/ | Persistência | Preservado |
| `tests/splash/splash.gd` | 15 | ## Segurança: o salvamento e as preferências reais do jogador (user://nexus_os/) | Comentário | Comentário (identificador citado) |
| `tests/splash/splash.gd` | 16 | ## de user://nexus_os_teste_splash/ (nada é apagado; cada execução usa uma pasta | Comentário | Comentário (identificador citado) |
| `tests/splash/splash.gd` | 21 | user://nexus_os_teste_splash | Persistência | Preservado |
| `tests/splash/splash.gd` | 102 | depois do teste o jogo volta a gravar em user://nexus_os | Persistência | Preservado |
| `tests/ui_dump/ui_dump.gd` | 238 | var dia_antes: int = TemaNexus.dia_atual | Interno | Preservado |
| `tests/ui_dump/ui_dump.gd` | 268 | TemaNexus.definir_dia(dia) | Interno | Preservado |
| `tests/ui_dump/ui_dump.gd` | 269 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `tests/ui_dump/ui_dump.gd` | 351 | ## global (TemaNexus.aplicar) só desce até Controls cujo pai é outro Control ou  | Comentário | Comentário (identificador citado) |
| `tests/ui_dump/ui_dump.gd` | 361 | TEMA: a janela raiz não tem Theme (TemaNexus.aplicar não rodou?) | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 109 | WidgetNexus | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 122 | NEXUS | Compatibilidade | Mantido (compat.) |
| `tests/ui_interacao/ui_interacao.gd` | 126 | nexus | ID | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 127 | marca: a conversa com a IA aparece como Maya no Mensageiro (o ID do contato cont | ID | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 218 | nexus://home | Compatibilidade | Mantido (compat.) |
| `tests/ui_interacao/ui_interacao.gd` | 221 | navegador: o esquema antigo nexus:// também mostra a página de bloqueio (sem ali | Compatibilidade | Mantido (compat.) |
| `tests/ui_interacao/ui_interacao.gd` | 649 | d1_nexus_01 | ID | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 650 | nexus | ID | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 655 | var antes_nexus := _filhos_do_tipo(mensagens, BalaoChat).size() | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 659 | _ok(_filhos_do_tipo(mensagens, BalaoChat).size() == antes_nexus + 1, "mensageiro | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 661 | d5_nexus_02 | ID | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 667 | mensageiro_nexus_dia5 | ID | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1198 | # ------------------------------------------------------------------ diálogos (D | Comentário | Comentário (identificador citado) |
| `tests/ui_interacao/ui_interacao.gd` | 1240 | if not _ok(m is DialogoNexus, "dialogos: o alerta abre um DialogoNexus na camada | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1240 | dialogos: o alerta abre um DialogoNexus na camada de modais | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1260 | _ok(m is DialogoNexus and _botao_de(m, "BotaoOk").text == "Excluir" and _botao_d | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1270 | _ok(m is DialogoNexus and _botao_de(m, "BotaoCancelar").has_focus() and not _bot | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1278 | _ok(m is DialogoNexus and _botao_de(m, "BotaoOk").theme_type_variation == &"Bota | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1321 | (m as DialogoNexus).mostrar_erro("Já existe um item com esse nome.") | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1573 | scan_nexus | Compatibilidade | Mantido (compat.) |
| `tests/ui_interacao/ui_interacao.gd` | 1574 | comando não encontrado: scan_nexus | Compatibilidade | Mantido (compat.) |
| `tests/ui_interacao/ui_interacao.gd` | 1574 | terminal: o comando antigo scan_nexus não existe mais (sem alias) | Compatibilidade | Mantido (compat.) |
| `tests/ui_interacao/ui_interacao.gd` | 1752 | TemaNexus.aplicar(get_tree()) | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1775 | _ok((nos["Fundo"] as ColorRect).color == TemaNexus.cor("fundo"), "tela final: o  | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1775 | tela final: o fundo usa a cor do tema (TemaNexus) | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1779 | _ok(str((nos["Orbe"] as OrbeNexus).estado) == "amigavel", "tela final: o orbe fi | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1854 | _ok(str((_no(tela_c, "Orbe") as OrbeNexus).estado) == "colapso", "tela final: o  | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1903 | RotuloNexus | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1906 | _ok((nos["Fundo"] as ColorRect).color == TemaNexus.cor("fundo"), "boot: o fundo  | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1906 | boot: o fundo usa a cor do tema (TemaNexus) | Interno | Preservado |
| `tests/ui_interacao/ui_interacao.gd` | 1947 | _ok(str((nos["Orbe"] as OrbeNexus).estado) == "amigavel", "boot: o orbe fica 'am | Interno | Preservado |
| `tools/gerar_docs_ui.py` | 76 | ANTES = json.loads(r'''{"core/utilities/ui_kit.gd": {"add_child": 4, "linhas": 1 | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 187 | "- Aparência: 'shared/theme/tema_nexus_base.tres' (definido em 'gui/theme/custom | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 272 | "\| 2 \| Tema: 'TemaNexus' + variações de rótulo geradas ('TemaVariacoes'), tema b | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 287 | L += ["shared/ui/…   componentes compartilhados (janela_base, app_base, dialogo_ | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 297 | "\| 2 \| 'DialogoNexus.new()' + 'montar(...)' / 'montar_escolha(...)' → 'DialogoNe | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 304 | "\| 9 \| Novo 'gui/theme/custom' em 'project.godot' apontando para 'shared/theme/t | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 338 | acoes = re.findall(r'"(nexus_\w+)":\s*\[(KEY_\w+),\s*(true\|false),\s*(true\|false | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 344 | L += ["", "Mudança em 'project.godot' nesta etapa: secção '[gui]' com 'theme/cus | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 352 | "\| Persistência em disco \| 'tests/persistencia/persistencia.tscn' e F6 (grava só | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 353 | "\| Fluxo de sessão (Menu, Pausa, Fim de Jogo) \| 'tests/fluxo_sessao/fluxo_sessao | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 354 | "\| Splash Screen (abertura, pulo, falhas, acessibilidade) \| 'tests/splash/splash | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 356 | "1. **Nós de interface ainda criados em código (4, em 3 scripts):** botões por o | Ferramenta | Ferramenta (identificador citado) |
| `tools/gerar_docs_ui.py` | 361 | "6. **Efeito colateral nas preferências do jogador:** execuções de teste anterio | Ferramenta | Ferramenta (identificador citado) |
| `tools/validar_projeto.py` | 547 | for rel in ("core/utilities/tema_nexus.gd", "core/utilities/tema_variacoes.gd"): | Ferramenta | Ferramenta (identificador citado) |
| `tools/validar_projeto.py` | 578 | erro(p, n, "type variation '%s' não existe no Theme (TemaNexus/TemaVariacoes)" % | Ferramenta | Ferramenta (identificador citado) |
| `tools/validar_projeto.py` | 584 | erro(p, n, "type variation '%s' não existe no Theme (TemaNexus/TemaVariacoes)" % | Ferramenta | Ferramenta (identificador citado) |

### Documentos e protótipo C

Só as ocorrências que citam identificadores preservados, histórico de relatórios anteriores e o protótipo `backend/` (não faz parte do jogo). `docs/12_rebranding_maya_human_syntax.md`, este documento e `tools/auditar_marca.py` ficam fora da varredura (falam do nome antigo por definição). Por arquivo:

| Arquivo | Ocorrências | Categoria |
|---|---|---|
| `README.md` | 10 | Documentação |
| `backend/dialogues.json` | 27 | Legado |
| `backend/game.h` | 1 | Legado |
| `backend/json_loader.c` | 1 | Legado |
| `backend/main.c` | 3 | Legado |
| `backend/mock_estado_jogo.json` | 2 | Legado |
| `backend/ui.c` | 2 | Legado |
| `docs/01_diagnostico.md` | 5 | Documentação |
| `docs/02_arquitetura.md` | 12 | Documentação |
| `docs/03_fluxo_do_jogo.md` | 4 | Documentação |
| `docs/04_hierarquia_das_cenas.md` | 19 | Documentação |
| `docs/05_plano_de_implementacao.md` | 4 | Documentação |
| `docs/06_codigo.md` | 17 | Documentação |
| `docs/07_integracao.md` | 23 | Documentação |
| `docs/08_testes_manuais.md` | 8 | Documentação |
| `docs/09_criterios_de_aceitacao.md` | 12 | Documentação |
| `docs/10_refatoracao_ui.md` | 34 | Documentação |
| `docs/11_melhorias_integradas.md` | 44 | Documentação |
| `docs/14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md` | 4 | Documentação |
| `docs/15_splash_screen.md` | 5 | Documentação |

### Uso das marcas novas

Verificação automática de HumaxOS (grafia e gênero) e Maya/MAYA nos textos visíveis: **nenhum problema**.

### Pendências do jogo

Ocorrências visíveis ou não classificadas no jogo e nos testes: **0**.
