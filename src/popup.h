#pragma once
#include "utils.h"
#include <vector>
#include <windows.h>

template <typename T> struct Window {
  HWND m_hWnd = nullptr;
  static LRESULT CALLBACK WindProc(HWND const hwnd, UINT const uMsg,
                                   WPARAM const wParam, LPARAM const lParam) {
    T *self;
    if (uMsg == WM_NCCREATE) {
      self = static_cast<T *>(
          reinterpret_cast<LPCREATESTRUCT>(lParam)->lpCreateParams);
      SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
      self->m_hWnd = hwnd; // 保存窗口句柄
    } else {
      self = reinterpret_cast<T *>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    }

    if (self) {
      return self->MessageHandler(uMsg, wParam, lParam);
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }
  virtual LRESULT MessageHandler(UINT const uMsg, WPARAM const wParam,
                                 LPARAM const lParam) {
    switch (uMsg) {
    case WM_PAINT:
      OnPaint();
      return 0;
    case WM_TIMER:
      OnTimer(wParam);
      return 0;
    case WM_DESTROY:
      OnDestroy();
      return 0;
    case WM_ACTIVATE:
    case WM_MOUSEACTIVATE:
      return MA_NOACTIVATE;
    case WM_WINDOWPOSCHANGING:
      // 防止窗口获得焦点
      ((WINDOWPOS *)lParam)->flags |= SWP_NOZORDER | SWP_NOACTIVATE;
      return 0;
    default:
      return DefWindowProc(m_hWnd, uMsg, wParam, lParam);
    }
  }
  virtual void OnPaint() { /* 子类实现 */ }
  virtual void OnTimer(UINT_PTR id) { /* 子类实现 */ }
  virtual void OnDestroy() { /* 子类实现 */ }
};

#define TIMER_ID 202505301623
// 具体的弹出窗口类
class PopupWindow : public Window<PopupWindow> {
public:
  PopupWindow(const std::wstring &text, int showTimeMs)
      : m_text(text), m_showTime(showTimeMs) {}
  ~PopupWindow() {
    if (m_hWnd) {
      KillTimer(m_hWnd, TIMER_ID); // 清理定时器
      DestroyWindow(m_hWnd);
    }
  }
  bool Create() {
    WNDCLASSEX wc = {sizeof(WNDCLASSEX)};
    if (!GetClassInfoEx(GetModuleHandle(nullptr), L"PopupWindowClass", &wc)) {
      // 如果未注册，则注册新类
      wc.style = CS_HREDRAW | CS_VREDRAW;
      wc.lpfnWndProc = &PopupWindow::WindProc;
      wc.hInstance = GetModuleHandle(nullptr);
      wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
      wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
      wc.lpszClassName = L"PopupWindowClass";
      if (!RegisterClassEx(&wc)) {
        DWORD error = GetLastError();
        if (error != ERROR_CLASS_ALREADY_EXISTS)
          return false;
      }
    }
    // 创建窗口
    m_hWnd =
        CreateWindowEx(WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
                       L"PopupWindowClass", L"Popup", WS_POPUP | WS_VISIBLE,
                       CW_USEDEFAULT, CW_USEDEFAULT, 300, 100, nullptr, nullptr,
                       GetModuleHandle(nullptr), this);
    if (!m_hWnd)
      return false;
    PositionWindow(); // 设置窗口位置
    // 设置定时器，用于自动关闭
    SetTimer(m_hWnd, TIMER_ID, m_showTime, nullptr);
    return true;
  }
  void ResetTimer(int showTimeMs) {
    m_showTime = showTimeMs;
    KillTimer(m_hWnd, TIMER_ID);                     // 先杀掉旧的定时器
    SetTimer(m_hWnd, TIMER_ID, m_showTime, nullptr); // 设置新的定时器
  }
  void Show() {
    ShowWindow(m_hWnd, SW_SHOWNA);
    UpdateWindow(m_hWnd);
  }
  void ShowWithTimeout(int showTimeMs) {
    ResetTimer(showTimeMs);
    Show();
  }
  void Hide() { ShowWindow(m_hWnd, SW_HIDE); }
  void SetText(const std::wstring &text) {
    m_text = text;
    ResetTimer(m_showTime);                // 重置定时器
    InvalidateRect(m_hWnd, nullptr, TRUE); // 重绘窗口
  }
  void PositionWindow() {
    // 1. 获取鼠标位置
    POINT pt;
    GetCursorPos(&pt);
    // 2. 获取鼠标所在的显示器
    HMONITOR hMonitor = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
    MONITORINFO mi = {sizeof(MONITORINFO)};
    GetMonitorInfo(hMonitor, &mi);
    // 3. 计算窗口大小
    RECT rcWindow;
    GetWindowRect(m_hWnd, &rcWindow);
    int width = rcWindow.right - rcWindow.left;
    int height = rcWindow.bottom - rcWindow.top;
    // 4. 计算位置
    int x = (m_xoffset >= 0) ? mi.rcWork.left + m_xoffset
                             : mi.rcWork.right + m_xoffset - width;

    int y = (m_yoffset >= 0) ? mi.rcWork.top + m_yoffset
                             : mi.rcWork.bottom + m_yoffset - height;
    // 5. 设置窗口位置
    SetWindowPos(m_hWnd, nullptr, x, y, width, height,
                 SWP_NOZORDER | SWP_NOACTIVATE);
  }
  int m_xoffset = 0;  // 水平偏移量
  int m_yoffset = -5; // 垂直偏移量，默认向上偏移5个像素
protected:
  void OnPaint() override {
    if (m_text.empty()) {
      Hide();
      return;
    }
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(m_hWnd, &ps);
    // 绘制背景
    RECT rc;
    GetClientRect(m_hWnd, &rc);
    FillRect(hdc, &rc, (HBRUSH)(COLOR_WINDOW + 1));
    // 绘制文本
    SetBkMode(hdc, TRANSPARENT);
    // set font size and font name
    HFONT hFont =
        CreateFont(26, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                   OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
                   DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    HFONT hOldFont = (HFONT)SelectObject(hdc, hFont);
    // get text size
    SIZE textSize{0, 0};
    std::vector<std::wstring> lines = ws_split(m_text, L"\n");
    std::vector<SIZE> lineSizes;
#define MAX(x, y) ((x) > (y) ? (x) : (y))
    for (const auto &line : lines) {
      SIZE lineSize;
      GetTextExtentPoint32(hdc, line.c_str(), (int)line.size(), &lineSize);
      lineSizes.push_back(lineSize);
      textSize.cx = MAX(textSize.cx, lineSize.cx);
      textSize.cy += lineSize.cy + 5;
    }
    textSize.cy -= 5; // 最后一行不需要额外的间距
    // set the window size to fit the text
    SetWindowPos(m_hWnd, nullptr, 0, 0, textSize.cx + 20, textSize.cy + 20,
                 SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    int x = 5, y = 10;
    for (auto i = 0; i < lines.size(); ++i) {
      RECT lineRect = {x, y, x + textSize.cx, y + lineSizes.at(i).cy};
      DrawText(hdc, lines.at(i).c_str(), -1, &lineRect,
               DT_LEFT | DT_VCENTER | DT_SINGLELINE);
      y += lineSizes.at(i).cy + 5;
    }
    EndPaint(m_hWnd, &ps);
  }
  void OnTimer(UINT_PTR id) override {
    if (id == TIMER_ID) {
      KillTimer(m_hWnd, TIMER_ID); // 关闭定时器
      Hide();
    }
  }
  void OnDestroy() override { Hide(); }

private:
  std::wstring m_text;
  int m_showTime;
};
