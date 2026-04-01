#include "common.hpp"

int main(int argc, char **argv) {
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 9) {
    json_err(
      "bad_request",
      "参数不足：courses_insert <data_dir> <id> <name> <teacher_id> <term> <color> <credits> <notes>"
    );
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *id = args[2].c_str();
  const char *name = args[3].c_str();
  const char *teacher_id = args[4].c_str();
  const char *term = args[5].c_str();
  const char *color = args[6].c_str();
  const char *credits = args[7].c_str();
  const char *notes = args[8].c_str();

  char path[1024];
  path_join(path, sizeof(path), data_dir, "courses.csv");
  ensure_csv_with_header(path, "id,course_name,teacher_profile_id,term_code,color,credits,notes");

  char row[4096];
  std::snprintf(row, sizeof(row), "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"", id, name, teacher_id, term, color, credits, notes);
  if (!append_line(path, row)) {
    json_err("io_error", "写入 courses.csv 失败");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"id\":\"", stdout);
  json_escape(id);
  std::fputs("\"}", stdout);
  json_ok_end();
  return 0;
}
