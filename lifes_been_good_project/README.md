## flutter_app
Flutter 前端原型（Windows/Linux/Android 目标）。Windows/Linux 通过 `Process.run` 调用本地二进制完成数据读写与处理。

### 你需要准备
- Flutter SDK
- 对应平台的构建环境（Windows: Visual Studio；Linux: 工具链；Android: Android SDK）
- 编译好的 `campus_cli` 二进制

### 二进制放置位置
App 启动后会创建数据目录：application support 下的 `campus_data/`。

请把 `campus_cli` 放到：
- Windows：`<campus_data>/bin/campus_cli.exe`
- Linux/Android：`<campus_data>/bin/campus_cli`

如果你采用“一个功能一个 C 文件、一个可执行文件”的方式（见 `native/features/`），把对应二进制也放到同一个目录，例如：
- Windows：`<campus_data>/bin/students_delete.exe`
- Linux：`<campus_data>/bin/students_delete`

当前 Flutter 会优先查找并调用这些二进制（不存在时才回退到 `campus_cli`）：
- `system_init`
- `profiles_list`
- `courses_list`
- `timetable_list`
- `contacts_list`
- `todos_list` / `todos_add` / `todos_toggle`
- `students_list` / `students_insert` / `students_delete`
- `attendance_session_start` / `attendance_record_mark`

首次进入登录页后，点“初始化示例数据”会在 `campus_data/` 下创建并填充 CSV。

### 运行
在你自己的 Flutter 工程中，复制本目录的 `lib/` 与 `pubspec.yaml` 依赖（`path_provider`、`path`）。

常用命令：
- `flutter pub get`
- `flutter run -d windows`
- `flutter run -d linux`
- `flutter run -d android`

### Android 说明
Android 上直接执行外部二进制通常不可行（应用私有目录可能无执行权限、也不建议随意 `exec`）。如果你必须复用同一套 C 逻辑，建议把这些 C 文件通过 NDK 编译成 `lib*.so`，再用 `dart:ffi` 调用（仍然可以保持“一个功能一个 C 文件”，只是不再以 `main()` 作为入口）。
