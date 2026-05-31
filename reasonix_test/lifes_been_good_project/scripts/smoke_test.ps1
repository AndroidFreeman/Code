param(
  [Parameter(Mandatory = $true)][string]$CliPath,
  [Parameter(Mandatory = $true)][string]$DataDir,
  [string]$StudentsListPath = "",
  [string]$StudentsInsertPath = "",
  [string]$StudentsDeletePath = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Init..."
& $CliPath system.init --data-dir $DataDir --seed | Write-Host

$req = '{"action":"profiles.list","payload":{}}'
Write-Host "profiles.list..."
& $CliPath call --data-dir $DataDir --request $req | Write-Host

$reqAdd = '{"action":"todos.add","payload":{"owner":"u_student_001","title":"Smoke 测试待办"}}'
Write-Host "todos.add..."
& $CliPath call --data-dir $DataDir --request $reqAdd | Write-Host

$reqList = '{"action":"todos.list","payload":{}}'
Write-Host "todos.list..."
$listOut = & $CliPath call --data-dir $DataDir --request $reqList
Write-Host $listOut

if ($StudentsDeletePath -ne "") {
  Write-Host "students_delete..."
  & $StudentsDeletePath $DataDir "张同学" "20260001" | Write-Host
  $reqStudents = '{"action":"students.list","payload":{}}'
  Write-Host "students.list..."
  & $CliPath call --data-dir $DataDir --request $reqStudents | Write-Host
}

if ($StudentsInsertPath -ne "" -and $StudentsListPath -ne "") {
  Write-Host "students_insert..."
  & $StudentsInsertPath $DataDir "s_003" "20260003" "王小明" "CLS1" "13800000003" | Write-Host
  Write-Host "students_list..."
  & $StudentsListPath $DataDir | Write-Host
}

Write-Host "Done"
