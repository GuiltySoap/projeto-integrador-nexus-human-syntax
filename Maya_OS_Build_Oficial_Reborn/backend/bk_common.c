#define _POSIX_C_SOURCE 200809L
#include "bk_common.h"
#include "cJSON.h"

#include <errno.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef _WIN32
#include <io.h>
#include <windows.h>
#else
#include <unistd.h>
#endif

const char *bk_status_str(bk_status s) {
    switch (s) {
        case BK_OK: return "ok";
        case BK_ERR_ARG: return "argumento invalido";
        case BK_ERR_ID_FORMATO: return "id de escolha com formato invalido";
        case BK_ERR_ID_DESCONHECIDO: return "id de escolha desconhecido";
        case BK_ERR_IO: return "falha de entrada/saida";
        case BK_ERR_JSON: return "json malformado";
        case BK_ERR_MEM: return "falha de alocacao";
        case BK_ERR_ESQUEMA: return "json fora do esquema";
        case BK_ERR_LIMITE: return "limite excedido";
    }
    return "erro desconhecido";
}

void bk_err(char *err, size_t cap, const char *fmt, ...) {
    if (err == NULL || cap == 0) {
        return;
    }
    err[0] = '\0';
    if (fmt == NULL) {
        return;
    }
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(err, cap, fmt, ap);
    va_end(ap);
    if (n < 0) {
        err[0] = '\0';
    }
    err[cap - 1] = '\0';
}

bool bk_copiar(char *dst, size_t cap, const char *src) {
    if (dst == NULL || cap == 0) {
        return false;
    }
    dst[0] = '\0';
    if (src == NULL) {
        return false;
    }
    size_t n = strlen(src);
    if (n >= cap) {
        return false;
    }
    memcpy(dst, src, n + 1);
    return true;
}

bool bk_id_valido(const char *id) {
    if (id == NULL) {
        return false;
    }
    size_t n = strlen(id);
    if (n == 0 || n > BK_ID_MAX) {
        return false;
    }
    if (id[0] < 'a' || id[0] > 'z') {
        return false;
    }
    for (size_t i = 1; i < n; i++) {
        char c = id[i];
        bool ok = (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_';
        if (!ok) {
            return false;
        }
    }
    return true;
}

bool bk_status_texto_valido(const char *s) {
    if (s == NULL) {
        return false;
    }
    size_t n = strlen(s);
    if (n == 0 || n > BK_STATUS_MAX) {
        return false;
    }
    for (size_t i = 0; i < n; i++) {
        char c = s[i];
        if (!((c >= 'a' && c <= 'z') || c == '_')) {
            return false;
        }
    }
    return true;
}

static bool digitos(const char *p, size_t n) {
    for (size_t i = 0; i < n; i++) {
        if (p[i] < '0' || p[i] > '9') {
            return false;
        }
    }
    return true;
}

static int num2(const char *p) {
    return (p[0] - '0') * 10 + (p[1] - '0');
}

bool bk_timestamp_valido(const char *ts) {
    if (ts == NULL || strlen(ts) != BK_TIMESTAMP_MAX - 1) {
        return false;
    }
    /* 0123456789012345678 9  -> YYYY-MM-DDTHH:MM:SSZ */
    if (!digitos(ts, 4) || ts[4] != '-' || !digitos(ts + 5, 2) || ts[7] != '-' || !digitos(ts + 8, 2) || ts[10] != 'T' ||
        !digitos(ts + 11, 2) || ts[13] != ':' || !digitos(ts + 14, 2) || ts[16] != ':' || !digitos(ts + 17, 2) || ts[19] != 'Z') {
        return false;
    }
    int mes = num2(ts + 5);
    int dia = num2(ts + 8);
    int hora = num2(ts + 11);
    int min = num2(ts + 14);
    int seg = num2(ts + 17);
    return mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31 && hora <= 23 && min <= 59 && seg <= 60;
}

bool bk_timestamp_agora(char *out, size_t cap) {
    if (out == NULL || cap < BK_TIMESTAMP_MAX) {
        return false;
    }
    time_t agora = time(NULL);
    if (agora == (time_t)-1) {
        return false;
    }
    struct tm partes;
#ifdef _WIN32
    if (gmtime_s(&partes, &agora) != 0) {
        return false;
    }
#else
    if (gmtime_r(&agora, &partes) == NULL) {
        return false;
    }
#endif
    return strftime(out, cap, "%Y-%m-%dT%H:%M:%SZ", &partes) == BK_TIMESTAMP_MAX - 1;
}

double bk_limitar(double v, double lo, double hi) {
    if (isnan(v)) {
        return lo;
    }
    if (v < lo) {
        return lo;
    }
    if (v > hi) {
        return hi;
    }
    return v;
}

bool bk_caminho_valido(const char *p) {
    if (p == NULL) {
        return false;
    }
    size_t n = strlen(p);
    if (n == 0 || n >= BK_PATH_MAX) {
        return false;
    }
    for (size_t i = 0; i < n; i++) {
        if ((unsigned char)p[i] < 0x20 || p[i] == 0x7f) {
            return false;
        }
    }
    return true;
}

/* ------------------------------------------------------------------ memória (com injeção de falhas nos testes) */
#ifdef BK_TESTING
static long g_falha_em = -1;
static long g_vivas = 0;
void bk_test_falhar_alocacao_apos(long n) {
    g_falha_em = n;
}
long bk_test_alocacoes_vivas(void) {
    return g_vivas;
}
#endif

void *bk_malloc(size_t n) {
#ifdef BK_TESTING
    if (g_falha_em == 0) {
        g_falha_em = -1;
        return NULL;
    }
    if (g_falha_em > 0) {
        g_falha_em--;
    }
#endif
    void *p = malloc(n == 0 ? 1 : n);
#ifdef BK_TESTING
    if (p != NULL) {
        g_vivas++;
    }
#endif
    return p;
}

void bk_free(void *p) {
    if (p == NULL) {
        return;
    }
#ifdef BK_TESTING
    g_vivas--;
#endif
    free(p);
}

void bk_cjson_instalar_hooks(void) {
    static cJSON_Hooks hooks;
    hooks.malloc_fn = bk_malloc;
    hooks.free_fn = bk_free;
    cJSON_InitHooks(&hooks);
}

/* ------------------------------------------------------------------ arquivos */
bk_status bk_ler_arquivo(const char *caminho, char **out, size_t *tamanho, char *err, size_t cap) {
    if (out != NULL) {
        *out = NULL;
    }
    if (tamanho != NULL) {
        *tamanho = 0;
    }
    if (caminho == NULL || out == NULL || tamanho == NULL) {
        bk_err(err, cap, "bk_ler_arquivo: ponteiro nulo");
        return BK_ERR_ARG;
    }
    FILE *f = fopen(caminho, "rb");
    if (f == NULL) {
        bk_err(err, cap, "nao foi possivel abrir '%s': %s", caminho, strerror(errno));
        return BK_ERR_IO;
    }
    bk_status st = BK_OK;
    char *buf = NULL;
    if (fseek(f, 0, SEEK_END) != 0) {
        bk_err(err, cap, "fseek falhou em '%s'", caminho);
        st = BK_ERR_IO;
        goto fim;
    }
    long len = ftell(f);
    if (len < 0) {
        bk_err(err, cap, "ftell falhou em '%s'", caminho);
        st = BK_ERR_IO;
        goto fim;
    }
    if (len > BK_FILE_MAX_BYTES) {
        /* Uma pasta aberta com fopen devolve um tamanho absurdo (LONG_MAX) em vez de falhar: a mensagem cobre os dois casos. */
        bk_err(err, cap, "'%s' passa do limite de %ld bytes ou nao e um arquivo comum", caminho, BK_FILE_MAX_BYTES);
        st = BK_ERR_LIMITE;
        goto fim;
    }
    if (fseek(f, 0, SEEK_SET) != 0) {
        bk_err(err, cap, "fseek falhou em '%s'", caminho);
        st = BK_ERR_IO;
        goto fim;
    }
    size_t n = (size_t)len;
    buf = (char *)bk_malloc(n + 1);
    if (buf == NULL) {
        bk_err(err, cap, "sem memoria para ler '%s' (%zu bytes)", caminho, n);
        st = BK_ERR_MEM;
        goto fim;
    }
    if (n > 0 && fread(buf, 1, n, f) != n) {
        bk_err(err, cap, "leitura incompleta de '%s'", caminho);
        st = BK_ERR_IO;
        goto fim;
    }
    buf[n] = '\0';
    size_t ini = 0;
    if (n >= 3 && (unsigned char)buf[0] == 0xEF && (unsigned char)buf[1] == 0xBB && (unsigned char)buf[2] == 0xBF) {
        ini = 3;
    }
    if (ini > 0) {
        memmove(buf, buf + ini, n - ini + 1);
        n -= ini;
    }
    *out = buf;
    *tamanho = n;
    buf = NULL;
fim:
    bk_free(buf);
    (void)fclose(f);
    return st;
}

bk_status bk_gravar_atomico(const char *caminho, const char *dados, size_t n, char *err, size_t cap) {
    if (caminho == NULL || dados == NULL) {
        bk_err(err, cap, "bk_gravar_atomico: ponteiro nulo");
        return BK_ERR_ARG;
    }
    if (!bk_caminho_valido(caminho)) {
        bk_err(err, cap, "caminho de saida invalido");
        return BK_ERR_ARG;
    }
    char tmp[BK_PATH_MAX + 8];
    int escritos = snprintf(tmp, sizeof tmp, "%s.tmp", caminho);
    if (escritos < 0 || (size_t)escritos >= sizeof tmp) {
        bk_err(err, cap, "caminho de saida longo demais");
        return BK_ERR_LIMITE;
    }
    FILE *f = fopen(tmp, "wb");
    if (f == NULL) {
        bk_err(err, cap, "nao foi possivel criar '%s': %s", tmp, strerror(errno));
        return BK_ERR_IO;
    }
    bool ok = fwrite(dados, 1, n, f) == n && fflush(f) == 0;
    if (ok) {
#ifdef _WIN32
        ok = _commit(_fileno(f)) == 0;
#else
        ok = fsync(fileno(f)) == 0;
#endif
    }
    if (fclose(f) != 0) {
        ok = false;
    }
    if (!ok) {
        bk_err(err, cap, "falha ao gravar '%s'", tmp);
        (void)remove(tmp);
        return BK_ERR_IO;
    }
#ifdef _WIN32
    if (!MoveFileExA(tmp, caminho, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        bk_err(err, cap, "nao foi possivel substituir '%s'", caminho);
        (void)remove(tmp);
        return BK_ERR_IO;
    }
#else
    if (rename(tmp, caminho) != 0) {
        bk_err(err, cap, "nao foi possivel renomear para '%s': %s", caminho, strerror(errno));
        (void)remove(tmp);
        return BK_ERR_IO;
    }
#endif
    return BK_OK;
}
