# Audiobookshelf Helm Chart

[![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 2.33.1](https://img.shields.io/badge/AppVersion-2.33.1-informational?style=flat-square)](Chart.yaml)

Self-hosted audiobooks and podcast server

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install audiobookshelf bdclark/audiobookshelf -f values.yaml
```

## Runtime Defaults

By default, this chart follows upstream container behavior (root-compatible). 
Use the non-root profile below when your cluster policy requires non-root workloads.

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

```yaml
env:
  TZ: America/New_York
  HOST: 0.0.0.0
  PORT: "80"
  CONFIG_PATH: /config
  METADATA_PATH: /metadata
  BACKUP_PATH: /metadata/backups
```

## Persistence

This chart manages two PVCs by default:
- `persistence.config` mounted at `/config`
- `persistence.metadata` mounted at `/metadata`

```yaml
persistence:
  config:
    enabled: true
    size: 5Gi
  metadata:
    enabled: true
    size: 5Gi
```

### Media Volumes (Existing PVCs)

Use `mediaMounts` to mount user-provided media claims:

```yaml
mediaMounts:
  - name: audiobooks
    existingClaim: media-audiobooks
    mountPath: /audiobooks
    readOnly: true
  - name: podcasts
    existingClaim: media-podcasts
    mountPath: /podcasts
    readOnly: true
```

## Non-Root Profile Example

For non-root execution, switch to a non-privileged port and align service/container settings:

```yaml
podSecurityContext:
  fsGroup: 1000

securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  runAsNonRoot: true

env:
  PORT: "13378"

ports:
  - name: http
    containerPort: 13378
    protocol: TCP

service:
  port: 13378
  targetPort: http

permissionsInitContainer:
  enabled: true
  chownUser: 1000
  chownGroup: 1000
  chownPaths:
    - /config
    - /metadata
```

## Permissions Init Container

The optional built-in permissions init container is intentionally scoped to chart-owned writable paths (`/config`, `/metadata`) and does not touch media mounts.

## Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: audiobookshelf.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Override the release name. |
| fullnameOverride | string | `""` | Override the full release name. |
| replicaCount | int | `1` | Number of replicas. |
| strategy | object | `{"type":"Recreate"}` | Deployment update strategy. |
| commonLabels | object | `{}` | Labels to add to all resources. |
| deploymentAnnotations | object | `{}` | Annotations for the Deployment. |
| extraDeploymentLabels | object | `{}` | Additional labels for the Deployment. |
| podAnnotations | object | `{}` | Annotations for pods. |
| podLabels | object | `{}` | Additional labels for pods. |
| image.repository | string | `"ghcr.io/advplyr/audiobookshelf"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| imagePullSecrets | list | `[]` | Image pull secrets. |
| podSecurityContext | object | `{}` | Pod security context. |
| securityContext | object | `{}` | Container security context. |
| ports | list | `[{"containerPort":80,"name":"http","protocol":"TCP"}]` | Container ports. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| resources | object | `{}` | Resource requests and limits. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| persistence.config.enabled | bool | `true` | Enable persistence for config data. |
| persistence.config.mountPath | string | `"/config"` | Mount path. |
| persistence.config.subPath | string | `""` | Subdirectory of the volume to mount (optional). |
| persistence.config.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.config.size | string | `"5Gi"` | Volume size. |
| persistence.config.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.config.annotations | object | `{}` | PVC annotations. |
| persistence.metadata.enabled | bool | `true` | Enable persistence for metadata. |
| persistence.metadata.mountPath | string | `"/metadata"` | Mount path. |
| persistence.metadata.subPath | string | `""` | Subdirectory of the volume to mount (optional). |
| persistence.metadata.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.metadata.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.metadata.size | string | `"5Gi"` | Volume size. |
| persistence.metadata.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.metadata.annotations | object | `{}` | PVC annotations. |
| mediaMounts | list | `[]` | Structured media mounts for user-provided existing PVCs. |
| permissionsInitContainer.enabled | bool | `false` | Enable built-in permissions init container. |
| permissionsInitContainer.image | string | `"busybox:1.37"` | Image for the permissions init container. |
| permissionsInitContainer.runAsUser | int | `0` | UID used to run the init container. |
| permissionsInitContainer.runAsGroup | int | `0` | GID used to run the init container. |
| permissionsInitContainer.chownUser | int | `1000` | UID to chown target paths to. |
| permissionsInitContainer.chownGroup | int | `1000` | GID to chown target paths to. |
| permissionsInitContainer.chownPaths | list | `["/config","/metadata"]` | Paths to chown. Keep this limited to app-owned writable paths. |
| initContainers | list | `[]` | Additional init containers. |
| sidecars | list | `[]` | Additional sidecar containers. |
| extraVolumes | list | `[]` | Additional volumes. |
| extraVolumeMounts | list | `[]` | Additional volume mounts. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `80` | Service port. |
| service.targetPort | string | `"http"` | Target port name or number. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"audiobookshelf.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
