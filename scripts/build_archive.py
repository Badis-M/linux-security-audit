"""Build a reproducible CLI archive from an explicit, non-sensitive file allowlist."""

import gzip
import hashlib
import io
import re
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    version = re.search(r'LSA_VERSION="([0-9.]+)"', (ROOT / "lib/cli.sh").read_text())
    if version is None:
        raise SystemExit("Cannot find CLI version")
    name = f"linux-security-audit-{version.group(1)}"
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    archive = output / f"{name}.tar.gz"
    sources = [ROOT / "README.md", ROOT / "LICENSE", ROOT / "CHANGELOG.md"]
    sources.extend(path for folder in ["bin", "lib", "docs"] for path in (ROOT / folder).rglob("*") if path.is_file())
    raw = io.BytesIO()
    with tarfile.open(fileobj=raw, mode="w", format=tarfile.PAX_FORMAT) as bundle:
        for path in sorted(sources):
            relative = path.relative_to(ROOT)
            if path.is_symlink():
                raise SystemExit("Archive sources must not be symlinks")
            info = tarfile.TarInfo(f"{name}/{relative.as_posix()}")
            data = path.read_bytes()
            info.size = len(data)
            info.mode = 0o755 if relative.parts[0] == "bin" else 0o644
            info.uid = info.gid = info.mtime = 0
            bundle.addfile(info, io.BytesIO(data))
    with archive.open("wb") as handle:
        with gzip.GzipFile(filename="", mode="wb", fileobj=handle, mtime=0) as compressed:
            compressed.write(raw.getvalue())
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (output / "SHA256SUMS").write_text(f"{digest}  {archive.name}\n")
    print(archive.name)


if __name__ == "__main__":
    main()
