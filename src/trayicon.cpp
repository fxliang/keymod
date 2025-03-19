#include "trayicon.h"
#include "resource.h"
#include <shellapi.h>
#include <winuser.h>

#define MENU_QUIT 1002
#define MENU_ENABLED 1003
#define MENU_RELOAD 1004

bool keymod_enabled = true;

TrayIcon::TrayIcon(HINSTANCE hInstance, const std::wstring &tooltip)
    : hInst(hInstance), hMenu(NULL) {
  CreateHwnd();
  m_iconDisabled = LoadIcon(NULL, IDI_ERROR);
  m_iconEnabled = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_KEYMOD));
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = m_hWnd;
  nid.uID = 1;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid.uCallbackMessage = WM_USER + 1;
  wcsncpy_s(nid.szTip, tooltip.c_str(), _countof(nid.szTip) - 1);
  nid.szTip[_countof(nid.szTip) - 1] = L'\0'; // 确保以空字符结尾
}

TrayIcon::~TrayIcon() {
  Hide();
  DestroyWindow(m_hWnd);
}

void TrayIcon::Show() { Shell_NotifyIcon(NIM_ADD, &nid); }

void TrayIcon::Hide() { Shell_NotifyIcon(NIM_DELETE, &nid); }

void TrayIcon::CreateHwnd() {
  WNDCLASS wc = {0};
  wc.lpfnWndProc = WndProc;
  wc.hInstance = hInst;
  wc.lpszClassName = L"TrayIcon";
  wc.hIcon = LoadIcon(hInst, MAKEINTRESOURCE(IDI_KEYMOD));
  wc.hCursor = LoadCursor(NULL, IDC_ARROW);
  ::RegisterClass(&wc);
  m_hWnd =
      CreateWindow(L"TrayIcon", L"TrayIcon", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
                   CW_USEDEFAULT, 0, 0, NULL, NULL, hInst, this);
  ShowWindow(m_hWnd, SW_HIDE);
}

void TrayIcon::SetIcon(HICON hIcon) {
  nid.hIcon = hIcon;
  Shell_NotifyIcon(NIM_MODIFY, &nid);
}

void TrayIcon::Enable(bool enabled) {
  keymod_enabled = enabled;
  SetIcon(enabled ? m_iconEnabled : m_iconDisabled);
  ShowBalloonTip(L"提示", enabled ? L"keymod 已启用" : L"keymod 已禁用");
}

void TrayIcon::SetTooltip(const std::wstring &tooltip) {
  // 使用 _countof 宏确保数组大小正确
  wcsncpy_s(nid.szTip, tooltip.c_str(), _countof(nid.szTip) - 1);
  nid.szTip[_countof(nid.szTip) - 1] = L'\0'; // 确保以空字符结尾
  Shell_NotifyIcon(NIM_MODIFY, &nid);
}

void TrayIcon::CreateContextMenu() {
  if (hMenu == NULL) {
    hMenu = CreatePopupMenu();
    AppendMenu(hMenu, MF_STRING, MENU_RELOAD, L"重新加载脚本");
    AppendMenu(hMenu, MF_STRING | (keymod_enabled ? MF_CHECKED : MFS_UNCHECKED),
               MENU_ENABLED, L"启用keymod");
    AppendMenu(hMenu, MF_STRING, MENU_QUIT, L"退出");
  }
}

void TrayIcon::ShowBalloonTip(const std::wstring &title,
                              const std::wstring &message, DWORD timeout) {
  if (nid.uFlags | NIF_INFO) {
    OnBalloonTimeout();
  }
  // 设置 NIF_INFO 来显示气泡提示
  nid.uFlags |= NIF_INFO;
  // 设置气泡提示的标题和内容
  wcsncpy_s(nid.szInfoTitle, title.c_str(), _TRUNCATE);
  wcsncpy_s(nid.szInfo, message.c_str(), _TRUNCATE);
  // 设置气泡提示的显示时间
  nid.uTimeout = timeout;      // 以毫秒为单位
  nid.dwInfoFlags = NIIF_INFO; // 设定气泡提示的类型（信息级别）
  // 发送更新托盘图标的消息并显示气泡提示
  Shell_NotifyIcon(NIM_MODIFY, &nid);
  // 启动定时器，超时后清除气泡提示
  SetTimer(m_hWnd, TIMER_BALLOON_TIMEOUT, timeout, NULL);
}

void TrayIcon::OnBalloonTimeout() {
  KillTimer(m_hWnd, TIMER_BALLOON_TIMEOUT);
  // 清除气泡提示内容
  nid.uFlags &= ~NIF_INFO;                             // 移除 NIF_INFO 标志
  memset(nid.szInfoTitle, 0, sizeof(nid.szInfoTitle)); // 清空标题
  memset(nid.szInfo, 0, sizeof(nid.szInfo));           // 清空提示内容
  // 更新托盘图标，清除气泡提示
  Shell_NotifyIcon(NIM_MODIFY, &nid);
}

void TrayIcon::ProcessMessage(HWND hwnd, UINT msg, WPARAM wParam,
                              LPARAM lParam) {
  switch (msg) {
  case WM_USER + 1:
    if (lParam == WM_RBUTTONUP) {
      CreateContextMenu();
      POINT pt;
      GetCursorPos(&pt);
      SetForegroundWindow(hwnd);
      TrackPopupMenu(hMenu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, NULL);
    }
    break;

  case WM_TIMER:
    if (wParam == TIMER_BALLOON_TIMEOUT)
      OnBalloonTimeout();
    break;
  case WM_COMMAND: {
    switch (LOWORD(wParam)) {
    case MENU_QUIT: {
      Hide();
      PostQuitMessage(0);
      break;
    }
    case MENU_ENABLED: {
      keymod_enabled = !keymod_enabled;
      if (hMenu)
        CheckMenuItem(hMenu, MENU_ENABLED,
                      keymod_enabled ? MF_CHECKED : MF_UNCHECKED);
      Enable(keymod_enabled);
      InvalidateRect(hwnd, NULL, true);
      break;
    }
    case MENU_RELOAD: {
      if (m_reload_handler)
        m_reload_handler();
      ShowBalloonTip(L"提示", L"脚本已重新加载");
      break;
    }
    }
  } break;
  }
}

LRESULT CALLBACK TrayIcon::WndProc(HWND hwnd, UINT msg, WPARAM wParam,
                                   LPARAM lParam) {
  TrayIcon *self;
  if (msg == WM_NCCREATE) {
    self = static_cast<TrayIcon *>(
        reinterpret_cast<LPCREATESTRUCT>(lParam)->lpCreateParams);
    SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
  } else {
    self = reinterpret_cast<TrayIcon *>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
  }
  if (self)
    self->ProcessMessage(hwnd, msg, wParam, lParam);
  return DefWindowProc(hwnd, msg, wParam, lParam);
}
