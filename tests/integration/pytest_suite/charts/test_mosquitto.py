from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path

import pytest

from ..lib.helm import HelmRelease
from ..lib.kube import (
    create_namespace,
    persistent_volume_claims,
    read_config_map,
    read_service,
    wait_for_deployment_ready,
)


@pytest.fixture(scope="module")
def mosquitto_chart(charts_root: Path) -> Path:
    return charts_root / "mosquitto"


@pytest.fixture(scope="module")
def mosquitto_namespace(kind_cluster) -> Iterator[str]:
    handle = create_namespace("mosquitto", kind_cluster.env)
    try:
        yield handle.name
    finally:
        handle.delete()


@pytest.fixture(scope="module")
def mosquitto_release(
    mosquitto_chart: Path,
    mosquitto_namespace: str,
    kind_cluster,
    apps_v1_api,
) -> Iterator[HelmRelease]:
    release = HelmRelease(
        name="mosquitto-pytest",
        chart_path=mosquitto_chart,
        namespace=mosquitto_namespace,
        env=kind_cluster.env,
    )
    release.install()
    wait_for_deployment_ready(
        apps_v1_api,
        name=release.name,
        namespace=release.namespace,
    )

    yield release

    release.uninstall()


def test_mosquitto_deployment_available(mosquitto_release, apps_v1_api):
    deployment = wait_for_deployment_ready(
        apps_v1_api,
        name=mosquitto_release.name,
        namespace=mosquitto_release.namespace,
    )
    assert deployment.status.available_replicas == deployment.spec.replicas


def test_mosquitto_configmap_contains_mqtt_listener(
    mosquitto_release,
    core_v1_api,
):
    config_map = read_config_map(
        core_v1_api,
        name=f"{mosquitto_release.name}-config",
        namespace=mosquitto_release.namespace,
    )
    config_body = config_map.data.get("mosquitto.conf", "")
    assert "listener 1883" in config_body


def test_mosquitto_service_exposes_default_port(
    mosquitto_release,
    core_v1_api,
):
    service = read_service(
        core_v1_api,
        name=mosquitto_release.name,
        namespace=mosquitto_release.namespace,
    )

    ports = {port.port for port in service.spec.ports}
    assert 1883 in ports


def test_persistence_mode_creates_bound_pvc(
    mosquitto_chart: Path,
    kind_cluster,
    apps_v1_api,
    core_v1_api,
    repo_root: Path,
):
    values_file = (
        repo_root / "tests" / "integration" / "charts" / "mosquitto" / "test-values.yaml"
    )
    namespace = create_namespace("mosquitto-persist", kind_cluster.env)
    release = HelmRelease(
        name="mosquitto-persist",
        chart_path=mosquitto_chart,
        namespace=namespace.name,
        env=kind_cluster.env,
    )
    try:
        release.install(values_files=[values_file])
        wait_for_deployment_ready(
            apps_v1_api,
            name=release.name,
            namespace=release.namespace,
        )

        pvcs = persistent_volume_claims(core_v1_api, namespace=namespace.name)
        managed_pvcs = [
            pvc for pvc in pvcs if release.name in pvc.metadata.name
        ]
        assert managed_pvcs, "expected PVCs created by the chart"
        assert managed_pvcs[0].status.phase == "Bound"
    finally:
        release.uninstall()
        namespace.delete()
