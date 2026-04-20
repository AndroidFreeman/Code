## campus_cli
本目录提供一个本地数据处理 CLI（C 语言实现）。Flutter 通过 `Process.run` 调用它完成 CSV 读写与处理。

### 运行方式
二进制调用示例：
- 初始化数据目录（可选写入种子数据）：
  - `campus_cli system.init --data-dir <DATA_DIR> --seed`
- 处理请求（推荐，匹配 Process.run）：
  - `campus_cli call --data-dir <DATA_DIR> --request '{"action":"todos.list","payload":{"owner":"u_student_001"}}'`
- 处理请求（可选，stdin JSON）：
  - `campus_cli call --data-dir <DATA_DIR> --stdin`
  - stdin 输入：`{"action":"todos.list","payload":{"owner":"u_student_001"}}`

说明：
- `system.init` 不依赖 `--request/--stdin`。
- `call` 模式下，action 由请求 JSON 的 `action` 字段决定。

### 支持的 action（MVP）
- `profiles.list`
- `students.list`
- `students.get`（payload：`student_no`）
- `courses.list`
- `timetable.list`
- `contacts.list`
- `todos.list`
- `todos.add`（payload：`owner`、`title`、可选 `due_at`）
- `todos.toggle`（payload：`id`）
- `attendance.session.start`（payload：`course_id`、`created_by`）
- `attendance.record.mark`（payload：`session_id`、`student_id`、`status`、`marked_by`）

### CSV 约束
- UTF-8
- 不支持带引号/转义的 CSV 字段，字段中避免逗号
- 第一行为表头

### 构建
#### Linux
```bash
gcc -O2 -std=c11 -o campus_cli campus_cli.c
```

#### Windows（MinGW-w64）
```powershell
gcc -O2 -std=c11 -o campus_cli.exe campus_cli.c
```
