# 15.5 Plano de implementação

> **Atualização (2026-11-09).** A interface agora é montada em cenas `.tscn` editáveis (não mais em código). Onde este documento fala de `UiKit` construindo nós ou de cenas só com a raiz, leia como a etapa anterior; a descrição atual está em [`10_refatoracao_ui.md`](10_refatoracao_ui.md) e [`04_hierarquia_das_cenas.md`](04_hierarquia_das_cenas.md).

O desenvolvimento foi dividido nas 16 etapas pedidas no prompt. Todas as etapas estão **implementadas no código**; o que ainda falta é **executá-las na Godot** (veja `09_criterios_de_aceitacao.md`). A coluna "Depende de" mostra a ordem em que as etapas devem ser retomadas se algo precisar ser refeito. Os números em "Testes" remetem aos 32 testes de `08_testes_manuais.md`.

```text
1 Pastas ─► 2 Autoloads ─► 3 Boot ───────────────┐
                │                                ▼
                ├──► 8 VFS ──────────────────► 9 Apps básicos ─┐
                ├──► 5 Janelas ─► 6 Barra ─► 4 Área de trabalho  │
                │        ▲              ▲                        │
                └──► 7 Catálogo ────────┘                        ▼
                                              10 Narrativa ─► 11 Dias ─► 12 Puzzles ─► 13 Processos ─► 14 Finais
                                                                                                          │
                                                                  15 Polimento ◄──────────────────────────┘
                                                                        │
                                                                        ▼
                                                                    16 Testes
```

| # | Etapa | O que entrega | Arquivos principais | Depende de | Testes |
|---|---|---|---|---|---|
| 1 | **Organização de pastas** | Árvore por funcionalidade em `snake_case`, `.gitignore` com `.godot/`, `.uid`/`.import` preservados, componentes sem uso removidos. | toda a árvore, `README.md`, `.gitignore` | — | — |
| 2 | **Configuração dos Autoloads** | 9 serviços registrados em ordem de dependência no `project.godot`: `RelogioGlobal`, `GerenciadorConfiguracoes`, `GerenciadorEstado`, `SistemaAudio`, `SistemaNotificacoes`, `SistemaArquivosVirtual`, `GerenciadorJanelas`, `GerenciadorNarrativa`, `SistemaPersistencia`. Input Map e barramentos criados em código. | `core/autoload/*.gd`, `project.godot` | 1 | 6, 19 |
| 3 | **Fluxo de boot** | BIOS → registro de usuário (novo/continuar) → saudação da Maya com orbe reativo → área de trabalho no Dia 1. (Desde 2026-11-13 o boot é aberto pelo Novo Jogo do Menu Principal, que vem depois da Splash Screen; ver `15_splash_screen.md`.) | `tela_boot.gd/.tscn`, `orbe_nexus.gd`, `cenas.gd` | 2 | 1, 2, 3, 4 |
| 4 | **Área de trabalho** | 9 camadas nomeadas, papel de parede por dia, ícones, widgets, toasts, efeitos, modais e atalhos globais. | `area_de_trabalho.gd/.tscn`, `papel_de_parede.gd`, `icone_area_de_trabalho.gd`, `widget_*.gd`, `pilha_toasts.gd`, `popup_notificacao.gd`, `centro_notificacoes.gd`, `cartao_dia.gd`, `painel_debug.gd` | 2, 5, 6 | 3, 4, 28 |
| 5 | **Gerenciador de janelas** | Janela com barra de título, minimizar/maximizar/fechar, arrastar com limites, redimensionar, tamanho mínimo, foco e z-order, restauração de tamanho; diálogos modais; contrato `AppBase`. | `janela_base.gd/.tscn`, `app_base.gd`, `gerenciador_janelas.gd`, `dialogo_nexus.gd`, `dialogo_arquivo.gd` | 2, 7 | 6–11 |
| 6 | **Barra de tarefas** | Iniciar, fixados, janelas abertas, bandeja (segurança, corrupção, microfone, notificações), relógio; menu iniciar com busca, dica e encerrar dia. | `barra_de_tarefas.gd`, `menu_iniciar.gd`, `ajuda_dica.gd` | 5, 7 | 5, 12 |
| 7 | **Catálogo de aplicativos** | `catalogo_apps.json` (id, nome, ícone, cena, tamanhos, instâncias, dia e condição de desbloqueio) lido por menu, barra, atalhos e gerenciador. | `core/data/catalogo_apps.json`, `gerenciador_janelas.gd` | 2 | 6 |
| 8 | **Sistema de arquivos virtual** | VFS em memória com caminhos validados, ocultos, somente leitura, criptografia por hash, lixeira, busca, serialização. | `sistema_arquivos_virtual.gd`, `core/data/vfs_inicial.json`, `abridor_arquivos.gd` | 2 | 13, 14 |
| 9 | **Aplicativos básicos** | Explorador, Bloco de Notas, Calculadora, Configurações, Leitor de Texto, Terminal simulado, Galeria, Navegador simulado. | `features/apps/*` | 5, 7, 8 | 13–20, 23 |
| 10 | **Sistema narrativo** | Motor orientado a dados: dias, objetivos, eventos, mensagens, e-mails, agenda, páginas, processos; Mensageiro, E-mail e Agenda. | `gerenciador_narrativa.gd`, `core/data/narrativa/*.json`, `app_mensageiro.gd`, `balao_chat.gd`, `app_email.gd`, `app_calendario.gd` | 2, 8, 9 | 21, 22 |
| 11 | **Progressão dos dias** | `iniciar_dia`/`encerrar_dia`, objetivos obrigatórios, dicas progressivas e modo assistido, tema e trilha por dia, checkpoints e autosave. | `gerenciador_narrativa.gd`, `gerenciador_estado.gd`, `sistema_persistencia.gd`, `tema_nexus.gd`, `sistema_audio.gd` | 10 | 4, 19, 21, 28 |
| 12 | **Puzzles** | Cofre lógico, arquivos criptografados (diálogo de chave), pista nos metadados da imagem. | `minigame_logica.gd`, `porta_logica_item.gd`, `slot_circuito.gd`, `dialogo_chave.gd`, `app_visualizador.gd` | 8, 9, 11 | 26, 27 |
| 13 | **Eventos de processo** | Processo malicioso simulado (barra controlada pelo jogo, dificuldade ajustável, nova tentativa mais lenta), Monitor do Sistema, processo isca, `ps`/`kill` no Terminal. | `tabela_processos.gd`, `app_monitor_sistema.gd`, `app_terminal.gd`, `core/data/narrativa/processos.json` | 9, 11 | 24, 25 |
| 14 | **Finais** | Terminal de emergência (Dia 5), quatro finais ligados a flags/evidências/puzzles e tela final com repetir o Dia 5. | `gerenciador_narrativa.gd` (`comando_emergencia`, `finalizar`), `finais.json`, `tela_final.gd` | 12, 13 | 30, 31 |
| 15 | **Polimento visual** | Tema por dia, glitch com opções de acessibilidade, modo conforto (`Ctrl+Shift+D`), alto contraste, tamanho de texto, redução de animações. | `tema_nexus.gd`, `ui_kit.gd`, `efeito_glitch.gd`, `gerenciador_configuracoes.gd`, `app_config.gd` | 4–14 | 28, 29 |
| 16 | **Testes** | 32 testes manuais, teste de fumaça headless, validador estático. | `docs/08_testes_manuais.md`, `tests/smoke_test.gd`, `tools/validar_projeto.py` | 1–15 | 1–32 |

## Notas por etapa

1. **Pastas.** `assets/` e `resources/` só existem dentro de uma funcionalidade quando há um arquivo (o Git não versiona pasta vazia). Assets compartilhados ficam em `shared/assets/`.
2. **Autoloads.** A ordem é uma regra: cada autoload só usa os que vêm antes dele. A narrativa pede ações à interface **por sinal**; ela não conhece janelas.
3. **Boot.** A narrativa só começa a correr depois que a área de trabalho existe (`pausado = false` no primeiro quadro), para nenhum toast se perder.
5. **Janelas.** O gerenciador instancia a cena do catálogo com `PackedScene.instantiate()`; cena ausente gera aviso e toast, nunca erro fatal.
7. **Catálogo.** Adicionar um app novo = uma entrada no JSON + uma pasta com `scenes/` e `scripts/` (que herda `AppBase`). Veja `07_integracao.md`.
8. **VFS.** Nenhuma operação toca o disco: excluir move para `/lixeira`. Os caminhos são normalizados (`.` e `..` são resolvidos e **nunca sobem acima de `/`**); nomes vazios, com mais de 64 caracteres, com caracteres de controle ou com `\ / : * ? " < > |` são recusados; o texto de um arquivo tem limite de 200 000 caracteres e o jogador pode criar no máximo 300 itens.
10. **Narrativa.** Para mudar texto, atrasos, objetivos ou condições basta editar o JSON; o código só interpreta `quando`, `condicao` e `acoes`.
11. **Modo assistido.** Cumpre a flag do objetivo, com duas regras: a escolha do final no Dia 5 (`assistivel: false` em `dias.json`) nunca é assistida, e os objetivos de processo malicioso encerram o processo de verdade, para ele não voltar e os requisitos dos finais continuarem coerentes.
13. **Processo.** A barra de extração é decidida pelo jogo (`GerenciadorNarrativa._atualizar_processos`), nunca por um processo real. Cada falha deixa a próxima tentativa 35% mais longa (até 3 vezes), então o jogador não fica sem saída.
15. **Polimento.** O glitch nunca passa de 40% de opacidade nem ocupa a tela inteira; "reduzir glitch" o desliga, "sem flashes" o deixa estático.
16. **Testes.** Os testes manuais cobrem o que a checagem estática não alcança (aparência, foco, arrastar, áudio e o painel Output).
