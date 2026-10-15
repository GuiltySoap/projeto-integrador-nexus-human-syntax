#ifndef GAME_H
#define GAME_H

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

extern GameState game;

#endif
