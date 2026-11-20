# 14. Fluxo de sessão: Menu Principal, Pausa e Tela de Fim de Jogo

> Rodada de 2026-11-13, na Godot 4.7.2 (Windows). Este documento descreve o fluxo **como está implementado e testado**; a seção 9 traz os números de cada suíte e a seção 11 diz o que **não** foi verificado. Os nomes de arquivo, classes, nós, flags, ações do mapa de entrada e a pasta `user://nexus_os/` continuam os de antes (identificadores internos preservados, como no rebranding).

> **Atualização (2026-11-13, Splash Screen).** Depois desta rodada o jogo ganhou a Splash Screen como primeira cena ([`15_splash_screen.md`](15_splash_screen.md)), e o Novo Jogo passou a abrir o **boot completo** (BIOS, registro, saudação). Onde este documento diz que a `TelaBoot` é a cena principal, que o Menu vem depois da BIOS ou que o Novo Jogo abre o registro "em modo registro, sem BIOS", leia como a etapa anterior: hoje a ordem é Executável → Splash → Menu Principal → Novo Jogo → BIOS → registro → saudação → jogo (o contexto do Menu para a `TelaBoot` passou de `modo = "registro"` para `modo = "novo_jogo"`), e o **Carregar** continua indo direto ao jogo salvo. Os números da seção 9 são os dessa rodada; os da rodada da Splash estão no `docs/15`.

## 1. Resumo

```text
Splash Screen (cena principal desde a rodada da Splash; nesta rodada a cena principal era a TelaBoot, com a BIOS antes do Menu)
  └─ Menu Principal ─┬─ Novo Jogo ──► boot do HumaxOS (TelaBoot: BIOS ─► registro de usuário) ─► saudação da Maya ─► área de trabalho (Dia 1)
                     ├─ Carregar ───► área de trabalho (ou TelaFinal, se o salvamento é de uma história concluída)
                     ├─ Opções ─────► painel de opções (o mesmo componente da Pausa)
                     ├─ Créditos ───► painel de créditos
                     └─ Sair do jogo

Área de trabalho (jogo)  ── Esc ──► Menu de Pausa (a árvore fica pausada)
  ├─ Continuar
  ├─ Salvar jogo
  ├─ Carregar salvamento anterior   (confirmação; só pontos seguros)
  ├─ Recomeçar jogo                 (confirmação; mantém o nome e as configurações)
  ├─ Opções
  └─ Retornar ao menu inicial       (confirmação)

Quatro finais ─► TelaFinal (epílogo) ─► Tela de Fim de Jogo (abre sozinha, uma vez, depois do epílogo)
  ├─ Recomeçar jogo
  ├─ Carregar salvamento anterior
  ├─ Retornar ao menu inicial
  └─ Rever epílogo                  (volta à TelaFinal; Esc faz o mesmo)
```

Tudo é real: cada botão chama a mesma fachada (`Sessao`), que usa a única camada de troca de cena (`Cenas`) e a persistência que já existia (`SistemaPersistencia`). Não há um segundo sistema de salvamento, de carga ou de reinício, e nenhum autoload foi adicionado ou duplicado.

## 2. Diagnóstico inicial (o que havia antes)

Conferido no projeto de partida (o pacote do rebranding, `Maya_Human_Syntax_rebranding_final.zip`):

| Ponto | Estado antes | Risco |
|---|---|---|
| Entrada | A `TelaBoot` ia da BIOS direto ao registro de usuário (nome + "Continuar jogo salvo"). Não havia menu. | Quem tinha salvamento só o encontrava dentro do registro; não havia créditos nem opções antes de jogar |
| Pausa | Nada usava `get_tree().paused` nem `process_mode`; o Esc só fechava diálogos, o menu Iniciar e a central de notificações. `GerenciadorNarrativa.pausado` existia, mas nada o ligava ao jogador. | Impossível parar o jogo (relógio, autosave, trilha, animações) sem sair dele |
| Sair da partida | O menu Iniciar ("Sair para o início", com confirmação e gravação) chamava `sair_do_jogo()`, que desliga o jogo e pausa a narrativa, e só depois pedia a troca de cena para a `TelaBoot`. | Se a troca falhasse, o jogador ficava numa área de trabalho inerte; o destino era a BIOS, não um menu |
| Carregar | `TelaBoot._ao_continuar` e `TelaFinal._ao_repetir_dia5` aplicavam o estado e só depois pediam a troca de cena. | Se a cena não abrisse, o estado já estava trocado (jogo "ativo" sem tela) |
| Fim de jogo | A `TelaFinal` mostrava o epílogo e botões próprios ("Tentar de novo (Dia 5)", "Voltar ao início", "Sair"). Não havia tela de fim de jogo com as três saídas. | Nenhuma saída uniforme; "Voltar ao início" caía na BIOS |
| Salvamento ilegível | Um arquivo principal inválido seria sobrescrito pelo primeiro autosave do jogo novo. | Perda silenciosa de dados do jogador |

O que já estava certo e foi **preservado**: `Cenas.ir_para` como porta única das trocas de cena, os nove autoloads, o formato do salvamento (`versao`, `salvo_em`, `estado`, `vfs`), os checkpoints `checkpoint_dia_1..5.json`, o autosave de 12 s e a gravação a cada início de dia, as flags, as janelas, os quatro finais e a `TelaFinal`.

## 3. Arquivos novos e alterados

Comparação com o projeto de partida (o pacote `Maya_Human_Syntax_rebranding_final`, 363 arquivos; agora são 420): **57 arquivos novos** (19 de jogo e de teste, 11 que a própria Godot gera para eles, os `.uid` e o `.import` do logo, este documento e 26 de evidência em `tests/_saida/`) e **32 alterados** (os 16 de jogo e de teste descritos abaixo, o `README.md`, 8 documentos, `tools/gerar_docs_ui.py` e 6 arquivos de evidência), nenhum removido. `project.godot` **não mudou** nesta rodada: a cena principal continuava sendo a `TelaBoot` (a rodada da Splash a trocou pela Splash Screen), e nenhum autoload, ação do InputMap, classe, ID, flag ou caminho de salvamento foi renomeado.

### Novos

| Arquivo | Para que serve |
|---|---|
| `core/utilities/sessao.gd` | Fachada de sessão: `carregar`, `carregar_checkpoint`, `novo_jogo`, `recomecar`, `voltar_ao_menu`, textos de confirmação e mensagens. É a única chamada das três telas |
| `features/menu_principal/scenes/menu_principal.tscn`, `scripts/menu_principal.gd` | Menu Principal (Novo Jogo, Carregar, Opções, Créditos, Sair do jogo) |
| `features/menu_principal/scenes/painel_creditos.tscn`, `scripts/painel_creditos.gd` | Painel de créditos (seções sem dados ficam escondidas; nada foi inventado) |
| `features/pause/scripts/camada_sobreposta.gd` | Base comum da Pausa e do Fim de Jogo: pausa a árvore, prende o foco, confirma ações, desfaz a pausa em todo caminho de saída |
| `features/pause/scenes/menu_pausa.tscn`, `scripts/menu_pausa.gd` | Menu de Pausa |
| `features/pause/scenes/tela_fim_de_jogo.tscn`, `scripts/tela_fim_de_jogo.gd` | Tela de Fim de Jogo |
| `shared/ui/painel_confirmacao/` (cena + script) | Caixa de confirmação (Confirmar/Cancelar, foco preso, Esc cancela) |
| `shared/ui/painel_opcoes/` (cena + script) | Painel de opções (volumes, tela cheia, tamanho do texto, alto contraste, acessibilidade e dificuldade) ligado ao `GerenciadorConfiguracoes` |
| `shared/ui/indicador_carregamento/` (cena + script) | Cortina "Carregando…" com barra, durante uma troca de cena |
| `shared/assets/textures/logo_maya_neon.png` | Logo do Menu Principal (ver a seção 10) |
| `tests/fluxo_sessao/fluxo_sessao.gd` e `.tscn` | Teste de ponta a ponta do fluxo (seção 9) |

### Alterados

| Arquivo | O que mudou | Por quê |
|---|---|---|
| `core/utilities/cenas.gd` | De 20 para 176 linhas: guarda de transição, número de geração, carga em segundo plano com tempo limite, gancho `preparar`, despausa antes da troca, vigia de tempo, recado entre cenas (`definir_contexto`/`consumir_contexto`) | Troca de cena segura e única; falha antes de mudar qualquer estado |
| `core/utilities/ui_kit.gd` | `refs_ok` e `travar_foco` | Foco preso na camada que está por cima e conferência de referências |
| `core/autoload/sistema_persistencia.gd` | API **aditiva**: `validar_arquivo`, `ponto_de_carga`, `existe_ponto_de_carga`, `ler_conferido`, `aplicar_dados`, `preservar_se_invalido`, `caminho_do_checkpoint`; `VERSAO` segue 2 | Conferir o arquivo antes de tocar no estado; nunca apagar nem sobrescrever um salvamento ilegível |
| `core/autoload/sistema_audio.gd` | Os players de efeito rodam com a árvore pausada; "Reduzir ruído" também vale para a trilha **pausada** | Cliques e avisos da Pausa soam; a opção funciona dentro da Pausa |
| `core/autoload/gerenciador_estado.gd` | O temporizador do "gaslighting" do backend deixou de contar durante a pausa (`create_timer(1.0, false)`) | Nada acontece por trás da Pausa |
| `features/shell/tela_boot/` (cena e script) | Nesta rodada: depois da BIOS ia ao Menu Principal; modo "registro" (vindo do menu) com "Voltar ao menu"; o registro antigo continuava como alternativa se o menu não abrisse. (A rodada da Splash tirou da `TelaBoot` o desvio para o Menu: ela agora só segue para a frente, aberta pelo Novo Jogo; ver `15_splash_screen.md`.) | Manter a `TelaBoot` como primeira cena e não deixar o jogador sem saída |
| `features/shell/area_de_trabalho/` (cena e script) | Hospeda `MenuPausa` e `TelaFimDeJogo`; decide quando o Esc pode pausar (`pode_pausar`); `encerrar_sessao()` | Pausa dentro do jogo |
| `features/narrative/finais/` (cena e script) | Abre a Tela de Fim de Jogo depois do epílogo; "Tentar de novo (Dia 5)" e "Voltar ao início" passam pela fachada | Fim de jogo com saídas uniformes; carga atômica |
| `features/apps/calculadora/scripts/app_calculadora.gd` | Esc só limpa o visor quando há o que limpar; senão segue adiante e abre a Pausa. Delete continua limpando | A calculadora não pode "engolir" o Esc |
| `tests/smoke_test.gd`, `tests/persistencia/persistencia.gd`, `tests/resolucoes/resolucoes.gd`, `tests/ui_interacao/ui_interacao.gd` | Verificações novas do fluxo (e uma correção de uma linha no `ui_interacao`); o teste de resoluções ganhou uma pasta de salvamento própria | Cobertura do que foi criado; nenhuma suíte lê o salvamento do jogador |

Os documentos alterados são o `docs/04`, o `docs/06` e o `docs/10` (regenerados por `tools/gerar_docs_ui.py` e `tools/gerar_indice_codigo.py`), o `07`, o `09` e o `11` (números atuais e notas de que os anteriores ficam como histórico), o `12` (nota de atualização) e o `13` (regenerado por `tools/auditar_marca.py --escrever`). Os seis arquivos de evidência alterados são os quatro logs, a folha de contato e o `LEIA-ME.md` de `tests/_saida/`.

## 4. Como cada peça funciona

### 4.1 `Cenas`: a única camada de troca de cena

`Cenas.ir_para(arvore, caminho, ao_falhar, preparar)` devolve `true` quando **aceita** o pedido e `false`, sem mudar nada, quando: não há árvore, já há uma troca em andamento (aviso no Depurador) ou a cena não existe (erro no Depurador). Depois de aceita:

1. a cena de destino é carregada em segundo plano, com tempo limite de 20 s;
2. só então o gancho `preparar` roda (reiniciar a campanha, aplicar um salvamento, desligar a sessão), ainda com a árvore pausada; se devolver `false`, a troca é cancelada;
3. a árvore é **despausada** e a cena é trocada;
4. a guarda só é liberada dois quadros depois, com a cena nova já rodando. Um vigia de 30 s a libera à força se algo travar.

Falha nas etapas 1 ou 2 libera a guarda, registra o motivo e chama `ao_falhar(motivo)`: a tela mostra a mensagem e o jogo continua **exatamente como estava**.

### 4.2 `Sessao`: as ações de sessão

| Função | O que faz | Onde é usada |
|---|---|---|
| `carregar(arvore, origem, ao_falhar)` | Lê e confere o ponto de carga **uma vez**, carrega a cena de destino e só então aplica o estado | Menu, Pausa, Fim de Jogo |
| `carregar_checkpoint(arvore, dia, ao_falhar)` | O mesmo caminho, para o checkpoint de um dia | "Tentar de novo (Dia 5)" da `TelaFinal` |
| `novo_jogo(arvore, nome, ao_falhar)` | Reinicia a campanha e abre a área de trabalho; antes, preserva (renomeia) um salvamento principal ilegível | Registro de usuário |
| `recomecar(arvore, ao_falhar)` | `novo_jogo` com o nome atual | Pausa, Fim de Jogo |
| `voltar_ao_menu(arvore, ao_falhar)` | Desliga a sessão, para a trilha e abre o Menu Principal | Pausa, Fim de Jogo, `TelaFinal` |

`origem` (`MENU`, `PAUSA`, `FIM_DE_JOGO`) decide **quais pontos de carga valem**: o Menu aceita qualquer salvamento válido (inclusive de uma história concluída, que reabre o epílogo); a Pausa e o Fim de Jogo só aceitam pontos **seguros** (sem `final_id`), de modo que carregar nunca reabra um final por cima de uma sessão que acabou de recomeçar nem entre em ciclo.

### 4.3 Menu Principal

- Sem salvamento nem checkpoint válido, **Carregar fica desativado** e o aviso diz "Nenhum registro de sessão disponível.". Com salvamento, mostra o resumo ("Ana — Dia 3 (salvo em …)").
- **Novo Jogo** com progresso existente pede confirmação (a campanha volta ao Dia 1 e o salvamento é substituído; as configurações são mantidas) e abre a `TelaBoot`. (Nesta rodada ela abria o registro direto, em modo "registro", sem BIOS; desde a Splash o Novo Jogo abre o boot completo, com a BIOS, no modo "novo_jogo", e o registro continua sem "Continuar jogo salvo" e com "Voltar ao menu".)
- **Carregar** usa `Sessao.carregar`. Se falhar, o jogador continua no menu com "Não foi possível restaurar a sessão. O estado atual permanece protegido." e o arquivo ilegível **nunca é apagado**.
- **Opções**, **Créditos** e **Sair do jogo**. Esc fecha qualquer painel e devolve o foco ao botão que o abriu.

### 4.4 Menu de Pausa

Abre com **Esc** (ação `ui_cancel`). Pausa de verdade: `get_tree().paused = true`, e a camada tem `process_mode = WHEN_PAUSED`, então só ela e os sons de interface continuam. Para: relógio da narrativa e relógio global, autosave, animações, temporizadores e a trilha. A pausa é desfeita em **todo** caminho de saída: ao continuar, ao trocar de cena (`Cenas` despausa antes da troca) e se a própria camada sair da árvore.

- **Continuar** (ou Esc de novo) retoma e devolve o foco ao controle que o tinha antes.
- **Salvar jogo** grava o salvamento principal agora ("Progresso salvo.").
- **Carregar salvamento anterior**, **Recomeçar jogo** e **Retornar ao menu inicial** pedem confirmação; Esc ou Cancelar mantém tudo como estava. Sem ponto de carga seguro, a Pausa diz "Nenhum salvamento anterior disponível." e não carrega nada.
- **Opções** abre o mesmo painel do menu, por cima da Pausa.
- Textos de confirmação: "Retornar ao Menu Inicial?\n\nO progresso não salvo da sessão atual poderá ser perdido." e "Carregar o último salvamento?\n\nO progresso não salvo desta sessão será descartado.". O de recomeçar diz que o salvamento é substituído e que áudio, tela e acessibilidade são mantidos.

### 4.5 Tela de Fim de Jogo

Aparece **sozinha, uma vez**, depois do epílogo da `TelaFinal` (3 s, ou 1 s com "reduzir animações"). Mostra "Fim de jogo", o final alcançado e o resumo da jornada, pausa a árvore e oferece Recomeçar jogo, Carregar salvamento anterior e Retornar ao menu inicial, todos com confirmação, mais **Rever epílogo** (fecha a tela e devolve a `TelaFinal`; Esc faz o mesmo). Carregar usa só pontos seguros: o checkpoint do Dia 5, nunca o salvamento do próprio final (que reabriria a tela em ciclo). Se a `TelaFinal` não puder abrir, a área de trabalho abre esta tela no lugar.

## 5. Prioridade do Esc

Do mais específico ao mais geral; cada nível consome o Esc e os de baixo nem o veem:

1. **Confirmação ou Opções abertas** (na Pausa, no Fim de Jogo ou no Menu): Esc as fecha e a camada continua.
2. **Menu de Pausa aberto**: Esc continua o jogo. **Tela de Fim de Jogo**: Esc faz "Rever epílogo".
3. **Diálogos do jogo (modais)**: cancelam o diálogo; a Pausa não abre.
4. **Menu Iniciar** e **central de notificações**: fecham; a Pausa não abre.
5. **App com Esc próprio**: a Calculadora só consome o Esc quando há o que limpar.
6. **Campo de texto com o foco** (Terminal, Bloco de Notas, endereço do Navegador): o `LineEdit`/`TextEdit` consome o Esc na etapa da interface e ele nunca chegaria a `_unhandled_input`; por isso a área de trabalho o lê antes, em `_input`, quando o foco está num desses campos e `pode_pausar()` é verdadeiro.
7. **Esc livre**: abre a Pausa (`_unhandled_input`).

`pode_pausar()` exige: área de trabalho pronta e não encerrando, árvore não pausada, nenhuma troca de cena em curso, jogo ativo, nenhum modal, nenhuma sobreposição e nenhum menu Iniciar ou central aberta.

## 6. O que a Pausa para e o que continua

| Para | Continua |
|---|---|
| Relógio da narrativa (`tempo_do_dia`) e relógio global (`RelogioGlobal`) | O Menu de Pausa, o painel de opções e as confirmações |
| Autosave (`SistemaPersistencia._process`) | Sons de interface e de aviso (players SFX em `PROCESS_MODE_ALWAYS`) |
| Animações, tweens e temporizadores presos à árvore | As teclas de segurança (Ctrl+Shift+D e F11), tratadas pela camada pausada |
| A trilha sonora (**uma só**, no barramento BGM existente; não há barramento novo) | Ajustes de volume e acessibilidade, que valem na hora (inclusive "Reduzir ruído" na trilha pausada) |

Um `AudioStreamPlayer` pausado deixa de contar como `playing` no Godot; o código e o teste tratam "pausada" como "em andamento".

## 7. Estado e persistência

- **Nenhum autoload novo.** Os nove continuam os mesmos; só os dados que guardam são reiniciados ou substituídos, e só depois de a cena de destino estar carregada.
- **Configurações** (áudio, tela, acessibilidade) nunca são tocadas por Recomeçar, Carregar ou Voltar ao menu.
- **Formato do salvamento inalterado** (`VERSAO` 2, `versao`/`salvo_em`/`estado`/`vfs`); salvamentos antigos continuam válidos, e a migração da marca antiga continua em `migrar_marca_antiga`.
- **Nada é apagado.** O projeto proíbe `DirAccess.remove*`. Um salvamento principal ilegível é renomeado para `salvamento.json.corrompido_<tempo>` antes de um jogo novo gravar o seu, e o menu continua usando os outros pontos de carga.
- **Recomeçar** mantém o nome do usuário, volta ao Dia 1 e **substitui** o salvamento (a confirmação diz isso). **Retornar ao menu** não salva nada além do autosave; a confirmação avisa que o progresso não salvo pode ser perdido.
- Os testes gravam em pastas isoladas (`user://nexus_os_teste*`) e **nunca** tocam em `user://nexus_os/`.

## 8. Falhas controladas (sem softlock)

| Falha | O que acontece |
|---|---|
| Cena de destino ausente | `ir_para` recusa, a guarda não liga e nada muda |
| Cena que não carrega, tempo esgotado ou preparação recusada | A guarda é liberada, o motivo vai ao log e a tela mostra "Não foi possível abrir a próxima tela. O jogo continua como estava." |
| Pedidos repetidos durante uma troca | Só o primeiro é aceito; não há cena duplicada e a raiz não acumula nós |
| Salvamento ilegível ou incoerente | Carregar fica desativado ou falha com "Não foi possível restaurar a sessão. O estado atual permanece protegido."; o arquivo é preservado |
| Nenhum ponto de carga | "Nenhum registro de sessão disponível." (Menu) ou "Nenhum salvamento anterior disponível." (Pausa e Fim de Jogo) |
| Menu Principal ausente | Nesta rodada, a `TelaBoot` caía no registro antigo; desde a Splash, `Sessao.voltar_ao_menu` abre a `TelaBoot` (sem contexto, com o fluxo antigo completo) e a Splash mostra o aviso "Não foi possível abrir o Menu Inicial" com "Tentar novamente" e "Sair do jogo". Em todos os casos o jogo continua jogável |
| Troca que nunca termina | O vigia de 30 s libera a guarda |

## 9. Testes e resultados

Todos rodados no editor da Godot 4.7.2 (Windows), com os arquivos finais deste pacote. Os logs e as capturas de tela estão em `tests/_saida/`.

| Teste | Como rodar | Resultado |
|---|---|---|
| Validador estático | `python3 -I tools/validar_projeto.py` | 0 erros, 0 avisos |
| Auditoria de marca | `python3 -I tools/auditar_marca.py` | sai com 0 (nenhum texto visível da marca antiga) |
| Fumaça com interface | `tests/smoke_test.tscn`, argumentos `-- --ui` | **341 verificações, 0 falhas**, Depurador limpo (rodada da Splash: 345) |
| Fumaça sem interface | `tests/smoke_test.tscn`, sem argumentos | **304 verificações, 0 falhas**, Depurador limpo (rodada da Splash: 308) |
| Persistência | `tests/persistencia/persistencia.tscn` | **119 verificações, 0 falhas**; 6 avisos esperados no Depurador |
| Resoluções | `tests/resolucoes/resolucoes.tscn` | **119 verificações, 0 falhas** (rodada da Splash: 139; Menu, Pausa e Fim de Jogo dentro da tela e centralizados em 16:9, 16:10, 21:9 e 4:3; a 119ª confirma que o menu lê só o salvamento da pasta de testes) |
| Interação de interface | `tests/ui_interacao/ui_interacao.tscn` | **544 verificações, 0 falhas**, Depurador limpo (532 da rodada de 2026-11-12 mais 12 do rebranding; o fluxo de sessão não alterou nenhuma delas; rodada da Splash: 554) |
| **Fluxo de sessão** (novo) | `tests/fluxo_sessao/fluxo_sessao.tscn` | **186 verificações, 0 falhas**; 6 mensagens esperadas no Depurador (rodada da Splash: 194) |
| Avisos do editor | `tests/avisos_editor/varredura_editor.gd`, *Arquivo → Executar* | **62 cenas, 0 avisos** (eram 55 cenas; as 7 novas e 3 rótulos com quebra de linha sem largura mínima foram corrigidos; rodada da Splash: 63 cenas) |

**Isolamento dos testes.** Nenhuma suíte lê nem grava `user://nexus_os/` (o salvamento e as preferências do jogador): a persistência usa `user://nexus_os_teste/exec_*`, o fluxo de sessão `user://nexus_os_teste_fluxo/exec_*` e as resoluções `user://nexus_os_teste_resolucoes/exec_*`, cada uma com uma subpasta nova por execução (os testes e o jogo nunca apagam arquivos; as pastas de teste podem ser apagadas à mão). Uma primeira versão do teste de resoluções fotografava o Menu Principal lendo o salvamento real do jogador (só leitura, nada era gravado); isso foi corrigido e as capturas foram refeitas com um salvamento de teste ("Teste — Dia 1").

O teste de **fluxo de sessão** prova, com a interface real e o jogo rodando:

- **Arranque** como a partida real (nesta rodada, a `TelaBoot` como cena principal; na rodada da Splash, a Splash Screen, com a BIOS só depois do Novo Jogo): BIOS pulada por "reduzir animações", BIOS pulada por um clique do mouse e BIOS inteira (5,6 s), sempre terminando no Menu Principal, sem pausa e sem troca em curso; foco inicial em Novo Jogo; clique real do mouse abre e fecha as Opções.
- **Menu sem salvamento**: Carregar desativado com o texto exato; Opções e Créditos abrem e o Esc devolve o foco; Esc no registro volta ao menu sem iniciar jogo.
- **Pausa**: Esc abre e fecha; relógios da narrativa e global **param** e voltam; a trilha (uma só) pausa e volta sem dobrar; três Esc seguidos terminam abertos; o foco volta ao controle de antes.
- **Mouse na Pausa** (cliques reais, convertidos para a escala da janela): um clique no botão Iniciar por baixo da Pausa não abre o menu Iniciar; Continuar, Opções/Voltar e Retornar ao menu inicial/Cancelar funcionam.
- **Prioridade do Esc**: menu Iniciar, diálogo modal, Calculadora (com e sem o que limpar), Terminal e Bloco de Notas (campo de texto com o foco).
- **Foco preso**: Tab e setas não saem da Pausa nem das Opções; "Reduzir ruído" mexido com o jogo pausado ajusta a trilha pausada.
- **Carregar, Recomeçar e Voltar ao menu** pela Pausa, pelo Menu e pelo Fim de Jogo: confirmação com os textos do documento, cancelar não muda nada, o salvamento restaurado é o certo (Dia 3, marca salva, progresso não salvo descartado), o Recomeçar mantém nome e configurações e substitui o salvamento.
- **Fim de Jogo**: abre uma única vez depois do epílogo; Rever epílogo e Esc; Carregar volta ao início do Dia 5 e, 3 s depois, a área de trabalho continua e o final **não** reabriu (sem ciclo).
- **Falhas controladas**: cena ausente, preparação recusada, três trocas recusadas pela guarda, salvamento ilegível preservado como `.corrompido`, pasta sem nenhum salvamento.
- **Transições repetidas**: três idas e voltas menu ↔ jogo sem pausa presa, sem guarda presa e sem cena sobrando.
- **Teclas de segurança e tema**: o `Theme` do jogo chega à Pausa; Ctrl+Shift+D e o alto contraste funcionam com a Pausa aberta.

As 6 mensagens esperadas no Depurador do teste de fluxo vêm de falhas provocadas de propósito: 2 erros (cena ausente; preparação da troca recusada) e 4 avisos (3 trocas recusadas pela guarda; 1 salvamento ilegível preservado).

## 10. Decisões tomadas e limites

- **Sair do jogo** foi acrescentado ao Menu Principal: a `TelaBoot` já oferecia a saída e, sem o botão, só restaria Alt+F4.
- **Créditos**: as seções sem dados ficam escondidas até serem preenchidas; nada foi inventado. A autoria e a licença do logo não estão declaradas.
- **Logo**: o arquivo recebido tinha fundo opaco e aparecia como um quadrado sobre o menu. O fundo foi convertido em transparência (800×800 RGBA) em `shared/assets/textures/logo_maya_neon.png`, e a máscara de gradiente que tentava escondê-lo foi removida. O arquivo original continua intacto na pasta do usuário.
- **Opções**: só há controles para o que o jogo já tem (volumes, tela cheia, tamanho do texto, alto contraste, acessibilidade e dificuldade). Idioma, resolução e qualidade não existem no projeto e não foram criados.
- **Um único salvamento**: não há seletor de vários slots (o formato tem um salvamento principal e cinco checkpoints).
- **Calculadora**: a mudança do Esc é uma alteração de comportamento de um app existente (ver a seção 3).
- **O analisador do GDScript não pega nome de método errado em variável tipada**: o erro aparece só ao executar (foi assim que se achou `esta_aberta()` contra `esta_aberto()` num teste). Por isso a validação estática não substitui a rodada no motor.

## 11. Pendências e o que não foi verificado

- Jogo real na janela do jogo com o **Game embutido** do editor e em tela cheia exclusiva (F11): os testes rodam na janela normal do editor.
- Jogo manual completo pelo jogador (um dia inteiro seguido de um final) com o salvamento real.
- **Entrada por IME** (teclados de composição) em campos de texto durante a Pausa.
- **Leitor de tela**: a suíte `accessibility_live` não foi executada.
- **Exportação** (Windows/Linux): não testada; o fluxo não depende de nada específico do editor.
- Os testes não cobrem controle (gamepad) na Pausa: o Esc é a única entrada da Pausa; o mapa de entrada existente não ganhou ação nova. (A Splash, na rodada seguinte, trata qualquer botão do controle como pulo, simulado por evento; um controle físico não foi testado.)
- Os roteiros manuais R1–R6 do rebranding (`docs/08_testes_manuais.md`), a **instalação limpa** e um **salvamento antigo real** (versão 1) do jogador: os testes automáticos simulam os dois (uma pasta nova por execução e um salvamento da versão 1 escrito pelo teste de persistência), mas ninguém abriu o jogo à mão nessas condições.

## 12. Roteiro de teste manual

O teste automático cobre o fluxo, mas não substitui jogar. Para conferir à mão (cada item termina com o que deve acontecer):

1. **Primeira partida sem salvamento.** Renomeie a pasta `nexus_os` da pasta de dados (*Projeto → Abrir pasta de dados do usuário*) para guardar o seu salvamento e aperte F5. (Desde a Splash: a Splash abre primeiro, Espaço a pula, e o Menu Principal abre; a BIOS só vem com o **Novo Jogo**.) O Menu Principal abre; **Carregar** está desativado e o aviso diz "Nenhum registro de sessão disponível.".
2. **Novo Jogo.** (Desde a Splash, a BIOS passa primeiro; uma tecla a pula depois de 0,4 s.) Escolha um nome; a saudação da Maya aparece e a área de trabalho abre no Dia 1. O Esc nunca está "preso" no registro: ele volta ao menu.
3. **Pausa.** Aperte Esc na área de trabalho: o relógio do canto para, a trilha para e só o menu de pausa responde. Esc de novo (ou **Continuar**) retoma do mesmo ponto, com o mesmo foco.
4. **Prioridade do Esc.** Com o menu Iniciar, um diálogo ou a central de notificações abertos, o Esc fecha só isso. Digitando no Terminal ou no Bloco de Notas, o Esc abre a Pausa; ao continuar, o cursor volta ao campo.
5. **Salvar jogo.** "Progresso salvo." aparece e a Pausa continua aberta.
6. **Carregar salvamento anterior.** Avance, aperte **Carregar salvamento anterior**, confirme: o jogo volta ao ponto salvo e o que não estava salvo some. **Cancelar** (ou Esc) não muda nada.
7. **Opções na Pausa.** Mude o volume da música e "Reduzir ruído": o efeito vale na hora e continua depois de **Continuar**.
8. **Recomeçar jogo.** A confirmação cita o salvamento substituído e as configurações mantidas; ao aceitar, volta ao Dia 1 com o mesmo nome.
9. **Retornar ao menu inicial.** A confirmação avisa do progresso não salvo; ao aceitar, o Menu Principal abre e **Carregar** mostra o resumo do salvamento.
10. **Fim de jogo.** Chegue a um dos quatro finais: o epílogo aparece e, poucos segundos depois, a Tela de Fim de Jogo abre uma única vez. **Rever epílogo** (ou Esc) volta ao epílogo; **Carregar salvamento anterior** leva ao início do Dia 5, sem reabrir o final.
11. **Mouse.** Repita 3, 6 e 9 só com o mouse; clique no botão Iniciar por baixo da Pausa: nada acontece.
12. **Acessibilidade.** Com Ctrl+Shift+D (modo conforto) e com alto contraste ligados, o Menu, a Pausa e o Fim de Jogo continuam legíveis e navegáveis por Tab e setas, sem o foco escapar para o que está por trás.
13. **Salvamento corrompido.** Com o jogo fechado, copie `salvamento.json` para um lugar seguro, estrague o original (apague metade do texto) e abra o jogo: o menu continua utilizável e o arquivo estragado é preservado ao lado, com o sufixo `.corrompido`, em vez de apagado. Depois devolva a cópia.

