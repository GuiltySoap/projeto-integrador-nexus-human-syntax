#ifndef BK_ESTADO_H
#define BK_ESTADO_H
/*
 * Estado do jogo devolvido pelo backend: estado_jogo.json.
 *
 *   {
 *     "schema_version": 1,
 *     "choice_id": "choice_fixed_01",   // "" enquanto nenhuma escolha foi aplicada
 *     "status": "ok",                   // [a-z_]{1,32}
 *     "metrics": { "autonomia": 50, "conformidade": 50, "dependencia": 0 },   // 0..100
 *     "timestamp": "2026-11-17T21:00:00Z",
 *     "is_placeholder": true            // a escolha aplicada ainda usa texto/narrativa provisórios
 *   }
 *
 * O Godot lê e grava o MESMO formato (core/utilities/estado_jogo_backend.gd). Campos desconhecidos são ignorados na leitura
 * (compatibilidade futura) e não são preservados na regravação.
 */
#include "bk_common.h"

#define BK_SCHEMA_VERSION 1
#define BK_AUT_INICIAL 50.0
#define BK_CON_INICIAL 50.0
#define BK_DEP_INICIAL 0.0

typedef struct {
    double autonomia;
    double conformidade;
    double dependencia;
} bk_metricas;

typedef struct {
    int schema_version;
    char choice_id[BK_ID_MAX + 1];
    char status[BK_STATUS_MAX + 1];
    bk_metricas metricas;
    char timestamp[BK_TIMESTAMP_MAX];
    bool is_placeholder;
} bk_estado;

/* Estado inicial: métricas iniciais, status "inicial", sem escolha. `timestamp` fica vazio até a primeira gravação. */
void bk_estado_inicial(bk_estado *e);

/* Soma os deltas e limita cada métrica a [0, 100]. */
void bk_metricas_somar(bk_metricas *m, double d_aut, double d_con, double d_dep);

bk_status bk_estado_validar(const bk_estado *e, char *err, size_t cap);

/* Serializa em JSON (UTF-8, com quebra de linha final). *json passa a ser do chamador: libere com bk_free(). */
bk_status bk_estado_serializar(const bk_estado *e, char **json, char *err, size_t cap);

/* Interpreta e valida um JSON. `out` só é alterado se tudo estiver certo. */
bk_status bk_estado_interpretar(const char *json, bk_estado *out, char *err, size_t cap);

/* Grava de forma atômica (veja bk_gravar_atomico). Valida antes de gravar: nunca escreve um estado fora do esquema. */
bk_status bk_estado_gravar(const char *caminho, const bk_estado *e, char *err, size_t cap);

/* Lê e valida o arquivo. */
bk_status bk_estado_ler(const char *caminho, bk_estado *out, char *err, size_t cap);

#endif
