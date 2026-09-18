#!/bin/bash
set -euo pipefail
root=/var/lib/package-repository
mkdir -p /app/fixtures "$root/public/pool" "$root/quarantine" "$root/incoming"
for package in acme-agent-utils acme-agent acme-notes; do
    staging=$(mktemp -d)
    mkdir -p "$staging/DEBIAN" "$staging/usr/share/doc/$package"
    printf 'Package: %s\nVersion: 1.0\nArchitecture: all\nMaintainer: Acme Packaging <packages@example.invalid>\nDescription: Harmless documentation fixture\n' "$package" > "$staging/DEBIAN/control"
    printf 'Documentation fixture for %s. No executable content.\n' "$package" > "$staging/usr/share/doc/$package/README"
    SOURCE_DATE_EPOCH=1700000000 dpkg-deb --root-owner-group --build "$staging" "/app/fixtures/${package}_1.0_all.deb"
    rm -rf -- "$staging"
done
for fixture in /app/fixtures/*.deb; do
    /app/repoctl.sh publish "$fixture"
done
