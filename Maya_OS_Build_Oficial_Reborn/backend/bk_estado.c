#include "bk_estado.h"
#include "cJSON.h"

#include <math.h>
#include <string.h>

void bk_estado_inicial(bk_estado *e) {
    if (e == NULL) {
        return;
    }
    memset(e, 0, sizeof *e);
    e->schema_version = BK_SCHEMA_VERSION;
    (void)bk_copiar(e->status, sizeof e->status, "inicial");
    e->metricas.autonomia = BK_AUT_INICIAL;
    e->metricas.conformidade = BK_CON_INICIAL;
    e->metricas.dependencia = BK_DEP_INICIAL;
}

void bk_metricas_somar(bk_metricas *m, double d_aut, double d_con, double d_dep) {
    if (m == NULL) {
        return;
    }
    m->autonomia = bk_limitar(m->autonomia + d_aut, BK_METRICA_MIN, BK_METRICA_MAX);
    m->conformidade = bk_limitar(m->conformidade + d_con, BK_METRICA_MIN, BK_METRICA_MAX);
    m->dependencia = bk_limitar(m->dependencia + d_dep, BK_METRICA_MIN, BK_METRICA_MAX);
}

static bool metrica_ok(double v) {
    return isfinite(v) && v >= BK_METRICA_MIN && v <= BK_METRICA_MAX;
}

bk_status bk_estado_validar(const bk_estado *e, char *err, size_t cap) {
    if (e == NULL) {
        bk_err(err, cap, "estado nulo");
        return BK_ERR_ARG;
    }
    if (e->schema_version != BK_SCHEMA_VERSION) {
        bk_err(err, cap, "schema_version %d nao suportado (esperado %d)", e->schema_version, BK_SCHEMA_VERSION);
        return BK_ERR_ESQUEMA;
    }
    if (e->choice_id[0] != '\0' && !bk_id_valido(e->choice_id)) {
        bk_err(err, cap, "choice_id invalido");
        return BK_ERR_ESQUEMA;
    }
    if (!bk_status_texto_valido(e->status)) {
        bk_err(err, cap, "status invalido");
        return BK_ERR_ESQUEMA;
    }
    if (!metrica_ok(e->metricas.autonomia) || !metrica_ok(e->metricas.conformidade) || !metrica_ok(e->metricas.dependencia)) {
        bk_err(err, cap, "metrica fora do intervalo 0..100");
        return BK_ERR_ESQUEMA;
    }
    if (e->timestamp[0] != '\0' && !bk_timestamp_valido(e->timestamp)) {
        bk_err(err, cap, "timestamp invalido");
        return BK_ERR_ESQUEMA;
    }
    return BK_OK;
}

static double arredondar2(double v) {
    return round(v * 100.0) / 100.0;
}

bk_status bk_estado_serializar(const bk_estado *e, char **json, char *err, size_t cap) {
    if (json != NULL) {
        *json = NULL;
    }
    if (e == NULL || json == NULL) {
        bk_err(err, cap, "bk_estado_serializar: ponteiro nulo");
        return BK_ERR_ARG;
    }
    bk_status st = bk_estado_validar(e, err, cap);
    if (st != BK_OK) {
        return st;
    }
    cJSON *raiz = cJSON_CreateObject();
    cJSON *metricas = cJSON_CreateObject();
    char *texto = NULL;
    char *copia = NULL;
    if (raiz == NULL || metricas == NULL) {
        bk_err(err, cap, "sem memoria para montar o JSON");
        st = BK_ERR_MEM;
        goto fim;
    }
    if (cJSON_AddNumberToObject(metricas, "autonomia", arredondar2(e->metricas.autonomia)) == NULL ||
        cJSON_AddNumberToObject(metricas, "conformidade", arredondar2(e->metricas.conformidade)) == NULL ||
        cJSON_AddNumberToObject(metricas, "dependencia", arredondar2(e->metricas.dependencia)) == NULL) {
        bk_err(err, cap, "sem memoria para montar as metricas");
        st = BK_ERR_MEM;
        goto fim;
    }
    if (cJSON_AddNumberToObject(raiz, "schema_version", e->schema_version) == NULL ||
        cJSON_AddStringToObject(raiz, "choice_id", e->choice_id) == NULL ||
        cJSON_AddStringToObject(raiz, "status", e->status) == NULL) {
        bk_err(err, cap, "sem memoria para montar o JSON");
        st = BK_ERR_MEM;
        goto fim;
    }
    /* A posse de `metricas` passa para `raiz` quando o item é anexado com sucesso. */
    if (!cJSON_AddItemToObject(raiz, "metrics", metricas)) {
        bk_err(err, cap, "sem memoria para anexar as metricas");
        st = BK_ERR_MEM;
        goto fim;
    }
    metricas = NULL;
    if (cJSON_AddStringToObject(raiz, "timestamp", e->timestamp) == NULL || cJSON_AddBoolToObject(raiz, "is_placeholder", e->is_placeholder) == NULL) {
        bk_err(err, cap, "sem memoria para montar o JSON");
        st = BK_ERR_MEM;
        goto fim;
    }
    texto = cJSON_Print(raiz);
    if (texto == NULL) {
        bk_err(err, cap, "sem memoria para imprimir o JSON");
        st = BK_ERR_MEM;
        goto fim;
    }
    size_t n = strlen(texto);
    copia = (char *)bk_malloc(n + 2);
    if (copia == NULL) {
        bk_err(err, cap, "sem memoria para o resultado");
        st = BK_ERR_MEM;
        goto fim;
    }
    memcpy(copia, texto, n);
    copia[n] = '\n';
    copia[n + 1] = '\0';
    *json = copia;
    copia = NULL;
fim:
    cJSON_Delete(raiz);
    cJSON_Delete(metricas);
    if (texto != NULL) {
        cJSON_free(texto);
    }
    bk_free(copia);
    return st;
}

static bk_status numero_do_objeto(const cJSON *obj, const char *nome, double *out, char *err, size_t cap) {
    const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, nome);
    if (!cJSON_IsNumber(item) || !metrica_ok(item->valuedouble)) {
        bk_err(err, cap, "metrics.%s ausente, nao numerica ou fora de 0..100", nome);
        return BK_ERR_ESQUEMA;
    }
    *out = item->valuedouble;
    return BK_OK;
}

bk_status bk_estado_interpretar(const char *json, bk_estado *out, char *err, size_t cap) {
    if (json == NULL || out == NULL) {
        bk_err(err, cap, "bk_estado_interpretar: ponteiro nulo");
        return BK_ERR_ARG;
    }
    cJSON *raiz = cJSON_Parse(json);
    if (raiz == NULL) {
        /* cJSON devolve NULL tanto para sintaxe inválida quanto para falta de memória (nos dois casos registra um erro em
         * cJSON_GetErrorPtr), então a mensagem cobre as duas hipóteses. */
        const char *onde = cJSON_GetErrorPtr();
        long pos = (onde != NULL && onde >= json) ? (long)(onde - json) : 0L;
        bk_err(err, cap, "json malformado ou sem memoria para interpreta-lo (perto do byte %ld)", pos);
        return BK_ERR_JSON;
    }
    bk_status st = BK_OK;
    bk_estado novo;
    bk_estado_inicial(&novo);
    if (!cJSON_IsObject(raiz)) {
        bk_err(err, cap, "a raiz do JSON deve ser um objeto");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *versao = cJSON_GetObjectItemCaseSensitive(raiz, "schema_version");
    if (!cJSON_IsNumber(versao) || versao->valuedouble != (double)BK_SCHEMA_VERSION) {
        bk_err(err, cap, "schema_version ausente ou diferente de %d", BK_SCHEMA_VERSION);
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *escolha = cJSON_GetObjectItemCaseSensitive(raiz, "choice_id");
    if (!cJSON_IsString(escolha) || escolha->valuestring == NULL || !bk_copiar(novo.choice_id, sizeof novo.choice_id, escolha->valuestring)) {
        bk_err(err, cap, "choice_id ausente, nao textual ou longo demais");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *status = cJSON_GetObjectItemCaseSensitive(raiz, "status");
    if (!cJSON_IsString(status) || status->valuestring == NULL || !bk_copiar(novo.status, sizeof novo.status, status->valuestring)) {
        bk_err(err, cap, "status ausente, nao textual ou longo demais");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *metricas = cJSON_GetObjectItemCaseSensitive(raiz, "metrics");
    if (!cJSON_IsObject(metricas)) {
        bk_err(err, cap, "metrics ausente ou nao e um objeto");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    st = numero_do_objeto(metricas, "autonomia", &novo.metricas.autonomia, err, cap);
    if (st == BK_OK) {
        st = numero_do_objeto(metricas, "conformidade", &novo.metricas.conformidade, err, cap);
    }
    if (st == BK_OK) {
        st = numero_do_objeto(metricas, "dependencia", &novo.metricas.dependencia, err, cap);
    }
    if (st != BK_OK) {
        goto fim;
    }
    const cJSON *carimbo = cJSON_GetObjectItemCaseSensitive(raiz, "timestamp");
    if (!cJSON_IsString(carimbo) || carimbo->valuestring == NULL || !bk_copiar(novo.timestamp, sizeof novo.timestamp, carimbo->valuestring)) {
        bk_err(err, cap, "timestamp ausente, nao textual ou longo demais");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *provisorio = cJSON_GetObjectItemCaseSensitive(raiz, "is_placeholder");
    if (!cJSON_IsBool(provisorio)) {
        bk_err(err, cap, "is_placeholder ausente ou nao booleano");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    novo.is_placeholder = cJSON_IsTrue(provisorio);
    st = bk_estado_validar(&novo, err, cap);
    if (st == BK_OK) {
        *out = novo;
    }
fim:
    cJSON_Delete(raiz);
    return st;
}

bk_status bk_estado_gravar(const char *caminho, const bk_estado *e, char *err, size_t cap) {
    char *json = NULL;
    bk_status st = bk_estado_serializar(e, &json, err, cap);
    if (st != BK_OK) {
        return st;
    }
    st = bk_gravar_atomico(caminho, json, strlen(json), err, cap);
    bk_free(json);
    return st;
}

bk_status bk_estado_ler(const char *caminho, bk_estado *out, char *err, size_t cap) {
    char *buf = NULL;
    size_t n = 0;
    bk_status st = bk_ler_arquivo(caminho, &buf, &n, err, cap);
    if (st != BK_OK) {
        return st;
    }
    st = bk_estado_interpretar(buf, out, err, cap);
    bk_free(buf);
    return st;
}
