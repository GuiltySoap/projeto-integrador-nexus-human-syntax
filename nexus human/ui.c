#include <stdio.h>
#include <stdlib.h>
#include "ui.h"

void esperar_enter(void) {
    printf("\n[Pressione ENTER para continuar...]");
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
}

void limpar_tela(void) {
    #ifdef _WIN32
        system("cls");
    #else
        system("clear");
    #endif
}

void exibir_cabecalho_ato(const char* act_title) {
    limpar_tela();
    printf("==================================================\n");
    printf("                 %s                   \n", act_title);
    printf("==================================================\n");
    printf("\n> Transicao de fase do sistema em curso...\n");
    esperar_enter();
}

void exibir_cabecalho_dia(const char* scene_title, int autonomia) {
    limpar_tela();
    printf("==================================================\n");
    printf("  %s  |  AUTONOMIA: %d%%\n", scene_title, autonomia);
    printf("==================================================\n\n");
    esperar_enter();
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
