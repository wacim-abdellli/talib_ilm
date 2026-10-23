# Run from an owner-access PowerShell terminal:
# powershell -ExecutionPolicy Bypass -File .\tool\verify_release_readiness.ps1
# Runs checks only. Does not modify permissions, commit, push, sign or publish.
[CmdletBinding()]
param(
    [string]$FlutterSdk,
    [switch]$NoPub
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $FlutterSdk) {
    $localSdk = Join-Path $projectRoot 'build/release-tools/flutter'
    if (Test-Path (Join-Path $localSdk 'bin/cache/flutter_tools.snapshot')) {
        $FlutterSdk = $localSdk
    }
}
$flutterCommand = 'flutter'
$flutterPrefix = @()
if ($FlutterSdk) {
    $FlutterSdk = (Resolve-Path -LiteralPath $FlutterSdk).Path
    $flutterCommand = Join-Path $FlutterSdk 'bin/cache/dart-sdk/bin/dart.exe'
    $toolSnapshot = Join-Path $FlutterSdk 'bin/cache/flutter_tools.snapshot'
    if (-not (Test-Path $flutterCommand) -or -not (Test-Path $toolSnapshot)) {
        throw "Incomplete Flutter SDK: $FlutterSdk"
    }
    $flutterPrefix = @($toolSnapshot, '--no-version-check', '--suppress-analytics')
}
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDirectory = Join-Path $projectRoot "build/release-readiness/$runStamp"
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$checkResults = @()
$previousGradleHome = $env:GRADLE_USER_HOME
$previousGitConfigCount = $env:GIT_CONFIG_COUNT
$sdkGitKeyName = $null
$sdkGitValueName = $null
$previousSdkGitKey = $null
$previousSdkGitValue = $null
$localGradleHome = Join-Path $projectRoot 'build/release-tools/gradle'
if ($FlutterSdk -and (Test-Path $localGradleHome)) {
    $env:GRADLE_USER_HOME = $localGradleHome
}
if ($FlutterSdk) {
    # A recovery SDK copied by another Windows account still needs Git's
    # ownership check. Trust this selected SDK only in child processes;
    # preserve existing injected Git settings and never change global config.
    $sdkGitIndex = if ($previousGitConfigCount) { [int]$previousGitConfigCount } else { 0 }
    $sdkGitKeyName = "GIT_CONFIG_KEY_$sdkGitIndex"
    $sdkGitValueName = "GIT_CONFIG_VALUE_$sdkGitIndex"
    $previousSdkGitKey = [Environment]::GetEnvironmentVariable($sdkGitKeyName, 'Process')
    $previousSdkGitValue = [Environment]::GetEnvironmentVariable($sdkGitValueName, 'Process')
    [Environment]::SetEnvironmentVariable($sdkGitKeyName, 'safe.directory', 'Process')
    [Environment]::SetEnvironmentVariable($sdkGitValueName, $FlutterSdk.Replace('\', '/'), 'Process')
    $env:GIT_CONFIG_COUNT = [string]($sdkGitIndex + 1)
}
$checks = @(
    @{ Name = 'analyze'; Command = $flutterCommand; Arguments = @($flutterPrefix) + @('analyze') },
    @{ Name = 'ui-lint-v2'; Command = 'python'; Arguments = @('tool/ui_lint_v2.py') },
    @{ Name = 'tests'; Command = $flutterCommand; Arguments = @($flutterPrefix) + @('test', '--concurrency=2') },
    @{ Name = 'debug-apk'; Command = $flutterCommand; Arguments = @($flutterPrefix) + @('build', 'apk', '--debug') }
)
if ($NoPub) {
    foreach ($check in $checks) {
        if ($check.Name -ne 'ui-lint-v2') {
            $check.Arguments += '--no-pub'
        }
    }
}

Push-Location $projectRoot
try {
    foreach ($check in $checks) {
        $checkName = $check.Name
        $commandName = $check.Command
        $commandArguments = $check.Arguments
        $logPath = Join-Path $logDirectory "$checkName.log"
        Write-Host "Running $commandName $($commandArguments -join ' ')"
        $startedAt = Get-Date
        $checkExitCode = 1
        try {
            Get-Command $commandName -ErrorAction Stop | Out-Null
            # Windows PowerShell can wrap stderr in ErrorRecord objects.
            # Keep collecting output, then judge native checks by their exit code.
            $ErrorActionPreference = 'Continue'
            & $commandName @commandArguments 2>&1 | Tee-Object -FilePath $logPath
            $checkExitCode = $LASTEXITCODE
            $ErrorActionPreference = 'Stop'
        } catch {
            $ErrorActionPreference = 'Stop'
            $_ | Out-String | Tee-Object -FilePath $logPath -Append | Write-Host
        }
        $checkResults += [PSCustomObject]@{
            Check = $checkName
            ExitCode = $checkExitCode
            Seconds = [math]::Round(((Get-Date) - $startedAt).TotalSeconds, 1)
            Log = $logPath
        }
    }
    $checkResults | Format-Table -AutoSize
    $checkResults | ConvertTo-Json | Set-Content -Path (Join-Path $logDirectory 'results.json') -Encoding UTF8
    Write-Host "Results saved to $logDirectory"
} finally {
    $env:GRADLE_USER_HOME = $previousGradleHome
    $env:GIT_CONFIG_COUNT = $previousGitConfigCount
    if ($sdkGitKeyName) {
        [Environment]::SetEnvironmentVariable($sdkGitKeyName, $previousSdkGitKey, 'Process')
        [Environment]::SetEnvironmentVariable($sdkGitValueName, $previousSdkGitValue, 'Process')
    }
    Pop-Location
}

if (@($checkResults | Where-Object { $_.ExitCode -ne 0 }).Count -gt 0) {
    exit 1
}
exit 0
