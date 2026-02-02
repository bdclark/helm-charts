# Prowlarr Helm Chart

[![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 2.3.0](https://img.shields.io/badge/AppVersion-2.3.0-informational?style=flat-square)](Chart.yaml)

Indexer manager for usenet and torrent users

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install prowlarr bdclark/prowlarr -f values.yaml
```

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

### LinuxServer Variables

This chart uses the [LinuxServer.io](https://docs.linuxserver.io/images/docker-prowlarr/) Prowlarr image,
which supports common environment variables:

```yaml
env:
  TZ: America/New_York
  PUID: "1000"
  PGID: "1000"
```

### Prowlarr Configuration Overrides

Prowlarr supports environment variables to override entries in `config.xml`. Variables follow the pattern
`PROWLARR__<NAMESPACE>__<SETTING>`. See the [Servarr Wiki](https://wiki.servarr.com/prowlarr/environment-variables)
for details.

```yaml
env:
  # Server settings
  PROWLARR__SERVER__PORT: "9696"
  PROWLARR__SERVER__URLBASE: /prowlarr
  # Logging
  PROWLARR__LOG__LEVEL: info
  # Authentication
  PROWLARR__AUTH__METHOD: Forms
  PROWLARR__AUTH__REQUIRED: Enabled
  # PostgreSQL (optional - replaces SQLite)
  PROWLARR__POSTGRES__HOST: postgres
  PROWLARR__POSTGRES__PORT: "5432"
  PROWLARR__POSTGRES__USER: prowlarr
  PROWLARR__POSTGRES__MAINDB: prowlarr-main
  PROWLARR__POSTGRES__LOGDB: prowlarr-log
  PROWLARR__POSTGRES__PASSWORD:
    valueFrom:
      secretKeyRef:
        name: prowlarr-postgres
        key: password
```

### Bulk Environment Variables

For bulk environment variables from ConfigMaps or Secrets:

```yaml
envFrom:
  - secretRef:
      name: prowlarr-credentials
  - configMapRef:
      name: prowlarr-config
```

## Persistence

Persistence is enabled by default for Prowlarr's database and settings.

```yaml
persistence:
  enabled: true
  size: 1Gi
  # storageClass: ""
  # existingClaim: prowlarr-config
```

### Using an Existing Claim

```yaml
persistence:
  enabled: true
  existingClaim: prowlarr-config
```

### Additional Volumes

For additional storage needs, use `volumes` and `volumeMounts`:

```yaml
volumes:
  - name: backups
    persistentVolumeClaim:
      claimName: backups-pvc

volumeMounts:
  - name: backups
    mountPath: /backups
```

## Ingress

Enable ingress to expose Prowlarr externally:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: prowlarr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: prowlarr-tls
      hosts:
        - prowlarr.example.com
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
| image.repository | string | `"lscr.io/linuxserver/prowlarr"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| securityContext | object | `{}` | Container security context. |
| resources | object | `{}` | Resource requests and limits. |
| ports | list | `[{"containerPort":9696,"name":"http","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| persistence.enabled | bool | `true` | Enable persistence for config. |
| persistence.mountPath | string | `"/config"` | Mount path. |
| persistence.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.size | string | `"1Gi"` | Volume size. |
| persistence.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.annotations | object | `{}` | PVC annotations. |
| volumeMounts | list | `[]` | Additional volume mounts. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `9696` | Service port. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"prowlarr.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| initContainers | list | `[]` | Additional init containers. |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
