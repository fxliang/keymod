#include "resource.h"
#include "trayicon.h"
#include "utils.h"
#include <cctype>
#include <csignal>
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <windows.h>

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

using namespace std;
namespace fs = std::filesystem;

HHOOK hKeyboardHook = NULL;
lua_State *L = nullptr;
int process_key = 0;
unique_ptr<TrayIcon> m_tray_icon;

// ----------------------------------------------------------------------------
// exported cfunctions
int is_caps_on(lua_State *L) {
  lua_pushboolean(L, (GetKeyState(VK_CAPITAL) & 0x0001) != 0);
  return 1;
}

string get_exe_path() {
  char path[MAX_PATH];
  DWORD length = GetModuleFileNameA(NULL, path, MAX_PATH);
  if (length == 0) {
    std::cerr << "Error getting executable path" << std::endl;
    exit(1);
  }
  return fs::path(path).parent_path().string();
}

int sendinput_keyevent(lua_State *L) {
  int vkCode = lua_tointeger(L, 1);
  bool keyup = lua_toboolean(L, 2);
  INPUT input;
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = vkCode;
  input.ki.wScan = 0;
  input.ki.time = 0;
  input.ki.dwExtraInfo = GetMessageExtraInfo();
  if (keyup)
    input.ki.dwFlags |= KEYEVENTF_KEYUP;
  else
    input.ki.dwFlags = 0;
  SendInput(1, &input, sizeof(INPUT));
  return 0;
}

int sendinput_str(lua_State *L) {
  const char *str_c = lua_tostring(L, 1);
  const string str(str_c);
  const wstring text = u8tow(str);
  std::wcout << text << endl;
  std::vector<INPUT> inputs;
  for (const auto &ch : text) {
    INPUT input = {};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = 0;
    input.ki.wScan = ch;
    input.ki.dwFlags = KEYEVENTF_UNICODE;
    input.ki.time = 0;
    input.ki.dwExtraInfo = GetMessageExtraInfo();
    inputs.push_back(input);
    INPUT inputRelease = input;
    inputRelease.ki.dwFlags |= KEYEVENTF_KEYUP;
    inputs.push_back(inputRelease);
  }
  if (!inputs.empty()) {
    SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
  }
  return 0;
}

int debugstr(lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  OutputDebugStringA(msg);
  lua_pop(L, 1);
  return 0;
}

int clear_screen(lua_State *L) {
  system("cls");
  return 0;
}

int u8toacp(lua_State *L) {
  const char *str = lua_tostring(L, 1);
  auto acp_string = _u8toacp(std::string(str));
  lua_pushstring(L, acp_string.c_str());
  return 1;
}

int acptou8(lua_State *L) {
  const char *str = lua_tostring(L, 1);
  auto u8string = _acptou8(std::string(str));
  lua_pushstring(L, u8string.c_str());
  return 1;
}

int set_console_enc(lua_State *L) {
  int enc = lua_tointeger(L, 1);
  SetConsoleOutputCP(enc);
  return 0;
}

// ----------------------------------------------------------------------------
template <typename T>
inline void push_simpledata_to_table(lua_State *L, const T &data,
                                     const char *name) {
  lua_pushstring(L, name);
  if constexpr (std::is_same_v<T, const char *>)
    lua_pushstring(L, data);
  else if constexpr (std::is_integral_v<T>)
    lua_pushinteger(L, (lua_Number)data);
  else if constexpr (std::is_floating_point_v<T>)
    lua_pushnumber(L, (lua_Number)data);
  else if constexpr (std::is_same_v<T, bool>)
    lua_pushboolean(L, data);
  else if constexpr (std::is_same_v<T, std::nullptr_t>)
    lua_pushnil(L);
  lua_settable(L, -3);
}

inline void finalize_env() {
  if (hKeyboardHook)
    UnhookWindowsHookEx(hKeyboardHook);
  if (L)
    lua_close(L);
  SetConsoleOutputCP(CP_ACP);
  CoUninitialize();
}
void cleanup(int signum) {
  cout << "Ctrl+c captured, now to exit the program" << endl;
  finalize_env();
  system("pause");
  exit(signum);
}
void append_lua_package_path(lua_State *L, const char *name,
                             const string &path) {
  string v = "";
  lua_getglobal(L, "package");
  lua_getfield(L, -1, name);
  v.append(lua_tostring(L, -1));
  v.append(";");
  v.append(path);
  lua_pushstring(L, v.c_str());
  lua_setfield(L, -3, name);
  lua_pop(L, 2);
}

LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
#define skip() return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam)
  if (!keymod_enabled)
    skip();
  if (nCode == HC_ACTION) {
    KBDLLHOOKSTRUCT *kinfo = (KBDLLHOOKSTRUCT *)lParam;
    if (!kinfo->scanCode)
      skip();

    lua_rawgeti(L, LUA_REGISTRYINDEX, process_key);
    if (!lua_isnil(L, -1)) {
      lua_pushinteger(L, wParam);
      lua_newtable(L);
      push_simpledata_to_table(L, kinfo->vkCode, "vkCode");
      push_simpledata_to_table(L, kinfo->scanCode, "scanCode");
      push_simpledata_to_table(L, kinfo->flags, "flags");
      push_simpledata_to_table(L, kinfo->time, "time");
      push_simpledata_to_table(L, kinfo->dwExtraInfo, "dwExtraInfo");
      auto st = lua_pcall(L, 2, 1, 0);
      if (st != LUA_OK) {
        string msg = "Error: " + std::string(lua_tostring(L, -1));
        lua_pop(L, 1);
        OutputDebugStringA(msg.c_str());
        printf("%s\n", msg.c_str());
        skip();
      }
      int ret = lua_toboolean(L, -1);
      if (ret)
        return ret;
    }
  }
  skip();
#undef skip
}

void init_lua_env() {
  if (L)
    lua_close(L);
  L = luaL_newstate();
  luaL_openlibs(L);
  append_lua_package_path(L, "path", get_exe_path() + "\\lua\\?.lua");
  append_lua_package_path(L, "cpath", get_exe_path() + "\\lua\\?.dll");

#define REG_FUNC(L, name) lua_register(L, #name, name)
  REG_FUNC(L, sendinput_keyevent);
  REG_FUNC(L, debugstr);
  REG_FUNC(L, is_caps_on);
  REG_FUNC(L, clear_screen);
  REG_FUNC(L, sendinput_str);
  REG_FUNC(L, set_console_enc);
  REG_FUNC(L, acptou8);
  REG_FUNC(L, u8toacp);
#undef REG_FUNC

  auto file_path = get_exe_path() + "\\lua\\keymod.lua";
  if (auto ret = luaL_dofile(L, file_path.c_str())) {
    string msg = "error happened when luaL_dofile(\"keymod.lua\"): " +
                 string(lua_tostring(L, -1));
    OutputDebugStringA(msg.c_str());
    printf("%s\n", msg.c_str());
    finalize_env();
    exit(ret);
  }

  lua_getglobal(L, "LowLevelKeyboardProc");
  if (lua_isfunction(L, -1))
    process_key = luaL_ref(L, LUA_REGISTRYINDEX);
  else {
    cout << "LowLevelKeyboardProc is not function in lua script, program exit!";
    finalize_env();
    exit(1);
  }
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    LPWSTR lpCmdLine, int nCmdShow) {
#ifdef _MSC_VER
  AllocConsole();
  freopen("CONOUT$", "w", stdout);
#endif
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  hKeyboardHook =
      SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, NULL, 0);
  if (!hKeyboardHook) {
    cout << "Failed to install keyboard hook!" << endl;
    finalize_env();
    return 1;
  }
  signal(SIGINT, cleanup);

  init_lua_env();
  m_tray_icon =
      make_unique<TrayIcon>(hInstance, L"keymod - 右键菜单更多操作^_^");
  m_tray_icon->reload_handler() = [&]() { init_lua_env(); };
  m_tray_icon->Show();
  m_tray_icon->Enable(keymod_enabled);

  MSG msg;
  while (GetMessage(&msg, NULL, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  finalize_env();
  return 0;
}
