require("base")
-------------------------------------------------------------------------------
-- simple keymaping
-- local keymap = {
--   ['d'] = 'e'
-- }
local qwerty_to_qwertz = {
    ['y'] = 'z',
    ['z'] = 'y',
}
local keymap = qwerty_to_qwertz
-------------------------------------------------------------------------------
--- return true means key action will be eaten
function simple_keymap(wParam, kinfo)
  keystates[kinfo.vkCode] = (wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN)

  local keyname = keymap[vk_to_name[kinfo.vkCode]]
  -- current key is mapped in keymap
  if keyname ~= nil then
    print('map ' .. vk_to_name[kinfo.vkCode] .. ' to ' .. keyname)
    local vkCodeMod = name_to_vk[keyname]
    local keyup = not (wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN)
    sendinput_keyevent(vkCodeMod, keyup)
    return true
  end
  return false
end
print("simple_keymap qwertz is loaded")
