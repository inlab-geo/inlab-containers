from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {".git", "__pycache__"}
TERMS = (
    "".join(("e", "sp", "resso")),
    "geo-" + "".join(("e", "sp", "resso")),
    "cofi_n_" + "".join(("e", "sp", "resso")),
    "".join(("E", "SP", "RESSO")),
)


def iter_text_files():
    for path in ROOT.rglob("*"):
        if any(part in SKIP_DIRS or part.startswith("notebook-run-results") for part in path.parts):
            continue
        if not path.is_file():
            continue
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue
        yield path, text


def test_removed_package_references() -> None:
    matches = []
    for path, text in iter_text_files():
        for term in TERMS:
            if term in text:
                matches.append(path.relative_to(ROOT).as_posix())
                break
    assert matches == []


if __name__ == "__main__":
    test_removed_package_references()
