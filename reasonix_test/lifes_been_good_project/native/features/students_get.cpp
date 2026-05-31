#include "common.hpp"

int main(int argc, char **argv) {
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 3) {
    json_err("bad_request", "参数不足：students_get <data_dir> <student_no>");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  const char *student_no = args[2].c_str();
  char path[1024];
  path_join(path, sizeof(path), data_dir, "students.csv");
  FILE *f = std::fopen(path, "rb");
  if (!f) {
    json_err("io_error", "读取 students.csv 失败");
    return 1;
  }

  char line[4096];
  if (!std::fgets(line, sizeof(line), f)) {
    std::fclose(f);
    json_err("not_found", "未找到学生");
    return 1;
  }
  auto headers = csv_split(line);

  std::vector<std::string> found;
  while (std::fgets(line, sizeof(line), f)) {
    auto fields = csv_split(line);
    if (fields.size() >= 2 && fields[1] == student_no) {
      found = fields;
      break;
    }
  }
  std::fclose(f);

  if (found.empty()) {
    json_err("not_found", "未找到学生");
    return 1;
  }

  json_ok_start();
  std::fputs("{\"student\":{", stdout);
  int first = 1;
  size_t n = headers.size() < found.size() ? headers.size() : found.size();
  for (size_t i = 0; i < n; i++) {
    if (!first) std::fputs(",", stdout);
    first = 0;
    std::fputs("\"", stdout);
    json_escape(headers[i].c_str());
    std::fputs("\":\"", stdout);
    json_escape(found[i].c_str());
    std::fputs("\"", stdout);
  }
  std::fputs("}}", stdout);
  json_ok_end();
  return 0;
}
