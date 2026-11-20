#include "bk_args.h"

#include <string.h>

/* Se argv[*i] é a opção `nome` (em "--nome valor" ou "--nome=valor"), devolve 1 e aponta *valor para o valor.
 * Devolve 0 se não é a opção, -1 se é a opção mas falta o valor. Avança *i quando consome o argumento seguinte. */
static int opcao_com_valor(int argc, char *const argv[], int *i, const char *nome, const char **valor) {
    const char *arg = argv[*i];
    size_t n = strlen(nome);
    if (strncmp(arg, nome, n) != 0) {
        return 0;
    }
    if (arg[n] == '=') {
        *valor = arg + n + 1;
        return 1;
    }
    if (arg[n] != '\0') {
        return 0;
    }
    if (*i + 1 >= argc || argv[*i + 1] == NULL || argv[*i + 1][0] == '-') {
        return -1;
    }
    (*i)++;
    *valor = argv[*i];
    return 1;
}

static bk_status copiar_caminho(char *dst, size_t cap, const char *valor, const char *opcao, char *err, size_t errcap) {
    if (!bk_caminho_valido(valor)) {
        bk_err(err, errcap, "valor invalido para %s (vazio, longo demais ou com caracteres de controle)", opcao);
        return BK_ERR_ARG;
    }
    if (!bk_copiar(dst, cap, valor)) {
        bk_err(err, errcap, "valor longo demais para %s", opcao);
        return BK_ERR_ARG;
    }
    return BK_OK;
}

bk_status bk_args_interpretar(int argc, char *const argv[], bk_args *out, char *err, size_t cap) {
    if (out == NULL) {
        bk_err(err, cap, "bk_args_interpretar: ponteiro de saida nulo");
        return BK_ERR_ARG;
    }
    memset(out, 0, sizeof *out);
    if (argc < 0 || (argc > 0 && argv == NULL)) {
        bk_err(err, cap, "argc/argv invalidos");
        return BK_ERR_ARG;
    }
    for (int i = 1; i < argc; i++) {
        if (argv[i] == NULL) {
            bk_err(err, cap, "argumento nulo na posicao %d", i);
            return BK_ERR_ARG;
        }
        const char *arg = argv[i];
        const char *valor = NULL;
        int r;
        if (strcmp(arg, "--help") == 0 || strcmp(arg, "-h") == 0) {
            out->ajuda = true;
            return BK_OK;
        }
        if (strcmp(arg, "--version") == 0) {
            out->versao = true;
            return BK_OK;
        }
        if (strcmp(arg, "--reset") == 0) {
            if (out->reiniciar) {
                bk_err(err, cap, "argumento duplicado: --reset");
                return BK_ERR_ARG;
            }
            out->reiniciar = true;
            continue;
        }
        r = opcao_com_valor(argc, argv, &i, "--choice", &valor);
        if (r != 0) {
            if (r < 0) {
                bk_err(err, cap, "--choice exige um id (ex.: --choice choice_fixed_01)");
                return BK_ERR_ARG;
            }
            if (out->tem_escolha) {
                bk_err(err, cap, "argumento duplicado: --choice");
                return BK_ERR_ARG;
            }
            if (!bk_id_valido(valor)) {
                bk_err(err, cap, "id de escolha invalido (use 1 a %d caracteres: letra minuscula e depois [a-z0-9_])", BK_ID_MAX);
                return BK_ERR_ID_FORMATO;
            }
            (void)bk_copiar(out->escolha, sizeof out->escolha, valor);
            out->tem_escolha = true;
            continue;
        }
        r = opcao_com_valor(argc, argv, &i, "--out", &valor);
        if (r != 0) {
            if (r < 0 || out->tem_saida) {
                bk_err(err, cap, r < 0 ? "--out exige um caminho" : "argumento duplicado: --out");
                return BK_ERR_ARG;
            }
            bk_status st = copiar_caminho(out->saida, sizeof out->saida, valor, "--out", err, cap);
            if (st != BK_OK) {
                return st;
            }
            out->tem_saida = true;
            continue;
        }
        r = opcao_com_valor(argc, argv, &i, "--catalog", &valor);
        if (r != 0) {
            if (r < 0 || out->tem_catalogo) {
                bk_err(err, cap, r < 0 ? "--catalog exige um caminho" : "argumento duplicado: --catalog");
                return BK_ERR_ARG;
            }
            bk_status st = copiar_caminho(out->catalogo, sizeof out->catalogo, valor, "--catalog", err, cap);
            if (st != BK_OK) {
                return st;
            }
            out->tem_catalogo = true;
            continue;
        }
        r = opcao_com_valor(argc, argv, &i, "--dialogues", &valor);
        if (r != 0) {
            if (r < 0 || out->tem_dialogos) {
                bk_err(err, cap, r < 0 ? "--dialogues exige um caminho" : "argumento duplicado: --dialogues");
                return BK_ERR_ARG;
            }
            bk_status st = copiar_caminho(out->dialogos, sizeof out->dialogos, valor, "--dialogues", err, cap);
            if (st != BK_OK) {
                return st;
            }
            out->tem_dialogos = true;
            continue;
        }
        r = opcao_com_valor(argc, argv, &i, "--timestamp", &valor);
        if (r != 0) {
            if (r < 0 || out->tem_timestamp) {
                bk_err(err, cap, r < 0 ? "--timestamp exige um valor" : "argumento duplicado: --timestamp");
                return BK_ERR_ARG;
            }
            if (!bk_timestamp_valido(valor)) {
                bk_err(err, cap, "--timestamp deve ser YYYY-MM-DDTHH:MM:SSZ");
                return BK_ERR_ARG;
            }
            (void)bk_copiar(out->timestamp, sizeof out->timestamp, valor);
            out->tem_timestamp = true;
            continue;
        }
        if (arg[0] == '-') {
            bk_err(err, cap, "argumento desconhecido: %.40s", arg);
        } else {
            bk_err(err, cap, "argumento inesperado (posicional): %.40s", arg);
        }
        return BK_ERR_ARG;
    }
    return BK_OK;
}
