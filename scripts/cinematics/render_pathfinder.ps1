# Render a stylized Mars Pathfinder intro, convert to Godot 4 .ogv.
# Blender 5.2 auto-detection; if FFmpeg is missing, install a local portable copy.
# No WinGet, admin rights or permanent PATH edits required.
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
    if ($FfmpegBinary -ne "ffmpeg") {
        throw "Requested FFmpeg binary not found: $FfmpegBinary"
    }

    # On many Windows installations winget is not present. Use a cached,
    # verified Essentials release without changing the user's system.
    $cacheDir = Join-Path $repo ".tools\pathfinder-ffmpeg"
    $portableExe = Join-Path $cacheDir "ffmpeg.exe"
    if (-not (Test-Path $portableExe -PathType Leaf)) {
        New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
        $archive = Join-Path $cacheDir "ffmpeg-release-essentials.zip"
        $extracted = Join-Path $cacheDir "extracted"
        $sourceUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
        $hashUrl = "$sourceUrl.sha256"
        Write-Host "WinGet is not required. Downloading portable FFmpeg Essentials (~109 MB) from gyan.dev..."
        Write-Host "Checking the published SHA-256 before extracting..."
        $expectedResponse = Invoke-WebRequest -Uri $hashUrl -UseBasicParsing
        $expectedHash = [regex]::Match([string]$expectedResponse.Content, "(?i)[0-9a-f]{64}").Value.ToUpperInvariant()
        if ($expectedHash.Length -ne 64) {
            throw "No trustworthy SHA-256 hash was returned for FFmpeg; refusing download."
        }
        Invoke-WebRequest -Uri $sourceUrl -OutFile $archive -UseBasicParsing
        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToUpperInvariant()
        if ($actualHash -ne $expectedHash) {
            Remove-Item -LiteralPath $archive -Force
            throw "FFmpeg SHA-256 mismatch. Removed download; no executable will be used."
        }
        Expand-Archive -LiteralPath $archive -DestinationPath $extracted -Force
        $found = @(Get-ChildItem -Path $extracted -Recurse -File -Filter "ffmpeg.exe")
        if ($found.Count -ne 1) {
            throw "FFmpeg Essentials ZIP did not contain exactly one ffmpeg.exe."
        }
        Copy-Item -LiteralPath $found[0].FullName -Destination $portableExe -Force
        Write-Host "Portable FFmpeg ready: $portableExe"
    }
    $FfmpegBinary = $portableExe
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
