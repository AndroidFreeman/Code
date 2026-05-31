param(
  [string]$OutDir = "dist"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

if (!(Test-Path $OutDir)) {
  New-Item -ItemType Directory -Path $OutDir | Out-Null
}

function BuildOne([string]$outName, [string]$src) {
  & g++ -O2 -std=c++17 -o (Join-Path $OutDir ($outName + ".exe")) $src
  if ($LASTEXITCODE -ne 0) {
    throw "g++ failed: $src"
  }
}

BuildOne "system_init" "system_init.cpp"
BuildOne "profiles_list" "profiles_list.cpp"
BuildOne "students_list" "students_list.cpp"
BuildOne "students_insert" "students_insert.cpp"
BuildOne "students_delete" "students_delete.cpp"
BuildOne "students_get" "students_get.cpp"
BuildOne "courses_list" "courses_list.cpp"
BuildOne "courses_insert" "courses_insert.cpp"
BuildOne "timetable_list" "timetable_list.cpp"
BuildOne "timetable_insert" "timetable_insert.cpp"
BuildOne "contacts_list" "contacts_list.cpp"
BuildOne "todos_list" "todos_list.cpp"
BuildOne "todos_add" "todos_add.cpp"
BuildOne "todos_toggle" "todos_toggle.cpp"
BuildOne "attendance_session_start" "attendance_session_start.cpp"
BuildOne "attendance_record_mark" "attendance_record_mark.cpp"
BuildOne "csv_op" "csv_op.cpp"
BuildOne "json_op" "json_op.cpp"

Write-Host "Built: $(Join-Path $OutDir 'system_init.exe')"
Write-Host "Built: $(Join-Path $OutDir 'profiles_list.exe')"
Write-Host "Built: $(Join-Path $OutDir 'students_list.exe')"
Write-Host "Built: $(Join-Path $OutDir 'students_insert.exe')"
Write-Host "Built: $(Join-Path $OutDir 'students_delete.exe')"
Write-Host "Built: $(Join-Path $OutDir 'students_get.exe')"
Write-Host "Built: $(Join-Path $OutDir 'courses_list.exe')"
Write-Host "Built: $(Join-Path $OutDir 'courses_insert.exe')"
Write-Host "Built: $(Join-Path $OutDir 'timetable_list.exe')"
Write-Host "Built: $(Join-Path $OutDir 'timetable_insert.exe')"
Write-Host "Built: $(Join-Path $OutDir 'contacts_list.exe')"
Write-Host "Built: $(Join-Path $OutDir 'todos_list.exe')"
Write-Host "Built: $(Join-Path $OutDir 'todos_add.exe')"
Write-Host "Built: $(Join-Path $OutDir 'todos_toggle.exe')"
Write-Host "Built: $(Join-Path $OutDir 'attendance_session_start.exe')"
Write-Host "Built: $(Join-Path $OutDir 'attendance_record_mark.exe')"
Write-Host "Built: $(Join-Path $OutDir 'csv_op.exe')"
Write-Host "Built: $(Join-Path $OutDir 'json_op.exe')"
