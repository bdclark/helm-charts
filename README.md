# Helm Charts

[![CI](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml)
[![Release](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml)

Personal Helm charts. Each chart has its own README under `charts/<name>/`.

## Charts

| Chart                                       | Description                              |
| ------------------------------------------- | ---------------------------------------- |
| [lidarr](charts/lidarr/)                    | Music organizer/manager                  |
| [mealie](charts/mealie/)                    | Mealie recipe manager                    |
| [mosquitto](charts/mosquitto/)              | Eclipse Mosquitto MQTT broker            |
| [music-assistant](charts/music-assistant/)  | Music Assistant media server             |
| [nzbget](charts/nzbget/)                    | Usenet downloader                        |
| [prowlarr](charts/prowlarr/)                | Indexer manager for usenet and torrent   |
| [qbittorrent-vpn](charts/qbittorrent-vpn/)  | qBittorrent with VPN sidecar             |
| [radarr](charts/radarr/)                    | Movie organizer/manager                  |
| [seerr](charts/seerr/)                      | Request management (Overseerr replacement) |
| [sonarr](charts/sonarr/)                    | TV show organizer/manager                |
| [wyoming-piper](charts/wyoming-piper/)      | Wyoming protocol server for Piper TTS    |

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

CI install smoke checks run with `ct install` on changed charts in a kind cluster.
For chart-specific CI install overrides, add values files under:

```text
charts/<name>/ci/*-values.yaml
```

`ct install` will run install/tests for each matching file automatically.

## Contributing

1. Edit chart in `charts/<name>/`
2. Update unit tests in `charts/<name>/tests/`
3. Use `AGENTS.md` and `docs/chart-authoring/README.md` as the authoring guide and snippet library
4. Run `task verify CHART=<name>`
5. Run `task docs CHART=<name>` if values changed
6. Bump chart `version` in `Chart.yaml`
7. Open PR — CI runs lint, unittest, kubeconform, and docs check

## License

[MIT](LICENSE)
