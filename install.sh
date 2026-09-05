#!/bin/sh
set -eu
version=${SEAAPP_VERSION:-latest}
bindir=${SEAAPP_INSTALL_DIR:-"$HOME/.local/bin"}
case "$version" in latest) release=latest/download ;; v[0-9]*) case "$version" in *[!a-zA-Z0-9._-]*) echo 'Invalid SEAAPP_VERSION' >&2; exit 2;; esac; release="download/$version" ;; *) echo 'SEAAPP_VERSION must be latest or a v-prefixed release tag' >&2; exit 2;; esac
case "$(uname -s)" in Darwin) os=darwin ;; Linux) os=linux ;; *) echo 'Use install.ps1 on Windows.' >&2; exit 2;; esac
case "$(uname -m)" in arm64|aarch64) arch=arm64 ;; x86_64|amd64) arch=x64 ;; *) echo 'Unsupported architecture' >&2; exit 2;; esac
asset="seaapp-$os-$arch.tar.gz"
base="https://github.com/SeaAPPAI/seaapp-cli/releases/$release"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
curl --fail --location --silent --show-error --retry 3 "$base/$asset" -o "$tmp/$asset"
curl --fail --location --silent --show-error --retry 3 "$base/SHA256SUMS" -o "$tmp/SHA256SUMS"
expected=$(awk -v name="$asset" '$2 == name { print $1 }' "$tmp/SHA256SUMS")
[ ${#expected} -eq 64 ] || { echo 'Missing checksum' >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$tmp/$asset" | awk '{print $1}'); else actual=$(shasum -a 256 "$tmp/$asset" | awk '{print $1}'); fi
[ "$actual" = "$expected" ] || { echo 'Checksum mismatch' >&2; exit 1; }
tar -xzf "$tmp/$asset" -C "$tmp" seaapp
mkdir -p "$bindir"
install -m 755 "$tmp/seaapp" "$bindir/.seaapp-install-$$"
mv -f "$bindir/.seaapp-install-$$" "$bindir/seaapp"
"$bindir/seaapp" --version
printf 'Installed to %s/seaapp\nAdd %s to PATH if needed.\n' "$bindir" "$bindir"
