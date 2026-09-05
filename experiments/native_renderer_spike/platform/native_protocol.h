#ifndef BLAZEX_NATIVE_PROTOCOL_H
#define BLAZEX_NATIVE_PROTOCOL_H

#include <stddef.h>

#define BX_MAX_NODES 128
#define BX_MAX_TEXT 4096
#define BX_MAX_ERROR 256

typedef struct {
  int depth;
  int children;
  char id[64];
  char kind[32];
  char text[BX_MAX_TEXT + 1];
  char role[32];
  char name[BX_MAX_TEXT + 1];
  char states[BX_MAX_TEXT + 1];
  char relationships[BX_MAX_TEXT + 1];
  char layout[32];
  char focus[BX_MAX_TEXT + 1];
  char selection[BX_MAX_TEXT + 1];
  char listeners[BX_MAX_TEXT + 1];
} BxNativeNode;

typedef struct {
  int generation;
  int revision;
  char transition[16];
  char digest[65];
  size_t node_count;
  BxNativeNode nodes[BX_MAX_NODES];
} BxNativeBatch;

int bx_read_batch(const char *path, BxNativeBatch *batch, char error[BX_MAX_ERROR]);
int bx_is_next_update(const BxNativeBatch *current, const BxNativeBatch *candidate);

#endif
