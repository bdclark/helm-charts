# Helm Charts Collection

[![CI](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml)
[![Integration Tests](https://github.com/bdclark/helm-charts/actions/workflows/integration-test.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/integration-test.yaml)
[![Release Charts](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml)

Public Helm charts for my personal projects. Each chart has its own README under `charts/<name>` (and a matching Artifact Hub listing).

## Charts

| Chart                                      | Description                   |
|--------------------------------------------|-------------------------------|
| [mosquitto](charts/mosquitto/)             | Eclipse Mosquitto MQTT broker |
| [music-assistant](charts/music-assistant/) | Music Assistant media server  |

## Local Workflow

Prerequisites:

- [Helm 3](https://helm.sh/docs/intro/install/)
- [Task](https://taskfile.dev/)
- `kubectl` (for Kind-based tests)
- helm-unittest plugin
- kubeconform

Run `task tools` once to verify plugins/binaries.

Typical loop:

1. Edit charts in `charts/<name>/`.
2. Update unit tests (`charts/<name>/tests/`) and integration tests (`tests/integration/pytest_suite/charts/test_<name>.py`).
3. Update any chart README templates (`charts/<name>/README.md.gotmpl`) and re-render them with helm-docs if they exist:

   ```shell
   task helm-docs CHART=<name>        # regenerate a single chart README
   task helm-docs-all                # regenerate all chart docs
   ```

4. Validate locally:

   ```shell
   task lint                                   # yamllint over charts/
   task verify-chart CHART=<name>              # helm lint + helm-unittest + kubeconform
   task pytest PYTEST_ARGS=...test_<name>.py   # Kind-backed integration suite
   ```

5. Open a PR; GitHub Actions (`ci.yaml`, `integration-test.yaml`) run the same validations.
6. Merge → release workflow publishes chart packages (HTTPS + OCI).

Other helpful commands:

```shell
task verify-all               # static checks for every chart
task package CHART=<name>     # helm package into repo root
task package-all              # package every chart
task release-local            # build .cr-release-packages/ + local repo index
task clean                    # remove .venv, packages, gitignored files
```

Optional chart-testing utilities remain (`task ct-list`, `task ct-lint`, `task ct-install`) if you need ct-style change detection locally.

## Releases & OCI

- CI + Integration Tests must pass on `main`. The release workflow runs only when a chart version hasn’t been tagged yet (tags follow `<chart>-<version>`).
- Chart Releaser publishes the HTTPS repo (`gh-pages`). The same `.tgz` artifacts are pushed to OCI at `oci://ghcr.io/<owner>/helm-charts/<chart>`.

Install from OCI:

```shell
helm registry login ghcr.io -u <github-username> -p <token>
helm pull oci://ghcr.io/bdclark/helm-charts/mosquitto --version <version>
helm install my-mosquitto oci://ghcr.io/bdclark/helm-charts/mosquitto --version <version>
```

## Expectations

- Bump the chart `version` whenever you change a chart.
- Keep unit tests and pytest suites up to date.
- If a chart uses helm-docs templates, run `task helm-docs CHART=<name>` before opening a PR so the README stays in sync with `values.yaml`.
- Run `task verify-chart` + targeted `task pytest` before sending a PR.

## License & Support

- License: [MIT](LICENSE)
- Issues/Discussion: [GitHub Issues](https://github.com/bdclark/helm-charts/issues)
- For per-chart docs, see the README inside each chart or the Artifact Hub entry.
