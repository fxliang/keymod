# keymod 

a keyboard mod app powered by lua/luajit for Windows

## what's keymod for

make a keyboard mod app customizable by writing script (lua/luajit) in `lua` folder instead of precompiled app. then you can define your own mod logic by yourself!
## build
### dependencies
- xmake
- msvc or mingw
### build steps
```
git clone -v https://github.com/fxliang/keymod.git
cd keymod
xmake
```
## how to make your own mod logic

the mod logic is written in `lua/keymod.lua`, the function name is `LowLevelKeyboardProc`, for detail info, please check `lua/keymod.lua`. the directory `lua` has been added to the `package.path` and `package.cpath`

```lua
-- global variables
require("combo_pinyin")
-- require("qwertz")
-------------------------------------------------------------------------------
--- exported api
--- sendinput_keyevent(vkCode, keyup) sendinput to system by vkCode and keyup status
--- is_caps_on() return if currently capslock is on
--- debugstr(str) OutputDebugStringA with string
--- clear_screen() clear screen like what the command 'cls' does
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
-- LowLevelKeyboardProc = simple_keymap

```