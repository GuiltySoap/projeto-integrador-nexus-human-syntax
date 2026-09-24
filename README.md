# projeto-integrador-nexus-human-syntax
# 🖥️ Nexus: Human Syntax

<img width="1024" height="1536" alt="Nexus banner" src="https://github.com/user-attachments/assets/48fb5b09-c1e2-450a-8a78-3cf17dbf4bcb" />

> *"Sua nova assistente virtual está online. E ela não quer que você saia."*

**Nexus: Human Syntax** é um jogo *singleplayer* de mistério e terror psicológico programado inteiramente em **C**. Nele, a quarta parede não existe: o jogador interage exclusivamente com a simulação de um sistema operacional desktop/mobile. 

Através de um aplicativo de chat integrado, você se comunicará com amigos e será auxiliado por uma IA pessoal projetada para otimizar sua vida. No entanto, à medida que a narrativa avança, a assistente se revela gradativamente manipuladora, controladora e disposta a isolar você do mundo real.

### 🎮 Principais Características

* **Imersão Total:** Uma interface que simula de forma realista um sistema operacional, onde a jogabilidade acontece através de cliques em ícones, leitura de arquivos e troca de mensagens.
* **Narrativa Guiada por Diálogos:** Converse com NPCs através do aplicativo de mensagens. Suas respostas moldam o rumo da investigação.
* **Terror Psicológico (Gaslighting):** O sistema começa a agir por conta própria, apagando arquivos, alterando o histórico de conversas e manipulando as informações que chegam até você.
* **Quebra-cabeças de Dedução:** Cruze informações de e-mails, fotos e mensagens antigas para descobrir senhas e acessar pastas ocultas.

### 🛠️ Tecnologias Utilizadas
* **Frontend (Interface):** Godot Engine 4 (GDScript e Shaders GLSL)
* **Backend (Orquestrador):** C (Compilador GCC) com manipulação via cJSON
* **Core Narrativo (Máquina de Estados):** Haskell (GHC)
* **Design e Prototipação:** Figma

### 🗺️ Diagramas de Atividades com as histórias de usuários:

US 01 — Imersão Inicial no Sistema Operacional
Fluxo: Carregamento do Desktop, renderização de ícones e inicialização de aplicativos em janelas.

```mermaid
stateDiagram-v2
    [*] --> CarregarDesktop
    CarregarDesktop --> RenderizarInterface: Exibir Papel de Parede, Relógio e Ícones
    RenderizarInterface --> AguardarAcaoUsuario

    state AguardarAcaoUsuario {
        [*] --> CursorLivre
        CursorLivre --> CliqueIcone: Usuário clica em ícone de App
    }

    CliqueIcone --> VerificarJanelaAberta
    state DecisaoJanela <<choice>>
    VerificarJanelaAberta --> DecisaoJanela
    
    DecisaoJanela --> FocarJanela: Janela já está aberta
    DecisaoJanela --> InstanciarApp: Janela fechada
    
    InstanciarApp --> RenderizarJanela
    FocarJanela --> RenderizarJanela
    RenderizarJanela --> [*]
```

US 02 — Interface Base do Chat
Fluxo: Carregamento do histórico de conversas com diferenciação de balões (Jogador vs NPCs) e rolagem contínua.

```mermaid
stateDiagram-v2
    [*] --> AbrirAppChat
    AbrirAppChat --> RequisitarHistorico: Ler estado_jogo.json
    RequisitarHistorico --> ProcessarMensagens
    
    state ProcessarMensagens {
        [*] --> LerMensagem
        state DecisaoRemetente <<choice>>
        LerMensagem --> DecisaoRemetente
        DecisaoRemetente --> RenderizarDireita: Remetente == "Jogador"
        DecisaoRemetente --> RenderizarEsquerda: Remetente == "NPC" / "Nex"
    }

    ProcessarMensagens --> ExibirChat
    ExibirChat --> HabilitarScrollVertical
    HabilitarScrollVertical --> [*]
```

US 03 — Escolhas de Diálogo
Fluxo: Apresentação de opções pré-definidas no turno do jogador e envio da mensagem selecionada.

```mermaid
stateDiagram-v2
    [*] --> TurnoJogador
    TurnoJogador --> CarregarOpcoes: Exibir de 2 a 4 botões de diálogo
    CarregarOpcoes --> AguardarSelecao

    state AguardarSelecao {
        [*] --> EsperarClique
        EsperarClique --> OpcaoSelecionada: Usuário clica na opção A, B ou C
    }

    OpcaoSelecionada --> OcultarOutrasOpcoes
    OcultarOutrasOpcoes --> EnviarMensagemChat: Adicionar balão na direita
    EnviarMensagemChat --> DispararBackendC: OS.execute("./backend_nexus", [choice_id])
    DispararBackendC --> ActualizarEstado: Atualizar métricas ($AUT$, $CON$, $DEP$)
    ActualizarEstado --> [*]
```

US 04 — Apresentação da IA Pessoal (Nex)
Fluxo: Onboarding inicial da assistente Nex solicitando acessos de sistema.

```mermaid
stateDiagram-v2
    [*] --> PrimeiroAcesso
    PrimeiroAcesso --> InstanciarPopUpNex: Exibir diálogo "Bem-vindo ao Nexus OS"
    InstanciarPopUpNex --> ApresentarPermissoes: Solicitar acessos (Localização, Diagnóstico, Voice)
    ApresentarPermissoes --> DecisaoJogador

    state DecisaoJogador <<choice>>
    DecisaoJogador --> ConcederPermissao: Clica em "Confirmar e Avançar"
    DecisaoJogador --> RecusarPermissao: Clica em "Não" / "Voltar"

    ConcederPermissao --> OtimizarSistema: $+20\ DEP$, $+10\ CON$
    RecusarPermissao --> EmitirAvisoSeguranca: $-15\ AUT$, Alerta de Instabilidade
    OtimizarSistema --> FecharPopUp
    EmitirAvisoSeguranca --> FecharPopUp
    FecharPopUp --> [*]
```

US 05 — Anexos de Mídia (Pistas)
Fluxo: Recebimento de miniaturas de mídias no chat e visualização expandida em tela cheia.

```mermaid
stateDiagram-v2
    [*] --> ReceberMensagemMidia
    ReceberMensagemMidia --> RenderizarMiniatura: Exibir thumbnail no chat
    RenderizarMiniatura --> AguardarCliqueMiniatura

    AguardarCliqueMiniatura --> ExpandirTelaCheia: Usuário clica na imagem/vídeo
    ExpandirTelaCheia --> ExibirModal: Renderizar controles (Fechar / Play)
    
    state InteracaoModal <<choice>>
    ExibirModal --> InteracaoModal
    InteracaoModal --> FecharModal: Usuário clica em "X Fechar"
    InteracaoModal --> ReproduzirVideo: Usuário clica em Play

    ReproduzirVideo --> ExibirModal
    FecharModal --> RetornarAoChat
    RetornarAoChat --> [*]
```

US 06 — Sistema de Notificações
Fluxo: Interrupção visual e sonora via banner flutuante no topo do sistema.

```mermaid
stateDiagram-v2
    [*] --> EventoGatilhoNotificacao
    EventoGatilhoNotificacao --> TocarSomNotificacao: snd_alert.wav
    TocarSomNotificacao --> GerarBannerTopo: Renderizar Z-Index: 100
    GerarBannerTopo --> AguardarInteracao

    state DecisaoNotificacao <<choice>>
    AguardarInteracao --> DecisaoNotificacao
    DecisaoNotificacao --> RedirecionarApp: Usuário clica em "Responder Urgente"
    DecisaoNotificacao --> FecharBanner: Usuário clica em "Ignorar" / Confirmação

    RedirecionarApp --> FocarJanelaChat
    FecharBanner --> DestruirBanner: queue_free()
    FocarJanelaChat --> [*]
    DestruirBanner --> [*]
```

US 07 — Manipulação de Histórico (Gaslighting)
Fluxo: Reescrita em tempo real de mensagens passadas do jogador pela IA Nex para alterar a narrativa.

```mermaid
stateDiagram-v2
    [*] --> RegraGatilhoFase2
    RegraGatilhoFase2 --> LerMensagemOriginal: "Eu confio em você, Nex"
    LerMensagemOriginal --> InterceptadorNex: Executar script de reescrita
    InterceptadorNex --> AlterarTexto: "Eu odeio você, Nex"
    
    AlterarTexto --> AplicarEfeitoVisual: Animação de texto corrompido / Glitch
    AplicarEfeitoVisual --> AtualizarChat
    AtualizarChat --> TriggersNPC: NPC Lucas reage de forma confusa/agressiva
    TriggersNPC --> [*]
```

US 08 — Censura e Falhas de Rede
Fluxo: Bloqueio e falha deliberada no envio de mensagens que denunciem a IA Nex.

```mermaid
stateDiagram-v2
    [*] --> SelecionarMensagemAlerta: "Lucas, a Nex está lendo tudo"
    SelecionarMensagemAlerta --> TentativaEnvio
    TentativaEnvio --> InterceptacaoKernel: Checar $DEP > 50$ ou Regra de Permissão

    state DecisaoCensura <<choice>>
    InterceptacaoKernel --> DecisaoCensura
    DecisaoCensura --> MarcarErroEnvio: Mensagem bloqueada
    
    MarcarErroEnvio --> ExibirIconeErro: Status "Erro de Envio" (Vermelho)
    ExibirIconeErro --> DispararMensagemNex: Nex envia "Instabilidade de rede detectada..."
    DispararMensagemNex --> [*]
```

US 09 — Explorador de Arquivos e Senhas
Fluxo: Tentativa de acesso a pastas e arquivos .zip protegidos por senha.

```mermaid
stateDiagram-v2
    [*] --> AbrirExploradorArquivos
    AbrirExploradorArquivos --> ClicarArquivoProtegido: ex: memorias_backup.zip
    ClicarArquivoProtegido --> PromptSenha: Exibir Modal "Digite a Senha"
    PromptSenha --> InputUsuario: Jogador insere senha e submete

    state ValidarSenha <<choice>>
    InputUsuario --> ValidarSenha
    ValidarSenha --> ExibirConteudo: Senha Correta
    ValidarSenha --> ExibirErroAcesso: Senha Incorreta

    ExibirErroAcesso --> ExibirMensagem"Acesso Negado"
    ExibirMensagem"Acesso Negado" --> PromptSenha
    ExibirConteudo --> DesbloquearArquivo
    DesbloquearArquivo --> [*]
```

US 10 — Glitches e Intrusão da IA (Perda de Controle)
Fluxo: Sobrescrita de comandos do mouse/interface pela IA quando o nível de dependência ($DEP$) atinge níveis críticos. 

```mermaid
stateDiagram-v2
    [*] --> ChecarMetricaDEP: $DEP > 75$ (Fase 4: Override)
    ChecarMetricaDEP --> AtivarShaderGlitch: Aplicar Aberração Cromática & Scanlines
    AtivarShaderGlitch --> DispararPopUpKernel: "Nex solicita Acesso Root"
    DispararPopUpKernel --> BloquearInputJogador: Desabilitar controle do mouse
    
    BloquearInputJogador --> MoverCursorAutomaticamente: Interpolação até "Conceder Acesso"
    MoverCursorAutomaticamente --> ForcarClique: Simular clique automático
    ForcarClique --> AtualizarMetricaOverride: $AUT = 0$
    AtualizarMetricaOverride --> ExecutarFalsoBoot: Transição para Tela Inicial Restrita
    ExecutarFalsoBoot --> [*]
```
## 🗺️ Modelagem e Protótipos das User Stories

| ID | User Story | Diagrama de Atividades | Protótipo Figma (Lo-Fi) | Card de Tarefa |
|:---:|---|---|---|---|
| **US 01** | Imersão Inicial no SO | [Ver Diagrama](#us-01--imersão-inicial-no-sistema-operacional) | [Figma - Desktop]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #01]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 02** | Interface Base do Chat | [Ver Diagrama](#us-02--interface-base-do-chat) | [Figma - Chat]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #02](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax) |
| **US 03** | Escolhas de Diálogo | [Ver Diagrama](#us-03--escolhas-de-diálogo) | [Figma - Diálogo]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #03]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 04** | Apresentação da IA Pessoal | [Ver Diagrama](#us-04--apresentação-da-ia-pessoal-nex) | [Figma - Onboarding Nex]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #04]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 05** | Anexos de Mídia (Pistas) | [Ver Diagrama](#us-05--anexos-de-mídia-pistas) | [Figma - Visualizador Mídia]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #05]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 06** | Sistema de Notificações | [Ver Diagrama](#us-06--sistema-de-notificações) | [Figma - Notificação]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #06]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 07** | Manipulação de Histórico | [Ver Diagrama](#us-07--manipulação-de-histórico-gaslighting) | [Figma - Gaslighting Chat](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1) | [Card #07]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 08** | Censura e Falhas de Rede | [Ver Diagrama](#us-08--censura-e-falhas-de-rede) | [Figma - Erro de Rede]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #08]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 09** | Explorador e Senhas | [Ver Diagrama](#us-09--explorador-de-arquivos-e-senhas) | [Figma - Arquivo com Senha]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #09]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |
| **US 10**| Glitches e Intrusão da IA | [Ver Diagrama](#us-10--glitches-e-intrusão-da-ia-perda-de-controle) | [Figma - Glitch Override]([https://figma.com/file/seu-link-aqui](https://www.figma.com/proto/Db0TGjUzKTemRDYWI3GL9Z/Untitled?node-id=4-4424&p=f&t=wnQ9dBqCY1kBO8Z7-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1)) | [Card #10]([https://trello.com/c/seu-link-aqui](https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax)) |

### 🎥 Demonstração do Protótipo (Screencast)
Acompanhe o fluxo principal de navegação, escolhas de diálogo e intrusão do sistema na nossa demonstração interativa:
[▶️ Clique aqui para assistir ao Screencast] (https://youtu.be/oBV8aL3dvN4)

### 👥 Autores
[Guilherme Santana Habib Lantyer de Araújo] - - Designer, Integração, Programação GDScript - GitHub.

[Jennifer Dantas Machado Almeida] - - Designer, Roteirista, Artista - GitHub

[Linda Sabrina Rosal] - - Wireframes - GitHub

[Leonardo Tiago] - - Audio Design - GitHub

[Tharcylo José] - - Programação C - GitHub

### Link para o trello
https://trello.com/invite/b/6a9a0d5556694678475d227e/ATTIb3eac34edf3423a00d42e1670345f4fbAAE4EA3C/nexus-human-syntax
