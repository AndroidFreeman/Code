#include "common.hpp"

int main(int argc, char **argv) {
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 4) {
    json_err("bad_request", "参数不足：todos_add <data_dir> <owner_profile_id> <title> [due_at]");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *owner = args[2].c_str();
  const char *title = args[3].c_str();
  const char *due_at = (args.size() >= 5) ? args[4].c_str() : "";

  if (contains_comma(owner) || contains_comma(title) || contains_comma(due_at)) {
    json_err("bad_request", "字段中不能包含逗号");
    return 2;
  }

  char path[1024];
  path_join(path, sizeof(path), data_dir, "todos.csv");
  if (!ensure_csv_with_header(path, "id,owner_profile_id,title,is_done,due_at,created_at,updated_at")) {
    json_err("io_error", "无法创建 todos.csv");
    return 1;
  }

  std::string id = gen_id("td");
  char ts[64];
  now_iso(ts);
  char row[2048];
  std::snprintf(row, sizeof(row), "%s,%s,%s,false,%s,%s,%s", id.c_str(), owner, title, due_at, ts, ts);
  if (!append_line(path, row)) {
    json_err("io_error", "写入 todos.csv 失败");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"id\":\"", stdout);
  json_escape(id.c_str());
  std::fputs("\"}", stdout);
  json_ok_end();
  return 0;
}
