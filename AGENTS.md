# AGENTS.md

This file is the high-level chart authoring contract for this repository.

## Goals

- Help agents and contributors move faster by reusing established repo patterns.
- Prefer consistency where it is useful.
- Preserve flexibility for charts that need different resource models or storage layouts.

## Hard Rules

- `README.md` files are generated with `helm-docs`. Do not hand-edit generated chart READMEs.
- Run `task docs CHART=<name>` when values comments or `README.md.gotmpl` change.
- Run `task verify CHART=<name>` before finishing chart work.
- Make schema decisions intentionally. If `additionalProperties` is open, it should be by choice rather than omission.

## Defaults, Not Requirements

These are preferred defaults, not structural requirements:

- Values ordering usually follows:
  metadata overrides, deployment/workload settings, image/runtime config, probes, env configuration, persistence, service, ingress, scheduling, pod-spec escape hatches.
- When an env map is appropriate, prefer the repo pattern that allows either scalar values or `{ value }` / `{ valueFrom }`.
- Use plain names for first-class user-owned sections and `extra*` names for additive escape hatches merged into chart-owned defaults.
- Prefer `sidecars` for additional long-running peer containers.
- Keep `initContainers` as `initContainers`; do not introduce `extraInitContainers`.
- Prefer `extraVolumes` and `extraVolumeMounts` for additive pod-spec injections.
- Choose env naming intentionally:
  use `env` / `envFrom` when the chart does not synthesize built-in env for the workload, and use `extraEnv` / `extraEnvFrom` when env is purely additive to chart-defined defaults.
- When persistence is needed, choose the shape that matches the chart:
  single PVC, grouped PVCs, zero PVCs, or other storage patterns are all valid.
- Tests should match the resources the chart actually renders. Do not assume every chart uses `Deployment`, `Ingress`, or `PVC`.

## Reference Map

Start from the closest existing chart before inventing new structure.

- Standard single-app charts:
  `radarr`, `lidarr`, `sonarr`, `nzbget`, `prowlarr`
- Sidecar and multi-service patterns:
  `qbittorrent-vpn`
- Networking/auth/config-heavy patterns:
  `mosquitto`
- Non-standard runtime args and simpler single-PVC layouts:
  `wyoming-piper`

## Snippet Library

Reusable examples live under `docs/chart-authoring/snippets/`.

- Use snippets as building blocks, not as a mandatory scaffold.
- Prefer copying from a real chart when behavior is highly chart-specific.
- Prefer snippets when you need a small, repeated pattern:
  helper definitions, env helper logic, schema fragments, README sections, or helm-unittest starters.
- Snippet naming contract for future charts:
  `podLabels`, `podAnnotations`, `commonLabels`, `deploymentAnnotations`, `extraDeploymentLabels`, `initContainers`, `sidecars`, `extraVolumes`, `extraVolumeMounts`, plus either `env` / `envFrom` or `extraEnv` / `extraEnvFrom` based on ownership.

## Values Ordering Policy

- For new charts, use the ordering from `docs/chart-authoring/snippets/values-layout-basic.yaml` or `values-layout-multi-pvc.yaml` as the default baseline.
- Use the closest existing chart to choose behavior and feature patterns, not to preserve older key ordering by default.
- For existing charts, preserve the current layout unless the work already includes a values/schema cleanup or substantial refactor.
- If adding a new section to an existing chart, place it according to the snippet ordering when practical.

## New Chart Workflow

1. Identify the closest reference chart from the map above.
2. Reuse snippets for small repeated patterns.
3. Keep `values.yaml`, `values.schema.json`, `README.md.gotmpl`, templates, and tests aligned.
4. Run `task verify CHART=<name>`.
5. Run `task docs CHART=<name>`.
6. Bump chart `version` in `Chart.yaml` when needed.

## Modify Existing Chart Workflow

1. Preserve the existing chart’s shape unless there is a reason to refactor it.
2. Reuse the snippet library only where it reduces repetition cleanly.
3. Update tests to match rendered behavior.
4. Run `task verify CHART=<name>`.
5. Run `task docs CHART=<name>` if docs inputs changed.

## What Not To Enforce

- Do not assume every chart should use `Deployment`. `StatefulSet` or other workload kinds may be appropriate.
- Do not assume every chart should have one PVC, any PVCs, or one service.
