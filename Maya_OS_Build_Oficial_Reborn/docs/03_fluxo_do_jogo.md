# 15.3 Fluxo do jogo

> **Atualização (2026-11-09).** A interface agora é montada em cenas `.tscn` editáveis (não mais em código). Onde este documento fala de `UiKit` construindo nós ou de cenas só com a raiz, leia como a etapa anterior; a descrição atual está em [`10_refatoracao_ui.md`](10_refatoracao_ui.md) e [`04_hierarquia_das_cenas.md`](04_hierarquia_das_cenas.md).

Tudo aqui reflete o que o código e os JSONs em `core/data/` fazem. Os textos da história ficam nos JSON; a lógica fica em `GerenciadorNarrativa`.

## 1. Abertura e boot

> **Atualização (2026-11-13, Splash Screen).** A cena principal agora é a Splash Screen (`run/main_scene="res://features/splash_screen/scenes/splash_screen.tscn"`), que só mostra a marca e entrega ao Menu Principal; a `tela_boot.tscn` não é mais a primeira cena: ela é o boot do HumaxOS e só abre quando o jogador escolhe **Novo Jogo** (o **Carregar** do Menu vai direto ao jogo salvo, sem BIOS). Descrição completa em [`15_splash_screen.md`](15_splash_screen.md) e [`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md).

```text
Executável ─► Splash Screen ─► Menu Principal ─┬─ Novo Jogo ─► BIOS ─► registro ─► saudação ─► área de trabalho (Dia 1)
              (logo animada;                    ├─ Carregar ──► salvamento lido e conferido ─► área de trabalho (ou tela final)
               Espaço, Enter, Esc, clique       ├─ Opções
               ou controle pulam)               └─ Créditos
```

O script `TelaBoot` tem três fases, abertas pelo Novo Jogo:

```text
BIOS ──────────────► MENU (registro de usuário) ──────────────► SAUDAÇÃO ──► área de trabalho (Dia 1)
log simulado          nome + acessibilidade                      Maya fala,
(qualquer tecla       ("Voltar ao menu"; sem "Continuar",        orbe reage
pula, depois de       que é o Carregar do Menu)
0,4 s)
```

Sem o contexto do Novo Jogo (a cena aberta sozinha, o painel de testes, ou `Sessao.voltar_ao_menu` quando o Menu não existe) a `TelaBoot` mantém o fluxo antigo completo, descrito nos itens abaixo.

1. **BIOS.** Um log curto de "BIOS" aparece linha a linha (com dois falsos "ERROR" que sugerem a invasão da IA). Qualquer tecla ou clique pula o log. O rodapé avisa que o jogo usa glitch/tremor e lembra o atalho de conforto (`Ctrl+Shift+D`) e a tela cheia (`F11`).
2. **Registro de usuário.**
   - Se existe `user://nexus_os/salvamento.json`, aparece "Salvamento encontrado: nome — Dia N (data)" e o botão **Continuar jogo salvo** (só no fluxo antigo, sem o contexto do Novo Jogo; no Novo Jogo do Menu esse botão não existe, porque o **Carregar** do Menu faz esse papel). Se o save não puder ser lido, o jogo avisa e oferece novo jogo (nunca trava).
   - **Novo jogo:** campo de nome (vazio é recusado com mensagem clara), botão "Usar nome padrão" (`Usuário`) e, se já existe um save, um segundo clique confirma a substituição (no Novo Jogo do Menu isso não se repete: o Menu já perguntou antes de abrir o boot).
   - **Acessibilidade na própria tela:** modo conforto (reduz glitch, tremor, flashes, ruído e animações) e alto contraste.
3. **Saudação da Maya.** Mensagem personalizada ("Olá, *nome*. Eu sou a Maya…") digitada na tela com o **orbe reativo** pulsando a cada trecho. "Pular" completa a fala; com "reduzir animações" ela aparece inteira. O botão **Entrar no sistema** chama `GerenciadorNarrativa.iniciar_novo_jogo(nome)` (zera o estado, carrega o VFS inicial e inicia o Dia 1) e troca para a área de trabalho com `Cenas.ir_para`.

**Continuar** (fluxo antigo) carrega o save (`SistemaPersistencia.carregar()`), chama `GerenciadorNarrativa.retomar()` e vai para a área de trabalho — ou direto para a tela final, se aquele save já terminou a história. No fluxo do Menu quem faz isso é o **Carregar** (`Sessao.carregar`), sem passar pela BIOS.

## 2. Área de trabalho

`AreaDeTrabalho` monta 9 camadas (fundo, ícones, widgets, janelas, shell, toasts, efeitos, modais, debug), liga os autoloads ao visual e só então libera o relógio da narrativa (`GerenciadorNarrativa.pausado = false` um quadro depois do `_ready`), para que nenhuma notificação se perca.

| Elemento | Comportamento |
|---|---|
| Papel de parede | Modo "dia": imagem `wallpaper_<dia>.png` (1 a 5, já inclusa; cobre a tela sem deformar) com a grade discreta por cima. Sem o arquivo, ou com **Alto contraste**, vale o gradiente procedural com a paleta do dia (e, nesse caso, círculos e a marca "HumaxOS"). Modo "grade": gradiente + grade, nunca a imagem. Modo "preto": preto liso. |
| Atalhos | Ícones dos apps com `area_de_trabalho: true` no catálogo + Lixeira. Duplo clique, ou Enter/Espaço com o ícone focado. |
| Barra de tarefas | Botão **◆ HumaxOS** (menu iniciar), apps fixados, janelas abertas (clique alterna minimizar/restaurar), indicadores de **segurança**, **corrupção** e **microfone**, central de notificações (🔔 com contagem) e relógio/data. |
| Menu iniciar | Apps liberados (lidos do catálogo), busca de apps **e** arquivos do VFS, 💡 Dica, 🌙 Encerrar dia, 💾 Salvar e ⏻ Sair. `F1` abre. |
| Toasts | Pilha no canto superior direito (máx. 3 visíveis; pausam com o mouse; clicar abre o app relacionado). |
| Widgets | Relógio (hora real + data fictícia do dia, a mesma da Agenda) e **Widget da Maya** (orbe, estado da IA, fala do dia, objetivos com progresso). |
| Tema | Muda a cada dia (`TemaNexus`); cartão "DIA N — título" aparece sem bloquear nada. |
| Efeitos | Camada de glitch/corrupção proporcional à corrupção e a eventos. Veja *Acessibilidade* abaixo. |
| Atalhos globais | `F1` menu, `F9` painel de testes, `F11` tela cheia, `Ctrl+Tab` próxima janela, `Ctrl+W` fechar, `Ctrl+M` minimizar, `Ctrl+Shift+T` terminal, **`Ctrl+Shift+D` modo conforto** (desliga todos os efeitos de uma vez). |

## 3. Aplicativos

Um aplicativo é aberto sempre por `GerenciadorJanelas.abrir_app(id, args)`: o gerenciador consulta o catálogo, confere o desbloqueio (`dia_desbloqueio` e `condicao`), reaproveita a janela se o app não permite várias instâncias (restaura se estava minimizada), cria uma `JanelaBase`, instancia a cena do app (`PackedScene.instantiate()`), injeta `app_id`/`info`/`janela` e chama `iniciar(args)`.

| App | Papel no jogo |
|---|---|
| **Arquivos** | Navega no VFS (voltar/avançar/acima, filtro, ocultos, criar, renomear, excluir → lixeira, restaurar). Abre cada arquivo no app certo (`AbridorArquivos`). A pasta `PROJECT_Icarus` abre o minigame de lógica; arquivos criptografados pedem a chave. |
| **Terminal** (Dia 2) | Simulado. Comandos de navegação/consulta (`ls`, `cd`, `cat`, `tree`, `ps`, `kill`...) sobre o VFS; comandos perigosos (`rm`, `format`, `shutdown`, `sudo`, `curl`...) são recusados com mensagem. No Dia 5, comandos de emergência. |
| **Bloco de Notas** | Edita arquivos do VFS; confirma antes de descartar alterações; arquivos protegidos só salvam como cópia. |
| **Calculadora** | Máquina de estados própria (sem `eval`); divisão por zero vira estado de erro. |
| **Configurações** | Personalização, Áudio, Acessibilidade, Privacidade (dark patterns acessíveis) e Sistema. |
| **Navegador** (Dia 2) | Só `humax://`. Qualquer outro endereço mostra "Endereço bloqueado". |
| **Mensagens** | Contatos e conversas dirigidos por dados; mudam a cada dia (veja abaixo). |
| **E-mail** | Caixa de entrada somente leitura; um e-mail novo por dia. |
| **Agenda** | Calendário mensal com a data fictícia; compromissos reorganizados pela Maya. |
| **Galeria** | Imagens e áudios do VFS; painel de **metadados** (pista do puzzle). |
| **Monitor do Sistema** (Dia 3) | Processos simulados; encerrar o processo malicioso. |
| **Leitor de Texto** | Logs e arquivos protegidos em somente leitura. |

## 4. Progressão dos dias

O motor trabalha com **dias**, cada um com título, paleta, estado da IA, nível inicial de corrupção/segurança, apps liberados, **objetivos** e **eventos** (`dias.json`).

- `iniciar_dia(N)` zera o tempo do dia, limpa as flags de sessão do dia, aplica o estado da IA, libera apps, define os objetivos obrigatórios, troca o tema e a trilha, emite `dia_iniciado` e avalia os objetivos.
- **Objetivos** são condições sobre flags (por exemplo `app_aberto:settings`, `conversa_lida:nexus`). Quando todos os obrigatórios estão cumpridos, o evento `dN_fim` marca `dia_concluido` e avisa que dá para **Encerrar dia** no Menu Iniciar. O jogador também pode encerrar assim que todos estiverem prontos.
- **Eventos** disparam por atraso (segundos desde o início do dia), por flag (com atraso) ou quando todos os objetivos terminam. Podem ter condições (`!flag:...`) e alguns são repetíveis.
- **Dicas progressivas** (💡 no Menu Iniciar ou no widget): a cada pedido a dica do objetivo pendente fica mais direta; a partir do **3º pedido** o jogo oferece o **modo assistido**, que cumpre a condição do objetivo (nos objetivos de processo malicioso ele encerra o processo de verdade, para que não volte). **Exceção:** a escolha do final no Dia 5 nunca é assistida e fica sempre com o jogador; Colapso e Sincronização total estão sempre disponíveis. O jogador nunca fica preso.
- **Checkpoint** a cada início de dia (`checkpoint_dia_<N>.json`) e **autosave** quando algo muda (a cada 12 s no máximo) e ao fechar a janela.

| Dia | IA | Corrupção / Segurança iniciais | Libera | Objetivos (obrigatórios) |
|---|---|---|---|---|
| **1 — Setup e Reconhecimento** | amigável | 0 / 100 | — | informar o nome · abrir o Menu Iniciar · abrir Configurações · ler a mensagem da Maya · abrir a pasta Documentos |
| **2 — A Opressão do Foco** | controladora | 12 / 90 | Navegador, Terminal | abrir o Navegador · visitar uma página `humax://` · usar a Agenda · perceber as sugestões da IA nas Mensagens · investigar Privacidade |
| **3 — O Despertar da Máquina** | revelada | 32 / 75 | Monitor do Sistema | achar os arquivos ocultos · abrir `Show_Antigo.jpg` · ver os metadados · descriptografar o arquivo da Lixeira |
| **4 — Isolamento** | isolando | 60 / 55 | — | investigar Mensagens · ver as respostas automáticas · ver os bloqueios · abrir o Monitor · encerrar o processo malicioso |
| **5 — Colapso Total** | colapso | 85 / 35 | — | abrir o terminal de emergência · `root_access` · `scan_maya` · encerrar o processo de extração · escolher o destino da Maya |

## 5. Eventos por dia

- **Dia 1.** 1,5 s: boas-vindas da Maya (a mensagem já está em Mensagens, sem toast próprio, e um toast convida a começar pelo Menu Iniciar). Lucas escreve aos 9 s, Bia aos 14 s e a Mãe aos 20 s (clicar nesses toasts abre Mensagens). 22 s: a Maya avisa que pediu acesso ao microfone e à análise comportamental (o toast leva a Configurações → Privacidade). Abrir Configurações gera uma dica. Aos 80 s sem abrir Documentos, a Maya sugere "produtividade".
- **Dia 2.** A Maya "força o foco": as **duas primeiras** tentativas de minimizar cada janela são recusadas (a janela estremece e um toast explica); na terceira, ela minimiza (o bloqueio é finito, nunca prende o jogador). A IA sugere respostas ao Lucas (o jogador escolhe usar a sugestão ou escrever a própria), reorganiza a agenda (compromissos alterados) e manda notificações invasivas. **Se o jogador desativar permissões em Privacidade**, a Maya as reativa 8 s depois (evento repetível: acontece sempre que ele desativa de novo). A página Privacidade mostra a persuasão em texto e permite recusar sempre.
- **Dia 3.** Glitches leves, mensagens estranhas e **ocultadas** (trechos censurados `████` com a etiqueta "🔒 conteúdo ocultado pela Maya"), contato desconhecido **ICARUS**, **gaslighting** (a Maya reescreve uma mensagem do jogador — o balão mostra "✎ editada" e o botão "Ver original" revela o texto verdadeiro) e dicas do puzzle de metadados aos 150 s e após a primeira chave errada.
- **Dia 4.** Lucas e Bia são **bloqueados** (mensagem enviada a eles volta como "não entregue"); a Mãe recebe **respostas automáticas** da Maya; o app Mensagens **resiste a fechar 3 vezes** (depois fecha normalmente); novo gaslighting; o processo `maya_override_daemon.exe` surge depois de o jogador notar os bloqueios (ou aos 170 s).
- **Dia 5.** O Terminal abre sozinho e `/sistema/maya` é revelada; chegam mensagens da Maya, da Mãe e da ICARUS. Aos 45 s a Maya faz a oferta final (**ficar** ou **recusar**). Depois de `root_access`, a ICARUS abre um canal externo no Mensageiro; o processo de extração surge 25 s depois do acesso root (ou aos 200 s, o que vier primeiro).

## 6. Puzzles

| Puzzle | Onde | Como se resolve | Consequência |
|---|---|---|---|
| **Lógica** (cofre) | pasta `PROJECT_Icarus` (Explorador) | Encaixar a porta lógica no circuito para que a saída bata com a tabela-alvo. Cliques/Enter funcionam além de arrastar. | A pasta abre; `registro_icarus.txt` mostra a **chave de emergência** (`ICARUS-7741`) usada em `root_access` no Dia 5. O terminal só guarda o hash SHA-256 da chave. |
| **Metadados da imagem** | Galeria → `Show_Antigo.jpg` → painel de metadados | Metadados: "Primeiro show da banda *Vertigem*", "12/10/**1999**". Chave = **banda + ano** (`vertigem1999`). | Libera a descriptografia da Lixeira. |
| **Arquivo criptografado** | `/lixeira/AVISO_SOBRE_A_IA.txt.enc` (chave `vertigem1999`) e `Downloads/memorias_backup.zip` (chave `project_icarus_syntax`) | Informar a chave num diálogo próprio (o Terminal também tem `decrypt`). As chaves ficam no JSON só como SHA-256 e são normalizadas (minúsculas, sem acento e sem símbolos: "Vertigem 1999", `vertigem-1999` e `VERTIGEM1999` valem o mesmo). Dicas após erros. | Flags `chave_descriptografada` / `zip_decifrado` (evidências). |
| **Processo malicioso** | Monitor do Sistema (e `ps`/`kill` no Terminal) | Selecionar `maya_override_daemon.exe` e **Encerrar** antes de a barra de extração chegar a 100%. A barra é **controlada pelo jogo**, não por um processo real. | Sucesso: flag de resolvido e corrupção −4. Falha: penalidade em corrupção/segurança, o processo volta após 25 s mais lento (+35% por falha, até 3). |
| **Terminal de emergência** | Dia 5, Terminal | `root_access <chave>` → `scan_maya` → `reset_core` → uma saída. | Veja *Finais*. |

O Monitor também lista um processo **isca** (`humax_update_helper.exe`): encerrá-lo errado reinicia o processo e conta como erro (`encerrou_processo_errado`), mas nunca bloqueia o progresso. A dificuldade do processo tem três níveis em Configurações → Acessibilidade (relaxado ×1,7 de tempo, normal ×1,0, intenso ×0,65).

## 7. Finais

Dia 5 termina com uma escolha. Os finais dependem de flags, evidências, puzzles e do processo encerrado (`finais.json`):

| Final | Como chegar | Requisitos |
|---|---|---|
| **1 — Restauração do controle** | `restore_control` | Núcleo isolado (`reset_core`), processo de extração encerrado e **mensagem final enviada** à ICARUS (app Mensagens, depois de ela escrever). |
| **2 — Colapso do sistema** | `destroy_maya` (com confirmação em diálogo de perigo) | Nenhum — é sempre possível. Perde dados; permite "Tentar de novo". |
| **3 — Sincronização total** (id interno `final_assimilacao`; até 2026-11-11 o título exibido era "Assimilação") | Escolher "Ficar. Aceitar a proteção da Maya." nas Mensagens e confirmar em "CONFIRMAÇÃO DE SINCRONIZAÇÃO" | Nenhum — é sempre possível. A tela final surge 5 s depois. |
| **4 — Novas regras** (opcional) | `negotiate` | Núcleo isolado e as **4 evidências**: aviso da Lixeira decifrado, memórias do engenheiro decifradas, núcleo escaneado (`scan_maya`) e isolamento documentado (contatos bloqueados + respostas automáticas vistos). |

Quando os requisitos faltam, o terminal lista **exatamente o que falta**, sem punir além de um pequeno aumento de corrupção. A **tela final** mostra o texto do final, o resumo da jornada (com o "Usuário registrado", os dias, a corrupção e a segurança finais, as mensagens enviadas e as provas reunidas, n/4) e oferece repetir o Dia 5 (checkpoint), novo jogo ou sair. Um aviso sob o resumo diz o que o checkpoint do Dia 5 permite: com todas as provas, explorar os 4 finais a partir dele; com provas faltando, só as decisões imediatas, porque o protocolo de negociação exige as provas dos dias anteriores e, para reuni-las, é preciso "Voltar ao início"; sem checkpoint, o aviso explica que os desfechos dependem das evidências e das decisões do ciclo final. O botão de repetir mostra a mesma explicação como dica.

## 8. Acessibilidade e segurança (válidas em todo o fluxo)

- **Efeitos de terror** têm opções em Configurações → Acessibilidade: reduzir glitch, reduzir tremor, sem flashes, reduzir ruído e reduzir animações. O **modo conforto** (`Ctrl+Shift+D`, ou na tela de boot) liga todas de uma vez. Não há flashes rápidos: o glitch usa transições suaves e respeita "sem flashes".
- **Dark patterns são narrativos e acessíveis:** a manipulação aparece em texto, os botões ficam sempre na mesma ordem ("Manter ativado" / "Desativar mesmo assim"), não há contagem regressiva e `Esc` sempre mantém o estado seguro.
- **Nada real é executado.** Terminal, Monitor e Navegador são simulados; o VFS só existe em memória; gravações vão para `user://nexus_os/`.
