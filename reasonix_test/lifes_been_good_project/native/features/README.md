## native/features
这里放“一个功能一个 C 文件”的本地数据处理程序（每个文件编译成一个可执行文件）。Flutter 通过 `Process.run()` 直接调用对应的二进制。

### 约定
- 所有程序 stdout 输出 JSON：成功 `{"ok":true,"data":...}`；失败 `{"ok":false,"error":{"code":"...","message":"..."}}`
- 统一参数：第一个参数为 `data_dir`（数据目录），CSV 都从该目录读取/写入

### 已提供示例
- `system_init.cpp`
  - 用法：`system_init <data_dir> [--seed]`
  - 作用：创建所需 CSV（可选写入种子数据）
- `profiles_list.cpp`
  - 用法：`profiles_list <data_dir>`
  - 作用：读取 `profiles.csv` 返回 JSON 列表
- `courses_list.cpp`
  - 用法：`courses_list <data_dir>`
  - 作用：读取 `courses.csv` 返回 JSON 列表
- `timetable_list.cpp`
  - 用法：`timetable_list <data_dir>`
  - 作用：读取 `timetable.csv` 返回 JSON 列表
- `contacts_list.cpp`
  - 用法：`contacts_list <data_dir>`
  - 作用：读取 `contacts.csv` 返回 JSON 列表
- `todos_list.cpp`
  - 用法：`todos_list <data_dir>`
  - 作用：读取 `todos.csv` 返回 JSON 列表
- `todos_add.cpp`
  - 用法：`todos_add <data_dir> <owner_profile_id> <title> [due_at]`
  - 作用：向 `todos.csv` 追加一行
- `todos_toggle.cpp`
  - 用法：`todos_toggle <data_dir> <id>`
  - 作用：切换 `todos.csv` 的 `is_done`
- `students_list.cpp`
  - 用法：`students_list <data_dir>`
  - 作用：读取 `students.csv` 返回 JSON 列表
- `students_insert.cpp`
  - 用法：`students_insert <data_dir> <id> <student_no> <full_name> <class_code> <phone>`
  - 作用：向 `students.csv` 追加一行（字段中不能含逗号）
- `students_delete.cpp`
  - 用法：`students_delete <data_dir> <full_name> <student_no>`
  - 作用：从 `students.csv` 删除匹配“姓名 + 学号”的一行
- `students_get.cpp`
  - 用法：`students_get <data_dir> <student_no>`
  - 作用：按学号查找学生，返回 `{"student":{...}}`
- `attendance_session_start.cpp`
  - 用法：`attendance_session_start <data_dir> <course_id> <created_by_profile_id>`
  - 作用：创建点名场次，写入 `attendance_sessions.csv`
- `attendance_record_mark.cpp`
  - 用法：`attendance_record_mark <data_dir> <session_id> <student_id> <status> <marked_by_profile_id>`
  - 作用：写入点名记录到 `attendance_records.csv`

### 构建
#### Windows（MinGW-w64）
```powershell
cd native/features
pwsh -NoProfile -File build.ps1
g++ -O2 -std=c++17 -o dist/students_list.exe students_list.cpp
g++ -O2 -std=c++17 -o dist/students_insert.exe students_insert.cpp
g++ -O2 -std=c++17 -o dist/students_delete.exe students_delete.cpp
```

#### Linux
```bash
cd native/features
g++ -O2 -std=c++17 -o dist/students_list students_list.cpp
g++ -O2 -std=c++17 -o dist/students_insert students_insert.cpp
g++ -O2 -std=c++17 -o dist/students_delete students_delete.cpp
```

编译完成后，把二进制复制到 Flutter 的数据目录：`<campus_data>/bin/`。
