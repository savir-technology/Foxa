param(
    [string]$ApiBaseUrl = 'https://savir-technology.online/roaqv2/'
)

$ErrorActionPreference = 'Stop'
[void][Reflection.Assembly]::LoadWithPartialName('System.Net.Http')
$base = $ApiBaseUrl.TrimEnd('/') + '/'
$protectedPaths = @(
    'dash/master/home.php',
    'dash/master/orders/list.php',
    'dash/master/finance/overview.php',
    'dash/master/vendors/get_vendors.php',
    'dash/master/users/overview.php',
    'dash/master/deployment_health.php'
)
$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [TimeSpan]::FromSeconds(30)

function Invoke-JsonRequest {
    param(
        [string]$Uri,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )

    $method = if ($null -eq $Body) {
        [System.Net.Http.HttpMethod]::Get
    }
    else {
        [System.Net.Http.HttpMethod]::Post
    }
    $request = [System.Net.Http.HttpRequestMessage]::new($method, $Uri)
    foreach ($header in $Headers.GetEnumerator()) {
        [void]$request.Headers.TryAddWithoutValidation(
            [string]$header.Key,
            [string]$header.Value
        )
    }
    if ($null -ne $Body) {
        $json = $Body | ConvertTo-Json -Compress
        $request.Content = [System.Net.Http.StringContent]::new(
            $json,
            [Text.Encoding]::UTF8,
            'application/json'
        )
    }
    try {
        $response = $httpClient.SendAsync($request).GetAwaiter().GetResult()
        $responseBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        return [pscustomobject]@{
            StatusCode = [int]$response.StatusCode
            Body = $responseBody
        }
    }
    catch {
        return [pscustomobject]@{
            StatusCode = 0
            Body = ''
        }
    }
    finally {
        $request.Dispose()
    }
}

Write-Host "Testing $base"
$failures = 0
foreach ($path in $protectedPaths) {
    $result = Invoke-JsonRequest -Uri ($base + $path)
    if ($result.StatusCode -ne 401) {
        Write-Host "FAIL unauthenticated $path -> HTTP $($result.StatusCode)" -ForegroundColor Red
        $failures++
    }
    else {
        Write-Host "OK   unauthenticated $path -> HTTP 401" -ForegroundColor Green
    }
}

$legacy = Invoke-JsonRequest -Uri ($base + 'dash/users/get/get_users.php')
if ($legacy.StatusCode -ne 200) {
    Write-Host "FAIL shared users endpoint -> HTTP $($legacy.StatusCode)" -ForegroundColor Red
    $failures++
}
elseif ($legacy.Body -match 'users_password|verification_code|users_verify_code') {
    Write-Host 'FAIL shared users endpoint contains sensitive fields' -ForegroundColor Red
    $failures++
}
else {
    Write-Host 'OK   shared users endpoint returns no sensitive fields' -ForegroundColor Green
}

$smokeEmail = [Environment]::GetEnvironmentVariable('JEEB_MASTER_SMOKE_EMAIL')
$smokePassword = [Environment]::GetEnvironmentVariable('JEEB_MASTER_SMOKE_PASSWORD')
if ($smokeEmail -and $smokePassword) {
    $login = Invoke-JsonRequest -Uri ($base + 'dash/master_auth/login.php') -Body @{
        email = $smokeEmail
        password = $smokePassword
        portal = 'home'
    }
    $loginJson = $login.Body | ConvertFrom-Json
    $token = $loginJson.data.token
    if ($login.StatusCode -ne 200 -or [string]::IsNullOrWhiteSpace([string]$token)) {
        Write-Host 'FAIL master login smoke test' -ForegroundColor Red
        $failures++
    }
    else {
        $auth = @{ Authorization = "Bearer $token" }
        $home = Invoke-JsonRequest -Uri ($base + 'dash/master/home.php') -Headers $auth
        if ($home.StatusCode -ne 200) {
            Write-Host "FAIL authenticated master home -> HTTP $($home.StatusCode)" -ForegroundColor Red
            $failures++
        }
        else {
            Write-Host 'OK   authenticated master home' -ForegroundColor Green
        }

        $health = Invoke-JsonRequest -Uri ($base + 'dash/master/deployment_health.php') -Headers $auth
        $healthJson = $null
        try { $healthJson = $health.Body | ConvertFrom-Json } catch { }
        $healthy = $healthJson.data.healthy -eq $true
        if ($health.StatusCode -ne 200 -or -not $healthy) {
            $missing = if ($healthJson.data.missing_tables) {
                ($healthJson.data.missing_tables -join ', ')
            } else { 'unknown' }
            Write-Host "FAIL deployment health -> HTTP $($health.StatusCode); missing: $missing" -ForegroundColor Red
            $failures++
        }
        else {
            Write-Host 'OK   deployment health: database and required tables are ready' -ForegroundColor Green
        }
    }
}
else {
    Write-Host 'SKIP authenticated login (set JEEB_MASTER_SMOKE_EMAIL and JEEB_MASTER_SMOKE_PASSWORD to enable)'
}

if ($failures -gt 0) {
    throw "$failures production smoke test(s) failed."
}
Write-Host 'All production smoke tests passed.' -ForegroundColor Green
