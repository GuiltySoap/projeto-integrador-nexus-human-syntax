#define _POSIX_C_SOURCE 200809L
#include "ui.h"

#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <io.h>
#include <windows.h>
#define BK_ISATTY(f) _isatty(_fileno(f))
#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING 0x0004
#endif
#else
#include <unistd.h>
#define BK_ISATTY(f) isatty(fileno(f))
#endif

void limpar_tela(void) {
    if (!BK_ISATTY(stdout)) {
        return;
    }
#ifdef _WIN32
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD modo = 0;
    if (h != INVALID_HANDLE_VALUE && GetConsoleMode(h, &modo)) {
        (void)SetConsoleMode(h, modo | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    }
#endif
    fputs("\x1b[2J\x1b[H", stdout);
}

bool ui_ler_linha(char *buf, size_t cap) {
    if (buf == NULL || cap < 2) {
        return false;
    }
    buf[0] = '\0';
    if (fgets(buf, (int)(cap > (size_t)INT_MAX ? (size_t)INT_MAX : cap), stdin) == NULL) {
        return false;
    }
    size_t n = strlen(buf);
    if (n > 0 && buf[n - 1] == '\n') {
        buf[n - 1] = '\0';
        return true;
    }
    /* Linha maior que o buffer: descarta o resto até a quebra de linha (ou EOF). */
    int c;
    while ((c = getchar()) != '\n' && c != EOF) {
    }
    return true;
}

bool esperar_enter(void) {
    char lixo[8];
    fputs("\n[Pressione ENTER para continuar...]", stdout);
    (void)fflush(stdout);
    return ui_ler_linha(lixo, sizeof lixo);
}

void exibir_cabecalho_ato(const char *act_title) {
    limpar_tela();
    printf("==================================================\n");
    printf("                 %s                   \n", act_title != NULL ? act_title : "");
    printf("==================================================\n");
    printf("\n> Transicao de fase do sistema em curso...\n");
    (void)esperar_enter();
}

void exibir_cabecalho_dia(const char *scene_title, int autonomia) {
    limpar_tela();
    printf("==================================================\n");
    printf("  %s  |  AUTONOMIA: %d%%\n", scene_title != NULL ? scene_title : "", autonomia);
    printf("==================================================\n\n");
    (void)esperar_enter();
}

bk_status ui_ler_inteiro(int min, int max, int *out) {
    char linha[64];
    if (out == NULL) {
        return BK_ERR_ARG;
    }
    if (!ui_ler_linha(linha, sizeof linha)) {
        return BK_ERR_IO;
    }
    char *fim = NULL;
    errno = 0;
    long v = strtol(linha, &fim, 10);
    if (errno != 0 || fim == linha || *fim != '\0' || v < (long)min || v > (long)max) {
        return BK_ERR_ARG;
    }
    *out = (int)v;
    return BK_OK;
}

bk_status executar_turno(GameState *jogo, const Turn *turno) {
    if (jogo == NULL || turno == NULL) {
        return BK_ERR_ARG;
    }
    for (int i = 0; i < turno->message_count && i < MAX_MESSAGES; i++) {
        printf("[%s] %s: %s\n", turno->messages[i].timestamp, turno->messages[i].sender, turno->messages[i].text);
        if (!esperar_enter()) {
            return BK_ERR_IO;
        }
    }
    if (turno->choice_count <= 0) {
        return BK_OK;
    }
    for (;;) {
        printf("\n--- OPCOES DE RESPOSTA / DECISAO ---\n");
        for (int i = 0; i < turno->choice_count && i < MAX_CHOICES; i++) {
            printf("%d) \"%s\"\n", turno->choices[i].id, turno->choices[i].text);
        }
        printf("\nDigite o numero da sua escolha: ");
        (void)fflush(stdout);
        int opcao = 0;
        bk_status st = ui_ler_inteiro(INT_MIN, INT_MAX, &opcao);
        if (st == BK_ERR_IO) {
            return BK_ERR_IO;
        }
        const Choice *escolhida = NULL;
        if (st == BK_OK) {
            for (int i = 0; i < turno->choice_count && i < MAX_CHOICES; i++) {
                if (turno->choices[i].id == opcao) {
                    escolhida = &turno->choices[i];
                    break;
                }
            }
        }
        if (escolhida == NULL) {
            printf("Opcao invalida. Digite o numero de uma das opcoes acima.\n");
            continue;
        }
        long novo = (long)jogo->autonomia + (long)escolhida->autonomy_impact;
        jogo->autonomia = novo < 0 ? 0 : (novo > 100 ? 100 : (int)novo);
        if (escolhida->delegated) {
            printf("\n[SISTEMA]: Acao delegada a Maya. (-Autonomia / +Conformidade)\n");
        } else {
            printf("\n[SISTEMA]: Acao mantida sob controlo manual do utilizador.\n");
        }
        if (!esperar_enter()) {
            return BK_ERR_IO;
        }
        printf("\n[MAYA]: %s\n", escolhida->nexus_reply);
        if (!esperar_enter()) {
            return BK_ERR_IO;
        }
        return BK_OK;
    }
}
