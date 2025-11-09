from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path

import pytest

from ..lib.helm import HelmRelease
from ..lib.kube import (
    create_namespace,
    exec_in_pod,
    first_pod_name,
    persistent_volume_claims,
    pod_logs,
    read_service,
    wait_for_deployment_ready,
)

VALUES_FILE_NAME = (
    "tests/integration/charts/music-assistant/test-values.yaml"
)
LABEL_SELECTOR = "app.kubernetes.io/name=music-assistant"


@pytest.fixture(scope="module")
def music_assistant_chart(charts_root: Path) -> Path:
    return charts_root / "music-assistant"


@pytest.fixture(scope="module")
def music_assistant_namespace(kind_cluster) -> Iterator[str]:
    handle = create_namespace("music-assistant", kind_cluster.env)
    try:
        yield handle.name
    finally:
        handle.delete()


@pytest.fixture(scope="module")
def music_assistant_release(
    music_assistant_chart: Path,
    music_assistant_namespace: str,
    kind_cluster,
    apps_v1_api,
    repo_root: Path,
) -> Iterator[HelmRelease]:
    values_file = repo_root / VALUES_FILE_NAME
    release = HelmRelease(
        name="music-assistant-pytest",
        chart_path=music_assistant_chart,
        namespace=music_assistant_namespace,
        env=kind_cluster.env,
    )
    release.install(values_files=[values_file])
    wait_for_deployment_ready(
        apps_v1_api,
        name=release.name,
        namespace=release.namespace,
    )
    try:
        yield release
    finally:
        release.uninstall()


def test_music_assistant_pod_is_running(
    music_assistant_release: HelmRelease,
    core_v1_api,
):
    pod_name = first_pod_name(
        core_v1_api,
        namespace=music_assistant_release.namespace,
        label_selector=LABEL_SELECTOR,
    )
    pod = core_v1_api.read_namespaced_pod(
        name=pod_name,
        namespace=music_assistant_release.namespace,
    )
    assert pod.status.phase == "Running"
    assert pod.spec.host_network in (None, False)


def test_music_assistant_logs_show_startup(
    music_assistant_release: HelmRelease,
    core_v1_api,
):
    logs = pod_logs(
        core_v1_api,
        namespace=music_assistant_release.namespace,
        label_selector=LABEL_SELECTOR,
    )
    assert "Starting Music Assistant Server" in logs
    assert "Starting webserver" in logs


def test_music_assistant_service_ports(
    music_assistant_release: HelmRelease,
    core_v1_api,
):
    service = read_service(
        core_v1_api,
        name=music_assistant_release.name,
        namespace=music_assistant_release.namespace,
    )
    ports = {port.port for port in service.spec.ports}
    assert {8095, 8097}.issubset(ports)


def test_music_assistant_service_has_endpoints(
    music_assistant_release: HelmRelease,
    core_v1_api,
):
    endpoints = core_v1_api.read_namespaced_endpoints(
        name=music_assistant_release.name,
        namespace=music_assistant_release.namespace,
    )
    addresses = []
    for subset in endpoints.subsets or []:
        addresses.extend(subset.addresses or [])
    assert addresses, "expected at least one service endpoint address"


def test_music_assistant_persistence_pvc_bound(
    music_assistant_release: HelmRelease,
    core_v1_api,
):
    pvcs = persistent_volume_claims(
        core_v1_api,
        namespace=music_assistant_release.namespace,
    )
    managed = [
        pvc for pvc in pvcs if music_assistant_release.name in pvc.metadata.name
    ]
    assert managed, "expected persistence PVC managed by the release"
    assert managed[0].status.phase == "Bound"


def test_music_assistant_data_mount_accessible(
    music_assistant_release: HelmRelease,
    core_v1_api,
):
    pod_name = first_pod_name(
        core_v1_api,
        namespace=music_assistant_release.namespace,
        label_selector=LABEL_SELECTOR,
    )
    output = exec_in_pod(
        core_v1_api,
        namespace=music_assistant_release.namespace,
        pod_name=pod_name,
        command=["ls", "-a", "/data"],
    )
    assert "." in output
    assert ".." in output
