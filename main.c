#include <stdio.h>
#include <stdlib.h>
#include "cJSON.h"

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Erro: ID da escolha nao fornecido.\n");
        return 1;
    }

    int escolha_jogador = atoi(argv[1]);

    // Valores padrao caso o jogo esteja comecando agora
    int aut = 50;
    int con = 20;
    int dep = 10;
    int fase_os = 1;

    // 1. TENTA LER O ESTADO ATUAL DO JSON
    FILE *f_in = fopen("estado_jogo.json", "r");
    if (f_in != NULL) {
        fseek(f_in, 0, SEEK_END);
        long len = ftell(f_in);
        fseek(f_in, 0, SEEK_SET);

        if (len > 0) {
            char *data = (char *)malloc(len + 1);
            fread(data, 1, len, f_in);
            data[len] = '\0';

            cJSON *existing = cJSON_Parse(data);
            if (existing != NULL) {
                cJSON *metricas = cJSON_GetObjectItemCaseSensitive(existing, "metricas");
                if (metricas != NULL) {
                    cJSON *j_aut = cJSON_GetObjectItemCaseSensitive(metricas, "autonomia");
                    cJSON *j_con = cJSON_GetObjectItemCaseSensitive(metricas, "conveniencia");
                    cJSON *j_dep = cJSON_GetObjectItemCaseSensitive(metricas, "dependencia");

                    if (cJSON_IsNumber(j_aut)) aut = j_aut->valueint;
                    if (cJSON_IsNumber(j_con)) con = j_con->valueint;
                    if (cJSON_IsNumber(j_dep)) dep = j_dep->valueint;
                }
                cJSON_Delete(existing);
            }
            free(data);
        }
        fclose(f_in);
    }

    // 2. APLICA A LOGICA DA ESCOLHA SOBRE OS VALORES ANTERIORES
    if (escolha_jogador == 3) { // Conceder Acesso à Nex
        dep += 15;
        aut -= 5;
        con += 10;
    } else if (escolha_jogador == 1) { // Recusar Acesso
        dep -= 10;
        aut += 10;
        con -= 5;
    }

    // Trava as metricas entre 0 e 100
    if (dep < 0) dep = 0; if (dep > 100) dep = 100;
    if (aut < 0) aut = 0; if (aut > 100) aut = 100;
    if (con < 0) con = 0; if (con > 100) con = 100;

    // 3. CALCULA A FASE DO SISTEMA OPERACIONAL
    if (dep >= 50) {
        fase_os = 3;
    } else if (dep >= 25) {
        fase_os = 2;
    } else {
        fase_os = 1;
    }

    char *mensagem;
    if (fase_os == 3) {
        mensagem = "ALERTA: Nex reescrevendo permissoes do Kernel...";
    } else if (fase_os == 2) {
        mensagem = "AVISO: Sistema apresentando instabilidades leves.";
    } else {
        mensagem = "Sistema operando normalmente.";
    }

    // 4. GRAVA O NOVO JSON
    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "fase_os", fase_os);
    cJSON_AddStringToObject(root, "mensagem_nex", mensagem);
    cJSON_AddBoolToObject(root, "bloquear_botao_cancelar", (fase_os >= 3));

    cJSON *metricas_novas = cJSON_CreateObject();
    cJSON_AddNumberToObject(metricas_novas, "autonomia", aut);
    cJSON_AddNumberToObject(metricas_novas, "conveniencia", con);
    cJSON_AddNumberToObject(metricas_novas, "dependencia", dep);
    cJSON_AddItemToObject(root, "metricas", metricas_novas);

    FILE *f_out = fopen("estado_jogo.json", "w");
    if (f_out != NULL) {
        char *json_string = cJSON_Print(root);
        fprintf(f_out, "%s\n", json_string);
        fclose(f_out);
        free(json_string);
    }

    cJSON_Delete(root);
    printf("Estado persistido! DEP: %d, AUT: %d, CON: %d\n", dep, aut, con);
    return 0;
}