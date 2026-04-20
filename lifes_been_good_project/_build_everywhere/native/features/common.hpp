#pragma once

#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <string>
#include <vector>

#if defined(_WIN32)
#include <direct.h>
#include <windows.h>
#include <shellapi.h>
#define MKDIR(path) _mkdir(path)
#else
#include <sys/stat.h>
#define MKDIR(path) mkdir(path, 0755)
#endif

#if defined(_WIN32)
static inline void init_console_utf8()
{
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);
}

static inline std::string wide_to_utf8(const wchar_t *w)
{
  if (!w)
    return std::string();
  int needed = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
  if (needed <= 0)
    return std::string();
  std::string out;
  out.resize((size_t)needed - 1);
  WideCharToMultiByte(CP_UTF8, 0, w, -1, out.data(), needed, nullptr, nullptr);
  return out;
}

struct ConsoleUtf8AutoInit
{
  ConsoleUtf8AutoInit() { init_console_utf8(); }
};

static inline ConsoleUtf8AutoInit g_console_utf8_auto_init;
#else
static inline void init_console_utf8() {}
#endif

static inline std::vector<std::string> get_args_utf8(int argc, char **argv)
{
#if defined(_WIN32)
  int argcw = 0;
  LPWSTR *argvw = CommandLineToArgvW(GetCommandLineW(), &argcw);
  std::vector<std::string> out;
  if (!argvw || argcw <= 0)
  {
    if (argvw)
      LocalFree(argvw);
    return out;
  }
  out.reserve((size_t)argcw);
  for (int i = 0; i < argcw; i++)
    out.push_back(wide_to_utf8(argvw[i]));
  LocalFree(argvw);
  return out;
#else
  std::vector<std::string> out;
  out.reserve((size_t)argc);
  for (int i = 0; i < argc; i++)
    out.push_back(argv[i] ? argv[i] : "");
  return out;
#endif
}

static inline uint64_t fnv1a64(const void *data, size_t len)
{
  const uint8_t *p = (const uint8_t *)data;
  uint64_t h = 14695981039346656037ULL;
  for (size_t i = 0; i < len; i++)
  {
    h ^= (uint64_t)p[i];
    h *= 1099511628211ULL;
  }
  return h;
}

static inline std::string fnv1a64_hex(const char *s)
{
  if (!s)
    return std::string();
  uint64_t h = fnv1a64(s, std::strlen(s));
  char buf[17];
  std::snprintf(buf, sizeof(buf), "%016llx", (unsigned long long)h);
  return std::string(buf);
}

static inline void json_escape(const char *s)
{
  const unsigned char *p = (const unsigned char *)s;
  while (*p)
  {
    unsigned char c = *p++;
    if (c == '"')
    {
      std::fputs("\\\"", stdout);
      continue;
    }
    if (c == '\\')
    {
      std::fputs("\\\\", stdout);
      continue;
    }
    if (c == '\n')
    {
      std::fputs("\\n", stdout);
      continue;
    }
    if (c == '\r')
    {
      std::fputs("\\r", stdout);
      continue;
    }
    if (c == '\t')
    {
      std::fputs("\\t", stdout);
      continue;
    }
    if (c < 0x20)
    {
      std::printf("\\u%04x", (unsigned int)c);
      continue;
    }
    std::fputc((int)c, stdout);
  }
}

static inline void json_err(const char *code, const char *message)
{
  std::fputs("{\"ok\":false,\"error\":{\"code\":\"", stdout);
  json_escape(code);
  std::fputs("\",\"message\":\"", stdout);
  json_escape(message);
  std::fputs("\"}}", stdout);
}

static inline void json_ok_start()
{
  std::fputs("{\"ok\":true,\"data\":", stdout);
}

static inline void json_ok_end()
{
  std::fputs("}", stdout);
}

static inline void path_join(char *out, size_t out_sz, const char *dir, const char *name)
{
  size_t dl = std::strlen(dir);
  const char *sep = (dl > 0 && (dir[dl - 1] == '/' || dir[dl - 1] == '\\')) ? "" : "/";
  std::snprintf(out, out_sz, "%s%s%s", dir, sep, name);
}

static inline int ensure_dir(const char *path)
{
  if (!path || !*path)
    return 0;
  if (MKDIR(path) == 0)
    return 1;
  return errno == EEXIST ? 1 : 0;
}

static inline int ensure_dir_recursive(const char *path)
{
  if (!path || !*path)
    return 0;
  char buf[1024];
  std::strncpy(buf, path, sizeof(buf) - 1);
  buf[sizeof(buf) - 1] = '\0';
  size_t len = std::strlen(buf);
  for (size_t i = 1; i < len; i++)
  {
    if (buf[i] == '/' || buf[i] == '\\')
    {
      char saved = buf[i];
      buf[i] = '\0';
      size_t bl = std::strlen(buf);
      int skip = 0;
      if (bl == 2 && buf[1] == ':')
        skip = 1;
      if (!skip)
        ensure_dir(buf);
      buf[i] = saved;
    }
  }
  return ensure_dir(buf);
}

static inline std::vector<std::string> csv_split(const char *line)
{
  std::vector<std::string> out;
  std::string cur;
  int in_quotes = 0;
  for (const char *p = line; *p; p++)
  {
    if (*p == '\r' || *p == '\n')
      break;
    if (*p == '"')
    {
      in_quotes = !in_quotes;
      continue;
    }
    if (*p == ',' && !in_quotes)
    {
      out.push_back(cur);
      cur.clear();
      continue;
    }
    cur.push_back(*p);
  }
  out.push_back(cur);
  return out;
}

static inline int file_exists(const char *path)
{
  FILE *f = std::fopen(path, "rb");
  if (!f)
    return 0;
  std::fclose(f);
  return 1;
}

static inline int ensure_csv_with_header(const char *path, const char *header_line)
{
  if (file_exists(path))
    return 1;
  FILE *f = std::fopen(path, "wb");
  if (!f)
    return 0;
  std::fputs(header_line, f);
  std::fputs("\n", f);
  std::fclose(f);
  return 1;
}

static inline int append_line(const char *path, const char *line)
{
  FILE *f = std::fopen(path, "ab");
  if (!f)
    return 0;
  std::fputs(line, f);
  std::fputs("\n", f);
  std::fclose(f);
  return 1;
}

static inline int file_has_data_rows(const char *path)
{
  FILE *f = std::fopen(path, "rb");
  if (!f)
    return 0;
  char line[4096];
  int lines = 0;
  while (std::fgets(line, sizeof(line), f))
  {
    lines++;
    if (lines >= 2)
      break;
  }
  std::fclose(f);
  return lines >= 2;
}

static inline void now_iso(char out[64])
{
  std::time_t t = std::time(nullptr);
  std::tm tmv;
#if defined(_WIN32)
  gmtime_s(&tmv, &t);
#else
  gmtime_r(&t, &tmv);
#endif
  std::strftime(out, 64, "%Y-%m-%dT%H:%M:%SZ", &tmv);
}

static inline std::string gen_id(const char *prefix)
{
  std::time_t t = std::time(nullptr);
  char buf[64];
  std::snprintf(buf, sizeof(buf), "%s_%lld", prefix, (long long)t);
  return std::string(buf);
}

static inline int contains_comma(const char *s)
{
  return std::strchr(s, ',') != nullptr;
}

static inline void trim_ascii(std::string &s)
{
  while (!s.empty() && (s.front() == ' ' || s.front() == '\t'))
    s.erase(s.begin());
  while (!s.empty() && (s.back() == ' ' || s.back() == '\t'))
    s.pop_back();
}

static inline int json_print_csv_items(const char *path)
{
  FILE *f = std::fopen(path, "rb");
  if (!f)
  {
    json_err("io_error", "无法打开CSV");
    return 0;
  }

  char line[4096];
  if (!std::fgets(line, sizeof(line), f))
  {
    std::fclose(f);
    json_ok_start();
    std::fputs("{\"items\":[]}", stdout);
    json_ok_end();
    return 1;
  }

  auto headers = csv_split(line);

  json_ok_start();
  std::fputs("{\"items\":[", stdout);
  int first = 1;
  while (std::fgets(line, sizeof(line), f))
  {
    auto fields = csv_split(line);
    if (fields.size() == 1 && fields[0].empty())
      continue;

    if (!first)
      std::fputs(",", stdout);
    first = 0;
    std::fputs("{", stdout);
    int inner_first = 1;
    size_t n = headers.size() < fields.size() ? headers.size() : fields.size();
    for (size_t i = 0; i < n; i++)
    {
      if (!inner_first)
        std::fputs(",", stdout);
      inner_first = 0;
      std::fputs("\"", stdout);
      json_escape(headers[i].c_str());
      std::fputs("\":\"", stdout);
      trim_ascii(fields[i]);
      json_escape(fields[i].c_str());
      std::fputs("\"", stdout);
    }
    std::fputs("}", stdout);
  }
  std::fclose(f);
  std::fputs("]}", stdout);
  json_ok_end();
  return 1;
}
