#ifndef BK_COMMON_H
#define BK_COMMON_H
/*
 * Tipos e utilidades comuns do backend em C (Maya Human Syntax).
 *
 * CONTRATOS DE OWNERSHIP (valem para todo o backend):
 *   - Funções que devolvem memória (`char **out`) entregam a posse ao chamador, que a libera com bk_free().
 *   - Funções que recebem ponteiros NUNCA guardam o ponteiro recebido: copiam o conteúdo para buffers de tamanho fixo.
 *   - Toda função que pode falhar devolve um bk_status e escreve a mensagem técnica (opcional) em `err`.
 *   - Nenhuma função chama exit(): só main() decide o código de saída.
 */
#include <stdbool.h>
#include <stddef.h>

#define BK_ID_MAX 48               /* tamanho máximo do ID de escolha, sem o terminador */
#define BK_STATUS_MAX 32           /* tamanho máximo do campo "status", sem o terminador */
#define BK_PATH_MAX 1024           /* tamanho máximo de caminhos recebidos por argumento (com o terminador) */
#define BK_ERR_MSG_MAX 256         /* tamanho dos buffers de mensagem de erro */
#define BK_TIMESTAMP_MAX 21        /* "YYYY-MM-DDTHH:MM:SSZ" + terminador */
#define BK_FILE_MAX_BYTES (1024L * 1024L)   /* nenhum JSON lido pelo backend passa de 1 MiB */
#define BK_METRICA_MIN 0.0
#define BK_METRICA_MAX 100.0

/* Os valores são também os códigos de saída do processo (0 = sucesso). */
typedef enum {
    BK_OK = 0,
    BK_ERR_ARG = 2,            /* argumento ausente, duplicado, desconhecido ou fora do formato */
    BK_ERR_ID_FORMATO = 3,     /* ID de escolha com tamanho ou caracteres inválidos */
    BK_ERR_ID_DESCONHECIDO = 4,/* ID válido, mas que não existe no catálogo */
    BK_ERR_IO = 5,             /* falha ao abrir, ler, gravar ou renomear arquivo */
    BK_ERR_JSON = 6,           /* JSON malformado */
    BK_ERR_MEM = 7,            /* falha de alocação */
    BK_ERR_ESQUEMA = 8,        /* JSON válido, mas fora do esquema esperado */
    BK_ERR_LIMITE = 9          /* tamanho ou quantidade acima do limite seguro */
} bk_status;

const char *bk_status_str(bk_status s);

/* Escreve uma mensagem formatada em `err` (se não for NULL e cap > 0). Sempre termina a string com '\0'. */
#if defined(__GNUC__) || defined(__clang__)
#define BK_PRINTF(a, b) __attribute__((format(printf, a, b)))
#else
#define BK_PRINTF(a, b)
#endif
void bk_err(char *err, size_t cap, const char *fmt, ...) BK_PRINTF(3, 4);

/* Copia `src` para `dst` (capacidade `cap`, com o terminador). Devolve false, sem truncar e deixando `dst` vazio, se
 * `src` for NULL ou não couber. Com `dst` NULL ou `cap` 0 não faz nada e devolve false. */
bool bk_copiar(char *dst, size_t cap, const char *src);

/* ID de escolha válido: 1 a BK_ID_MAX caracteres, começa com letra minúscula e só tem [a-z0-9_]. */
bool bk_id_valido(const char *id);

/* Texto curto de estado: 1 a BK_STATUS_MAX caracteres [a-z_]. */
bool bk_status_texto_valido(const char *s);

/* "YYYY-MM-DDTHH:MM:SSZ" (UTC), com campos numericamente plausíveis. */
bool bk_timestamp_valido(const char *ts);

/* Preenche `out` (BK_TIMESTAMP_MAX bytes) com a hora atual em UTC. */
bool bk_timestamp_agora(char *out, size_t cap);

/* Limita um valor ao intervalo [lo, hi]; NaN vira lo. */
double bk_limitar(double v, double lo, double hi);

/* Memória. Todo o backend (inclusive a cJSON) aloca por aqui, para os testes poderem injetar falhas de alocação. */
void *bk_malloc(size_t n);
void bk_free(void *p);
void bk_cjson_instalar_hooks(void);
#ifdef BK_TESTING
/* n >= 0: a (n+1)-ésima alocação a partir de agora falha (0 = a próxima). n < 0: desliga a injeção. */
void bk_test_falhar_alocacao_apos(long n);
long bk_test_alocacoes_vivas(void);
#endif

/* Lê um arquivo inteiro (até BK_FILE_MAX_BYTES) para memória terminada em '\0'. Pula o BOM UTF-8. Posse do buffer: chamador. */
bk_status bk_ler_arquivo(const char *caminho, char **out, size_t *tamanho, char *err, size_t cap);

/* Grava `n` bytes em `caminho` de forma atômica: escreve `caminho.tmp`, força para o disco e renomeia por cima do destino.
 * Se algo falhar, o destino anterior continua intacto e o .tmp é removido. */
bk_status bk_gravar_atomico(const char *caminho, const char *dados, size_t n, char *err, size_t cap);

/* Caminho de arquivo aceitável: não vazio, cabe em BK_PATH_MAX e sem caracteres de controle. */
bool bk_caminho_valido(const char *p);

#endif
