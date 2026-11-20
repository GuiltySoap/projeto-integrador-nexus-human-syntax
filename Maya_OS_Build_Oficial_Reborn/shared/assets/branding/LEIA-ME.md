# Logos da marca (§22)

O registro de logos fica em `core/utilities/marca.gd` (classe `Marca`): é o único lugar que conhece os caminhos. As telas pedem a marca por id
através do componente `LogoMarca` (`shared/ui/logo_marca/`) e, se o arquivo faltar, mostram o nome em texto (nunca ficam vazias).

| Id | Arquivo | Estado |
|---|---|---|
| `maya_marca` | `shared/assets/textures/logo_maya_neon.png` | oficial, RGBA com fundo recortado (Menu Principal) |
| `maya_completa` | `features/splash_screen/assets/mayaos_intro_logo.png` | oficial, RGB sobre fundo preto (Splash e Créditos) |
| `icone_jogo` | `shared/assets/icons/icone_maya.png` | ícone do jogo e do projeto (256x256, cantos transparentes) |
| `humaxos` | `shared/assets/branding/humaxos_logo.png` (ou `.svg`, `.webp`) | **PENDENTE: o arquivo oficial ainda não foi fornecido** |

## Como ativar o logo do HumaxOS

1. Coloque o arquivo oficial nesta pasta com o nome `humaxos_logo.png` (ou `.svg` / `.webp`).
   Pede-se PNG com **fundo transparente de verdade** (os cantos precisam ter alfa 0), ao menos 32 px de lado e proporção entre 1:4 e 4:1.
2. Abra o projeto no editor da Godot (a importação cria o `.import`).
3. Rode `tests/sistemas_novos/sistemas_novos.tscn`: o módulo "Marca visual" passa a **exigir** que o arquivo seja um logo válido
   (`Marca.validar("humaxos")`: tamanho, proporção e transparência). Nenhuma cena nem script precisa mudar.

Enquanto o arquivo não existir, a tela de registro (TelaBoot) e a barra de tarefas mostram "HumaxOS" em texto, e o teste registra a
pendência como informação (não como falha).
