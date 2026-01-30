# Helm Charts

[![CI](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml)
[![Release](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml)

Personal Helm charts. Each chart has its own README under `charts/<name>/`.

## Charts

| Chart                                       | Description                    |
| ------------------------------------------- | ------------------------------ |
| [mealie](charts/mealie/)                    | Mealie recipe manager          |
| [mosquitto](charts/mosquitto/)              | Eclipse Mosquitto MQTT broker  |
| [music-assistant](charts/music-assistant/)  | Music Assistant media server   |
| [qbittorrent-vpn](charts/qbittorrent-vpn/)  | qBittorrent with VPN sidecar   |

## Usage

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install my-release bdclark/<chart>
```

Or via OCI:

```bash
helm install my-release oci://ghcr.io/bdclark/helm-charts/<chart> --version <version>
```

## Local Development

Prerequisites: [Helm](https://helm.sh/docs/intro/install/), [Task](https://taskfile.dev/), [kubeconform](https://github.com/yannh/kubeconform), [helm-docs](https://github.com/norwoodj/helm-docs) (optional)

```bash
task tools                    # install helm-unittest plugin
task verify CHART=<name>      # helm lint + unittest + kubeconform
task verify-all               # verify all charts
task docs CHART=<name>        # regenerate chart README
task docs-all                 # regenerate all READMEs
task ct-lint CHART=<name>     # run chart-testing lint
```

## Contributing

1. Edit chart in `charts/<name>/`
2. Update unit tests in `charts/<name>/tests/`
3. Run `task verify CHART=<name>`
4. Run `task docs CHART=<name>` if values changed
5. Bump chart `version` in `Chart.yaml`
6. Open PR — CI runs lint, unittest, kubeconform, and docs check

## License

[MIT](LICENSE)
