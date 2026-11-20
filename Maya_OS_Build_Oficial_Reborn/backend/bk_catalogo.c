#include "bk_catalogo.h"
#include "cJSON.h"

#include <math.h>
#include <string.h>

static bk_status delta_do_objeto(const cJSON *obj, const char *nome, double *out, size_t indice, char *err, size_t cap) {
    const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, nome);
    if (item == NULL) {
        *out = 0.0;
        return BK_OK;
    }
    if (!cJSON_IsNumber(item) || !isfinite(item->valuedouble) || item->valuedouble < -100.0 || item->valuedouble > 100.0) {
        bk_err(err, cap, "choices[%zu].%s deve ser numero entre -100 e 100", indice, nome);
        return BK_ERR_ESQUEMA;
    }
    *out = item->valuedouble;
    return BK_OK;
}

bk_status bk_catalogo_interpretar(const char *json, bk_catalogo *cat, char *err, size_t cap) {
    if (json == NULL || cat == NULL) {
        bk_err(err, cap, "bk_catalogo_interpretar: ponteiro nulo");
        return BK_ERR_ARG;
    }
    cJSON *raiz = cJSON_Parse(json);
    if (raiz == NULL) {
        const char *onde = cJSON_GetErrorPtr();
        long pos = (onde != NULL && onde >= json) ? (long)(onde - json) : 0L;
        bk_err(err, cap, "catalogo: json malformado ou sem memoria (perto do byte %ld)", pos);
        return BK_ERR_JSON;
    }
    bk_status st = BK_OK;
    bk_catalogo novo;
    memset(&novo, 0, sizeof novo);
    if (!cJSON_IsObject(raiz)) {
        bk_err(err, cap, "catalogo: a raiz deve ser um objeto");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *versao = cJSON_GetObjectItemCaseSensitive(raiz, "schema_version");
    if (!cJSON_IsNumber(versao) || versao->valuedouble != 1.0) {
        bk_err(err, cap, "catalogo: schema_version ausente ou diferente de 1");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *lista = cJSON_GetObjectItemCaseSensitive(raiz, "choices");
    if (!cJSON_IsArray(lista)) {
        bk_err(err, cap, "catalogo: 'choices' ausente ou nao e uma lista");
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    size_t quantidade = (size_t)cJSON_GetArraySize(lista);
    if (quantidade > BK_CATALOGO_MAX) {
        bk_err(err, cap, "catalogo: %zu escolhas (limite %d)", quantidade, BK_CATALOGO_MAX);
        st = BK_ERR_LIMITE;
        goto fim;
    }
    const cJSON *item = NULL;
    size_t i = 0;
    cJSON_ArrayForEach(item, lista) {
        if (!cJSON_IsObject(item)) {
            bk_err(err, cap, "catalogo: choices[%zu] nao e um objeto", i);
            st = BK_ERR_ESQUEMA;
            goto fim;
        }
        bk_escolha *e = &novo.itens[i];
        const cJSON *id = cJSON_GetObjectItemCaseSensitive(item, "id");
        if (!cJSON_IsString(id) || !bk_id_valido(id->valuestring)) {
            bk_err(err, cap, "catalogo: choices[%zu].id ausente ou com formato invalido", i);
            st = BK_ERR_ESQUEMA;
            goto fim;
        }
        (void)bk_copiar(e->id, sizeof e->id, id->valuestring);
        for (size_t j = 0; j < i; j++) {
            if (strcmp(novo.itens[j].id, e->id) == 0) {
                bk_err(err, cap, "catalogo: id repetido em choices[%zu]", i);
                st = BK_ERR_ESQUEMA;
                goto fim;
            }
        }
        const cJSON *status = cJSON_GetObjectItemCaseSensitive(item, "status");
        if (status == NULL) {
            (void)bk_copiar(e->status, sizeof e->status, "ok");
        } else if (!cJSON_IsString(status) || !bk_status_texto_valido(status->valuestring) || !bk_copiar(e->status, sizeof e->status, status->valuestring)) {
            bk_err(err, cap, "catalogo: choices[%zu].status invalido", i);
            st = BK_ERR_ESQUEMA;
            goto fim;
        }
        st = delta_do_objeto(item, "autonomia", &e->d_autonomia, i, err, cap);
        if (st == BK_OK) {
            st = delta_do_objeto(item, "conformidade", &e->d_conformidade, i, err, cap);
        }
        if (st == BK_OK) {
            st = delta_do_objeto(item, "dependencia", &e->d_dependencia, i, err, cap);
        }
        if (st != BK_OK) {
            goto fim;
        }
        const cJSON *provisorio = cJSON_GetObjectItemCaseSensitive(item, "is_placeholder");
        if (provisorio != NULL && !cJSON_IsBool(provisorio)) {
            bk_err(err, cap, "catalogo: choices[%zu].is_placeholder nao e booleano", i);
            st = BK_ERR_ESQUEMA;
            goto fim;
        }
        e->is_placeholder = provisorio != NULL && cJSON_IsTrue(provisorio);
        i++;
    }
    novo.n = i;
    *cat = novo;
fim:
    cJSON_Delete(raiz);
    return st;
}

bk_status bk_catalogo_carregar(const char *caminho, bk_catalogo *cat, char *err, size_t cap) {
    char *buf = NULL;
    size_t n = 0;
    bk_status st = bk_ler_arquivo(caminho, &buf, &n, err, cap);
    if (st != BK_OK) {
        return st;
    }
    st = bk_catalogo_interpretar(buf, cat, err, cap);
    bk_free(buf);
    return st;
}

const bk_escolha *bk_catalogo_buscar(const bk_catalogo *cat, const char *id) {
    if (cat == NULL || id == NULL) {
        return NULL;
    }
    for (size_t i = 0; i < cat->n && i < BK_CATALOGO_MAX; i++) {
        if (strcmp(cat->itens[i].id, id) == 0) {
            return &cat->itens[i];
        }
    }
    return NULL;
}
