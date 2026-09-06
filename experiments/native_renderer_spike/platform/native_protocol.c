#include "native_protocol.h"

#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int split_tabs(char *line, char **fields, int maximum) {
  int count = 0;
  char *cursor = line;
  while (count < maximum) {
    fields[count++] = cursor;
    char *tab = strchr(cursor, '\t');
    if (tab == NULL) break;
    *tab = '\0';
    cursor = tab + 1;
  }
  return count;
}

static int hex_digit(char value) {
  if (value >= '0' && value <= '9') return value - '0';
  if (value >= 'a' && value <= 'f') return value - 'a' + 10;
  return -1;
}

static int valid_hex(const char *value, size_t maximum_bytes) {
  size_t length = strlen(value);
  if (length % 2 != 0 || length / 2 > maximum_bytes) return 0;
  for (size_t index = 0; index < length; ++index)
    if (hex_digit(value[index]) < 0) return 0;
  return 1;
}

static int parse_nonnegative(const char *value, int *result) {
  char *end = NULL;
  errno = 0;
  long parsed = strtol(value, &end, 10);
  if (errno != 0 || end == value || *end != '\0' || parsed < 0 || parsed > INT_MAX) return 0;
  *result = (int)parsed;
  return 1;
}

static int decode_hex(const char *source, char *target, size_t maximum) {
  size_t length = strlen(source);
  if (length % 2 != 0 || length / 2 > maximum) return 0;
  for (size_t index = 0; index < length; index += 2) {
    int high = hex_digit(source[index]);
    int low = hex_digit(source[index + 1]);
    if (high < 0 || low < 0) return 0;
    target[index / 2] = (char)((high << 4) | low);
  }
  target[length / 2] = '\0';
  return 1;
}

static int valid_kind(const char *kind) {
  static const char *kinds[] = {"text", "group", "action", "field", "selection", "collection", "surface"};
  for (size_t index = 0; index < sizeof(kinds) / sizeof(kinds[0]); ++index) {
    if (strcmp(kind, kinds[index]) == 0) return 1;
  }
  return 0;
}

static int valid_role(const char *role) {
  static const char *roles[] = {"none", "generic", "text", "group", "button", "text_field",
                                "checkbox", "list", "list_item", "dialog", "status"};
  for (size_t index = 0; index < sizeof(roles) / sizeof(roles[0]); ++index)
    if (strcmp(role, roles[index]) == 0) return 1;
  return 0;
}

static int valid_transition(const char *transition) {
  return strcmp(transition, "mount") == 0 || strcmp(transition, "update") == 0 ||
         strcmp(transition, "replace") == 0 || strcmp(transition, "dispose") == 0;
}

static int consume_tree(const BxNativeBatch *batch, size_t index, int depth, size_t *next) {
  if (index >= batch->node_count || batch->nodes[index].depth != depth) return 0;
  size_t cursor = index + 1;
  for (int child = 0; child < batch->nodes[index].children; ++child) {
    if (!consume_tree(batch, cursor, depth + 1, &cursor)) return 0;
  }
  *next = cursor;
  return 1;
}

static int valid_tree(const BxNativeBatch *batch) {
  if (batch->node_count == 0 || strcmp(batch->nodes[0].kind, "surface") != 0) return 0;
  for (size_t left = 0; left < batch->node_count; ++left) {
    if (batch->nodes[left].id[0] == '\0') return 0;
    for (size_t right = left + 1; right < batch->node_count; ++right)
      if (strcmp(batch->nodes[left].id, batch->nodes[right].id) == 0) return 0;
  }
  size_t next = 0;
  return consume_tree(batch, 0, 0, &next) && next == batch->node_count;
}

static void fail(char error[BX_MAX_ERROR], const char *message) {
  snprintf(error, BX_MAX_ERROR, "%s", message);
}

int bx_read_batch(const char *path, BxNativeBatch *batch, char error[BX_MAX_ERROR]) {
  error[0] = '\0';
  FILE *file = fopen(path, "rb");
  if (file == NULL) { fail(error, "cannot-open-batch"); return 0; }
  memset(batch, 0, sizeof(*batch));
  char line[65536];
  if (fgets(line, sizeof(line), file) == NULL) { fclose(file); fail(error, "missing-header"); return 0; }
  line[strcspn(line, "\r\n")] = '\0';
  char *header[6];
  if (split_tabs(line, header, 6) != 6 || strcmp(header[0], "BXN1") != 0 ||
      strlen(header[4]) != 64 || !valid_hex(header[4], 32) || !valid_hex(header[5], BX_MAX_TEXT)) {
    fclose(file); fail(error, "invalid-header"); return 0;
  }
  if (strlen(header[3]) >= sizeof(batch->transition) ||
      strlen(header[4]) >= sizeof(batch->digest)) {
    fclose(file); fail(error, "oversized-header"); return 0;
  }
  if (!parse_nonnegative(header[1], &batch->generation) || batch->generation == 0 ||
      !parse_nonnegative(header[2], &batch->revision) || !valid_transition(header[3])) {
    fclose(file); fail(error, "invalid-header-values"); return 0;
  }
  snprintf(batch->transition, sizeof(batch->transition), "%s", header[3]);
  snprintf(batch->digest, sizeof(batch->digest), "%s", header[4]);

  int saw_end = 0;
  while (fgets(line, sizeof(line), file) != NULL) {
    line[strcspn(line, "\r\n")] = '\0';
    if (strcmp(line, "END") == 0) { saw_end = 1; break; }
    if (batch->node_count == BX_MAX_NODES) { fail(error, "node-limit"); break; }
    char *fields[14];
    if (split_tabs(line, fields, 14) != 14 || strcmp(fields[0], "NODE") != 0 ||
        !valid_kind(fields[3]) || !valid_role(fields[5]) ||
        (strcmp(fields[9], "none") != 0 && strcmp(fields[9], "stack") != 0)) {
      fail(error, "invalid-node"); break;
    }
    BxNativeNode *node = &batch->nodes[batch->node_count];
    if (strlen(fields[2]) >= sizeof(node->id) || strlen(fields[3]) >= sizeof(node->kind) ||
        strlen(fields[5]) >= sizeof(node->role) || strlen(fields[9]) >= sizeof(node->layout)) {
      fail(error, "oversized-node-field"); break;
    }
    if (!parse_nonnegative(fields[1], &node->depth) ||
        !parse_nonnegative(fields[13], &node->children) || node->depth > 32 ||
        (batch->node_count == 0 && node->depth != 0) ||
        (batch->node_count > 0 && node->depth > batch->nodes[batch->node_count - 1].depth + 1)) {
      fail(error, "invalid-tree-depth"); break;
    }
    snprintf(node->id, sizeof(node->id), "%s", fields[2]);
    snprintf(node->kind, sizeof(node->kind), "%s", fields[3]);
    snprintf(node->role, sizeof(node->role), "%s", fields[5]);
    snprintf(node->layout, sizeof(node->layout), "%s", fields[9]);
    if (!decode_hex(fields[4], node->text, BX_MAX_TEXT) ||
        !decode_hex(fields[6], node->name, BX_MAX_TEXT) ||
        !decode_hex(fields[7], node->states, BX_MAX_TEXT) ||
        !decode_hex(fields[8], node->relationships, BX_MAX_TEXT) ||
        !decode_hex(fields[10], node->focus, BX_MAX_TEXT) ||
        !decode_hex(fields[11], node->selection, BX_MAX_TEXT) ||
        !decode_hex(fields[12], node->listeners, BX_MAX_TEXT)) {
      fail(error, "invalid-hex"); break;
    }
    batch->node_count += 1;
  }
  if (saw_end) {
    while (fgets(line, sizeof(line), file) != NULL) {
      line[strcspn(line, "\r\n")] = '\0';
      if (line[0] != '\0') { fail(error, "trailing-record"); break; }
    }
  }
  fclose(file);
  if (!saw_end || error[0] != '\0') return 0;
  if (strcmp(batch->transition, "dispose") == 0) {
    if (batch->node_count != 0) { fail(error, "dispose-with-tree"); return 0; }
  } else if (!valid_tree(batch)) {
    fail(error, "invalid-tree"); return 0;
  }
  return 1;
}

int bx_is_next_update(const BxNativeBatch *current, const BxNativeBatch *candidate) {
  return strcmp(candidate->transition, "update") == 0 &&
         candidate->generation == current->generation &&
         candidate->revision == current->revision + 1;
}
