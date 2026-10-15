#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "json_loader.h"
#include "game.h"
#include "ui.h"
#include "cJSON.h"

static char* read_file_to_string(const char* filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        printf("[ERRO - FILE]: Nao foi possivel abrir %s\n", filename);
        return NULL;
    }
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
    char *buffer = (char*)malloc(length + 1);
    if (buffer) {
        fread(buffer, 1, length, file);
        buffer[length] = '\0';
    }
    fclose(file);
    return buffer;
}

void executar_jogo(const char* json_filename) {
    char *json_data = read_file_to_string(json_filename);
    if (!json_data) return;

    cJSON *root = cJSON_Parse(json_data);
    if (!root) {
        printf("[ERRO - cJSON]: Sintaxe invalida no JSON!\n");
        free(json_data);
        return;
    }

    cJSON *days = cJSON_GetObjectItem(root, "days");
    cJSON *day_item = NULL;

    cJSON_ArrayForEach(day_item, days) {
        int day_num = cJSON_GetObjectItem(day_item, "day_number")->valueint;
        int act_num = cJSON_GetObjectItem(day_item, "act")->valueint;
        char *act_title = cJSON_GetObjectItem(day_item, "act_title")->valuestring;
        char *scene_title = cJSON_GetObjectItem(day_item, "scene_title")->valuestring;

        if (act_num != game.current_act) {
            game.current_act = act_num;
            exibir_cabecalho_ato(act_title);
        }

        game.current_day = day_num;
        strcpy(game.scene_title, scene_title);

        exibir_cabecalho_dia(game.scene_title, game.autonomia);

        cJSON *turns = cJSON_GetObjectItem(day_item, "turns");
        cJSON *turn_item = NULL;

        cJSON_ArrayForEach(turn_item, turns) {
            Turn current_turn;
            current_turn.message_count = 0;
            current_turn.choice_count = 0;

            cJSON *msgs = cJSON_GetObjectItem(turn_item, "messages");
            cJSON *m_item = NULL;
            cJSON_ArrayForEach(m_item, msgs) {
                Message *m = &current_turn.messages[current_turn.message_count];
                m->id = cJSON_GetObjectItem(m_item, "id")->valueint;
                strcpy(m->timestamp, cJSON_GetObjectItem(m_item, "timestamp")->valuestring);
                strcpy(m->sender, cJSON_GetObjectItem(m_item, "sender")->valuestring);
                strcpy(m->text, cJSON_GetObjectItem(m_item, "text")->valuestring);
                current_turn.message_count++;
            }

            cJSON *choices = cJSON_GetObjectItem(turn_item, "choices");
            cJSON *c_item = NULL;
            cJSON_ArrayForEach(c_item, choices) {
                Choice *c = &current_turn.choices[current_turn.choice_count];
                c->id = cJSON_GetObjectItem(c_item, "choice_id")->valueint;
                strcpy(c->text, cJSON_GetObjectItem(c_item, "text")->valuestring);
                c->autonomy_impact = cJSON_GetObjectItem(c_item, "autonomy_impact")->valueint;
                c->delegated = cJSON_GetObjectItem(c_item, "delegated")->valueint;
                strcpy(c->nexus_reply, cJSON_GetObjectItem(c_item, "nexus_reply")->valuestring);
                current_turn.choice_count++;
            }

            executar_turno(&current_turn);
            limpar_tela();
        }
    }

    cJSON_Delete(root);
    free(json_data);
}
