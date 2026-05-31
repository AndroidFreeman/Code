#!/usr/bin/env sh
set -e

OUT_DIR="${1:-dist}"

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

mkdir -p "$ROOT_DIR/$OUT_DIR"

gcc -O2 -std=c11 -o "$ROOT_DIR/$OUT_DIR/campus_cli" "$ROOT_DIR/campus_cli.c"

echo "Built $ROOT_DIR/$OUT_DIR/campus_cli"

