#ifndef BK_CATALOGO_H
#define BK_CATALOGO_H
/*
 * Catálogo de escolhas (choices.json): quanto cada escolha mexe em AUT/CON/DEP. É o espelho, para o backend, dos deltas que o
 * jogo guarda em core/data/narrativa/conversas.json (campo "metricas" de cada escolha); tools/testar_backend.py confere que os dois
 * lados não se afastam.
 *
 *   { "schema_version": 1,
 *     "choices": [ { "id": "choice_fixed_01", "status": "ok", "autonomia": 0, "conformidade": 0, "dependencia": 0,
 *                    "is_placeholder": true } ] }
 *
 * "status", os deltas e "is_placeholder" são opcionais (padrões: "ok", 0, false). Deltas ficam em [-100, 100].
 */
#include "bk_common.h"

#define BK_CATALOGO_MAX 128

typedef struct {
    char id[BK_ID_MAX + 1];
    char status[BK_STATUS_MAX + 1];
    double d_autonomia;
    double d_conformidade;
    double d_dependencia;
    bool is_placeholder;
} bk_escolha;

typedef struct {
    bk_escolha itens[BK_CATALOGO_MAX];
    size_t n;
} bk_catalogo;

/* `cat` só é alterado se tudo estiver certo. Mais de BK_CATALOGO_MAX escolhas ou IDs repetidos são recusados. */
bk_status bk_catalogo_interpretar(const char *json, bk_catalogo *cat, char *err, size_t cap);
bk_status bk_catalogo_carregar(const char *caminho, bk_catalogo *cat, char *err, size_t cap);

/* Devolve um ponteiro para dentro de `cat` (não liberar) ou NULL se o ID não existir ou algum argumento for nulo. */
const bk_escolha *bk_catalogo_buscar(const bk_catalogo *cat, const char *id);

#endif
