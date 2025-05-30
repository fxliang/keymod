--- exported api
--- sendinput_keyevent(vkCode, keyup) sendinput to system by vkCode and keyup status
--- is_caps_on() return if currently capslock is on
--- debugstr(str) OutputDebugStringA with string
--- clear_screen() clear screen like what the command 'cls' does
--- sendinput_str(str) send string directly
--- set_console_enc(enc) call win32 api SetConsoleOutputCP(enc), if lua file encoded in utf-8, call set_console_enc(65001)
--- acptou8(str) convert str from acp to utf8
--- u8toacp(str) convert str from utf8 to acp
-------------------------------------------------------------------------------
-- set console output in utf-8, for lua scripts encoded in utf-8
set_console_enc(65001)
-------------------------------------------------------------------------------
-- global variables
require("combo_pinyin")
-- require("qwertz")
-- require('keylogger')
-------------------------------------------------------------------------------
--- data param to LowLevelKeyboardProc
--- wParam int
--- kinfo struct just the same like KBDLLHOOKSTRUCT
---   vkCode    int
---   scanCode  int
---   flags     int
---   time      int
---   dwExtraInfo int
LowLevelKeyboardProc = combo_pinyin_proc
-- LowLevelKeyboardProc = keylogger_func
-- LowLevelKeyboardProc = simple_keymap
