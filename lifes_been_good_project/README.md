# Life's Been Good

A local-first Flutter application for managing campus life, courses, students, and schedules, designed with a frontend-backend separation architecture using native C++ executables for all file processing.

## Architecture

This project adopts a unique **frontend-backend separation** pattern in a local-first environment:
- **Frontend**: Flutter (Dart) handles UI, state management, and user interactions.
- **Backend**: Native C++ executables (located in `native/features/`) act as local microservices.
- **Communication**: Dart uses `Process.run()` passing JSON payloads to the C++ binaries, which perform file I/O (CSV/JSON) and return JSON responses.

### Key Components

- **Dart Side**: `lib/services/native_features.dart` abstracts the interaction with the C++ binaries (`csv_op.exe`, `json_op.exe`, etc.).
- **Native Side**: `native/features/` contains the C++ code (`csv_op.cpp`, `json_op.cpp`, etc.). These are compiled into independent executables.

## Features

- **Teacher & Student Roles**: Different permissions and views based on login role.
- **Class & Student Management**: Teachers can add classes, manage students, and assign roles (e.g., class cadre).
  - Default student passwords are automatically generated (last 6 digits of Student ID, padded with 0).
- **Course & Timetable Management**: Create courses, manage enrollments, and schedule classes.
- **Attendance Tracking**: Start attendance sessions and mark records.
- **To-Do & Contacts**: Manage personal tasks and a campus address book.

## Building and Running

### Prerequisites
- Flutter SDK (latest stable)
- C++17 Compiler (GCC/MinGW-w64 on Windows, GCC on Linux, Clang on macOS)

### Compile Native Backend
Run the build script in the `native/features` directory to compile all C++ features:
```powershell
cd native/features
./build.ps1
```
*(On Linux/macOS, use `build.sh`)*

The compiled binaries will be placed in `native/features/dist/` and automatically synced to the app's internal bin directory by the Dart bootstrapper.

### Run Flutter App
```bash
flutter run -d windows
```

## Data Storage
All data is stored locally in CSV and JSON files within the application's document directory (e.g., `%APPDATA%\lifes_been_good` on Windows). The C++ backend ensures reliable parsing and updating of these files.