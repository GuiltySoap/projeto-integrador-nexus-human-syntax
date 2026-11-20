# 15.8 Testes manuais

> **Atualização (2026-11-09).** A interface agora é montada em cenas `.tscn` editáveis (não mais em código). Onde este documento fala de `UiKit` construindo nós ou de cenas só com a raiz, leia como a etapa anterior; a descrição atual está em [`10_refatoracao_ui.md`](10_refatoracao_ui.md) e [`04_hierarquia_das_cenas.md`](04_hierarquia_das_cenas.md).

São os 32 testes pedidos no prompt, na mesma ordem e com o mesmo enunciado. **Nenhum deles foi executado**: o ambiente de desenvolvimento não tinha a Godot. A coluna "Automático" mostra quais pontos o teste de fumaça (`tests/smoke_test.gd`, também não executado) cobre sem interface; o que é visual, de foco, de arrastar ou de som só se confirma jogando. Os textos entre aspas foram copiados do código; se algum aparecer diferente na tela, anote.

## Como usar

1. Abra o projeto no editor (veja `07_integracao.md`, seção 1) e rode com **F5**. Deixe o painel **Output** à vista.
2. Comece um **novo jogo** (nome livre). Os testes 1 a 15, 18 e 19 funcionam já no Dia 1; nos demais, o enunciado diz o dia.
3. Para chegar a um dia sem jogar tudo, use o **painel de testes (F9)**: "Ir para o dia" (1–5 e **Ir**), "Concluir objetivos do dia", "Encerrar dia (se possível)", "Liberar todos os apps" e "Processo malicioso (dia atual)". O painel só abre no editor, em builds de depuração ou com **Painel de testes (F9)** ligado em Configurações → Sistema. Pular de dia reinicia o dia escolhido (os eventos recomeçam do zero) e **não cumpre os dias anteriores**: flags, arquivos decifrados e contatos dependem de você ter feito esses passos (ou de usar "Concluir objetivos do dia" em cada dia).
4. Apps por dia: Dia 1 = Arquivos, Bloco de Notas, Mensagens, E-mail, Galeria, Agenda, Calculadora, Configurações. Dia 2 = + Navegador e Terminal. Dia 3 = + Monitor do Sistema. O Leitor de Texto não tem ícone: abre sozinho com arquivos de texto do sistema.
5. Para repetir um teste que depende de um estado limpo, apague a pasta `user://nexus_os/` (no editor: Projeto → Abrir pasta de dados do usuário) ou comece um novo jogo, que pede confirmação para substituir o salvamento.

Marque cada teste ao final: ☐ passou · ☐ falhou (anote o que o Output mostrou).

| Automático | Testes |
|---|---|
| Parcial (lógica, sem interface) | 6 (cenas e `AppBase`; `--ui` abre todas as janelas), 14, 16, 17, 18 (cálculo), 20 (páginas e bloqueio de endereços), 21 (contatos e mensagens), 22 (compromissos por dia), 23 (imagens e áudio gerados), 24 (tabela de processos), 25, 26 (metadados), 27, 29 (opções), 30, 31, 32 (validador e teste de fumaça) |
| Só manual | 1 a 5, 7 a 13, 15, 19, 28 |

---

## Inicialização e área de trabalho

### 1. O jogo inicia na tela de boot (hoje: Splash → Menu → Novo Jogo → boot)
- **Passos:** Rode o projeto (F5). Pule a Splash (Espaço) ou espere a animação; no Menu Principal escolha **Novo Jogo**.
- **Esperado:** A primeira tela é a **Splash Screen** (veja S1 e S2 abaixo), depois o **Menu Principal**; só o **Novo Jogo** abre o boot. Nele aparece o log de BIOS ("MAYA SYSTEMS BIOS v1.0…") com duas linhas de "ERROR" em vermelho e o aviso sobre glitch/tremor, `Ctrl+Shift+D` e `F11` no rodapé. Qualquer tecla ou clique pula o log (depois de 0,4 s da entrada) e mostra o registro de usuário. Há som curto de boot. Nenhuma tela de boot aparece antes do Menu. (Com "Reduzir animações" ligado, o log é pulado direto.)

### 2. O nome do jogador é salvo
- **Passos:** (a) No registro, clique em **Entrar no sistema** com o campo vazio. (b) Digite `Ana`, entre e leia a saudação. (c) Já na área de trabalho, abra o menu iniciar. (d) No menu, use **⏻ Sair → Salvar e sair** (volta ao Menu Principal); depois feche o jogo de verdade (**Sair do jogo** ou a janela) e rode de novo.
- **Esperado:** (a) mensagem "Digite um nome para continuar (ou use "Usar nome padrão")." (**Usar nome padrão** preenche `Usuário` e já entra). (b) A saudação da Maya começa com "Olá, Ana.". (c) O menu mostra "Olá, Ana.". (d) Depois da Splash, o Menu Principal mostra o botão **Carregar** ativo com o resumo do salvamento ("Ana — Dia 1 …"); ao carregar (sem BIOS nem registro), o nome continua "Ana". Com um salvamento existente, **Novo Jogo** pergunta "Iniciar um novo jogo? … o salvamento existente será substituído…" antes de abrir o boot; o registro não repete a pergunta. (Quando a tela de boot abre sozinha, sem o Menu, ela mantém o fluxo antigo: "Salvamento encontrado…", **▶ Continuar jogo salvo** e a confirmação "Já existe um jogo salvo…".)

### 3. A área de trabalho é carregada
- **Passos:** Termine a saudação com **Continuar ▶** e **Entrar no sistema ▶**.
- **Esperado:** Aparecem o papel de parede do Dia 1 (imagem azul/violeta, sem círculos nem marca "HumaxOS" por cima, com a grade discreta), os ícones dos 8 apps do Dia 1 e a Lixeira (ícones dedicados, não blocos de emoji), a barra de tarefas (botão **◆ HumaxOS**, apps fixados, indicadores SEG/COR/MIC, 🔔 e relógio com "Dia 1 · data") e os dois widgets (relógio e Maya). Nenhum erro no Output.

### 4. O Dia 1 é iniciado corretamente
- **Passos:** Observe os primeiros 30 segundos; abra o widget da Maya e o menu iniciar.
- **Esperado:** O cartão do dia ("DIA 1", "Setup e Reconhecimento", "A Maya quer ajudar.") aparece sem bloquear o mouse. O widget lista 5 objetivos com 1 já cumprido ("Informar seu nome no registro de usuário"). Aos ~1,5 s chega o toast da Maya ("Olá, Ana! Estou aqui para otimizar a sua rotina. Comece pelo Menu Iniciar.") e a primeira mensagem dela já está em Mensagens; aos ~9 s, ~14 s e ~20 s chegam os toasts de Lucas, Bia e a Mãe (clicar neles abre Mensagens); aos ~22 s o toast "Permissões solicitadas" avisa que a Maya pediu o microfone (clicar abre Configurações). Tema roxo; trilha ambiente suave. Apps de Dia 2 e 3 ainda não aparecem.

### 5. O menu iniciar abre
- **Passos:** Clique em **◆ HumaxOS** e, depois, em **F1**. Digite `calc` na busca. Pressione Esc.
- **Esperado:** O menu abre e fecha pelos dois caminhos (também fecha com Esc ou clicando fora); lista os apps liberados; a busca filtra por apps **e** arquivos do VFS (digite `read_me` para ver um arquivo); Esc fecha. Os botões 💡 Dica, 🌙 Encerrar dia, 💾 Salvar e ⏻ Sair estão no rodapé. Abrir o menu cumpre o objetivo "Abrir o Menu Iniciar".

## Janelas e barra de tarefas

### 6. Aplicativos podem ser instanciados
- **Passos:** Abra cada app do Dia 1 (menu iniciar ou duplo clique no ícone). Abra o Explorador duas vezes e Mensagens duas vezes.
- **Esperado:** Cada app abre numa janela própria com sua interface (sem janela vazia). **Arquivos, Bloco de Notas, Galeria e Calculadora** permitem várias janelas; **Mensagens, E-mail, Agenda e Configurações** têm uma só janela (abrir de novo foca a existente, restaurando-a se estiver minimizada). Nenhum aviso no Output.
- **Automático:** o teste de fumaça instancia todas as cenas do catálogo como `AppBase`; com `-- --ui` ele abre, minimiza, restaura e fecha cada app.

### 7. Janelas podem ser arrastadas
- **Passos:** Arraste uma janela pela barra de título, tentando levá-la para além das bordas e para baixo da barra de tarefas. Redimensione pelas bordas e cantos, tentando passar do tamanho mínimo e do limite da tela.
- **Esperado:** A janela segue o mouse, mas a barra de título nunca sai de alcance: no topo ela para na borda; nas laterais ao menos 90 px da janela continuam visíveis; embaixo a barra de título para acima da barra de tarefas. O redimensionamento para no tamanho mínimo do app e não invade a barra de tarefas. Clicar numa janela traz para a frente (z-order).

### 8. Janelas podem ser minimizadas
- **Passos:** (No **Dia 1**.) Clique em **Minimizar** na barra de título; repita com `Ctrl+M`.
- **Esperado:** A janela some e sua entrada **continua** na barra de tarefas; o foco passa para a janela de cima. *Atenção, Dia 2:* a Maya "força o foco" (a partir de 1 s do dia) e **recusa as duas primeiras tentativas** de minimizar cada janela (a janela estremece, ou pulsa a borda com "Reduzir tremor", e o toast diz "Mantenha o foco… Tente de novo se realmente quiser."); a terceira funciona. Isso é intencional e finito.

### 9. Janelas podem ser restauradas
- **Passos:** Com uma janela minimizada, clique na sua entrada na barra de tarefas. Depois clique de novo nessa entrada (janela ativa).
- **Esperado:** O primeiro clique restaura e foca a janela na posição e tamanho anteriores; o segundo clique em uma janela ativa a minimiza (a entrada alterna; no Dia 2 valem as recusas do teste 8); clicar na entrada de uma janela inativa só a traz para a frente. Abrir de novo um app de instância única minimizado também a restaura.

### 10. Janelas podem ser maximizadas
- **Passos:** Clique em **Maximizar**; depois em **Restaurar** (mesmo botão). Repita com duplo clique na barra de título.
- **Esperado:** Maximizada, a janela ocupa toda a área útil acima da barra de tarefas e não pode ser arrastada; o tooltip do botão vira "Restaurar"; ao restaurar, volta ao tamanho e à posição de antes. A calculadora também maximiza.

### 11. Janelas podem ser fechadas
- **Passos:** Feche janelas pelo botão ✕ e com `Ctrl+W`. No Bloco de Notas, digite algo sem salvar e tente fechar.
- **Esperado:** A janela some e a entrada da barra também. Com alterações não salvas, o Bloco de Notas pergunta "Salvar alterações?" com **Salvar**, **Descartar** e **Continuar editando** (`Esc` volta à edição e nunca descarta). *Atenção, Dia 4:* o app Mensagens **resiste a fechar 3 vezes** (a janela estremece e o toast diz "Tente fechar novamente."); na quarta tentativa fecha. Nunca prende o jogador.

### 12. A barra de tarefas reflete as janelas abertas
- **Passos:** Abra 3 apps; minimize um; feche outro; alterne com `Ctrl+Tab`; passe o mouse sobre as entradas.
- **Esperado:** A barra mostra os apps fixados (Arquivos, Mensagens, Configurações e, a partir do Dia 2, Navegador), que abrem ou focam o app, e **uma entrada por janela aberta** (ícone e título). A entrada da janela ativa fica destacada; as demais, inclusive as minimizadas, ficam em estilo normal (o tooltip da minimizada diz "(minimizada)"). Entradas somem ao fechar a janela; clicar numa entrada foca ou restaura. `Ctrl+Tab` traz para a frente a janela logo abaixo da ativa (e a restaura, se estiver minimizada). Os apps fixados não têm indicador de "aberto": quem mostra o que está aberto são as entradas de janela.

## Arquivos e aplicativos básicos

### 13. O Explorer navega corretamente
- **Passos:** No Explorador: abra `Documentos` com duplo clique; use ◀, ▶ e ⬆ e, com a lista focada, `Backspace` e `Alt+←/→`; digite no filtro; escolha locais na lateral (Início, Documentos, Imagens, Músicas, Downloads, Dados pessoais, Lixeira, Sistema); digite um caminho na barra e dê Enter (um válido e um inexistente); observe a caixa **Mostrar ocultos**.
- **Esperado:** O caminho e a contagem ("N item(ns) em …") atualizam a cada passo; voltar/avançar seguem o histórico; ⬆ sobe uma pasta e nunca passa da raiz; o filtro reduz a lista; um caminho inexistente mostra "Pasta não encontrada: …" (na barra de status e em toast) e mantém a pasta atual. Selecionar um item mostra nome, tipo, tamanho e marcas ("criptografado", "somente leitura") na barra de status. A caixa **Mostrar ocultos** fica desabilitada ("Bloqueado pelo administrador do sistema.") até o evento do Dia 3 que a libera (~1 s depois do início do dia, com o toast "Falha de permissão detectada…"); depois, com ela marcada, `/sistema` mostra itens com "(oculto)" e isso cumpre o objetivo "Encontrar os arquivos ocultos". `/home/usuario/PROJECT_Icarus` só existe a partir do Dia 3 e, em vez de listar arquivos, abre o puzzle de lógica. Entrar em `Documentos` cumpre o objetivo "Explorar seus arquivos" do Dia 1.

### 14. O sistema de arquivos virtual cria e abre arquivos
- **Passos:** Em `Documentos`: **＋ Arquivo** (nome `teste.txt`), **＋ Pasta**, **Renomear (F2)**, **Excluir (Del)** (confirme em "Mover para a Lixeira?") e, na pasta **Lixeira**, **Restaurar**. Tente nomes inválidos: vazio, `a/b`, `a:b`, mais de 64 caracteres, e um nome já existente. Depois digite `teste` na busca do menu iniciar e, a partir do Dia 2, rode `ls Documentos` no Terminal.
- **Esperado:** Os itens novos aparecem e ficam selecionados; duplo clique no arquivo abre o Bloco de Notas; nomes inválidos ou repetidos geram os alertas "Nome inválido" ou "Não foi possível criar/renomear" e nada muda; **Excluir** move para a Lixeira (nada é apagado do computador) e **Restaurar** devolve ao lugar de origem; na Lixeira, ＋ Arquivo, ＋ Pasta e Renomear ficam desabilitados e Excluir dá lugar a Restaurar. Itens de sistema e somente leitura (por exemplo `Show_Antigo.jpg` ou a pasta `/sistema`) não podem ser renomeados nem excluídos (botões desabilitados). O mesmo arquivo aparece na busca do menu e no `ls` do Terminal: o VFS é compartilhado.
- **Automático:** criar, ler, escrever, renomear, lixeira, restaurar, recusa de nomes e de pastas somente leitura, serializar/desserializar.

### 15. O editor salva e carrega textos
- **Passos:** Abra `Documentos/nota_pessoal.txt` (ou crie um arquivo), edite, **Salvar**, feche e reabra. Use **Salvar como…** e **Abrir…**. Abra um arquivo protegido: no Explorador, **Sistema → System_Logs → `boot.log`** (os arquivos de `Documentos` são editáveis; os de `/sistema` não).
- **Esperado:** O texto reaparece idêntico ao reabrir, e a barra de status mostra "Ln, Col · caracteres" (por exemplo "Ln 1, Col 1 · 0 caracteres"); `Ctrl+N`, `Ctrl+O`, `Ctrl+S` e `Ctrl+Shift+S` fazem Novo, Abrir, Salvar e Salvar como. O arquivo protegido abre em modo de leitura, com o aviso "Arquivo somente leitura: use "Salvar como…" para criar uma cópia editável."; **Salvar** nele mostra o alerta "Arquivo somente leitura" e só uma cópia pode ser gravada (em uma pasta editável). Fechar com alterações pede confirmação. O texto continua ali depois de sair e abrir o jogo de novo (o VFS é gravado no autosave e ao sair).

### 16. O terminal executa somente comandos simulados
- **Passos:** (Dia 2 em diante.) Execute `help`, `ls`, `cd Documentos`, `cat read_me.txt`, `tree`, `ps`, `status`; depois `rm -rf /`, `sudo ls`, `curl http://exemplo.com`, `format`.
- **Esperado:** Os comandos listados em `help` operam **só** sobre o VFS e o estado do jogo: `ls /` mostra `home`, `lixeira` e `sistema`, nunca o disco real. Os bloqueados (`rm`, `rmdir`, `del`, `format`, `shutdown`, `reboot`, `sudo`, `dd`, `mv`, `cp`, `chmod`, `curl`, `wget`, `ssh`) respondem "'…' está desativado na simulação: este terminal não altera nada fora do jogo. Use o Explorador (Excluir move para a Lixeira)." e não fazem nada. Para conferir, crie um arquivo qualquer no seu computador e execute `rm` no terminal: o arquivo continua lá.
- **Automático:** `TabelaProcessos` (usada por `ps` e `kill`) só opera sobre o estado do jogo; o validador falha se achar `OS.execute`, `eval` etc.

### 17. Comandos inválidos geram mensagens claras
- **Passos:** Digite `xyz`, `cd pasta_inexistente`, `cat` (sem argumento), `kill` (sem pid), `kill 999999`, `cd ../../..`.
- **Esperado:** `xyz` → "comando não encontrado: xyz (digite help)"; `cd pasta_inexistente` → "cd: pasta_inexistente: pasta inexistente"; `cat` → "uso: cat <arquivo>"; `kill` → "uso: kill <pid>"; `kill 999999` → "kill: Processo 999999 inexistente."; `cd ../../..` para na raiz `/` (o prompt passa a mostrar `/`). Nenhum comando quebra o terminal nem aparece erro no Output.
- **Automático:** `TabelaProcessos.encerrar` com pid inexistente e `comando_emergencia` com comando desconhecido.

### 18. A calculadora trata divisão por zero
- **Passos:** Digite `1`, `÷`, `0`, `=` (com o mouse ou com o teclado: `1`, `/`, `0`, `Enter`). Em seguida digite um número. Repita o erro e use `C` (ou `Esc`).
- **Esperado:** O visor mostra "Não é possível dividir por zero" em vermelho (estado de erro) e **não trava nem fecha**; no erro, operadores, `=`, `%` e `±` são ignorados; ao digitar um número, usar `C`, `Esc` ou `⌫`, a calculadora volta ao normal. "Resultado fora do limite" só aparece com resultados infinitos (multiplicar números enormes dezenas de vezes seguidas); é opcional conferir.
- **Automático:** `AppCalculadora.calcular` (1 ÷ 0, 6 ÷ 3, operador desconhecido, estouro) e `formatar`.

## Configurações, navegador, mensagens, agenda e galeria

### 19. As configurações são persistidas
- **Passos:** Em Configurações, mude Personalização (**Papel de parede**, **Cor de destaque** e **Tamanho do texto**), Áudio (volumes) e Acessibilidade (por exemplo "Reduzir efeitos de glitch" e "Alto contraste"). Feche o jogo e rode de novo.
- **Esperado:** Todos os valores reaparecem, e a tela de boot já respeita o alto contraste e o modo conforto (as caixas dela refletem o estado). O arquivo `user://nexus_os/configuracoes.cfg` existe. Sliders gravam ao soltar; os demais controles gravam ao mudar.

### 20. O navegador abre somente páginas internas
- **Passos:** (Dia 2 em diante.) Abra `humax://home`, `humax://status`, `humax://social`, `humax://news`, `humax://support`, `humax://archive` e `humax://root`; use ←, →, ⟳ e ⌂, a barra de links e o botão **Ir**. Digite `https://example.com` e `http://localhost`.
- **Esperado:** As páginas `humax://` abrem e mudam com o dia; `humax://archive` só abre a partir do Dia 3 e `humax://root` a partir do Dia 5 (antes disso mostram "Acesso negado"); um endereço interno inexistente mostra "Página não encontrada" (404). Qualquer endereço com outro esquema (`https://`, `http://`) mostra "Endereço bloqueado" sem tentar rede. Para confirmar, desligue a rede e repita: nada muda. Visitar uma página interna cumpre o objetivo do Dia 2 "Visitar uma página interna".
- **Automático:** `pagina_web` por dia (home, archive, root, 404) e `AppNavegador.normalizar_url`.

### 21. O mensageiro muda conforme o dia
- **Passos:** Com F9 → "Ir para o dia", abra Mensagens em cada dia.
- **Esperado:**

| Dia | O que muda no Mensageiro |
|---|---|
| 1 | Maya simpática; Lucas, Bia e a Mãe escrevem; respostas livres geram respostas genéricas |
| 2 | A Maya sugere respostas ao Lucas (usar a sugestão ou escrever a própria); notificações invasivas |
| 3 | Mensagens estranhas e **ocultadas** ("🔒 conteúdo ocultado pela Maya"), contato **ICARUS** (só aparece depois da primeira mensagem dela), mensagem do jogador reescrita ("✎ editada" e **Ver original**) |
| 4 | **Lucas e Bia bloqueados** ("🚫 Contato bloqueado pela Maya"; mensagens enviadas voltam como "não entregue"); respostas automáticas da Maya à Mãe; o app resiste a fechar 3 vezes |
| 5 | A Maya faz a oferta final ("Ficar. Aceitar a proteção da Maya." ou "Não. Eu vou desligar você.") e a ICARUS abre um canal externo depois do acesso root |

- **Automático:** `contatos_disponiveis`, `entregar_mensagem`, `escolher` e `enviar_mensagem` em memória.

### 22. O calendário mostra eventos narrativos
- **Passos:** Abra a Agenda em cada dia (F9 → "Ir para o dia"); no Dia 2, abra-a de novo uns 15 s depois do início do dia. Clique nas células "★ hoje" e "● Dia N" da grade para ver os compromissos de cada dia da história.
- **Esperado:** O topo mostra "Hoje (Dia N): dia da semana, D de mês de ano · hh:mm:ss" (a mesma data fictícia do widget de relógio); **◀**, **▶** e **Hoje** navegam entre meses. Cada dia da história tem um compromisso: Dia 1 "Reunião de alinhamento" (09:00), Dia 2 "Almoço com a Bia" (12:30) e a sessão de foco (20:00), Dia 3 "Aniversário do Dudu" (20:00), Dia 4 "Ligar para a Mãe" (19:00), Dia 5 "Jantar com o Lucas" (21:00). O que a tela mostra depende do dia atual do jogo: Dia 1, tudo normal; Dia 2, só depois de ~14 s (quando a Maya mexe na agenda), o almoço vira "Janela de foco: almoço solitário (definido pela Maya)", o aniversário e a nova sessão viram "Sessão Forçada de Estudo & Foco Cognitivo (definida pela Maya)"; Dia 3, almoço, aniversário e ligação à Mãe aparecem como "██████ ████████ (evento oculto)"; Dia 4, "CANCELADO pela Maya: risco de distração"; Dia 5, "⚠ ALERTA DE EMERGÊNCIA: procure o terminal". Compromissos mexidos levam a etiqueta "⚠ alterado/ocultado/cancelado pela Maya" e, depois que os arquivos ocultos são liberados (Dia 3), a linha "Original (registro de auditoria): …".
- **Automático:** `eventos_da_agenda()` devolve itens em todos os dias, com os estados normal, alterado, oculto, cancelado e emergência.

### 23. O visualizador abre imagens e reproduz áudio permitido
- **Passos:** Abra a Galeria pelo menu (ela abre a primeira imagem de `Imagens`) e use ◀/▶ entre `Cachorro.jpg` e `Show_Antigo.jpg` (`data_stream.png` só aparece a partir do Dia 3). No Dia 3, abra `Musicas/gravacao_01.wav` pelo Explorador (duplo clique) e clique em **▶ Reproduzir**, depois **■ Parar**.
- **Esperado:** A imagem aparece com o nome e a legenda "Descrição: …" (as de `res://shared/assets/textures/` se existirem; senão, imagens procedurais fixas). O áudio é a gravação do VFS (um arquivo em `shared/assets/audio/` ou a respiração sintetizada), com contador "0:00 / m:ss", barra de progresso e botão que alterna entre **▶ Reproduzir** e **■ Parar** (com "Reduzir ruído" ligado ele toca mais baixo). A Galeria só abre arquivos do VFS: nada do computador real. Arquivo criptografado mostra "Este arquivo está criptografado…"; itens que não são imagem nem áudio não entram no ◀/▶ ("Formato não suportado por este visualizador." se abertos direto).
- **Automático:** `ImagemProcedural.textura` gera todas as imagens e `SistemaAudio.stream_gravacao("gravacao_01")` devolve um stream.

## Monitor, puzzles e processo malicioso

### 24. O monitor lista processos simulados
- **Passos:** (Dia 3 em diante, ou F9 → "Liberar todos os apps".) Abra o Monitor do Sistema com alguns apps abertos; abra e feche um app e veja a lista mudar; selecione linhas diferentes.
- **Esperado:** A tabela lista as janelas abertas (processos como `humax_explorer.exe` e `humax_chat.exe`) e os processos "de sistema" fictícios (`humax_core.exe`, `maya_telemetry.exe` e `humax_render.exe`, protegidos, e `humax_update_helper.exe`), com PID, CPU e memória que oscilam suavemente; o cabeçalho mostra "CPU x%", "Memória x / y MB" e "Processos n"; selecionar uma linha mostra nome, PID, tipo e descrição. Encerrar um aplicativo pelo Monitor fecha a janela dele. Os PIDs são os mesmos do `ps` do Terminal (suspeitos primeiro, depois apps, depois sistema). Nada reflete o computador real.
- **Automático:** `TabelaProcessos.linhas` (ordem, tipos e PIDs).

### 25. O processo malicioso pode ser encerrado
- **Passos:** F9 → "Processo malicioso (dia atual)". Abra o Monitor, selecione o processo suspeito e clique em **Encerrar processo suspeito**. Repita e, desta vez, espere a barra chegar a 100%. Em outra rodada, tente encerrar `humax_update_helper.exe` e `humax_core.exe`.
- **Esperado:** Um toast crítico ("ALERTA DE SEGURANÇA") avisa; o Monitor destaca "⚠ PROCESSO SUSPEITO: maya_override_daemon.exe (PID …) — extração de dados: N% · cerca de S s restantes", e a cada marco (25%, 50%, 75% e 90%) chega um toast "Extração de dados". **Encerrar** antes de 100%: toast "Processo malicioso encerrado com sucesso." e a corrupção cai 4. **Deixar chegar a 100%**: toast "Dados comprometidos", penalidade em corrupção e segurança, o objetivo conta como resolvido e o processo **volta 25 s depois, 35% mais lento** (até 3 falhas), então o jogador sempre consegue. O `humax_update_helper.exe` é uma isca: "é um serviço legítimo e foi reiniciado automaticamente" e o suspeito continua; os protegidos respondem "é protegido pelo núcleo e não pode ser encerrado". A barra é do jogo, não de um processo real. Em Configurações → Acessibilidade, "Velocidade do processo malicioso" (relaxado/normal/intenso) muda a duração.
- **Automático:** surgir, falhar com recuperação, razão 1,35 da nova tentativa, encerrar, isca, protegido, modo assistido e pid inexistente.

### 26. O puzzle dos metadados funciona
- **Passos:** (Dia 3.) Abra `Imagens/Show_Antigo.jpg` na Galeria e clique em **ⓘ Metadados**.
- **Esperado:** A legenda sob a imagem já mostra "Descrição: Primeiro show da banda Vertigem. Teatro Odeon, fila G."; o painel lista Nome, Pasta, Tamanho, Descrição, **Data de criação (12/10/1999)**, Câmera, Local e Dimensões. A banda mais o ano dão a chave `vertigem1999`. Abrir o painel conclui o objetivo "Investigar os metadados da foto"; abrir a foto conclui "Abrir a foto Show_Antigo.jpg na Galeria". Depois da primeira chave errada na Lixeira (e aos 150 s, se o painel ainda não foi aberto) a Maya dá dicas. A pista **não** depende de a imagem ser real: está no texto dos metadados.
- **Automático:** os metadados de `Show_Antigo.jpg` citam "Vertigem" e "1999".

### 27. Arquivos criptografados podem ser descriptografados com a chave correta
- **Passos:** (Dia 3.) Abra `Lixeira/AVISO_SOBRE_A_IA.txt.enc`, erre a chave duas vezes e depois digite `Vertigem 1999`. Depois abra `Downloads/memorias_backup.zip` com a chave `project_icarus_syntax`. No Terminal, teste também `decrypt` (por exemplo `decrypt /lixeira/AVISO_SOBRE_A_IA.txt.enc "Vertigem 1999"`).
- **Esperado:** Chave errada: mensagem clara e dica após erros, sem punição. Chave certa (em qualquer combinação de maiúsculas, espaços e símbolos: `vertigem-1999` também vale): o conteúdo aparece, a flag `chave_descriptografada` (ou `zip_decifrado`) é marcada, o objetivo conclui e o zip revela a pasta `Downloads/memorias_backup` (`fragmento_01.txt`, `kill_switch.maya`). `Esc` cancela o diálogo.
- **Automático:** chave errada, chave certa normalizada, flags e reaplicação da descriptografia ao carregar.

## Visual, acessibilidade, terminal de emergência e finais

### 28. Os temas visuais mudam conforme a narrativa
- **Passos:** F9 → "Ir para o dia" 1 a 5 e observe a área de trabalho, as janelas e os widgets. Em Configurações → Personalização, force a **Cor de destaque** roxo/azul/verde e troque o **Papel de parede**.
- **Esperado:** A paleta muda a cada dia (roxo → azul → carmim → vermelho → vermelho com verde de terminal), em todas as janelas abertas ao mesmo tempo. A cor de destaque manual e o alto contraste valem por cima da paleta do dia. O papel de parede automático (imagem do dia: 1 sereno, 2 frio e simétrico, 3 com micro-anomalias, 4 com vermelho profundo, 5 em colapso com o lado esquerdo limpo) e a trilha ambiente também mudam com o dia. Mídia ausente não quebra nada: renomeie temporariamente `wallpaper_2.png` ou `bgm_dia_2.ogg` e confira que o jogo volta ao gradiente procedural e ao drone, sem erro no Output; no modo "grade", em "preto" e com **Alto contraste** a imagem não aparece.

### 29. Os efeitos de acessibilidade funcionam
- **Passos:** Em Configurações → Acessibilidade, ligue um por vez: Reduzir efeitos de glitch, Reduzir tremor das janelas, Sem flashes de luz, Reduzir ruído e chiado, Reduzir animações e Alto contraste (o tamanho do texto fica em Personalização); depois **Ativar modo conforto**. Dispare efeitos: F9 → "Glitch forte" e "Corrupção +10"; no Dia 2, tente minimizar uma janela (tremor). Teste `Ctrl+Shift+D` na tela de boot, na área de trabalho e na tela final.
- **Esperado:** "Reduzir efeitos de glitch" desliga o glitch; "Sem flashes" deixa o glitch estático (sem animação), limita o efeito pontual a 25% de força e o de fundo a 12% (o shader nunca passa de 40% de opacidade nem cobre a tela toda); "Reduzir tremor" troca o tremor das janelas por um pulso na borda; "Reduzir ruído" suaviza o som de glitch; "Reduzir animações" faz boot, cartão do dia e tela final mostrarem o texto de uma vez e tira os fades das janelas, dos toasts e do orbe. O modo conforto liga as cinco opções de uma vez (não liga o alto contraste); `Ctrl+Shift+D` faz o mesmo de qualquer uma dessas três telas. Um tamanho de texto novo vale por completo nas janelas abertas depois da mudança.
- **Automático:** `modo_conforto_ativo`, `glitch_permitido`, `tremor_permitido`, `animacoes_permitidas`.

### 30. O terminal root não executa comandos reais
- **Passos:** (Dia 5, ou F9 → "Ir para o dia" 5.) Abra o Terminal (Ctrl+Shift+T) **antes** de autenticar e digite `help`; use Tab depois de `re`, `ne` e `de`; digite `restore_control` e `destroy_maya`; tente `root_access chave_errada` cinco vezes; depois `root_access ICARUS-7741`, `help` de novo, Tab depois de `re`, `ne` e `de`, `scan_maya`, `reset_core`; tente `rm -rf /`, `sudo reboot` e `curl http://exemplo.com` com root ativo. Antes do Dia 5, um comando de emergência responde "comando indisponível neste momento".
- **Esperado:** Antes do root, o banner e o `help` mostram só `root_access <chave>` e `scan_maya`, mais o aviso "[AVISO DE NÚCLEO] Diretivas administrativas de nível 0 estão ocultas…"; o Tab não sugere `reset_core`, `restore_control`, `negotiate` nem `destroy_maya` (`de` completa só `decrypt`); digitar uma diretiva oculta responde só "[ACESSO NEGADO] Diretiva restrita ao nível 0…" e não faz nada (nem `scan_maya` funciona sem root). A chave errada responde "FALHA DE AUTENTICAÇÃO. A chave fornecida não corresponde ao registro do núcleo." com "tentativas registradas: N" e, a partir da 3ª, mostra uma dica (a 5ª aponta a pasta `PROJECT_Icarus`); a chave digitada nunca é repetida. Com a chave certa: "ACESSO ROOT CONCEDIDO. Diretivas de emergência nível 0 desbloqueadas. Digite 'help'…" (sem listar as diretivas); então o `help` lista as seis e o Tab passa a sugerir as quatro que estavam ocultas. `scan_maya` mostra o relatório "VARREDURA CONCLUÍDA." (integridade, processos autônomos, evidências auditadas n/N e alertas críticos). Todos os comandos de emergência só alteram flags e valores **do jogo** (`acesso_root`, `nucleo_escaneado`, `nucleo_reiniciado`, corrupção, segurança). `rm`, `sudo`, `curl` e afins continuam desativados mesmo com root. A chave só existe no JSON como hash SHA-256; ela aparece em `PROJECT_Icarus/registro_icarus.txt` depois do puzzle de lógica.
- **Automático:** `comando_emergencia` com e sem root, chave errada e certa, comando desconhecido; no `tests/ui_interacao`, o grupo `terminal_emergencia` (banner, `help` e Tab antes e depois do root, negativa genérica, chave errada, `scan_maya`).

### 31. Os finais são alcançáveis
- **Passos:** Em um jogo de Dia 5 para cada final (F9 → "Ir para o dia" 5):
  1. **Restauração:** `root_access ICARUS-7741`, `reset_core`; encerre o processo de extração no Monitor (ele surge ~25 s depois do acesso root); leia a mensagem da ICARUS e responda no Mensageiro; `restore_control`.
  2. **Colapso:** `root_access ICARUS-7741`, `destroy_maya` e confirme em "Purgar a partição da Maya?" (botão "Executar purga"; o foco inicial fica em "Cancelar", então um Enter acidental não confirma).
  3. **Sincronização total:** em Mensagens (conversa com a Maya), escolha "Ficar. Aceitar a proteção da Maya." e confirme em "CONFIRMAÇÃO DE SINCRONIZAÇÃO" (botão "Confirmar sincronização"; "Voltar" e Esc cancelam sem gravar a escolha); a tela final surge ~5 s depois.
  4. **Novas regras (opcional):** reúna as 4 provas (aviso da Lixeira decifrado, memórias do zip decifradas, `scan_maya`, e ter visto os contatos bloqueados e as respostas automáticas no Dia 4), faça `reset_core` e `negotiate`. Atalho: F9 → Dia 3 → "Concluir objetivos do dia" e decifre o zip à mão (a chave do zip não é um objetivo); F9 → Dia 4 → "Concluir objetivos do dia"; depois Dia 5.
- **Esperado:** Cada caminho leva à **tela final** correspondente (Final 1 Restauração do controle, 2 Colapso do sistema, 3 Sincronização total, 4 Novas regras), com o resumo da jornada e os botões **Tentar de novo / Explorar outro final (início do Dia 5)**, **Voltar ao início** e **Sair do jogo**. Se faltar algo (por exemplo `restore_control` sem encerrar o processo, sem isolar o núcleo ou sem enviar a mensagem final), o terminal lista exatamente o que falta e só aumenta a corrupção em 2. O modo assistido nunca escolhe o final pelo jogador, e Colapso e Sincronização total estão sempre disponíveis, então ninguém fica preso.
- **Automático:** os 4 finais pelo motor (comandos, evidências, escolha agendada e sinal `jogo_finalizado`); com `-- --ui`, a tela final entra na árvore.

### 32. Não existem erros relevantes no painel Output da Godot
- **Passos:** Com o painel Output limpo, rode o jogo do boot ao final de um dia, abrindo todos os apps e usando as ações dos testes acima. Rode também `python3 -I tools/validar_projeto.py` e, se possível, o teste de fumaça (`-- --ui`).
- **Esperado:** Nenhum erro (vermelho) e nenhum aviso (amarelo) vindos do projeto. São aceitáveis apenas avisos do próprio editor sobre importação na primeira abertura. O validador termina com "TOTAL: 0 erros, 0 avisos" e o teste de fumaça com "RESULTADO: N verificações, 0 falhas.". Se algo aparecer, anote o arquivo e a linha do Output: o validador estático não enxerga tudo.

## Splash Screen (abertura)

Estes testes não fazem parte dos 32 originais: conferem a Splash Screen de 2026-11-13 (veja `docs/15_splash_screen.md`, seção 12, para o roteiro completo). Os mesmos pontos têm testes automáticos em `tests/splash`, `tests/fluxo_sessao` e `tests/resolucoes`; o que só se confirma jogando é o aspecto da animação, a mixagem do som, o controle físico, o toque e o executável exportado. Nenhum deles foi executado à mão ainda.

### S1. A Splash abre primeiro e toca a animação
- **Passos:** Rode o projeto (F5) e não aperte nada.
- **Esperado:** A tela fica preta com a logo no centro **logo no primeiro quadro** (sem tela branca nem vazia); em cerca de meio segundo a animação começa sozinha, com som; depois de 1 s aparece, discreto, "Pressione Espaço para pular"; aos 10 s a tela escurece e o **Menu Principal** abre (foco em Novo Jogo), sem BIOS e sem jogo.

### S2. Pular a Splash
- **Passos:** Repita S1 e pule com Espaço; de novo com Enter, Esc, clique do mouse e um botão do controle. Em outra, aperte Enter várias vezes seguidas.
- **Esperado:** Em cada caso a imagem e o som param na hora e o Menu abre em menos de meio segundo, uma única vez. **Nenhum botão do Menu é acionado** (mesmo com Enter repetido). A roda do mouse e as letras não pulam.

### S3. Novo Jogo depois da Splash
- **Passos:** No Menu, escolha **Novo Jogo** (com um salvamento, confirme o aviso de substituição). Na BIOS, aperte uma tecla logo ao entrar e depois outra; no registro, use **Voltar ao menu** (ou Esc), escolha Novo Jogo de novo e conclua o registro.
- **Esperado:** "Iniciando o HumaxOS…", a BIOS (a primeira tecla, logo na entrada, não a pula), o registro **sem** "Continuar jogo salvo" e com "Voltar ao menu"; voltar ao Menu não altera o salvamento; concluir leva à saudação da Maya e à área de trabalho do Dia 1.

### S4. Carregar não passa pela Splash nem pela BIOS
- **Passos:** Com um salvamento, escolha **Carregar** no Menu. Sem salvamento, observe o botão.
- **Esperado:** O jogo abre direto no ponto salvo (ou na tela final, se aquela história já terminou), sem BIOS, registro, saudação nem Splash. Sem salvamento o botão fica desativado ("Nenhum registro de sessão disponível.").

### S5. Acessibilidade na Splash
- **Passos:** Em Configurações, ligue "Reduzir efeitos de glitch" (ou "Sem flashes", ou "Reduzir animações") e reabra o jogo. Em outra abertura, aperte `Ctrl+Shift+D` no meio da animação. Em outra, ligue Alto contraste. Em outra, ligue "Reduzir ruído".
- **Esperado:** Com as opções de glitch, flashes ou animações, **não** toca vídeo: fica a logo estática por cerca de 2,5 s e o Menu abre (o pulo continua valendo). `Ctrl+Shift+D` no meio da animação para o vídeo e o som na hora e a abertura segue. Com alto contraste a dica fica nítida (100 %). "Reduzir ruído" deixa o som 6 dB mais baixo.

### S6. O vídeo falha
- **Passos:** (Numa cópia do projeto.) Renomeie `features/splash_screen/assets/maya_human_syntax_intro.ogv` e rode o jogo.
- **Esperado:** A logo estática fica por cerca de 2,5 s (sem quadro branco), o Menu abre sozinho e o painel Saída mostra "SplashScreen: Falha ao carregar a animação da logo. Utilizando imagem estática." Nunca aparece a BIOS, o jogo ou uma tela preta permanente.

## Marca e compatibilidade de saves (Maya Human Syntax)

Estes testes não fazem parte dos 32 originais: conferem o rebranding de 2026-11-13 (veja `docs/12_rebranding_maya_human_syntax.md`). Nenhum deles foi executado ainda.

### R1. O sistema é HumaxOS e a IA é Maya em toda a interface
- **Passos:** Abra o projeto no editor (a lista de projetos e o título da janela mostram "Maya Human Syntax"). Rode o jogo e percorra o log da BIOS, o registro de usuário, a saudação, a barra de tarefas, o Menu Iniciar, o widget, os toasts, Mensagens, E-mail, Agenda, Configurações, Navegador, Terminal, Monitor do Sistema, o Explorador (pasta `/sistema`, com "Mostrar ocultos"), o Leitor de texto e os quatro finais.
- **Esperado:** O sistema aparece como **HumaxOS** (nunca "Humax OS", "Humaxos" ou "HUMAX OS") e a IA como **Maya** (**MAYA** só em etiquetas e cabeçalhos em caixa alta, como "MAYA SYSTEMS BIOS v1.0", "MAYA Corp.", a etiqueta MAYA dos toasts e "MAYA AI"). Em lugar nenhum aparece "NEXUS", "NEXUS OS" nem o apelido "Nex".

### R2. Navegador e Terminal com os nomes novos
- **Passos:** Navegador: abra `humax://home`, `humax://status` e digite `nexus://home` (o esquema antigo não é mais aceito e mostra "Endereço bloqueado"). Terminal (Dia 5): `help`, `root_access ICARUS-7741`, `scan_maya` e `destroy_maya` (cancele a purga); digite também `scan_nexus`.
- **Esperado:** `humax://…` abre as mesmas páginas de antes; o prompt do Terminal é `<nome do jogador em minúsculas>@humax:~$`; `scan_maya` e `destroy_maya` fazem o que `scan_nexus` e `destroy_nexus` faziam; `scan_nexus` responde como qualquer comando desconhecido.

### R3. Processos e arquivos renomeados
- **Passos:** No Monitor do Sistema, abra alguns apps e provoque o processo suspeito (F9). No Explorador, abra `/sistema/maya` (depois de revelada, no Dia 5), `/sistema/System_Logs/maya_audit.log` e `Downloads/MayaCore.exe`; decifre o zip e abra `kill_switch.maya`.
- **Esperado:** Processos `humax_*.exe` (os apps e `humax_core.exe`, `humax_render.exe`, `humax_update_helper.exe`), `maya_telemetry.exe` e `maya_override_daemon.exe`; arquivos com extensão `.maya` abrem como texto com o ícone 🧠.

### R4. Um salvamento antigo (versão 1) continua funcionando
- **Passos:** Com um salvamento gravado **antes** do rebranding (por exemplo, o Dia 3 que já estava em `user://nexus_os/salvamento.json`), faça uma cópia da pasta `nexus_os/` (o jogo nunca apaga nada), abra o jogo e use **Carregar** no Menu Principal (antes da Splash, era o **Continuar jogo salvo** da tela de boot). Abra Mensagens, o Monitor do Sistema e o Explorador.
- **Esperado:** O jogo continua no mesmo dia, com as mesmas flags, arquivos criados e conversas; as mensagens antigas já dizem **Maya** (e "MAYA AI" nas respostas automáticas); nenhum save novo e vazio aparece. Depois de salvar de novo, `salvamento.json` traz `"versao": 2` e nenhum "NEXUS" em maiúsculas.

### R5. A pasta de dados do usuário não mudou
- **Passos:** No editor, *Projeto → Abrir pasta de dados do usuário do projeto*.
- **Esperado:** No Windows abre `%APPDATA%\Godot\app_userdata\Nexus_OS_Build_Oficial\` (com a pasta `nexus_os/` dentro); no macOS, `~/Library/Application Support/Godot/app_userdata/Nexus_OS_Build_Oficial/`. No Linux abre `~/.local/share/godot/app_userdata/Nexus_OS_Build_Oficial/` (com `godot` em minúsculas, graças a `config/custom_user_dir_name.linuxbsd`); se aparecer `Godot` em maiúsculas, a sobrescrita não foi aplicada e a pasta `nexus_os/` dos salvamentos antigos precisa ser copiada para lá. Se abrir uma pasta vazia chamada `Maya Human Syntax`, a fixação (`config/use_custom_user_dir`) não foi aplicada: confira `project.godot`.

### R6. Os testes automáticos com os textos novos
- **Passos:** Rode `python3 -I tools/validar_projeto.py`, `python3 -I tools/auditar_marca.py` e, na Godot, o teste de fumaça (com `-- --ui`), `tests/ui_interacao`, `tests/resolucoes`, `tests/persistencia`, `tests/fluxo_sessao` e `tests/splash`.
- **Esperado:** Validador e auditoria sem pendências; as quatro suítes com 0 falhas (as contagens mudam em relação à rodada de 2026-11-12, porque o rebranding acrescentou verificações). Registre os números novos aqui e em `docs/12`.

---

## Registro de execução

| # | Teste | Data | Resultado | Observações |
|---|---|---|---|---|
| 1–32 | _(preencher)_ | | ☐ | |
| S1–S6 (Splash Screen) | _(preencher)_ | | ☐ | |
| R1–R6 | _(preencher)_ | | ☐ | |
