import tomllib
from pathlib import Path

import wrms_backend

PYPROJECT = Path(__file__).resolve().parents[2] / "pyproject.toml"


def test_version_matches_pyproject() -> None:
    # Proves the package is installed and its metadata comes from pyproject.toml.
    expected = tomllib.loads(PYPROJECT.read_text(encoding="utf-8"))["project"]["version"]

    assert wrms_backend.__version__ == expected
