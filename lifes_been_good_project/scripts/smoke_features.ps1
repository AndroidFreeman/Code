param(
  [Parameter(Mandatory = $true)][string]$BinDir,
  [Parameter(Mandatory = $true)][string]$DataDir
)

$ErrorActionPreference = "Stop"

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $utf8NoBom
[Console]::InputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

function ExePath([string]$name) {
  return Join-Path $BinDir ($name + ".exe")
}

$init = ExePath "system_init"
$profiles = ExePath "profiles_list"
$courses = ExePath "courses_list"
$timetable = ExePath "timetable_list"
$contacts = ExePath "contacts_list"
$todosList = ExePath "todos_list"
$todosAdd = ExePath "todos_add"
$todosToggle = ExePath "todos_toggle"
$studentsList = ExePath "students_list"
$studentsInsert = ExePath "students_insert"
$studentsDelete = ExePath "students_delete"
$startSession = ExePath "attendance_session_start"
$markRecord = ExePath "attendance_record_mark"

Write-Host "Init..."
& $init $DataDir --seed | Write-Host

Write-Host "profiles_list..."
& $profiles $DataDir | Write-Host

Write-Host "courses_list..."
& $courses $DataDir | Write-Host

Write-Host "timetable_list..."
& $timetable $DataDir | Write-Host

Write-Host "contacts_list..."
& $contacts $DataDir | Write-Host

Write-Host "todos_add..."
& $todosAdd $DataDir "u_student_001" "Smoke Features Todo" | Write-Host

Write-Host "todos_list..."
$todosOut = & $todosList $DataDir
Write-Host $todosOut

Write-Host "students_insert..."
& $studentsInsert $DataDir "s_003" "20260003" "王小明" "CLS1" "13800000003" | Write-Host

Write-Host "students_list..."
& $studentsList $DataDir | Write-Host

Write-Host "students_delete..."
& $studentsDelete $DataDir "王小明" "20260003" | Write-Host

Write-Host "students_list..."
& $studentsList $DataDir | Write-Host

Write-Host "attendance_session_start..."
$sessOut = & $startSession $DataDir "c_001" "u_teacher_001"
Write-Host $sessOut

$sessJson = $sessOut | ConvertFrom-Json
$sessionId = $sessJson.data.session_id

Write-Host "attendance_record_mark..."
& $markRecord $DataDir $sessionId "s_001" "present" "u_teacher_001" | Write-Host

Write-Host "Done"
