#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# TALIB ILM — PRODUCTION ANDROID KEYSTORE SETUP TOOL (BASH)
# ============================================================

ALIAS="${1:-talib-ilm-upload}"
DNAME="CN=Talib Ilm App, OU=Engineering, O=Talib Ilm, C=DZ"

echo "============================================================"
echo " TALIB ILM — PRODUCTION ANDROID KEYSTORE SETUP TOOL (BASH)  "
echo "============================================================"

# 1. Locate keytool
if ! command -v keytool &> /dev/null; then
    echo "[ERROR] 'keytool' not found. Please install OpenJDK or Android Studio." >&2
    exit 1
fi

# 2. Get password
read -s -p "Enter a strong password for your release keystore: " PASSWORD
echo ""
if [ ${#PASSWORD} -lt 6 ]; then
    echo "[ERROR] Password must be at least 6 characters long." >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$REPO_ROOT/android"
KEYSTORE_PATH="$ANDROID_DIR/upload-keystore.jks"
PROPERTIES_PATH="$ANDROID_DIR/key.properties"

# 3. Generate Keystore if not exists
if [ -f "$KEYSTORE_PATH" ]; then
    read -p "Keystore already exists. Overwrite? (y/N): " ANS
    if [[ "$ANS" =~ ^[Yy]$ ]]; then
        rm -f "$KEYSTORE_PATH"
    fi
fi

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "[1/4] Generating 4096-bit RSA production keystore..."
    keytool -genkeypair -v \
        -keystore "$KEYSTORE_PATH" \
        -alias "$ALIAS" \
        -keyalg RSA \
        -keysize 4096 \
        -validity 10000 \
        -storepass "$PASSWORD" \
        -keypass "$PASSWORD" \
        -dname "$DNAME" \
        -storetype JKS
    echo "[PASS] Keystore generated: $KEYSTORE_PATH"
fi

# 4. Generate key.properties
echo "[2/4] Writing android/key.properties..."
cat <<EOF > "$PROPERTIES_PATH"
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=$ALIAS
storeFile=../upload-keystore.jks
EOF
echo "[PASS] android/key.properties written successfully."

# 5. Extract Fingerprints
echo "[3/4] Extracting Certificate Fingerprints..."
CERT_INFO=$(keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$ALIAS" -storepass "$PASSWORD")
SHA256=$(echo "$CERT_INFO" | grep -E "SHA256:" | awk '{print $2}')
SHA1=$(echo "$CERT_INFO" | grep -E "SHA1:" | awk '{print $2}')

echo "  -> SHA-256 Fingerprint: $SHA256"
echo "  -> SHA-1   Fingerprint: $SHA1"

# 6. Base64 encode for GitHub Actions
echo "[4/4] Base64 Encoding Keystore for GitHub Actions CI/CD..."
BASE64_KEYSTORE=$(base64 -w 0 "$KEYSTORE_PATH" 2>/dev/null || base64 "$KEYSTORE_PATH")

SECRETS_OUT="$ANDROID_DIR/keystore_secrets_export.txt"
cat <<EOF > "$SECRETS_OUT"
============================================================
 TALIB ILM — PRODUCTION RELEASE CREDENTIALS
 (KEEP THIS FILE STRICTLY PRIVATE - DO NOT COMMIT)
============================================================
Keystore File : android/upload-keystore.jks
Properties    : android/key.properties
Key Alias     : $ALIAS
Key Password  : $PASSWORD
Store Password: $PASSWORD

CERTIFICATE FINGERPRINTS:
SHA-256: $SHA256
SHA-1  : $SHA1

GITHUB ACTIONS REPOSITORY SECRETS:
ANDROID_KEYSTORE_BASE64 :
$BASE64_KEYSTORE

KEYSTORE_PASSWORD : $PASSWORD
KEY_ALIAS         : $ALIAS
KEY_PASSWORD      : $PASSWORD
============================================================
EOF
echo "[PASS] Secrets exported safely to: $SECRETS_OUT"

echo "============================================================"
echo " ALL SETUP COMPLETE! You can now run: flutter build appbundle --release"
echo "============================================================"

