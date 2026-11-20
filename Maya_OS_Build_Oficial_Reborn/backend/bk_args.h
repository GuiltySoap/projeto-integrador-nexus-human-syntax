#ifndef BK_ARGS_H
#define BK_ARGS_H
/*
 * Interpretação ESTRITA dos argumentos de linha de comando. Nada aqui executa ou monta comandos de shell: os valores só são
 * validados e copiados para buffers de tamanho fixo.
 *
 *   --choice <id>        aplica a escolha <id> do catálogo e grava estado_jogo.json (também aceita --choice=<id>)
 *   --out <caminho>      onde gravar o estado (padrão: $MAYA_USER_DIR/estado_jogo.json, ou ./estado_jogo.json)
 *   --catalog <caminho>  catálogo de escolhas (padrão: choices.json ou backend/choices.json)
 *   --timestamp <iso>    carimbo fixo "YYYY-MM-DDTHH:MM:SSZ" (testes determinísticos)
 *   --reset              ignora o estado gravado e parte dos valores iniciais
 *   --dialogues <caminho> roteiro do modo interativo (padrão: dialogues.json)
 *   --help, -h           mostra a ajuda
 *   --version            mostra a versão
 * Sem --choice, o programa abre o modo interativo (console).
 */
#include "bk_common.h"

typedef struct {
    bool ajuda;
    bool versao;
    bool reiniciar;
    bool tem_escolha;
    char escolha[BK_ID_MAX + 1];
    bool tem_saida;
    char saida[BK_PATH_MAX];
    bool tem_catalogo;
    char catalogo[BK_PATH_MAX];
    bool tem_timestamp;
    char timestamp[BK_TIMESTAMP_MAX];
    bool tem_dialogos;
    char dialogos[BK_PATH_MAX];
} bk_args;

/* Devolve BK_OK, BK_ERR_ARG (ausente, duplicado, desconhecido, posicional...) ou BK_ERR_ID_FORMATO (--choice fora do formato).
 * `out` é sempre zerado antes. Com BK_OK e `ajuda`/`versao` verdadeiros, o resto dos argumentos é ignorado. */
bk_status bk_args_interpretar(int argc, char *const argv[], bk_args *out, char *err, size_t cap);

#endif
