-- base variables
WM_KEYDOWN = 256
WM_KEYUP = 257
WM_SYSKEYDOWN = 260
WM_SYSKEYUP = 261

VK_SHIFT = 0X10
VK_LSHIFT = 0XA0
VK_RSHIFT = 0XA1

VK_CONTROL = 0X11
VK_LCONTROL = 0XA2
VK_RCONTROL = 0XA3

VK_MENU = 0X12
VK_LMENU = 0XA4
VK_RMENU = 0XA5

-------------------------------------------------------------------------------
--- init keystates
keystates = {}
for _=1, 256 do
  table.insert(keystates, false)
end
-------------------------------------------------------------------------------
vk_to_name = {
  [0x01] = 'lbtn', -- 鼠标左键
  [0x02] = 'rbtn', -- 鼠标右键
  [0x03] = 'cancel', -- 控制中断处理
  [0x04] = 'mbtn', -- 鼠标中间按钮
  [0x05] = 'xbtn1', -- X1 鼠标按钮
  [0x06] = 'xbtn2', -- X2 鼠标按钮
  -- 0x07	保留
  [0x08] = 'bspc', -- Backspace 键
  [0x09] = 'tab', -- Tab 键
  -- 0x0A-0B	保留
  [0x0C] = 'clear', -- 清除键
  [0x0D] = 'return', -- 输入键
  -- 0x0E-0F	未分配
  [0x10] = 'shift', -- 换档键SPACE
  [0x11] = 'control', -- Ctrl 键
  [0x12] = 'menu', -- Alt 键
  [0x13] = 'pause', -- 暂停键
  [0x14] = 'caps', -- Caps lock 键
  [0x15] = 'kana', -- IME 假名模式
  --[0x15] = 'hangul', -- IME 朝鲜文模式
  [0x16] = 'ime_on', -- IME On
  [0x17] = 'junja', -- IME Junja 模式
  [0x18] = 'final', -- IME 最终模式
  --[0x19] = 'hanja', -- IME Hanja 模式
  [0x19] = 'kanji', -- IME 汉字模式
  [0x1A] = 'ime_off', -- IME 关闭
  [0x1B] = 'esc', -- Esc 键
  [0x1C] = 'convert', -- IME 转换
  [0x1D] = 'nonconvert', -- IME 非转换
  [0x1E] = 'accept', -- IME 接受
  [0x1F] = 'modechange', -- IME 模式更改请求
  [0x20] = 'spc', -- 空格键
  [0x21] = 'pgup', -- Page up 键
  [0x22] = 'pgdn', -- Page down 键
  [0x23] = 'end', -- 结束键
  [0x24] = 'home', -- 主键
  [0x25] = 'left', -- 向左键
  [0x26] = 'up', -- 向上键
  [0x27] = 'right', -- 向右键
  [0x28] = 'down', -- 向下键
  [0x29] = 'sel', -- select 选择密钥
  [0x2A] = 'prt', -- print 打印键
  [0x2B] = 'execute', -- 执行键
  [0x2C] = 'snapshot', -- 打印屏幕键
  [0x2D] = 'ins', -- 插入键
  [0x2E] = 'del', -- 删除密钥
  [0x2F] = 'help', -- 帮助密钥
  [0x30] = '0', -- 0 键
  [0x31] = '1', -- 1 个键
  [0x32] = '2', -- 2 键
  [0x33] = '3', -- 3 个键
  [0x34] = '4', -- 4 键
  [0x35] = '5', -- 5 个键
  [0x36] = '6', -- 6 个键
  [0x37] = '7', -- 7 键
  [0x38] = '8', -- 8 键
  [0x39] = '9', -- 9 键
  --0x3A-40	定义
  [0x41] = 'a', -- 密钥
  [0x42] = 'b', -- B 键
  [0x43] = 'c', -- C 键
  [0x44] = 'd', -- D 键
  [0x45] = 'e', -- E 键
  [0x46] = 'f', -- F 键
  [0x47] = 'g', -- G 键
  [0x48] = 'h', -- H 键
  [0x49] = 'i', -- I 键
  [0x4A] = 'j', -- J 键
  [0x4B] = 'k', -- K 键
  [0x4C] = 'l', -- L 键
  [0x4D] = 'm', -- M 键
  [0x4E] = 'n', -- N 键
  [0x4F] = 'o', -- O 键
  [0x50] = 'p', -- P 键
  [0x51] = 'q', -- Q 键
  [0x52] = 'r', -- R 键
  [0x53] = 's', -- S 键
  [0x54] = 't', -- T 键
  [0x55] = 'u', -- U 键
  [0x56] = 'v', -- V 键
  [0x57] = 'w', -- W 键
  [0x58] = 'x', -- X 键
  [0x59] = 'y', -- Y 键
  [0x5A] = 'z', -- Z 键
  [0x5B] = 'lwin', -- 左 Windows 徽标键
  [0x5C] = 'rwin', -- 右 Windows 徽标键
  [0x5D] = 'apps', -- 应用程序密钥
  -- 0x5E	保留
  [0x5F] = 'sleep', -- 计算机睡眠键
  [0x60] = 'kp0', -- 数字键盘 0 键
  [0x61] = 'kp1', -- 数字键盘 1 键
  [0x62] = 'kp2', -- 数字键盘 2 键
  [0x63] = 'kp3', -- 数字键盘 3 键
  [0x64] = 'kp4', -- 数字键盘 4 键
  [0x65] = 'kp5', -- 数字键盘 5 键
  [0x66] = 'kp6', -- 数字键盘 6 键
  [0x67] = 'kp7', -- 数字键盘 7 键
  [0x68] = 'kp8', -- 数字键盘 8 键
  [0x69] = 'kp9', -- 数字键盘 9 键
  [0x6A] = 'kp*', -- 相乘键
  [0x6B] = 'kp+', -- 添加密钥
  [0x6C] = 'separator', -- 分隔符键
  [0x6D] = 'kp-', -- 减去键
  [0x6E] = 'pk.', -- 十进制键
  [0x6F] = 'kp/', -- 除键
  [0x70] = 'f1', -- F1 键
  [0x71] = 'f2', -- F2 键
  [0x72] = 'f3', -- F3 键
  [0x73] = 'f4', -- F4 键
  [0x74] = 'f5', -- F5 键
  [0x75] = 'f6', -- F6 键
  [0x76] = 'f7', -- F7 键
  [0x77] = 'f8', -- F8 键
  [0x78] = 'f9', -- F9 键
  [0x79] = 'f10', -- F10 键
  [0x7A] = 'f11', -- F11 键
  [0x7B] = 'f12', -- F12 键
  [0x7C] = 'f13', -- F13 键
  [0x7D] = 'f14', -- F14 键
  [0x7E] = 'f15', -- F15 键
  [0x7F] = 'f16', -- F16 键
  [0x80] = 'f17', -- F17 键
  [0x81] = 'f18', -- F18 键
  [0x82] = 'f19', -- F19 键
  [0x83] = 'f20', -- F20 键
  [0x84] = 'f21', -- F21 键
  [0x85] = 'f22', -- F22 键
  [0x86] = 'f23', -- F23 键
  [0x87] = 'f24', -- F24 键
  -- 0x88-8F	保留
  [0x90] = 'numlock', -- Num lock 键
  [0x91] = 'scroll', -- 滚动锁键
  --0x92-96	OEM 特定
  --0x97-9F	未分配
  [0xA0] = 'lsft', -- 左移键
  [0xA1] = 'rsft', -- 右移键
  [0xA2] = 'lctl', -- 左 Ctrl 键
  [0xA3] = 'rctl', -- 右 Ctrl 键
  [0xA4] = 'lmenu', -- 左 Alt 键
  [0xA5] = 'rmenu', -- 右 Alt 键
  [0xA6] = 'browser_back', -- 浏览器后退键
  [0xA7] = 'browser_forward', -- 浏览器转发密钥
  [0xA8] = 'browser_refresh', -- 浏览器刷新密钥
  [0xA9] = 'browser_stop', -- 浏览器停止键
  [0xAA] = 'browser_search', -- 浏览器搜索键
  [0xAB] = 'browser_favorites', -- 浏览器收藏夹密钥
  [0xAC] = 'browser_home', -- 浏览器“开始”和“开始”键
  [0xAD] = 'volume_mute', -- 音量静音键
  [0xAE] = 'volume_down', -- 调低音量键
  [0xAF] = 'volume_up', -- 调高音量键
  [0xB0] = 'media_next_track', -- 下一个 Track 键
  [0xB1] = 'media_prev_track', -- 上一曲目键
  [0xB2] = 'media_stop', -- 停止媒体键
  [0xB3] = 'media_play_pause', -- 播放/暂停媒体键
  [0xB4] = 'launch_mail', -- 启动邮件密钥
  [0xB5] = 'launch_media_select', -- 选择媒体键
  [0xB6] = 'launch_app1', -- 启动应用程序 1 密钥
  [0xB7] = 'launch_app2', -- 启动应用程序 2 密钥
  -- 0xB8-B9	保留
  [0xBA] = ';', -- oem_1 用于其他字符;它可能因键盘而异。 对于美国标准键盘，;: 键
  [0xBB] = '=', -- oem_plus 对于任何国家/地区，+ 密钥
  [0xBC] = ',', -- oem_comma 对于任何国家/地区，, 密钥
  [0xBD] = '-', -- oem_minus 对于任何国家/地区，- 密钥
  [0xBE] = '.', -- oem_period 对于任何国家/地区，. 密钥
  [0xBF] = '/', -- oem_2 用于其他字符;它可能因键盘而异。 对于美国标准键盘，/? 键
  [0xC0] = '`', -- oem_3 用于其他字符;它可能因键盘而异。 对于美国标准键盘，~ 键
  -- 0xC1-DA	保留
  [0xDB] = '[', -- oem_4 用于其他字符;它可能因键盘而异。 对于美国标准键盘，[{ 键
  [0xDC] = '\\', -- oem_5 用于其他字符;它可能因键盘而异。 对于美国标准键盘，\\| 键
  [0xDD] = ']', -- oem_6 用于其他字符;它可能因键盘而异。 对于美国标准键盘，]} 键
  [0xDE] = '\'', -- oem_7 用于其他字符;它可能因键盘而异。 对于美国标准键盘，'" 键
  [0xDF] = 'oem_8', -- 用于其他字符;它可能因键盘而异。
  -- 0xE0	保留
  -- 0xE1	OEM 特定
  [0xE2] = '\\', -- oem_102 美国标准键盘上的 <> 键，或非 US 102 键键盘上的 \\| 键
  -- 0xE3-E4	OEM 特定
  [0xE5] = 'processkey', -- IME PROCESS 密钥
  -- 0xE6	OEM 特定
  [0xE7] = 'packet', -- 用于传递 Unicode 字符，就像是击键一样。 PACKET 键是用于非键盘输入方法的 32 位虚拟键值的低字。 有关详细信息，请参阅 KEYBDINPUT、SendInput、WM_KEYDOWN和 WM_KEYUP 中的备注
  -- 0xE8	未分配
  -- 0xE9-F5	OEM 特定
  [0xF6] = 'attn', -- Attn 键
  [0xF7] = 'crsel', -- CrSel 键
  [0xF8] = 'exsel', -- ExSel 密钥
  [0xF9] = 'ereof', -- 擦除 EOF 密钥
  [0xFA] = 'play', -- 播放键
  [0xFB] = 'zoom', -- 缩放键
  -- NONAME	0xFC	保留
  [0xFD] = 'pa1', -- PA1 密钥
  [0xFE] = 'oem_clear', -- oem_clear 清除键
}
-------------------------------------------------------------------------------
-- generate name to vkcode table
name_to_vk = {}
for vk, name in pairs(vk_to_name) do name_to_vk[name] = vk end

function is_alted()
  return keystates[VK_MENU] or keystates[VK_LMENU] or keystates[VK_RMENU]
end
function is_shifted()
  return keystates[VK_SHIFT] or keystates[VK_LSHIFT] or keystates[VK_RSHIFT]
end
function is_ctrled()
  return keystates[VK_CONTROL] or keystates[VK_LCONTROL] or keystates[VK_RCONTROL]
end
