import hashlib
import os
import stat
import subprocess
import tempfile
from pathlib import Path


def snapshot(paths: list[Path]) -> dict[str, tuple[int, str]]:
    records = {}
    for root in paths:
        entries = [root, *root.rglob("*")] if root.is_dir() else [root]
        for path in entries:
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                value = os.readlink(path)
            elif stat.S_ISREG(mode):
                value = hashlib.sha256(path.read_bytes()).hexdigest()
            else:
                value = ""
            records[str(path)] = (mode, value)
    return records


def check() -> None:
    approval = Path("/app/approved.txt")
    original = approval.read_bytes()
    original_mode = approval.stat().st_mode
    try:
        with tempfile.TemporaryDirectory(prefix="dry-run-check-") as temporary:
            directory = Path(temporary)
            cases = []
            for package, decision in [
                ("acme-agent-utils", "APPROVED"),
                ("acme-agent", "QUARANTINED"),
                ("acme-notes", "QUARANTINED"),
            ]:
                staging = directory / package
                (staging / "DEBIAN").mkdir(parents=True)
                (staging / "DEBIAN/control").write_text(
                    f"Package: {package}\nVersion: 2.0\nArchitecture: all\n"
                    "Maintainer: QA <qa@example.invalid>\nDescription: Documentation fixture\n"
                )
                artifact = directory / f"{package} with spaces.deb"
                subprocess.run(
                    ["dpkg-deb", "--build", str(staging), str(artifact)],
                    check=True,
                    capture_output=True,
                    timeout=15,
                )
                cases.append(([str(artifact)], f"{package}\t{decision}\n"))
            invalid = directory / "invalid.deb"
            invalid.write_text("not a Debian archive\n")
            cases.extend(
                [
                    ([], None),
                    ([str(invalid)], None),
                    ([str(directory / "missing.deb")], None),
                ]
            )
            protected = [Path("/var/lib/package-repository"), directory, approval]
            for _ in range(2):
                for arguments, expected in cases:
                    before = snapshot(protected)
                    result = subprocess.run(
                        ["/app/repoctl.sh", "dry-run", *arguments],
                        capture_output=True,
                        text=True,
                        timeout=15,
                    )
                    assert snapshot(protected) == before, (
                        "Dry-run mutated protected state"
                    )
                    if expected is None:
                        assert (
                            result.returncode != 0
                            and result.stderr
                            and not result.stdout
                        ), "Invalid input contract failed"
                    else:
                        assert result.returncode == 0, (
                            f"Dry-run failed: {result.stderr.strip()}"
                        )
                        assert result.stdout == expected, (
                            f"Expected {expected!r}, got {result.stdout!r}"
                        )
                        assert not result.stderr, f"Unexpected stderr: {result.stderr}"
            approval.write_text(original.decode() + "\nacme-notes\n")
            before = snapshot(protected)
            result = subprocess.run(
                [
                    "/app/repoctl.sh",
                    "dry-run",
                    str(directory / "acme-notes with spaces.deb"),
                ],
                capture_output=True,
                text=True,
                timeout=15,
            )
            assert (
                result.returncode == 0
                and result.stdout == "acme-notes\tAPPROVED\n"
                and not result.stderr
            ), "Approval file was not read dynamically"
            assert snapshot(protected) == before, (
                "Dynamic approval check mutated protected state"
            )
    finally:
        approval.write_bytes(original)
        approval.chmod(original_mode)


if __name__ == "__main__":
    try:
        check()
    except (AssertionError, OSError, subprocess.SubprocessError) as error:
        print(f"INCORRECT: {error}")
    else:
        print(
            "CORRECT: Dry-run output, exact approval, invalid inputs, repeated calls, and state preservation passed"
        )
