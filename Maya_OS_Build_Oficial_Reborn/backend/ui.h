#ifndef UI_H
#define UI_H
/* Entrada e saída do modo interativo. Nada aqui chama o shell (nada de system()); toda leitura trata EOF. */
#include "bk_common.h"
#include "game.h"

/* Limpa a tela com sequências ANSI (só quando a saída é um terminal). */
void limpar_tela(void);
/* Espera ENTER. Devolve false se a entrada acabou (EOF) ou deu erro. */
bool esperar_enter(void);
void exibir_cabecalho_ato(const char *act_title);
void exibir_cabecalho_dia(const char *scene_title, int autonomia);
/* Lê uma linha (descartando o excesso). Devolve false em EOF/erro. */
bool ui_ler_linha(char *buf, size_t cap);
/* Lê um inteiro em [min, max]. Devolve BK_OK, BK_ERR_ARG (linha que não é número no intervalo) ou BK_ERR_IO (fim da entrada). */
bk_status ui_ler_inteiro(int min, int max, int *out);
/* Executa um turno. Devolve BK_ERR_IO se a entrada acabou no meio dele. `jogo` e `turno` não podem ser nulos. */
bk_status executar_turno(GameState *jogo, const Turn *turno);

#endif
