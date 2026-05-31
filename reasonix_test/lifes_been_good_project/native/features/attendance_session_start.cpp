#include "common.hpp"

int main(int argc, char **argv) {
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 4) {
    json_err("bad_request", "参数不足：attendance_session_start <data_dir> <course_id> <created_by_profile_id>");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *course_id = args[2].c_str();
  const char *created_by = args[3].c_str();

  if (contains_comma(course_id) || contains_comma(created_by)) {
    json_err("bad_request", "字段中不能包含逗号");
    return 2;
  }

  char path[1024];
  path_join(path, sizeof(path), data_dir, "attendance_sessions.csv");
  if (!ensure_csv_with_header(path, "id,course_id,created_by_profile_id,started_at,ended_at")) {
    json_err("io_error", "无法创建 attendance_sessions.csv");
    return 1;
  }

  std::string id = gen_id("as");
  char ts[64];
  now_iso(ts);
  char row[2048];
  std::snprintf(row, sizeof(row), "%s,%s,%s,%s,", id.c_str(), course_id, created_by, ts);
  if (!append_line(path, row)) {
    json_err("io_error", "写入 attendance_sessions.csv 失败");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"session_id\":\"", stdout);
  json_escape(id.c_str());
  std::fputs("\"}", stdout);
  json_ok_end();
  return 0;
}
