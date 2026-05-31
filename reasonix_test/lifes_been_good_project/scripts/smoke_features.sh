#!/usr/bin/env sh
set -eu

BIN_DIR="$1"
DATA_DIR="$2"

"$BIN_DIR/system_init" "$DATA_DIR" --seed
"$BIN_DIR/profiles_list" "$DATA_DIR"
"$BIN_DIR/courses_list" "$DATA_DIR"
"$BIN_DIR/timetable_list" "$DATA_DIR"
"$BIN_DIR/contacts_list" "$DATA_DIR"
"$BIN_DIR/todos_add" "$DATA_DIR" "u_student_001" "Smoke Features Todo"
"$BIN_DIR/todos_list" "$DATA_DIR"
"$BIN_DIR/students_insert" "$DATA_DIR" "s_003" "20260003" "王小明" "CLS1" "13800000003"
"$BIN_DIR/students_list" "$DATA_DIR"
"$BIN_DIR/students_delete" "$DATA_DIR" "王小明" "20260003"
"$BIN_DIR/students_list" "$DATA_DIR"
SESS_OUT=$("$BIN_DIR/attendance_session_start" "$DATA_DIR" "c_001" "u_teacher_001")
echo "$SESS_OUT"
SESSION_ID=$(echo "$SESS_OUT" | sed -n 's/.*"session_id":"\([^"]*\)".*/\1/p')
"$BIN_DIR/attendance_record_mark" "$DATA_DIR" "$SESSION_ID" "s_001" "present" "u_teacher_001"
