# Radarr Helm Chart

[![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 6.0.4](https://img.shields.io/badge/AppVersion-6.0.4-informational?style=flat-square)](Chart.yaml)

Movie organizer/manager for usenet and torrent users

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install radarr bdclark/radarr -f values.yaml
```

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

### LinuxServer Variables

This chart uses the [LinuxServer.io](https://docs.linuxserver.io/images/docker-radarr/) Radarr image,
which supports common environment variables:

```yaml
env:
  TZ: America/New_York
  PUID: "1000"
  PGID: "1000"
```

### Radarr Configuration Overrides

Radarr supports environment variables to override entries in `config.xml`. Variables follow the pattern
`RADARR__<NAMESPACE>__<SETTING>`. See the [Servarr Wiki](https://wiki.servarr.com/radarr/environment-variables)
for details.

```yaml
env:
  # Server settings
  RADARR__SERVER__PORT: "7878"
  RADARR__SERVER__URLBASE: /radarr
  # Logging
  RADARR__LOG__LEVEL: info
  # Authentication
  RADARR__AUTH__METHOD: Forms
  RADARR__AUTH__REQUIRED: Enabled
  # PostgreSQL (optional - replaces SQLite)
  RADARR__POSTGRES__HOST: postgres
  RADARR__POSTGRES__PORT: "5432"
  RADARR__POSTGRES__USER: radarr
  RADARR__POSTGRES__MAINDB: radarr-main
  RADARR__POSTGRES__LOGDB: radarr-log
  RADARR__POSTGRES__PASSWORD:
    valueFrom:
      secretKeyRef:
        name: radarr-postgres
        key: password
```

### Bulk Environment Variables

For bulk environment variables from ConfigMaps or Secrets:

```yaml
envFrom:
  - secretRef:
      name: radarr-credentials
  - configMapRef:
      name: radarr-config
```

## Persistence

Two persistent volumes are available: `config` for Radarr's database and settings, and `data` for media files.
Both are enabled by default.

```yaml
persistence:
  config:
    enabled: true
    size: 1Gi
    # storageClass: ""
    # existingClaim: radarr-config
  data:
    enabled: true
    size: 100Gi
    mountPath: /data
    # storageClass: ""
    # existingClaim: media-library
```

### Using Existing Claims

To use pre-existing PVCs (useful for shared media libraries):

```yaml
persistence:
  config:
    enabled: true
    existingClaim: radarr-config
  data:
    enabled: true
    existingClaim: shared-media
```

### Additional Volumes

For more complex storage setups, use `volumes` and `volumeMounts`:

```yaml
volumes:
  - name: movies
    nfs:
      server: nas.local
      path: /volume1/movies
  - name: downloads
    persistentVolumeClaim:
      claimName: downloads-pvc

volumeMounts:
  - name: movies
    mountPath: /movies
  - name: downloads
    mountPath: /downloads
```

## Ingress

Enable ingress to expose Radarr externally:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: radarr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: radarr-tls
      hosts:
        - radarr.example.com
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
| podSecurityContext | object | `{}` | Pod security context. |
| image.repository | string | `"lscr.io/linuxserver/radarr"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| securityContext | object | `{}` | Container security context. |
| resources | object | `{}` | Resource requests and limits. |
| ports | list | `[{"containerPort":7878,"name":"http","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| persistence.config.enabled | bool | `true` | Enable persistence for config. |
| persistence.config.mountPath | string | `"/config"` | Mount path. |
| persistence.config.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.config.size | string | `"1Gi"` | Volume size. |
| persistence.config.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.config.annotations | object | `{}` | PVC annotations. |
| persistence.data.enabled | bool | `true` | Enable persistence for data. |
| persistence.data.mountPath | string | `"/data"` | Mount path. |
| persistence.data.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.data.size | string | `"100Gi"` | Volume size. |
| persistence.data.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.data.annotations | object | `{}` | PVC annotations. |
| volumeMounts | list | `[]` | Additional volume mounts. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `7878` | Service port. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"radarr.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| initContainers | list | `[]` | Additional init containers. |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
