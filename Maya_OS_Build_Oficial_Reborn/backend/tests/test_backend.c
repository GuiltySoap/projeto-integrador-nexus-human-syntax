/*
 * Testes nativos do backend em C. Compilados com -DBK_TESTING (injeção de falhas de alocação) e, no Makefile, com ASan/UBSan
 * (`make test-c`) e sob valgrind (`make test-c-valgrind`). POSIX apenas (mkdtemp, dup2); o alvo Windows não compila este arquivo.
 *
 * Cobre: argumentos (válidos, ausentes, duplicados, desconhecidos, injeção de shell), formato do ID, limites de tamanho,
 * ponteiros nulos, falhas de alocação, vazamentos, JSON do estado (esquema, versão, valores inválidos), escrita atômica,
 * catálogo, `--choice` ponta a ponta e o modo interativo com a entrada em EOF.
 */
#define _POSIX_C_SOURCE 200809L
#include "../bk_args.h"
#include "../bk_catalogo.h"
#include "../bk_comando.h"
#include "../bk_common.h"
#include "../bk_estado.h"
#include "../cJSON.h"
#include "../game.h"
#include "../json_loader.h"
#include "../ui.h"

#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#ifndef BK_CHOICES_PATH
#define BK_CHOICES_PATH "backend/choices.json"
#endif

static int g_checks = 0;
static int g_falhas = 0;

#define CHECK(cond)                                                                \
    do {                                                                           \
        g_checks++;                                                                \
        if (!(cond)) {                                                             \
            g_falhas++;                                                            \
            fprintf(stderr, "FALHA %s:%d: %s\n", __FILE__, __LINE__, #cond);       \
        }                                                                          \
    } while (0)

static char g_dir[256];

/* Copia um texto para um buffer estático e devolve um `char *` gravável (argv exige char *, e literais são const). */
static char *M(const char *texto) {
    static char pool[64][BK_PATH_MAX + 16];
    static unsigned proximo = 0;
    char *dst = pool[proximo++ % 64];
    snprintf(dst, BK_PATH_MAX + 16, "%s", texto);
    return dst;
}

static void caminho_em(char *out, size_t cap, const char *nome) {
    snprintf(out, cap, "%s/%s", g_dir, nome);
}

static void escrever(const char *nome, const char *conteudo) {
    char p[512];
    caminho_em(p, sizeof p, nome);
    FILE *f = fopen(p, "wb");
    if (f != NULL) {
        fputs(conteudo, f);
        fclose(f);
    }
}

static char *ler_tudo(const char *nome) {
    char p[512];
    caminho_em(p, sizeof p, nome);
    char *buf = NULL;
    size_t n = 0;
    char err[BK_ERR_MSG_MAX];
    if (bk_ler_arquivo(p, &buf, &n, err, sizeof err) != BK_OK) {
        return NULL;
    }
    return buf;
}

static bool arquivo_existe(const char *nome) {
    char p[512];
    caminho_em(p, sizeof p, nome);
    return bk_arquivo_existe(p);
}

/* ------------------------------------------------------------------ utilidades comuns */
static void teste_comum(void) {
    char buf[8];
    CHECK(bk_copiar(buf, sizeof buf, "1234567"));            /* cabe exatamente (7 + terminador) */
    CHECK(strcmp(buf, "1234567") == 0);
    CHECK(!bk_copiar(buf, sizeof buf, "12345678"));          /* 8 não cabe: não trunca */
    CHECK(buf[0] == '\0');                                   /* e o destino fica vazio e terminado */
    CHECK(!bk_copiar(buf, sizeof buf, NULL));
    CHECK(!bk_copiar(NULL, sizeof buf, "x"));
    CHECK(!bk_copiar(buf, 0, "x"));

    CHECK(bk_id_valido("choice_fixed_01"));
    CHECK(bk_id_valido("a"));
    CHECK(!bk_id_valido(""));
    CHECK(!bk_id_valido(NULL));
    CHECK(!bk_id_valido("1abc"));
    CHECK(!bk_id_valido("Abc"));
    CHECK(!bk_id_valido("a-b"));
    CHECK(!bk_id_valido("a b"));
    CHECK(!bk_id_valido("a;b"));
    CHECK(!bk_id_valido("a$(x)"));
    CHECK(!bk_id_valido("a`b`"));
    CHECK(!bk_id_valido("a|b"));
    CHECK(!bk_id_valido("../x"));
    CHECK(!bk_id_valido("ação"));
    char longo[BK_ID_MAX + 8];
    memset(longo, 'a', sizeof longo);
    longo[BK_ID_MAX] = '\0';
    CHECK(bk_id_valido(longo));                              /* 48 caracteres: no limite */
    longo[BK_ID_MAX] = 'a';
    longo[BK_ID_MAX + 1] = '\0';
    CHECK(!bk_id_valido(longo));                             /* 49: acima do limite */

    CHECK(bk_status_texto_valido("ok"));
    CHECK(bk_status_texto_valido("erro_de_envio"));
    CHECK(!bk_status_texto_valido(""));
    CHECK(!bk_status_texto_valido("OK"));
    CHECK(!bk_status_texto_valido("a b"));

    CHECK(bk_timestamp_valido("2026-11-17T21:00:00Z"));
    CHECK(!bk_timestamp_valido("2026-13-17T21:00:00Z"));
    CHECK(!bk_timestamp_valido("2026-11-17 21:00:00Z"));
    CHECK(!bk_timestamp_valido("2026-11-17T21:00:00"));
    CHECK(!bk_timestamp_valido("2026-11-17T25:00:00Z"));
    CHECK(!bk_timestamp_valido(""));
    CHECK(!bk_timestamp_valido(NULL));
    char agora[BK_TIMESTAMP_MAX];
    CHECK(bk_timestamp_agora(agora, sizeof agora) && bk_timestamp_valido(agora));
    CHECK(!bk_timestamp_agora(agora, 5));
    CHECK(!bk_timestamp_agora(NULL, 64));

    CHECK(bk_limitar(150.0, 0.0, 100.0) == 100.0);
    CHECK(bk_limitar(-3.0, 0.0, 100.0) == 0.0);
    CHECK(bk_limitar(NAN, 0.0, 100.0) == 0.0);
    CHECK(bk_limitar(INFINITY, 0.0, 100.0) == 100.0);

    CHECK(bk_caminho_valido("a/b.json"));
    CHECK(!bk_caminho_valido(""));
    CHECK(!bk_caminho_valido(NULL));
    CHECK(!bk_caminho_valido("a\nb"));
    char enorme[BK_PATH_MAX + 4];
    memset(enorme, 'x', sizeof enorme);
    enorme[sizeof enorme - 1] = '\0';
    CHECK(!bk_caminho_valido(enorme));

    char msg[16];
    bk_err(msg, sizeof msg, "%s", "uma mensagem bem maior que o buffer");
    CHECK(strlen(msg) == sizeof msg - 1);                    /* cortada, mas sempre terminada */
    bk_err(NULL, 10, "x");                                   /* não deve quebrar */
    bk_err(msg, 0, "x");
    CHECK(strcmp(bk_status_str(BK_ERR_ID_DESCONHECIDO), "id de escolha desconhecido") == 0);
}

/* ------------------------------------------------------------------ argumentos */
static bk_status args(bk_args *a, char *err, size_t cap, int argc, ...) {
    char *argv[16];
    va_list ap;
    va_start(ap, argc);
    for (int i = 0; i < argc && i < 16; i++) {
        argv[i] = va_arg(ap, char *);
    }
    va_end(ap);
    return bk_args_interpretar(argc, argv, a, err, cap);
}

static void teste_argumentos(void) {
    bk_args a;
    char err[BK_ERR_MSG_MAX];

    CHECK(args(&a, err, sizeof err, 3, "x", "--choice", "choice_fixed_01") == BK_OK);
    CHECK(a.tem_escolha && strcmp(a.escolha, "choice_fixed_01") == 0);
    CHECK(args(&a, err, sizeof err, 2, "x", "--choice=ok") == BK_OK && strcmp(a.escolha, "ok") == 0);
    CHECK(args(&a, err, sizeof err, 1, "x") == BK_OK && !a.tem_escolha);               /* ausência = modo interativo */

    CHECK(args(&a, err, sizeof err, 2, "x", "--choice") == BK_ERR_ARG);                 /* falta o valor */
    CHECK(args(&a, err, sizeof err, 3, "x", "--choice", "--reset") == BK_ERR_ARG);      /* o "valor" é outra opção */
    CHECK(args(&a, err, sizeof err, 5, "x", "--choice", "a", "--choice", "b") == BK_ERR_ARG);   /* duplicado */
    CHECK(args(&a, err, sizeof err, 3, "x", "--choice=a", "--choice=b") == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 3, "x", "--reset", "--reset") == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 2, "x", "--desconhecido") == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 2, "x", "-z") == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 2, "x", "choice_fixed_01") == BK_ERR_ARG);           /* posicional */
    CHECK(args(&a, err, sizeof err, 2, "x", "--choicex") == BK_ERR_ARG);

    /* formato do ID, tamanho e caracteres permitidos */
    CHECK(args(&a, err, sizeof err, 3, "x", "--choice", "") == BK_ERR_ID_FORMATO);
    CHECK(args(&a, err, sizeof err, 3, "x", "--choice", "Choice") == BK_ERR_ID_FORMATO);
    CHECK(args(&a, err, sizeof err, 3, "x", "--choice", "1abc") == BK_ERR_ID_FORMATO);
    CHECK(args(&a, err, sizeof err, 2, "x", "--choice=a b") == BK_ERR_ID_FORMATO);
    char longo[BK_ID_MAX + 2];
    memset(longo, 'a', sizeof longo);
    longo[BK_ID_MAX + 1] = '\0';
    CHECK(args(&a, err, sizeof err, 3, "x", "--choice", longo) == BK_ERR_ID_FORMATO);
    CHECK(!a.tem_escolha);                                                               /* nada fica pela metade */

    /* tentativas de injeção de shell: nunca viram um ID válido (e o backend não tem nenhuma chamada ao shell) */
    const char *injecoes[] = {"a;ls", "a&&ls", "a|ls", "$(ls)", "`ls`", "a>b", "a\nls", "../../x", "a'b", "a\"b", "%s%n", "a\\b"};
    for (size_t i = 0; i < sizeof injecoes / sizeof injecoes[0]; i++) {
        char *av[] = {M("x"), M("--choice"), M(injecoes[i])};
        CHECK(bk_args_interpretar(3, av, &a, err, sizeof err) == BK_ERR_ID_FORMATO);
    }

    /* demais opções */
    CHECK(args(&a, err, sizeof err, 3, "x", "--out", "/tmp/a b.json") == BK_OK && a.tem_saida && strcmp(a.saida, "/tmp/a b.json") == 0);
    CHECK(args(&a, err, sizeof err, 3, "x", "--out", "x; rm -rf /") == BK_OK);           /* só texto: nada é executado */
    CHECK(args(&a, err, sizeof err, 2, "x", "--out") == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 3, "x", "--out", "a\tb") == BK_ERR_ARG);              /* caractere de controle */
    char enorme[BK_PATH_MAX + 10];
    memset(enorme, 'p', sizeof enorme);
    enorme[sizeof enorme - 1] = '\0';
    CHECK(args(&a, err, sizeof err, 3, "x", "--out", enorme) == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 5, "x", "--out", "a", "--out", "b") == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 3, "x", "--catalog", "c.json") == BK_OK && a.tem_catalogo);
    CHECK(args(&a, err, sizeof err, 3, "x", "--dialogues", "d.json") == BK_OK && a.tem_dialogos);
    CHECK(args(&a, err, sizeof err, 3, "x", "--timestamp", "2026-11-17T21:00:00Z") == BK_OK && a.tem_timestamp);
    CHECK(args(&a, err, sizeof err, 3, "x", "--timestamp", "ontem") == BK_ERR_ARG);
    CHECK(args(&a, err, sizeof err, 2, "x", "--help") == BK_OK && a.ajuda);
    CHECK(args(&a, err, sizeof err, 2, "x", "-h") == BK_OK && a.ajuda);
    CHECK(args(&a, err, sizeof err, 2, "x", "--version") == BK_OK && a.versao);

    /* ponteiros nulos e argc/argv inconsistentes */
    char *av1[] = {M("x")};
    CHECK(bk_args_interpretar(1, av1, NULL, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_args_interpretar(1, NULL, &a, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_args_interpretar(-1, av1, &a, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_args_interpretar(0, NULL, &a, err, sizeof err) == BK_OK);
    char *av2[] = {M("x"), NULL};
    CHECK(bk_args_interpretar(2, av2, &a, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_args_interpretar(2, av2, &a, NULL, 0) == BK_ERR_ARG);                       /* sem buffer de erro também funciona */
}

/* ------------------------------------------------------------------ arquivos */
static void teste_arquivos(void) {
    char p[512], err[BK_ERR_MSG_MAX];
    char *buf = NULL;
    size_t n = 0;

    caminho_em(p, sizeof p, "nao_existe.json");
    CHECK(bk_ler_arquivo(p, &buf, &n, err, sizeof err) == BK_ERR_IO && buf == NULL);
    CHECK(bk_ler_arquivo(NULL, &buf, &n, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_ler_arquivo(p, NULL, &n, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_ler_arquivo(p, &buf, NULL, err, sizeof err) == BK_ERR_ARG);

    escrever("vazio.txt", "");
    caminho_em(p, sizeof p, "vazio.txt");
    CHECK(bk_ler_arquivo(p, &buf, &n, err, sizeof err) == BK_OK && n == 0 && buf != NULL && buf[0] == '\0');
    bk_free(buf);

    escrever("bom.txt", "\xEF\xBB\xBF{\"a\":1}");             /* com BOM UTF-8: é pulado */
    caminho_em(p, sizeof p, "bom.txt");
    CHECK(bk_ler_arquivo(p, &buf, &n, err, sizeof err) == BK_OK && n == 7 && strcmp(buf, "{\"a\":1}") == 0);
    bk_free(buf);

    /* acima do limite de 1 MiB: recusado sem ler nada para a memória */
    caminho_em(p, sizeof p, "grande.bin");
    FILE *f = fopen(p, "wb");
    CHECK(f != NULL);
    if (f != NULL) {
        fseek(f, BK_FILE_MAX_BYTES, SEEK_SET);
        fputc('x', f);
        fclose(f);
        CHECK(bk_ler_arquivo(p, &buf, &n, err, sizeof err) == BK_ERR_LIMITE && buf == NULL);
    }

    /* falha de alocação ao ler */
    caminho_em(p, sizeof p, "bom.txt");
    bk_test_falhar_alocacao_apos(0);
    CHECK(bk_ler_arquivo(p, &buf, &n, err, sizeof err) == BK_ERR_MEM && buf == NULL);
    bk_test_falhar_alocacao_apos(-1);

    /* gravação atômica: cria, sobrescreve, não deixa .tmp */
    caminho_em(p, sizeof p, "atomico.json");
    CHECK(bk_gravar_atomico(p, "um", 2, err, sizeof err) == BK_OK);
    CHECK(bk_gravar_atomico(p, "dois", 4, err, sizeof err) == BK_OK);
    char *lido = ler_tudo("atomico.json");
    CHECK(lido != NULL && strcmp(lido, "dois") == 0);
    bk_free(lido);
    CHECK(!arquivo_existe("atomico.json.tmp"));
    /* se o .tmp não puder ser criado (aqui: já existe como PASTA), o destino anterior continua intacto */
    char tmpdir[600];
    snprintf(tmpdir, sizeof tmpdir, "%s.tmp", p);
    CHECK(mkdir(tmpdir, 0700) == 0);
    CHECK(bk_gravar_atomico(p, "tres", 4, err, sizeof err) == BK_ERR_IO);
    lido = ler_tudo("atomico.json");
    CHECK(lido != NULL && strcmp(lido, "dois") == 0);
    bk_free(lido);
    rmdir(tmpdir);
    /* pasta de destino inexistente */
    caminho_em(p, sizeof p, "sem_pasta/x.json");
    CHECK(bk_gravar_atomico(p, "x", 1, err, sizeof err) == BK_ERR_IO);
    CHECK(bk_gravar_atomico(NULL, "x", 1, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_gravar_atomico(p, NULL, 1, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_gravar_atomico("", "x", 1, err, sizeof err) == BK_ERR_ARG);
}

/* ------------------------------------------------------------------ estado (esquema) */
static const char *JSON_BOM =
    "{\"schema_version\":1,\"choice_id\":\"choice_fixed_01\",\"status\":\"ok\","
    "\"metrics\":{\"autonomia\":40,\"conformidade\":55.5,\"dependencia\":12},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":true}";

static void teste_estado(void) {
    char err[BK_ERR_MSG_MAX];
    bk_estado e, antes;
    bk_estado_inicial(&e);
    CHECK(e.schema_version == 1 && e.metricas.autonomia == 50.0 && e.metricas.conformidade == 50.0 && e.metricas.dependencia == 0.0);
    CHECK(strcmp(e.status, "inicial") == 0 && e.choice_id[0] == '\0' && !e.is_placeholder);
    bk_estado_inicial(NULL);                                     /* não quebra */

    /* interpretação válida */
    CHECK(bk_estado_interpretar(JSON_BOM, &e, err, sizeof err) == BK_OK);
    CHECK(strcmp(e.choice_id, "choice_fixed_01") == 0 && e.metricas.autonomia == 40.0 && e.metricas.conformidade == 55.5 && e.is_placeholder);

    /* campos extras são ignorados */
    const char *com_extra =
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"inicial\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3,\"x\":9},"
        "\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false,\"futuro\":{\"a\":1}}";
    CHECK(bk_estado_interpretar(com_extra, &e, err, sizeof err) == BK_OK && e.metricas.dependencia == 3.0);

    /* rejeições de esquema: `e` não pode mudar */
    bk_estado_interpretar(JSON_BOM, &e, err, sizeof err);
    antes = e;
    const char *invalidos[] = {
        "[]",
        "{}",
        "{\"schema_version\":2,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":\"1\",\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"Ruim Demais\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":7,\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"OK!\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":101,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":-0.5,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":1e999},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":\"x\",\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"hoje\",\"is_placeholder\":false}",
        "{\"schema_version\":1,\"choice_id\":\"\",\"status\":\"ok\",\"metrics\":{\"autonomia\":1,\"conformidade\":2,\"dependencia\":3},\"timestamp\":\"2026-11-17T21:00:00Z\",\"is_placeholder\":\"sim\"}",
    };
    for (size_t i = 0; i < sizeof invalidos / sizeof invalidos[0]; i++) {
        bk_status st = bk_estado_interpretar(invalidos[i], &e, err, sizeof err);
        CHECK(st == BK_ERR_ESQUEMA);
        CHECK(memcmp(&e, &antes, sizeof e) == 0);
    }
    CHECK(bk_estado_interpretar("{ nao e json", &e, err, sizeof err) == BK_ERR_JSON);
    CHECK(bk_estado_interpretar("", &e, err, sizeof err) == BK_ERR_JSON);
    CHECK(memcmp(&e, &antes, sizeof e) == 0);
    CHECK(bk_estado_interpretar(NULL, &e, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_estado_interpretar(JSON_BOM, NULL, err, sizeof err) == BK_ERR_ARG);

    /* ida e volta (serializar -> interpretar) */
    bk_estado a;
    bk_estado_inicial(&a);
    (void)bk_copiar(a.choice_id, sizeof a.choice_id, "ficar");
    (void)bk_copiar(a.status, sizeof a.status, "ok");
    (void)bk_copiar(a.timestamp, sizeof a.timestamp, "2026-11-17T21:00:00Z");
    a.metricas.autonomia = 33.33;
    a.metricas.dependencia = 99.5;
    a.is_placeholder = true;
    char *json = NULL;
    CHECK(bk_estado_serializar(&a, &json, err, sizeof err) == BK_OK && json != NULL);
    if (json != NULL) {
        /* o cJSON imprime "chave":<tab>valor; o que importa é o esquema, conferido pela releitura logo abaixo */
        CHECK(strstr(json, "\"schema_version\":\t1") != NULL && strstr(json, "\"metrics\"") != NULL && strstr(json, "\"is_placeholder\":\ttrue") != NULL);
        CHECK(json[strlen(json) - 1] == '\n');
        bk_estado b;
        CHECK(bk_estado_interpretar(json, &b, err, sizeof err) == BK_OK);
        CHECK(strcmp(b.choice_id, "ficar") == 0 && fabs(b.metricas.autonomia - 33.33) < 1e-9 && b.metricas.dependencia == 99.5 && b.is_placeholder);
        bk_free(json);
    }
    /* estado inválido nunca é serializado nem gravado */
    a.metricas.dependencia = 150.0;
    json = (char *)0x1;
    CHECK(bk_estado_serializar(&a, &json, err, sizeof err) == BK_ERR_ESQUEMA && json == NULL);
    char p[512];
    caminho_em(p, sizeof p, "invalido.json");
    CHECK(bk_estado_gravar(p, &a, err, sizeof err) == BK_ERR_ESQUEMA && !arquivo_existe("invalido.json"));
    CHECK(bk_estado_serializar(NULL, &json, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_estado_serializar(&a, NULL, err, sizeof err) == BK_ERR_ARG);
    a.metricas.dependencia = 1.0;
    a.schema_version = 2;
    CHECK(bk_estado_validar(&a, err, sizeof err) == BK_ERR_ESQUEMA);
    CHECK(bk_estado_validar(NULL, err, sizeof err) == BK_ERR_ARG);

    /* gravar e ler de volta pelo arquivo */
    bk_estado_inicial(&a);
    (void)bk_copiar(a.timestamp, sizeof a.timestamp, "2026-11-17T21:00:00Z");
    caminho_em(p, sizeof p, "estado.json");
    CHECK(bk_estado_gravar(p, &a, err, sizeof err) == BK_OK);
    bk_estado lido;
    CHECK(bk_estado_ler(p, &lido, err, sizeof err) == BK_OK && lido.metricas.autonomia == 50.0 && strcmp(lido.status, "inicial") == 0);
    escrever("corrompido.json", "{\"schema_version\":1,");
    caminho_em(p, sizeof p, "corrompido.json");
    CHECK(bk_estado_ler(p, &lido, err, sizeof err) == BK_ERR_JSON);

    /* limites das métricas */
    bk_metricas m = {95.0, 5.0, 0.0};
    bk_metricas_somar(&m, 20.0, -20.0, -1.0);
    CHECK(m.autonomia == 100.0 && m.conformidade == 0.0 && m.dependencia == 0.0);
    bk_metricas_somar(NULL, 1, 1, 1);
}

/* ------------------------------------------------------------------ falhas de alocação em TODO o caminho (sem vazamento) */
static void teste_alocacao(void) {
    char err[BK_ERR_MSG_MAX];
    long base = bk_test_alocacoes_vivas();
    bk_estado a;
    bk_estado_inicial(&a);
    (void)bk_copiar(a.timestamp, sizeof a.timestamp, "2026-11-17T21:00:00Z");
    int falhou = 0, passou = 0;
    for (long n = 0; n < 60; n++) {
        char *json = NULL;
        bk_test_falhar_alocacao_apos(n);
        bk_status st = bk_estado_serializar(&a, &json, err, sizeof err);
        bk_test_falhar_alocacao_apos(-1);
        CHECK(st == BK_OK || st == BK_ERR_MEM);
        CHECK((st == BK_OK) == (json != NULL));
        bk_free(json);
        CHECK(bk_test_alocacoes_vivas() == base);               /* nada vaza, com ou sem falha */
        if (st == BK_ERR_MEM) {
            falhou++;
        } else {
            passou++;
        }
    }
    CHECK(falhou > 0 && passou > 0);                            /* a injeção alcançou o caminho de erro e o de sucesso */

    for (long n = 0; n < 60; n++) {
        bk_estado out;
        bk_test_falhar_alocacao_apos(n);
        bk_status st = bk_estado_interpretar(JSON_BOM, &out, err, sizeof err);
        bk_test_falhar_alocacao_apos(-1);
        CHECK(st == BK_OK || st == BK_ERR_JSON);                /* cJSON não distingue sintaxe de falta de memória */
        CHECK(bk_test_alocacoes_vivas() == base);
    }
    const char *cat_json = "{\"schema_version\":1,\"choices\":[{\"id\":\"a\"},{\"id\":\"b\",\"autonomia\":1}]}";
    for (long n = 0; n < 60; n++) {
        bk_catalogo *cat = (bk_catalogo *)malloc(sizeof *cat);
        CHECK(cat != NULL);
        if (cat == NULL) {
            continue;
        }
        bk_test_falhar_alocacao_apos(n);
        bk_status st = bk_catalogo_interpretar(cat_json, cat, err, sizeof err);
        bk_test_falhar_alocacao_apos(-1);
        CHECK(st == BK_OK || st == BK_ERR_JSON);
        CHECK(bk_test_alocacoes_vivas() == base);
        free(cat);
    }
}

/* ------------------------------------------------------------------ catálogo */
static void teste_catalogo(void) {
    char err[BK_ERR_MSG_MAX];
    bk_catalogo *cat = (bk_catalogo *)malloc(sizeof *cat);
    CHECK(cat != NULL);
    if (cat == NULL) {
        return;
    }
    memset(cat, 0, sizeof *cat);
    CHECK(bk_catalogo_interpretar("{\"schema_version\":1,\"choices\":[{\"id\":\"a\"},{\"id\":\"b_2\",\"status\":\"feito\",\"autonomia\":-5,\"conformidade\":2.5,\"dependencia\":100,\"is_placeholder\":true}]}", cat, err, sizeof err) == BK_OK);
    CHECK(cat->n == 2 && strcmp(cat->itens[0].status, "ok") == 0 && cat->itens[0].d_autonomia == 0.0 && !cat->itens[0].is_placeholder);
    CHECK(cat->itens[1].d_autonomia == -5.0 && cat->itens[1].d_conformidade == 2.5 && cat->itens[1].d_dependencia == 100.0 && cat->itens[1].is_placeholder);
    CHECK(bk_catalogo_buscar(cat, "b_2") == &cat->itens[1]);
    CHECK(bk_catalogo_buscar(cat, "nao_tem") == NULL);
    CHECK(bk_catalogo_buscar(cat, NULL) == NULL && bk_catalogo_buscar(NULL, "a") == NULL);

    const char *invalidos[] = {
        "[]", "{}", "{\"schema_version\":1}", "{\"schema_version\":1,\"choices\":{}}",
        "{\"schema_version\":2,\"choices\":[]}",
        "{\"schema_version\":1,\"choices\":[1]}",
        "{\"schema_version\":1,\"choices\":[{}]}",
        "{\"schema_version\":1,\"choices\":[{\"id\":\"Maiuscula\"}]}",
        "{\"schema_version\":1,\"choices\":[{\"id\":\"a\"},{\"id\":\"a\"}]}",
        "{\"schema_version\":1,\"choices\":[{\"id\":\"a\",\"autonomia\":101}]}",
        "{\"schema_version\":1,\"choices\":[{\"id\":\"a\",\"conformidade\":\"x\"}]}",
        "{\"schema_version\":1,\"choices\":[{\"id\":\"a\",\"status\":\"Nao Pode\"}]}",
        "{\"schema_version\":1,\"choices\":[{\"id\":\"a\",\"is_placeholder\":1}]}",
    };
    size_t antes_n = cat->n;
    for (size_t i = 0; i < sizeof invalidos / sizeof invalidos[0]; i++) {
        CHECK(bk_catalogo_interpretar(invalidos[i], cat, err, sizeof err) == BK_ERR_ESQUEMA);
        CHECK(cat->n == antes_n);                               /* só é alterado em caso de sucesso */
    }
    CHECK(bk_catalogo_interpretar("{ x", cat, err, sizeof err) == BK_ERR_JSON);
    CHECK(bk_catalogo_interpretar(NULL, cat, err, sizeof err) == BK_ERR_ARG);
    CHECK(bk_catalogo_interpretar("{}", NULL, err, sizeof err) == BK_ERR_ARG);

    /* mais escolhas do que o limite */
    size_t cap = 64 + (size_t)(BK_CATALOGO_MAX + 2) * 24;
    char *grande = (char *)malloc(cap);
    CHECK(grande != NULL);
    if (grande != NULL) {
        size_t pos = (size_t)snprintf(grande, cap, "{\"schema_version\":1,\"choices\":[");
        for (int i = 0; i < BK_CATALOGO_MAX + 1; i++) {
            pos += (size_t)snprintf(grande + pos, cap - pos, "%s{\"id\":\"c%d\"}", i == 0 ? "" : ",", i);
        }
        snprintf(grande + pos, cap - pos, "]}");
        CHECK(bk_catalogo_interpretar(grande, cat, err, sizeof err) == BK_ERR_LIMITE);
        free(grande);
    }

    /* o catálogo REAL do projeto carrega e tem os 4 IDs de espaço reservado + as 6 escolhas da história */
    CHECK(bk_catalogo_carregar(BK_CHOICES_PATH, cat, err, sizeof err) == BK_OK);
    const char *esperados[] = {"choice_fixed_01", "choice_fixed_02", "choice_fixed_03", "choice_injected", "ok", "sozinho", "usar", "propria", "ficar", "recusar"};
    for (size_t i = 0; i < sizeof esperados / sizeof esperados[0]; i++) {
        CHECK(bk_catalogo_buscar(cat, esperados[i]) != NULL);
    }
    CHECK(bk_catalogo_buscar(cat, "choice_injected") != NULL && bk_catalogo_buscar(cat, "choice_injected")->is_placeholder);
    free(cat);
}

/* ------------------------------------------------------------------ --choice ponta a ponta */
static bk_status comando(const char *escolha, const char *saida, bool reset, bk_estado *r) {
    bk_args a;
    memset(&a, 0, sizeof a);
    a.tem_escolha = escolha != NULL;
    if (escolha != NULL) {
        (void)bk_copiar(a.escolha, sizeof a.escolha, escolha);
    }
    a.tem_saida = true;
    (void)bk_copiar(a.saida, sizeof a.saida, saida);
    a.tem_catalogo = true;
    (void)bk_copiar(a.catalogo, sizeof a.catalogo, BK_CHOICES_PATH);
    a.tem_timestamp = true;
    (void)bk_copiar(a.timestamp, sizeof a.timestamp, "2026-11-17T21:00:00Z");
    a.reiniciar = reset;
    char err[BK_ERR_MSG_MAX];
    return bk_comando_escolha(&a, r, NULL, 0, err, sizeof err);
}

static void teste_comando(void) {
    char out[512], err[BK_ERR_MSG_MAX];
    bk_estado r;
    caminho_em(out, sizeof out, "run.json");

    CHECK(comando("ok", out, false, &r) == BK_OK);                          /* (50,50,0) + (-3,+2,+4) */
    CHECK(r.metricas.autonomia == 47.0 && r.metricas.conformidade == 52.0 && r.metricas.dependencia == 4.0);
    CHECK(strcmp(r.choice_id, "ok") == 0 && !r.is_placeholder && strcmp(r.timestamp, "2026-11-17T21:00:00Z") == 0);
    bk_estado lido;
    CHECK(bk_estado_ler(out, &lido, err, sizeof err) == BK_OK && memcmp(&lido, &r, sizeof lido) == 0);   /* gravou exatamente isso */
    CHECK(!arquivo_existe("run.json.tmp"));

    CHECK(comando("ficar", out, false, &r) == BK_OK);                       /* continua do estado gravado */
    CHECK(r.metricas.autonomia == 37.0 && r.metricas.conformidade == 58.0 && r.metricas.dependencia == 14.0);

    for (int i = 0; i < 12; i++) {                                           /* limites: AUT não passa de 0, DEP não passa de 100 */
        CHECK(comando("ficar", out, false, &r) == BK_OK);
    }
    CHECK(r.metricas.autonomia == 0.0 && r.metricas.dependencia == 100.0 && r.metricas.conformidade <= 100.0);

    /* --reset parte do zero (50/50/0), ignorando o estado de antes (AUT 0, DEP 100). O placeholder injetado não mexe nas métricas, como a
     * escolha de mesmo id em conversas.json (que não tem "metricas"); tools/testar_backend.py confere esse espelho. */
    CHECK(comando("choice_injected", out, true, &r) == BK_OK);
    CHECK(r.metricas.autonomia == 50.0 && r.metricas.conformidade == 50.0 && r.metricas.dependencia == 0.0 && r.is_placeholder);
    CHECK(comando("choice_fixed_01", out, false, &r) == BK_OK && r.is_placeholder && r.metricas.autonomia == 50.0);
    CHECK(comando("ok", out, true, &r) == BK_OK);                            /* uma escolha de verdade aplica os deltas do catálogo */
    CHECK(r.metricas.autonomia == 47.0 && r.metricas.conformidade == 52.0 && r.metricas.dependencia == 4.0 && !r.is_placeholder);

    /* id desconhecido (formato válido): nada é criado */
    char out2[512];
    caminho_em(out2, sizeof out2, "naocria.json");
    CHECK(comando("nao_existe_no_catalogo", out2, false, &r) == BK_ERR_ID_DESCONHECIDO && !arquivo_existe("naocria.json"));
    /* id com formato inválido chegando direto à função (defesa em profundidade) */
    CHECK(comando("A;ls", out2, false, &r) == BK_ERR_ID_FORMATO && !arquivo_existe("naocria.json"));
    CHECK(comando(NULL, out2, false, &r) == BK_ERR_ARG);

    /* estado existente e corrompido NÃO é sobrescrito em silêncio */
    escrever("ruim.json", "isto nao e json");
    char ruim[512];
    caminho_em(ruim, sizeof ruim, "ruim.json");
    CHECK(comando("ok", ruim, false, &r) == BK_ERR_JSON);
    char *conteudo = ler_tudo("ruim.json");
    CHECK(conteudo != NULL && strcmp(conteudo, "isto nao e json") == 0);
    bk_free(conteudo);
    CHECK(comando("ok", ruim, true, &r) == BK_OK && bk_estado_ler(ruim, &lido, err, sizeof err) == BK_OK);   /* --reset recria */

    /* pasta de saída inexistente e catálogo ausente */
    char sem[512];
    caminho_em(sem, sizeof sem, "nao/existe/x.json");
    CHECK(comando("ok", sem, false, &r) == BK_ERR_IO);
    bk_args a;
    memset(&a, 0, sizeof a);
    a.tem_escolha = true;
    (void)bk_copiar(a.escolha, sizeof a.escolha, "ok");
    a.tem_catalogo = true;
    caminho_em(a.catalogo, sizeof a.catalogo, "catalogo_que_nao_existe.json");
    CHECK(bk_comando_escolha(&a, NULL, NULL, 0, err, sizeof err) == BK_ERR_IO);
    CHECK(bk_comando_escolha(NULL, NULL, NULL, 0, err, sizeof err) == BK_ERR_ARG);

    /* caminho padrão pela variável de ambiente */
    bk_args b;
    memset(&b, 0, sizeof b);
    char padrao[BK_PATH_MAX];
    setenv("MAYA_USER_DIR", g_dir, 1);
    CHECK(bk_caminho_do_estado(&b, padrao, sizeof padrao, err, sizeof err) == BK_OK && strstr(padrao, "estado_jogo.json") != NULL && strncmp(padrao, g_dir, strlen(g_dir)) == 0);
    unsetenv("MAYA_USER_DIR");
    CHECK(bk_caminho_do_estado(&b, padrao, sizeof padrao, err, sizeof err) == BK_OK && strcmp(padrao, "estado_jogo.json") == 0);
    CHECK(bk_caminho_do_estado(NULL, padrao, sizeof padrao, err, sizeof err) == BK_ERR_ARG);
    char pequeno[8];
    b.tem_saida = true;
    (void)bk_copiar(b.saida, sizeof b.saida, "um_caminho_maior_que_o_buffer.json");
    CHECK(bk_caminho_do_estado(&b, pequeno, sizeof pequeno, err, sizeof err) == BK_ERR_LIMITE);

    /* falhas de alocação no fluxo inteiro: ou conclui, ou devolve BK_ERR_MEM/BK_ERR_JSON, sem vazar e sem corromper o arquivo */
    long base = bk_test_alocacoes_vivas();
    char alvo[512];
    caminho_em(alvo, sizeof alvo, "alocacao.json");
    for (long n = 0; n < 80; n++) {
        bk_test_falhar_alocacao_apos(n);
        bk_status st = comando("ok", alvo, true, &r);
        bk_test_falhar_alocacao_apos(-1);
        CHECK(st == BK_OK || st == BK_ERR_MEM || st == BK_ERR_JSON);
        CHECK(bk_test_alocacoes_vivas() == base);
        if (arquivo_existe("alocacao.json")) {
            CHECK(bk_estado_ler(alvo, &lido, err, sizeof err) == BK_OK);      /* o que existe é sempre um estado válido */
        }
        CHECK(!arquivo_existe("alocacao.json.tmp"));
    }
}

/* ------------------------------------------------------------------ modo interativo: carregador e entrada (EOF-safe) */
static int g_stdout_salvo = -1;
static void silenciar_stdout(void) {
    fflush(stdout);
    g_stdout_salvo = dup(1);
    if (freopen("/dev/null", "w", stdout) == NULL) {
        fprintf(stderr, "aviso: nao foi possivel silenciar stdout\n");
    }
}
static void restaurar_stdout(void) {
    fflush(stdout);
    if (g_stdout_salvo >= 0) {
        dup2(g_stdout_salvo, 1);
        close(g_stdout_salvo);
        g_stdout_salvo = -1;
    }
    clearerr(stdout);
}
static void stdin_de(const char *nome) {
    char p[512];
    caminho_em(p, sizeof p, nome);
    if (freopen(p, "r", stdin) == NULL) {
        fprintf(stderr, "aviso: nao foi possivel redirecionar stdin\n");
    }
}

static void teste_interativo(void) {
    char err[BK_ERR_MSG_MAX];
    Turn t;
    cJSON *j;

    /* turno válido: "delegated" como 0/1 ou true/false */
    j = cJSON_Parse("{\"messages\":[{\"id\":1,\"timestamp\":\"09:00\",\"sender\":\"Maya\",\"text\":\"oi\"}],"
                    "\"choices\":[{\"choice_id\":1,\"text\":\"a\",\"autonomy_impact\":-5,\"delegated\":1,\"nexus_reply\":\"r\"},"
                    "{\"choice_id\":2,\"text\":\"b\",\"autonomy_impact\":5,\"delegated\":false,\"nexus_reply\":\"r2\"}]}");
    CHECK(j != NULL);
    CHECK(carregar_turno(j, &t, err, sizeof err) == BK_OK && t.message_count == 1 && t.choice_count == 2 && t.choices[0].delegated && !t.choices[1].delegated);
    cJSON_Delete(j);

    /* texto grande demais NÃO estoura o buffer: é recusado (ASan confirma que nada foi escrito fora) */
    char *enorme = (char *)malloc(2000);
    CHECK(enorme != NULL);
    if (enorme != NULL) {
        memset(enorme, 'A', 1999);
        enorme[1999] = '\0';
        char *js = (char *)malloc(4000);
        CHECK(js != NULL);
        if (js != NULL) {
            snprintf(js, 4000, "{\"messages\":[{\"id\":1,\"timestamp\":\"09:00\",\"sender\":\"Maya\",\"text\":\"%s\"}],\"choices\":[]}", enorme);
            j = cJSON_Parse(js);
            CHECK(j != NULL && carregar_turno(j, &t, err, sizeof err) == BK_ERR_LIMITE);
            cJSON_Delete(j);
            snprintf(js, 4000, "{\"messages\":[{\"id\":1,\"timestamp\":\"%s\",\"sender\":\"M\",\"text\":\"x\"}],\"choices\":[]}", "12345678901");   /* 11 > 9 */
            j = cJSON_Parse(js);
            CHECK(j != NULL && carregar_turno(j, &t, err, sizeof err) == BK_ERR_LIMITE);
            cJSON_Delete(j);
            free(js);
        }
        free(enorme);
    }
    /* mais mensagens/escolhas que o máximo */
    char lista[2048];
    size_t pos = (size_t)snprintf(lista, sizeof lista, "{\"messages\":[");
    for (int i = 0; i < MAX_MESSAGES + 1; i++) {
        pos += (size_t)snprintf(lista + pos, sizeof lista - pos, "%s{\"id\":%d,\"timestamp\":\"t\",\"sender\":\"s\",\"text\":\"x\"}", i == 0 ? "" : ",", i);
    }
    snprintf(lista + pos, sizeof lista - pos, "],\"choices\":[]}");
    j = cJSON_Parse(lista);
    CHECK(j != NULL && carregar_turno(j, &t, err, sizeof err) == BK_ERR_LIMITE);
    cJSON_Delete(j);
    pos = (size_t)snprintf(lista, sizeof lista, "{\"messages\":[],\"choices\":[");
    for (int i = 0; i < MAX_CHOICES + 1; i++) {
        pos += (size_t)snprintf(lista + pos, sizeof lista - pos, "%s{\"choice_id\":%d,\"text\":\"x\",\"autonomy_impact\":0,\"delegated\":0,\"nexus_reply\":\"y\"}", i == 0 ? "" : ",", i);
    }
    snprintf(lista + pos, sizeof lista - pos, "]}");
    j = cJSON_Parse(lista);
    CHECK(j != NULL && carregar_turno(j, &t, err, sizeof err) == BK_ERR_LIMITE);
    cJSON_Delete(j);
    /* campos ausentes / tipo errado / nulos */
    j = cJSON_Parse("{\"messages\":[{\"id\":1}],\"choices\":[]}");
    CHECK(j != NULL && carregar_turno(j, &t, err, sizeof err) == BK_ERR_ESQUEMA);
    cJSON_Delete(j);
    j = cJSON_Parse("{\"messages\":{},\"choices\":[]}");
    CHECK(j != NULL && carregar_turno(j, &t, err, sizeof err) == BK_ERR_ESQUEMA);
    cJSON_Delete(j);
    j = cJSON_Parse("{\"messages\":[],\"choices\":[{\"choice_id\":1.5,\"text\":\"x\",\"autonomy_impact\":0,\"delegated\":0,\"nexus_reply\":\"y\"}]}");
    CHECK(j != NULL && carregar_turno(j, &t, err, sizeof err) == BK_ERR_ESQUEMA);
    cJSON_Delete(j);
    CHECK(carregar_turno(NULL, &t, err, sizeof err) == BK_ERR_ARG);

    /* executar_jogo */
    GameState g;
    memset(&g, 0, sizeof g);
    g.autonomia = 100;
    char p[512];
    caminho_em(p, sizeof p, "nao_existe_roteiro.json");
    CHECK(executar_jogo(p, &g, err, sizeof err) == BK_ERR_IO);
    CHECK(executar_jogo(NULL, &g, err, sizeof err) == BK_ERR_ARG);
    CHECK(executar_jogo(p, NULL, err, sizeof err) == BK_ERR_ARG);
    escrever("roteiro_ruim.json", "{ nao");
    caminho_em(p, sizeof p, "roteiro_ruim.json");
    CHECK(executar_jogo(p, &g, err, sizeof err) == BK_ERR_JSON);
    escrever("roteiro_acts.json", "{\"meta\":{},\"acts\":[]}");
    caminho_em(p, sizeof p, "roteiro_acts.json");
    CHECK(executar_jogo(p, &g, err, sizeof err) == BK_ERR_ESQUEMA && strstr(err, "acts/nodes") != NULL);
    escrever("roteiro_ok.json",
             "{\"days\":[{\"day_number\":1,\"act\":1,\"act_title\":\"Ato\",\"scene_title\":\"Cena\",\"turns\":[{\"messages\":[{\"id\":1,\"timestamp\":\"09:00\",\"sender\":\"Maya\",\"text\":\"oi\"}],"
             "\"choices\":[{\"choice_id\":1,\"text\":\"a\",\"autonomy_impact\":-30,\"delegated\":1,\"nexus_reply\":\"r\"},{\"choice_id\":2,\"text\":\"b\",\"autonomy_impact\":5,\"delegated\":0,\"nexus_reply\":\"r2\"}]}]}]}");
    caminho_em(p, sizeof p, "roteiro_ok.json");

    /* entrada já em EOF: o jogo termina com erro de E/S em vez de ficar num laço infinito */
    silenciar_stdout();
    escrever("vazio_stdin.txt", "");
    stdin_de("vazio_stdin.txt");
    g.autonomia = 100;
    bk_status st = executar_jogo(p, &g, err, sizeof err);
    restaurar_stdout();
    CHECK(st == BK_ERR_IO);

    /* entrada roteirizada: ENTER, ENTER, ENTER (cabeçalhos), mensagem; depois "7" e "abc" (inválidos) e "1" (válida); ENTER, ENTER */
    escrever("entrada.txt", "\n\n\n7\nabc\n1\n\n\n");
    silenciar_stdout();
    stdin_de("entrada.txt");
    g.autonomia = 100;
    st = executar_jogo(p, &g, err, sizeof err);
    restaurar_stdout();
    CHECK(st == BK_OK);
    CHECK(g.autonomia == 70);                          /* 100 + (-30) */
    CHECK(g.current_day == 1 && g.current_act == 1 && strcmp(g.scene_title, "Cena") == 0);

    /* ui_ler_inteiro */
    escrever("numeros.txt", "abc\n99\n  \n2\n");
    stdin_de("numeros.txt");
    int v = 0;
    CHECK(ui_ler_inteiro(1, 3, &v) == BK_ERR_ARG);
    CHECK(ui_ler_inteiro(1, 3, &v) == BK_ERR_ARG);
    CHECK(ui_ler_inteiro(1, 3, &v) == BK_ERR_ARG);
    CHECK(ui_ler_inteiro(1, 3, &v) == BK_OK && v == 2);
    CHECK(ui_ler_inteiro(1, 3, &v) == BK_ERR_IO);      /* fim da entrada */
    CHECK(ui_ler_inteiro(1, 3, NULL) == BK_ERR_ARG);
    /* linha maior que o buffer é descartada sem estourar nada */
    char *longa = (char *)malloc(5000);
    CHECK(longa != NULL);
    if (longa != NULL) {
        memset(longa, '7', 4999);
        longa[4999] = '\0';
        char conteudo[5100];
        snprintf(conteudo, sizeof conteudo, "%s\n1\n", longa);
        escrever("longa.txt", conteudo);
        stdin_de("longa.txt");
        CHECK(ui_ler_inteiro(1, 3, &v) == BK_ERR_ARG);
        CHECK(ui_ler_inteiro(1, 3, &v) == BK_OK && v == 1);
        free(longa);
    }
    char linha[8];
    CHECK(!ui_ler_linha(NULL, 8) && !ui_ler_linha(linha, 1));
    CHECK(executar_turno(NULL, &t) == BK_ERR_ARG && executar_turno(&g, NULL) == BK_ERR_ARG);
}

int main(void) {
    bk_cjson_instalar_hooks();
    snprintf(g_dir, sizeof g_dir, "%s/maya_bk_XXXXXX", getenv("TMPDIR") != NULL && getenv("TMPDIR")[0] != '\0' ? getenv("TMPDIR") : "/tmp");
    if (mkdtemp(g_dir) == NULL) {
        fprintf(stderr, "nao foi possivel criar a pasta temporaria\n");
        return 2;
    }
    teste_comum();
    teste_argumentos();
    teste_arquivos();
    teste_estado();
    teste_alocacao();
    teste_catalogo();
    teste_comando();
    teste_interativo();
    /* limpeza da pasta temporária (só arquivos que os testes criaram) */
    char cmd_dir[300];
    snprintf(cmd_dir, sizeof cmd_dir, "%s", g_dir);
    const char *nomes[] = {"vazio.txt", "bom.txt", "grande.bin", "atomico.json", "estado.json", "corrompido.json", "run.json", "ruim.json",
                           "alocacao.json", "roteiro_ruim.json", "roteiro_acts.json", "roteiro_ok.json", "vazio_stdin.txt", "entrada.txt",
                           "numeros.txt", "longa.txt"};
    for (size_t i = 0; i < sizeof nomes / sizeof nomes[0]; i++) {
        char p[512];
        caminho_em(p, sizeof p, nomes[i]);
        remove(p);
    }
    rmdir(cmd_dir);
    fprintf(stderr, "RESULTADO C: %d verificacoes, %d falhas.\n", g_checks, g_falhas);
    return g_falhas == 0 ? 0 : 1;
}
