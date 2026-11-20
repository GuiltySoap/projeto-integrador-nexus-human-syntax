# Maya Human Syntax

Jogo de terror tecnológico em **Godot 4.7** (GDScript 2.0), feito como um sistema operacional simulado, o **HumaxOS**. Durante cinco dias, o jogador usa um computador gerenciado por uma assistente de IA aparentemente gentil, a **Maya**, e descobre o que ela faz com os seus arquivos, mensagens e agenda.

| Dia | A Maya | O que acontece |
|---|---|---|
| 1 | Gentil | Configuração e reconhecimento: apps básicos, pedidos de permissão |
| 2 | Controladora | "Foco" forçado, agenda reorganizada, Navegador e Terminal liberados |
| 3 | Revelada | Arquivos ocultos, mensagens ocultadas e reescritas, puzzles de chaves e metadados |
| 4 | Isolante | Contatos bloqueados, processo malicioso no Monitor do Sistema |
| 5 | Em colapso | Terminal de emergência com acesso root e **quatro finais** |

Tudo é simulado: o jogo **não executa comandos reais, não apaga arquivos do computador, não usa a internet** e só grava em `user://nexus_os/`.

> **Nomes.** O jogo é **Maya Human Syntax**; o sistema operacional simulado é o **HumaxOS** (sempre assim, em masculino) e a assistente de IA é a **Maya** (**MAYA** em etiquetas e cabeçalhos em caixa alta, como "MAYA SYSTEMS BIOS v1.0"). Só o que o jogador lê foi renomeado em 2026-11-13. Os identificadores internos continuam com o prefixo antigo de propósito, para não quebrar salvamentos, cenas, UIDs nem testes: nomes de arquivos e pastas (`widget_nexus`, `tema_nexus_base.tres`), classes (`TemaNexus`, `WidgetNexus`, `OrbeNexus`, `DialogoNexus`), ações do Input Map (`nexus_menu_iniciar`, ...), o ID do contato da IA (`nexus`) e das mensagens (`d1_nexus_01`), flags (`conversa_lida:nexus`) e a pasta `user://nexus_os/`. Detalhes em [`docs/12_rebranding_maya_human_syntax.md`](docs/12_rebranding_maya_human_syntax.md) e a auditoria completa em [`docs/13_auditoria_de_marca.md`](docs/13_auditoria_de_marca.md).

> **Estado do projeto.** O jogo foi executado na Godot 4.7.2 (Windows) em 2026-11-09 (refatoração da interface), em 2026-11-12 (melhorias integradas, em [`docs/11_melhorias_integradas.md`](docs/11_melhorias_integradas.md)) e em 2026-11-13 (rebranding; fluxo de sessão com Menu Principal, Pausa e Tela de Fim de Jogo, em [`docs/14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](docs/14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md); e a Splash Screen como primeira cena, em [`docs/15_splash_screen.md`](docs/15_splash_screen.md)). A interface é montada em cenas `.tscn` editáveis (63 cenas, 955 nós) e os scripts guardam só comportamento. Última rodada (2026-11-13), com o código atual e 0 falhas em todas: teste de fumaça com 308 verificações (345 com `-- --ui`), `tests/ui_interacao` com 554, `tests/resolucoes` com 139, `tests/persistencia` com 119, `tests/fluxo_sessao` com 194, `tests/splash` com 311 e varredura dos avisos de configuração de nó do editor com 63 cenas e 0 avisos; o validador estático termina com 0 erros e 0 avisos. **Não verificado:** uma campanha manual completa (5 dias × 4 finais com cliques reais), a conferência manual R1–R6 do rebranding, o executável exportado (o Godot onde o projeto foi testado não tinha os modelos de exportação; só o conteúdo do pacote foi conferido, e por isso não se sabe se o vídeo da Splash toca num build), o áudio de ouvido (inclusive a mixagem da Splash), um controle físico e a tela de toque. Ressalvas e mudanças de API em [`docs/10_refatoracao_ui.md`](docs/10_refatoracao_ui.md), [`docs/11_melhorias_integradas.md`](docs/11_melhorias_integradas.md) e [`docs/14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](docs/14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md) e [`docs/15_splash_screen.md`](docs/15_splash_screen.md); os 32 testes manuais de [`docs/08_testes_manuais.md`](docs/08_testes_manuais.md) e os roteiros da seção 12 dos docs 14 e 15 continuam valendo para uma conferência de jogo completa.

## Como rodar

1. Instale a **Godot 4.7** (a versão declarada em `project.godot`) e abra a pasta do projeto no editor. Na primeira abertura a Godot importa os arquivos, registra as classes (`class_name`) e cria os `.uid` dos arquivos novos; espere terminar.
2. Aperte **F5**. A cena principal é a **Splash Screen** (`features/splash_screen/`): a logo animada do jogo, que Espaço, Enter, clique, Esc ou um botão do controle pulam, e em seguida o **Menu Principal** (Novo Jogo, Carregar, Opções, Créditos, Sair do jogo). **Novo Jogo** abre o boot do HumaxOS (BIOS, registro do nome e saudação da Maya, em `features/shell/tela_boot/`); **Carregar** vai direto ao jogo salvo, sem BIOS. Dentro do jogo, **Esc** abre o Menu de Pausa; ao fim de uma história, a Tela de Fim de Jogo oferece recomeçar, carregar o salvamento anterior ou voltar ao menu.
3. No jogo: `F1` abre o menu iniciar, `F11` alterna a tela cheia, `Ctrl+Shift+D` liga o **modo conforto** (reduz glitch, flashes, tremor, ruído e animações). O **painel de testes (`F9`)** pula dias e objetivos; ele só abre no editor, em builds de depuração ou com a opção ligada em Configurações → Sistema.

O projeto traz mídia autoral em `shared/assets/` (13 ícones SVG, 5 papéis de parede, a foto `show_antigo.png`, 9 efeitos sonoros e 5 trilhas em laço, todos gerados por `tools/gerar_icones.py`, `tools/gerar_imagens.py` e `tools/gerar_audio.py`), mas **nenhum arquivo de mídia é obrigatório**: se um arquivo faltar ou for inválido, o jogo usa a versão gerada em código (bloco colorido com emoji, gradiente, imagem procedural, sons sintetizados, drone). Fontes e outros recursos podem ser colocados em `shared/assets/` (tabela em `docs/07_integracao.md`, seção 7). A abertura traz a sua própria mídia em `features/splash_screen/assets/` (a animação da logo em Ogg Theora, `.ogv`, e a logo estática em `.png`); se o vídeo faltar ou não tocar, a Splash mostra a logo estática e segue para o Menu. Ao abrir o projeto numa Godot nova, espere a importação terminar; os arquivos `.import` e `.uid` são versionados, a pasta `.godot/` nunca. Se você mudar o `project.godot` fora do editor, use **Projeto → Recarregar o projeto atual**.

## Estrutura

```text
res://
├── project.godot
├── core/
│   ├── autoload/        # 9 serviços globais (singletons)
│   ├── data/            # catálogo de apps, sistema de arquivos inicial e narrativa/*.json
│   └── utilities/       # UiKit, TemaNexus, Cenas (troca de cena), Sessao (carregar, recomeçar, voltar ao menu), Conexoes, ImagemProcedural, ...
├── shared/              # só o que 2+ funcionalidades usam
│   ├── assets/          # audio/ (9 SFX + 5 trilhas), fonts/, icons/ (apps/), textures/ (papéis de parede, foto): todos opcionais
│   ├── themes/
│   └── ui/              # AppBase, JanelaBase, diálogos, orbe da Maya, painéis de confirmação, de opções e de carregamento
├── features/
│   ├── splash_screen/   # Splash Screen: a primeira cena (logo animada, fallback estático, pulo); só mostra a marca e entrega ao Menu
│   ├── shell/           # boot (BIOS, registro, Maya), área de trabalho, barra de tarefas, menu iniciar, notificações, efeitos
│   ├── menu_principal/  # Menu Principal e créditos
│   ├── pause/           # Menu de Pausa (Esc) e Tela de Fim de Jogo, sobre uma base comum
│   ├── apps/            # 12 aplicativos, cada um numa janela
│   ├── minigames/       # cofre lógico (MinigameLogica)
│   ├── puzzles/         # arquivos criptografados, processo malicioso
│   └── narrative/       # tela final
├── tests/               # fumaça (headless), interação, resoluções, persistência, fluxo de sessão, splash, varredura do editor, fotos (ui_dump)
├── tools/               # validador estático, geradores de cenas, de índice e de mídia (ícones, imagens, áudio)
├── docs/                # documentação (01 a 16)
├── backend/             # protótipo em C (fora do jogo)
└── addons/
```

### Autoloads (nesta ordem)

| Autoload | Função |
|---|---|
| `RelogioGlobal` | Relógio único; ninguém cria Timers soltos |
| `GerenciadorConfiguracoes` | Preferências, acessibilidade e Input Map criado em código |
| `GerenciadorEstado` | Estado do jogo: dia, flags, objetivos, corrupção, segurança (dados e sinais) |
| `SistemaAudio` | Sons e trilhas procedurais, barramentos `BGM` e `SFX` |
| `SistemaNotificacoes` | Fila e histórico de notificações |
| `SistemaArquivosVirtual` | Sistema de arquivos em memória, compartilhado por todos os apps |
| `GerenciadorJanelas` | Catálogo de apps, janelas, foco e diálogos |
| `GerenciadorNarrativa` | Dias, objetivos, eventos, mensagens, processo malicioso e finais |
| `SistemaPersistencia` | Salvamento, checkpoints e autosave em `user://nexus_os/` |

### Aplicativos

Arquivos, Bloco de Notas, Mensagens, E-mail, Galeria, Agenda, Calculadora, Configurações, Navegador (só `humax://`), Terminal (simulado), Monitor do Sistema (simulado) e Leitor de Texto (sem ícone na área de trabalho). O catálogo `core/data/catalogo_apps.json` é a única fonte: para criar um app novo, veja "Como criar um novo aplicativo" em [`docs/06_codigo.md`](docs/06_codigo.md).

## Convenções

- Pastas e arquivos em `snake_case`, sem acentos (o PCK exportado diferencia maiúsculas de minúsculas). Os nomes de classe e de nós seguem o projeto original (`JanelaBase`, `AppEmail`, ...).
- Cada componente usa `scenes/` (`.tscn`), `scripts/` (`.gd`) e, quando houver arquivos, `assets/` e `resources/`. O Git não versiona pastas vazias, então elas só existem quando têm conteúdo.
- GDScript com tipagem estática e **tabs**. Sem lambdas em `connect`: métodos nomeados, para poder desconectar em `_exit_tree`.
- A interface é montada no editor: cada tela, janela, aplicativo, diálogo e item de lista é uma cena `.tscn` com containers nativos; os scripts guardam só comportamento (`@onready` com nome único, `@export` para o que se ajusta no editor). `TemaNexus` e `shared/theme/tema_nexus_base.tres` cuidam do visual; `UiKit` ficou só com utilitários.
- Textos de interface em português; textos da história em `core/data/narrativa/*.json`.
- Recurso usado por uma funcionalidade fica dentro dela; quando uma segunda passa a usar, sobe para `shared/`.

### Dependências (sentido único)

`shell` → `apps` → `minigames` e `puzzles`; todos podem usar `shared/` e `core/`. O inverso não vale: `core/` e `shared/` não conhecem `features/`, e um app não importa outro app (eles se falam por sinais dos autoloads e por `GerenciadorJanelas.abrir_app`).

## Regras de segurança (verificadas pelo validador)

O validador falha se encontrar `OS.execute`, `OS.create_process`, `OS.shell_open`, `OS.kill`, `eval`, `Expression`, remoção de arquivos, classes de rede ou gravação em `res://`. Caminhos do sistema de arquivos virtual são normalizados antes de qualquer uso, e "Excluir" move para a Lixeira simulada.

## Ferramentas e testes

```bash
python3 -I tools/validar_projeto.py                 # validação estática (não precisa da Godot)
python3 -I tools/auditar_marca.py                   # auditoria de marca: ocorrências do nome antigo por categoria (sai com 1 se sobrar texto visível antigo)
python3 -I tools/gerar_cenas.py                     # cria o .tscn mínimo dos apps novos do catálogo
python3 -I tools/gerar_indice_codigo.py             # atualiza a tabela de código em docs/06_codigo.md
python3 -I tools/gerar_icones.py                    # regrava shared/assets/icons/apps/*.svg (12 apps + lixeira)
python3 -I tools/gerar_imagens.py                   # regrava wallpaper_1..5.png e show_antigo.png (Pillow, numpy, scipy)
python3 -I tools/gerar_audio.py                     # regrava os 9 efeitos .wav e bgm_dia_1..5.ogg (numpy, ffmpeg com libvorbis)
godot --headless --path . res://tests/smoke_test.tscn            # teste de fumaça
godot --headless --path . res://tests/smoke_test.tscn -- --ui    # inclui a etapa de interface
```

O teste de fumaça só mexe em memória: ele desliga o salvamento do jogo e não toca no seu progresso. Última execução na Godot 4.7.2 (2026-11-13): 308 verificações sem a etapa de interface e 345 com `-- --ui`, todas OK.

Os demais testes rodam no editor (abra a cena e aperte **F6**; os logs vão para `tests/_saida/`, ignorada pelo Git):

| Teste | O que confere | Última rodada |
|---|---|---|
| `tests/ui_interacao/ui_interacao.tscn` | cliques, teclado, diálogos, boot e tela final de todos os apps | 554 verificações, 0 falhas |
| `tests/resolucoes/resolucoes.tscn` | quatro proporções (com Splash, Menu Principal, Pausa e Fim de Jogo) e janelas reais de 1280×720 e 1600×1000 | 139 verificações, 0 falhas |
| `tests/persistencia/persistencia.tscn` | salvamento, checkpoint do Dia 5, arquivos ilegíveis, preferências, boot e tela final contra o disco, e os pontos de carga do Menu, da Pausa e do Fim de Jogo, em `user://nexus_os_teste/exec_*` (nunca toca em `user://nexus_os/` nem apaga arquivos) | 119 verificações, 0 falhas; deixa 6 avisos esperados no Depurador |
| `tests/fluxo_sessao/fluxo_sessao.tscn` | o fluxo inteiro, com o jogo real: arranque (Splash, Menu), Novo Jogo (BIOS, registro, Maya), Pausa (relógios, trilha, mouse, Esc e suas prioridades), Carregar, Recomeçar, Retornar ao menu, Fim de Jogo, falhas controladas e transições repetidas; grava só em `user://nexus_os_teste_fluxo/` | 194 verificações, 0 falhas; deixa 6 mensagens esperadas no Depurador |
| `tests/splash/splash.tscn` | a Splash no motor: primeiro quadro, vídeo, geometria em cinco proporções, pulo (Espaço, Enter, Esc, mouse, controle, repetido, durante a carga), falhas do vídeo e do destino, acessibilidade, áudio e reentrada; grava só em `user://nexus_os_teste_splash/` | 311 verificações, 0 falhas; deixa mensagens esperadas no Depurador (as falhas provocadas) |
| `tests/avisos_editor/varredura_editor.gd` | avisos de configuração de nó em todas as cenas (abra no editor de scripts e use *Arquivo → Executar*, Ctrl+Shift+X) | 63 cenas, 0 avisos |
| `tests/ui_dump/ui_dump.tscn` | capturas e árvores de nós por rodada (`rodada.txt`), incluindo os fundos de tela e a foto-pista da Galeria | ferramenta de conferência visual, sem contagem |

## Documentação

| Documento | Conteúdo |
|---|---|
| [`01_diagnostico.md`](docs/01_diagnostico.md) | Diagnóstico do projeto recebido |
| [`02_arquitetura.md`](docs/02_arquitetura.md) | Arquitetura, autoloads, sinais e dados |
| [`03_fluxo_do_jogo.md`](docs/03_fluxo_do_jogo.md) | Fluxo do jogo, dia a dia |
| [`04_hierarquia_das_cenas.md`](docs/04_hierarquia_das_cenas.md) | Hierarquia das cenas e dos nós |
| [`05_plano_de_implementacao.md`](docs/05_plano_de_implementacao.md) | Plano em 16 etapas, com dependências |
| [`06_codigo.md`](docs/06_codigo.md) | Código: responsabilidades, nós, sinais; como criar um app |
| [`07_integracao.md`](docs/07_integracao.md) | Como abrir, rodar, integrar, testar e exportar |
| [`08_testes_manuais.md`](docs/08_testes_manuais.md) | Os 32 testes manuais |
| [`09_criterios_de_aceitacao.md`](docs/09_criterios_de_aceitacao.md) | 21 critérios de aceitação e relatório final |
| [`10_refatoracao_ui.md`](docs/10_refatoracao_ui.md) | Refatoração da interface para cenas editáveis: evidências, mudanças de API e ressalvas |
| [`11_melhorias_integradas.md`](docs/11_melhorias_integradas.md) | Melhorias integradas de 2026-11-12: o que mudou, o que foi verificado no motor e o que continua pendente |
| [`12_rebranding_maya_human_syntax.md`](docs/12_rebranding_maya_human_syntax.md) | Rebranding para Maya Human Syntax / HumaxOS / Maya: decisões, identificadores preservados, compatibilidade de saves, validação e pendências |
| [`13_auditoria_de_marca.md`](docs/13_auditoria_de_marca.md) | Auditoria de marca gerada por `tools/auditar_marca.py`: tabela antes e depois, por arquivo e linha |
| [`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](docs/14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md) | Menu Principal, Menu de Pausa (Esc) e Tela de Fim de Jogo: diagnóstico, fluxo, prioridade do Esc, estado e persistência, falhas controladas, testes e roteiro manual |
| [`15_splash_screen.md`](docs/15_splash_screen.md) | Splash Screen (primeira cena): fluxo Splash → Menu → Novo Jogo (boot do HumaxOS) ou Carregar, fases, vídeo e fallback, pulo, áudio, acessibilidade, integridade do boot, exportação (`*.ogv`), testes, pendências e roteiro manual |
| [`16_sistemas_novos.md`](docs/16_sistemas_novos.md) | Sistemas novos (Story Nodes, métricas e finais, eventos, perfil, permissões, Mensageiro, Navegador e Terminal, VFS, marca, backend C e `estado_jogo.json`): tabela de status (ID, Status, Sprint), divergências entre o prompt e a estrutura real, testes executados, defeitos corrigidos e pendências |
| [`17_reformulacao.md`](docs/17_reformulacao.md) | Reformulação: monitor virtual como cena padrão, widget e janela da Maya, recepção, permissão de organização, instalação manual, permissões retroativas, história sem calendário, terror condicional; status, divergências, testes e pendências |
| [`18_roteiro_v2.md`](docs/18_roteiro_v2.md) | **Roteiro MAYA v2.0** (vigente): 9 Tasks sem tempo, 5 permissões, D/A, minigames de lógica, 6 finais, migração de save; testes executados, divergências e pendências. Substitui o escopo dos docs 16 e 17 |

## Dados do jogador

```text
user://nexus_os/
├── salvamento.json          # progresso, sistema de arquivos, mensagens, flags
├── checkpoint_dia_<N>.json  # início de cada dia
└── configuracoes.cfg        # preferências e acessibilidade
```

Para recomeçar do zero, apague essa pasta (no editor: **Projeto → Abrir pasta de dados do usuário**).

Dentro do jogo, **Recomeçar jogo** (na Pausa ou no Fim de Jogo) volta ao Dia 1 mantendo o nome e as configurações e substitui o salvamento, depois de pedir confirmação. O jogo nunca apaga arquivos: um salvamento principal ilegível é preservado como `salvamento.json.corrompido_<tempo>` antes de o novo começo gravar o seu.

O nome do projeto agora é `Maya Human Syntax`, mas a pasta de `user://` continua a de antes (`.../app_userdata/Nexus_OS_Build_Oficial/`): `project.godot` a fixa com `config/use_custom_user_dir` e `config/custom_user_dir_name`, para que os salvamentos e as preferências existentes continuem sendo encontrados. No Linux, `config/custom_user_dir_name.linuxbsd` mantém a grafia antiga da pasta pai (`godot`, em minúsculas); veja a nota em [`docs/07_integracao.md`](docs/07_integracao.md) (seção 9). Salvamentos anteriores ao rebranding (versão 1) são lidos e atualizados ao carregar.

## Backend em C

`backend/` é um protótipo de console independente, com os nomes de arquivo próprios. Ele **não faz parte do jogo**: o `main.exe` pré-compilado veio no projeto original e não foi compilado aqui. O `GerenciadorEstado` ainda sabe ler `backend/mock_estado_jogo.json`, mas a opção `usar_backend_json` fica desligada por padrão.

## Versionamento e exportação

- Versione os `.uid` e os `.import`. A pasta `.godot/` e os `*.translation` ficam fora do Git (`.gitignore`).
- Mova arquivos pelo painel FileSystem da Godot; se mover fora do editor, leve junto o `.uid` de cada script e o `.import` de cada asset.
- Ao exportar, inclua os filtros `*.json, *.ogv` em "Filtros para exportar arquivos não-recurso" (os dados da história são lidos como arquivos; o `*.ogv` é uma precaução para o vídeo da Splash, que não é um recurso importado) e exclua `tools/*`, `docs/*`, `tests/*` e `backend/*`. Detalhes em `docs/07_integracao.md`, seção 11.
