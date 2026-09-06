#include "native_protocol.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef void GtkWidget;
typedef void GtkWindow;
typedef void GtkBox;
typedef void GtkListBox;
typedef void GtkListBoxRow;
typedef void GtkEditable;
typedef unsigned long GType;
typedef int gboolean;
typedef void *gpointer;
typedef void (*GCallback)(void);

extern void gtk_init(void);
extern GtkWidget *gtk_window_new(void);
extern void gtk_window_set_child(GtkWindow *, GtkWidget *);
extern void gtk_window_present(GtkWindow *);
extern void gtk_window_destroy(GtkWindow *);
extern GtkWidget *gtk_box_new(int, int);
extern void gtk_box_append(GtkBox *, GtkWidget *);
extern GtkWidget *gtk_label_new(const char *);
extern GtkWidget *gtk_button_new_with_label(const char *);
extern GtkWidget *gtk_entry_new(void);
extern void gtk_editable_set_text(GtkEditable *, const char *);
extern const char *gtk_editable_get_text(GtkEditable *);
extern void gtk_editable_select_region(GtkEditable *, int, int);
extern gboolean gtk_editable_get_selection_bounds(GtkEditable *, int *, int *);
extern GtkWidget *gtk_check_button_new_with_label(const char *);
extern void gtk_check_button_set_active(void *, gboolean);
extern gboolean gtk_check_button_get_active(void *);
extern GtkWidget *gtk_list_box_new(void);
extern void gtk_list_box_append(GtkListBox *, GtkWidget *);
extern GtkListBoxRow *gtk_list_box_get_row_at_index(GtkListBox *, int);
extern void gtk_list_box_select_row(GtkListBox *, GtkListBoxRow *);
extern GtkListBoxRow *gtk_list_box_get_selected_row(GtkListBox *);
extern gboolean gtk_widget_grab_focus(GtkWidget *);
extern gboolean gtk_widget_activate(GtkWidget *);
extern GtkWidget *gtk_root_get_focus(void *);
extern void gtk_root_set_focus(void *, GtkWidget *);
extern int gtk_accessible_get_accessible_role(void *);
extern GType gtk_accessible_role_get_type(void);
extern gpointer gtk_file_dialog_new(void);
extern unsigned long g_signal_connect_data(gpointer, const char *, GCallback, gpointer, void (*)(gpointer, void *), int);
extern void g_signal_emit_by_name(gpointer, const char *, ...);
extern const char *g_type_name_from_instance(void *);
extern char *g_enum_to_string(GType, int);
extern void g_free(gpointer);
extern void g_object_unref(gpointer);
extern gboolean g_main_context_iteration(gpointer, gboolean);

typedef struct {
  GtkWidget *widgets[BX_MAX_NODES];
  BxNativeBatch batch;
  int action_events;
  int change_events;
  int selection_events;
  int disposal_count;
  int disposed;
} GtkSpike;

static void on_action(void *widget, gpointer data) { (void)widget; ((GtkSpike *)data)->action_events += 1; }
static void on_change(void *widget, gpointer data) { (void)widget; ((GtkSpike *)data)->change_events += 1; }
static void on_selection(void *widget, gpointer data) { (void)widget; ((GtkSpike *)data)->selection_events += 1; }
static void on_list_selection(void *widget, void *row, gpointer data) {
  (void)widget;
  (void)row;
  ((GtkSpike *)data)->selection_events += 1;
}

static GtkWidget *make_widget(const BxNativeNode *node) {
  const char *label = node->name[0] ? node->name : (node->text[0] ? node->text : node->kind);
  if (strcmp(node->kind, "surface") == 0) return gtk_window_new();
  if (strcmp(node->kind, "group") == 0) return gtk_box_new(1, 8);
  if (strcmp(node->kind, "text") == 0) return gtk_label_new(node->text);
  if (strcmp(node->kind, "action") == 0) return gtk_button_new_with_label(label);
  if (strcmp(node->kind, "field") == 0) return gtk_entry_new();
  if (strcmp(node->kind, "selection") == 0 && strcmp(node->role, "list_item") == 0) return gtk_label_new(label);
  if (strcmp(node->kind, "selection") == 0) return gtk_check_button_new_with_label(label);
  if (strcmp(node->kind, "collection") == 0) return gtk_list_box_new();
  return NULL;
}

static int attach(GtkSpike *spike, size_t index, char error[BX_MAX_ERROR]) {
  BxNativeNode *node = &spike->batch.nodes[index];
  if (node->depth == 0) return 1;
  size_t parent_index = index;
  while (parent_index > 0) {
    parent_index -= 1;
    if (spike->batch.nodes[parent_index].depth == node->depth - 1) break;
  }
  GtkWidget *parent = spike->widgets[parent_index];
  const char *parent_kind = spike->batch.nodes[parent_index].kind;
  if (strcmp(parent_kind, "surface") == 0) gtk_window_set_child((GtkWindow *)parent, spike->widgets[index]);
  else if (strcmp(parent_kind, "group") == 0) gtk_box_append((GtkBox *)parent, spike->widgets[index]);
  else if (strcmp(parent_kind, "collection") == 0) gtk_list_box_append((GtkListBox *)parent, spike->widgets[index]);
  else { snprintf(error, BX_MAX_ERROR, "invalid-parent-kind:%s", parent_kind); return 0; }
  return 1;
}

static int materialize(GtkSpike *spike, const char *path, char error[BX_MAX_ERROR]) {
  if (!bx_read_batch(path, &spike->batch, error)) return 0;
  if (spike->batch.node_count == 0) { snprintf(error, BX_MAX_ERROR, "missing-projection-tree"); return 0; }
  for (size_t index = 0; index < spike->batch.node_count; ++index) {
    BxNativeNode *node = &spike->batch.nodes[index];
    GtkWidget *widget = make_widget(node);
    if (widget == NULL) { snprintf(error, BX_MAX_ERROR, "unmapped-kind:%s", node->kind); return 0; }
    spike->widgets[index] = widget;
    if (!attach(spike, index, error)) return 0;
    if (strstr(node->listeners, "activate") != NULL) g_signal_connect_data(widget, "clicked", (GCallback)on_action, spike, NULL, 0);
    if (strcmp(node->kind, "field") == 0) g_signal_connect_data(widget, "changed", (GCallback)on_change, spike, NULL, 0);
    if (strcmp(node->kind, "selection") == 0 && strcmp(node->role, "list_item") != 0) g_signal_connect_data(widget, "toggled", (GCallback)on_selection, spike, NULL, 0);
    if (strcmp(node->kind, "collection") == 0) g_signal_connect_data(widget, "row-selected", (GCallback)on_list_selection, spike, NULL, 0);
  }
  return 1;
}

static int find_kind(const GtkSpike *spike, const char *kind) {
  for (size_t index = 0; index < spike->batch.node_count; ++index) if (strcmp(spike->batch.nodes[index].kind, kind) == 0) return (int)index;
  return -1;
}

static void dispose(GtkSpike *spike) {
  if (spike->disposed) return;
  gtk_window_destroy((GtkWindow *)spike->widgets[0]);
  spike->disposed = 1;
  spike->disposal_count += 1;
}

int main(int argc, char **argv) {
  if (argc != 3) { fprintf(stderr, "usage: gtk4_adapter MOUNT_BATCH STALE_BATCH\n"); return 2; }
  gtk_init();
  GtkSpike spike;
  memset(&spike, 0, sizeof(spike));
  char error[BX_MAX_ERROR] = {0};
  if (!materialize(&spike, argv[1], error)) { fprintf(stderr, "%s\n", error); return 3; }
  gpointer file_dialog = gtk_file_dialog_new();
  printf("SERVICE\tfile-choice\t%s\n", g_type_name_from_instance(file_dialog));
  g_object_unref(file_dialog);
  gtk_window_present((GtkWindow *)spike.widgets[0]);
  while (g_main_context_iteration(NULL, 0)) {}

  int action = find_kind(&spike, "action");
  int field = find_kind(&spike, "field");
  int check = find_kind(&spike, "selection");
  int list = find_kind(&spike, "collection");
  if (action < 0 || field < 0 || check < 0 || list < 0) return 4;
  gtk_editable_set_text((GtkEditable *)spike.widgets[field], "Ada");
  gtk_editable_select_region((GtkEditable *)spike.widgets[field], 0, 3);
  gtk_check_button_set_active(spike.widgets[check], 1);
  GtkListBoxRow *row = gtk_list_box_get_row_at_index((GtkListBox *)spike.widgets[list], 1);
  gtk_list_box_select_row((GtkListBox *)spike.widgets[list], row);
  g_signal_emit_by_name(spike.widgets[action], "clicked");
  (void)gtk_widget_grab_focus(spike.widgets[field]);
  if (gtk_root_get_focus(spike.widgets[0]) != spike.widgets[field])
    gtk_root_set_focus(spike.widgets[0], spike.widgets[field]);
  while (g_main_context_iteration(NULL, 0)) {}

  int start = -1, end = -1;
  int selection_ok = gtk_editable_get_selection_bounds((GtkEditable *)spike.widgets[field], &start, &end);
  int check_active = gtk_check_button_get_active(spike.widgets[check]);
  int list_selected = gtk_list_box_get_selected_row((GtkListBox *)spike.widgets[list]) == row;
  int focus_active = gtk_root_get_focus(spike.widgets[0]) == spike.widgets[field];
  BxNativeBatch stale;
  char stale_error[BX_MAX_ERROR] = {0};
  if (!bx_read_batch(argv[2], &stale, stale_error)) return 5;
  int stale_rejected = !bx_is_next_update(&spike.batch, &stale);

  for (size_t index = 0; index < spike.batch.node_count; ++index) {
    char *role = g_enum_to_string(gtk_accessible_role_get_type(), gtk_accessible_get_accessible_role(spike.widgets[index]));
    printf("CONTROL\t%s\t%s\t%s\n", spike.batch.nodes[index].kind, g_type_name_from_instance(spike.widgets[index]), role);
    g_free(role);
  }

  int passed = strcmp(gtk_editable_get_text((GtkEditable *)spike.widgets[field]), "Ada") == 0 &&
               selection_ok && start == 0 && end == 3 &&
               check_active && list_selected && focus_active &&
               spike.action_events == 1 && spike.change_events >= 1 && spike.selection_events >= 2 && stale_rejected;
  dispose(&spike);
  dispose(&spike);
  passed = passed && spike.disposal_count == 1;
  printf("RESULT\t%s\tcontrols=%zu\taction=%d\tchange=%d\tselection_events=%d\ttext_selection=%d:%d:%d\tcheck=%d\tlist=%d\tfocus=%d\tstale_rejected=%d\tdisposals=%d\n",
         passed ? "passed" : "failed", spike.batch.node_count, spike.action_events, spike.change_events,
         spike.selection_events, selection_ok, start, end, check_active, list_selected, focus_active,
         stale_rejected, spike.disposal_count);
  return passed ? 0 : 6;
}
