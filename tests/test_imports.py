# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
import re
from pathlib import Path

from docker import DockerClient


def _pinned_pygimli_version() -> str:
    containerfile = (Path(__file__).parent.parent / "image" / "Containerfile").read_text()
    match = re.search(r'ARG PYGIMLI_VERSION="([^"]+)"', containerfile)
    assert match, "ARG PYGIMLI_VERSION default not found in image/Containerfile"
    return match.group(1)


def test_example_dependency_imports(
    docker_client: DockerClient,
    image_name: str,
) -> None:
    """Full image should import the packages needed by representative examples."""
    command = [
        "bash",
        "-lc",
        (
            "python -c "
            "\"import cofi, numpy, scipy, matplotlib, pygimli, pysurf96, "
            "pyfm2d, pyrf96, pyhk, smt, seislib, astroquery, discretize; "
            "print('ok')\""
        ),
    ]
    docker_client.containers.run(image_name, command=command, remove=True)


def test_cofi_paper_dependency_imports(docker_client: DockerClient) -> None:
    """cofi image should import CoFI plus the packages cofi-paper's notebooks need."""
    command = [
        "bash",
        "-lc",
        (
            "python -c "
            "\"import cofi, numpy, scipy, matplotlib, h5py, arviz, bayesbay, "
            "seislib, cartopy, cmcrameri, mealpy, pyfm2d, marimo; "
            "print('ok')\""
        ),
    ]
    docker_client.containers.run("inlabgeo/cofi", command=command, remove=True)


def test_cofi_excludes_full_examples(docker_client: DockerClient) -> None:
    """cofi image should only carry cofi-paper, not the rest of cofi-examples
    or the inlab-only PyGIMLi/Jupyter stack."""
    command = [
        "bash",
        "-lc",
        (
            "test -d /home/jovyan/cofi-examples/cofi-paper "
            "&& test ! -e /home/jovyan/cofi-examples/examples "
            "&& test ! -e /home/jovyan/cofi-examples/tutorials "
            "&& ! python -c 'import jupyterlab' 2>/dev/null "
            "&& ! python -c 'import pygimli' 2>/dev/null "
            "&& echo PASS"
        ),
    ]
    result = docker_client.containers.run("inlabgeo/cofi", command=command, remove=True)
    assert b"PASS" in result


def test_pygimli_version_matches_pin(
    docker_client: DockerClient,
    image_name: str,
) -> None:
    """PyGIMLi should resolve to the Containerfile's pinned PYGIMLI_VERSION on every
    architecture, whether installed via the amd64 pip wheel or built from source on arm64."""
    pinned = _pinned_pygimli_version()
    command = [
        "bash",
        "-lc",
        "python -c 'import pygimli as pg; print(pg.__version__)'",
    ]
    result = docker_client.containers.run(image_name, command=command, remove=True)
    assert pinned in result.decode()
