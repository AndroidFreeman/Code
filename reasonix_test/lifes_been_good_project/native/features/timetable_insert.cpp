#include "common.hpp"

int main(int argc, char **argv) {
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 14) {
    json_err(
      "bad_request",
      "参数不足：timetable_insert <data_dir> <id> <owner> <weekday> <start_period> <end_period> <start_time> <end_time> <course_id> <location> <creator> <is_locked> <weeks>"
    );
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *id = args[2].c_str();
  const char *owner = args[3].c_str();
  const char *weekday = args[4].c_str();
  const char *start_period = args[5].c_str();
  const char *end_period = args[6].c_str();
  const char *start_time = args[7].c_str();
  const char *end_time = args[8].c_str();
  const char *course_id = args[9].c_str();
  const char *location = args[10].c_str();
  const char *creator = args[11].c_str();
  const char *is_locked = args[12].c_str();
  const char *weeks = args[13].c_str();

  char path[1024];
  path_join(path, sizeof(path), data_dir, "timetable.csv");
  ensure_csv_with_header(
    path,
    "id,owner_profile_id,weekday,start_period,end_period,start_time,end_time,course_id,location,created_by_profile_id,is_locked,weeks"
  );

  char row[4096];
  std::snprintf(row, sizeof(row), "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"", id, owner, weekday, start_period, end_period, start_time, end_time, course_id, location, creator, is_locked, weeks);
  if (!append_line(path, row)) {
    json_err("io_error", "写入 timetable.csv 失败");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"id\":\"", stdout);
  json_escape(id);
  std::fputs("\"}", stdout);
  json_ok_end();
  return 0;
}
