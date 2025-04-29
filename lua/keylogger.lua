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
  local pid = ffi.new("DWORD[1]")
  user32.GetWindowThreadProcessId(hwnd, pid)
  pid = tonumber(pid[0])
  local path = getProcessPath(pid)
  local name = extractProcessName(path)
  return pid, name
end

function keylogger_func(wParam, kinfo)
  keystates[kinfo.vkCode] = (wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN)
  local sta = keystates[kinfo.vkCode] and "keydown:" or "keyup:  "
  local keyname = vk_to_name[kinfo.vkCode]
  if keyname ~= nil then
    local pid, name = getActiveWindowInfo()
    print(sta, keyname, 'pid: '..pid, 'name: '..name)
  end
  return false
end
print('keylogger.lua 加载成功 ^_^')
