# 15. Splash Screen: a abertura da marca

> Rodada de 2026-11-13, na Godot 4.7.2 (Windows). Este documento descreve a Splash **como está implementada e testada**; a seção 9 traz os números de cada suíte e a seção 11 diz o que **não** foi verificado. Os nomes de arquivo, classes, nós, flags, ações do mapa de entrada e a pasta `user://nexus_os/` continuam os de antes (identificadores internos preservados, como no rebranding). O fluxo de sessão (Menu Principal, Pausa, Fim de Jogo) está no [`docs/14`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md); onde ele diz que a `TelaBoot` é a cena principal, vale este documento.

## 1. Resumo

```text
Executável
  └─ Splash Screen (cena principal; só a marca "Maya Human Syntax": logo estática → vídeo de 10 s; Espaço, Enter, clique, Esc ou botão do controle pulam)
       └─ Menu Principal ─┬─ Novo Jogo ─► (confirma, se há progresso) ─► boot do HumaxOS (TelaBoot: BIOS ─► registro do nome ─► saudação da Maya) ─► área de trabalho (Dia 1)
                          ├─ Carregar ──► salvamento lido e conferido ─► estado aplicado ─► área de trabalho (ou TelaFinal, se a história já terminou)   [sem BIOS, sem registro, sem Splash]
                          ├─ Opções ────► painel de opções
                          ├─ Créditos ──► painel de créditos
                          └─ Sair do jogo
```

- A Splash é uma cena **independente**: ela só consome três serviços que já existiam, `Cenas` (a única camada de troca de cena), `SistemaAudio` (o barramento `BGM`, que obedece ao volume do jogador) e `GerenciadorConfiguracoes` (acessibilidade). Não toca na `TelaBoot`, na área de trabalho, no estado de um novo jogo, na narrativa, na progressão, nos checkpoints, nos salvamentos, no terminal nem em app algum.
- O boot do HumaxOS (BIOS, registro, saudação da Maya) só abre quando o jogador escolhe **Novo Jogo**. **Carregar** segue o caminho de persistência de sempre (`Sessao.carregar`) e nunca passa pelo boot.
- Nenhum autoload foi criado ou duplicado, nenhuma ação nova foi registrada no mapa de entrada e nenhum segundo gerenciador de cenas, de áudio ou de carregamento existe.

## 2. Diagnóstico inicial (o que havia antes)

Conferido no pacote da rodada anterior (`Maya_Human_Syntax_menu_pausa_fim_de_jogo_final.zip`, 420 arquivos):

| Ponto | Estado antes | Risco |
|---|---|---|
| Cena principal | `run/main_scene="uid://dn6752s6df8if"`, a `TelaBoot`. Ela rodava a BIOS e **ia sozinha ao Menu Principal**. | A BIOS vinha antes do menu (o contrário do fluxo pedido) e fazia parte de toda abertura do jogo, inclusive de quem só queria Carregar |
| Menu Principal | `features/menu_principal/`; **Novo Jogo** abria o registro da `TelaBoot` em modo "registro", sem BIOS. Não dependia de nenhum estado criado pela BIOS (lê só `SistemaPersistencia`, `Sessao` e `GerenciadorConfiguracoes`). | Ao tirar a BIOS do caminho de entrada, o Novo Jogo precisava passar a abri-la |
| `TelaBoot` | BIOS → Menu (ou registro antigo, se o menu falhasse); modo "registro" com "Voltar ao menu" | Dois fluxos misturados na mesma cena |
| Gerenciador de cenas | `Cenas.ir_para` (guarda de transição, carga em segundo plano, `get_tree().paused = false` antes da troca, contexto entre cenas) e a fachada `Sessao` | Nada a criar: a Splash usa a mesma porta de saída das outras telas |
| Autoloads | Os nove de sempre (`RelogioGlobal`, `GerenciadorConfiguracoes`, `GerenciadorEstado`, `SistemaAudio`, `SistemaNotificacoes`, `SistemaArquivosVirtual`, `GerenciadorJanelas`, `GerenciadorNarrativa`, `SistemaPersistencia`) | Todos já existem quando a primeira cena abre; a Splash não pode instanciá-los de novo |
| Assets | Não havia vídeo nem logo de abertura. Recebidos: `Maya_Human_Syntax_intro.mp4` (H.264 + AAC, 1280×720, 24 fps, 10,03 s, 2,96 MB) e `MayaOS_Intro_Logo.jpg` (1024×1024) | **A Godot 4.7 não toca H.264**: o `.mp4` não é reproduzível pelo núcleo (ver a seção 5) |
| Áudio | `SistemaAudio` (barramentos `BGM` e `SFX`, enviados a `Master`; volumes e "Reduzir ruído" do `GerenciadorConfiguracoes`) | Um player de áudio a mais ou um barramento novo duplicaria o sistema |
| Acessibilidade | `GerenciadorConfiguracoes`: `reduzir_glitch`, `sem_flashes`, `reduzir_animacoes`, `reduzir_ruido`, `alto_contraste`, modo conforto (Ctrl+Shift+D), tela cheia (F11) | A animação tem uma rajada de glitch: precisa respeitar essas opções |
| Mapa de entrada | `ui_accept` (Enter, Enter do teclado numérico, Espaço) e `ui_cancel` (Esc) do motor; as ações `nexus_*` criadas em código | Nenhuma ação nova é necessária. `ui_accept` **não** tem botão de controle no motor: o controle é tratado por código |
| Testes de inicialização | `tests/fluxo_sessao` arrancava pela `TelaBoot`; o teste de fumaça e o de resoluções assumiam o fluxo antigo | Precisaram ser ajustados ao novo arranque |
| Cor de limpeza do motor | Cinza padrão (0,3) e imagem de boot padrão da Godot | Um cinza apareceria entre o fade preto da Splash e a entrada do Menu |

O que já estava certo e foi **preservado**: `Cenas.ir_para` como porta única das trocas de cena, os nove autoloads, o formato do salvamento (`VERSAO` 2), os checkpoints, o autosave, as flags, as janelas e os quatro finais.

## 3. Arquivos criados e alterados

Comparação com o pacote da rodada anterior (420 arquivos): **7 arquivos de jogo novos** (cena, script, vídeo, logo e os `.uid`/`.import` que a própria Godot gera), **3 de teste novos**, este documento e a evidência em `tests/_saida/`; **4 arquivos de jogo alterados**, 4 suítes alteradas, os documentos e a ferramenta de documentação. Nenhum arquivo foi removido. Nenhum autoload, ação do mapa de entrada, classe, ID, flag ou caminho de salvamento foi criado, renomeado ou removido.

| Arquivo | Alteração | Motivo | Dependências | Testes |
|---|---|---|---|---|
| `features/splash_screen/scenes/splash_screen.tscn` | **Novo.** 16 nós: `SplashScreen` (Control, `process_mode` sempre), `FundoPreto`, `ContainerVideo` (AspectRatioContainer 16:9) com `VideoLogo`, `LogoFallback`, `CamadaInteracao` com `IndicadorPular`, `PainelFalha` (título, mensagem, "Tentar novamente", "Sair do jogo") e `FadeOverlay` | Cena independente e editável, primeira do jogo | O script e a logo PNG | `tests/splash` (estrutura e geometria), varredura do editor (0 avisos) |
| `features/splash_screen/scripts/splash_screen.gd` (+ `.uid`) | **Novo.** `SplashScreen`: fases, carga em segundo plano, primeiro quadro válido, fallback, pulo, fade e saída única | Comportamento da abertura | `Cenas`, `SistemaAudio`, `GerenciadorConfiguracoes`, `TemaNexus`, `UiKit`, `Conexoes` | `tests/splash` (311), `tests/fluxo_sessao` |
| `features/splash_screen/assets/maya_human_syntax_intro.ogv` (+ `.uid`) | **Novo.** A animação da logo convertida para Ogg Theora + Vorbis (a Godot não toca o MP4 recebido) | Formato que o núcleo da Godot 4.7 reproduz | `VideoStreamPlayer` | `tests/splash` (é um `VideoStreamTheora`, contêiner Ogg de verdade, toca de fato) |
| `features/splash_screen/assets/mayaos_intro_logo.png` (+ `.import`) | **Novo.** A logo estática (1024×1024, fundo preto puro) derivada de `MayaOS_Intro_Logo.jpg` | Fallback visual e fase estática | `LogoFallback` | `tests/splash` (carrega; cantos pretos puros) |
| `project.godot` | `run/main_scene` passa a ser a Splash (caminho `res://…`); `boot_splash/bg_color` preto e `boot_splash/show_image=false`; `default_clear_color` preto | A Splash é a primeira cena; nada cinza ou com a imagem padrão da Godot antes dela ou entre ela e o Menu | — | Fumaça (confere os três valores), `tests/splash` |
| `core/utilities/cenas.gd` | Acrescenta a constante `SPLASH`; comentários da camada e de `BOOT` atualizados | Caminho único da cena, como as demais | — | Fumaça (as cenas principais existem), `tests/splash` |
| `features/menu_principal/scripts/menu_principal.gd` | **Novo Jogo** passa a abrir a `TelaBoot` (BIOS) com o contexto `modo = "novo_jogo"` e a mensagem "Iniciando o HumaxOS…"; antes abria o registro direto | O boot do HumaxOS só acontece depois de Novo Jogo | `Cenas.definir_contexto`, `Cenas.BOOT` | `tests/fluxo_sessao` (Novo Jogo abre a `TelaBoot` uma única vez; Carregar não abre) |
| `features/shell/tela_boot/scripts/tela_boot.gd` | Não é mais a cena principal nem leva ao Menu: a BIOS termina no registro. No contexto `novo_jogo` o registro não oferece "Continuar jogo salvo", mostra "Voltar ao menu" (Esc também) e não repete a confirmação de substituir o salvamento. Janela de 0,4 s em que um toque não pula a BIOS (o 2º clique de um clique duplo em Novo Jogo). Sem o contexto, o fluxo antigo completo continua | Separar o boot da abertura e do menu | `Cenas.consumir_contexto` | `tests/ui_interacao` (4ª instância do boot), `tests/fluxo_sessao`, `tests/splash` |
| `tests/splash/splash.gd`, `splash.tscn` (+ `.uid`) | **Novos.** A suíte da Splash (311 verificações) | Provar a abertura no motor | — | — |
| `tests/smoke_test.gd`, `tests/fluxo_sessao/fluxo_sessao.gd`, `tests/ui_interacao/ui_interacao.gd`, `tests/resolucoes/resolucoes.gd` | Verificações novas e arranque pela Splash (seção 9) | Cobertura do novo fluxo | — | as próprias suítes |
| `README.md`, `docs/01`, `02`, `03`, `05`, `07`, `08`, `09`, `14`, `tools/gerar_docs_ui.py` (que regenera o `04` e o `10`), `docs/06` e `docs/13` (regenerados), `tests/_saida/` | Nova cena principal, fluxo, números e este documento | Documentação em dia | — | validador, auditor de marca |

## 4. Como a Splash funciona

### 4.1 Estrutura da cena

`SplashScreen` ocupa a janela inteira (`process_mode` sempre: nunca fica presa, mesmo com a árvore pausada). De baixo para cima: `FundoPreto` (preto puro), `ContainerVideo` (`AspectRatioContainer` em 16:9, modo *fit*) com o `VideoLogo` (`VideoStreamPlayer` com `expand`, sem autoplay e sem laço), `LogoFallback` (`TextureRect` centralizado, `KEEP_ASPECT_CENTERED`), `CamadaInteracao` com o `IndicadorPular`, o `PainelFalha` e o `FadeOverlay` (preto puro). Todos os nós usados pelo script têm nome único (`%`). Em 4:3, 16:10, 21:9 e até em 9:16 o vídeo e a logo ficam centralizados, sem esticar, e o resto é preto (as quatro fotos em `tests/_saida/resolucoes/splash_*.png` e a linha "Splash" da folha de contato).

### 4.2 Fases

```text
CARREGANDO ──► REPRODUZINDO ──► (fim, pulo ou tempo) ──► SAINDO ──► Menu Principal
     │               │                                       ▲
     └──► ESTATICA ──┴───────────────────────────────────────┘         FALHA_NO_DESTINO (o Menu não abriu)
     (falha do vídeo ou acessibilidade)                                  └─► "Tentar novamente" ──► SAINDO
```

1. **Primeiro quadro.** `_ready` deixa o fundo preto, a logo estática visível e opaca, o vídeo **invisível** (`modulate.a = 0`) e o fade transparente. Nunca há tela vazia ou branca (medido: luminância média 0,042 no primeiro quadro desenhado, 0,063 no máximo durante a abertura inteira).
2. **Carregando.** O vídeo é pedido em segundo plano (`ResourceLoader.load_threaded_request`) e acompanhado a cada quadro. Se não ficar disponível em `tempo_maximo_carga_s` (4 s) ou o recurso for inválido, a Splash passa à fase estática.
3. **Reproduzindo.** O vídeo é iniciado **uma única vez**. Ele continua invisível até existir o **primeiro quadro válido** (`get_video_texture()` não nulo e com tamanho); só então a proporção do vídeo é aplicada ao contêiner e a logo estática se dissolve em `duracao_dissolver_s` (0,5 s). Medido: primeiro quadro válido em 0,34 s. Se não vier em `tempo_primeiro_quadro_s` (3 s) ou o player parar antes, volta à logo estática.
4. **Fim.** O sinal `finished` (ou o player parado sem sinal) leva à saída com o motivo "fim da animação". Se `finished` nunca vier, `tempo_maximo_reproducao_s` (15 s) encerra a abertura com o motivo "tempo máximo da animação" e um aviso no log de desenvolvimento. Medido: o Menu abre 10,8 s depois da abertura.
5. **Estática.** Só a logo, por um tempo mínimo (`duracao_estatica_s`, 2,5 s contados desde a abertura, nunca menos de 1 s depois de uma falha), e depois a saída.
6. **Saindo.** No começo da saída a mídia é parada (o volume desce em 0,12 s e o vídeo para) e a tela escurece num fade para preto (`duracao_fade_saida_s`, 0,35 s; 0,15 s com "Reduzir animações"). A troca de cena só acontece depois do fade e quando o jogador **para de apertar** por 0,25 s (no máximo 1 s depois do fim do fade): quem aperta Enter várias vezes para pular não aciona, sem querer, o primeiro botão do Menu. Quando a saída não veio de um pulo (o vídeo terminou sozinho), não há o que esperar e a troca é imediata ao fim do fade.

### 4.3 Saída única

Toda saída (fim do vídeo, pulo, tempo limite, fim da logo estática, nova tentativa) passa por `_ir_para_menu_principal(motivo)`, protegida por `_transicao_iniciada`. `finished`, o teclado, o mouse e o vigia de tempo podem chegar juntos que **só a primeira** conta: não há troca dupla, instância dupla do Menu nem retorno à BIOS. A troca em si é `Cenas.ir_para(get_tree(), caminho_destino, _ao_falha_da_troca)` (que, como em toda troca, faz `get_tree().paused = false` antes de sair; a Splash também o faz). Não existe nenhuma chamada a `change_scene_to_file` no script.

### 4.4 Pular

| Entrada | Como é tratada |
|---|---|
| Espaço, Enter, Enter do teclado numérico | `ui_accept` (ação do motor, já usada pelo jogo) |
| Esc | `ui_cancel` (ação do motor). Na Splash não há nada para fechar, então não há conflito |
| Botão esquerdo, direito ou do meio do mouse | `InputEventMouseButton` pressionado (a roda não pula) |
| Qualquer botão do controle | `InputEventJoypadButton` pressionado, tratado no código: o `ui_accept` do Godot 4.7.2 **não** tem botão de controle (verificado: `[Enter, Kp Enter, Space]`) |
| Toque na tela | `InputEventScreenTouch` pressionado |

Eventos repetidos (`echo`) não contam. O pulo vale em **qualquer** momento, inclusive enquanto o vídeo ainda carrega. Nenhuma ação nova (`skip_splash` ou outra) foi registrada: as já existentes bastam. Letras, Shift e a roda do mouse não pulam. Ao pular, o som desce em 0,12 s e o vídeo para (medido: o vídeo para 0,12 s depois do pedido; o Menu abre 0,43 s depois), e o fade segue. Se o pulo chegou durante a carga, a carga pendente é recolhida em `_exit_tree` e nenhum retorno de chamada toca a cena destruída.

### 4.5 Áudio

O som do vídeo sai pelo `VideoStreamPlayer` no barramento `BGM` do `SistemaAudio` (`SistemaAudio.BUS_BGM`): vale o volume geral, o de música e o mudo do jogador, e **nenhum player de áudio foi criado** (o teste conta os players antes e depois). O vídeo foi masterizado baixo (cerca de −32 LUFS contra −20 LUFS das trilhas, que tocam a −6 dB), então a Splash soma `ganho_audio_db` (+6 dB) para igualar o nível ao da trilha nos volumes padrão; "Reduzir ruído" desce 6 dB (e desligar a opção no meio do vídeo devolve o volume). Ao terminar, pular, fechar a janela ou sair da árvore, o vídeo e o som param (pico do barramento `BGM` cai de −27,6 dB para −200 dB, isto é, silêncio); o volume dos barramentos nunca é alterado pela Splash. A Splash não inicia nenhuma trilha nem o som de boot (esses sons pertencem ao Menu e à `TelaBoot`).

### 4.6 Acessibilidade

| Opção | O que a Splash faz |
|---|---|
| "Reduzir glitch", "Sem flashes" ou "Reduzir animações" (ligadas antes de abrir) | A animação (que tem uma rajada de glitch) **não toca**: fica a logo estática por no mínimo 2,5 s e depois o Menu; o pulo continua valendo. Com "Reduzir animações" o fade cai para 0,15 s e a dica aparece sem animação |
| Modo conforto (Ctrl+Shift+D) com a animação já tocando | A animação para na hora (vídeo e som), fica a logo estática e a abertura segue |
| "Reduzir ruído" | −6 dB no som do vídeo, também no meio da reprodução |
| Alto contraste | A dica "Pressione Espaço para pular" passa de 70 % para 100 % de opacidade e o tema de alto contraste é aplicado (medido: 0,70 → 1,00) |
| Volume geral zerado ou mudo | O vídeo fica sem som (o barramento `BGM` envia ao `Master` mudo) |
| F11 | Alterna a tela cheia (a Splash trata a tecla como toda tela do jogo) |

A dica "Pressione Espaço para pular" aparece depois de 1 s (`atraso_dica_s`), pequena, com o estilo de texto fraco do tema (`RotuloFraco`) e 70 % de opacidade, para não competir com a logo. Ela aparece também na fase estática (modo conforto e falha do vídeo) e some assim que a saída começa.

### 4.7 Uma vez por execução

`SplashScreen.ja_exibida` (variável estática) vale para a execução do jogo: se a cena for instanciada de novo no mesmo processo, ela vai direto ao Menu, sem vídeo nem som. Nada no jogo pede a Splash de volta (verificado por busca nos scripts); "Retornar ao menu inicial" abre o Menu Principal. `exibir_somente_uma_vez` (exportada) existe para uma futura opção "Assistir abertura".

### 4.8 O Menu não abre

Se `Cenas.ir_para` recusar o pedido ou falhar de forma assíncrona (Menu ausente ou ilegível), a Splash **nunca** cai na BIOS, no jogo nem numa tela preta: mostra o painel "Não foi possível abrir o Menu Inicial" com **Tentar novamente** (com o foco) e **Sair do jogo**, a logo estática esmaecida atrás, e a guarda de `Cenas` já liberada. O Espaço não pula esse aviso; só os botões agem. "Tentar novamente" é um pedido explícito do jogador e reabre a guarda uma única vez.

## 5. Os assets

| Arquivo | Origem | Conversão e decisão |
|---|---|---|
| `maya_human_syntax_intro.ogv` | `Maya_Human_Syntax_intro.mp4` (H.264 1280×720 24 fps, AAC 48 kHz estéreo, 10,03 s, 2.955.633 bytes) | A Godot 4.7 só toca **Ogg Theora** (com som Ogg Vorbis) no núcleo; H.264 exigiria uma extensão (GDExtension) que o projeto não tem. O arquivo foi convertido com o ffmpeg para Theora (qualidade 9, GOP de 64 quadros, 1280×720, 24 fps) e Vorbis (44,1 kHz, estéreo, 192 kb/s): 10,0 s, **2.409.603 bytes**, sem redução de resolução nem de quadros. O `.mp4` **não** vai no pacote (um segundo arquivo "igual" só confundiria) |
| `mayaos_intro_logo.png` | `MayaOS_Intro_Logo.jpg` (1024×1024 JPEG) | PNG 1024×1024 sem transparência; o ruído de compressão do JPEG ao redor da logo foi zerado para **preto puro** (os cantos são verificados no teste), então a logo estática se encaixa no fundo preto sem formar um quadrado visível |

O vídeo **não é um recurso importado** (o `.ogv` é lido direto pelo carregador de Theora, sem arquivo `.import`); por precaução, o preset de exportação inclui o filtro `*.ogv` (seção 8). O PNG é importado como qualquer textura (o `.import` vai versionado).

A autoria e a licença da logo e do vídeo não estão declaradas; os créditos não as citam (mesma regra do logo do Menu Principal: nada foi inventado).

## 6. Integridade do boot

- A Splash **não referencia** a `TelaBoot`, a área de trabalho, `GerenciadorNarrativa`, `GerenciadorEstado`, `SistemaPersistencia` nem `Sessao` (o teste procura esses termos no script e não acha nenhum), não grava arquivo algum (0 arquivos de salvamento criados) e não altera a campanha.
- **Novo Jogo** (Menu): confirmação se há progresso → `Cenas.definir_contexto({"modo": "novo_jogo"})` → `TelaBoot` (BIOS com o som de boot; Espaço, Enter ou clique a pulam, mas só depois de 0,4 s) → registro do nome e das opções de acessibilidade, **sem** "Continuar jogo salvo" e com "Voltar ao menu" → saudação da Maya → `Sessao.novo_jogo` → área de trabalho no Dia 1.
- **Carregar** (Menu): `Sessao.carregar` lê e confere o ponto de carga, carrega a cena de destino e só então aplica o estado (como na Pausa e no Fim de Jogo). O teste confere que nenhuma `TelaBoot` nem Splash é criada nesse caminho.
- **Desvio documentado do fluxo pedido.** O fluxo da especificação mostra "inicialização do estado da campanha" antes do boot. Aqui a campanha só é iniciada **no fim da saudação** (`Sessao.novo_jogo`), porque o nome do jogador só existe depois do registro, que faz parte do boot. Consequência boa: abandonar o boot ("Voltar ao menu" ou Esc) nunca mexe no salvamento nem no estado.
- Sem o contexto `novo_jogo` (a cena aberta isoladamente, o painel de testes, ou `Sessao.voltar_ao_menu` quando o Menu não existe), a `TelaBoot` mantém o fluxo antigo completo (BIOS → registro com "Continuar jogo salvo" → saudação).

## 7. `project.godot`

```ini
[application]
run/main_scene="res://features/splash_screen/scenes/splash_screen.tscn"
boot_splash/bg_color=Color(0, 0, 0, 1)
boot_splash/show_image=false

[rendering]
environment/defaults/default_clear_color=Color(0, 0, 0, 1)
```

- `run/main_scene` passou de `uid://dn6752s6df8if` (a `TelaBoot`) para o caminho da Splash. Os autoloads são criados antes de qualquer cena e **não** dependem da cena principal.
- `boot_splash`: preto e sem a imagem padrão da Godot, para a janela não piscar nada antes da Splash.
- `default_clear_color` preto: o Menu Principal entra com `modulate.a = 0` e um fundo cinza padrão apareceria entre o fade preto da Splash e o fade de entrada do Menu.
- Depois de mudar o `project.godot` fora do editor, use **Projeto → Recarregar o projeto atual** (a Godot só relê o arquivo ao abrir o projeto).

## 8. Exportação

O projeto não traz `export_presets.cfg` (é gerado pelo editor e depende da máquina). Ao criar um preset, o filtro de arquivos não-recurso passa a ser **`*.json, *.ogv`**. O `*.json` já era necessário. O `*.ogv` é uma **precaução**: o vídeo não é um recurso importado, e este projeto não verificou, num pacote exportado, se a Godot o inclui sem o filtro. Se ele ficar de fora do pacote, a Splash cai na logo estática no executável, sem travar (o aviso vai para o log de desenvolvimento). O `.png` entra como as demais texturas. O restante da seção 11 do [`docs/07`](07_integracao.md) continua valendo. **O executável não foi gerado nem testado** (o Godot onde o projeto foi verificado não tem modelos de exportação), e a exportação em PCK/ZIP feita em 2026-11-12 (`docs/07`, seção 11) não foi refeita depois da Splash.

## 9. Testes e resultados

Todos rodados no editor da Godot 4.7.2 (Windows), com os arquivos finais deste pacote. Os logs e as capturas de tela estão em `tests/_saida/`.

| Teste | Como rodar | Resultado |
|---|---|---|
| Validador estático | `python3 -I tools/validar_projeto.py` | 0 erros, 0 avisos (94 scripts, 72 cenas, 9 autoloads, 75 classes) |
| Auditoria de marca | `python3 -I tools/auditar_marca.py` | sai com 0 |
| Fumaça com interface | `tests/smoke_test.tscn`, argumentos `-- --ui` | **345 verificações, 0 falhas** (341 antes). As 4 novas: a cena da Splash carrega e tem script (2) e duas conferências do `project.godot` (tela de boot do motor preta e sem imagem; cor de limpeza preta). A conferência da cena principal passou a exigir a Splash |
| Fumaça sem interface | `tests/smoke_test.tscn`, sem argumentos | **308 verificações, 0 falhas** (304 antes) |
| **Splash** (novo) | `tests/splash/splash.tscn` | **311 verificações, 0 falhas** |
| Fluxo de sessão | `tests/fluxo_sessao/fluxo_sessao.tscn` | **194 verificações, 0 falhas**; 6 mensagens esperadas no Depurador (186 antes) |
| Interação de interface | `tests/ui_interacao/ui_interacao.tscn` | **554 verificações, 0 falhas** (544 antes; as 10 novas são o boot aberto pelo Novo Jogo) |
| Resoluções | `tests/resolucoes/resolucoes.tscn` | **139 verificações, 0 falhas** (119 antes; as 20 novas são a Splash em 16:9, 16:10, 21:9 e 4:3) |
| Persistência | `tests/persistencia/persistencia.tscn` | **119 verificações, 0 falhas**; 6 avisos esperados no Depurador (inalterada) |
| Avisos do editor | `tests/avisos_editor/varredura_editor.gd`, *Arquivo → Executar* | **63 cenas, 0 avisos** (62 antes; a nova é a Splash) |

**Isolamento.** Nenhuma suíte lê nem grava `user://nexus_os/` (o salvamento e as preferências do jogador): a Splash usa `user://nexus_os_teste_splash/exec_*`, o fluxo `user://nexus_os_teste_fluxo/exec_*`, e assim por diante, cada uma com uma subpasta nova por execução (o jogo e os testes nunca apagam arquivos).

A suíte **`tests/splash`** prova, com o motor real e a cena instanciada como cena principal:

- **Projeto e assets**: a cena principal é a Splash; o vídeo é um `VideoStreamTheora` e um Ogg de verdade; a logo carrega e tem cantos pretos puros; a pasta de assets tem só o `.ogv` e o `.png`; o script não cita boot, jogo, salvamento, narrativa nem apps; a saída passa por `Cenas`; nenhum script pede a Splash de volta.
- **Geometria** (16:9, 16:10, 21:9, 4:3 e 9:16): logo centralizada e sem distorção, vídeo 16:9 sem esticar, fundo preto.
- **Execução limpa**: o primeiro quadro tem a logo sobre preto; o vídeo começa sozinho (0,34 s); nenhum quadro é branco; um único `VideoStreamPlayer` e nenhum player de áudio a mais; o som passa pelo barramento `BGM`; a abertura dura a animação inteira e o Menu abre sozinho, sem BIOS nem jogo.
- **Pulo**: Espaço (com o som já audível), Enter, Enter do teclado numérico, Esc, clique esquerdo, clique direito, botão A e botão B do controle, entradas repetidas (6 Enter, 2 cliques e Esc em sequência) e pulo **durante o carregamento**. Em cada uma: o Menu abre uma única vez, o som e o vídeo param, nada de BIOS, jogo ou salvamento, nenhum player sobrando, o volume do barramento intacto e o Menu responde (foco em Novo Jogo). Roda do mouse, a letra A e o Shift não pulam.
- **Falhas do vídeo**: arquivo ausente, caminho vazio, formato desconhecido (`.mp4`), codec incompatível (H.264 dentro de um `.ogv`), arquivo vazio, `finished` que nunca vem e uma logo estática de 30 s. Em todas fica a logo estática (sem quadro branco) e o jogador chega ao destino ou pula.
- **Falhas do destino**: Menu ausente e cena ilegível mostram o aviso com "Tentar novamente" e "Sair do jogo", sem tela preta permanente e com a guarda liberada.
- **Acessibilidade**: as três opções que trocam a animação pela logo estática, modo conforto no meio do vídeo, Ctrl+Shift+D, "Reduzir ruído", alto contraste (0,70 → 1,00), volume geral zerado, o volume do jogador intacto no fim.
- **Tempos do teste.** A suíte encurta alguns tempos para não demorar (por exemplo, `duracao_estatica_s` = 1,5 s nas simulações de acessibilidade e `tempo_maximo_reproducao_s` = 1 s no caso do `finished` que nunca vem). Com os tempos padrão, o teste de fluxo mede 3,0 s entre a abertura e o Menu quando a acessibilidade troca o vídeo pela logo estática (2,5 s de logo, o fade curto e a espera de entrega).
- **Reentrada e limpeza**: a Splash repetida vai direto ao destino sem vídeo nem som; cada autoload existe uma única vez; a janela fechada no meio do vídeo para o som e não troca de cena; depois do teste o jogo volta a gravar em `user://nexus_os`.

As mensagens esperadas no Depurador da suíte vêm das falhas provocadas de propósito (os avisos da Splash, um por simulação; os erros do carregador de vídeo com arquivos falsos; o erro da camada `Cenas` para o Menu ausente e a cena ilegível).

No **fluxo de sessão**, o arranque agora é a partida real: a Splash entra como cena principal e entrega o Menu (com a animação, com o Espaço, com a logo estática por "Reduzir animações"); o Novo Jogo abre a `TelaBoot` uma única vez (BIOS, registro sem "Continuar", saudação, área de trabalho); o **Carregar vai direto ao jogo salvo sem criar BIOS nem Splash**.

## 10. Decisões tomadas e limites

- **Ogg Theora em vez de MP4.** A Godot 4.7 não reproduz H.264 (nem AAC) sem extensão. O vídeo foi convertido sem perda perceptível de resolução e o `.mp4` não vai no pacote. Quem quiser outro formato precisa de uma GDExtension de vídeo (decisão de projeto).
- **Estrutura da pasta.** `features/splash_screen/{scenes,scripts,assets}`, como pedido, com `.ogv` no lugar do `.mp4`.
- **Ganho de +6 dB** no som da abertura, por causa da masterização baixa do vídeo. É um valor exportado (`ganho_audio_db`), fácil de ajustar. Foi medido nos barramentos, não ouvido (seção 11).
- **Esperar o jogador parar de apertar** (0,25 s, máximo 1 s depois do fade) antes de entregar o Menu: sem isso, quem pula com Enter repetido aciona "Novo Jogo" sem querer.
- **Janela de 0,4 s** na BIOS do Novo Jogo, pela mesma razão (o 2º clique de um clique duplo em "Novo Jogo" chega quando a BIOS já abriu).
- **Cor de limpeza e imagem de boot do motor pretas** (seção 7).
- **Painel de falha do Menu**: não existia no projeto e foi criado só na Splash, com o mesmo tema dos demais painéis. Nenhum texto técnico aparece em condições normais; as falhas do vídeo só vão para o log de desenvolvimento ("Falha ao carregar a animação da logo. Utilizando imagem estática." e "Não foi possível reproduzir a animação da Splash Screen. Utilizando fallback estático.").
- **Sem opção "Assistir abertura".** A abertura vale uma vez por execução; a opção seria uma melhoria futura (a variável exportada já existe).
- **Controle e toque**: o código trata qualquer botão do controle e o toque; os testes simulam botões de controle, e o toque não foi simulado.

## 11. Pendências e o que não foi verificado

- **Executável exportado**: não foi gerado nem rodado (sem modelos de exportação). Em particular, não foi confirmado, num build, que o vídeo vai para o pacote e toca (nem se o filtro `*.ogv` é mesmo necessário; ele foi mantido por precaução).
- **Campanha manual completa** (cinco dias, quatro finais, com cliques reais), os roteiros R1–R6 do rebranding e a conferência de um salvamento antigo (versão 1) real: nenhum deles foi refeito à mão.
- **O áudio de ouvido**: o nível foi medido no barramento `BGM` (por exemplo, −19,4 dB de pico na execução limpa) e o ganho de +6 dB vem da medição de loudness do arquivo (−32,1 LUFS integrados), mas ninguém avaliou a mixagem com fones. O ganho pode precisar de ajuste fino.
- **Controle físico, toque real e leitores de tela**: o controle foi testado por eventos simulados; um controle de verdade e uma tela de toque não.
- **Áudio indisponível** (uma máquina sem saída de áudio): não foi simulado.
- **Tela cheia exclusiva (F11) com o Game embutido do editor**: os testes rodam na janela normal.
- **Opção "Assistir abertura"** e a **autoria/licença** da logo e do vídeo: decisões de design e de produção, fora desta tarefa.
- **Textos antigos nos documentos**: `docs/08` e `docs/09` guardam descrições de rodadas anteriores (por exemplo "nenhum deles foi executado"); apenas o teste 1 e o teste 2 do `docs/08`, os critérios e o fluxo foram atualizados para a Splash.
- **Problema preexistente**: o analisador do GDScript não pega nome de método errado em variável tipada; o erro aparece só ao executar (o validador estático não substitui a rodada no motor).

## 12. Roteiro de teste manual

O teste automático cobre o fluxo, mas não substitui jogar. Para conferir à mão (cada item termina com o que deve acontecer):

1. **Primeira abertura.** Aperte F5 (ou abra o executável). A tela fica preta com a logo no centro **imediatamente**; em cerca de meio segundo a animação começa sozinha, com som; depois de 1 s aparece, discreto, "Pressione Espaço para pular"; aos 10 s a tela escurece e o Menu Principal abre, com o foco em **Novo Jogo**.
2. **Pular.** Repita e pule com Espaço, depois com Enter, clique do mouse, Esc e um botão do controle. Em cada um: o som e a imagem param na hora, o Menu abre em menos de meio segundo e **nenhum botão do Menu é acionado**, mesmo apertando várias vezes.
3. **Novo Jogo.** Com salvamento, a confirmação aparece; depois, "Iniciando o HumaxOS…", a BIOS do HumaxOS (uma tecla a pula, mas só depois de 0,4 s), o registro **sem** "Continuar jogo salvo" e com "Voltar ao menu", a saudação da Maya e a área de trabalho do Dia 1. Esc no registro volta ao Menu e o salvamento continua intacto.
4. **Carregar.** Com salvamento: o jogo abre direto onde parou, sem BIOS, registro nem Splash. Sem salvamento: o botão fica desativado ("Nenhum registro de sessão disponível.").
5. **Opções e Créditos.** Abrem sobre o Menu; Esc fecha e devolve o foco.
6. **Acessibilidade.** Em Opções, ligue o modo conforto e feche e reabra o jogo: a Splash mostra só a logo por cerca de 2,5 s (sem vídeo e sem som) e abre o Menu. No meio da animação, Ctrl+Shift+D faz o mesmo na hora. Com alto contraste, a dica fica nítida.
7. **Som.** Com a música no mínimo (Opções), a abertura fica muda; com "Reduzir ruído", fica 6 dB mais baixa.
8. **Janela.** Redimensione a janela e alterne F11: a logo continua centralizada, sem esticar, com faixas pretas.
9. **Uma vez por execução.** Na Pausa, "Retornar ao menu inicial" abre o Menu direto; a Splash só volta ao reabrir o jogo.
10. **Falha do vídeo** (numa cópia do projeto): renomeie `maya_human_syntax_intro.ogv`. A logo estática fica por cerca de 2,5 s, o Menu abre sozinho e o painel Saída mostra "SplashScreen: Falha ao carregar a animação da logo. Utilizando imagem estática.". Devolva o nome do arquivo.
11. **Exportação.** Exporte com o filtro `*.json, *.ogv` e repita 1 e 2 no executável. Se o vídeo não tocar (a logo estática aparece por 2,5 s e o Menu abre), confira se o `.ogv` está no pacote.
