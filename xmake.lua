local luadist = 'lua'
add_requires(luadist)

target('keymod')
  set_kind('binary')
  set_languages('c++17')
  add_files('./src/main.cpp', "./src/keymod.rc")
  add_packages(luadist)
  add_defines('MAKE_LIB', 'UNICODE')
  add_links('ole32', 'user32', 'shell32')

  if is_plat('mingw') then
    add_ldflags('-municode -static-libgcc -static-libstdc++ -static', {force=true})
    add_cxflags("-O2")
  elseif is_plat('windows') then
    add_cxflags("/utf-8 /O2")
  end

  after_build(function(target)
    local prjoutput = path.join(target:targetdir(), target:filename())
    print("copy " .. prjoutput .. " to $(projectdir)")
    os.trycp(prjoutput, "$(projectdir)")
  end)
