[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
    [Parameter(Mandatory = $true)]
    [int]$UserStartId,
    [int]$Vus = 100,
    [string]$MaxDuration = '5m'
)

$normalizedUrl = $BaseUrl.TrimEnd('/')
if ($normalizedUrl -match '^https?://(www\.)?savir-technology\.online(?:/|$)') {
    throw 'Production URL is blocked. Use a staging hostname.'
}
if ($UserStartId -le 0 -or $Vus -le 0) {
    throw 'UserStartId and Vus must be positive integers.'
}
if (-not (Get-Command k6 -ErrorAction SilentlyContinue)) {
    throw 'k6 is not installed or is not available on PATH.'
}

$envArgs = @(
    '-e', "BASE_URL=$normalizedUrl",
    '-e', "USER_START_ID=$UserStartId",
    '-e', "VUS=$Vus",
    '-e', "MAX_DURATION=$MaxDuration"
)

& k6 run @envArgs (Join-Path $PSScriptRoot 'checkout.js')
exit $LASTEXITCODE
