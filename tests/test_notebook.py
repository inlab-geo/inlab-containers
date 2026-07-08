# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
import requests
from tests.conftest import TrackedContainer, find_free_port


def test_secured_server(
    container: TrackedContainer, http_client: requests.Session
) -> None:
    """Notebook server should eventually request user login."""
    host_port = find_free_port()
    container.run_detached(ports={"8888/tcp": host_port})
    resp = http_client.get(f"http://localhost:{host_port}")
    resp.raise_for_status()
    assert "login_submit" in resp.text, "User login not requested"


def test_cofi_marimo_server(
    cofi_container: TrackedContainer, http_client: requests.Session
) -> None:
    """cofi image should serve the cofi-paper marimo notebooks."""
    host_port = find_free_port()
    cofi_container.run_detached(ports={"2718/tcp": host_port})
    resp = http_client.get(f"http://localhost:{host_port}")
    resp.raise_for_status()
    assert "marimo" in resp.text.lower(), "Marimo UI not served"
