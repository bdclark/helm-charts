# Bindery Helm Chart

[![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square)](Chart.yaml)
[![AppVersion: v1.33.3](https://img.shields.io/badge/AppVersion-v1.33.3-informational?style=flat-square)](Chart.yaml)

Automated ebook and audiobook download manager for Usenet and torrents

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install bindery bdclark/bindery -f values.yaml
```

## Persistence

Bindery stores its SQLite database, backups, and image cache in `persistence.config`,
which is enabled by default and mounted at `/config`.

`persistence.data` is disabled by default. Bindery and its download client must mount
the same filesystem at the same path to use hardlinks rather than copying completed
downloads. Enable it with an existing shared claim for the normal media-stack layout:

```yaml
persistence:
  data:
    enabled: true
    existingClaim: shared-media
    mountPath: /data
```

Configure Bindery to use directories beneath that shared mount:

```yaml
env:
  BINDERY_DOWNLOAD_DIR: /data/downloads/complete
  BINDERY_LIBRARY_DIR: /data/books
  # Optional: leave unset to keep audiobooks with the ebook library.
  # BINDERY_AUDIOBOOK_DIR: /data/audiobooks
```

To provision a standalone data claim, enable `persistence.data` without
`existingClaim`. It only supports hardlinks when the download client also mounts that
same claim at the same path.

### Additional Volumes

Use `extraVolumes` and `extraVolumeMounts` for additional media roots, Calibre
integration, or a nonstandard storage topology:

```yaml
extraVolumes:
  - name: calibre
    persistentVolumeClaim:
      claimName: calibre-library

extraVolumeMounts:
  - name: calibre
    mountPath: /calibre
    readOnly: true
```

## Environment Variables

Configure Bindery through the web UI. Use `env` for environment-level settings such as
paths, URL base, logging, or API-key seeding, and `envFrom` for bulk ConfigMap or
Secret references.

```yaml
env:
  BINDERY_LOG_LEVEL: info
  BINDERY_URL_BASE: /bindery
  BINDERY_API_KEY:
    valueFrom:
      secretKeyRef:
        name: bindery-secrets
        key: api-key

envFrom:
  - secretRef:
      name: bindery-env
```

## Security and Probes

The upstream distroless image runs as UID/GID `65532`. This chart uses the upstream
non-root, read-only-root-filesystem security profile and mounts an internal writable
`/tmp`. Startup uses a TCP probe; readiness and liveness use `/api/v1/health`.

## Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: bindery.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Override the release name. |
| fullnameOverride | string | `""` | Override the full release name. |
| replicaCount | int | `1` | Number of replicas. Bindery uses SQLite and supports one active replica. |
| strategy | object | `{"type":"Recreate"}` | Deployment update strategy. Bindery uses SQLite and requires Recreate. |
| deploymentAnnotations | object | `{}` | Annotations for the Deployment. |
| extraDeploymentLabels | object | `{}` | Additional labels for the Deployment. |
| podAnnotations | object | `{}` | Annotations for pods. |
| podLabels | object | `{}` | Additional labels for pods. |
| commonLabels | object | `{}` | Labels to add to all resources. |
| image.repository | string | `"ghcr.io/vavallee/bindery"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| imagePullSecrets | list | `[]` | Image pull secrets. |
| podSecurityContext | object | `{"fsGroup":65532,"runAsGroup":65532,"runAsNonRoot":true,"runAsUser":65532,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod security context. |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Container security context. |
| resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"50m","memory":"128Mi"}}` | Resource requests and limits. |
| ports | list | `[{"containerPort":8787,"name":"http","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{"failureThreshold":30,"periodSeconds":5,"tcpSocket":{"port":"http"}}` | Startup probe configuration. |
| livenessProbe | object | `{"failureThreshold":5,"httpGet":{"path":"/api/v1/health","port":"http"},"initialDelaySeconds":30,"periodSeconds":10}` | Liveness probe configuration. |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/api/v1/health","port":"http"},"periodSeconds":10}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. Configure media paths below the mounted data volume. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| persistence.config.enabled | bool | `true` | Enable persistence for Bindery's database, backups, and image cache. |
| persistence.config.mountPath | string | `"/config"` | Mount path. |
| persistence.config.subPath | string | `""` | Subdirectory of the volume to mount (optional). |
| persistence.config.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.config.size | string | `"4Gi"` | Volume size. |
| persistence.config.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.config.annotations | object | `{}` | PVC annotations. |
| persistence.data.enabled | bool | `false` | Enable a shared media volume for downloads and libraries. |
| persistence.data.mountPath | string | `"/data"` | Mount path. |
| persistence.data.subPath | string | `""` | Subdirectory of the volume to mount (optional). |
| persistence.data.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.data.size | string | `"100Gi"` | Volume size when provisioning a PVC. |
| persistence.data.existingClaim | string | `""` | Existing shared media PVC. Recommended when the download client uses the same filesystem. |
| persistence.data.annotations | object | `{}` | PVC annotations. |
| extraVolumeMounts | list | `[]` | Additional volume mounts. |
| initContainers | list | `[]` | Additional init containers. |
| sidecars | list | `[]` | Additional sidecar containers. |
| extraVolumes | list | `[]` | Additional volumes. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `8787` | Service port. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"bindery.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
