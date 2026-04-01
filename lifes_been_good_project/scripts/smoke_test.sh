#!/usr/bin/env sh
set -e

CLI_PATH="$1"
DATA_DIR="$2"

if [ -z "$CLI_PATH" ] || [ -z "$DATA_DIR" ]; then
  echo "Usage: $0 <cli_path> <data_dir>" >&2
  exit 2
fi

echo "Init..."
"$CLI_PATH" system.init --data-dir "$DATA_DIR" --seed

echo "profiles.list..."
"$CLI_PATH" call --data-dir "$DATA_DIR" --request '{"action":"profiles.list","payload":{}}'

echo "todos.add..."
"$CLI_PATH" call --data-dir "$DATA_DIR" --request '{"action":"todos.add","payload":{"owner":"u_student_001","title":"Smoke 测试待办"}}'

echo "todos.list..."
"$CLI_PATH" call --data-dir "$DATA_DIR" --request '{"action":"todos.list","payload":{}}'

echo "Done"

