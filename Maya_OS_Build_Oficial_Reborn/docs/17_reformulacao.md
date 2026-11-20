# 17. Reformulação: monitor virtual, janela da Maya, recepção, permissões e história sem calendário

> **SUBSTITUÍDO pelo roteiro v2.0** — o modelo de dias, e-mail, calendário, navegador, monitor de sistema, falso boot e terror condicional descritos aqui foram removidos. O escopo vigente está em [`18_roteiro_v2.md`](18_roteiro_v2.md). Este documento fica como histórico.

Escopo desta etapa (23 seções do pedido de 2026-11-18): monitor virtual como apresentação padrão do jogo, widget e janela da Maya, remoção do
"protocolo do ciclo", Navegador com portais, escolhas sem digitação livre, cena de recepção, permissão para organizar a área de trabalho,
instalação manual de aplicativos, permissões retroativas, dark patterns limitados, fim do sistema de 5 dias, progressão por escolhas/eventos,
terror condicional, acesso total ao sistema, persistência e testes.

Regra de nomes: o projeto é **Maya Human Syntax** (IA: Maya; sistema: HumaxOS). Os identificadores internos (`nexus_*`, `TemaNexus`, contato `nexus`,
`user://nexus_os/`, `OrbeNexus`, chave JSON `nexus_reply`, ações do InputMap `nexus_*`, ids de nós e eventos `dia_*`) foram preservados de
propósito por compatibilidade com saves e dados; qualquer "Nexus" que o jogador veja deve ser lido como Maya.

Regra de conteúdo: nenhuma narrativa definitiva foi alterada. Tudo o que ainda não tem texto final é marcado `[PLACEHOLDER_...]` e fica separado
do texto definitivo.

## 17.1 Mapa de status

Legenda: **Validado** (implementado, ligado ao jogo e coberto por teste executado no motor), **Validado (lógica)** (a regra está coberta por teste,
a cena não tem teste de interface próprio), **Parcial** (falta uma parte externa ao código), **Pendência narrativa** (texto definitivo ainda não existe).

| § | Sistema | Status | Onde / como é testado |
|---|---|---|---|
| 3 | Monitor virtual como cena padrão do jogo (SubViewport 1920×1080, mesa neutra, monitor genérico, foco `F8`/clique fora, Esc/pausa preservados, um único sistema de entrada) | Validado | `Cenas.GAMEPLAY` → `cena_gameplay.tscn` (instância de `monitor_virtual.tscn`); `Sessao` e `TelaBoot` apontam para ela; testes `fluxo_sessao` (etapa do monitor) e `monitor_virtual` |
| 4 | Widget da Maya: logo oficial no extremo direito da Barra de Tarefas, depois do relógio | Validado | `features/shell/widget_maya/`, `barra_de_tarefas.tscn`; módulo "Widget e janela da Maya" e `ui_interacao` |
| 5 | Janela própria da Maya: **Pedir ajuda** (dica contextual sugestiva, `[PLACEHOLDER_DICA_CONTEXTUAL]`) e **Falar com Maya** (hub) | Validado | `AppMaya`, `AjudaMaya`, `DialogoMaya`; módulos "hub da Maya" e "Pedir ajuda à Maya"; a ação `nexus_pedir_ajuda` existe no InputMap |
| 6 | Janela do "protocolo do ciclo" e o cartão do dia removidos | Validado | `cartao_dia.*` e `widget_nexus/*` fora das cenas; `smoke_test` e `smoke_test_ui` (nenhuma referência órfã) |
| 7 | Navegador convencional com portais **Notícias**, **Social** e **Cesar School**, sem rede | Validado | `PortaisWeb`, `core/data/narrativa/portais_web.json`; módulo "PortaisWeb" (texto BBCode escapado, tudo placeholder) |
| 8 | Sem digitação livre: 3 escolhas narrativas + aleatória (+ especial quando liberada) | Validado | `OpcoesDialogo`, `ItemEscolha`; módulos "OpcoesDialogo" (requisitos, semente, decisão própria, confirmação) |
| 9 | Cena de recepção após Novo Jogo (nome, gênero opcional, pronome, idade, e-mail validado só local; primeira escolha persistida) | Validado | `RecepcaoMaya`, `PerfilJogador`; módulos "Recepção", "Perfil extra", "Cena RecepcaoMaya"; `fluxo_sessao` |
| 10 | Permissão para organizar a área de trabalho: aceita → apps revelados um a um (com trava e Pular); recusa → desktop mínimo (Terminal, Menu Iniciar, Configurações, Lixeira) | Validado | `OrganizacaoDesktop`, `RevelacaoDesktop`; módulos "Organização", "Área de trabalho mínima" e "Revelação gradual" |
| 11 | Instalação manual: `apt-get install navegador|mensageiro|email` e pela interface, mesma fonte de verdade | Validado | `InstalacaoApps`, `CatalogoPacotes`, `AppTerminal`; módulos "instalação manual" e "Navegador e Terminal" |
| 12 | Permissões centrais e retroativas; resistência à revogação quando a Dependência está alta | Validado | `Permissoes`, `GerenciadorEstado.definir_permissao`; módulos "Organização e permissão" e Permissões |
| 13 | Dark patterns limitados e canceláveis (ficcionais, nunca fora do jogo) | Validado (lógica); a cena do diálogo de revogação não tem teste de interface próprio | módulo Permissões |
| 14 | Sistema de 5 dias e "Encerrar dia" removidos; o índice antigo vira "etapa" interna e a interface mostra títulos de capítulo | Validado | `GerenciadorNarrativa.titulo_da_etapa`; `ui_interacao`, `persistencia`, `fluxo_sessao` (nenhum texto "Dia N" visível) |
| 15 | Progressão por escolhas, eventos e nós | Validado | `GerenciadorNos`, `SistemaEventos`; módulo "História sem calendário" |
| 16 | Aceleração por Dependência e retrocesso/retardo por Autonomia | Validado | `RitmoProgressao`, `AutonomiaAcoes`, `regras.json` (`progressao`, `autonomia_acoes`); módulo "ritmo e progressão" |
| 17 | Terror condicional (Dependência ≥ 70 + recusa + tentativa de autonomia; acessibilidade sempre manda) | Validado | `EfeitosTerror`; módulo "Efeitos de terror" |
| 18 | Acesso total ao sistema desde o início (nenhum app bloqueado por etapa) | Validado | módulo "Acesso ao sistema desde o início" |
| 19 | Arquivos secretos, criptografados e corrompidos no VFS | Validado | `SistemaArquivosVirtual`, `ArquivoVirtual` (reaproveitado do sprint anterior) |
| 20 | Persistência (versão 4; saves anteriores carregam) | Validado | `SistemaPersistencia.VERSAO` = 4; módulo "Persistência" e suíte `persistencia` |
| 21 | Testes | Validado | ver 17.3 |

## 17.2 Divergências entre o pedido e a estrutura real (a estrutura real prevaleceu)

1. **O índice de dia continua existindo por dentro** (`dia_atual`, `checkpoint_dia_<N>.json`, ids `dia_*`): é o que os saves, os eventos e os
   checkpoints já usam. Ele passou a se chamar "etapa" na documentação e a interface mostra apenas o **título do capítulo**.
2. **Não há opção de configuração para desligar o monitor virtual.** Em janelas pequenas ele reduz o desktop de 1920×1080; o jogo inteiro roda
   dentro do `SubViewport`, e a entrada física é uma só (a do monitor repassa para o desktop com `push_input`).
3. **`Esc`**: com o foco no mundo físico, abre a pausa e devolve o foco ao computador; com o jogo pausado, o monitor continua processando entrada
   (`process_mode` do monitor em `ALWAYS`) e o desktop fica `PAUSABLE`.
4. **`F8`** (alternar foco do monitor) é uma ação do InputMap; os testes a disparam por `InputEventAction`, nunca pela tecla física (no editor `F8` é "Parar").
5. **Ação "recusar organização"** vale AUT +5 / DEP −3 (e "aceitar" DEP +8 / CON +3), definidas em `regras.json`; valores técnicos provisórios.
6. **O processo do app Maya** no catálogo ficou `humax_maya.exe`, igual aos outros 12 aplicativos (a primeira versão usava `maya_assistente.exe`).
7. **Comandos de validação**: o ambiente de desenvolvimento não tem Godot de linha de comando; `godot --headless ...` equivale a abrir a cena de teste
   no editor e apertar F6, que foi o que se executou (mesmo código, mesmos arquivos de log em `tests/_saida/<suite>/log.txt`).

## 17.3 Testes executados

| Comando / cena | Resultado |
|---|---|
| `python3 -I tools/validar_projeto.py` | 0 erros, 0 avisos (138 scripts, 82 cenas, 11 autoloads, 105 classes) |
| `python3 -I tools/auditar_marca.py` | 0 ocorrências pendentes, 0 problemas no uso das marcas |
| `tests/sistemas_novos/sistemas_novos.tscn` (inclui o módulo novo "Reformulação da Maya": 391 verificações) | **2957 verificações, 0 falhas**; 9 avisos esperados |
| `tests/fluxo_sessao/fluxo_sessao.tscn` (inclui a etapa do monitor do jogo) | **221 verificações, 0 falhas** |
| `tests/smoke_test.tscn` e `tests/smoke_test_ui.tscn` | **324/0** e **363/0** |
| `tests/ui_interacao/ui_interacao.tscn` | **555 verificações, 0 falhas** |
| `tests/persistencia/persistencia.tscn` | **119 verificações, 0 falhas** |
| `tests/resolucoes/resolucoes.tscn` | **139 verificações, 0 falhas** |
| `tests/splash/splash.tscn` | **311 verificações, 0 falhas** |
| `tests/monitor_virtual/monitor_virtual.tscn` | **135 verificações, 0 falhas** |
| `tests/integracao_c/integracao_c.tscn` | **144 verificações, 0 falhas** |

O backend em C não foi alterado nesta etapa; os resultados de `make test` do sprint anterior (documento 16) continuam valendo.

## 17.4 Defeitos encontrados e corrigidos na validação

| Onde | Defeito | Correção |
|---|---|---|
| `PerfilJogador.validar_idade` | a idade lida do JSON chega como `float` (`45.0`) e era recusada: a idade se perdia ao carregar um save | aceita decimais inteiros (45.0 → 45); recusa NaN, infinito e fracionários; teste unitário |
| `Cenas._executar` | depois de `ir_para` devolver `true`, uma cena em cache fazia a troca terminar de forma síncrona e a guarda de transição ficava desligada cedo | `await arvore.process_frame` no início e verificação da geração |
| `catalogo_apps.json` | processo do app Maya fora do padrão `humax_*.exe` | `humax_maya.exe` |
| `tema_variacoes.gd` | variável local sem uso (aviso do editor) e comentário antigo ("Cartão do dia") | removidos |
| `monitor_virtual.gd` | variável local `material` sombreava um membro | renomeada |
| Testes | expectativas antigas de "Dia N" em resumos de salvamento, Calendário, Configurações e tela final; ids de gênero inválidos; métricas deslocadas pelo evento de instalação manual; terror condicional ligado a nós | expectativas migradas para títulos de capítulo; helpers `_depois_de_instalar`, `_esgotar_uso_do_terminal`, `_liberar_terror` |

Nenhuma asserção foi removida ou enfraquecida e nenhum teste foi desativado; o validador não foi alterado para esconder erros.

## 17.5 Pendências reais

- **Texto narrativo definitivo**: dica contextual, hub da Maya, portais Notícias/Social/Cesar School, microposts e a confirmação da instalação seguem como
  placeholders. Há uma menção a "Dia 5" em `core/data/vfs_inicial.json` (narrativa definitiva) que foi deixada como está.
- **Logo oficial do HumaxOS** e **build Windows** (ver documento 16, §22 e §27): dependem de arquivo e de ferramentas externas.
- A **cena do diálogo de revogação** e a **sobreposição do falso boot** seguem sem teste de interface próprio (a lógica está coberta).
- **Arquivos órfãos no computador**: as cenas e scripts de `widget_nexus/` e `cartao_dia` foram removidos do projeto de trabalho, mas o editor do Godot não
  apaga arquivos que ele não vê; as cópias antigas, sem nenhuma referência, ainda estão na pasta do computador e podem ser apagadas à mão.
