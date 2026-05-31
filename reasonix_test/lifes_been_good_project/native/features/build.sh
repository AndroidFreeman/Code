#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
mkdir -p dist

g++ -O2 -std=c++17 -o dist/system_init system_init.cpp
g++ -O2 -std=c++17 -o dist/profiles_list profiles_list.cpp
g++ -O2 -std=c++17 -o dist/students_list students_list.cpp
g++ -O2 -std=c++17 -o dist/students_insert students_insert.cpp
g++ -O2 -std=c++17 -o dist/students_delete students_delete.cpp
g++ -O2 -std=c++17 -o dist/students_get students_get.cpp
g++ -O2 -std=c++17 -o dist/courses_list courses_list.cpp
g++ -O2 -std=c++17 -o dist/timetable_list timetable_list.cpp
g++ -O2 -std=c++17 -o dist/contacts_list contacts_list.cpp
g++ -O2 -std=c++17 -o dist/todos_list todos_list.cpp
g++ -O2 -std=c++17 -o dist/todos_add todos_add.cpp
g++ -O2 -std=c++17 -o dist/todos_toggle todos_toggle.cpp
g++ -O2 -std=c++17 -o dist/attendance_session_start attendance_session_start.cpp
g++ -O2 -std=c++17 -o dist/attendance_record_mark attendance_record_mark.cpp
g++ -O2 -std=c++17 -o dist/csv_op csv_op.cpp
g++ -O2 -std=c++17 -o dist/json_op json_op.cpp
g++ -O2 -std=c++17 -o dist/courses_insert courses_insert.cpp
g++ -O2 -std=c++17 -o dist/timetable_insert timetable_insert.cpp

echo "Built: dist/system_init"
echo "Built: dist/profiles_list"
echo "Built: dist/students_list"
echo "Built: dist/students_insert"
echo "Built: dist/students_delete"
echo "Built: dist/students_get"
echo "Built: dist/courses_list"
echo "Built: dist/timetable_list"
echo "Built: dist/contacts_list"
echo "Built: dist/todos_list"
echo "Built: dist/todos_add"
echo "Built: dist/todos_toggle"
echo "Built: dist/attendance_session_start"
echo "Built: dist/attendance_record_mark"
echo "Built: dist/csv_op"
echo "Built: dist/json_op"
echo "Built: dist/courses_insert"
echo "Built: dist/timetable_insert"
