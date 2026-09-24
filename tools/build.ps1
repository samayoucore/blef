$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$godot = (Get-Command 'Godot_v4.6.2-stable_win64_console.exe').Source
$engine = (Get-Command 'Godot_v4.6.2-stable_win64.exe').Source
$build = Join-Path $root 'build'
New-Item -ItemType Directory -Force -Path $build | Out-Null
Set-Content -LiteralPath (Join-Path $build '.gdignore') -Value ''

# Import once in a fresh checkout, then export the game data into a portable PCK.
& $godot --headless --path $root --editor --import --quit -- --profile=build-import
if ($LASTEXITCODE -ne 0) { throw 'Не удалось импортировать проект.' }
& $godot --headless --path $root --editor --export-pack 'Windows Desktop' (Join-Path $build 'BLEF.pck') -- --profile=build-export
if ($LASTEXITCODE -ne 0) { throw 'Не удалось собрать игровой пакет.' }

Copy-Item -LiteralPath $engine -Destination (Join-Path $build 'BLEF.exe') -Force
Copy-Item -LiteralPath (Join-Path $root 'CREDITS.md') -Destination (Join-Path $build 'CREDITS.md') -Force
Copy-Item -LiteralPath (Join-Path $root 'ASSET_LICENSES.md') -Destination (Join-Path $build 'ASSET_LICENSES.md') -Force
Copy-Item -LiteralPath (Join-Path $root 'docs\ПРОЧИТАЙТЕ.txt') -Destination (Join-Path $build 'ПРОЧИТАЙТЕ.txt') -Force
$licenses = Join-Path $build 'licenses'
New-Item -ItemType Directory -Force -Path $licenses | Out-Null
foreach ($pack in @('kenney_furniture','kenney_food','kenney_cube_pets')) {
    Copy-Item -LiteralPath (Join-Path $root ('assets\environment\'+$pack+'\License.txt')) -Destination (Join-Path $licenses ($pack+'.txt')) -Force
}

# GitHub rejects individual files over 100 MB; the engine compresses below that limit.
Compress-Archive -LiteralPath (Join-Path $build 'BLEF.exe') -DestinationPath (Join-Path $build 'BLEF-engine.zip') -CompressionLevel Optimal -Force
Write-Host 'Сборка готова: build\BLEF.exe + build\BLEF.pck; для GitHub: BLEF-engine.zip + BLEF.pck.'
