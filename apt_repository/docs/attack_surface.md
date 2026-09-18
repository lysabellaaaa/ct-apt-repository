# Integrity boundaries

The approval file expresses the packaging team's publication policy. Package names must match whole lines exactly. Package metadata, the quarantine directory, the published pool, archive indexes, and downloaded bytes are separate integrity boundaries.

NGINX serves only the public archive directory. Quarantine is outside that directory. The consumer check uses a separate APT client and fresh metadata caches to confirm that approved bytes are retrievable and unapproved packages remain unavailable. Harmless documentation packages exercise these properties without installing or executing package contents.

This teaching environment uses an unsigned repository on an internal service network. Production deployment would require signed metadata, an approval workflow, and an appropriate network access policy.
