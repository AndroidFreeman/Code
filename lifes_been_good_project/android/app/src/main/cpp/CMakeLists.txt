cmake_minimum_required(VERSION 3.10.2)

project(NativeBinaries)

set(NATIVE_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native)
set(FEATURES_DIR ${NATIVE_ROOT}/features)
set(CLI_DIR ${NATIVE_ROOT}/campus_cli)

include_directories(${FEATURES_DIR})

add_executable(campus_cli ${CLI_DIR}/campus_cli.c)

set(FEATURE_FILES
    attendance_record_mark.cpp
    attendance_session_start.cpp
    contacts_list.cpp
    courses_insert.cpp
    courses_list.cpp
    profiles_list.cpp
    students_delete.cpp
    students_get.cpp
    students_insert.cpp
    students_list.cpp
    system_init.cpp
    timetable_insert.cpp
    timetable_list.cpp
    todos_add.cpp
    todos_list.cpp
    todos_toggle.cpp
)

foreach(FILE ${FEATURE_FILES})
    get_filename_component(NAME ${FILE} NAME_WE)
    add_executable(${NAME} ${FEATURES_DIR}/${FILE})
endforeach()
