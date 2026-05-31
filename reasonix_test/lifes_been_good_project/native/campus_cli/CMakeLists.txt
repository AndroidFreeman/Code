cmake_minimum_required(VERSION 3.10)
project(campus_cli)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Explicit source list — avoids GLOB_RECURSE which silently misses new/removed files
set(MAIN_SRC campus_cli.c)
set(FEATURE_SRCS
    ../features/accounting.cpp
    ../features/attendance_record_mark.cpp
    ../features/attendance_session_start.cpp
    ../features/contacts_list.cpp
    ../features/courses_insert.cpp
    ../features/courses_list.cpp
    ../features/csv_op.cpp
    ../features/json_op.cpp
    ../features/profiles_list.cpp
    ../features/students_delete.cpp
    ../features/students_get.cpp
    ../features/students_insert.cpp
    ../features/students_list.cpp
    ../features/system_init.cpp
    ../features/timetable_insert.cpp
    ../features/timetable_list.cpp
    ../features/todos_add.cpp
    ../features/todos_list.cpp
    ../features/todos_toggle.cpp
)

include_directories("../features")

# ⚠️ WARNING: --allow-multiple-definition is a hack — multiple main() functions coexist
# via linker override. Behavior is undefined (depends on link order). This flag does NOT
# work on MSVC (Windows). A proper fix: remove main() from each feature .cpp and keep
# only campus_cli.c as the sole entry point, or compile each feature as a separate binary.
if(UNIX)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--allow-multiple-definition")
endif()

add_executable(campus_cli ${MAIN_SRC} ${FEATURE_SRCS})

find_package(Threads REQUIRED)
target_link_libraries(campus_cli PRIVATE Threads::Threads)
