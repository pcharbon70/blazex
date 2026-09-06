#define UNICODE
#include <windows.h>
#include <commctrl.h>
#include <commdlg.h>
#include <shellapi.h>
#include <string.h>
#include "native_protocol.h"

static LRESULT CALLBACK window_proc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  (void)lparam;
  if (message == WM_COMMAND && HIWORD(wparam) == BN_CLICKED) return 0;
  if (message == WM_DESTROY) { PostQuitMessage(0); return 0; }
  return DefWindowProcW(window, message, wparam, lparam);
}

static void utf8_to_wide(const char *source, WCHAR *target, int length) {
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, source, -1, target, length) == 0)
    target[0] = L'\0';
}

static void materialize_standard_controls(HWND window, const BxNativeBatch *batch) {
  int y = 12;
  for (size_t index = 0; index < batch->node_count; ++index) {
    const BxNativeNode *node = &batch->nodes[index];
    WCHAR label[BX_MAX_TEXT + 1];
    utf8_to_wide(node->name[0] ? node->name : node->text, label, BX_MAX_TEXT + 1);
    if (strcmp(node->kind, "text") == 0)
      CreateWindowW(L"STATIC", label, WS_CHILD | WS_VISIBLE, 12, y, 260, 24, window, NULL, NULL, NULL);
    else if (strcmp(node->kind, "action") == 0)
      CreateWindowW(L"BUTTON", label, WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON, 12, y, 160, 28, window, (HMENU)(INT_PTR)(100 + index), NULL, NULL);
    else if (strcmp(node->kind, "field") == 0)
      CreateWindowW(L"EDIT", L"", WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_BORDER | ES_AUTOHSCROLL, 12, y, 260, 28, window, (HMENU)(INT_PTR)(100 + index), NULL, NULL);
    else if (strcmp(node->kind, "selection") == 0 && strcmp(node->role, "checkbox") == 0)
      CreateWindowW(L"BUTTON", label, WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_AUTOCHECKBOX, 12, y, 200, 28, window, (HMENU)(INT_PTR)(100 + index), NULL, NULL);
    else if (strcmp(node->kind, "collection") == 0)
      CreateWindowW(L"LISTBOX", L"", WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_BORDER | LBS_NOTIFY, 12, y, 260, 90, window, (HMENU)(INT_PTR)(100 + index), NULL, NULL);
    else continue;
    y += strcmp(node->kind, "collection") == 0 ? 98 : 34;
  }
}

static void deferred_file_choice(HWND window) {
  OPENFILENAMEW request = {0};
  request.lStructSize = sizeof(request);
  request.hwndOwner = window;
  (void)GetOpenFileNameW(&request);
}

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE previous, PWSTR command_line, int show) {
  (void)previous; (void)command_line; (void)deferred_file_choice;
  int argument_count = 0;
  LPWSTR *arguments = CommandLineToArgvW(GetCommandLineW(), &argument_count);
  if (arguments == NULL || argument_count != 2) return 2;
  char batch_path[MAX_PATH * 4];
  if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, arguments[1], -1, batch_path,
                          sizeof(batch_path), NULL, NULL) == 0) return 3;
  LocalFree(arguments);
  BxNativeBatch batch;
  char error[BX_MAX_ERROR] = {0};
  if (!bx_read_batch(batch_path, &batch, error)) return 4;
  INITCOMMONCONTROLSEX controls = {sizeof(controls), ICC_STANDARD_CLASSES};
  InitCommonControlsEx(&controls);
  WNDCLASSW klass = {0};
  klass.lpfnWndProc = window_proc;
  klass.hInstance = instance;
  klass.lpszClassName = L"BlazeXNativeSpike";
  RegisterClassW(&klass);
  HWND window = CreateWindowW(klass.lpszClassName, L"BlazeX native spike", WS_OVERLAPPEDWINDOW,
                              CW_USEDEFAULT, CW_USEDEFAULT, 360, 320, NULL, NULL, instance, NULL);
  materialize_standard_controls(window, &batch);
  ShowWindow(window, show);
  MSG message;
  while (GetMessageW(&message, NULL, 0, 0) > 0) { TranslateMessage(&message); DispatchMessageW(&message); }
  return 0;
}
