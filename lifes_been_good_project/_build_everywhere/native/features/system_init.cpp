#include "common.hpp"

int main(int argc, char **argv)
{
  auto args = get_args_utf8(argc, argv);
  if (args.size() < 2)
  {
    json_err("bad_request", "参数不足：system_init <data_dir> [--seed]");
    return 2;
  }

  const char *data_dir = args[1].c_str();
  int seed = 0;
  for (size_t i = 2; i < args.size(); i++)
  {
    if (args[i] == "--seed")
      seed = 1;
  }

  if (!ensure_dir_recursive(data_dir))
  {
    json_err("io_error", "无法创建数据目录");
    return 1;
  }

  char p[1024];
  path_join(p, sizeof(p), data_dir, "profiles.csv");
  if (!ensure_csv_with_header(p, "id,role,staff_no,student_no,display_name,org_code,class_code,password_hash,created_at"))
  {
    json_err("io_error", "无法创建 profiles.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "students.csv");
  if (!ensure_csv_with_header(p, "id,student_no,full_name,class_code,phone,position"))
  {
    json_err("io_error", "无法创建 students.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "courses.csv");
  if (!ensure_csv_with_header(p, "id,course_name,teacher_profile_id,term_code,color,credits,notes"))
  {
    json_err("io_error", "无法创建 courses.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "course_members.csv");
  if (!ensure_csv_with_header(p, "id,course_id,student_id"))
  {
    json_err("io_error", "无法创建 course_members.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "timetable.csv");
  if (!ensure_csv_with_header(
          p,
          "id,owner_profile_id,weekday,start_period,end_period,start_time,end_time,course_id,location,created_by_profile_id,is_locked,weeks"))
  {
    json_err("io_error", "无法创建 timetable.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "attendance_sessions.csv");
  if (!ensure_csv_with_header(p, "id,course_id,created_by_profile_id,started_at,ended_at"))
  {
    json_err("io_error", "无法创建 attendance_sessions.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "attendance_records.csv");
  if (!ensure_csv_with_header(p, "id,session_id,student_id,status,marked_at,marked_by_profile_id"))
  {
    json_err("io_error", "无法创建 attendance_records.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "todos.csv");
  if (!ensure_csv_with_header(p, "id,owner_profile_id,title,is_done,due_at,created_at,updated_at"))
  {
    json_err("io_error", "无法创建 todos.csv");
    return 1;
  }
  path_join(p, sizeof(p), data_dir, "contacts.csv");
  if (!ensure_csv_with_header(p, "id,owner_profile_id,contact_profile_id,alias,phone"))
  {
    json_err("io_error", "无法创建 contacts.csv");
    return 1;
  }

  if (seed)
  {
    char profiles_path[1024];
    path_join(profiles_path, sizeof(profiles_path), data_dir, "profiles.csv");
    if (!file_has_data_rows(profiles_path))
    {
      char ts[64];
      now_iso(ts);
      std::string pw = fnv1a64_hex("123456");
      append_line(profiles_path, (std::string("u_teacher_001,teacher,T001,,王老师,ORG1,CLS1,") + pw + "," + ts).c_str());
      append_line(profiles_path, (std::string("u_student_001,student,,S001,张同学,ORG1,CLS1,") + pw + "," + ts).c_str());
      append_line(profiles_path, (std::string("u_student_002,student,,S002,李班长,ORG1,CLS1,") + pw + "," + ts).c_str());
    }

    char students_path[1024];
    path_join(students_path, sizeof(students_path), data_dir, "students.csv");
    if (!file_has_data_rows(students_path))
    {
      append_line(students_path, "s_001,20260001,张同学,CLS1,13800000001,");
      append_line(students_path, "s_002,20260002,李班长,CLS1,13800000002,cadre");
    }

    char courses_path[1024];
    path_join(courses_path, sizeof(courses_path), data_dir, "courses.csv");
    if (!file_has_data_rows(courses_path))
    {
      append_line(courses_path, "c_001,高等数学,u_teacher_001,2026S,4289372671,2,重点课程");
    }

    char members_path[1024];
    path_join(members_path, sizeof(members_path), data_dir, "course_members.csv");
    if (!file_has_data_rows(members_path))
    {
      append_line(members_path, "cm_001,c_001,s_001");
      append_line(members_path, "cm_002,c_001,s_002");
    }

    char timetable_path[1024];
    path_join(timetable_path, sizeof(timetable_path), data_dir, "timetable.csv");
    if (!file_has_data_rows(timetable_path))
    {
      append_line(timetable_path, "tt_001,u_student_001,1,1,2,08:00,09:40,c_001,教一101,u_teacher_001,true,1-20");
      append_line(timetable_path, "tt_002,u_student_002,1,1,2,08:00,09:40,c_001,教一101,u_teacher_001,true,1-20");
    }

    char todos_path[1024];
    path_join(todos_path, sizeof(todos_path), data_dir, "todos.csv");
    if (!file_has_data_rows(todos_path))
    {
      append_line(todos_path, "td_001,u_student_001,完成作业,false,,2026-03-01T00:00:00Z,2026-03-01T00:00:00Z");
    }
  }

  json_ok_start();
  std::fputs("{\"initialized\":true}", stdout);
  json_ok_end();
  return 0;
}
