# Capítulo I: read-only import check + headless acceptance tests.
# NO tests have been run by the assistant; launch locally only after the
# user decides to validate with Godot 4.x installed.
param(
    [string]$GodotBinary = "godot"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tests = @(
    "tests/workshop_glb_smoke.gd",
    "tests/ares_vallis_v33_smoke.gd",
    "tests/pathfinder_cinematic_intro_smoke.gd",
    "tests/sojourner_imported_visual_smoke.gd",
    "tests/vanguard_1_story_loop_smoke.gd",
    "tests/surveyor_1_story_loop_smoke.gd",
    "tests/apollo_11_stage_story_loop_smoke.gd",
    "tests/apollo_15_lrv_story_loop_smoke.gd",
    "tests/viking_1_science_story_loop_smoke.gd",
    "tests/spirit_slip_story_loop_smoke.gd",
    "tests/opportunity_power_story_loop_smoke.gd",
    "tests/sky_crane_story_loop_smoke.gd",
    "tests/ingenuity_flight_story_loop_smoke.gd",
    "tests/science_fair_insight_story_loop_smoke.gd",
    "tests/next_two_artifacts_greybox_smoke.gd",
    "tests/archive_recency_smoke.gd",
    "tests/chapter1_persistence_smoke.gd"
)

if (-not (Get-Command $GodotBinary -ErrorAction SilentlyContinue)) {
    throw "Godot not found: $GodotBinary. Pass -GodotBinary with the local executable path."
}

Push-Location $projectRoot
try {
    Write-Host "Capítulo I — Importing Godot project (headless)..."
    & $GodotBinary --headless --editor --path . --quit
    if ($LASTEXITCODE -ne 0) {
        throw "Godot editor import failed (exit code $LASTEXITCODE)."
    }

    foreach ($relative in $tests) {
        $resource = "res://" + $relative.Replace("\", "/")
        Write-Host "Running: $resource"
        & $GodotBinary --headless --path . --script $resource
        if ($LASTEXITCODE -ne 0) {
            throw "Test failed: $resource (exit code $LASTEXITCODE)."
        }
    }

    Write-Host "PASS: All $($tests.Count) scheduled chapter I smoke scripts completed."
} finally {
    Pop-Location
}
