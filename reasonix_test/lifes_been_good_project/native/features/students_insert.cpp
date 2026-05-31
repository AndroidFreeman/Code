#include "common.hpp"

int main(int argc, char **argv)
{
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 8)
  {
    json_err("bad_request", "参数不足：students_insert <data_dir> <id> <student_no> <full_name> <class_code> <phone> <position>");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *id = args[2].c_str();
  const char *student_no = args[3].c_str();
  const char *full_name = args[4].c_str();
  const char *class_code = args[5].c_str();
  const char *phone = args[6].c_str();
  const char *position = args[7].c_str();

  if (contains_comma(id) || contains_comma(student_no) || contains_comma(full_name) || contains_comma(class_code) || contains_comma(phone) || contains_comma(position))
  {
    json_err("bad_request", "字段中不能包含逗号");
    return 2;
  }

  char students_path[1024];
  path_join(students_path, sizeof(students_path), data_dir, "students.csv");
  if (!ensure_csv_with_header(students_path, "id,student_no,full_name,class_code,phone,position"))
  {
    json_err("io_error", "无法创建 students.csv");
    return 1;
  }

  char row[2048];
  std::snprintf(row, sizeof(row), "%s,%s,%s,%s,%s,%s", id, student_no, full_name, class_code, phone, position);
  if (!append_line(students_path, row))
  {
    json_err("io_error", "无法写入 students.csv");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"inserted\":true,\"id\":\"", stdout);
  json_escape(id);
  std::fputs("\",\"student_no\":\"", stdout);
  json_escape(student_no);
  std::fputs("\"}", stdout);
  json_ok_end();
  return 0;
}
