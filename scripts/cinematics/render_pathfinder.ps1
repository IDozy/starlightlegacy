# Render a stylized Mars Pathfinder intro, convert to Godot 4 .ogv.
# Blender 5.2 auto-detection; FFmpeg must be on PATH or passed explicitly.
param(
    [ValidateSet("draft", "final")]
    [string]$Quality = "draft",
    [string]$BlenderBinary = "",
    [string]$FfmpegBinary = "ffmpeg"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$blenderScript = Join-Path $PSScriptRoot "render_pathfinder_blender.py"
$framesDir = Join-Path $repo "renders\pathfinder\$Quality"
$targetDir = Join-Path $repo "assets\videos\pathfinder"
$target = Join-Path $targetDir "pathfinder_intro.ogv"

if (-not $BlenderBinary) {
    $candidate = Get-Command "blender" -ErrorAction SilentlyContinue
    if ($candidate) { $BlenderBinary = $candidate.Source }
}
if (-not $BlenderBinary) {
    $versions = @(Get-ChildItem "C:\Program Files\Blender Foundation\Blender *\blender.exe" -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)
    if ($versions.Count -gt 0) { $BlenderBinary = $versions[0].FullName }
}
if (-not $BlenderBinary -or -not (Test-Path $BlenderBinary -PathType Leaf)) {
    throw "Blender not found. Use -BlenderBinary 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'"
}
if (-not (Get-Command $FfmpegBinary -ErrorAction SilentlyContinue)) {
    throw "FFmpeg missing. Install with: winget install --id Gyan.FFmpeg -e ; restart PowerShell."
}

New-Item -Path $framesDir -ItemType Directory -Force | Out-Null
New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
$prefix = Join-Path $framesDir "frame_"
$fps = if ($Quality -eq "final") { 24 } else { 12 }
$framePattern = Join-Path $framesDir "frame_%04d.png"

Write-Host "Blender: $BlenderBinary"
Write-Host "Building Pathfinder cinematic ($Quality, $fps fps)..."
& $BlenderBinary --background --factory-startup --python $blenderScript -- --quality $Quality --output-prefix $prefix
if ($LASTEXITCODE -ne 0) {
    throw "Blender failed (exit code $LASTEXITCODE)"
}
if (-not (Test-Path (Join-Path $framesDir "frame_0001.png"))) {
    throw "Blender produced no frames."
}

# Theora is supported in core Godot 4. MP4 is NOT supported without plugins.
Write-Host "Encoding Godot Ogg Theora: $target"
& $FfmpegBinary -hide_banner -loglevel error -y -framerate $fps -start_number 1 -i $framePattern -c:v libtheora -q:v 7 -pix_fmt yuv420p -an $target
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $target)) {
    throw "OGV conversion failed."
}
Write-Host "OK: $target"
Write-Host "Open levels/ares_vallis/pathfinder_video_intro.tscn and press F6 in Godot."
Write-Host "Sources and frames are under renders/pathfinder/ (local, not for Git)."
