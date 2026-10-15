#ifndef UI_H
#define UI_H

#include "game.h"

void esperar_enter(void);
void limpar_tela(void);
void exibir_cabecalho_ato(const char* act_title);
void exibir_cabecalho_dia(const char* scene_title, int autonomia);
void executar_turno(Turn *turn);

#endif
