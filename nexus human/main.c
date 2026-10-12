#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "cJSON.h"

#define MAX_MESSAGES 20
#define MAX_CHOICES 5

typedef struct {
    int id;
    char timestamp[10];
    char sender[32];
    char text[512];
} Message;

typedef struct {
    int id;
    char text[256];
    int autonomy_impact;
    bool delegated;
    char nexus_reply[256];
} Choice;

typedef struct {
    Message messages[MAX_MESSAGES];
    int message_count;
    Choice choices[MAX_CHOICES];
    int choice_count;
} Turn;

typedef struct {
    int autonomia;
    int current_act;
    int current_day;
    char scene_title[128];
    char act_title[128];
} GameState;

GameState game;

void esperar_enter() {
    printf("\n[Pressione ENTER para continuar...]");
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
}

void limpar_tela() {
    #ifdef _WIN32
        system("cls");
    #else
        system("clear");
    #endif
}

char* read_file_to_string(const char* filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        printf("Erro ao abrir %s\n", filename);
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

void executar_turno(Turn *turn) {
    for (int i = 0; i < turn->message_count; i++) {
        printf("[%s] %s: %s\n", 
            turn->messages[i].timestamp, 
            turn->messages[i].sender, 
            turn->messages[i].text);
        esperar_enter();
    }

    int opcao = 0;
    bool escolha_valida = false;

    while (!escolha_valida) {
        printf("\n--- OPÇÕES DE RESPOSTA / DECISÃO ---\n");
        for (int i = 0; i < turn->choice_count; i++) {
            printf("%d) \"%s\"\n", turn->choices[i].id, turn->choices[i].text);
        }
        
        printf("\nDigite o numero da sua escolha: ");
        if (scanf("%d", &opcao) != 1) {
            while(getchar() != '\n'); 
            continue;
        }

        for (int i = 0; i < turn->choice_count; i++) {
            if (turn->choices[i].id == opcao) {
                escolha_valida = true;
                
                game.autonomia += turn->choices[i].autonomy_impact;
                if (game.autonomia < 0) game.autonomia = 0;
                if (game.autonomia > 100) game.autonomia = 100;

                while(getchar() != '\n');
                
                if (turn->choices[i].delegated) {
                    printf("\n[SISTEMA]: Acao delegada ao NEXUS. (-Autonomia / +Conveniencia)\n");
                } else {
                    printf("\n[SISTEMA]: Acao mantida sob controlo manual do utilizador.\n");
                }
                esperar_enter();

                printf("\n[NEXUS]: %s\n", turn->choices[i].nexus_reply);
                esperar_enter();
                break;
            }
        }
        
        if (!escolha_valida) {
            printf("Opcao invalida. Digite o numero de uma das opcoes acima.\n");
        }
    }
}

void executar_jogo(const char* json_filename) {
    char *json_data = read_file_to_string(json_filename);
    if (!json_data) return;

    cJSON *root = cJSON_Parse(json_data);
    if (!root) {
        printf("Erro ao processar JSON!\n");
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

        // Anúncio de transição de Ato
        if (act_num != game.current_act) {
            game.current_act = act_num;
            limpar_tela();
            printf("==================================================\n");
            printf("                 %s                   \n", act_title);
            printf("==================================================\n");
            printf("\n> O Ato I foi concluido. A iniciar uma nova fase do sistema...\n");
            esperar_enter();
        }

        game.current_day = day_num;
        strcpy(game.scene_title, scene_title);

        limpar_tela();
        printf("==================================================\n");
        printf("  %s  |  AUTONOMIA: %d%%\n", game.scene_title, game.autonomia);
        printf("==================================================\n\n");
        esperar_enter();

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

int main(void) {
    game.autonomia = 100;
    game.current_act = 0;
    game.current_day = 0;

    executar_jogo("dialogues.json");

    limpar_tela();
    printf("==================================================\n");
    printf("            FIM DA DEMONSTRAÇÃO DO JOGO           \n");
    printf("==================================================\n\n");
    printf("Autonomia Final do Utilizador: %d%%\n", game.autonomia);
    esperar_enter();

    return 0;
}