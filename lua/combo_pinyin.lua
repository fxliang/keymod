-- string sorted by a base string(no-repeat)
string.resortby = function (self, base)
  local char_to_index = {}
  for i=1, #base do
    char_to_index[base:sub(i, i)] = i
  end
  local input_chars = {}
  for i = 1, #self do
    table.insert(input_chars, self:sub(i, i))
  end
  table.sort(input_chars, function(a, b)
    return char_to_index[a] < char_to_index[b]
  end)
  return table.concat(input_chars)
end
-- xform fun for string
string.xform = function (self, pat, replace)
  local ret, count = self:gsub(pat, replace)
  return ret
end
-- xlit fun for string
string.xlit = function (self, pat, replace)
  local char_map = {}
  for i = 1, #pat do
    local input = pat:sub(i, i)
    local output = replace:sub(i, i)
    char_map[input] = output
  end

  local function xlitc(c) return char_map[c] or c end

  local out = ''
  for i = 1, #self do
    out = out .. xlitc(self:sub(i, i))
  end
  return out
end
-- split string to lines array
string.split = function(self, delimiter)
  local result = {}
  for match in (self..delimiter):gmatch("(.-)"..delimiter) do
    local prefix, pat, replace = string.match(match, "^%s*- '?(%w+)[/|](.-)[/|](.-)[/|]'?")
    if prefix then
      table.insert(result, match)
    end
  end
  return result
end
-------------------------------------------------------------------------------
-- algebra text from combo_pinyin pc layout
local algebra_text = [[
  # 先將物理按鍵字符對應到宮保拼音鍵位中的拼音字母
  - 'xlit|swxdecfrvgtbjum kiloaqzhynp|SCZHLFGDBKTPIUVANREOXXXXXXX|'

  # 以下根據宮保拼音的鍵位分別變換聲母、韻母部分
  # 空格鍵單擊時產生空白
  - 'xform/^A$/ /'
  # 消除無效按鍵
  - xform/X+//

  # 並擊聲母
  - xform/^ZF/zh/
  - xform/^CL/ch/
  - xform/^FB/m/
  - xform/^LD/n/
  - xform/^HG/r/
  # 特殊配列鍵盤用
  - xform/^ZB/p/
  - xform/^CD/t/
  - xform/^SG/k/

  # common_options
  - xlit/BPFDTLGKHZCS/bpfdtlgkhzcs/

  # G,K,H 接 I/Ü 作 ⟨ji/ju, qi/qu, xi/xu⟩
  # 若分尖團，也可用 Z,C,S 與 I/Ü 相拼
  - xform/^[gz]([IV])/j$1/
  - xform/^[kc]([IV])/q$1/
  - xform/^[hs]([IV])/x$1/

  # ⟨er⟩自成音節
  - xform/^R$/er/
  # 舌尖元音⟨ï⟩
  - xform/^([zcsr]h?)R?$/$1i/

  - xform/ANE$/ang/
  - xform/UARO$/uang/
  - xform/IRO$/iong/
  - xform/URO$/ong/
  - xform/VNE$/iong/
  - xform/UNE$/ong/
  - xform/INE$/ing/
  - xform/NE$/eng/

  - xform/AN$/an/
  - xform/VN$/vn/
  - xform/UN$/uen/
  - xform/IN$/in/
  - xform/N$/en/

  - xform/IAR$/iao/
  - xform/AR$/ai/
  - xform/RE$/ei/
  - xform/UR$/uei/
  - xform/RO$/ou/
  - xform/IR$/iou/
  - xform/AO$/ao/
  - xform/AE$/a/

  - xform/^([dtnlgkhzcsr]h?)O$/$1ou/
  - xform/^([bpmfdtnlgkh])E$/$1ei/

  - xlit/AOEIUV/aoeiuv/

  # 漢語拼音方案的拼寫規則
  - xform/^i(ng?)$/yi$1/
  - xform/^i$/yi/
  - xform/^i/y/
  - xform/^ong$/weng/
  - xform/^u$/wu/
  - xform/^u/w/
  - xform/^v/yu/
  - xform/^([jqx])v/$1u/
  # 一些容錯
  - xform/^([bpmf])uo$/$1o/
  - xform/^([nl])uei$/$1ei/
  - xform/^([nl])iong$/$1ong/
  - xform/io$/iao/
  - xform/^([zcsr]h?)i([aoe])/$1$2/
  - xform/^([zcsr]h?)i(ng?)$/$1e$2/
  # 拼寫規則
  - xform/iou$/iu/
  - xform/uei$/ui/
  - xform/uen$/un/

  # 聲母獨用時補足隠含的韻母
  # ⟨bu, pu, fu⟩
  - xform/^([bpf])$/$1u/
  # ⟨de, te, ne, le, ge, ke, he⟩
  # 特別地，⟨me⟩ 對應常用字「麼·么」
  - xform/^([mdtnlgkh])$/$1e/
]]

-- initial algebra
local algebra = algebra_text:split('\n')
-- combo alphabet table
local alphabet = 'swxdecfrvgtbjum kiloaqzhynp'
-------------------------------------------------------------------------------
-- process chord
local function process_chord(input)
  local ret = input
  for _, rule in ipairs(algebra) do
    local prefix, pat, rpl = rule:match("^%s*- '?(%w+)[/|](.-)[/|](.-)[/|]'?")
    if prefix then
      if rpl then rpl = rpl:gsub('%$', '%%') end
      ret = (prefix == 'xlit') and ret:xlit(pat, rpl) or ret:xform(pat, rpl)
    end
  end
  return ret
end

-------------------------------------------------------------------------------
local chord = ""
local pressed_keys_ = ""
local function ProcessKeyEvent(keychar, is_key_down)
  if alphabet:find(keychar) then
    local position = pressed_keys_:find(keychar)
    local finish_chord = false
    if is_key_down then
      if not finish_chord and not position then
        pressed_keys_ = pressed_keys_ .. keychar
        pressed_keys_ = pressed_keys_:resortby(alphabet)
        if pressed_keys_ == ' ' then
          chord = ' '
        else
          chord = (process_chord(pressed_keys_))
        end
      end
			return true, ""
    else
      if position and position > 1 then
        pressed_keys_ = pressed_keys_:sub(1, position - 1) .. pressed_keys_:sub(position + 1)
      else
        pressed_keys_ = ""
        finish_chord = true
      end

			if finish_chord then
				local ret_chord = chord
				chord = ''
				return true, ret_chord
			else
				return true, ""
			end
    end
	else -- not to process
		return false, ""
  end
end

require('base')
-------------------------------------------------------------------------------
--- this is an easy demo to simulate combo_pinyin chording
local combo_pinyin_enabled = true
local last_chords = {}

function combo_pinyin_proc(wParam, kinfo)
	-- print('combo_pinyin_proc is called')
  keystates[kinfo.vkCode] = (wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN)
	-- switch enabled or disabled by f1
	if kinfo.vkCode == name_to_vk['f1'] and (wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN) then
		combo_pinyin_enabled = not combo_pinyin_enabled
		print("combo_pinyin_enabled: " .. tostring(combo_pinyin_enabled))
		return true
	end
	if not combo_pinyin_enabled then return false end
  -- if ctrl or alt pressed, let it go
	if is_ctrled() or is_alted() then return false end
  -- process a-z and spc only
  if (kinfo.vkCode >= name_to_vk['a'] and kinfo.vkCode <= name_to_vk['z']) or vk_to_name[kinfo.vkCode] == 'spc' then
    local key = vk_to_name[kinfo.vkCode]
		if key == 'spc' then key = ' ' end
    local is_key_down = (wParam == WM_KEYDOWN or wParam == WM_SYSKEYDOWN)
    local eat, chords = ProcessKeyEvent(key, is_key_down)
    if #chords > 0 then
      print("finished chording: " .. chords)
      for i=1, #chords do
				local c = string.sub(chords, i, i)
				if c == ' ' then c = 'spc' end
        sendinput_keyevent(name_to_vk[c], false)
        sendinput_keyevent(name_to_vk[c], true)
      end
      table.insert(last_chords, #chords)
    end
    if chords == ' ' then last_chords = {} end
    return eat
  end
  -- handle backspace
  if vk_to_name[kinfo.vkCode] == 'bspc' and keystates[kinfo.vkCode] then
    if #last_chords > 0 and last_chords[#last_chords] > 0 then
      for i=1, last_chords[#last_chords] do
        sendinput_keyevent(name_to_vk['bspc'], false)
        sendinput_keyevent(name_to_vk['bspc'], true)
      end
      table.remove(last_chords)
      return true
    end
  end
  return false
end
print("combo_pinyin_proc is loaded")
