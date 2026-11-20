#include "json_loader.h"
#include "cJSON.h"
#include "ui.h"

#include <limits.h>
#include <math.h>
#include <string.h>

static bk_status campo_texto(const cJSON *obj, const char *nome, char *dst, size_t cap, char *err, size_t errcap) {
    const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, nome);
    if (!cJSON_IsString(item) || item->valuestring == NULL) {
        bk_err(err, errcap, "campo '%s' ausente ou nao textual", nome);
        return BK_ERR_ESQUEMA;
    }
    if (!bk_copiar(dst, cap, item->valuestring)) {
        bk_err(err, errcap, "campo '%s' tem %zu bytes (limite %zu)", nome, strlen(item->valuestring), cap - 1);
        return BK_ERR_LIMITE;
    }
    return BK_OK;
}

static bk_status campo_inteiro(const cJSON *obj, const char *nome, int *dst, char *err, size_t errcap) {
    const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, nome);
    if (!cJSON_IsNumber(item) || !isfinite(item->valuedouble) || item->valuedouble != floor(item->valuedouble) ||
        item->valuedouble < (double)INT_MIN || item->valuedouble > (double)INT_MAX) {
        bk_err(err, errcap, "campo '%s' ausente ou nao e um inteiro", nome);
        return BK_ERR_ESQUEMA;
    }
    *dst = (int)item->valuedouble;
    return BK_OK;
}

/* "delegated" aparece como 0/1 em roteiros antigos e como true/false nos novos. */
static bk_status campo_booleano(const cJSON *obj, const char *nome, bool *dst, char *err, size_t errcap) {
    const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, nome);
    if (cJSON_IsBool(item)) {
        *dst = cJSON_IsTrue(item);
        return BK_OK;
    }
    if (cJSON_IsNumber(item) && (item->valuedouble == 0.0 || item->valuedouble == 1.0)) {
        *dst = item->valuedouble == 1.0;
        return BK_OK;
    }
    bk_err(err, errcap, "campo '%s' ausente ou nao booleano", nome);
    return BK_ERR_ESQUEMA;
}

bk_status carregar_turno(const struct cJSON *turno_json, Turn *out, char *err, size_t cap) {
    if (turno_json == NULL || out == NULL) {
        bk_err(err, cap, "carregar_turno: ponteiro nulo");
        return BK_ERR_ARG;
    }
    memset(out, 0, sizeof *out);
    const cJSON *msgs = cJSON_GetObjectItemCaseSensitive(turno_json, "messages");
    if (!cJSON_IsArray(msgs)) {
        bk_err(err, cap, "turno sem lista 'messages'");
        return BK_ERR_ESQUEMA;
    }
    if (cJSON_GetArraySize(msgs) > MAX_MESSAGES) {
        bk_err(err, cap, "turno com %d mensagens (limite %d)", cJSON_GetArraySize(msgs), MAX_MESSAGES);
        return BK_ERR_LIMITE;
    }
    const cJSON *m_item = NULL;
    cJSON_ArrayForEach(m_item, msgs) {
        Message *m = &out->messages[out->message_count];
        bk_status st = campo_inteiro(m_item, "id", &m->id, err, cap);
        if (st == BK_OK) {
            st = campo_texto(m_item, "timestamp", m->timestamp, sizeof m->timestamp, err, cap);
        }
        if (st == BK_OK) {
            st = campo_texto(m_item, "sender", m->sender, sizeof m->sender, err, cap);
        }
        if (st == BK_OK) {
            st = campo_texto(m_item, "text", m->text, sizeof m->text, err, cap);
        }
        if (st != BK_OK) {
            return st;
        }
        out->message_count++;
    }
    const cJSON *choices = cJSON_GetObjectItemCaseSensitive(turno_json, "choices");
    if (!cJSON_IsArray(choices)) {
        bk_err(err, cap, "turno sem lista 'choices'");
        return BK_ERR_ESQUEMA;
    }
    if (cJSON_GetArraySize(choices) > MAX_CHOICES) {
        bk_err(err, cap, "turno com %d escolhas (limite %d)", cJSON_GetArraySize(choices), MAX_CHOICES);
        return BK_ERR_LIMITE;
    }
    const cJSON *c_item = NULL;
    cJSON_ArrayForEach(c_item, choices) {
        Choice *c = &out->choices[out->choice_count];
        bk_status st = campo_inteiro(c_item, "choice_id", &c->id, err, cap);
        if (st == BK_OK) {
            st = campo_texto(c_item, "text", c->text, sizeof c->text, err, cap);
        }
        if (st == BK_OK) {
            st = campo_inteiro(c_item, "autonomy_impact", &c->autonomy_impact, err, cap);
        }
        if (st == BK_OK) {
            st = campo_booleano(c_item, "delegated", &c->delegated, err, cap);
        }
        if (st == BK_OK) {
            st = campo_texto(c_item, "nexus_reply", c->nexus_reply, sizeof c->nexus_reply, err, cap);
        }
        if (st != BK_OK) {
            return st;
        }
        out->choice_count++;
    }
    return BK_OK;
}

bk_status executar_jogo(const char *json_filename, GameState *jogo, char *err, size_t cap) {
    if (json_filename == NULL || jogo == NULL) {
        bk_err(err, cap, "executar_jogo: ponteiro nulo");
        return BK_ERR_ARG;
    }
    char *json_data = NULL;
    size_t tamanho = 0;
    bk_status st = bk_ler_arquivo(json_filename, &json_data, &tamanho, err, cap);
    if (st != BK_OK) {
        return st;
    }
    cJSON *root = cJSON_Parse(json_data);
    bk_free(json_data);
    if (root == NULL) {
        bk_err(err, cap, "sintaxe invalida em '%s' (ou sem memoria)", json_filename);
        return BK_ERR_JSON;
    }
    const cJSON *days = cJSON_GetObjectItemCaseSensitive(root, "days");
    if (!cJSON_IsArray(days)) {
        if (cJSON_GetObjectItemCaseSensitive(root, "acts") != NULL) {
            bk_err(err, cap, "'%s' esta no formato acts/nodes (roteiro v4), que o modo interativo nao le; ele espera days/turns", json_filename);
        } else {
            bk_err(err, cap, "'%s' nao tem a lista 'days'", json_filename);
        }
        st = BK_ERR_ESQUEMA;
        goto fim;
    }
    const cJSON *day_item = NULL;
    cJSON_ArrayForEach(day_item, days) {
        int day_num = 0;
        int act_num = 0;
        char act_title[sizeof jogo->act_title];
        char scene_title[sizeof jogo->scene_title];
        st = campo_inteiro(day_item, "day_number", &day_num, err, cap);
        if (st == BK_OK) {
            st = campo_inteiro(day_item, "act", &act_num, err, cap);
        }
        if (st == BK_OK) {
            st = campo_texto(day_item, "act_title", act_title, sizeof act_title, err, cap);
        }
        if (st == BK_OK) {
            st = campo_texto(day_item, "scene_title", scene_title, sizeof scene_title, err, cap);
        }
        if (st != BK_OK) {
            goto fim;
        }
        if (act_num != jogo->current_act) {
            jogo->current_act = act_num;
            (void)bk_copiar(jogo->act_title, sizeof jogo->act_title, act_title);
            exibir_cabecalho_ato(jogo->act_title);
        }
        jogo->current_day = day_num;
        (void)bk_copiar(jogo->scene_title, sizeof jogo->scene_title, scene_title);
        exibir_cabecalho_dia(jogo->scene_title, jogo->autonomia);
        const cJSON *turns = cJSON_GetObjectItemCaseSensitive(day_item, "turns");
        if (!cJSON_IsArray(turns)) {
            bk_err(err, cap, "dia %d sem lista 'turns'", day_num);
            st = BK_ERR_ESQUEMA;
            goto fim;
        }
        const cJSON *turn_item = NULL;
        cJSON_ArrayForEach(turn_item, turns) {
            Turn turno;
            st = carregar_turno(turn_item, &turno, err, cap);
            if (st != BK_OK) {
                goto fim;
            }
            st = executar_turno(jogo, &turno);
            if (st != BK_OK) {
                bk_err(err, cap, "a entrada terminou no meio do jogo");
                goto fim;
            }
            limpar_tela();
        }
    }
fim:
    cJSON_Delete(root);
    return st;
}
