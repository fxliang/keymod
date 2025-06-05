#include "popup.h"
#include <memory>
extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
}
// ----------------------------------------------------------------------------
std::unique_ptr<PopupWindow> popup_window = nullptr;

void update_popup_window(const std::wstring &text, int showTimeMs, int xoffset,
                         int yoffset, unsigned char alpah = 0xaf) {
  if (!popup_window) {
    popup_window = std::make_unique<PopupWindow>(text, showTimeMs);
    popup_window->m_alpha = alpah;
    if (!popup_window->Create()) {
      popup_window.reset();
      return;
    }
    popup_window->ShowWithTimeout(showTimeMs);
  } else {
    popup_window->SetText(text);
    popup_window->ShowWithTimeout(showTimeMs);
  }
  popup_window->m_xoffset = xoffset;
  popup_window->m_yoffset = yoffset;
  popup_window->PositionWindow();
}

int cleanup(lua_State *L) {
  popup_window.reset();
  return 0;
}

int popup(lua_State *L) {
  // get parameter count
  int argCount = lua_gettop(L);
  const char *text = lua_tostring(L, 1);
  int showTimeMs = lua_tointeger(L, 2);
  int x = 5, y = -5, alpha = 0xaf;
  if (argCount >= 4) {
    x = lua_tointeger(L, 3);
    y = lua_tointeger(L, 4);
    if (argCount == 5) {
      alpha = lua_tointeger(L, 5);
    }
  } else if (argCount != 2) {
    luaL_error(L, "Usage: popup(text, showTimeMs[, x, y])");
    return 0; // never reached
  }
  update_popup_window(u8tow(text), showTimeMs, x, y, alpha);
  return 0;
}

int check(lua_State *L) {
  if (popup_window) {
    lua_pushboolean(L, true);
    return 1;
  } else {
    lua_pushboolean(L, false);
    return 1;
  }
}

extern "C" __declspec(dllexport) int luaopen_popup(lua_State *L) {
  static const luaL_Reg popup_lib[] = {
      {"popup", popup}, {"cleanup", cleanup}, {"check", check}, {NULL, NULL}};
  luaL_newlib(L, popup_lib);
  // 添加 __gc 元方法
  lua_pushstring(L, "__gc");
  lua_pushcfunction(L, cleanup);
  lua_settable(L, -3);
  return 1;
}
