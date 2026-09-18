#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
project="ct-apt-check-$(date +%s)-$$"
compose=(docker compose -p "$project" -f apt_repository/codebase/compose.yml)
trap '"${compose[@]}" down --volumes --remove-orphans > /dev/null' EXIT
"${compose[@]}" build
"${compose[@]}" up -d --wait
expected_hash=$("${compose[@]}" exec -T default sha256sum /app/fixtures/acme-agent-utils_1.0_all.deb | cut -d ' ' -f 1)
"${compose[@]}" cp apt_repository/tests/check_client.py client:/tmp/check_client.py
"${compose[@]}" cp apt_repository/main_tasks/add_publish_dry_run/check_dry_run.py default:/tmp/check_dry_run.py
"${compose[@]}" exec -T client python3 /tmp/check_client.py "$expected_hash"
baseline=$("${compose[@]}" exec -T default python3 /tmp/check_dry_run.py)
printf '%s\n' "$baseline"
[[ "$baseline" == INCORRECT:* ]] || { echo 'Unsolved baseline unexpectedly passed' >&2; exit 1; }
"${compose[@]}" exec -T default patch --batch --forward --directory=/app --strip=1 < apt_repository/main_tasks/add_publish_dry_run/reference_solution/dry-run.patch
for iteration in 1 2; do
    solved=$("${compose[@]}" exec -T default python3 /tmp/check_dry_run.py)
    printf '%s\n' "$solved"
    [[ "$solved" == CORRECT:* ]] || exit 1
done
"${compose[@]}" exec -T default /app/repoctl.sh publish /app/fixtures/acme-agent-utils_1.0_all.deb
"${compose[@]}" exec -T default /app/repoctl.sh publish /app/fixtures/acme-agent_1.0_all.deb
"${compose[@]}" exec -T client python3 /tmp/check_client.py "$expected_hash"
before=$("${compose[@]}" exec -T default sha256sum /var/lib/package-repository/public/Packages.gz /var/lib/package-repository/publish.log)
"${compose[@]}" exec -T default /app/restart.sh
"${compose[@]}" restart default
"${compose[@]}" up -d --wait
after=$("${compose[@]}" exec -T default sha256sum /var/lib/package-repository/public/Packages.gz /var/lib/package-repository/publish.log)
[[ "$before" == "$after" ]] || { echo 'Restart changed persisted state' >&2; exit 1; }
"${compose[@]}" exec -T client python3 /tmp/check_client.py "$expected_hash"
echo 'PASS: baseline fails; reference solution passes twice; publication, isolation, and restart persistence pass'
