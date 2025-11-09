from __future__ import annotations

import os
import shutil
import tempfile
import uuid
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import Dict

import pytest
from kubernetes import client, config

from .lib.utils import run_command

KIND_IMAGE = os.getenv("PYTEST_KIND_IMAGE", "kindest/node:v1.30.0")


@dataclass
class KindClusterContext:
    name: str
    kubeconfig: Path
    env: Dict[str, str]


@pytest.fixture(scope="session")
def repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


@pytest.fixture(scope="session")
def charts_root(repo_root: Path) -> Path:
    return repo_root / "charts"


@pytest.fixture(scope="session")
def kind_cluster() -> Iterator[KindClusterContext]:
    base_name = os.getenv("PYTEST_KIND_CLUSTER", "helm-charts-pytest")
    cluster_name = f"{base_name}-{uuid.uuid4().hex[:6]}"
    work_dir = Path(tempfile.mkdtemp(prefix="kind-"))
    kubeconfig_path = work_dir / "kubeconfig"

    base_env = os.environ.copy()
    create_command = [
        "kind",
        "create",
        "cluster",
        "--name",
        cluster_name,
        "--wait",
        "120s",
        "--image",
        KIND_IMAGE,
        "--kubeconfig",
        str(kubeconfig_path),
    ]

    run_command(create_command, env=base_env)

    env = base_env.copy()
    env["KUBECONFIG"] = str(kubeconfig_path)

    context = KindClusterContext(
        name=cluster_name,
        kubeconfig=kubeconfig_path,
        env=env,
    )

    try:
        yield context
    finally:
        run_command(
            ["kind", "delete", "cluster", "--name", cluster_name],
            env=base_env,
            check=False,
        )
        shutil.rmtree(work_dir, ignore_errors=True)


@pytest.fixture(scope="session")
def core_v1_api(kind_cluster: KindClusterContext) -> client.CoreV1Api:
    config.load_kube_config(config_file=str(kind_cluster.kubeconfig))
    return client.CoreV1Api()


@pytest.fixture(scope="session")
def apps_v1_api(kind_cluster: KindClusterContext) -> client.AppsV1Api:
    config.load_kube_config(config_file=str(kind_cluster.kubeconfig))
    return client.AppsV1Api()
