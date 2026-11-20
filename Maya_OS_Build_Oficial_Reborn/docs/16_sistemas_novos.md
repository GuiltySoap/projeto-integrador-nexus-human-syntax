# 16. Sistemas novos: estado, mapa de status e validação

> **SUBSTITUÍDO pelo roteiro v2.0** — o modelo de dias, e-mail, calendário, navegador, monitor de sistema, falso boot e terror condicional descritos aqui foram removidos. O escopo vigente está em [`18_roteiro_v2.md`](18_roteiro_v2.md). Este documento fica como histórico.

Escopo: Story Nodes, métricas AUT/CON/DEP e finais, eventos, perfil e tags, permissões, dark patterns, Mensageiro, Navegador, Terminal
(`apt-get`), VFS, monitor virtual, marca, backend em C e ponte `estado_jogo.json`.
Regra de nomes: o projeto é **Maya Human Syntax** (IA: Maya; sistema: HumaxOS). Os identificadores internos (`nexus_*`, `TemaNexus`, contato
`nexus`, `user://nexus_os/`, chave JSON `nexus_reply`) foram preservados de propósito por compatibilidade com saves e dados; qualquer
"Nexus" que o jogador veja deve ser lido como Maya.

## 16.1 Mapa de status

Legenda de status: **Validado** (implementado, ligado ao jogo e coberto por teste executado), **Validado, não integrado** (implementado e
testado, mas sem uso no fluxo principal), **Parcial** (falta uma parte externa ao código), **Não verificável aqui** (depende de ferramenta que
este ambiente não tem), **Não necessário** (decisão documentada).

| ID | Sistema | Status | Sprint | Onde / como é testado |
|---|---|---|---|---|
| §5 | Story Nodes + `GerenciadorNos` | Validado | S3 | `core/autoload/gerenciador_nos.gd`, `core/data/narrativa/story_nodes.json`; módulo Story Nodes e eventos |
| §6 | Métricas AUT/CON/DEP e fórmula única dos finais | Validado | S2 | `GerenciadorEstado` (única fonte), `Metricas`; módulo Métricas, perfil final e finais |
| §7 | `DependencyManager` | Não necessário | S2 | `SistemaEventos` + autoloads já cobrem as dependências; nenhum autoload duplicado foi criado |
| §8 | Tags `{NOME_JOGADOR}`, `{PRONOME_JOGADOR}` e legadas | Validado | S4 | `PerfilJogador`; módulo Perfil, tags e instalação |
| §9 | 12 eventos (ID, origem, dados, condições, efeitos, destino, registro, deduplicação) | Validado | S3 | `SistemaEventos`, `core/data/eventos.json`; módulo Story Nodes e eventos |
| §10 | Reações de NPC | Validado | S6 | `Mensageria`; módulo Mensageiro |
| §11 | `erro_de_envio` e censura automática | Validado | S6 | `GerenciadorNarrativa.enviar_mensagem`; módulo Mensageiro |
| §12 | Monitor virtual (SubViewport, foco, roteamento do mouse) | Validado, não integrado | S8 | `features/shell/monitor_virtual/`; teste `monitor_virtual` (135/0). Não é a tela principal do jogo por decisão de escopo |
| §13 | Instalação técnica do HumaxOS (boot) | Validado | S4 | `InstalacaoHumaxOS`, `TelaBoot`; módulo Perfil, tags e instalação |
| §14 | Permissões (ligar/revogar, efeitos) | Validado | S4 | `GerenciadorEstado`, `core/data/permissoes.json`; módulo Permissões |
| §15 | Dark patterns fictícios + Master Toggle | Validado (lógica); a cena do diálogo de revogação não tem teste próprio | S5 | módulo Permissões |
| §16 | Visuais de terror condicionais | Validado (lógica e acessibilidade) | S5 | módulos Permissões e Story Nodes; smoke_test_ui |
| §17 | Ajuda da Maya | Validado | S5 | módulo Story Nodes e eventos |
| §18 | Falso boot | Validado (lógica); a sobreposição não tem teste de cena próprio | S5 | módulo Story Nodes e eventos |
| §19 | Mensageiro (escolhas fixas + injetada, status, anexos) | Validado | S6 | `Mensageria`, `AppMensageiro`; módulo Mensageiro |
| §20 | Navegador (abas, histórico, busca interna, páginas por dia, erro) | Validado | S7 | `AppNavegador`, `BuscaInterna`; módulo Instalação, Terminal e Navegador |
| §21 | Terminal CLI e `apt-get install` (fonte única) | Validado | S7 | `AppTerminal`, `InstalacaoApps`, `CatalogoPacotes`; mesmo módulo |
| §22 | Marca: logos Maya, HumaxOS, fallback, testes visuais | **Parcial**: falta o logo oficial do HumaxOS | S10 | `Marca`, `LogoMarca`; módulo Marca visual. Instruções em `shared/assets/branding/LEIA-ME.md` |
| §23 | VFS: pastas acessíveis desde o início, 3 tipos de arquivo, 5 estados, placeholders do Rafael | Validado | S7 | `SistemaArquivosVirtual`, `ArquivoVirtual`; módulo VFS |
| §24 | Backend em C: correções de memória | Validado | S9 | `make test`: C 1013/0 (ASan/UBSan e valgrind), `clang-tidy`, `gcc -fanalyzer` |
| §25 | `--choice <id>` | Validado | S9 | testes C e `tools/testar_backend.py` (149/0) |
| §26 | `estado_jogo.json` (esquema v1, atômico, UTF-8, nunca em `res://`) | Validado | S9 | `EstadoJogoBackend`; suíte `integracao_c` (144/0) + ciclo C → Godot → C (8/0) |
| §27 | Build Windows e Makefile | **Não verificável aqui** (sem MinGW nem templates de exportação) | S10 | `Makefile` (alvos `windows`, `dist-check`), `export_presets.cfg` com `exclude_filter` de tools/docs/tests/backend/addons; `tools/testar_pacote.py` 34/0 |
| §28–30 | Validação obrigatória e testes funcionais mínimos | Validado | S11 | ver 16.3 |

Classificação dos sistemas encontrados no diagnóstico (arquivo existir não conta como implementado): os sistemas acima eram **parciais** ou
**ausentes** e hoje estão como na tabela; os que já existiam e funcionavam (janelas, apps base, persistência, áudio, acessibilidade, splash,
menu/pausa/fim de jogo) continuam **existentes e funcionais** e passaram pela regressão.

## 16.2 Divergências entre o prompt e a estrutura real (a estrutura real prevaleceu)

1. **`tipo` já era pasta/arquivo** em dados e saves. O formato do prompt (`"tipo": "arquivo_corrompido"`) é aceito e traduzido para
   `tipo: "arquivo"` + `tipo_arquivo` (`ArquivoVirtual.normalizar_no`). Saves e dados antigos não precisam de migração.
2. **Persistência**: `SistemaPersistencia.VERSAO` passou a 3 (nós, métricas, perfil, permissões, apps instalados). Saves anteriores carregam; campos
   ausentes ou corrompidos viram vazio. O registro `/sistema/aplicativos/<id>.pkg` é derivado de `apps_instalados`, nunca do log do VFS.
3. **`DependencyManager`**: não criado (§7 só o autoriza se necessário).
4. **Instalação de apps**: um único serviço (`InstalacaoApps`) atende a interface gráfica e o `apt-get`; o estado fica em `GerenciadorEstado.apps_instalados`.
5. **Eventos**: aplicam os efeitos **antes** do sinal `evento_emitido`; rejeições (`desabilitado`, `evento_desconhecido`, `profundidade_excedida`,
   `dados_incompletos:<campo>`, `condicao_nao_atendida`, `duplicado`) ficam em `SistemaEventos.rejeicoes()` e não geram aviso do motor.
6. **Logo do HumaxOS**: o arquivo oficial não foi fornecido; o jogo usa o texto "HumaxOS" até ele existir (ver `shared/assets/branding/LEIA-ME.md`).
7. **Comandos de validação**: o ambiente do desenvolvimento não tem Godot de linha de comando; `godot --headless ...` equivale a abrir a cena no editor
   e apertar F6, que foi o que se executou (mesmo código de teste, mesmos arquivos de log).
8. **`Makefile`**: alterado fora do canal de sincronização com o computador (arquivo protegido); a cópia final vai no pacote.

## 16.3 Testes executados

| Comando / cena | Resultado |
|---|---|
| `python3 -I tools/validar_projeto.py` | 0 erros, 0 avisos (129 scripts, 80 cenas, 11 autoloads) |
| `python3 -I tools/auditar_marca.py` | 0 ocorrências pendentes, 0 problemas no uso das marcas |
| `make test` (C com ASan/UBSan e valgrind, `clang-tidy`, `gcc -fanalyzer`, contrato C ↔ JSON, conferidor de pacote) | C 1013/0, Python 149/0, pacote 34/0, saída 0 |
| `tests/sistemas_novos/sistemas_novos.tscn` (8 módulos: estado, nós/eventos, perfil, permissões, Mensageiro, instalação/Terminal/Navegador, VFS, marca) | 2549 verificações, 0 falhas; 9 avisos esperados |
| `tests/smoke_test.tscn` e `tests/smoke_test_ui.tscn` (`-- --ui`) | 313/0 e 350/0 |
| `tests/ui_interacao`, `fluxo_sessao`, `persistencia`, `resolucoes`, `splash` | 554/0, 194/0, 119/0, 139/0, 311/0 |
| `tests/monitor_virtual` | 135/0 |
| `tests/integracao_c` + `tools/testar_backend.py --integracao tests/_saida/integracao_c` | 144/0 e 8/0 |

Cobertura dos testes mínimos (§29): Estado (módulo 1), Story Nodes (2), Parsing (3), Permissões (4), Mensageiro (5), Navegador e Terminal (6),
VFS (7), C (`make test` e `integracao_c`).

## 16.4 Defeitos encontrados e corrigidos na validação

| Onde | Defeito | Correção |
|---|---|---|
| `GerenciadorNarrativa.retomar` | o contador de ids de mensagens reiniciava ao carregar um save e repetia ids | `_sincronizar_contador_de_mensagens()` |
| `EstadoJogoBackend.serializar` | `JSON.stringify` ordenava as chaves alfabeticamente; o contrato (e o backend em C) usa a ordem schema_version, choice_id, status, metrics, timestamp, is_placeholder | `sort_keys = false` |
| `ArquivoVirtual.semente_do_id` | para texto vazio devolvia o valor inicial do hash (mais de 31 bits) | máscara de 31 bits também no retorno |
| `tests/integracao_c` | usava o contato `nexus` para a mensagem `d2_sugestao_01`, que pertence ao contato `lucas`; acessos sem `.get` viravam erro de execução | contato corrigido e leituras seguras |
| `tests/monitor_virtual` | tecla F8 lida por `physical_keycode` (o InputMap grava `keycode`); atalho testado com o tipo de evento errado; clique injetado sem converter para coordenadas da janela | testes corrigidos; o código do monitor não mudou |

Nenhuma asserção foi removida ou enfraquecida e nenhum teste foi desativado; o validador não foi alterado para esconder erros.

## 16.5 Pendências reais

- Logo oficial do HumaxOS (§22): fornecer o arquivo (ver `shared/assets/branding/LEIA-ME.md`).
- `make windows` / exportação com templates / teste do `.exe` (§27): exigem MinGW e templates de exportação.
- Conteúdo narrativo definitivo: todos os marcadores `[...PENDENTE]`/`[PLACEHOLDER_...]` (Rafael, `app-pendente-01/02`, busca placeholder,
  confirmação da instalação) seguem como placeholders e nunca se misturam com texto definitivo.
- Cenas de `DialogoRevogacao` e `SobreposicaoFalsoBoot` sem teste de interface próprio (a lógica está coberta).
