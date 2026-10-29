# Como Contribuir com o IARA

Obrigado por colocar a mão na massa! Este guia explica como a gente trabalha no repositório: como organizar branches, como escrever commits e como levar uma mudança até o `main`.

A ideia central é simples: **mudanças pequenas, revisadas rápido e integradas com frequência.**

---

## 1. Fluxo de trabalho (GitHub Flow)

Usamos um fluxo enxuto, com **uma única branch de longa duração**: o `main`.

| Branch | Papel | Nasce de | Vai para |
|--------|-------|----------|----------|
| `main` | Sempre estável e jogável. Tudo que está aqui pode virar entrega. | — | — |
| `<tipo>/<escopo-curto>` | Uma mudança isolada, de vida curta (idealmente 1 a 3 dias). | `main` | `main` |

Entregas oficiais (U1, U2, ...) não têm branch própria. Elas são marcadas com **tags** no `main`:

```bash
git tag -a v1.0.1 -m "Entrega U1"
git push origin v1.0.1
```

### Regras

- Ninguém faz push direto no `main`. Toda mudança entra por Pull Request.
- Uma branch resolve **um** problema. Se você começou a mexer em outra coisa, abra outra branch.
- Atualize sua branch com o `main` antes de pedir revisão (`git pull --rebase origin main`).
- Branch mesclada é branch apagada. O GitHub pode fazer isso automaticamente após o merge.
- Correção urgente? Segue o mesmo caminho, só que com prioridade na revisão. Não existe fila separada para `hotfix`.

### Nomes de branches

Formato: `<tipo>/<area>-<descricao-curta>`, tudo em minúsculas e separado por hífen.

```
feat/engine-c-menu-principal
feat/rules-hs-pontuacao-dia12
fix/engine-c-crash-menu
docs/atualiza-readme
chore/atualiza-dependencias
```

O `<tipo>` é o mesmo usado nos commits (veja a seção 2).

---

## 2. Mensagens de commit

Seguimos o [Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/) com **escopo entre parênteses** para dizer qual parte do projeto foi tocada:

```
tipo(escopo): descrição curta no imperativo

Corpo opcional: explique o POR QUÊ, não só o quê.

Refs: #42
```

### Tipos

| Tipo | Use quando... |
|---|---|
| `feat` | Entra uma funcionalidade nova no jogo |
| `fix` | Você corrige um bug |
| `docs` | Só a documentação mudou |
| `test` | Você cria ou ajusta testes |
| `refactor` | Reorganiza o código sem mudar o comportamento |
| `style` | Formatação e indentação, sem mudar a lógica |
| `perf` | Melhora de desempenho |
| `build` | Mudança no Makefile, Stack/Cabal ou scripts de build |
| `ci` | Mudança nos workflows do GitHub Actions |
| `chore` | Manutenção geral, configs, dependências |
| `revert` | Desfaz um commit anterior |

### Escopos sugeridos

| Escopo | Cobre |
|---|---|
| `engine` | Código em C (janela, loop, render, input) |
| `rules` | Regras e pontuação em Haskell |
| `ui` | Menus, HUD e telas |
| `assets` | Sprites, sons e fontes |
| `repo` | Arquivos de configuração e organização do repositório |

### Exemplos

```
feat(ui): adiciona menu principal navegável
fix(rules): corrige Pontuação_Dia no cenário de empate
docs(repo): adiciona matriz RACI da squad
ci(repo): roda build automático a cada push
refactor(engine): separa o loop principal em funções menores
```

### Boas práticas

- Título com no máximo ~72 caracteres, no imperativo ("adiciona", não "adicionado").
- Sem ponto final no título.
- **Um commit, uma ideia.** Se a mensagem precisa de "e" para descrever, provavelmente são dois commits.
- Referencie a issue no rodapé quando existir (`Refs: #42` ou `Closes: #42`).

### Validação automática

Existe um hook `commit-msg` em `.githooks/` que bloqueia commits fora do padrão. Ative uma única vez após clonar:

```bash
git config core.hooksPath .githooks
```

Se o commit for recusado, releia o título: quase sempre o problema é o tipo ou os dois-pontos.

---

## 3. Pull Requests

### Antes de abrir

- [ ] O projeto compila sem erros nem warnings novos.
- [ ] Você rodou o jogo e testou o que mudou.
- [ ] Sua branch está atualizada com o `main`.
- [ ] Os commits seguem o padrão da seção 2.

### Ao abrir

1. Abra o PR da sua branch **para o `main`**.
2. O título segue o formato de commit, por exemplo: `feat(ui): adiciona menu principal navegável`.
3. Preencha a descrição com estes três pontos:
   - **O que mudou:** resumo direto da alteração.
   - **Como testar:** passo a passo para reproduzir.
   - **Fora do escopo:** o que você deixou de fazer de propósito.
4. Se for mudança visual, anexe um print ou GIF.
5. PR ainda em andamento? Abra como **Draft**.

### Revisão

- É necessária **1 aprovação** de outro integrante. Ninguém aprova o próprio PR.
- Quem revisa tenta responder em até **2 dias úteis**.
- Comentários são sobre o código, não sobre a pessoa. Prefira perguntas e sugestões a ordens.
- Quem abriu o PR resolve os comentários e avisa quando estiver pronto para nova revisão.

### Merge

- Usamos **Squash and merge**: o PR vira um único commit no `main`, e o título do PR vira a mensagem do commit (por isso ele precisa seguir o padrão).
- Quem abriu o PR faz o merge depois da aprovação e do build verde.
- Depois do merge, confirme que a branch foi apagada.

---

## 4. Dúvidas e problemas

- Encontrou um bug ou tem uma ideia? Abra uma **issue** descrevendo o que aconteceu, o que você esperava e como reproduzir.
- Não sabe por onde começar? Procure issues com o rótulo `good first issue` ou pergunte no canal da squad antes de começar a codar.
