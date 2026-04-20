#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>

#if defined(_WIN32)
#include <direct.h>
#define MKDIR(path) _mkdir(path)
#else
#include <sys/stat.h>
#define MKDIR(path) mkdir(path, 0755)
#endif

#if defined(_WIN32)
#define STRTOK_R strtok_s
#else
#define STRTOK_R strtok_r
#endif

static void json_write_escaped(const char *s) {
  const unsigned char *p = (const unsigned char *)s;
  while (*p) {
    unsigned char c = *p++;
    if (c == '"') {
      fputs("\\\"", stdout);
      continue;
    }
    if (c == '\\') {
      fputs("\\\\", stdout);
      continue;
    }
    if (c == '\n') {
      fputs("\\n", stdout);
      continue;
    }
    if (c == '\r') {
      fputs("\\r", stdout);
      continue;
    }
    if (c == '\t') {
      fputs("\\t", stdout);
      continue;
    }
    if (c < 0x20) {
      printf("\\u%04x", (unsigned int)c);
      continue;
    }
    fputc((int)c, stdout);
  }
}

static void json_ok_start(void) {
  fputs("{\"ok\":true,\"data\":", stdout);
}

static void json_ok_end(void) {
  fputs("}", stdout);
}

static void json_err(const char *code, const char *message) {
  fputs("{\"ok\":false,\"error\":{\"code\":\"", stdout);
  json_write_escaped(code);
  fputs("\",\"message\":\"", stdout);
  json_write_escaped(message);
  fputs("\"}}", stdout);
}

static int file_exists(const char *path) {
  FILE *f = fopen(path, "rb");
  if (!f) return 0;
  fclose(f);
  return 1;
}

static int ensure_dir(const char *path) {
  if (!path || !*path) return 0;
  if (MKDIR(path) == 0) return 1;
  if (errno == EEXIST) return 1;
  return 0;
}

static int ensure_dir_recursive(const char *path) {
  if (!path || !*path) return 0;
  char buf[1024];
  strncpy(buf, path, sizeof(buf) - 1);
  buf[sizeof(buf) - 1] = '\0';
  size_t len = strlen(buf);

  for (size_t i = 1; i < len; i++) {
    if (buf[i] == '/' || buf[i] == '\\') {
      char saved = buf[i];
      buf[i] = '\0';
      size_t bl = strlen(buf);
      int skip = 0;
      if (bl == 2 && buf[1] == ':') skip = 1;
      if (!skip) ensure_dir(buf);
      buf[i] = saved;
    }
  }
  return ensure_dir(buf);
}

static void path_join(char *out, size_t out_sz, const char *dir, const char *name) {
  size_t dl = strlen(dir);
  const char *sep = (dl > 0 && (dir[dl - 1] == '/' || dir[dl - 1] == '\\')) ? "" : "/";
  snprintf(out, out_sz, "%s%s%s", dir, sep, name);
}

static char *read_all_stdin(void) {
  size_t cap = 4096;
  size_t len = 0;
  char *buf = (char *)malloc(cap);
  if (!buf) return NULL;
  int ch;
  while ((ch = fgetc(stdin)) != EOF) {
    if (len + 1 >= cap) {
      size_t ncap = cap * 2;
      char *nb = (char *)realloc(buf, ncap);
      if (!nb) {
        free(buf);
        return NULL;
      }
      buf = nb;
      cap = ncap;
    }
    buf[len++] = (char)ch;
  }
  buf[len] = '\0';
  return buf;
}

static const char *skip_ws(const char *p) {
  while (*p == ' ' || *p == '\n' || *p == '\r' || *p == '\t') p++;
  return p;
}

static const char *find_json_key(const char *json, const char *key) {
  size_t kl = strlen(key);
  const char *p = json;
  while ((p = strstr(p, "\"")) != NULL) {
    p++;
    if (strncmp(p, key, kl) == 0 && p[kl] == '"') {
      const char *q = p + kl + 1;
      q = skip_ws(q);
      if (*q != ':') {
        p = q;
        continue;
      }
      return q + 1;
    }
    p++;
  }
  return NULL;
}

static int json_get_string_at(const char *p, char *out, size_t out_sz) {
  p = skip_ws(p);
  if (*p != '"') return 0;
  p++;
  size_t i = 0;
  while (*p && *p != '"') {
    if (*p == '\\') {
      p++;
      if (!*p) break;
      char c = *p;
      if (c == '"' || c == '\\' || c == '/') {
        if (i + 1 < out_sz) out[i++] = c;
        p++;
        continue;
      }
      if (c == 'n') {
        if (i + 1 < out_sz) out[i++] = '\n';
        p++;
        continue;
      }
      if (c == 'r') {
        if (i + 1 < out_sz) out[i++] = '\r';
        p++;
        continue;
      }
      if (c == 't') {
        if (i + 1 < out_sz) out[i++] = '\t';
        p++;
        continue;
      }
      p++;
      continue;
    }
    if (i + 1 < out_sz) out[i++] = *p;
    p++;
  }
  out[i] = '\0';
  return *p == '"';
}

static int json_get_string(const char *json, const char *key, char *out, size_t out_sz) {
  const char *p = find_json_key(json, key);
  if (!p) return 0;
  return json_get_string_at(p, out, out_sz);
}

static const char *json_get_object_range(const char *json, const char *key, const char **out_end) {
  const char *p = find_json_key(json, key);
  if (!p) return NULL;
  p = skip_ws(p);
  if (*p != '{') return NULL;
  int depth = 0;
  const char *q = p;
  while (*q) {
    if (*q == '"') {
      q++;
      while (*q && *q != '"') {
        if (*q == '\\' && q[1]) q += 2;
        else q++;
      }
      if (*q == '"') q++;
      continue;
    }
    if (*q == '{') depth++;
    else if (*q == '}') {
      depth--;
      if (depth == 0) {
        if (out_end) *out_end = q + 1;
        return p;
      }
    }
    q++;
  }
  return NULL;
}

static int csv_split_inplace(char *line, char **fields, int max_fields) {
  int n = 0;
  char *p = line;
  while (*p && n < max_fields) {
    fields[n++] = p;
    while (*p && *p != ',' && *p != '\n' && *p != '\r') p++;
    if (*p == ',') {
      *p = '\0';
      p++;
      continue;
    }
    if (*p == '\r' || *p == '\n') {
      *p = '\0';
      break;
    }
    if (!*p) break;
  }
  return n;
}

static int ensure_csv_with_header(const char *path, const char *header) {
  if (file_exists(path)) return 1;
  FILE *f = fopen(path, "wb");
  if (!f) return 0;
  fputs(header, f);
  fputs("\n", f);
  fclose(f);
  return 1;
}

static void now_iso(char *out, size_t out_sz) {
  time_t t = time(NULL);
  struct tm tmv;
#if defined(_WIN32)
  gmtime_s(&tmv, &t);
#else
  gmtime_r(&t, &tmv);
#endif
  strftime(out, out_sz, "%Y-%m-%dT%H:%M:%SZ", &tmv);
}

static void gen_id(char *out, size_t out_sz, const char *prefix) {
  char ts[32];
  now_iso(ts, sizeof(ts));
  unsigned int r = (unsigned int)rand();
  snprintf(out, out_sz, "%s_%s_%08x", prefix, ts, r);
  for (char *p = out; *p; p++) {
    if (*p == ':' || *p == '-') *p = '_';
  }
}

static int write_line_append(const char *path, const char *line) {
  FILE *f = fopen(path, "ab");
  if (!f) return 0;
  fputs(line, f);
  fputs("\n", f);
  fclose(f);
  return 1;
}

static char *read_file_all(const char *path) {
  FILE *f = fopen(path, "rb");
  if (!f) return NULL;
  fseek(f, 0, SEEK_END);
  long sz = ftell(f);
  if (sz < 0) {
    fclose(f);
    return NULL;
  }
  fseek(f, 0, SEEK_SET);
  char *buf = (char *)malloc((size_t)sz + 1);
  if (!buf) {
    fclose(f);
    return NULL;
  }
  size_t rd = fread(buf, 1, (size_t)sz, f);
  fclose(f);
  buf[rd] = '\0';
  return buf;
}

static int overwrite_file(const char *path, const char *content) {
  char tmp[1024];
  snprintf(tmp, sizeof(tmp), "%s.tmp", path);
  FILE *f = fopen(tmp, "wb");
  if (!f) return 0;
  fputs(content, f);
  fclose(f);
  remove(path);
  if (rename(tmp, path) != 0) {
    remove(tmp);
    return 0;
  }
  return 1;
}

static int action_system_init(const char *data_dir, int seed) {
  if (!ensure_dir_recursive(data_dir)) {
    json_err("io_error", "无法创建数据目录");
    return 0;
  }

  char p[1024];
  path_join(p, sizeof(p), data_dir, "profiles.csv");
  if (!ensure_csv_with_header(p, "id,role,display_name,org_code,class_code")) {
    json_err("io_error", "无法创建 profiles.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "students.csv");
  if (!ensure_csv_with_header(p, "id,student_no,full_name,class_code,phone,position")) {
    json_err("io_error", "无法创建 students.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "courses.csv");
  if (!ensure_csv_with_header(p, "id,course_name,teacher_profile_id,term_code,color,credits,notes")) {
    json_err("io_error", "无法创建 courses.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "course_members.csv");
  if (!ensure_csv_with_header(p, "id,course_id,student_id")) {
    json_err("io_error", "无法创建 course_members.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "timetable.csv");
  if (!ensure_csv_with_header(p, "id,owner_profile_id,weekday,start_period,end_period,start_time,end_time,course_id,location,created_by_profile_id,is_locked,weeks")) {
    json_err("io_error", "无法创建 timetable.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "attendance_sessions.csv");
  if (!ensure_csv_with_header(p, "id,course_id,created_by_profile_id,started_at,ended_at")) {
    json_err("io_error", "无法创建 attendance_sessions.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "attendance_records.csv");
  if (!ensure_csv_with_header(p, "id,session_id,student_id,status,marked_at,marked_by_profile_id")) {
    json_err("io_error", "无法创建 attendance_records.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "todos.csv");
  if (!ensure_csv_with_header(p, "id,owner_profile_id,title,is_done,due_at,created_at,updated_at")) {
    json_err("io_error", "无法创建 todos.csv");
    return 0;
  }
  path_join(p, sizeof(p), data_dir, "contacts.csv");
  if (!ensure_csv_with_header(p, "id,owner_profile_id,contact_profile_id,alias,phone")) {
    json_err("io_error", "无法创建 contacts.csv");
    return 0;
  }

  if (seed) {
    char profiles_path[1024];
    path_join(profiles_path, sizeof(profiles_path), data_dir, "profiles.csv");
    char students_path[1024];
    path_join(students_path, sizeof(students_path), data_dir, "students.csv");
    char courses_path[1024];
    path_join(courses_path, sizeof(courses_path), data_dir, "courses.csv");
    char members_path[1024];
    path_join(members_path, sizeof(members_path), data_dir, "course_members.csv");
    char timetable_path[1024];
    path_join(timetable_path, sizeof(timetable_path), data_dir, "timetable.csv");
    char todos_path[1024];
    path_join(todos_path, sizeof(todos_path), data_dir, "todos.csv");

    char *profiles_txt = read_file_all(profiles_path);
    char *students_txt = read_file_all(students_path);
    char *courses_txt = read_file_all(courses_path);
    char *members_txt = read_file_all(members_path);
    char *timetable_txt = read_file_all(timetable_path);
    char *todos_txt = read_file_all(todos_path);

    int need_seed = 1;
    if (profiles_txt) {
      const char *p1 = strchr(profiles_txt, '\n');
      if (p1 && strchr(p1 + 1, '\n')) need_seed = 0;
    }

    if (need_seed) {
      write_line_append(profiles_path, "u_teacher_001,teacher,王老师,ORG1,CLS1");
      write_line_append(profiles_path, "u_student_001,student,张同学,ORG1,CLS1");
      write_line_append(profiles_path, "u_cadre_001,cadre,李班长,ORG1,CLS1");

      write_line_append(students_path, "s_001,20260001,张同学,CLS1,13800000001,");
      write_line_append(students_path, "s_002,20260002,李班长,CLS1,13800000002,cadre");

      write_line_append(courses_path, "c_001,高等数学,u_teacher_001,2026S,4289372671,2,重点课程");
      write_line_append(members_path, "cm_001,c_001,s_001");
      write_line_append(members_path, "cm_002,c_001,s_002");

      write_line_append(timetable_path, "tt_001,u_student_001,1,1,2,08:00,09:40,c_001,教一101,u_teacher_001,true,1-20");
      write_line_append(timetable_path, "tt_002,u_cadre_001,1,1,2,08:00,09:40,c_001,教一101,u_teacher_001,true,1-20");

      write_line_append(todos_path, "td_001,u_student_001,完成作业,false,,2026-03-01T00:00:00Z,2026-03-01T00:00:00Z");
    }

    free(profiles_txt);
    free(students_txt);
    free(courses_txt);
    free(members_txt);
    free(timetable_txt);
    free(todos_txt);
  }

  json_ok_start();
  fputs("{\"initialized\":true}", stdout);
  json_ok_end();
  return 1;
}

static void json_print_csv_list(const char *path, int max_fields) {
  FILE *f = fopen(path, "rb");
  if (!f) {
    fputs("[]", stdout);
    return;
  }
  char line[4096];
  char headers_store[64][128];
  int header_n = 0;
  if (fgets(line, sizeof(line), f)) {
    char *headers_tmp[64];
    header_n = csv_split_inplace(line, headers_tmp, max_fields);
    if (header_n > 64) header_n = 64;
    for (int i = 0; i < header_n; i++) {
      strncpy(headers_store[i], headers_tmp[i], sizeof(headers_store[i]) - 1);
      headers_store[i][sizeof(headers_store[i]) - 1] = '\0';
    }
  }
  fputs("[", stdout);
  int first_row = 1;
  while (fgets(line, sizeof(line), f)) {
    char *fields[64];
    int n = csv_split_inplace(line, fields, max_fields);
    if (n <= 0) continue;
    if (!first_row) fputs(",", stdout);
    first_row = 0;
    fputs("{", stdout);
    int first_field = 1;
    for (int i = 0; i < header_n && i < n; i++) {
      if (!first_field) fputs(",", stdout);
      first_field = 0;
      fputs("\"", stdout);
      json_write_escaped(headers_store[i]);
      fputs("\":\"", stdout);
      json_write_escaped(fields[i]);
      fputs("\"", stdout);
    }
    fputs("}", stdout);
  }
  fputs("]", stdout);
  fclose(f);
}

static int action_list_simple(const char *data_dir, const char *file, int max_fields, const char *data_key) {
  char p[1024];
  path_join(p, sizeof(p), data_dir, file);
  json_ok_start();
  fputs("{\"", stdout);
  json_write_escaped(data_key);
  fputs("\":", stdout);
  json_print_csv_list(p, max_fields);
  fputs("}", stdout);
  json_ok_end();
  return 1;
}

static int action_todos_add(const char *data_dir, const char *payload_json) {
  char owner[128];
  char title[512];
  char due_at[64];
  owner[0] = '\0';
  title[0] = '\0';
  due_at[0] = '\0';

  if (!json_get_string(payload_json, "owner", owner, sizeof(owner))) {
    json_err("bad_request", "缺少 owner");
    return 0;
  }
  if (!json_get_string(payload_json, "title", title, sizeof(title))) {
    json_err("bad_request", "缺少 title");
    return 0;
  }
  json_get_string(payload_json, "due_at", due_at, sizeof(due_at));

  char id[128];
  gen_id(id, sizeof(id), "td");
  char now[64];
  now_iso(now, sizeof(now));

  char row[2048];
  snprintf(row, sizeof(row), "%s,%s,%s,false,%s,%s,%s", id, owner, title, due_at, now, now);

  char path[1024];
  path_join(path, sizeof(path), data_dir, "todos.csv");
  if (!write_line_append(path, row)) {
    json_err("io_error", "写入 todos.csv 失败");
    return 0;
  }

  json_ok_start();
  fputs("{\"id\":\"", stdout);
  json_write_escaped(id);
  fputs("\"}", stdout);
  json_ok_end();
  return 1;
}

static int action_todos_toggle(const char *data_dir, const char *payload_json) {
  char id[128];
  id[0] = '\0';
  if (!json_get_string(payload_json, "id", id, sizeof(id))) {
    json_err("bad_request", "缺少 id");
    return 0;
  }

  char path[1024];
  path_join(path, sizeof(path), data_dir, "todos.csv");
  char *txt = read_file_all(path);
  if (!txt) {
    json_err("io_error", "读取 todos.csv 失败");
    return 0;
  }

  char *out = (char *)malloc(strlen(txt) + 4096);
  if (!out) {
    free(txt);
    json_err("io_error", "内存不足");
    return 0;
  }
  out[0] = '\0';

  char *saveptr = NULL;
  char *line = STRTOK_R(txt, "\n", &saveptr);
  int line_idx = 0;
  int updated = 0;
  while (line) {
    size_t ll = strlen(line);
    if (ll > 0 && line[ll - 1] == '\r') line[ll - 1] = '\0';
    if (line_idx == 0) {
      strcat(out, line);
      strcat(out, "\n");
      line_idx++;
      line = STRTOK_R(NULL, "\n", &saveptr);
      continue;
    }
    char buf[4096];
    strncpy(buf, line, sizeof(buf) - 1);
    buf[sizeof(buf) - 1] = '\0';
    char *fields[16];
    int n = csv_split_inplace(buf, fields, 16);
    if (n >= 7 && strcmp(fields[0], id) == 0) {
      const char *cur = fields[3];
      const char *next = (strcmp(cur, "true") == 0) ? "false" : "true";
      char now[64];
      now_iso(now, sizeof(now));
      char row[4096];
      snprintf(row, sizeof(row), "%s,%s,%s,%s,%s,%s,%s", fields[0], fields[1], fields[2], next, fields[4], fields[5], now);
      strcat(out, row);
      strcat(out, "\n");
      updated = 1;
    } else {
      strcat(out, line);
      strcat(out, "\n");
    }
    line_idx++;
    line = STRTOK_R(NULL, "\n", &saveptr);
  }

  free(txt);

  if (!updated) {
    free(out);
    json_err("not_found", "未找到 todo");
    return 0;
  }

  if (!overwrite_file(path, out)) {
    free(out);
    json_err("io_error", "写入 todos.csv 失败");
    return 0;
  }
  free(out);
  json_ok_start();
  fputs("{\"updated\":true}", stdout);
  json_ok_end();
  return 1;
}

static int action_attendance_session_start(const char *data_dir, const char *payload_json) {
  char course_id[128];
  char created_by[128];
  course_id[0] = '\0';
  created_by[0] = '\0';
  if (!json_get_string(payload_json, "course_id", course_id, sizeof(course_id))) {
    json_err("bad_request", "缺少 course_id");
    return 0;
  }
  if (!json_get_string(payload_json, "created_by", created_by, sizeof(created_by))) {
    json_err("bad_request", "缺少 created_by");
    return 0;
  }

  char id[128];
  gen_id(id, sizeof(id), "as");
  char started_at[64];
  now_iso(started_at, sizeof(started_at));

  char row[1024];
  snprintf(row, sizeof(row), "%s,%s,%s,%s,", id, course_id, created_by, started_at);

  char path[1024];
  path_join(path, sizeof(path), data_dir, "attendance_sessions.csv");
  if (!write_line_append(path, row)) {
    json_err("io_error", "写入 attendance_sessions.csv 失败");
    return 0;
  }

  json_ok_start();
  fputs("{\"session_id\":\"", stdout);
  json_write_escaped(id);
  fputs("\",\"started_at\":\"", stdout);
  json_write_escaped(started_at);
  fputs("\"}", stdout);
  json_ok_end();
  return 1;
}

static int action_attendance_record_mark(const char *data_dir, const char *payload_json) {
  char session_id[128];
  char student_id[128];
  char status[32];
  char marked_by[128];
  session_id[0] = '\0';
  student_id[0] = '\0';
  status[0] = '\0';
  marked_by[0] = '\0';

  if (!json_get_string(payload_json, "session_id", session_id, sizeof(session_id))) {
    json_err("bad_request", "缺少 session_id");
    return 0;
  }
  if (!json_get_string(payload_json, "student_id", student_id, sizeof(student_id))) {
    json_err("bad_request", "缺少 student_id");
    return 0;
  }
  if (!json_get_string(payload_json, "status", status, sizeof(status))) {
    json_err("bad_request", "缺少 status");
    return 0;
  }
  if (!json_get_string(payload_json, "marked_by", marked_by, sizeof(marked_by))) {
    json_err("bad_request", "缺少 marked_by");
    return 0;
  }

  char id[128];
  gen_id(id, sizeof(id), "ar");
  char marked_at[64];
  now_iso(marked_at, sizeof(marked_at));
  char row[1024];
  snprintf(row, sizeof(row), "%s,%s,%s,%s,%s,%s", id, session_id, student_id, status, marked_at, marked_by);

  char path[1024];
  path_join(path, sizeof(path), data_dir, "attendance_records.csv");
  if (!write_line_append(path, row)) {
    json_err("io_error", "写入 attendance_records.csv 失败");
    return 0;
  }

  json_ok_start();
  fputs("{\"record_id\":\"", stdout);
  json_write_escaped(id);
  fputs("\"}", stdout);
  json_ok_end();
  return 1;
}

static int action_students_get_by_student_no(const char *data_dir, const char *payload_json) {
  char student_no[128];
  student_no[0] = '\0';
  if (!json_get_string(payload_json, "student_no", student_no, sizeof(student_no))) {
    json_err("bad_request", "缺少 student_no");
    return 0;
  }

  char path[1024];
  path_join(path, sizeof(path), data_dir, "students.csv");
  FILE *f = fopen(path, "rb");
  if (!f) {
    json_err("io_error", "读取 students.csv 失败");
    return 0;
  }
  char line[4096];
  char *headers[16];
  int header_n = 0;
  if (fgets(line, sizeof(line), f)) {
    header_n = csv_split_inplace(line, headers, 16);
  }
  int found = 0;
  char found_line[4096];
  found_line[0] = '\0';
  while (fgets(line, sizeof(line), f)) {
    char buf[4096];
    strncpy(buf, line, sizeof(buf) - 1);
    buf[sizeof(buf) - 1] = '\0';
    char *fields[16];
    int n = csv_split_inplace(buf, fields, 16);
    if (n >= 2 && strcmp(fields[1], student_no) == 0) {
      strncpy(found_line, line, sizeof(found_line) - 1);
      found_line[sizeof(found_line) - 1] = '\0';
      found = 1;
      break;
    }
  }
  fclose(f);

  if (!found) {
    json_err("not_found", "未找到学生");
    return 0;
  }

  char buf[4096];
  strncpy(buf, found_line, sizeof(buf) - 1);
  buf[sizeof(buf) - 1] = '\0';
  char *fields[16];
  int n = csv_split_inplace(buf, fields, 16);

  json_ok_start();
  fputs("{\"student\":{", stdout);
  int first = 1;
  for (int i = 0; i < header_n && i < n; i++) {
    if (!first) fputs(",", stdout);
    first = 0;
    fputs("\"", stdout);
    json_write_escaped(headers[i]);
    fputs("\":\"", stdout);
    json_write_escaped(fields[i]);
    fputs("\"", stdout);
  }
  fputs("}}", stdout);
  json_ok_end();
  return 1;
}

static int parse_args(int argc, char **argv, const char **data_dir, int *use_stdin, int *seed, const char **action) {
  *data_dir = NULL;
  *use_stdin = 0;
  *seed = 0;
  *action = NULL;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--data-dir") == 0 && i + 1 < argc) {
      *data_dir = argv[++i];
      continue;
    }
    if (strcmp(argv[i], "--stdin") == 0) {
      *use_stdin = 1;
      continue;
    }
    if (strcmp(argv[i], "--seed") == 0) {
      *seed = 1;
      continue;
    }
    if (!*action) {
      *action = argv[i];
      continue;
    }
  }
  return 1;
}

int main(int argc, char **argv) {
  srand((unsigned int)time(NULL));
  const char *data_dir = NULL;
  int use_stdin = 0;
  int seed = 0;
  const char *action = NULL;
  parse_args(argc, argv, &data_dir, &use_stdin, &seed, &action);

  const char *request_arg = NULL;
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--request") == 0 && i + 1 < argc) {
      request_arg = argv[i + 1];
      break;
    }
  }

  if (!data_dir || !*data_dir) {
    json_err("bad_request", "缺少 --data-dir");
    return 2;
  }

  if (!action || !*action) {
    json_err("bad_request", "缺少 action");
    return 2;
  }

  if (strcmp(action, "system.init") == 0) {
    return action_system_init(data_dir, seed) ? 0 : 1;
  }

  char *req_owned = NULL;
  const char *req = NULL;
  if (request_arg && *request_arg) {
    req = request_arg;
  } else if (use_stdin) {
    req_owned = read_all_stdin();
    if (!req_owned) {
      json_err("io_error", "读取 stdin 失败");
      return 1;
    }
    req = req_owned;
  } else {
    json_err("bad_request", "缺少 --request 或 --stdin");
    return 2;
  }

  char action_in[128];
  action_in[0] = '\0';
  if (!json_get_string(req, "action", action_in, sizeof(action_in))) {
    free(req_owned);
    json_err("bad_request", "请求缺少 action");
    return 1;
  }

  const char *payload_end = NULL;
  const char *payload = json_get_object_range(req, "payload", &payload_end);
  char payload_buf[4096];
  payload_buf[0] = '\0';
  if (payload && payload_end && payload_end > payload) {
    size_t pl = (size_t)(payload_end - payload);
    if (pl >= sizeof(payload_buf)) pl = sizeof(payload_buf) - 1;
    memcpy(payload_buf, payload, pl);
    payload_buf[pl] = '\0';
  } else {
    strcpy(payload_buf, "{}");
  }

  int ok = 0;
  if (strcmp(action_in, "profiles.list") == 0) {
    ok = action_list_simple(data_dir, "profiles.csv", 16, "items");
  } else if (strcmp(action_in, "students.list") == 0) {
    ok = action_list_simple(data_dir, "students.csv", 16, "items");
  } else if (strcmp(action_in, "courses.list") == 0) {
    ok = action_list_simple(data_dir, "courses.csv", 16, "items");
  } else if (strcmp(action_in, "timetable.list") == 0) {
    ok = action_list_simple(data_dir, "timetable.csv", 16, "items");
  } else if (strcmp(action_in, "contacts.list") == 0) {
    ok = action_list_simple(data_dir, "contacts.csv", 16, "items");
  } else if (strcmp(action_in, "todos.list") == 0) {
    ok = action_list_simple(data_dir, "todos.csv", 16, "items");
  } else if (strcmp(action_in, "todos.add") == 0) {
    ok = action_todos_add(data_dir, payload_buf);
  } else if (strcmp(action_in, "todos.toggle") == 0) {
    ok = action_todos_toggle(data_dir, payload_buf);
  } else if (strcmp(action_in, "students.get") == 0) {
    ok = action_students_get_by_student_no(data_dir, payload_buf);
  } else if (strcmp(action_in, "attendance.session.start") == 0) {
    ok = action_attendance_session_start(data_dir, payload_buf);
  } else if (strcmp(action_in, "attendance.record.mark") == 0) {
    ok = action_attendance_record_mark(data_dir, payload_buf);
  } else {
    json_err("bad_request", "未知 action");
    ok = 0;
  }

  free(req_owned);
  return ok ? 0 : 1;
}

