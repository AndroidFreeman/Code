#include "common.hpp"

static int overwrite_file(const char *path, const std::string &content) {
  char tmp[1024];
  std::snprintf(tmp, sizeof(tmp), "%s.tmp", path);
  FILE *f = std::fopen(tmp, "wb");
  if (!f) return 0;
  std::fwrite(content.data(), 1, content.size(), f);
  std::fclose(f);
  std::remove(path);
  if (std::rename(tmp, path) != 0) {
    std::remove(tmp);
    return 0;
  }
  return 1;
}

int main(int argc, char **argv) {
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 3) {
    json_err("bad_request", "参数不足：todos_toggle <data_dir> <id>");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *id = args[2].c_str();

  char path[1024];
  path_join(path, sizeof(path), data_dir, "todos.csv");
  FILE *f = std::fopen(path, "rb");
  if (!f) {
    json_err("io_error", "读取 todos.csv 失败");
    return 1;
  }

  char line[4096];
  std::string out;
  if (std::fgets(line, sizeof(line), f)) {
    out += line;
  }

  int found = 0;
  char ts[64];
  now_iso(ts);
  while (std::fgets(line, sizeof(line), f)) {
    auto fields = csv_split(line);
    if (fields.size() >= 7 && fields[0] == id) {
      found = 1;
      const char *cur = fields[3].c_str();
      const char *next = (std::strcmp(cur, "true") == 0) ? "false" : "true";
      char row[4096];
      std::snprintf(
        row,
        sizeof(row),
        "%s,%s,%s,%s,%s,%s,%s\n",
        fields[0].c_str(),
        fields[1].c_str(),
        fields[2].c_str(),
        next,
        fields[4].c_str(),
        fields[5].c_str(),
        ts
      );
      out += row;
      continue;
    }
    out += line;
  }
  std::fclose(f);

  if (!found) {
    json_err("not_found", "未找到待办");
    return 1;
  }
  if (!overwrite_file(path, out)) {
    json_err("io_error", "写回 todos.csv 失败");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"toggled\":true}", stdout);
  json_ok_end();
  return 0;
}
