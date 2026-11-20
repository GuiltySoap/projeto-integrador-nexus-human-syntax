#ifndef BK_COMANDO_H
#define BK_COMANDO_H
/* Modo não interativo: `--choice <id>`. Fica fora de main() para os testes nativos poderem chamá-lo direto. */
#include "bk_args.h"
#include "bk_estado.h"

/* Aplica a escolha `args->escolha` ao estado gravado (ou ao estado inicial, com --reset ou sem arquivo) e grava estado_jogo.json.
 * Passos: valida os argumentos -> carrega o catálogo -> procura o ID (desconhecido = BK_ERR_ID_DESCONHECIDO) -> lê o estado anterior
 * (arquivo existente mas inválido = erro, nunca sobrescrito em silêncio) -> aplica os deltas com limites -> grava de forma atômica.
 * `resultado` e `saida_usada` (caminho gravado) são opcionais (podem ser NULL). Nada é executado no shell. */
bk_status bk_comando_escolha(const bk_args *args, bk_estado *resultado, char *saida_usada, size_t cap_saida, char *err, size_t cap);

/* Caminho do estado: --out, senão $MAYA_USER_DIR/estado_jogo.json, senão ./estado_jogo.json. */
bk_status bk_caminho_do_estado(const bk_args *args, char *out, size_t cap, char *err, size_t errcap);

/* O arquivo existe e pode ser aberto para leitura? */
bool bk_arquivo_existe(const char *caminho);

#endif
