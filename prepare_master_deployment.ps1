param(
    [string]$OutputRoot = "deploy"
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path $PSScriptRoot).Path
$masterRoot = Join-Path $projectRoot 'master'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bundleRoot = Join-Path (Join-Path $projectRoot $OutputRoot) "jeeb-master-$timestamp"
$webRoot = Join-Path $bundleRoot 'web'
$backendRoot = Join-Path $bundleRoot 'backend-roaq'
$migrationRoot = Join-Path $bundleRoot 'migrations'

if (-not (Test-Path (Join-Path $masterRoot 'pubspec.yaml'))) {
    throw "master Flutter project was not found at $masterRoot"
}

Write-Host 'Building the Master web application...'
Push-Location $masterRoot
try {
    flutter build web --release --no-pub
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter web build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

New-Item -ItemType Directory -Force -Path $webRoot, $backendRoot, $migrationRoot | Out-Null
Copy-Item -Path (Join-Path $masterRoot 'build\web\*') -Destination $webRoot -Recurse -Force

$backendFiles = @(
    'connect.php',
    'functions.php',
    'config\database.php',
    'config\database.local.php.example',
    'payments\init_payment.php',
    'payments\.htaccess',
    'dash\master_auth\verify_signup_code.php',
    'dash\master_auth\seed_portal_accounts.php',
    'dash\master_auth\verify_portal_accounts.php',
    'dash\master_auth\login.php',
    'dash\notifications\save_web_push_token.php',
    'dash\order\assign\assign_driver.php',
    'dash\master\finance\action.php',
    'dash\users\get\get_users.php',
    'dash\items\get\get_item_edit_data.php',
    'dash\items\attributes\save.php',
    'dash\sections\get\get_categories.php',
    'dash\items\get\get_items.php'
)

# The master dashboard is a complete backend surface, not only the files
# touched by the auth migration. Include every production endpoint under
# dash/master so an older server cannot silently keep legacy behavior.
$backendSourceRoot = Join-Path $projectRoot 'backend\roaq'
$masterEndpointRoot = Join-Path $backendSourceRoot 'dash\master'
foreach ($file in Get-ChildItem -LiteralPath $masterEndpointRoot -Recurse -File -Filter *.php) {
    if ($file.Name -eq 'fix_permissions.php') {
        continue
    }
    $relative = $file.FullName.Substring($backendSourceRoot.Length).TrimStart([char]92, [char]47)
    if ($backendFiles -notcontains $relative) {
        $backendFiles += $relative
    }
}

$masterAuthRoot = Join-Path $backendSourceRoot 'dash\master_auth'
foreach ($file in Get-ChildItem -LiteralPath $masterAuthRoot -File -Filter *.php) {
    $relative = $file.FullName.Substring($backendSourceRoot.Length).TrimStart([char]92, [char]47)
    if ($backendFiles -notcontains $relative) {
        $backendFiles += $relative
    }
}

foreach ($relativePath in $backendFiles) {
    $source = Join-Path $backendSourceRoot $relativePath
    if (-not (Test-Path $source)) {
        throw "Required backend file is missing: $relativePath"
    }

    $destination = Join-Path $backendRoot $relativePath
    New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

$migrations = @(
    '20260909_master_auth_accounts.sql',
    '20261104_master_governance_permissions.sql'
)
foreach ($migrationName in $migrations) {
    $migration = Join-Path $projectRoot (Join-Path 'backend\roaq\migrations' $migrationName)
    if (-not (Test-Path $migration)) {
        throw "Required migration is missing: $migration"
    }
    Copy-Item -LiteralPath $migration -Destination $migrationRoot -Force
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'MASTER_DEPLOYMENT_CHECKLIST.md') -Destination $bundleRoot -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'verify_master_production.ps1') -Destination $bundleRoot -Force

$readme = @"
Jeeb Master deployment bundle
Generated: $(Get-Date -Format 'u')

Web files:      web\
Backend files:  backend-roaq\
Migrations:     migrations\20260909_master_auth_accounts.sql
                migrations\20261104_master_governance_permissions.sql
Smoke test:     verify_master_production.ps1

Upload the contents of backend-roaq\ into the existing backend root,
upload web\ to the dashboard hosting directory, then follow the checklist.
If the hosting panel does not expose environment variables to PHP, copy
config\database.local.php.example to config\database.local.php on the server
and set the real database credentials there. Never commit that local file.
Set JEEB_MASTER_BOOTSTRAP_PASSWORD in the server shell, then run
seed_portal_accounts.php from CLI only; never expose it as a web route.
"@
Set-Content -LiteralPath (Join-Path $bundleRoot 'README.txt') -Value $readme -Encoding UTF8

Write-Host "Deployment bundle created at: $bundleRoot"
