#ifndef GAME_H
#define GAME_H
/*
 * Tipos do MODO INTERATIVO (console) do backend. Os tamanhos dos campos de texto são limites DUROS: o carregador recusa o roteiro
 * (com erro e mensagem) quando um valor não cabe, em vez de truncar ou estourar o buffer.
 * O estado do jogo NÃO é mais global: quem executa o roteiro recebe um GameState por ponteiro.
 */
#include <stdbool.h>

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
    char nexus_reply[256]; /* chave "nexus_reply" do roteiro (nome legado do campo): é a fala da Maya */
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

#endif
