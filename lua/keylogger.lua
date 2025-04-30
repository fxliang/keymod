require('base')
--- function bellow is luajit based!!!
local ffi = require("ffi")
local bit = require("bit")

-- 显式加载所有需要的DLL
local kernel32 = ffi.load("kernel32")
local user32 = ffi.load("user32")
local psapi = ffi.load("psapi")  -- GetModuleFileNameExA 需要这个

-- 检查DLL是否加载成功
if not kernel32 then print('kernel32加载失败') end
if not user32 then print('user32加载失败') end
if not psapi then print('psapi加载失败') end

-- 定义Windows API函数和类型
ffi.cdef[[
typedef void* HANDLE;
typedef unsigned long DWORD;
typedef int BOOL;
typedef const char* LPCSTR;
typedef void* HWND;
typedef HANDLE HINSTANCE;

HWND GetForegroundWindow(void);
DWORD GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId);
HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
BOOL CloseHandle(HANDLE hObject);
DWORD GetLastError(void);
DWORD GetModuleFileNameExA(HANDLE hProcess, HINSTANCE hModule, char* lpFilename, DWORD nSize);
int GetWindowTextA(HWND hWnd, char* lpString, int nMaxCount);
int GetWindowTextLengthA(HWND hWnd);
]]

-- 常量定义
local PROCESS_QUERY_INFORMATION = 0x0400
local PROCESS_VM_READ = 0x0010
local MAX_PATH = 260

-- 获取进程可执行文件路径
local function getProcessPath(pid)
  local hProcess = kernel32.OpenProcess(bit.bor(PROCESS_QUERY_INFORMATION, PROCESS_VM_READ), 0, pid)
  if hProcess == nil then
    print("OpenProcess失败，错误代码:", kernel32.GetLastError())
    return nil
  end
  local buffer = ffi.new("char[?]", MAX_PATH)
  local success = psapi.GetModuleFileNameExA(hProcess, nil, buffer, MAX_PATH)
  kernel32.CloseHandle(hProcess)
  if success == 0 then
    print("GetModuleFileNameExA失败，错误代码:", kernel32.GetLastError())
    return nil
  end
  return acptou8(ffi.string(buffer))
end

-- 获取窗口标题
local function getWindowCaption(hwnd)
  if hwnd == nil then return nil end
  -- 先获取标题长度
  local length = user32.GetWindowTextLengthA(hwnd)
  if length == 0 then
    return ""
  end
  -- 分配缓冲区并获取标题
  local buffer = ffi.new("char[?]", length + 1)  -- +1 为 null 终止符
  user32.GetWindowTextA(hwnd, buffer, length + 1)
  return ffi.string(buffer)
end

-- 从路径中提取进程名
local function extractProcessName(path)
  if not path then return "未知" end
  local pattern = ".+\\([^\\]+)$"
  return path:match(pattern) or path
end

-- 获取当前激活窗口的进程ID和名称
local function getActiveWindowInfo()
  local hwnd = user32.GetForegroundWindow()
  if hwnd == nil then
    print('hwnd is nil, error code:', kernel32.GetLastError())
    return nil, nil
  end
  local caption = getWindowCaption(hwnd)
  local pid = ffi.new("DWORD[1]")
  user32.GetWindowThreadProcessId(hwnd, pid)
  pid = tonumber(pid[0])
  local path = getProcessPath(pid)
  local name = extractProcessName(path)
  return pid, name, caption
end

function keylogger_func(wParam, kinfo)
  keystates[kinfo.vkCode] = (wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN)
  local sta = keystates[kinfo.vkCode] and "↓: " or "↑: "
  local keyname = vk_to_name[kinfo.vkCode]
  if keyname ~= nil then
    local pid, name, caption = getActiveWindowInfo()
    local function format_len(str, len)
      return string.format("%-"..len.."s", str)
    end
    print(format_len(sta .. keyname, 15), format_len('pid: '..pid, 15),
      'name: '..name, 'caption: ' .. acptou8(caption))
  end
  return false
end
clear_screen()
print('keylogger.lua 加载成功 ^_^')
