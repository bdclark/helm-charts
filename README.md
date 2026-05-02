# Helm Charts

[![CI](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml)
[![Release](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml)

Personal Helm charts. Each chart has its own README under `charts/<name>/`.

## Charts

| Chart | Description |
| ----- | ----------- |
| [audiobookshelf](charts/audiobookshelf/) | Self-hosted audiobooks and podcast server |
| [lidarr](charts/lidarr/) | Music collection manager for usenet and torrent users |
| [mealie](charts/mealie/) | Mealie recipe manager and meal planner |
| [mosquitto](charts/mosquitto/) | Eclipse Mosquitto MQTT broker with authentication and persistence support |
| [music-assistant](charts/music-assistant/) | Music Assistant - Universal media library manager for streaming services and connected audio devices |
| [nzbget](charts/nzbget/) | Usenet downloader |
| [prowlarr](charts/prowlarr/) | Indexer manager for usenet and torrent users |
| [qbittorrent-vpn](charts/qbittorrent-vpn/) | qBittorrent with Gluetun VPN sidecar |
| [radarr](charts/radarr/) | Movie organizer/manager for usenet and torrent users |
| [seerr](charts/seerr/) | Request management for media libraries |
| [sonarr](charts/sonarr/) | TV show organizer/manager for usenet and torrent users |
| [wyoming-piper](charts/wyoming-piper/) | Wyoming protocol server for Piper text to speech |

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
