#include "common.hpp"

int main(int argc, char **argv)
{
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 2)
  {
    json_err("bad_request", "参数不足：profiles_list <data_dir>");
    return 2;
  }
  const char *data_dir = args[1].c_str();
  char path[1024];
  path_join(path, sizeof(path), data_dir, "profiles.csv");
  return json_print_csv_items(path) ? 0 : 1;
}
