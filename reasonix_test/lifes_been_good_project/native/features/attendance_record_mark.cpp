#include "common.hpp"

int main(int argc, char **argv) {
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 6) {
    json_err(
      "bad_request",
      "参数不足：attendance_record_mark <data_dir> <session_id> <student_id> <status> <marked_by_profile_id>"
    );
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *session_id = args[2].c_str();
  const char *student_id = args[3].c_str();
  const char *status = args[4].c_str();
  const char *marked_by = args[5].c_str();

  if (contains_comma(session_id) || contains_comma(student_id) || contains_comma(status) || contains_comma(marked_by)) {
    json_err("bad_request", "字段中不能包含逗号");
    return 2;
  }

  char path[1024];
  path_join(path, sizeof(path), data_dir, "attendance_records.csv");
  if (!ensure_csv_with_header(path, "id,session_id,student_id,status,marked_at,marked_by_profile_id")) {
    json_err("io_error", "无法创建 attendance_records.csv");
    return 1;
  }

  std::string id = gen_id("ar");
  char ts[64];
  now_iso(ts);
  char row[2048];
  std::snprintf(row, sizeof(row), "%s,%s,%s,%s,%s,%s", id.c_str(), session_id, student_id, status, ts, marked_by);
  if (!append_line(path, row)) {
    json_err("io_error", "写入 attendance_records.csv 失败");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"record_id\":\"", stdout);
  json_escape(id.c_str());
  std::fputs("\"}", stdout);
  json_ok_end();
  return 0;
}
