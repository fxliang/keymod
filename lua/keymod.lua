-- global variables
require("combo_pinyin")
-- require("qwertz")
-------------------------------------------------------------------------------
--- exported api
--- sendinput_keyevent(vkCode, keyup)
--- is_caps_on() return is currently capslock on
--- debugstr(str) OutputDebugStringA with string
--- clear_screen() clear screen like what the command 'cls' does
-------------------------------------------------------------------------------
--- data param to LowLevelKeyboardProc
--- wParam int
--- kinfo
---   vkCode    int
---   scanCode  int
---   flags     int
---   time      int
---   dwExtraInfo int
LowLevelKeyboardProc = combo_pinyin_proc
-- LowLevelKeyboardProc = simple_keymap
