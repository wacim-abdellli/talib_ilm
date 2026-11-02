<#
.SYNOPSIS
  Automated Turnkey Production Keystore Generator for طالب العلم (talib_ilm).
.DESCRIPTION
  Generates a production 4096-bit RSA upload keystore, configures android/key.properties,
  prints certificate fingerprints (SHA-256, SHA-1), and outputs the Base64 secret for GitHub Actions.
#>

param(
    [string]$Alias = "talib-ilm-upload",
    [string]$Password = "",
    [string]$DName = "CN=Talib Ilm App, OU=Engineering, O=Talib Ilm, C=DZ"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TALIB ILM -- PRODUCTION ANDROID KEYSTORE SETUP TOOL        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check for keytool (JDK)
$keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
$keytoolPath = ""
if ($keytoolCmd) {
    $keytoolPath = $keytoolCmd.Source
} else {
    $javaHomes = @(
        $env:JAVA_HOME,
        "C:\Program Files\Java\jdk-17\bin",
        "C:\Program Files\Android\Android Studio\jbr\bin"
    )
    foreach ($jh in $javaHomes) {
        if ($jh -and (Test-Path "$jh\keytool.exe")) {
            $keytoolPath = "$jh\keytool.exe"
            break
        }
        if ($jh -and (Test-Path "$jh\bin\keytool.exe")) {
            $keytoolPath = "$jh\bin\keytool.exe"
            break
        }
    }
}

if (-not $keytoolPath) {
    Write-Host "[ERROR] 'keytool' not found. Please install OpenJDK or Android Studio." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Using keytool: $keytoolPath" -ForegroundColor Green

# 2. Set Keystore Password
if ([string]::IsNullOrWhiteSpace($Password)) {
    Write-Host "`n[INPUT REQUIRED] Enter a strong password for your release keystore:" -ForegroundColor Yellow
    $securePass = Read-Host -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    if ([string]::IsNullOrWhiteSpace($Password) -or $Password.Length -lt 6) {
        Write-Host "[ERROR] Password must be at least 6 characters long." -ForegroundColor Red
        exit 1
    }
}

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$androidDir = Join-Path $repoRoot "android"
$keystorePath = Join-Path $androidDir "upload-keystore.jks"
$propertiesPath = Join-Path $androidDir "key.properties"

# 3. Generate Keystore if not exists
if (Test-Path $keystorePath) {
    Write-Host "`n[WARN] Keystore already exists at: $keystorePath" -ForegroundColor Yellow
    $ans = Read-Host "Do you want to overwrite it? (y/N)"
    if ($ans -ne 'y' -and $ans -ne 'Y') {
        Write-Host "Keeping existing keystore. Skipping generation." -ForegroundColor Yellow
    } else {
        Remove-Item $keystorePath -Force
    }
}

if (-not (Test-Path $keystorePath)) {
    Write-Host "`n[1/4] Generating 4096-bit RSA production keystore..." -ForegroundColor Cyan
    & $keytoolPath -genkeypair -v `
        -keystore $keystorePath `
        -alias $Alias `
        -keyalg RSA `
        -keysize 4096 `
        -validity 10000 `
        -storepass $Password `
        -keypass $Password `
        -dname $DName `
        -storetype JKS

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Keytool generation failed." -ForegroundColor Red
        exit 1
    }
    Write-Host "[PASS] Keystore generated successfully: $keystorePath" -ForegroundColor Green
}

# 4. Generate android/key.properties
Write-Host "`n[2/4] Writing android/key.properties..." -ForegroundColor Cyan
$propsContent = "storePassword=" + $Password + "`nkeyPassword=" + $Password + "`nkeyAlias=" + $Alias + "`nstoreFile=../upload-keystore.jks`n"
[System.IO.File]::WriteAllText($propertiesPath, $propsContent, [System.Text.Encoding]::ASCII)
Write-Host "[PASS] android/key.properties written successfully." -ForegroundColor Green

# 5. Extract Fingerprints
Write-Host "`n[3/4] Extracting Certificate Fingerprints..." -ForegroundColor Cyan
$certInfo = & $keytoolPath -list -v -keystore $keystorePath -alias $Alias -storepass $Password
$sha256Match = [regex]::Match($certInfo, 'SHA256:\s*([A-F0-9:]+)')
$sha1Match = [regex]::Match($certInfo, 'SHA1:\s*([A-F0-9:]+)')
$sha256 = if ($sha256Match.Success) { $sha256Match.Groups[1].Value } else { "N/A" }
$sha1 = if ($sha1Match.Success) { $sha1Match.Groups[1].Value } else { "N/A" }

Write-Host "  -> SHA-256 Fingerprint: $sha256" -ForegroundColor Magenta
Write-Host "  -> SHA-1   Fingerprint: $sha1" -ForegroundColor Magenta

# 6. Base64 encode for GitHub Actions
Write-Host "`n[4/4] Base64 Encoding Keystore for GitHub Actions CI/CD..." -ForegroundColor Cyan
$keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
$base64Keystore = [System.Convert]::ToBase64String($keystoreBytes)

$secretsOut = Join-Path $androidDir "keystore_secrets_export.txt"
$secretsText = "TALIB ILM RELEASE CREDENTIALS`n`n" +
    "Keystore File: android/upload-keystore.jks`n" +
    "Key Alias: $Alias`n" +
    "Key Password: $Password`n" +
    "SHA-256: $sha256`n" +
    "SHA-1: $sha1`n`n" +
    "GITHUB ACTIONS SECRET (ANDROID_KEYSTORE_BASE64):`n$base64Keystore`n"

[System.IO.File]::WriteAllText($secretsOut, $secretsText, [System.Text.Encoding]::UTF8)
Write-Host "[PASS] Secrets exported safely to: $secretsOut" -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " ALL SETUP COMPLETE! Keystore and key.properties are ready." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
