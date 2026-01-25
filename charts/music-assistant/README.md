# Music-Assistant Helm Chart

[![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 2.7.5](https://img.shields.io/badge/AppVersion-2.7.5-informational?style=flat-square)](Chart.yaml)

Music Assistant - Universal media library manager for streaming services and connected audio devices

## Installing

### From repo

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install music-assistant bdclark/music-assistant
```

### From source

```bash
helm install music-assistant ./charts/music-assistant
```

### Uninstall

```bash
helm uninstall music-assistant
```

## Networking Modes

| Mode | Use case | Notes |
|------|----------|-------|
| `hostNetwork=true` *(default)* | Direct VLAN / UPnP / Chromecast discovery | Pod shares node network namespace. Disable `service.*` unless you still need a ClusterIP for probes. |
| `hostNetwork=false` | Standard Kubernetes networking (ingress, services) | Enables `service.*` ports; device discovery depends on CNI support. |

## Persistence and update strategy

Music Assistant runs as a single replica, with a single PVC when persistence is
enabled. Persistence is recommended for production use to retain configuration,
metadata, and cache data across pod restarts and upgrades.

```yaml
persistence:
  enabled: true
  size: 5Gi
  storageClass: fast-ssd
```

The deployment update strategy defaults depend on persistence settings:

- Persistence disabled:
  uses Kubernetes default update behavior (RollingUpdate unless otherwise set).
- Persistence enabled:
  defaults to Recreate to avoid ReadWriteOnce attach/mount conflicts.

The deployment strategy may be overridden explicitly, for example:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 0
    maxUnavailable: 1
```

## Common overrides

### Cluster networking + ingress

```yaml
hostNetwork: false
service:
  enabled: true
  type: ClusterIP
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: music-assistant.local
      paths:
        - path: /
          pathType: Prefix
```

### Host networking with media mounts

```yaml
hostNetwork: true
additionalVolumes:
  - name: media-nfs
    nfs:
      server: nas.example.com
      path: /volume1/media
additionalMounts:
  - name: media-nfs
    mountPath: /media
    readOnly: true
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.repository | string | `"ghcr.io/music-assistant/server"` | Image repository |
| image.tag | string | `"2.7.5"` | Image tag |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| imagePullSecrets | list | `[]` | Secrets for pulling images from private repositories |
| nameOverride | string | `""` | Override the chart name |
| fullnameOverride | string | `""` | Override the full release name |
| podLabels | object | `{}` | Extra labels applied to the pod |
| podAnnotations | object | `{}` | Pod annotations applied to the Music Assistant pod |
| podSecurityContext | object | `{}` | Pod security context |
| resources | object | `{}` | Resource requests/limits for the pod |
| securityContext.runAsNonRoot | bool | `false` | Whether to run the container as non-root |
| securityContext.runAsUser | int | `0` | User ID to run the container as |
| securityContext.runAsGroup | int | `0` | Group ID to run the container as |
| securityContext.capabilities.enabled | bool | `false` |  |
| securityContext.capabilities.add | list | `[]` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| hostNetwork | bool | `true` | Run the pod in the node network namespace |
| dnsPolicy | string | `"ClusterFirst"` | DNS policy when using host networking |
| hostPort.enabled | bool | `false` | Enable hostPort configuration |
| hostPort.webPort | int | `8095` | Host port for the web interface |
| hostPort.streamPort | int | `8097` | Host port for audio streaming |
| service.enabled | bool | `false` | Create Service resources |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP/LoadBalancer/NodePort) |
| service.annotations | object | `{}` | Additional service annotations |
| service.webPort | int | `8095` | Port for the web interface |
| service.streamPort | int | `8097` | Port for audio streaming |
| service.loadBalancerIP | string | `""` | Static IP for LoadBalancer services |
| service.loadBalancerSourceRanges | list | `[]` | Allowed source ranges for LoadBalancer |
| service.externalTrafficPolicy | string | `"Cluster"` | Preserve client IP (Local) or use Cluster routing |
| service.sessionAffinity | string | `"None"` | Service session affinity mode |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.className | string | `""` | Ingress class name |
| ingress.annotations | object | `{}` | Additional ingress annotations |
| ingress.hosts | list | `[{"host":"music-assistant.local","paths":[{"path":"/","pathType":"Prefix"}]}]` | Ingress rules configuration |
| ingress.tls | list | `[]` | TLS configuration for ingress |
| persistence.enabled | bool | `true` | Enable persistent volume for Music Assistant data |
| persistence.storageClass | string | `""` | Storage class for PVC Set to "-" to disable dynamic provisioning and use default storage class Set to "" to use cluster default storage class |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes for the PVC |
| persistence.size | string | `"2Gi"` | Requested PVC size |
| persistence.existingClaim | string | `""` | Use an existing PVC instead of creating a new one If defined, PVC must be created manually before volume will be bound |
| persistence.annotations | object | `{}` | Annotations for PVC |
| strategy | object | `{}` | Deployment update strategy (default: Recreate when persistence.enabled) |
| additionalVolumes | list | `[]` | Extra volumes to mount (e.g., media libraries) |
| additionalMounts | list | `[]` | Additional volume mounts matching `additionalVolumes` |
| env | list | `[]` | Extra environment variables for the container |
| envFrom | list | `[]` | Environment sources (ConfigMap/Secret refs) |
| livenessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/","port":"web"},"initialDelaySeconds":60,"periodSeconds":30,"timeoutSeconds":10}` | Liveness probe configuration |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/","port":"web"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration |
| startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/","port":"web"},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration |
| nodeSelector | object | `{}` | Node selector for scheduling |
| tolerations | list | `[]` | Pod tolerations |
| affinity | object | `{}` | Pod affinity/anti-affinity rules |

## Contributing

- Bump `version`/`appVersion` in `Chart.yaml` for any change.
- Keep unit tests (`charts/music-assistant/tests/`) and integration tests (`tests/integration/pytest_suite/charts/test_music_assistant.py`) up to date.
- Run `task verify-chart CHART=music-assistant` + targeted `task pytest` before opening a PR.

## License

MIT — see [LICENSE](../../LICENSE).
