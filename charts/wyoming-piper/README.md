# Wyoming-Piper Helm Chart

[![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 2.2.2](https://img.shields.io/badge/AppVersion-2.2.2-informational?style=flat-square)](Chart.yaml)

Wyoming protocol server for Piper text to speech

> [!NOTE]
> This chart is under active development. Breaking changes may occur between minor versions.

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install wyoming-piper bdclark/wyoming-piper -f values.yaml
```

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

```yaml
env:
  TZ: America/New_York
  LOG_LEVEL: info

envFrom:
  - secretRef:
      name: wyoming-piper-secrets
```

## LinuxServer Image Example

To use LinuxServer's Piper image, override the image and set LinuxServer env vars.
If needed, adjust persistence mount path to `/config` for that image.

```yaml
image:
  repository: lscr.io/linuxserver/piper
  tag: latest

env:
  PUID: "1000"
  PGID: "1000"
  TZ: America/New_York

persistence:
  mountPath: /config
```

## Persistence

Persistence is enabled by default and mounted at `/data`.

```yaml
persistence:
  enabled: true
  size: 5Gi
  # storageClass: ""
  # existingClaim: wyoming-piper-data
```

### Additional Volumes

```yaml
volumes:
  - name: voices
    persistentVolumeClaim:
      claimName: piper-voices

volumeMounts:
  - name: voices
    mountPath: /voices
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Override the release name. |
| fullnameOverride | string | `""` | Override the full release name. |
| replicaCount | int | `1` | Number of replicas. |
| strategy | object | `{"type":"Recreate"}` | Deployment update strategy. |
| imagePullSecrets | list | `[]` | Image pull secrets. |
| deploymentAnnotations | object | `{}` | Annotations for the Deployment. |
| extraDeploymentLabels | object | `{}` | Additional labels for the Deployment. |
| podAnnotations | object | `{}` | Annotations for pods. |
| podLabels | object | `{}` | Additional labels for pods. |
| commonLabels | object | `{}` | Labels to add to all resources. |
| podSecurityContext | object | `{}` | Pod security context. |
| image.repository | string | `"rhasspy/wyoming-piper"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| securityContext | object | `{}` | Container security context. |
| resources | object | `{}` | Resource requests and limits. |
| ports | list | `[{"containerPort":10200,"name":"wyoming","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| persistence.enabled | bool | `true` | Enable persistence. |
| persistence.mountPath | string | `"/data"` | Mount path. |
| persistence.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.size | string | `"5Gi"` | Volume size. |
| persistence.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.annotations | object | `{}` | PVC annotations. |
| volumeMounts | list | `[]` | Additional volume mounts. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `10200` | Service port. |
| initContainers | list | `[]` | Additional init containers. |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
