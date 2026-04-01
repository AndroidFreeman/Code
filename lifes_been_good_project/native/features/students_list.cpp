#include "common.hpp"

int main(int argc, char **argv)
{
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 2)
  {
    json_err("bad_request", "参数不足：students_list <data_dir>");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  char students_path[1024];
  path_join(students_path, sizeof(students_path), data_dir, "students.csv");
  if (!json_print_csv_items(students_path))
    return 1;
  return 0;
}
