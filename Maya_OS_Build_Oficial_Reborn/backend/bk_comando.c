#include "bk_comando.h"
#include "bk_catalogo.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NOME_ARQUIVO_ESTADO "estado_jogo.json"

bool bk_arquivo_existe(const char *caminho) {
    if (caminho == NULL) {
        return false;
    }
    FILE *f = fopen(caminho, "rb");
    if (f == NULL) {
        return false;
    }
    (void)fclose(f);
    return true;
}

bk_status bk_caminho_do_estado(const bk_args *args, char *out, size_t cap, char *err, size_t errcap) {
    if (args == NULL || out == NULL || cap == 0) {
        bk_err(err, errcap, "bk_caminho_do_estado: ponteiro nulo");
        return BK_ERR_ARG;
    }
    if (args->tem_saida) {
        if (!bk_copiar(out, cap, args->saida)) {
            bk_err(err, errcap, "caminho de saida longo demais");
            return BK_ERR_LIMITE;
        }
        return BK_OK;
    }
    const char *pasta = getenv("MAYA_USER_DIR");
    if (pasta != NULL && pasta[0] != '\0') {
        if (!bk_caminho_valido(pasta)) {
            bk_err(err, errcap, "MAYA_USER_DIR invalido (longo demais ou com caracteres de controle)");
            return BK_ERR_ARG;
        }
        size_t n = strlen(pasta);
        bool tem_barra = pasta[n - 1] == '/' || pasta[n - 1] == '\\';
        int escritos = snprintf(out, cap, "%s%s%s", pasta, tem_barra ? "" : "/", NOME_ARQUIVO_ESTADO);
        if (escritos < 0 || (size_t)escritos >= cap) {
            bk_err(err, errcap, "MAYA_USER_DIR longo demais");
            return BK_ERR_LIMITE;
        }
        return BK_OK;
    }
    (void)bk_copiar(out, cap, NOME_ARQUIVO_ESTADO);
    return BK_OK;
}

static bk_status carregar_catalogo(const bk_args *args, bk_catalogo *cat, char *err, size_t cap) {
    if (args->tem_catalogo) {
        return bk_catalogo_carregar(args->catalogo, cat, err, cap);
    }
    static const char *const candidatos[] = {"choices.json", "backend/choices.json"};
    for (size_t i = 0; i < sizeof candidatos / sizeof candidatos[0]; i++) {
        if (bk_arquivo_existe(candidatos[i])) {
            return bk_catalogo_carregar(candidatos[i], cat, err, cap);
        }
    }
    bk_err(err, cap, "catalogo de escolhas nao encontrado (use --catalog <caminho>)");
    return BK_ERR_IO;
}

bk_status bk_comando_escolha(const bk_args *args, bk_estado *resultado, char *saida_usada, size_t cap_saida, char *err, size_t cap) {
    if (args == NULL) {
        bk_err(err, cap, "bk_comando_escolha: argumentos nulos");
        return BK_ERR_ARG;
    }
    if (!args->tem_escolha) {
        bk_err(err, cap, "falta --choice <id>");
        return BK_ERR_ARG;
    }
    if (!bk_id_valido(args->escolha)) {
        bk_err(err, cap, "id de escolha com formato invalido");
        return BK_ERR_ID_FORMATO;
    }
    /* O catálogo e o estado são grandes demais para a pilha de um chamador apertado: ficam no heap, com um único ponto de saída. */
    bk_catalogo *cat = (bk_catalogo *)bk_malloc(sizeof *cat);
    if (cat == NULL) {
        bk_err(err, cap, "sem memoria para o catalogo");
        return BK_ERR_MEM;
    }
    bk_status st = carregar_catalogo(args, cat, err, cap);
    if (st != BK_OK) {
        goto fim;
    }
    const bk_escolha *escolha = bk_catalogo_buscar(cat, args->escolha);
    if (escolha == NULL) {
        bk_err(err, cap, "escolha '%s' nao existe no catalogo", args->escolha);
        st = BK_ERR_ID_DESCONHECIDO;
        goto fim;
    }
    char caminho[BK_PATH_MAX];
    st = bk_caminho_do_estado(args, caminho, sizeof caminho, err, cap);
    if (st != BK_OK) {
        goto fim;
    }
    bk_estado estado;
    bk_estado_inicial(&estado);
    if (!args->reiniciar && bk_arquivo_existe(caminho)) {
        st = bk_estado_ler(caminho, &estado, err, cap);
        if (st != BK_OK) {
            goto fim; /* arquivo existente e invalido: nao sobrescrever em silencio (use --reset) */
        }
    }
    bk_metricas_somar(&estado.metricas, escolha->d_autonomia, escolha->d_conformidade, escolha->d_dependencia);
    (void)bk_copiar(estado.choice_id, sizeof estado.choice_id, escolha->id);
    (void)bk_copiar(estado.status, sizeof estado.status, escolha->status);
    estado.is_placeholder = escolha->is_placeholder;
    if (args->tem_timestamp) {
        (void)bk_copiar(estado.timestamp, sizeof estado.timestamp, args->timestamp);
    } else if (!bk_timestamp_agora(estado.timestamp, sizeof estado.timestamp)) {
        bk_err(err, cap, "nao foi possivel obter a hora atual");
        st = BK_ERR_IO;
        goto fim;
    }
    st = bk_estado_gravar(caminho, &estado, err, cap);
    if (st != BK_OK) {
        goto fim;
    }
    if (resultado != NULL) {
        *resultado = estado;
    }
    if (saida_usada != NULL && cap_saida > 0) {
        (void)bk_copiar(saida_usada, cap_saida, caminho);
    }
fim:
    bk_free(cat);
    return st;
}
