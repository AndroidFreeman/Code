#include "common.hpp"

int main(int argc, char **argv)
{
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 4)
  {
    json_err("bad_request", "参数不足：students_delete <data_dir> <full_name> <student_no>");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *full_name = args[2].c_str();
  const char *student_no = args[3].c_str();

  char students_path[1024];
  path_join(students_path, sizeof(students_path), data_dir, "students.csv");
  char tmp_path[1024];
  std::snprintf(tmp_path, sizeof(tmp_path), "%s.tmp", students_path);

  FILE *in = std::fopen(students_path, "rb");
  if (!in)
  {
    json_err("io_error", "无法打开 students.csv");
    return 1;
  }
  FILE *out = std::fopen(tmp_path, "wb");
  if (!out)
  {
    std::fclose(in);
    json_err("io_error", "无法创建临时文件");
    return 1;
  }

  char line[4096];
  int found = 0;

  if (!std::fgets(line, sizeof(line), in))
  {
    std::fclose(in);
    std::fclose(out);
    std::remove(tmp_path);
    json_err("io_error", "students.csv 为空");
    return 1;
  }
  std::fputs(line, out);

  while (std::fgets(line, sizeof(line), in))
  {
    auto fields = csv_split(line);
    if (fields.size() >= 3 && fields[1] == student_no && fields[2] == full_name)
    {
      found = 1;
      continue;
    }
    std::fputs(line, out);
  }

  std::fclose(in);
  std::fclose(out);

  std::remove(students_path);
  if (std::rename(tmp_path, students_path) != 0)
  {
    std::remove(tmp_path);
    json_err("io_error", "写回 students.csv 失败");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"found\":", stdout);
  std::fputs(found ? "true" : "false", stdout);
  std::fputs(",\"full_name\":\"", stdout);
  json_escape(full_name);
  std::fputs("\",\"student_no\":\"", stdout);
  json_escape(student_no);
  std::fputs("\"}", stdout);
  json_ok_end();
  return 0;
}
