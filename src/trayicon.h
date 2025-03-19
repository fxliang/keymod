#pragma once
#include <functional>
#include <string>
#include <windows.h>

typedef std::function<void(void)> vhandler;

extern bool keymod_enabled;
class TrayIcon {
public:
  TrayIcon(HINSTANCE hInstance, const std::wstring &tooltip);
  ~TrayIcon();
  void Show();
  void Hide();
  void SetIcon(HICON hIcon);
  void Enable(bool enabled);
  void SetTooltip(const std::wstring &tooltip);
  void ProcessMessage(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
  void ShowBalloonTip(const std::wstring &title, const std::wstring &message,
                      DWORD timeout = 1000);
  vhandler &reload_handler() { return m_reload_handler; }

private:
  void OnBalloonTimeout();
  static const UINT TIMER_BALLOON_TIMEOUT = 20241202;
  HINSTANCE hInst;
  NOTIFYICONDATA nid;
  HMENU hMenu;
  HWND m_hWnd;

  HICON m_iconEnabled;
  HICON m_iconDisabled;

  vhandler m_reload_handler;

  void CreateContextMenu();
  void CreateHwnd();
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam,
                                  LPARAM lParam);
};
