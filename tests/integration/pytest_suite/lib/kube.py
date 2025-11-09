from __future__ import annotations

import time
import uuid
from dataclasses import dataclass
from typing import Dict, Iterable, List, Sequence

from kubernetes import client
from kubernetes.stream import stream

from .utils import run_command


@dataclass
class NamespaceHandle:
    name: str
    env: Dict[str, str]

    def delete(self) -> None:
        run_command(
            ["kubectl", "delete", "namespace", self.name, "--ignore-not-found=true"],
            env=self.env,
            check=False,
        )


def create_namespace(prefix: str, env: Dict[str, str]) -> NamespaceHandle:
    name = f"{prefix}-{uuid.uuid4().hex[:5]}"
    run_command(["kubectl", "create", "namespace", name], env=env)
    return NamespaceHandle(name=name, env=env)


def wait_for_deployment_ready(
    api: client.AppsV1Api,
    *,
    name: str,
    namespace: str,
    timeout_seconds: int = 300,
) -> client.V1Deployment:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        deployment = api.read_namespaced_deployment(name=name, namespace=namespace)
        desired = deployment.spec.replicas or 0
        available = deployment.status.available_replicas or 0

        if desired and available >= desired:
            return deployment

        time.sleep(5)

    raise TimeoutError(
        f"Deployment {name} in namespace {namespace} did not become ready within {timeout_seconds}s",
    )


def read_config_map(
    api: client.CoreV1Api,
    *,
    name: str,
    namespace: str,
) -> client.V1ConfigMap:
    return api.read_namespaced_config_map(name=name, namespace=namespace)


def read_service(
    api: client.CoreV1Api,
    *,
    name: str,
    namespace: str,
) -> client.V1Service:
    return api.read_namespaced_service(name=name, namespace=namespace)


def persistent_volume_claims(
    api: client.CoreV1Api,
    *,
    namespace: str,
) -> Sequence[client.V1PersistentVolumeClaim]:
    response = api.list_namespaced_persistent_volume_claim(namespace=namespace)
    return response.items


def pod_logs(
    api: client.CoreV1Api,
    *,
    namespace: str,
    label_selector: str,
    container: str | None = None,
) -> str:
    pods = api.list_namespaced_pod(namespace=namespace, label_selector=label_selector)
    if not pods.items:
        return ""

    return api.read_namespaced_pod_log(
        name=pods.items[0].metadata.name,
        namespace=namespace,
        container=container,
    )


def first_pod_name(
    api: client.CoreV1Api,
    *,
    namespace: str,
    label_selector: str,
) -> str:
    pods = api.list_namespaced_pod(namespace=namespace, label_selector=label_selector)
    if not pods.items:
        raise RuntimeError(
            f"No pods found in namespace {namespace} with selector {label_selector}",
        )
    return pods.items[0].metadata.name


def exec_in_pod(
    api: client.CoreV1Api,
    *,
    namespace: str,
    pod_name: str,
    command: list[str],
    container: str | None = None,
) -> str:
    return stream(
        api.connect_get_namespaced_pod_exec,
        pod_name,
        namespace,
        container=container,
        command=command,
        stderr=True,
        stdin=False,
        stdout=True,
        tty=False,
    )
