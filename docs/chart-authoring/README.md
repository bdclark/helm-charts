# Chart Authoring

This directory is a passive reference library for chart authors and agents.

## How To Use This

- Start with the closest real chart in `charts/` when the overall behavior is similar.
- Use snippets when you only need a repeated building block rather than a whole chart shape.
- Prefer real-chart copying for chart-specific logic such as bootstrap flows, sidecars, special services, or unusual config files.

## Good Reference Charts

- Standard single-app baseline:
  `radarr`, `lidarr`, `sonarr`, `nzbget`, `prowlarr`
- Sidecar and multi-service:
  `qbittorrent-vpn`
- Networking/auth/config-heavy:
  `mosquitto`
- Runtime args and simpler storage:
  `wyoming-piper`

## Snippet Composition Guide

- Common helpers:
  `_helpers-common.tpl` + `env-from-map.tpl` + optionally `validate-config.tpl`
- Basic values + schema:
  `values-layout-basic.yaml` + `schema-env.json` + `schema-persistence-single.json`
- Multi-PVC values + schema:
  `values-layout-multi-pvc.yaml` + `schema-env.json` + `schema-persistence-map.json`
- README starter:
  `readme-header.gotmpl` + `readme-values-section.gotmpl`
- Helm-unittest starters:
  mix `unittest-*.yaml` files only for resources your chart actually renders

## Naming Defaults For New Snippets

- Keep metadata-style maps plain:
  `podLabels`, `podAnnotations`, `commonLabels`, `deploymentAnnotations`
- Keep `extraDeploymentLabels` additive and explicit.
- Keep `initContainers` as-is.
- Prefer `sidecars` for additional long-running pod containers.
- Prefer `extraVolumes` and `extraVolumeMounts` for additive pod-spec injections.
- Choose env naming based on ownership:
  `env` / `envFrom` when env is the primary user-owned section, and `extraEnv` / `extraEnvFrom` when the chart already renders required env entries and the values key is only additive.

Reference examples:

- `radarr`-style charts should generally keep `env` / `envFrom`.
- `mealie`-style charts should generally use `extraEnv` / `extraEnvFrom`.
- `qbittorrent-vpn` is the reference for sidecar and multi-service shapes; use `sidecars` for future snippets even though some existing charts still use `extraContainers`.

## Choosing Snippets vs Real Charts

- Use snippets when you need small repeated logic with minimal adaptation.
- Use a real chart when workload shape, service layout, or storage behavior is the main design choice.
- If a new chart is close to `radarr` but needs one custom config block, copy `radarr` and use snippets only for local additions.
