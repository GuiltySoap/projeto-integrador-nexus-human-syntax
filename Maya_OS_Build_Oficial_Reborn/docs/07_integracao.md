# 15.7 Integração

Como as peças se ligam no editor, o que o `project.godot` precisa conter e como testar cada módulo. Tudo o que está aqui **já está aplicado no projeto entregue**; as seções servem de conferência e de roteiro caso alguém precise refazer a configuração.

## 1. Primeira abertura

1. Abra a **Godot 4.7** (versão declarada em `config/features`), escolha **Importar** e aponte para o `project.godot` da raiz.
2. Deixe o editor terminar o primeiro escaneamento. É nele que a Godot:
   - cria a pasta `.godot/` (cache; **não** é versionada) e o cache de `class_name` (`UiKit`, `AppBase`, `TemaNexus`...), sem o qual os scripts não compilam;
   - gera os arquivos `.uid` dos scripts e das cenas novos (os `.uid` que já existiam foram mantidos).
3. Confira o painel **Output**: deve ficar sem erros nem avisos (é o teste 32 de `08_testes_manuais.md`).
4. Rode com **F5**. A cena principal é a **Splash Screen** (a logo animada do jogo); depois dela vem o Menu Principal, e o boot do HumaxOS (BIOS, registro, Maya) só abre quando o jogador escolhe **Novo Jogo** (veja [`15_splash_screen.md`](15_splash_screen.md)).

Sem o editor, o mesmo escaneamento pode ser pedido pela linha de comando: `godot --headless --path . --import`. Isso não foi testado no ambiente de desenvolvimento (que não tinha a Godot).

## 2. `project.godot`

O arquivo entregue contém exatamente isto (fora comentários):

```ini
config_version=5

[application]

config/name="Maya Human Syntax"
config/use_custom_user_dir=true
config/custom_user_dir_name="Godot/app_userdata/Nexus_OS_Build_Oficial"
config/custom_user_dir_name.linuxbsd="godot/app_userdata/Nexus_OS_Build_Oficial"
run/main_scene="res://features/splash_screen/scenes/splash_screen.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")
boot_splash/bg_color=Color(0, 0, 0, 1)
boot_splash/show_image=false
config/icon="res://shared/assets/icons/icon.svg"

[autoload]

RelogioGlobal="*res://core/autoload/relogio_global.gd"
GerenciadorConfiguracoes="*res://core/autoload/gerenciador_configuracoes.gd"
GerenciadorEstado="*res://core/autoload/gerenciador_estado.gd"
SistemaAudio="*res://core/autoload/sistema_audio.gd"
SistemaNotificacoes="*res://core/autoload/sistema_notificacoes.gd"
SistemaArquivosVirtual="*res://core/autoload/sistema_arquivos_virtual.gd"
GerenciadorJanelas="*res://core/autoload/gerenciador_janelas.gd"
GerenciadorNarrativa="*res://core/autoload/gerenciador_narrativa.gd"
SistemaPersistencia="*res://core/autoload/sistema_persistencia.gd"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/mode=4
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[physics]

3d/physics_engine="Jolt Physics"

[rendering]

rendering_device/driver.windows="d3d12"
```

| Configuração | Por quê |
|---|---|
| `viewport 1920×1080`, `stretch canvas_items`, `aspect expand` | A interface é desenhada para 1080p e escala com a janela. Em proporções mais largas ou mais altas o espaço extra é usado em vez de ganhar barras pretas. |
| `window/size/mode=4` | Tela cheia exclusiva (vinha do projeto original). **F11** alterna para uma janela de 1280×720 centralizada (`GerenciadorConfiguracoes.alternar_tela_cheia`). Para desenvolver em janela, troque para `window/size/mode=0` ou use F11. |
| `physics` e `rendering` | Vieram do projeto original e não afetam o jogo (só há interface 2D). Se a placa de vídeo não suportar D3D12 no Windows, troque o driver para `vulkan`. |
| Sem `[input]` e sem `[audio]` | Atalhos e barramentos são criados em código (seções 5 e 6), então não dependem de uma configuração que possa se perder. |

## 3. Cena principal

- Desde 2026-11-13, `run/main_scene` é o caminho `res://features/splash_screen/scenes/splash_screen.tscn` (a Splash Screen; antes era o UID da `tela_boot.tscn`, `uid://dn6752s6df8if`, que continua sendo o UID dessa cena). A Splash só mostra a marca e entrega ao Menu Principal; o Menu abre a `TelaBoot` quando o jogador escolhe Novo Jogo. Os autoloads são criados antes de qualquer cena e não dependem da cena principal.
- `boot_splash/bg_color` preto e `boot_splash/show_image=false` (e, em `[rendering]`, `environment/defaults/default_clear_color` preto) evitam qualquer clarão antes da Splash e entre a Splash e o Menu. Depois de mudar o `project.godot` fora do editor, use **Projeto → Recarregar o projeto atual**.
- Para trocar pelo editor: **Projeto → Configurações do Projeto → Aplicação → Run → Main Scene**.
- Cada tela abre a seguinte com `Cenas.ir_para(get_tree(), caminho)`: Splash → `Cenas.MENU_PRINCIPAL` → (Novo Jogo) `Cenas.BOOT` → `Cenas.AREA_DE_TRABALHO` → `Cenas.FINAL`; o Carregar do Menu vai direto à área de trabalho (veja a seção 8).
- Para testar uma tela isolada: **F6** com a cena aberta. A área de trabalho aberta direto (F6) retoma o salvamento, se existir, ou começa um jogo de teste (`AreaDeTrabalho._garantir_jogo`).

## 4. Autoloads

Registre em **Projeto → Configurações do Projeto → Globais → Autoload** (caminho, nome e **Variável Global** ligada) **nesta ordem**. A ordem é uma regra: cada autoload só usa os que vêm antes dele.

| # | Nome | Script | Depende de |
|---|---|---|---|
| 1 | `RelogioGlobal` | `res://core/autoload/relogio_global.gd` | — |
| 2 | `GerenciadorConfiguracoes` | `res://core/autoload/gerenciador_configuracoes.gd` | — |
| 3 | `GerenciadorEstado` | `res://core/autoload/gerenciador_estado.gd` | 2 |
| 4 | `SistemaAudio` | `res://core/autoload/sistema_audio.gd` | 2, 3 |
| 5 | `SistemaNotificacoes` | `res://core/autoload/sistema_notificacoes.gd` | 1, 3 |
| 6 | `SistemaArquivosVirtual` | `res://core/autoload/sistema_arquivos_virtual.gd` | 3 |
| 7 | `GerenciadorJanelas` | `res://core/autoload/gerenciador_janelas.gd` | 3, 4, 5 |
| 8 | `GerenciadorNarrativa` | `res://core/autoload/gerenciador_narrativa.gd` | 1, 2, 3, 4, 5, 6 |
| 9 | `SistemaPersistencia` | `res://core/autoload/sistema_persistencia.gd` | 3, 6, 8 |

Regras do registro: o nome **não pode** coincidir com um `class_name` (por isso nenhum autoload tem `class_name`); o `*` na frente do caminho significa "singleton" (é o que a caixa Variável Global grava). Para conferir de fora do editor, `tools/validar_projeto.py` lê esta seção e compara os nomes e as chamadas entre scripts.

## 5. Input Map

As ações são registradas **em código**, em `GerenciadorConfiguracoes._registrar_acoes()`, na inicialização. Só entram as que ainda não existem, então um atalho criado ou alterado no editor tem prioridade.

| Ação | Atalho | Onde é usada |
|---|---|---|
| `nexus_menu_iniciar` | `F1` | Área de trabalho: abre/fecha o menu iniciar |
| `nexus_tela_cheia` | `F11` | Boot, área de trabalho e tela final: alterna tela cheia/janela |
| `nexus_painel_debug` | `F9` | Área de trabalho: painel de testes (só em build de depuração ou com "Painel de testes" ligado em Configurações → Sistema) |
| `nexus_proxima_janela` | `Ctrl+Tab` | `GerenciadorJanelas`: foca a próxima janela |
| `nexus_fechar_janela` | `Ctrl+W` | `GerenciadorJanelas`: fecha a janela ativa (respeita o aviso de alterações) |
| `nexus_minimizar_janela` | `Ctrl+M` | `GerenciadorJanelas`: minimiza a janela ativa |
| `nexus_abrir_terminal` | `Ctrl+Shift+T` | Área de trabalho: abre o Terminal (se já liberado) |
| `nexus_forcar_desativar` | `Ctrl+Shift+D` | Boot, área de trabalho e tela final: **modo conforto** (desliga todos os efeitos intensos) |

Também são usadas as ações padrão da Godot `ui_accept` (Enter/Espaço) e `ui_cancel` (Esc, fecha menus e diálogos).

Para ver ou alterar no editor: **Projeto → Configurações do Projeto → Mapa de Entrada**, digite o nome da ação, **Adicionar** e escolha a tecla. Se a ação já existir lá, o código a respeita.

## 6. Barramentos de áudio

`SistemaAudio._garantir_barramentos()` cria `BGM` e `SFX` (enviando para `Master`) se não existirem. Se o projeto tiver um `default_bus_layout.tres` com esses nomes, ele é usado como está. Volumes (`volume_master`, `volume_bgm`, `volume_sfx`, de 0 a 1) vêm de Configurações → Áudio e são aplicados em `AudioServer`; com volume 0 o barramento é silenciado.

| Barramento | Uso | Players |
|---|---|---|
| `Master` | Volume geral | — |
| `BGM` | Trilha de fundo do dia (laço de 4 s gerado em código) | 1 `AudioStreamPlayer` |
| `SFX` | Cliques, janelas, notificações, glitch, finais | 6 `AudioStreamPlayer` em revezamento |

Se o áudio falhar (placa ausente, driver `Dummy` do modo headless), o jogo segue em silêncio: nenhuma função de áudio devolve erro ao chamador.

## 7. Fontes, ícones, texturas e áudio

**Nada aqui é obrigatório.** Cada recurso é procurado com `ResourceLoader.exists`; se faltar ou for inválido, há uma alternativa gerada em código e nenhuma falha é fatal. Basta colocar o arquivo no caminho certo; o editor importa sozinho na próxima abertura. O projeto já traz mídia autoral para os itens marcados com **(incluso)** na tabela, gerada pelos scripts `tools/gerar_icones.py`, `tools/gerar_imagens.py` e `tools/gerar_audio.py` (rode de novo para regravar; nomes em `snake_case` minúsculo, sem acento).

| Recurso | Onde colocar | Como o código procura | Alternativa quando falta |
|---|---|---|---|
| Fonte monoespaçada (terminal, logs, painel de testes) | `res://shared/assets/fonts/mono.ttf` | `TemaNexus.fonte_mono()` | `SystemFont` monoespaçada do sistema |
| Fonte da interface | `res://shared/assets/fonts/ui.ttf` | `TemaNexus` (fonte padrão do tema) | Fonte padrão da Godot |
| Ícone de aplicativo **(incluso: os 12 apps e `lixeira`, SVG)** | `res://shared/assets/icons/apps/<id>.svg` ou `.png` (`<id>` = campo `id` de `catalogo_apps.json`: `explorer`, `terminal`...; PNG com 128 px ou mais) | `UiKit.icone_app` (`IconeApp`) | Bloco colorido com o emoji do catálogo |
| Ícone do projeto | `res://shared/assets/icons/icon.svg` (já existe) | `project.godot` | — |
| Papel de parede **(incluso: dias 1 a 5, 1920×1080)** | `res://shared/assets/textures/wallpaper_<dia>.png` (dia 1 a 5) ou `wallpaper.png` | `PapelDeParede` (só no modo "dia" e sem Alto contraste; cobre a tela sem deformar) | Gradiente procedural com a paleta do dia, grade, círculos e marca "HumaxOS" |
| Imagem da Galeria **(incluso: `show_antigo.png`)** | `res://shared/assets/textures/<nome do arquivo virtual sem extensão, em minúsculas>.png`, `.jpg`, `.jpeg` ou `.webp` (ex.: `show_antigo.png`, `cachorro.png`, `data_stream.webp`) | `AppVisualizador._textura_real` | Imagem procedural gerada com semente fixa (`ImagemProcedural`) |
| Efeitos sonoros **(inclusos em `.wav`: `boot`, `clique`, `abrir`, `fechar`, `notificacao`, `erro`, `glitch`, `sucesso`, `tecla`)** | `res://shared/assets/audio/<nome>.ogg`, `.wav` ou `.mp3`. Nomes: `clique`, `tecla`, `abrir`, `fechar`, `minimizar`, `notificacao`, `mensagem`, `erro`, `alerta`, `sucesso`, `glitch`, `boot`, `final_bom`, `final_mau` | `SistemaAudio._carregar_arquivo` (o arquivo tem prioridade) | Tom gerado em código (`AudioStreamWAV`); `minimizar`, `mensagem`, `alerta`, `final_bom` e `final_mau` seguem procedurais |
| Trilha de cada dia **(inclusa: 48 s em laço por dia)** | `res://shared/assets/audio/bgm_dia_1.ogg` … `bgm_dia_5.ogg` | `SistemaAudio.tocar_bgm` (liga o laço em código; com "Reduzir ruído" a trilha de arquivo toca 6 dB mais baixa) | Drone gerado em código |
| Gravação do Dia 3 | `res://shared/assets/audio/gravacao_01.ogg` (ou `.wav`/`.mp3`) | `SistemaAudio.stream_gravacao` | Respiração sintetizada de 3 s |

Dicas de importação: fontes `.ttf`/`.otf`, ícones `.svg` e imagens `.png` são importados com as opções padrão; para músicas em `.ogg`/`.mp3`, marque **Loop** na aba Importar das trilhas `bgm_dia_*` (as trilhas incluídas já vêm com `loop=true` no `.import`, e o `SistemaAudio` também liga o laço em código). Depois de colocar um arquivo novo, abra o projeto no editor, espere a importação e versione o `.import` gerado ao lado dele; **nunca** versione a pasta `.godot/`. A pasta `shared/assets/*/` só existe no Git se tiver arquivo (por isso há `.gitkeep`).

## 8. Como carregar cenas

| Situação | Como | Falha |
|---|---|---|
| Trocar de tela (Splash → Menu → boot → área de trabalho → final) | `Cenas.ir_para(get_tree(), Cenas.AREA_DE_TRABALHO)` (usa `change_scene_to_file`) | Cena ausente ou erro: `push_error` e retorno `false`; a tela atual continua |
| Abrir um aplicativo | `GerenciadorJanelas.abrir_app("explorer", {"caminho": "/home/usuario"})` | App desconhecido, ainda bloqueado ou com cena ausente: aviso + toast e retorno `null` (nunca erro fatal) |
| Pedir um app a partir da narrativa | Ação `abrir_app` nos JSON → sinal `GerenciadorNarrativa.abrir_app_solicitado` → a área de trabalho chama `abrir_app` | A narrativa não conhece janelas, então não há dependência circular |
| Abrir um arquivo do VFS | `AbridorArquivos.abrir(caminho)` escolhe o app: pasta → Explorador; imagem e áudio → Galeria; texto → Bloco de Notas (ou Leitor de Texto, se for somente leitura ou criptografado) | Criptografado pede a chave antes; executável mostra o aviso "Programa simulado" e não executa nada; `.zip` abre a pasta de destino; item inexistente ou oculto mostra um toast de erro |
| Criar uma janela de diálogo | `await GerenciadorJanelas.confirmar(...)`, `.alerta(...)`, `.escolher(...)`, `.pedir_texto(...)`, `.escolher_arquivo(...)` | `Esc` sempre cancela |
| Ler dados da história | `FileAccess.get_file_as_string("res://core/data/...")` + `JSON.parse_string` | JSON ausente ou inválido: aviso e o jogo segue com o que carregou |

Cenas dos aplicativos (`features/apps/<nome>/scenes/app_<nome>.tscn`) são mínimas: raiz `Control` com o script. A interface é montada em código no `iniciar(args)`.

## 9. Salvar e carregar em `user://`

Nada do jogo grava fora de `user://nexus_os/`. O jogo **nunca apaga** arquivos reais: um salvamento ilegível é **renomeado** para `.corrompido`.

```text
user://nexus_os/
├── salvamento.json          # progresso: estado + VFS (autosave)
├── checkpoint_dia_<1..5>.json   # estado no início de cada dia
└── configuracoes.cfg        # preferências e acessibilidade (ConfigFile)
```

Onde fica `user://`: o nome do projeto (`config/name`) agora é `Maya Human Syntax`, mas a pasta dos salvamentos **não mudou**. Por padrão a Godot deriva essa pasta do nome do projeto; para não perder os salvamentos e as preferências que já existiam, `config/use_custom_user_dir=true` e `config/custom_user_dir_name="Godot/app_userdata/Nexus_OS_Build_Oficial"` fixam o caminho que o projeto sempre usou (o nome antigo do projeto, `Nexus_OS_Build_Oficial`, continua aparecendo aí de propósito). Uma segunda linha, `config/custom_user_dir_name.linuxbsd`, repete o caminho com `godot` em minúsculas só para Linux/BSD (veja a nota):

| Sistema | Pasta |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\Nexus_OS_Build_Oficial\nexus_os\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Nexus_OS_Build_Oficial/nexus_os/` |
| Linux | `~/.local/share/godot/app_userdata/Nexus_OS_Build_Oficial/nexus_os/` (veja a nota) |

> **Nota (Linux).** Com a pasta fixada, a Godot usa o texto de `custom_user_dir_name` tal como está, depois de `~/.local/share/`. Antes do rebranding, a pasta padrão do Linux era `~/.local/share/godot/app_userdata/Nexus_OS_Build_Oficial/nexus_os/` (com `godot` em minúsculas), enquanto no Windows e no macOS é `Godot`. Por isso `project.godot` traz a sobrescrita por tag de recurso `config/custom_user_dir_name.linuxbsd="godot/app_userdata/Nexus_OS_Build_Oficial"`, que vale só no Linux/BSD e mantém a grafia antiga; no Windows e no macOS a pasta é exatamente a mesma de antes. A Godot não estava disponível para conferir isso nesta rodada: o teste de fumaça só confere que `user://` termina em `.../app_userdata/Nexus_OS_Build_Oficial`, e o passo R5 de `docs/08_testes_manuais.md` descreve a conferência manual. Se num Linux a pasta aparecer com `Godot` em maiúsculas, a sobrescrita não foi aplicada: copie a pasta `nexus_os/` da pasta de minúsculas para a nova.

No editor: **Projeto → Abrir Pasta de Dados do Usuário**.

**Formato do salvamento** (`SistemaPersistencia`, versão 2):

```json
{
  "versao": 2,
  "salvo_em": "2026-11-07T19:00:00",
  "estado": { "nome_jogador": "...", "dia_atual": 3, "flags": {}, "chat": {}, "acoes_pendentes": [] },
  "vfs": { "versao": 1, "operacoes": [ { "op": "criar", "no": {} }, { "op": "texto", "c": "/home/usuario/Documentos/a.txt", "t": "..." } ] }
}
```

- `estado` é `GerenciadorEstado.para_dicionario()` (dia, jogador, flags, objetivos, apps liberados, permissões simuladas, processos, mensagens, contatos bloqueados, final).
- `vfs` guarda **apenas as operações do jogador** (criar, escrever, renomear, mover/lixeira, decifrar, revelar), que são reaplicadas sobre a árvore inicial (`vfs_inicial.json`) ao carregar. Assim o salvamento é pequeno e o conteúdo da história pode ser corrigido por atualização do jogo.
- **Quando salva:** a cada mudança relevante (flag, objetivo, mensagem, permissão, contato, arquivo), no máximo a cada 12 s; no início de cada dia (salvamento + checkpoint); ao chegar a um final; ao fechar a janela do jogo; e nos botões "Salvar" (menu iniciar, Configurações, painel de testes).
- **Como salva:** grava em `<arquivo>.tmp` e renomeia, para um corte de energia não deixar um arquivo pela metade.
- **Quando carrega:** o botão **Carregar** do Menu Principal (`Sessao.carregar`, que usa `SistemaPersistencia` e `GerenciadorNarrativa.retomar()`; ele não passa pela BIOS), o "Continuar jogo salvo" da tela de boot quando ela abre sem o contexto do Novo Jogo (fluxo antigo), a tela final ("Repetir o Dia 5" carrega `checkpoint_dia_5.json`) e a área de trabalho aberta direto no editor.
- **Versões e o rebranding.** A versão 2 tem o mesmo formato da 1: o que mudou foram os textos do jogo (NEXUS passou a Maya e HumaxOS). Ao carregar uma versão 1, `SistemaPersistencia._carregar_de()` chama `GerenciadorEstado.migrar_marca_antiga()`, que atualiza só os textos do chat (inclusive o original das mensagens editadas), dos processos suspeitos e das ações pendentes; e `SistemaArquivosVirtual` traduz os caminhos antigos do log de operações (`CAMINHOS_ANTIGOS`, por exemplo `/sistema/nexus` → `/sistema/maya`). IDs, flags, chaves de contato e o nome do jogador não mudam. Uma versão 2 não passa pela migração; uma versão maior que a atual continua sendo recusada.
- **Salvamento inválido** (versão desconhecida, JSON corrompido): é renomeado para `salvamento.json.corrompido`, o sinal `falha_ao_carregar` avisa a tela de boot e o jogador pode começar um novo jogo. Nada trava.
- **Para recomeçar do zero**, apague a pasta `nexus_os/` manualmente (o jogo não faz isso).

## 10. Como testar cada módulo

Preparação: abra o projeto no editor e rode com **F5**. Em build de depuração (inclusive o editor) o painel de testes abre com **F9**; ele pula objetivos e dias, dispara glitch, notificações e o processo malicioso, e lista as flags. Fora do editor, ligue "Painel de testes" em Configurações → Sistema.

| Módulo | Como testar | Resultado esperado | Testes de `08` |
|---|---|---|---|
| Autoloads e Input Map | Abrir o projeto; **Configurações do Projeto → Globais**; pressionar `F1`, `F9`, `F11` | 9 autoloads na ordem acima; as teclas respondem; Output sem erros | 1, 32 |
| Splash e Menu | F5; esperar a animação (ou Espaço, Enter, Esc ou clique para pular) | A logo aparece na hora, a animação toca sozinha, o Menu Principal abre e nenhum botão é acionado ao pular | 1, S1–S6 |
| Boot | F5 → Splash → **Novo Jogo**; qualquer tecla pula o log (depois de 0,4 s); digitar o nome; "Entrar no sistema" | BIOS → registro → saudação com o nome → área de trabalho | 1, 2, 3 |
| Área de trabalho e Dia 1 | Observar widgets, ícones, toasts, cartão "DIA 1" | Papel de parede roxo, objetivos no widget da Maya, mensagem da Maya após ~1,5 s | 3, 4, 28 |
| Menu iniciar e barra | `F1`; digitar "term" (aparece só depois do Dia 2); abrir 3 apps | Menu lê o catálogo; a barra mostra uma entrada por janela | 5, 12 |
| Janelas | Arrastar, minimizar, restaurar, maximizar, fechar; `Ctrl+Tab`, `Ctrl+M`, `Ctrl+W` | Janela respeita os limites; foco e ordem corretos | 7–11 |
| VFS e Explorador | Navegar; criar arquivo/pasta; renomear; excluir (vai para a Lixeira); restaurar | Nada some de verdade; nomes inválidos são recusados com mensagem | 13, 14 |
| Bloco de Notas | Abrir arquivo, editar, salvar, fechar com alteração, reabrir | Confirma antes de descartar; texto igual ao salvo | 15 |
| Terminal | `help`, `ls`, `cd`, `cat`, `ps`, `rm -rf /`, comando inexistente | Só comandos simulados; os perigosos são recusados; erros claros | 16, 17, 30 |
| Calculadora | `1 ÷ 0 =` | Estado de erro claro, sem travar | 18 |
| Configurações | Mudar tema, volume, acessibilidade; fechar e reabrir o jogo | Valores persistem | 19, 29 |
| Navegador | `humax://` e um endereço externo | Só `humax://` abre; o resto mostra "Endereço bloqueado" | 20 |
| Mensagens, E-mail e Agenda | F9 → "Ir para o dia" 1…5 e abrir cada app | Contatos, mensagens, e-mails e compromissos mudam por dia | 21, 22 |
| Galeria | Abrir imagens e `gravacao_01.wav` | Imagem (real ou procedural) e áudio gerado; painel de metadados | 23, 26 |
| Monitor e processo malicioso | F9 → "Processo malicioso"; abrir o Monitor; encerrar o processo suspeito | Barra de extração controlada pelo jogo; sucesso e falha tratados | 24, 25 |
| Puzzles | Lógica (pasta `PROJECT_Icarus`), metadados (`Show_Antigo.jpg`), chaves (Lixeira e zip) | Cada um resolve com a resposta certa e dá dicas após erros | 26, 27 |
| Terminal de emergência e finais | F9 → dia 5; `root_access ICARUS-7741`; `scan_maya`; `reset_core`; uma saída | Os 4 finais podem ser alcançados | 30, 31 |
| Persistência | Jogar, fechar, abrir e "Continuar jogo salvo" | Mesmo dia, flags, mensagens e arquivos | 2, 19 |

**Teste de fumaça sem interface** (verifica autoloads, catálogo, cenas, dados, VFS, os cinco dias e o modo assistido, a calculadora, os metadados da foto, a agenda, os contatos e o navegador, os quatro finais, o processo malicioso, o estado serializado, a acessibilidade e o áudio; com `-- --ui`, também abre todas as janelas):

```bash
godot --headless --path . res://tests/smoke_test.tscn
godot --headless --path . res://tests/smoke_test.tscn -- --ui
```

O código de saída é 0 quando tudo passa. O teste trabalha só em memória e desliga o salvamento do jogo (veja o cabeçalho de `tests/smoke_test.gd`). Última execução na Godot 4.7.2 (2026-11-13): 308 verificações sem a etapa de interface e 345 com `-- --ui`, todas OK (em 2026-11-12 eram 258 e 295). Além do que a lista acima já citava, o teste confere agora a mídia autoral (ícones, papéis de parede, a foto-pista, os 9 efeitos e as 5 trilhas em laço, com o recorte de cobertura do papel de parede) e os padrões de segurança (backend desligado, painel de testes só em depuração).

**Testes que rodam no editor** (abra a cena e aperte F6; os logs vão para `tests/_saida/`):

| Teste | Como rodar | Última rodada |
|---|---|---|
| Interação de interface | `tests/ui_interacao/ui_interacao.tscn` | 554 verificações, 0 falhas |
| Resoluções | `tests/resolucoes/resolucoes.tscn` | 139 verificações, 0 falhas |
| Persistência em disco | `tests/persistencia/persistencia.tscn` | 119 verificações, 0 falhas; 6 avisos esperados no Depurador |
| Fluxo de sessão (Menu Principal, Pausa, Fim de Jogo) | `tests/fluxo_sessao/fluxo_sessao.tscn` | 194 verificações, 0 falhas; 6 mensagens esperadas no Depurador |
| Splash Screen (abertura, pulo, falhas, acessibilidade) | `tests/splash/splash.tscn` | 311 verificações, 0 falhas; mensagens esperadas no Depurador (falhas provocadas de propósito) |
| Avisos de configuração de nó | `tests/avisos_editor/varredura_editor.gd`, *Arquivo → Executar* (Ctrl+Shift+X) | 63 cenas, 0 avisos |
| Capturas e árvores | `tests/ui_dump/ui_dump.tscn` (rodadas e unidades em `rodada.txt`) | ferramenta de conferência visual |

O teste de persistência usa a pasta `user://nexus_os_teste/exec_<tempo>/` (uma nova a cada execução; ele nunca apaga nada, então as pastas antigas podem ser removidas à mão) por meio de dois ganchos só de teste: `SistemaPersistencia.pasta` e `GerenciadorConfiguracoes.caminho`. Os dois padrões apontam para `user://nexus_os/` e qualquer valor fora de `user://` é recusado com aviso, então o jogo nunca grava em `res://`.

**Validação estática** (não precisa da Godot):

```bash
python3 -I tools/validar_projeto.py
```

Procura erros comuns de sintaxe, chamadas a funções que não existem, sinais com assinatura errada, caminhos `res://` ausentes e APIs proibidas (`OS.execute`, `eval`, `OS.shell_open`, remoção de arquivos, rede). Termina com código 1 se encontrar erro. Heurística: não substitui o Output da Godot.

## 11. Exportação

O projeto não traz `export_presets.cfg` (é gerado pelo editor e depende da máquina). Ao criar um preset:

| Campo | Valor |
|---|---|
| Filtros para exportar arquivos não-recurso | `*.json, *.ogv` (os dados da história em `core/data/` são lidos com `FileAccess`; o `*.ogv` é uma precaução para o vídeo da Splash, que não é um recurso importado e não tem `.import`) |
| Excluir arquivos/pastas | `tools/*, docs/*, tests/*, backend/*, addons/*` |
| Recursos | Exportar todos os recursos do projeto |

Imagens, SVGs e áudio são recursos importados: entram na exportação sem filtro extra, desde que os `.import` estejam versionados (o editor refaz o cache `.godot/imported/` ao exportar). Os geradores `tools/gerar_*.py` ficam fora pela exclusão de `tools/*`.

O `backend/` (protótipo em C, com um `main.exe` de terceiros) não faz parte do jogo e fica fora da exportação.

**Verificação feita em 2026-11-12.** O Godot 4.7.2 usado nos testes não tinha os modelos de exportação instalados (*Editor → Gerenciar modelos de exportação*), então não foi possível gerar nem rodar o executável. Com um preset *Windows Desktop* configurado como na tabela acima (filtro `*.json`; exclusão `tools/*, docs/*, tests/*, backend/*, addons/*`), *Exportar PCK/ZIP* (sem "Exportar como patch") numa pasta fora do projeto gerou um ZIP de 342 arquivos (8 MB) que traz as 9 bases JSON de `core/data/`, as 55 cenas e os 74 scripts compilados, `project.binary`, os ícones, as texturas e o áudio importados (20 `.ctex`, 9 `.sample`, 5 `.oggvorbisstr`) e nenhum arquivo de `tools/`, `docs/`, `tests/`, `backend/` ou `addons/`. Isso confirma o conteúdo do pacote e que todos os scripts compilam na exportação; **não** confirma que o jogo abre a partir do pacote. Para essa conferência, instale os modelos, exporte o executável para uma pasta isolada e rode o teste manual 1 de `08_testes_manuais.md`. A Splash Screen (2026-11-13) acrescentou ao projeto o vídeo `features/splash_screen/assets/maya_human_syntax_intro.ogv`, que não é um recurso importado; esse ZIP **não foi refeito** depois dela, então não se sabe se o vídeo entra no pacote sem o filtro `*.ogv` (por isso ele consta na tabela acima, por precaução). Se o vídeo faltar no executável, a Splash mostra a logo estática e segue para o Menu (veja [`15_splash_screen.md`](15_splash_screen.md)).
