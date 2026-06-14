# clone-repo.ps1
param([string]$InstallPath, [switch]$UseMirror)
$canvasDir = Join-Path $InstallPath "canvas-lms"
if (Test-Path $canvasDir) { Write-Host "Already exists: $canvasDir" -ForegroundColor Yellow; return }
New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
if ($UseMirror) { git clone "https://gitee.com/xiong-yuhui/canvas-Lms.git" $canvasDir }
else { git clone "https://github.com/instructure/canvas-lms.git" $canvasDir }
Write-Host "Done!" -ForegroundColor Green