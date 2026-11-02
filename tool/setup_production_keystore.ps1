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
Write-Host " TALIB ILM — PRODUCTION ANDROID KEYSTORE SETUP TOOL        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check for keytool (JDK)
$keytoolPath = (Get-Command keytool -ErrorAction SilentlyContinue)
if (-not $keytoolPath) {
    # Check common Java install paths
    $javaHomes = @(
        $env:JAVA_HOME,
        "C:\Program Files\Android\Android Studio\jbr\bin",
        "C:\Program Files\Java"
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

$repoRoot = Resolve-Path "$PSScriptRoot\.."
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
$propsContent = @"
storePassword=$Password
keyPassword=$Password
keyAlias=$Alias
storeFile=../upload-keystore.jks
"@
Set-Content -Path $propertiesPath -Value $propsContent -Encoding Ascii
Write-Host "[PASS] android/key.properties written successfully." -ForegroundColor Green

# 5. Extract Fingerprints
Write-Host "`n[3/4] Extracting Certificate Fingerprints..." -ForegroundColor Cyan
$certInfo = & $keytoolPath -list -v -keystore $keystorePath -alias $Alias -storepass $Password
$sha256 = ($certInfo | Select-String "SHA256:\s*([A-F0-9:]+)").Matches.Groups[1].Value
$sha1 = ($certInfo | Select-String "SHA1:\s*([A-F0-9:]+)").Matches.Groups[1].Value

Write-Host "  -> SHA-256 Fingerprint: $sha256" -ForegroundColor Magenta
Write-Host "  -> SHA-1   Fingerprint: $sha1" -ForegroundColor Magenta

# 6. Base64 encode for GitHub Actions
Write-Host "`n[4/4] Base64 Encoding Keystore for GitHub Actions CI/CD..." -ForegroundColor Cyan
$keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
$base64Keystore = [System.Convert]::ToBase64String($keystoreBytes)

# Save secrets summary file (ignored by Git)
$secretsOut = Join-Path $androidDir "keystore_secrets_export.txt"
$secretsText = @"
============================================================
 TALIB ILM — PRODUCTION RELEASE CREDENTIALS
 (KEEP THIS FILE STRICTLY PRIVATE - DO NOT COMMIT)
============================================================
Keystore File : android/upload-keystore.jks
Properties    : android/key.properties
Key Alias     : $Alias
Key Password  : $Password
Store Password: $Password

CERTIFICATE FINGERPRINTS:
SHA-256: $sha256
SHA-1  : $sha1

GITHUB ACTIONS REPOSITORY SECRETS (Settings -> Secrets -> Actions):
------------------------------------------------------------
ANDROID_KEYSTORE_BASE64 :
$base64Keystore

KEYSTORE_PASSWORD : $Password
KEY_ALIAS         : $Alias
KEY_PASSWORD      : $Password
============================================================
"@
Set-Content -Path $secretsOut -Value $secretsText -Encoding Utf8
Write-Host "[PASS] Secrets exported safely to: $secretsOut" -ForegroundColor Green

# 7. Check .gitignore safety
$gitignorePath = Join-Path $repoRoot ".gitignore"
$gitignore = Get-Content $gitignorePath
$hasKeystore = $gitignore | Select-String "upload-keystore.jks|\*.jks"
$hasProps = $gitignore | Select-String "key.properties"

if ($hasKeystore -and $hasProps) {
    Write-Host "`n[VERIFIED] .gitignore safely protects upload-keystore.jks and key.properties from git commit." -ForegroundColor Green
} else {
    Write-Host "`n[WARN] Please verify .gitignore includes *.jks and key.properties." -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " ALL SETUP COMPLETE! You can now run:" -ForegroundColor Green
Write-Host "   flutter build appbundle --release" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

