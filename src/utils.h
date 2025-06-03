#pragma once
#include <regex>
#include <sstream>
#include <string>
#include <windows.h>

inline std::vector<std::wstring> ws_split(const std::wstring &in,
                                          const std::wstring &delim) {
  std::wregex re{delim};
  return std::vector<std::wstring>{
      std::wsregex_token_iterator(in.begin(), in.end(), re, -1),
      std::wsregex_token_iterator()};
}

// ----------------------------------------------------------------------------
inline std::wstring string_to_wstring(const std::string &str,
                                      int code_page = CP_ACP) {
  // support CP_ACP and CP_UTF8 only
  if (code_page != 0 && code_page != CP_UTF8)
    return L"";
  // calc len
  int len =
      MultiByteToWideChar(code_page, 0, str.c_str(), (int)str.size(), NULL, 0);
  if (len <= 0)
    return L"";
  std::wstring res;
  TCHAR *buffer = new TCHAR[len + 1];
  MultiByteToWideChar(code_page, 0, str.c_str(), (int)str.size(), buffer, len);
  buffer[len] = '\0';
  res.append(buffer);
  delete[] buffer;
  return res;
}

inline std::string wstring_to_string(const std::wstring &wstr,
                                     int code_page = CP_ACP) {
  // support CP_ACP and CP_UTF8 only
  if (code_page != 0 && code_page != CP_UTF8)
    return "";
  int len = WideCharToMultiByte(code_page, 0, wstr.c_str(), (int)wstr.size(),
                                NULL, 0, NULL, NULL);
  if (len <= 0)
    return "";
  std::string res;
  char *buffer = new char[len + 1];
  WideCharToMultiByte(code_page, 0, wstr.c_str(), (int)wstr.size(), buffer, len,
                      NULL, NULL);
  buffer[len] = '\0';
  res.append(buffer);
  delete[] buffer;
  return res;
}

#define _u8toacp(x) wstring_to_string(string_to_wstring(x, CP_UTF8))
#define _acptou8(x) wstring_to_string(string_to_wstring(x), CP_UTF8)
#define u8tow(x) string_to_wstring(x, CP_UTF8)

class DebugStream {
public:
  DebugStream() = default;
  ~DebugStream() { OutputDebugString(ss.str().c_str()); }
  template <typename T> DebugStream &operator<<(const T &value) {
    ss << value;
    return *this;
  }
  DebugStream &operator<<(const char *value) {
    if (value) {
      std::wstring wvalue(u8tow(value)); // utf-8
      ss << wvalue;
    }
    return *this;
  }
  DebugStream &operator<<(const std::string value) {
    std::wstring wvalue(u8tow(value)); // utf-8
    ss << wvalue;
    return *this;
  }
  DebugStream &operator<<(const RECT &rc) {
    ss << L"rc = {" << rc.left << L", " << rc.top << L", " << rc.right << L", "
       << rc.bottom << L"}";
    return *this;
  }
  DebugStream &operator<<(const POINT &pt) {
    ss << L"pt = (" << pt.x << L", " << pt.y << L")";
    return *this;
  }

private:
  std::wstringstream ss;
};

#define DEBUG DebugStream()
