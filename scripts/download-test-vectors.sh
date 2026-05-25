#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="lib/src/androidTest/assets/TestVectors"
BASE_URL="https://github.com/zkmopro/zkID/releases/download/latest"
SMT_BASE_URL="https://github.com/moven0831/moica-revocation-smt/releases/download/snapshot-latest"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

download_and_gunzip() {
    local url="$1"        # URL to download
    local folder="${2:-}" # subfolder under DEST_DIR, or empty
    local out_name="${3:-}" # optional: override output filename after decompression
    local filename="${url##*/}"
    local decompressed="${filename%.gz}"
    local dest="$DEST_DIR/${folder:+$folder/}${out_name:-$decompressed}"

    if [ -f "$dest" ]; then
        echo "Already exists: $dest"
        return
    else
        mkdir -p "$(dirname "$dest")"
        echo "Downloading $url -> $dest"
        curl -fL "$url" -o "$TMP/$filename"
        gunzip -c "$TMP/$filename" > "$dest"
        echo "Saved to $dest"
    fi
}

download() {
    local url="$1"
    local folder="${2:-}"
    local filename="${url##*/}"
    local dest="$DEST_DIR/${folder:+$folder/}$filename"

    if [ -f "$dest" ]; then
        echo "Already exists: $dest"
    else
        mkdir -p "$(dirname "$dest")"
        echo "Downloading $url -> $dest"
        curl -fL "$url" -o "$dest"
        echo "Saved to $dest"
    fi
}

download_and_gunzip "$BASE_URL/certChainRS4096.r1cs.gz" "" "cert_chain_rs4096.r1cs"
download_and_gunzip "$BASE_URL/cert_chain_rs4096_proving.key.gz" "keys"
download_and_gunzip "$BASE_URL/cert_chain_rs4096_verifying.key.gz" "keys"
download_and_gunzip "$BASE_URL/userSigRS2048.r1cs.gz" "" "user_sig_rs2048.r1cs"
download_and_gunzip "$BASE_URL/user_sig_rs2048_proving.key.gz" "keys"
download_and_gunzip "$BASE_URL/user_sig_rs2048_verifying.key.gz" "keys"
download "$SMT_BASE_URL/g3-tree-snapshot.json.gz"
