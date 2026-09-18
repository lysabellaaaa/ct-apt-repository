# Internal APT Repository

## Overview

Acme's packaging team maintains an internal repository for distributing approved Debian packages. A Bash command-line publisher classifies package metadata, stores accepted artifacts, and rebuilds an APT index. NGINX serves the archive at `http://default:8080/`, and a separate client retrieves packages through APT.

## Capabilities

- Publish a local `.deb` with `/app/repoctl.sh publish PACKAGE.deb`.
- Approve package names by exact lines in `/app/approved.txt`; retain other packages in quarantine.
- Rebuild flat archive indexes with `/app/repoctl.sh index`.
- Preserve repository contents and the publication log across service restarts.

## Key files

- `/app/repoctl.sh`: publication decisions, artifact copying, and index generation.
- `/app/approved.txt`: exact package names authorized for publication.
- `/app/fixtures/`: documentation-only sample packages for local checks.
- `/app/nginx.conf`: HTTP service and archive root configuration.
- `/app/restart.sh`: validate configuration and start or reload the HTTP service.
- `/var/lib/package-repository/public/`: APT indexes and downloadable `pool/` artifacts.
- `/var/lib/package-repository/quarantine/`: artifacts held back from publication.
- `/var/lib/package-repository/publish.log`: package names and publication decisions.
- `/var/log/nginx/`: HTTP access and error logs.

## Running the system

Run `/app/restart.sh` to start or reload NGINX; inspect `/var/log/nginx/error.log` if it fails. Check archive availability with `curl --fail http://localhost:8080/Packages.gz`. The client source is `deb [trusted=yes] http://default:8080 ./`; `apt-get update` refreshes metadata and `apt-get download acme-agent-utils` retrieves an approved package. The internal unsigned archive requires no credentials. Restarting does not publish additional artifacts or reset state.
