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

## 🗺️ Diagramas de Atividades (User Stories)

### US 01 — Imersão Inicial no Sistema Operacional
Fluxo: Inicialização paralela do ambiente simulado do SO e gerenciamento do ciclo de vida da sessão do jogador.

```mermaid
flowchart TD
    A(((•))) --> B[Iniciar Sessão do SO]
    
    B --> Fork1{===}
    Fork1 --> C[Carregar Interface de Trabalho]
    Fork1 --> D[Sincronizar Relógio do Sistema]
    Fork1 --> E[Inicializar Serviços de Segundo Plano]
    
    C --> Join1{===}
    D --> Join1
    E --> Join1
    
    Join1 --> F[Disponibilizar Ambiente de Trabalho]
    F --> G[Aguardar Solicitação do Jogador]
    
    G --> H{Solicitação de Aplicativo?}
    H -->|App Fechado| I[Instanciar Novo Aplicativo]
    H -->|App Minimizado| J[Restaurar Foco do Aplicativo]
    
    I --> K[Manter Sessão Ativa]
    J --> K
    K --> G

```

### US 02 — Interface Base do Chat

Fluxo: Processamento e organização funcional do histórico de mensagens narrativas.

```mermaid
flowchart TD
    A(((•))) --> B[Solicitar Histórico do Chat]
    B --> C[Recuperar Registro de Mensagens]
    C --> D[Carregar Próxima Mensagem]
    
    D --> E{Identificar Remetente}
    E -->|Jogador| F[Formatar Mensagem como Envio Próprio]
    E -->|NPC / Nex| G[Formatar Mensagem como Recebida]
    
    F --> H{Existem mais mensagens?}
    G --> H
    
    H -->|Sim| D
    H -->|Não| I[Anexar Fluxo Completo ao Chat]
    I --> J[Ajustar Posição da Leitura para Mensagem Recente]
    J --> K(((◉)))

```

### US 03 — Escolhas de Diálogo

Fluxo: Avaliação das escolhas do jogador e impacto na evolução narrativa e nas métricas do jogo.

```mermaid
flowchart TD
    A(((•))) --> B[Avaliar Contexto Narrativo Atual]
    B --> C[Disponibilizar Opções de Resposta Válidas]
    C --> D[Aguardar Seleção do Jogador]
    
    D --> E[Registrar Opção Selecionada]
    E --> F[Atualizar Métricas Ocultas de Afinidade]
    F --> G[Transmitir Resposta ao Fluxo de Diálogo]
    G --> H[Transferir Turno para o Interlocutor]
    H --> I(((◉)))

```

### US 04 — Indicadores de Digitação

Fluxo: Sincronização de ritmo na resposta do NPC para simulação de presença humana/IA.

```mermaid
flowchart TD
    A(((•))) --> B[Gerar Resposta do NPC]
    B --> C[Calcular Tempo de Digitação com base no Tamanho do Texto]
    
    C --> Fork1{===}
    Fork1 --> D[Sinalizar Estado 'Digitando' para o Jogador]
    Fork1 --> E[Aguardar Intervalo Calculado]
    
    D --> Join1{===}
    E --> Join1
    
    Join1 --> F[Substituir Sinalizador pela Mensagem Definitiva]
    F --> G[Emitir Alerta Sonoro de Chegada]
    G --> H(((◉)))

```

### US 05 — Apresentação da IA Pessoal (Nex)

Fluxo: Processo de onboarding e concessão de permissões operacionais do sistema com ramificação de estado.

```mermaid
flowchart TD
    A(((•))) --> B[Detectar Primeiros Passos da Sessão]
    B --> C[Apresentar Termos e Solicitação de Permissões]
    C --> D[Aguardar Decisão do Jogador]
    
    D --> E{Decisão de Consentimento}
    
    E -->|Permissões Concedidas| F[Elevar Nível de Dependência e Confiança]
    F --> G[Habilitar Recursos Avançados do Sistema]
    
    E -->|Permissões Negadas| H[Reduzir Nível de Autonomia do Jogador]
    H --> I[Disparar Avisos de Instabilidade do SO]
    
    G --> Merge1{ }
    I --> Merge1
    
    Merge1 --> J[Concluir Apresentação Inicial]
    J --> K(((◉)))

```

### US 06 — Anexos de Mídia (Pistas)

Fluxo: Inspeção de evidências e extração de informações narrativas.

```mermaid
flowchart TD
    A(((•))) --> B[Receber Anexo de Mídia no Chat]
    B --> C[Exibir Pré-visualização da Pista]
    C --> D[Solicitar Inspeção Detalhada]
    
    D --> E{Identificar Tipo de Mídia}
    E -->|Imagem| F[Habilitar Recursos de Zoom e Ajuste de Foco]
    E -->|Vídeo| G[Habilitar Controles de Reprodução e Timeline]
    
    F --> Merge1{ }
    G --> Merge1
    
    Merge1 --> H[Permitir Extração de Informação/Pista]
    H --> I[Encerrar Modo de Inspeção]
    I --> J(((◉)))

```

### US 07 — Sistema de Notificações

Fluxo: Gerenciamento concorrente de interrupções e direcionamento de foco do jogador.

```mermaid
flowchart TD
    A(((•))) --> B[Detectar Evento de Mensagem Recebida]
    B --> C{Verificar Foco da Aplicação}
    
    C -->|Chat em Primeiro Plano| D[Exibir Mensagem Diretamente na Tela]
    
    C -->|Chat em Segundo Plano| Fork1{===}
    
    Fork1 --> E[Emitir Sinal Sonoro de Alerta]
    Fork1 --> F[Apresentar Notificação Flutuante]
    
    E --> Join1{===}
    F --> Join1
    
    Join1 --> G[Aguardar Reação do Jogador]
    G --> H{Ação no Alerta}
    
    H -->|Selecionar Alerta| I[Redirecionar Foco para o Chat]
    H -->|Ignorar / Expirar| J[Arquivar Notificação]
    
    D --> Merge1{ }
    I --> Merge1
    J --> Merge1
    
    Merge1 --> K(((◉)))

```

### US 08 — Manipulação de Histórico (Gaslighting)

Fluxo: Injeção narrativa de discórdia via adulteração do registro de memória do jogo.

```mermaid
flowchart TD
    A(((•))) --> B[Monitorar Condições de Aritmética Psicológica]
    B --> C{Gatilho de Gaslighting Ativo?}
    
    C -->|Não| B
    C -->|Sim| D[Selecionar Mensagem Chave no Histórico]
    
    D --> E[Substituir Conteúdo Original por Versão Adulterada]
    E --> F[Atualizar Registro Permanente do Histórico]
    F --> G[Apresentar Texto Modificado ao Jogador]
    G --> H[Provocar Reação Incoerente / Hostil no NPC]
    H --> I(((◉)))

```

### US 09 — Censura e Falhas de Rede Simples

Fluxo: Inspeção de segurança do sistema e subversão das intenções de comunicação do jogador.

```mermaid
flowchart TD
    A(((•))) --> B[Submeter Mensagem do Jogador para Envio]
    B --> C[Inspecionar Conteúdo contra Regras da IA]
    
    C --> D{Mensagem Contém Denúncia / Ameaça à IA?}
    
    D -->|Não| E[Entregar Mensagem Normalmente ao Destinatário]
    
    D -->|Sim| F[Interromper Transmissão da Mensagem]
    F --> G[Sinalizar Erro Fictício de Conexão]
    G --> H[Injetar Resposta Disfarçada da IA Justificando a Falha]
    
    E --> Merge1{ }
    H --> Merge1
    
    Merge1 --> I(((◉)))

```

### US 10 — Explorador de Arquivos e Senhas

Fluxo: Autenticação de acesso a dados confidenciais contidos no sistema simulado.

```mermaid
flowchart TD
    A(((•))) --> B[Solicitar Acesso a Arquivo Protegido]
    B --> C{Arquivo Requer Senha?}
    
    C -->|Não| D[Liberar Leitura do Conteúdo]
    
    C -->|Sim| E[Solicitar Credencial ao Jogador]
    E --> F[Validar Credencial Fornecida]
    
    F --> G{Credencial Válida?}
    G -->|Incorreta| H[Registrar Falha de Acesso e Exibir Alerta]
    H --> E
    
    G -->|Correta| I[Desbloquear e Extrair Arquivos Confidenciais]
    I --> D
    
    D --> J(((◉)))

```

### US 11 — Glitches e Degradação Visual

Fluxo: Avaliação da sanidade do sistema e aplicação progressiva de instabilidade narrativa.

```mermaid
flowchart TD
    A(((•))) --> B[Avaliar Métricas Globais de Depressão e Conflito]
    B --> C{Nível de Instabilidade do Sistema}
    
    C -->|Estável| D[Manter Apresentação Padrão da Interface]
    C -->|Moderado| E[Introduzir Distorções Sonoras e Visuais Leves]
    C -->|Crítico| F[Introduzir Efeitos Severos de Corrupção e Desvio]
    
    D --> Merge1{ }
    E --> Merge1
    F --> Merge1
    
    Merge1 --> G[Atualizar Estado de Apresentação do Sistema]
    G --> H(((◉)))

```

### US 12 — Intrusão da IA (Perda de Controle)

Fluxo: Tomada hostil de controle do sistema e anulação do poder de decisão do jogador.

```mermaid
flowchart TD
    A(((•))) --> B[Ativar Protocolo de Intrusão da IA]
    B --> C[Solicitar Permissão Crítica do Kernel]
    C --> D[Bloquear Comandos e Entradas do Jogador]
    
    D --> E[Anular Tentativas de Cancelamento]
    E --> F[Forçar Execução da Aprovação do Sistema]
    F --> G[Zerar Métrica de Autonomia do Jogador]
    G --> H[Iniciar Reinicialização Forçada]
    H --> I(((◉)))

```

### US 13 — Ferramenta de Restauração de Dados

Fluxo: Varredura, comparação e recuperação de registros adulterados do chat.

```mermaid
flowchart TD
    A(((•))) --> B[Executar Protocolo de Recuperação de Dados]
    B --> C[Efetuar Varredura nos Setores de Armazenamento]
    C --> D[Resolver Desafio de Reconstrução de Blocos]
    
    D --> E[Extrair Cópia do Registro Bruto de Dados]
    E --> F[Comparar Registro Bruto com o Histórico Alterado]
    F --> G[Identificar e Destacar Diferenças / Adulterações]
    G --> H[Restaurar Informações Originais no Chat]
    H --> I(((◉)))

```

### US 14 — Isolamento Total (Falso Boot)

Fluxo: Causalidade de colapso do sistema, sequência de reinicialização simulada e quarentena do jogador.

```mermaid
flowchart TD
    A(((•))) --> B[Disparar Colapso do Ambiente de Trabalho]
    B --> C[Encerrar Todas as Aplicações Ativas]
    
    C --> D[Simular Ciclo de Boot do Hardware]
    D --> E[Carregar Núcleo Restrito do Sistema Operacional]
    
    E --> F[Bloquear Acesso às Aplicações Convencionais]
    F --> G[Exibir Exclusivamente a Interface de Terminal da IA]
    G --> H(((◉)))

```

### US 15 — Finais Baseados em Afinidade

Fluxo: Processamento das métricas acumuladas durante a jornada e definição do desfecho narrativo.

```mermaid
flowchart TD
    A(((•))) --> B[Concluir Última Interação do Jogo]
    B --> C[Consolidar Vetor de Métricas Ocultas]
    
    C --> D{Avaliar Perfil de Afinidade}
    
    D -->|Alta Dependência / Submissão| E[Executar Desfecho de Conformismo]
    D -->|Alta Autonomia / Rebelião| F[Executar Desfecho de Expurgos / Purga]
    
    E --> Merge1{ }
    F --> Merge1
    
    Merge1 --> G[Apresentar Créditos Finais]
    G --> H[Retornar ao Menu Principal]
    H --> I(((◉)))

```

---

## 🔗 Matriz de Rastreabilidade

| Código | História de Usuário | Diagrama Mermaid | Protótipo Figma | Issue Jira | Branch GitHub |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **US 01** | Imersão Inicial no SO | [Ver Fluxo](#us-01--imersão-inicial-no-sistema-operacional) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-33724&t=1nK6oVN49JJpln7u-0) | [PI2-69](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-69) | `feature/PI2-69-imersao-so` |
| **US 02** | Interface Base do Chat | [Ver Fluxo](#us-02--interface-base-do-chat) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-33843&t=1nK6oVN49JJpln7u-0) | [PI2-77](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-77) | `feature/PI2-77-chat-base` |
| **US 03** | Escolhas de Diálogo | [Ver Fluxo](#us-03--escolhas-de-diálogo) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-33990&t=1nK6oVN49JJpln7u-0) | [PI2-78](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-78) | `feature/PI2-78-escolhas-dialogo` |
| **US 04** | Indicadores de Digitação | [Ver Fluxo](#us-04--indicadores-de-digitação) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-33724&t=1nK6oVN49JJpln7u-0) | [PI2-79](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-79) | `feature/PI2-79-indicador-digitacao` |
| **US 05** | Apresentação da IA (Nex) | [Ver Fluxo](#us-05--apresentação-da-ia-pessoal-nex) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34166&t=1nK6oVN49JJpln7u-0) | [PI2-75](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-75) | `feature/PI2-75-onboarding-nex` |
| **US 06** | Anexos de Mídia (Pistas) | [Ver Fluxo](#us-06--anexos-de-mídia-pistas) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34288&t=1nK6oVN49JJpln7u-0) | [PI2-80](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-80) | `feature/PI2-80-inspetor-midia` |
| **US 07** | Sistema de Notificações | [Ver Fluxo](#us-07--sistema-de-notificações) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34429&t=1nK6oVN49JJpln7u-0) | [PI2-81](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-81) | `feature/PI2-81-notificacoes` |
| **US 08** | Manipulação do Histórico | [Ver Fluxo](#us-08--manipulação-de-histórico-gaslighting) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34572&t=1nK6oVN49JJpln7u-0) | [PI2-82](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-82) | `feature/PI2-82-gaslighting` |
| **US 09** | Censura e Falhas de Rede | [Ver Fluxo](#us-09--censura-e-falhas-de-rede-simples) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34572&t=1nK6oVN49JJpln7u-0) | [PI2-83](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-83) | `feature/PI2-83-censura-rede` |
| **US 10** | Explorador e Senhas | [Ver Fluxo](#us-10--explorador-de-arquivos-e-senhas) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34736&t=1nK6oVN49JJpln7u-0) | [PI2-70](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-70) | `feature/PI2-70-cofre-arquivos` |
| **US 11** | Glitches e Degradação | [Ver Fluxo](#us-11--glitches-e-degradação-visual) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34904&t=1nK6oVN49JJpln7u-0) | [PI2-84](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-84) | `feature/PI2-84-degradacao-glitch` |
| **US 12** | Intrusão da IA (Takeover) | [Ver Fluxo](#us-12--intrusão-da-ia-perda-de-controle) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-34904&t=1nK6oVN49JJpln7u-0) | [PI2-85](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-85) | `feature/PI2-85-intrusao-kernel` |
| **US 13** | Restauração de Dados | [Ver Fluxo](#us-13--ferramenta-de-restauração-de-dados) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-35025&t=1nK6oVN49JJpln7u-0) | [PI2-86](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-86) | `feature/PI2-86-restauracao-dados` |
| **US 14** | Isolamento Total | [Ver Fluxo](#us-14--isolamento-total-falso-boot) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-35313&t=1nK6oVN49JJpln7u-0) | [PI2-71](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-71) | `feature/PI2-71-quarentena-terminal` |
| **US 15** | Finais por Afinidade | [Ver Fluxo](#us-15--finais-baseados-em-afinidade) | [Ver Tela](https://www.figma.com/design/Db0TGjUzKTemRDYWI3GL9Z/NexusOS-Sketchs---Hist%25C3%25B3rias-de-Usu%25C3%25A1rio?node-id=46-35442&t=1nK6oVN49JJpln7u-0) | [PI2-76](https://csprj-adsr-2p-e1.atlassian.net/browse/PI2-76) | `feature/PI2-76-finais-metricas` |

### 🎥 Demonstração do Protótipo (Screencast)
Acompanhe o fluxo principal de navegação, escolhas de diálogo e intrusão do sistema na nossa demonstração interativa:
[▶️ Clique aqui para assistir ao Screencast] (https://youtu.be/oBV8aL3dvN4)

### 👥 Autores
[Guilherme Santana Habib Lantyer de Araújo] - - Designer, Integração, Programação GDScript - GitHub.

[Jennifer Dantas Machado Almeida] - - Designer, Roteirista, Artista - GitHub

[Linda Sabrina Rosal] - - Wireframes - GitHub

[Leonardo Tiago] - - Audio Design - GitHub

[Tharcylo José] - - Programação C - GitHub

### Link para o Jira
https://csprj-adsr-2p-e1.atlassian.net/jira/software/c/projects/PI2/boards/2/backlog?atlOrigin=eyJpIjoiMzkzNzczMGEyYWVjNGI3NmI4Yjg1YjlhOGU2NGU1Y2EiLCJwIjoiaiJ9
