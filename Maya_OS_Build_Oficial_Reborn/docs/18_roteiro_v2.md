# 18. Roteiro MAYA v2.0: implementação, validação e divergências

Fonte de verdade: `MAYA_Roteiro_Revisado_v2.0.pdf`. Este documento **substitui** o escopo dos docs 16 e 17 (modelo de dias, e-mail, calendário,
navegador, monitor de sistema, falso boot, terror condicional e `apt-get`), que deixaram de existir no jogo.
Regra de nomes: o jogo é **Maya Human Syntax** (IA: Maya; sistema: HumaxOS). Identificadores internos `nexus_*`, `TemaNexus` e `user://nexus_os/`
foram preservados de propósito (compatibilidade); qualquer "Nexus" visível ao jogador deve ser lido como Maya.

## 18.1 Modelo

- **Sem tempo.** Não há dias, dias da semana nem "Encerrar o dia". O jogo avança por **9 Tasks**:
  `T1 → T2 → T3 → T4 → (T5 opcional) → T6 → { T7 se rafael_investigado | TR.1 } → T8 → T9 → AV`.
- **Dados, não código.** `core/data/narrativa/roteiro_v2.json` (77 nós: fala, rota, escolha, cartoes, espera, janela, minigame, barra_envio, fim, mais
  `revogacoes`), `relatorios_v2.json`, `finais_v2.json` (6 finais + cartão de encerramento) e `core/data/minigames_logica.json`.
  Condições e efeitos usam uma DSL única (`FluxoRoteiro.aplicar_efeito`, `GerenciadorEstado.avaliar_condicao`).
- **Uma fonte de verdade.** `GerenciadorEstado` guarda `task_atual`, `no_roteiro`, as 5 permissões, `dependencia_maya` (0–100, inicia em 50),
  `autonomia_jogador` (inicia em 0; +1 por ato de resistência, uma vez por id), flags, `atos_de_resistencia`, `tentativas_revogacao` e
  `tentativas_revogacao_task_9`. `GerenciadorNarrativa` é o único motor (nenhum autoload novo foi criado).
- **Permissões.** Cinco, todas `false` no início. A Maya só age por `Permissoes.agir_como_maya` (checagem central). Revogar: um clique até a Task 8
  (D −5, A +1); na Task 9, duas tentativas por permissão (D −10, A +1), com a Maya contestando na primeira.
- **Nó AV (determinístico, função pura `avaliar_final`).** Prioridade: Rafael 2 → Rafael 1 → Aceitação total → Recusa total → Meio-termo 1 → Meio-termo 2.
- **Persistência.** `SistemaPersistencia.VERSAO = 5`. Save sem `schema_roteiro` (anterior ao v2.0) migra: mantém perfil e configurações, recomeça na Task 1,
  zera D/A, permissões, tentativas e atos de resistência, e descarta flags/chat/final antigos.

## 18.2 O que foi implementado

| Sistema | Onde |
|---|---|
| Motor do roteiro, barra de envio (3 s / 6 s com tempo estendido), cartões, revogação, finais | `core/autoload/gerenciador_narrativa.gd`, `core/utilities/fluxo_roteiro.gd` |
| Estado, D/A, flags, migração | `core/autoload/gerenciador_estado.gd`, `core/utilities/metricas.gd`, `core/utilities/permissoes.gd`, `sistema_persistencia.gd` |
| Painel da Maya, cartões de permissão, relatórios, rotina, Mensageiro, Terminal, Configurações > Privacidade, Mural | `features/apps/{maya,privacidade_maya,relatorio,rotina,mensageiro,terminal,config,basico}` |
| Minigames de lógica (ordem de 3, histórico fragmentado, trava do Rafael) | `features/minigames/logica/` |
| Tela final (mini-epílogo + cartão de encerramento) | `features/narrative/finais/` |
| Testes | `tests/sistemas_novos/` (5 módulos + piloto determinístico) |

Minigames: sem cronômetro, tentativas ilimitadas, [Verificar] trava as peças certas, dica automática depois de 2 verificações sem acerto novo,
[Sair] salva o progresso, [Como jogar] sempre disponível, tutorial pulado se `conhecimento_logico_adquirido`; mouse, teclado e controle.

## 18.3 Removido ou migrado

Removidos (sem mais uso no roteiro): relógio de dias e `Encerrar o dia`, Calendário, E-mail, Navegador, Calculadora, Monitor de Sistema, falso boot,
efeitos de terror condicionais, `apt-get`/instalação de apps, padrões escuros, reações de NPC, ritmo de progressão, cartão do dia e a revelação do desktop.
No repositório os arquivos viraram stubs de uma linha (`# Arquivo obsoleto ... Pode ser apagado.`) apenas onde a pasta do jogador não permite apagar;
podem ser excluídos manualmente. O diretório `backend/` (protótipo em C) e `tools/testar_backend.py` **não fazem parte do jogo** e continuam descritos pelo
modelo antigo (veja pendências).

## 18.4 Validação executada

Executado no editor Godot 4.7.2 (Windows) em 2026-11-20:

| Suíte | Resultado |
|---|---|
| `tests/sistemas_novos/sistemas_novos.tscn` (estado 112, progressão 136, minigames 92, interfaces 97, desktop real 15, marca 97) | **549 verificações, 0 falhas**, 0 erros e 0 avisos no Depurador |
| `tests/monitor_virtual/monitor_virtual.tscn` (desktop real dentro do SubViewport) | 135 verificações, 0 falhas |
| `tests/splash/splash.tscn` | 311 verificações, 0 falhas |
| `tests/avisos_editor/varredura_editor.gd` (77 cenas) | 0 erros de parse, 0 avisos |
| `tools/validar_projeto.py` | 0 erros, 0 avisos |

A progressão é jogada pelo **mesmo motor do jogo** (`PilotoRoteiro`) nas 8 rotas do §22 (aceita tudo, recusa tudo, delega, concede e revoga, Rafael 1,
Rafael 2, investigação parcial, respostas neutras), mais Task 5 opcional, TR.1 × T7, os limites do nó AV, AV uma única vez e a migração de save antigo.

Bugs reais achados e corrigidos na primeira execução no motor: (1) falas com `canal: "chat"` e `pendente_se` eram descartadas por `falas_validas`
(a barra de envio da Task 6 não trocava a mensagem); (2) progresso de minigame com peça repetida era aproveitado pela metade;
(3) save antigo conservava permissões concedidas; (4) a janela de cartões de permissão se fechava ao abrir (T2.1 abria sem cartão e o fechamento
adiado vencia a reabertura em T2.2); (5) `grab_focus` fora da árvore; (6) `etapa_da_task` estático chamado por instância; (7) dois rótulos com
quebra automática sem largura mínima em `app_maya.tscn`.

## 18.5 Divergências e decisões (registro)

| # | Situação | Decisão |
|---|---|---|
| D1 | Conteúdo de **Jogos** e **Música** não está no roteiro | Apps existem com `[CONTEUDO_NARRATIVO_PENDENTE]` (`app_basico.gd`, `vfs_inicial.json`) |
| D2 | `[ALTERAÇÃO DE ESTADO NÃO ESPECIFICADA]` na montagem da rotina | Tratado como efeito vazio; só `rotina_resultado` (`sem_conflito`/`anotado`/`trocado`) é gravado |
| D3 | Texto das dicas automáticas dos minigames | O PDF define o gatilho, não o texto: foram escritos textos neutros ("A primeira mensagem é a que abre a conversa: não responde a nada.") — **a validar** |
| D4 | Primeira recusa em cartões com `confirma_recusa` | Mostra [Manter recusa]/[Permitir] do mesmo tamanho e não altera nada até a confirmação |
| D5 | Janela de cartões nos nós T2.x | Aberta só pelo nó `cartoes` (a abertura redundante em T2.1 foi removida) |
| D6 | Save antigo | Não há conversão fiel (o modelo de dias não tem equivalente): recomeça na Task 1 mantendo perfil/configurações |

## 18.6 Pendências reais

- Revisão narrativa de D1 e D3 (textos provisórios marcados com `[CONTEUDO_NARRATIVO_PENDENTE]` / texto neutro).
- Jogada manual completa pela interface (os testes automáticos cobrem o motor, o desktop real e cada app isolado, mas não substituem uma partida de ponta a ponta com mouse, teclado e controle).
- `backend/` (protótipo C) e `tools/testar_backend.py` seguem o modelo antigo; não afetam o jogo.
- Legado sem uso que pode ser apagado manualmente: `estado_jogo_backend.gd`, `busca_interna.gd`, `regras.gd`/`regras.json` parciais, itens de `shared/ui` (`painel_opcoes`, `dialogo_nexus`), sinais antigos de `gerenciador_estado.gd` e os stubs `# Arquivo obsoleto`.
