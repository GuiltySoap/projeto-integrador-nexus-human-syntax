# 15.1 Diagnóstico

> **Nota sobre os nomes (2026-11-13).** O jogo passou a se chamar **Maya Human Syntax**, o sistema simulado a **HumaxOS** e a assistente de IA a **Maya**. Este documento descreve uma etapa anterior ao rebranding; os nomes antigos que ele cita (NEXUS, NEXUS OS, `scan_nexus`, `destroy_nexus`, `nexus://`, `nexus_override_daemon.exe`...) são os da época. Hoje valem Maya, HumaxOS, `scan_maya`, `destroy_maya`, `humax://` e `maya_override_daemon.exe`. Os identificadores internos (arquivos, classes, nós, IDs, flags, ações do Input Map e a pasta `user://nexus_os/`) continuam como estão. Veja [`12_rebranding_maya_human_syntax.md`](12_rebranding_maya_human_syntax.md) e [`13_auditoria_de_marca.md`](13_auditoria_de_marca.md).

> **Atualização (2026-11-13, Splash Screen).** Este documento descreve o projeto como foi recebido. Hoje a cena principal **não** é mais a `tela_boot.tscn`: é a Splash Screen (`features/splash_screen/scenes/splash_screen.tscn`), que entrega ao Menu Principal; a `tela_boot` virou o boot do **Novo Jogo**. Ver [`15_splash_screen.md`](15_splash_screen.md).

Este documento descreve o ponto de partida do projeto, o que foi aproveitado, o que faltava, as dependências encontradas e as limitações que continuam valendo. Ele corresponde à seção 15.1 do prompt do jogo.

## O que já existia

O projeto recebido (`Nexus_OS_Build_Oficial_organizado.zip`, já reorganizado por funcionalidade) trazia:

| Item | Situação encontrada |
|---|---|
| `project.godot` | Godot 4.7 (Forward Plus), viewport 1920×1080, `canvas_items` + `expand`, tela cheia exclusiva (`window/size/mode=4`), cena principal `uid://dn6752s6df8if` (`tela_boot.tscn`). Um único autoload (`GerenciadorEstado`, registrado por UID). |
| `tela_boot.tscn` | Existia, com script próprio. |
| `GerenciadorEstado` | Existia; foi corrigido e ampliado para guardar objetivos, permissões, mensagens, processos e para serializar/restaurar o estado (hoje só dados e sinais). |
| `JanelaBase` | Existia, mas com raiz `Panel` e filhos antigos; não havia gerenciador de janelas nem catálogo. |
| Aplicativos | Só seis existiam: `AppConfig`, `AppEmail`, `AppLeitorTexto`, `AppMensageiro`, `AppNavegador` e `AppVisualizador`. Eles usavam caminhos de nó (`$...`) que já não batiam com as cenas e chamavam funções que não existiam (por exemplo `GerenciadorEstado.carregar_json`); a checagem estática encontrou 12 erros neles. |
| Componentes de interface | `PortaLogicaItem`, `SlotCircuito`, `MinigameLogica`, `BalaoChat`, `PopUpNotificacao`, `WidgetNexus` e outros, existentes como peças soltas; foram adaptados ou reescritos para o novo shell. Componentes sem uso (`balao_nexus`, `media_viewer_modal`, `icone_ficheiro`, `password_modal`) foram removidos. |
| `backend/` | Protótipo em C (console) com `dialogues.json` e `mock_estado_jogo.json`, mais um `main.exe` já compilado. Não faz parte do jogo Godot; foi mantido. |
| Árvore de pastas | Já organizada por funcionalidade (`core/`, `shared/`, `features/`), em `snake_case`, sem acentos. |

## O que foi reutilizado

- A árvore de pastas por funcionalidade, os nomes de classes e a convenção `scenes/ scripts/ assets/ resources/`.
- A cena principal e o `uid` registrado no `project.godot` (`tela_boot.tscn` era o ponto de entrada; desde 2026-11-13 o ponto de entrada é a Splash Screen, ver o aviso no topo).
- Os UIDs das cenas que já existiam: `tela_boot`, `area_de_trabalho`, `janela_base`, `app_config`, `app_email`, `app_leitor_texto`, `app_mensageiro`, `app_navegador` e `app_visualizador`.
- O ícone do projeto (`shared/assets/icons/icon.svg`), `.gitignore` (com `.godot/` ignorado) e `.gitattributes`.
- O protótipo em C e os JSONs de `backend/`. A ponte opcional com `mock_estado_jogo.json` fica desligada por padrão (`usar_backend_json`).
- A referência visual do protótipo HTML (`nexus_os_prototype.html`): interface escura, cores neon (roxo, azul, vermelho, verde de terminal), janelas translúcidas, toasts no canto superior direito e barra de tarefas com relógio.

## O que estava faltando

1. Serviços globais: configurações, relógio, sistema de arquivos virtual, notificações, áudio, gerenciador de janelas com catálogo, motor de narrativa e persistência.
2. Tema visual central e construtores de interface compartilhados (`TemaNexus`, `UiKit`), além de um contrato único para aplicativos (`AppBase`).
3. Shell completo: boot com fluxo de nome/continuar, área de trabalho em camadas, barra de tarefas, menu iniciar, bandeja, central de notificações, toasts, widgets, efeitos de glitch e tela final.
4. Aplicativos que faltavam: Explorador de Arquivos, Terminal, Bloco de Notas, Calculadora, Agenda e Monitor do Sistema; os seis existentes foram reescritos.
5. Dados da história (cinco dias, conversas, e-mails, páginas, agenda, processos e finais) em JSON, para que a narrativa possa crescer sem mexer em código.
6. Puzzles integrados à história: lógica, arquivos criptografados, pista nos metadados da imagem, processo malicioso e terminal de emergência.
7. Quatro finais ligados às flags, decisões e puzzles dos cinco dias.
8. Persistência em `user://`, autosave e checkpoint por dia.
9. Documentação, teste de fumaça e validação estática.

## Dependências encontradas

- **Godot 4.7** (`config/features`). O código usa recursos de GDScript 2.0 (tipagem estática, `await`, `Callable.bind`, `Array[Tipo]`) e `Image.create_empty`, que existe a partir da 4.3.
- **Sem addons** e **sem assets obrigatórios**: fontes, ícones, texturas e áudio são opcionais. Quando não existem, o jogo usa fonte padrão do tema, blocos coloridos com emoji, gradiente procedural e sons gerados em código. (Atualização de 2026-11-12: o projeto passou a trazer ícones, papéis de parede, a foto `show_antigo.png`, efeitos e trilhas autorais em `shared/assets/`; a regra "nenhum é obrigatório" continua valendo. Veja `11_melhorias_integradas.md`.)
- **Cache de classes**: o Godot só registra os `class_name` depois que o projeto é aberto uma vez no editor.
- **Dependências entre módulos**: ficam em uma única direção (veja `02_arquitetura.md`). A narrativa não conhece a interface; o sistema de arquivos virtual não toca o disco; a interface só reage a sinais.

## Limitações conhecidas

- **Atualização (2026-11-09):** o projeto passou a ser executado na Godot 4.7.2 (resultados em `10_refatoracao_ui.md`). Na etapa deste diagnóstico, **nada foi executado na Godot**: o ambiente não tinha o binário nem acesso à rede, e toda a validação foi estática (`tools/validar_projeto.py`, uma checagem heurística de sintaxe, referências, assinaturas e regras proibidas). O critério "sem erros relevantes no Output" (teste 32) e o comportamento visual precisam ser confirmados no editor.
- **Cenas mínimas.** Como a interface é montada em código, cada `.tscn` contém só a raiz (`Control` + script). A exceção é a área de trabalho, que declara as 9 camadas nomeadas. Isso evita nós quebrados, mas reduz o que se edita visualmente no editor.
- **Arquivos `.uid`** dos scripts novos serão gerados pelo Godot na primeira abertura; as cenas novas também recebem UID nesse momento.
- **Assets de arte e áudio** não foram fornecidos (lista em `09_criterios_de_aceitacao.md`).
- O `backend/output/main.exe` é um binário de terceiros incluído no zip original. Não é executado por nada no jogo e pode ser removido do repositório.
