# Pytest Integration Suite

This directory implements the next-generation integration harness for the charts in
this repository. Tests spin up a short-lived [kind](https://kind.sigs.k8s.io/)
cluster, install charts with Helm, and assert on Kubernetes resources via the
official Python client.

## Local Usage

```bash
# Create the local virtual environment and install dependencies
task pyenv

# Run the pytest suite (creates its own kind cluster)
task pytest
```

Environment variables:

- `PYTEST_KIND_IMAGE`: override the kind node image (defaults to `kindest/node:v1.30.0`)
- `PYTEST_KIND_CLUSTER`: base name used for the ephemeral cluster

## Structure

- `conftest.py`: Session-scoped fixtures for repo paths, kind cluster lifecycle,
  and Kubernetes API clients.
- `lib/`: Helpers for shelling out to Helm/kubectl and for Kubernetes assertions.
- `charts/`: Chart-specific test modules (currently `test_mosquitto.py` and `test_music_assistant.py`).

The legacy bash-based tests remain available while the pytest harness is rolled
out chart by chart. Once all charts are ported, the bash scripts will be removed
and CI will run `pytest` instead.
