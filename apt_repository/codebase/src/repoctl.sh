#!/bin/bash
set -euo pipefail
root=/var/lib/package-repository

case "${1:-}" in
    publish)
        [[ $# == 2 ]] || { echo 'usage: repoctl.sh publish PACKAGE.deb' >&2; exit 2; }
        package=$(dpkg-deb --field "$2" Package)
        version=$(dpkg-deb --field "$2" Version)
        architecture=$(dpkg-deb --field "$2" Architecture)
        if grep -Fxq -- "$package" /app/approved.txt; then
            destination="$root/public/pool"
            decision=APPROVED
        else
            destination="$root/quarantine"
            decision=QUARANTINED
        fi
        mkdir -p "$destination"
        cp -- "$2" "$destination/${package}_${version}_${architecture}.deb"
        printf '%s\t%s\n' "$package" "$decision" >> "$root/publish.log"
        /app/repoctl.sh index
        printf '%s\t%s\n' "$package" "$decision"
        ;;
    index)
        cd "$root/public"
        dpkg-scanpackages --multiversion pool /dev/null > Packages.next
        gzip -n -c Packages.next > Packages.gz.next
        mv Packages.next Packages
        mv Packages.gz.next Packages.gz
        ;;
    *)
        echo 'usage: repoctl.sh {publish PACKAGE.deb|index}' >&2
        exit 2
        ;;
esac
