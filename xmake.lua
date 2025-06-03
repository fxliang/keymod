-- luajit in xmake repo does not support mingw/x86_64
-- so when mingw, use lua instead
local luadist = is_plat('mingw') and 'lua' or 'luajit'
add_requires(luadist)

rule('copy')
  after_build(function(target)
    -- try kill keymod if running
    try {
      function()
        os.run('taskkill.exe /im '.. target:filename() .. ' /F')
        print('ensure keymod.exe killed before build done!')
      end
    } catch {}
    local prjoutput = path.join(target:targetdir(), target:filename())
    print("copy " .. prjoutput .. " to $(projectdir)")
    os.trycp(prjoutput, "$(projectdir)")
  end)

rule('build_flags')
  before_build(function(target)
    if is_plat('mingw') then
      target:add('ldflags', '-municode -static-libgcc -static-libstdc++ -static', {force=true})
      target:add("cxflags", "-O2")
    elseif is_plat('windows') then
      target:add("cxflags", "/utf-8 /O2")
    end
  end)

target('keymod')
  set_kind('binary')
  set_languages('c++17')
  add_files('./src/main.cpp', "src/trayicon.cpp","./src/keymod.rc")
  add_packages(luadist)

  add_defines('MAKE_LIB', 'UNICODE', "_WIN32_WINNT=0x0603")
  add_links( "user32", "gdi32", "shell32", "ole32")

  add_rules('copy', 'build_flags')

  local version_major = "0"
  local version_minor = "0"
  local version_patch = "1"

  on_load(function(target)
    import("core.base.text")
    local rc_template = path.join(os.projectdir(), "src/keymod.rc.in")
    local rc_output = path.join(os.projectdir(), "src/keymod.rc")
    local function generate_rc()
      local content = io.readfile(rc_template)
      content = content:gsub("${VERSION_MAJOR}", version_major)
      content = content:gsub("${VERSION_MINOR}", version_minor)
      content = content:gsub("${VERSION_PATCH}", version_patch)
      content = content:gsub("${FILE_DESCRIPTION}", "keymod powered by " .. luadist)
      -- if git command failed, commit_id fallback to '0'
      local commit_id = '0'
      try { function() commit_id = os.iorun("git rev-parse --short HEAD"):gsub("\n", "") end } catch {}
      content = content:gsub("${TAG_SUFFIX}", commit_id)
      io.writefile(rc_output, content)
    end
    local function check_version()
      local rc = io.readfile(rc_output)
      local commit_id = '0'
      -- if git command failed, commit_id fallback to '0'
      try { function() commit_id = os.iorun("git rev-parse --short HEAD"):gsub("\n", "") end } catch {}
      local version_str = version_major..'.'..version_minor..'.'..version_patch..'.'..commit_id
      return string.find(rc, version_str)
    end
    -- no rc file, or version info not match
    if not os.isfile(rc_output) or not check_version() then
      print("generate new rc file: " .. rc_output)
      generate_rc()
    end
  end)

target('popup')
  set_kind('shared')
  set_languages('c++17')
  add_files('./src/popup.cpp')
  add_packages(luadist)

  add_defines('MAKE_LIB', 'UNICODE', "_WIN32_WINNT=0x0603")
  add_links( "user32", "shell32", "ole32", "gdi32")
  set_filename("popup.dll")

  add_rules('copy', 'build_flags')

