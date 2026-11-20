#ifndef JSON_LOADER_H
#define JSON_LOADER_H
#include "bk_common.h"
#include "game.h"

/* Carrega o roteiro `json_filename` (formato "days"/"turns") e o executa no console, atualizando `jogo`.
 * Devolve BK_OK, BK_ERR_IO (arquivo ou fim da entrada), BK_ERR_JSON, BK_ERR_ESQUEMA (campo ausente ou do tipo errado),
 * BK_ERR_LIMITE (valor que não cabe no buffer ou lista maior que o máximo) ou BK_ERR_MEM. A mensagem vai em `err`. */
bk_status executar_jogo(const char *json_filename, GameState *jogo, char *err, size_t cap);

/* Só a leitura de UM turno do JSON para a estrutura (exposta para os testes nativos). */
struct cJSON;
bk_status carregar_turno(const struct cJSON *turno_json, Turn *out, char *err, size_t cap);

#endif
