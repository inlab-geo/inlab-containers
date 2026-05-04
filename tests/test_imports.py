# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
from docker import DockerClient


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
