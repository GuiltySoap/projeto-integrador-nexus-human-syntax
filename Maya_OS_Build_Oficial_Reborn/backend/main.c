/*
 * Backend em C (Maya Human Syntax): ferramenta auxiliar de linha de comando, FORA do jogo Godot (o jogo não a executa).
 *   - `--choice <id>`: aplica uma escolha do catálogo e grava `estado_jogo.json` (contrato lido pelo Godot);
 *   - sem argumentos: modo interativo de console, com o roteiro `dialogues.json` (formato days/turns).
 * Veja bk_args.h para todas as opções e bk_estado.h para o formato do arquivo.
 */
#include "bk_args.h"
#include "bk_comando.h"
#include "game.h"
#include "json_loader.h"
#include "ui.h"

#include <stdio.h>
#include <string.h>

#define BK_VERSAO "1.0.0"
#define BK_ROTEIRO_PADRAO "dialogues.json"

static void mostrar_ajuda(void) {
    puts("Uso: maya_backend [opcoes]\n"
         "  --choice <id>          aplica a escolha <id> do catalogo e grava estado_jogo.json\n"
         "  --out <caminho>        arquivo de estado (padrao: $MAYA_USER_DIR/estado_jogo.json ou ./estado_jogo.json)\n"
         "  --catalog <caminho>    catalogo de escolhas (padrao: choices.json)\n"
         "  --timestamp <iso>      carimbo fixo YYYY-MM-DDTHH:MM:SSZ (testes)\n"
         "  --reset                ignora o estado gravado e parte dos valores iniciais\n"
         "  --dialogues <caminho>  roteiro do modo interativo (padrao: dialogues.json)\n"
         "  --help, -h             esta ajuda\n"
         "  --version              versao\n"
         "Sem --choice abre o modo interativo (console).\n"
         "Codigos de saida: 0 ok, 2 argumento, 3 formato do id, 4 id desconhecido, 5 E/S, 6 json, 7 memoria, 8 esquema, 9 limite.");
}

static bk_status modo_interativo(const bk_args *args) {
    const char *roteiro = args->tem_dialogos ? args->dialogos : BK_ROTEIRO_PADRAO;
    char err[BK_ERR_MSG_MAX];
    for (;;) {
        limpar_tela();
        printf("==================================================\n");
        printf("         MAYA HUMAN SYNTAX - HUMAXOS v1.0         \n");
        printf("==================================================\n\n");
        printf("1. Iniciar Novo Jogo\n");
        printf("2. Sair\n");
        printf("\nEscolha uma opcao (1-2): ");
        (void)fflush(stdout);
        int opcao = 0;
        bk_status st = ui_ler_inteiro(1, 2, &opcao);
        if (st == BK_ERR_IO) {
            return BK_OK; /* entrada encerrada: sai sem erro */
        }
        if (st != BK_OK) {
            continue;
        }
        if (opcao == 2) {
            printf("\nEncerrando a sessao do HumaxOS... Ate logo!\n");
            return BK_OK;
        }
        GameState jogo;
        memset(&jogo, 0, sizeof jogo);
        jogo.autonomia = 100;
        st = executar_jogo(roteiro, &jogo, err, sizeof err);
        if (st != BK_OK) {
            fprintf(stderr, "[ERRO] %s\n", err);
            return st;
        }
        limpar_tela();
        printf("==================================================\n");
        printf("            FIM DA DEMONSTRACAO DO JOGO           \n");
        printf("==================================================\n\n");
        printf("Autonomia Final do Utilizador: %d%%\n", jogo.autonomia);
        printf("Status do Perfil: %s\n\n", jogo.autonomia <= 40 ? "ALOCADO COMO ATIVO/PRODUTO" : "DESCONECTADO COM SUCESSO");
        printf("Deseja jogar novamente? (S/N): ");
        (void)fflush(stdout);
        char resposta[8];
        if (!ui_ler_linha(resposta, sizeof resposta) || (resposta[0] != 'S' && resposta[0] != 's')) {
            printf("\nObrigado por jogar Maya Human Syntax!\n");
            return BK_OK;
        }
    }
}

int main(int argc, char **argv) {
    bk_cjson_instalar_hooks();
    bk_args args;
    char err[BK_ERR_MSG_MAX];
    bk_status st = bk_args_interpretar(argc, argv, &args, err, sizeof err);
    if (st != BK_OK) {
        fprintf(stderr, "[ERRO] %s\nUse --help para ver as opcoes.\n", err);
        return (int)st;
    }
    if (args.ajuda) {
        mostrar_ajuda();
        return 0;
    }
    if (args.versao) {
        puts("maya_backend " BK_VERSAO);
        return 0;
    }
    if (args.tem_escolha) {
        bk_estado estado;
        char usado[BK_PATH_MAX];
        st = bk_comando_escolha(&args, &estado, usado, sizeof usado, err, sizeof err);
        if (st != BK_OK) {
            fprintf(stderr, "[ERRO] %s (%s)\n", err, bk_status_str(st));
            return (int)st;
        }
        printf("ok: escolha '%s' aplicada; estado gravado em %s\n", estado.choice_id, usado);
        return 0;
    }
    st = modo_interativo(&args);
    return (int)st;
}
