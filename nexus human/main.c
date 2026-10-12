#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "game.h"
#include "ui.h"
#include "json_loader.h"

// Instanciação da variável global declarada em game.h
GameState game;

// Função para exibir o menu inicial do jogo (apenas 2 opções)
int exibir_menu_principal(void) {
    int opcao = 0;
    
    // Tratamento de entrada inválida usando laço while
    while (opcao < 1 || opcao > 2) {
        limpar_tela();
        printf("==================================================\n");
        printf("         NEXUS: HUMAN SYNTAX - OS v1.0            \n");
        printf("==================================================\n\n");
        printf("1. Iniciar Novo Jogo\n");
        printf("2. Sair\n");
        printf("\nEscolha uma opcao (1-2): ");
        
        if (scanf("%d", &opcao) != 1) {
            while (getchar() != '\n'); // Limpa buffer de entrada inválida
            opcao = 0;
        }
    }
    return opcao;
}

int main(void) {
    int opcao_menu = 0;
    char jogar_novamente = 'N';

    // Game Loop Principal usando do-while
    do {
        opcao_menu = exibir_menu_principal();

        if (opcao_menu == 2) {
            printf("\nA encerrar a sessao do NEXUS OS... Ate logo!\n");
            break;
        }

        // Inicialização do estado do jogo
        game.autonomia = 100;
        game.current_act = 0;
        game.current_day = 0;

        // Executa a missão/roteiro do jogo
        executar_jogo("dialogues.json");

        // Desfecho do jogo
        limpar_tela();
        printf("==================================================\n");
        printf("            FIM DA DEMONSTRACAO DO JOGO           \n");
        printf("==================================================\n\n");
        
        bool autonomia_critica = (game.autonomia <= 40) ? true : false;
        printf("Autonomia Final do Utilizador: %d%%\n", game.autonomia);
        printf("Status do Perfil: %s\n\n", autonomia_critica ? "ALOCADO COMO ATIVO/PRODUTO" : "DESCONECTADO COM SUCESSO");

        // Pergunta se deseja jogar novamente
        while (getchar() != '\n'); // Limpa buffer
        printf("Deseja jogar novamente? (S/N): ");
        scanf("%c", &jogar_novamente);

    } while (jogar_novamente == 'S' || jogar_novamente == 's');

    printf("\nObrigado por jogar NEXUS: Human Syntax!\n");
    return 0;
}
